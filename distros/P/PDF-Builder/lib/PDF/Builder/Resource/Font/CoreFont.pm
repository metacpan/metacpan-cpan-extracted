package PDF::Builder::Resource::Font::CoreFont;

use base 'PDF::Builder::Resource::Font';

use strict;
no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.014'; # VERSION
my $LAST_UPDATE = '3.013'; # manually update whenever code is changed

use File::Basename;

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

our $fonts;
our $alias;
our $subs;

=head1 NAME

PDF::Builder::Resource::Font::CoreFont - Module for using the 14 PDF built-in Fonts.

=head1 SYNOPSIS

    #
    use PDF::Builder;
    #
    $pdf = PDF::Builder->new();
    $cft = $pdf->corefont('Times-Roman');
    #

=head1 METHODS

=over

=item $font = PDF::Builder::Resource::Font::CoreFont->new($pdf, $fontname, %options)

=item $font = PDF::Builder::Resource::Font::CoreFont->new($pdf, $fontname)

Returns a corefont object.

=cut

=pod

Valid %options are:

I<-encode>
... changes the encoding of the font from its default.
See I<perl's Encode> for the supported values.

I<-pdfname> ... changes the reference-name of the font from its default.
The reference-name is normally generated automatically and can be
retrieved via C<$pdfname=$font->name()>.

=back

=head2 Supported typefaces

B<standard PDF types>

=over

=item helvetica helveticaoblique helveticabold helvetiaboldoblique

May have Arial substituted on some systems (e.g., Windows)

=item courier courieroblique courierbold courierboldoblique

Fixed pitch, may have Courier New substituted on some systems (e.g., Windows)

=item timesroman timesitalic timesbold timesbolditalic

May have Times New Roman substituted on some systems (e.g., Windows)

=item symbol zapfdingbats

=back

B<Primarily Windows typefaces>

=over

=item georgia georgiaitalic georgiabold georgiabolditalic

=item verdana verdanaitalic verdanabold verdanabolditalic

=item trebuchet trebuchetitalic trebuchetbold trebuchetbolditalic

=item bankgothic bankgothicitalic bankgothicbold bankgothicitalic

Free versions of Bank Gothic are often only medium weight.

=item webdings wingdings

=back

Keep in mind that only font metrics (widths) are provided with PDF::Builder;
the fonts themselves are provided by the reader's machine (often packaged
with the operating system, or obtained separately by the user). To use a
specific font may require you to obtain one or more files from some source.

If a font (typeface and variant) is not available on a given reader's
machine, a substitution I<may> be automatically made. For example, Helvetica is
usually not shipped with Windows machines, and Arial might be substituted.
For most characters, the glyph widths will be the same, but this can not be 
guaranteed!

PDF::Builder currently uses the [typeface].pm files to map glyph names to
code points (single byte encodings only) and to look up the glyph widths for
character positioning. There is no guarantee that a given font file includes
all the desired glyphs, nor that the widths will be absolutely the same, even
in different releases of the same font.

=cut

sub _look_for_font {
    my $fname = shift;

    ## return %{$fonts->{$fname}} if defined $fonts->{$fname};
    eval "require PDF::Builder::Resource::Font::CoreFont::$fname; "; ## no critic
    unless($@) {
        my $class = "PDF::Builder::Resource::Font::CoreFont::$fname";
        $fonts->{$fname} = deep_copy($class->data());
        $fonts->{$fname}->{'uni'} ||= [];
        foreach my $n (0..255) {
            $fonts->{$fname}->{'uni'}->[$n] = uniByName($fonts->{$fname}->{'char'}->[$n]) unless defined $fonts->{$fname}->{'uni'}->[$n];
        }
        return %{$fonts->{$fname}};
    } else {
        die "requested core font '$fname' not installed ";
    }
}

