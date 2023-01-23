package PDF::Builder::Resource::CIDFont::CJKFont;

use base 'PDF::Builder::Resource::CIDFont';

use strict;
use warnings;

our $VERSION = '3.025'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

our $fonts = {};
our $cmap  = {};
our $alias;
our $subs;

=head1 NAME

PDF::Builder::Resource::CIDFont::CJKFont - Base class for CJK fonts

=head1 METHODS

=over

=item $font = PDF::Builder::Resource::CIDFont::CJKFont->new($pdf, $cjkname, %options)

Returns a cjk-font object.

=over

* Traditional Chinese: Ming Ming-Bold Ming-Italic Ming-BoldItalic

* Simplified Chinese: Song Song-Bold Song-Italic Song-BoldItalic

* Korean: MyungJo MyungJo-Bold MyungJo-Italic MyungJo-BoldItalic

* Japanese (Mincho): KozMin KozMin-Bold KozMin-Italic KozMin-BoldItalic

* Japanese (Gothic): KozGo KozGo-Bold KozGo-Italic KozGo-BoldItalic

=back

Defined Options:

    encode ... specify fonts encoding for non-utf8 text.

=cut

sub _look_for_font {
    my $fname = lc(shift);

    $fname =~ s/[^a-z0-9]+//gi;
    $fname = $alias->{$fname} if defined $alias->{$fname};
    return {%{$fonts->{$fname}}} if defined $fonts->{$fname};

    if (defined $subs->{$fname}) {
        my $data = _look_for_font($subs->{$fname}->{'-alias'});
        foreach my $k (keys %{$subs->{$fname}}) {
            next if $k =~ /^\-/;
            if (substr($k, 0, 1) eq '+') {
                $data->{substr($k, 1)} .= $subs->{$fname}->{$k};
            } else {
                $data->{$k} = $subs->{$fname}->{$k};
            }
        }
        $fonts->{$fname} = $data;
        return {%$data};
    }

    eval "require 'PDF/Builder/Resource/CIDFont/CJKFont/$fname.data'"; ## no critic
    unless ($@) {
        return {%{$fonts->{$fname}}};
    } else {
        die "requested font '$fname' not installed ";
    }
}

# identical routine in Resource/CIDFont/TrueType/FontFile.pm
sub _look_for_cmap {
    my $map = shift;
    my $fname = lc($map);

    $fname =~ s/[^a-z0-9]+//gi;
    return {%{$cmap->{$fname}}} if defined $cmap->{$fname};
    eval "require 'PDF/Builder/Resource/CIDFont/CMap/$fname.cmap'"; ## no critic
    unless ($@) {
        return {%{$cmap->{$fname}}};
    } else {
        die "requested cmap '$map' not installed ";
    }
}

