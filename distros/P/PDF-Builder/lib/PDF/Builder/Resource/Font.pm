package PDF::Builder::Resource::Font;

use base 'PDF::Builder::Resource::BaseFont';

use strict;
use warnings;
#no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.023'; # VERSION
our $LAST_UPDATE = '3.021'; # manually update whenever code is changed

use Encode qw(:all);

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Resource::Font - some common support routines for font files. Inherits from L<PDF::Builder::Resource::BaseFont>

=cut

sub encodeByData {
    my ($self, $encoding) = @_;

    my $data = $self->data();

    if ($self->issymbol() || ($encoding||'') eq 'asis') {
        $encoding = undef;
    }

    if      (defined $encoding && $encoding =~ m|^uni(\d+)$|o) {
        my $blk = $1;
        $data->{'e2u'} = [ map { $blk*256+$_ } (0..255) ];
        $data->{'e2n'} = [ map { nameByUni($_) || '.notdef' } @{$data->{'e2u'}} ];
        $data->{'firstchar'} = 0;
    } elsif (defined $encoding) {
        $data->{'e2u'} = [ unpack('U*', decode($encoding, pack('C*', (0..255)))) ];
        $data->{'e2n'} = [ map { nameByUni($_) || '.notdef' } @{$data->{'e2u'}} ];
    } elsif (defined $data->{'uni'}) {
        $data->{'e2u'} = [ @{$data->{'uni'}} ];
        $data->{'e2n'} = [ map { $_ || '.notdef' } @{$data->{'char'}} ];
    } else {
        $data->{'e2u'} = [ map { uniByName($_) } @{$data->{'char'}} ];
        $data->{'e2n'} = [ map { $_ || '.notdef' } @{$data->{'char'}} ];
    }

    $data->{'u2c'} = {};
    $data->{'u2e'} = {};
    $data->{'u2n'} = {};
    $data->{'n2c'} = {};
    $data->{'n2e'} = {};
    $data->{'n2u'} = {};

    foreach my $n (0..255) {
        my $xchar = undef;
        my $xuni = undef;
        if (defined $data->{'char'}->[$n]) {
            $xchar = $data->{'char'}->[$n];
        } else {
            $xchar = '.notdef';
        }
        $data->{'n2c'}->{$xchar} = $n unless defined $data->{'n2c'}->{$xchar};

        if (defined $data->{'e2n'}->[$n]) {
            $xchar = $data->{'e2n'}->[$n];
        } else {
            $xchar = '.notdef';
        }
        $data->{'n2e'}->{$xchar} = $n unless defined $data->{'n2e'}->{$xchar};

        $data->{'n2u'}->{$xchar} = $data->{'e2u'}->[$n] 
	    unless defined $data->{'n2u'}->{$xchar};

        if (defined $data->{'char'}->[$n]) {
            $xchar = $data->{'char'}->[$n];
        } else {
            $xchar = '.notdef';
        }
        if (defined $data->{'uni'}->[$n]) {
            $xuni = $data->{'uni'}->[$n];
        } else {
            $xuni = 0;
        }
        $data->{'n2u'}->{$xchar} = $xuni unless defined $data->{'n2u'}->{$xchar};

        $data->{'u2c'}->{$xuni} ||= $n unless defined $data->{'u2c'}->{$xuni};

        if (defined $data->{'e2u'}->[$n]) {
            $xuni = $data->{'e2u'}->[$n];
        } else {
            $xuni = 0;
        }
        $data->{'u2e'}->{$xuni} ||= $n unless defined $data->{'u2e'}->{$xuni};

        if (defined $data->{'e2n'}->[$n]) {
            $xchar = $data->{'e2n'}->[$n];
        } else {
            $xchar = '.notdef';
        }
        $data->{'u2n'}->{$xuni} = $xchar unless defined $data->{'u2n'}->{$xuni};

        if (defined $data->{'char'}->[$n]) {
            $xchar = $data->{'char'}->[$n];
        } else {
            $xchar = '.notdef';
        }
        if (defined $data->{'uni'}->[$n]) {
            $xuni = $data->{'uni'}->[$n];
        } else {
            $xuni = 0;
        }
        $data->{'u2n'}->{$xuni} = $xchar unless defined $data->{'u2n'}->{$xuni};
    }

    my $en = PDFDict();
    $self->{'Encoding'} = $en;

    $en->{'Type'} = PDFName('Encoding');
    $en->{'BaseEncoding'} = PDFName('WinAnsiEncoding');

    $en->{'Differences'} = PDFArray(PDFNum(0));
    foreach my $n (0..255) {
        $en->{'Differences'}->add_elements(PDFName($self->glyphByEnc($n) || '.notdef'));
    }

    $self->{'FirstChar'} = PDFNum($data->{'firstchar'});
    $self->{'LastChar'} = PDFNum($data->{'lastchar'});

    $self->{'Widths'} = PDFArray();
    foreach my $n ($data->{'firstchar'} .. $data->{'lastchar'}) {
        $self->{'Widths'}->add_elements(PDFNum($self->wxByEnc($n)));
    }

    return $self;
}

=head1 METHODS

=over

=item $font->automap()

This applies to core fonts (C<< $pdf->corefont() >>) and PostScript fonts 
(C<< $pdf->psfont() >>). These cannot use UTF-8 (or other multibyte character) 
encoded text; only single byte characters. This limits a font to a maximum of
256 glyphs (the "standard" single-byte encoding being used). Any other glyphs 
supplied with the font are inaccessible.