#
# Deep copy something, thanks to Randal L. Schwartz
# Changed to deal w/ CODE refs, in which case it doesn't try to deep copy
#
sub deep_copy {
    my $this = shift;

    if      (not ref $this) {
        return $this;
    } elsif (ref $this eq "ARRAY") {
        return [map &deep_copy($_), @$this];   ## no critic
    } elsif (ref $this eq "HASH") {
        return +{map { $_ => &deep_copy($this->{$_}) } keys %$this};
    } elsif (ref $this eq "CODE") {
        # Can't deep copy code refs
        return $this;
    } else {
        die "what type is $_?";
    }
}

sub new {
    my ($class, $pdf, $name, @opts) = @_;

    my ($self,$data);
    my %opts = ();

    if (-f $name) {
        eval "require '$name'; "; ## no critic
        $name = basename($name,'.pm');
    }
    my $lookname = lc($name);
    $lookname =~ s/[^a-z0-9]+//gi;
    %opts = @opts if (scalar @opts)%2 == 0;
    $opts{'-encode'} ||= 'asis';

    $lookname = defined($alias->{$lookname})? $alias->{$lookname}: $lookname ;

    if (defined $subs->{$lookname}) {
        $data = {_look_for_font($subs->{$lookname}->{'-alias'})};
        foreach my $k (keys %{$subs->{$lookname}}) {
            next if $k =~ /^\-/;
            $data->{$k} = $subs->{$lookname}->{$k};
        }
    } else {
        unless (defined $opts{'-metrics'}) {
            $data = {_look_for_font($lookname)};
        } else {
            $data = {%{$opts{'-metrics'}}};
        }
    }

    die "Undefined Core Font '$name($lookname)'" unless $data->{'fontname'};

    # we have data now here so we need to check if
    # there is a -ttfile or -afmfile/-pfmfile/-pfbfile
    # and proxy the call to the relevant modules
    #
    #if (defined $data->{'-ttfile'} && $data->{'-ttfile'} = _look_for_fontfile($data->{'-ttfile'})) {
    #    return PDF::Builder::Resource::CIDFont::TrueType->new($pdf, $data->{'-ttfile'}, @opts);
    #} elsif (defined $data->{'-pfbfile'} && $data->{'-pfbfile'} = _look_for_fontfile($data->{'-pfbfile'})) {
    #    $data->{'-afmfile'} = _look_for_fontfile($data->{'-afmfile'});
    #    return PDF::Builder::Resource::Font::Postscript->new($pdf, $data->{'-pfbfile'}, $data->{'-afmfile'}, @opts));
    #} elsif (defined $data->{'-gfx'}) { # to be written and tested in 'Maki' first!
    #    return PDF::Builder::Resource::Font::gFont->new($pdf, $data, @opts);
    #}

    $class = ref $class if ref $class;
#   $self = $class->SUPER::new($pdf, $data->{'apiname'}.pdfkey().'~'.time());
    $self = $class->SUPER::new($pdf, $data->{'apiname'}.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);
    $self->{' data'} = $data;
    $self->{'-dokern'} = 1 if $opts{'-dokern'};

    $self->{'Subtype'} = PDFName($self->data()->{'type'});
    $self->{'BaseFont'} = PDFName($self->fontname());
    if ($opts{'-pdfname'}) {
        $self->name($opts{'-pdfname'});
    }

    unless ($self->data()->{'iscore'}) {
        $self->{'FontDescriptor'} = $self->descrByData();
    }

    $self->encodeByData($opts{'-encode'});

    return $self;
}

=over

=item PDF::Builder::Resource::Font::CoreFont->loadallfonts()

"Requires in" all fonts available as corefonts.

=cut

sub loadallfonts {
    foreach my $f (qw[
	    bankgothic bankgothicbold bankgothicbolditalic bankgothicitalic
        courier courierbold courierboldoblique courieroblique
        georgia georgiabold georgiabolditalic georgiaitalic
        helveticaboldoblique helveticaoblique helveticabold helvetica
        symbol
        timesbolditalic timesitalic timesroman timesbold
        verdana verdanabold verdanabolditalic verdanaitalic
        trebuchet trebuchetbold trebuchetbolditalic trebuchetitalic
        webdings
        wingdings
        zapfdingbats
    ]) {
        _look_for_font($f);
    }
    return;
}