# compare to TrueType/FontFile.pm: .data and .cmap files are apparently
# required when using cjkfont(), so no looking at internal cmap tables
sub new {
    my ($class, $pdf, $name, @opts) = @_;

    my %opts = ();
    %opts = @opts if (scalar @opts)%2 == 0;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-encode'} && !defined $opts{'encode'}) { $opts{'encode'} = delete($opts{'-encode'}); }
    $opts{'encode'} ||= 'ident';

    my $data = _look_for_font($name);

    my $cmap = _look_for_cmap($data->{'cmap'});

    $data->{'u2g'} = { %{$cmap->{'u2g'}} };
    $data->{'g2u'} = [ @{$cmap->{'g2u'}} ];

    $class = ref $class if ref $class;
    # ensure that apiname is initialized
    my $key = ($data->{'apiname'} // '') . pdfkey();
    my $self = $class->SUPER::new($pdf, $key);
    $pdf->new_obj($self) if defined($pdf) && !$self->is_obj($pdf);

    $self->{' data'} = $data;

    if (defined $opts{'encode'} && $opts{'encode'} ne 'ident') {
        $self->data->{'encode'} = $opts{'encode'};
    }

    my $emap = {
        'reg' => 'Adobe',
        'ord' => 'Identity',
        'sup' => 0,
        'map' => 'Identity',
        'dir' => 'H',
        'dec' => 'ident',
    };

    if (defined $cmap->{'ccs'}) {
        $emap->{'reg'} = $cmap->{'ccs'}->[0];
        $emap->{'ord'} = $cmap->{'ccs'}->[1];
        $emap->{'sup'} = $cmap->{'ccs'}->[2];
    }

    #if      (defined $cmap->{'cmap'} && defined $cmap->{'cmap'}->{$opts{'encode'}} ) {
    #    $emap->{'dec'} = $cmap->{'cmap'}->{$opts{'encode'}}->[0];
    #    $emap->{'map'} = $cmap->{'cmap'}->{$opts{'encode'}}->[1];
    #} elsif (defined $cmap->{'cmap'} && defined $cmap->{'cmap'}->{'utf8'}) {
    #    $emap->{'dec'} = $cmap->{'cmap'}->{'utf8'}->[0];
    #    $emap->{'map'} = $cmap->{'cmap'}->{'utf8'}->[1];
    #}

    $self->data()->{'decode'} = $emap->{'dec'};

    $self->{'BaseFont'} = PDFName(join('-',
		                       $self->fontname(),
				       $emap->{'map'},
				       $emap->{'dir'}));
    $self->{'Encoding'} = PDFName(join('-',
		                       $emap->{'map'},
				       $emap->{'dir'}));

    my $des = $self->descrByData();
    my $de = $self->{' de'};

    $de->{'FontDescriptor'} = $des;
    $de->{'Subtype'} = PDFName('CIDFontType0');
    $de->{'BaseFont'} = PDFName($self->fontname());
    $de->{'DW'} = PDFNum($self->missingwidth());
    $de->{'CIDSystemInfo'}->{'Registry'} = PDFString($emap->{'reg'}, 'x');
    $de->{'CIDSystemInfo'}->{'Ordering'} = PDFString($emap->{'ord'}, 'x');
    $de->{'CIDSystemInfo'}->{'Supplement'} = PDFNum($emap->{'sup'});
    ## $de->{'CIDToGIDMap'} = PDFName($emap->{'map'}); # ttf only

    return $self;
}

sub tounicodemap {
    my $self = shift;

    # no-op since PDF knows its char-collection
    return $self;
}

sub glyphByCId {
    my ($self, $cid) = @_;

    my $uni = $self->uniByCId($cid);
    return nameByUni($uni);
}

sub outobjdeep {
    my ($self, $fh, $pdf) = @_;

    my $notdefbefore = 1;

    my $wx = PDFArray();
    $self->{' de'}->{'W'} = $wx;
    my $ml;

    foreach my $i (0 .. (scalar @{$self->data()->{'g2u'}} - 1 )) {
        if      (ref($self->data()->{'wx'}) eq 'ARRAY' &&
            (defined $self->data()->{'wx'}->[$i]) &&
            ($self->data()->{'wx'}->[$i] != $self->missingwidth()) ) {
            if ($notdefbefore) {
                $notdefbefore = 0;
                $ml = PDFArray();
                $wx->add_elements(PDFNum($i), $ml);
	    }
            $ml->add_elements(PDFNum($self->data()->{'wx'}->[$i]));
        } elsif (ref($self->data()->{'wx'}) eq 'HASH' &&
            (defined $self->data()->{'wx'}->{$i}) &&
            ($self->data()->{'wx'}->{$i} != $self->missingwidth()) ) {
            if ($notdefbefore) {
                $notdefbefore = 0;
                $ml = PDFArray();
                $wx->add_elements(PDFNum($i), $ml);
	    }
            $ml->add_elements(PDFNum($self->data()->{'wx'}->{$i}));
        } else {
            $notdefbefore = 1;
        }
    }

    return $self->SUPER::outobjdeep($fh, $pdf);
}

BEGIN {

    $alias = {
        'traditional'           => 'adobemingstdlightacro',
        'traditionalbold'       => 'mingbold',
        'traditionalitalic'     => 'mingitalic',
        'traditionalbolditalic' => 'mingbolditalic',
        'ming'                  => 'adobemingstdlightacro',

        'simplified'            => 'adobesongstdlightacro',
        'simplifiedbold'        => 'songbold',
        'simplifieditalic'      => 'songitalic',
        'simplifiedbolditalic'  => 'songbolditalic',
        'song'                  => 'adobesongstdlightacro',

        'korean'                => 'adobemyungjostdmediumacro',
        'koreanbold'            => 'myungjobold',
        'koreanitalic'          => 'myungjoitalic',
        'koreanbolditalic'      => 'myungjobolditalic',
        'myungjo'               => 'adobemyungjostdmediumacro',

        'japanese'              => 'kozminproregularacro',
        'japanesebold'          => 'kozminbold',
        'japaneseitalic'        => 'kozminitalic',
        'japanesebolditalic'    => 'kozminbolditalic',
        'kozmin'                => 'kozminproregularacro',
        'kozgo'                 => 'kozgopromediumacro',

    };
    $subs = {
    # Chinese Traditional (i.e., ROC/Taiwan) Fonts
        'mingitalic' => {
            '-alias'    => 'adobemingstdlightacro',
            '+fontname' => ',Italic',
        },
        'mingbold' => {
            '-alias'    => 'adobemingstdlightacro',
            '+fontname' => ',Bold',
        },
        'mingbolditalic' => {
            '-alias'    => 'adobemingstdlightacro',
            '+fontname' => ',BoldItalic',
        },
    # Chinese Simplified (i.e., PRC/Mainland China) Fonts
        'songitalic' => {
            '-alias'    => 'adobesongstdlightacro',
            '+fontname' => ',Italic',
        },
        'songbold' => {
            '-alias'    => 'adobesongstdlightacro',
            '+fontname' => ',Bold',
        },
        'songbolditalic' => {
            '-alias'    => 'adobesongstdlightacro',
            '+fontname' => ',BoldItalic',
        },
    # Japanese Gothic (i.e., sans serif) Fonts
        'kozgoitalic' => {
            '-alias'    => 'kozgopromediumacro',
            '+fontname' => ',Italic',
        },
        'kozgobold' => {
            '-alias'    => 'kozgopromediumacro',
            '+fontname' => ',Bold',
        },
        'kozgobolditalic' => {
            '-alias'    => 'kozgopromediumacro',
            '+fontname' => ',BoldItalic',
        },
    # Japanese Mincho (i.e., serif) Fonts
        'kozminitalic' => {
            '-alias'    => 'kozminproregularacro',
            '+fontname' => ',Italic',
        },
        'kozminbold' => {
            '-alias'    => 'kozminproregularacro',
            '+fontname' => ',Bold',
        },
        'kozminbolditalic' => {
            '-alias'    => 'kozminproregularacro',
            '+fontname' => ',BoldItalic',
        },
    # Korean Fonts
        'myungjoitalic' => {
            '-alias'    => 'adobemyungjostdmediumacro',
            '+fontname' => ',Italic',
        },
        'myungjobold' => {
            '-alias'    => 'adobemyungjostdmediumacro',
            '+fontname' => ',Bold',
        },
        'myungjobolditalic' => {
            '-alias'    => 'adobemyungjostdmediumacro',
            '+fontname' => ',BoldItalic',
        },
    };

}

=back

=cut

1;