C<automap> splits a font containing more than 256 glyphs into "planes" of single
byte fonts of up to 256 glyphs, so that all glyphs may be accessed in separate 
"fonts". An array of new fonts will be returned, with [0] being the standard 
code page (of the selected encoding). If there are any glyphs beyond xFF on the 
standard encoding page, they will be returned in one or more additional fonts
of 223 glyphs each. I<Why 223?> The first 32 are reserved as control characters
(although they have no glyphs), and number x20 is a space. This, plus 223, 
gives 256 in total (the last plane may have fewer than 223 glyphs). These 
"fonts" are temporary (dynamic), though as usable as any other font. 

Note that a plane may be B<empty> (only I<space> at x20 and possibly an unusable
character at x21) if the previous plane was full. You might want to check if
any character in the plane has a Unicode value (if not, it's empty).

The I<ordering> of these 223 glyphs in each following plane does I<not> appear 
to follow any particular official scheme, so be sure to reference something like
C<examples/020_corefonts> to see what is available, and what code point a glyph 
is at (e.g., an 'A' in the text stream will print something different if you're 
not on plane 0). For a given font B<file>, they should be I<consistent>. For 
instance, in Times-Roman core font, an \x21 or ! in plane[1] should always give 
an A+macron. Further note that new editions of font files released in the future
may have changes to the glyph list and the ordering (affecting which plane a
glyph appears on), so use automap() with caution. It appears that glyphs are 
sorted by Unicode number, but if a new glyph is inserted, it would bump other 
glyphs to new positions, and even to the next plane.

An example:

    $fnt = $pdf->corefont('Times-Roman', -encode => 'latin1');
    @planes = ($fnt, $fnt->automap());  # two planes
    $text->font($planes[0], 15);  # or just $fnt will work
    $text->text('!');  # prints !
    $text->font($planes[1], 15);
    $text->text('!');  # prints A+macron

If you had used 'latin2' encoding, an \x21 on plane 1 will give an inverted !
(&iexcl; HTML entity).

Note that C<< $planes[$n]->fontname() >> should always be the desired base
font (e.g., I<Times-Roman>), while C<< $planes[$n]->name() >> will be the font
ID (e.g., I<TiRoCBC>) for plane 0, while for other planes there will be a 
unique suffix added (e.g., I<TiRoCBCam0>).

If you have just an occasional non-plane 0 character (or run of characters),
it may be tolerable to switch back and forth between planes like this, just as
typing an HTML entity once in a while when you need a Greek letter on a web page
is acceptable to most people. However, if you're typing a lot of Greek text, a 
dedicated keyboard may be better for you. Like that, switching to a TTF font in 
order to be able to use UTF-8 may be easier.

=back

=cut

sub automap {
    my ($self) = @_;
	my $data = $self->data();

    my %gl = map { $_=>defineName($_) } keys %{$data->{'wx'}};

    foreach my $n (0..255) {
        delete $gl{$data->{'e2n'}->[$n]};
    }

    if (defined $data->{'comps'} && !$self->{'-nocomps'}) {
        foreach my $n (keys %{$data->{'comps'}}) {
            delete $gl{$n};
        }
    }

    my @nm = sort { $gl{$a} <=> $gl{$b} } keys %gl;

    my @fnts = ();
    my $count = 0;
    while (my @glyphs = splice(@nm, 0, 223)) {
        my $obj = $self->SUPER::new($self->{' apipdf'}, $self->name().'am'.$count);
        $obj->{' data'} = { %{$data} };
        $obj->data()->{'firstchar'} = 32;
        $obj->data()->{'lastchar'} = 32+scalar(@glyphs);
        push(@fnts, $obj);
        foreach my $key (qw( Subtype BaseFont FontDescriptor )) {
            $obj->{$key} = $self->{$key} if defined $self->{$key};
        }
        $obj->data()->{'char'} = [];
        $obj->data()->{'uni'} = [];
        foreach my $n (0..31) {
            $obj->data()->{'char'}->[$n] = '.notdef';
            $obj->data()->{'uni'}->[$n] = 0;
        }
        $obj->data()->{'char'}->[32] = 'space';
        $obj->data()->{'uni'}->[32] = 32;
        foreach my $n (33 .. $obj->data()->{'lastchar'}) {
            $obj->data()->{'char'}->[$n] = $glyphs[$n-33];
            $obj->data()->{'uni'}->[$n] = $gl{$glyphs[$n-33]};
        }
        foreach my $n (($obj->data()->{'lastchar'}+1) .. 255) {
            $obj->data()->{'char'}->[$n] = '.notdef';
            $obj->data()->{'uni'}->[$n] = 0;
        }
        $obj->encodeByData(undef);

        $count++;
    }

    return @fnts;
}

sub remap {
    my ($self, $enc) = @_;

    my $obj = $self->SUPER::new($self->{' apipdf'}, $self->name().'rm'.pdfkey());
    $obj->{' data'}={ %{$self->data()} };
    foreach my $key (qw( Subtype BaseFont FontDescriptor )) {
        $obj->{$key} = $self->{$key} if defined $self->{$key};
    }

    $obj->encodeByData($enc);

    return $obj;
}

1;