# not yet supported
#    andalemono
#    arialrounded
#    impact
#    ozhandicraft

BEGIN
{

    $alias = {
        ## Windows Fonts with Type1 equivalence
        'arial'                     => 'helvetica',
        'arialitalic'               => 'helveticaoblique',
        'arialbold'                 => 'helveticabold',
        'arialbolditalic'           => 'helveticaboldoblique',

        'times'                     => 'timesroman',
        'timesnewromanbolditalic'   => 'timesbolditalic',
        'timesnewromanbold'         => 'timesbold',
        'timesnewromanitalic'       => 'timesitalic',
        'timesnewroman'             => 'timesroman',

        'couriernewbolditalic'      => 'courierboldoblique',
        'couriernewbold'            => 'courierbold',
        'couriernewitalic'          => 'courieroblique',
        'couriernew'                => 'courier',
    };

    $subs = {
         'bankgothicbold' => {
             'apiname'       => 'Bg2',
             '-alias'        => 'bankgothic',
             'fontname'      => 'BankGothicMediumBT,Bold',
             'flags'         => 32+262144,
         },
         'bankgothicbolditalic' => {
             'apiname'       => 'Bg3',
             '-alias'        => 'bankgothic',
             'fontname'      => 'BankGothicMediumBT,BoldItalic',
             'italicangle'   => -15,
             'flags'         => 96+262144,
         },
         'bankgothicitalic' => {
             'apiname'       => 'Bg4',
             '-alias'        => 'bankgothic',
             'fontname'      => 'BankGothicMediumBT,Italic',
             'italicangle'   => -15,
             'flags'         => 96,
         },
        #  'impactitalic'      => {
        #            'apiname' => 'Imp2',
        #            '-alias'  => 'impact',
        #            'fontname'  => 'Impact,Italic',
        #            'italicangle' => -12,
        #          },
        #  'ozhandicraftbold'    => {
        #            'apiname' => 'Oz2',
        #            '-alias'  => 'ozhandicraft',
        #            'fontname'  => 'OzHandicraftBT,Bold',
        #            'italicangle' => 0,
        #            'flags' => 32+262144,
        #          },
        #  'ozhandicraftitalic'    => {
        #            'apiname' => 'Oz3',
        #            '-alias'  => 'ozhandicraft',
        #            'fontname'  => 'OzHandicraftBT,Italic',
        #            'italicangle' => -15,
        #            'flags' => 96,
        #          },
        #  'ozhandicraftbolditalic'  => {
        #            'apiname' => 'Oz4',
        #            '-alias'  => 'ozhandicraft',
        #            'fontname'  => 'OzHandicraftBT,BoldItalic',
        #            'italicangle' => -15,
        #            'flags' => 96+262144,
        #          },
        #  'arialroundeditalic'  => {
        #            'apiname' => 'ArRo2',
        #            '-alias'  => 'arialrounded',
        #            'fontname'  => 'ArialRoundedMTBold,Italic',
        #            'italicangle' => -15,
        #            'flags' => 96+262144,
        #          },
        #  'arialitalic'  => {
        #            'apiname' => 'Ar2',
        #            '-alias'  => 'arial',
        #            'fontname'  => 'Arial,Italic',
        #            'italicangle' => -15,
        #            'flags' => 96,
        #          },
        #  'arialbolditalic'  => {
        #            'apiname' => 'Ar3',
        #            '-alias'  => 'arial',
        #            'fontname'  => 'Arial,BoldItalic',
        #            'italicangle' => -15,
        #            'flags' => 96+262144,
        #          },
        #  'arialbold'  => {
        #            'apiname' => 'Ar4',
        #            '-alias'  => 'arial',
        #            'fontname'  => 'Arial,Bold',
        #            'flags' => 32+262144,
        #          },
    };

    $fonts = { };

}

1;

__END__

=back

=head1 AUTHOR

Alfred Reibenschuh

=cut


