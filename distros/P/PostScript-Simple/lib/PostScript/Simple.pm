#! /usr/bin/perl -w

package PostScript::Simple;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Carp;
use Exporter;
use PostScript::Simple::EPS;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.09';


#-------------------------------------------------------------------------------

=head1 NAME

PostScript::Simple - Produce PostScript files from Perl

=head1 SYNOPSIS

    use PostScript::Simple;
    
    # create a new PostScript object
    $p = new PostScript::Simple(papersize => "A4",
                                colour => 1,
                                eps => 0,
                                units => "in");
    
    # create a new page
    $p->newpage;
    
    # draw some lines and other shapes
    $p->line(1,1, 1,4);
    $p->linextend(2,4);
    $p->box(1.5,1, 2,3.5);
    $p->circle(2,2, 1);
    $p->setlinewidth( 0.01 );
    $p->curve(1,5, 1,7, 3,7, 3,5);
    $p->curvextend(3,3, 5,3, 5,5);
    
    # draw a rotated polygon in a different colour
    $p->setcolour(0,100,200);
    $p->polygon({rotate=>45}, 1,1, 1,2, 2,2, 2,1, 1,1);
    
    # add some text in red
    $p->setcolour("red");
    $p->setfont("Times-Roman", 20);
    $p->text(1,1, "Hello");
    
    # write the output to a file
    $p->output("file.ps");


=head1 DESCRIPTION

PostScript::Simple allows you to have a simple method of writing PostScript
files from Perl. It has graphics primitives that allow lines, curves, circles,
polygons and boxes to be drawn. Text can be added to the page using standard
PostScript fonts.

The images can be single page EPS files, or multipage PostScript files. The
image size can be set by using a recognised paper size ("C<A4>", for example) or
by giving dimensions. The units used can be specified ("C<mm>" or "C<in>", etc)
and are the same as those used in TeX. The default unit is a bp, or a PostScript
point, unlike TeX.

=head1 PREREQUISITES

This module requires C<strict> and C<Exporter>.

=head2 EXPORT

None.

=cut


#-------------------------------------------------------------------------------

# Define some colour names
my %pscolours = (
  # Original colours from PostScript::Simple
  brightred         => [255, 0,   0],   brightgreen          => [0,   255, 0],   brightblue      => [0,   0,   1],
  red               => [204, 0,   0],   green                => [0,   204, 0],   blue            => [0,   0,   204],
  darkred           => [127, 0,   0],   darkgreen            => [0,   127, 0],   darkblue        => [0,   0,   127],
  grey10            => [25,  25,  25],  grey20               => [51,  51,  51],  grey30          => [76,  76,  76],
  grey40            => [102, 102, 102], grey50               => [127, 127, 127], grey60          => [153, 153, 153],
  grey70            => [178, 178, 178], grey80               => [204, 204, 204], grey90          => [229, 229, 229],
  black             => [0,   0,   0],   white                => [255, 255, 255],

  # X-Windows colours, unless they clash with the above (only /(dark)?(red|green|blue)/ )
  aliceblue         => [240, 248, 255], antiquewhite         => [250, 235, 215], aqua            => [0,   255, 255],
  aquamarine        => [127, 255, 212], azure                => [240, 255, 255], beige           => [245, 245, 220],
  bisque            => [255, 228, 196], blanchedalmond       => [255, 255, 205], blueviolet      => [138, 43,  226],
  brown             => [165, 42,  42],  burlywood            => [222, 184, 135], cadetblue       => [95,  158, 160],
  chartreuse        => [127, 255, 0],   chocolate            => [210, 105, 30],  coral           => [255, 127, 80],
  cornflowerblue    => [100, 149, 237], cornsilk             => [255, 248, 220], crimson         => [220, 20,  60],
  cyan              => [0,   255, 255], darkcyan             => [0,   139, 139], darkgoldenrod   => [184, 134, 11],
  darkgray          => [169, 169, 169], darkgrey             => [169, 169, 169], darkkhaki       => [189, 183, 107],
  darkmagenta       => [139, 0,   139], darkolivegreen       => [85,  107, 47],  darkorange      => [255, 140, 0],
  darkorchid        => [153, 50,  204], darksalmon           => [233, 150, 122], darkseagreen    => [143, 188, 143],
  darkslateblue     => [72,  61,  139], darkslategray        => [47,  79,  79],  darkslategrey   => [47,  79,  79],
  darkturquoise     => [0,   206, 209], darkviolet           => [148, 0,   211], deeppink        => [255, 20,  147],
  deepskyblue       => [0,   191, 255], dimgray              => [105, 105, 105], dimgrey         => [105, 105, 105],
  dodgerblue        => [30,  144, 255], firebrick            => [178, 34,  34],  floralwhite     => [255, 250, 240],
  forestgreen       => [34,  139, 34],  fuchsia              => [255, 0,   255], gainsboro       => [220, 220, 220],
  ghostwhite        => [248, 248, 255], gold                 => [255, 215, 0],   goldenrod       => [218, 165, 32],
  gray              => [128, 128, 128], grey                 => [128, 128, 128], greenyellow     => [173, 255, 47],
  honeydew          => [240, 255, 240], hotpink              => [255, 105, 180], indianred       => [205, 92,  92],
  indigo            => [75,  0,   130], ivory                => [255, 240, 240], khaki           => [240, 230, 140],
  lavender          => [230, 230, 250], lavenderblush        => [255, 240, 245], lawngreen       => [124, 252, 0],
  lemonchiffon      => [255, 250, 205], lightblue            => [173, 216, 230], lightcoral      => [240, 128, 128],
  lightcyan         => [224, 255, 255], lightgoldenrodyellow => [250, 250, 210], lightgray       => [211, 211, 211],
  lightgreen        => [144, 238, 144], lightgrey            => [211, 211, 211], lightpink       => [255, 182, 193],
  lightsalmon       => [255, 160, 122], lightseagreen        => [32,  178, 170], lightskyblue    => [135, 206, 250],
  lightslategray    => [119, 136, 153], lightslategrey       => [119, 136, 153], lightsteelblue  => [176, 196, 222],
  lightyellow       => [255, 255, 224], lime                 => [0,   255, 0],   limegreen       => [50,  205, 50],
  linen             => [250, 240, 230], magenta              => [255, 0,   255], maroon          => [128, 0,   0],
  mediumaquamarine  => [102, 205, 170], mediumblue           => [0,   0,   205], mediumorchid    => [186, 85,  211],
  mediumpurple      => [147, 112, 219], mediumseagreen       => [60,  179, 113], mediumslateblue => [123, 104, 238],
  mediumspringgreen => [0,   250, 154], mediumturquoise      => [72,  209, 204], mediumvioletred => [199, 21,  133],
  midnightblue      => [25,  25,  112], mintcream            => [245, 255, 250], mistyrose       => [255, 228, 225],
  moccasin          => [255, 228, 181], navajowhite          => [255, 222, 173], navy            => [0,   0,   128],
  oldlace           => [253, 245, 230], olive                => [128, 128, 0],   olivedrab       => [107, 142, 35],
  orange            => [255, 165, 0],   orangered            => [255, 69,  0],   orchid          => [218, 112, 214],
  palegoldenrod     => [238, 232, 170], palegreen            => [152, 251, 152], paleturquoise   => [175, 238, 238],
  palevioletred     => [219, 112, 147], papayawhip           => [255, 239, 213], peachpuff       => [255, 218, 185],
  peru              => [205, 133, 63],  pink                 => [255, 192, 203], plum            => [221, 160, 221],
  powderblue        => [176, 224, 230], purple               => [128, 0,   128], rosybrown       => [188, 143, 143],
  royalblue         => [65,  105, 225], saddlebrown          => [139, 69,  19],  salmon          => [250, 128, 114],
  sandybrown        => [244, 164, 96],  seagreen             => [46,  139, 87],  seashell        => [255, 245, 238],
  sienna            => [160, 82,  45],  silver               => [192, 192, 192], skyblue         => [135, 206, 235],
  slateblue         => [106, 90,  205], slategray            => [112, 128, 144], slategrey       => [112, 128, 144],
  snow              => [255, 250, 250], springgreen          => [0,   255, 127], steelblue       => [70,  130, 180],
  tan               => [210, 180, 140], teal                 => [0,   128, 128], thistle         => [216, 191, 216],
  tomato            => [253, 99,  71],  turquoise            => [64,  224, 208], violet          => [238, 130, 238],
  wheat             => [245, 222, 179], whitesmoke           => [245, 245, 245], yellow          => [255, 255, 0],
  yellowgreen       => [154, 205, 50],
);


# define page sizes here (a4, letter, etc)
# should be Properly Cased
my %pspaper = (
  A0                    => [2384, 3370],
  A1                    => [1684, 2384],
  A2                    => [1191, 1684],
  A3                    => [841.88976, 1190.5512],
  A4                    => [595.27559, 841.88976],
  A5                    => [420.94488, 595.27559],
  A6                    => [297, 420],
  A7                    => [210, 297],
  A8                    => [148, 210],
  A9                    => [105, 148],

  B0                    => [2920, 4127],
  B1                    => [2064, 2920],
  B2                    => [1460, 2064],
  B3                    => [1032, 1460],
  B4                    => [729, 1032],
  B5                    => [516, 729],
  B6                    => [363, 516],
  B7                    => [258, 363],
  B8                    => [181, 258],
  B9                    => [127, 181 ],
  B10                   => [91, 127],

  Executive             => [522, 756],
  Folio                 => [595, 935],
  'Half-Letter'         => [612, 397],
  Letter                => [612, 792],
  'US-Letter'           => [612, 792],
  Legal                 => [612, 1008],
  'US-Legal'            => [612, 1008],
  Tabloid               => [792, 1224],
  'SuperB'              => [843, 1227],
  Ledger                => [1224, 792],

  'Comm #10 Envelope'   => [297, 684],
  'Envelope-Monarch'    => [280, 542],
  'Envelope-DL'         => [312, 624],
  'Envelope-C5'         => [461, 648],

  'EuroPostcard'        => [298, 420],
);


# The 13 standard fonts that are available on all PS 1 implementations:
my @fonts = (
  'Courier', 'Courier-Bold', 'Courier-BoldOblique', 'Courier-Oblique',
  'Helvetica', 'Helvetica-Bold', 'Helvetica-BoldOblique', 'Helvetica-Oblique',
  'Times-Roman', 'Times-Bold', 'Times-BoldItalic', 'Times-Italic',
  'Symbol');

# define the origins for the page a document can have
# (default is "LeftBottom")
my %psorigin = (
  'LeftBottom'  => [ 0,  0],
  'LeftTop'     => [ 0, -1],
  'RightBottom' => [-1,  0],
  'RightTop'    => [-1, -1],
);

# define the co-ordinate direction (default is 'RightUp')
my %psdirs = (
  'RightUp'     => [ 1,  1],
  'RightDown'   => [ 1, -1],
  'LeftUp'      => [-1,  1],
  'LeftDown'    => [-1, -1],
);


# measuring units are two-letter acronyms as used in TeX:
#  bp: postscript point (72 per inch)
#  in: inch (72 postscript points)
#  pt: printer's point (72.27 per inch)
#  mm: millimetre (25.4 per inch)
#  cm: centimetre (2.54 per inch)
#  pi: pica (12 printer's points)
#  dd: didot point (67.567. per inch)
#  cc: cicero (12 didot points)

#  set up the others here (sp) XXXXX

my %psunits = (
  pt   => [72, 72.27],
  pc   => [72, 6.0225],
  in   => [72, 1],
  bp   => [1, 1],
  cm   => [72, 2.54],
  mm   => [72, 25.4],
  dd   => [72, 67.567],
  cc   => [72, 810.804],
);


#-------------------------------------------------------------------------------

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new PostScript::Simple object. The different options that can be set are:

=over 4

=item units

Units that are to be used in the file. Common units would be C<mm>, C<in>,
C<pt>, C<bp>, and C<cm>. Others are as used in TeX. (Default: C<bp>)

=item xsize

Specifies the width of the drawing area in units.

=item ysize

Specifies the height of the drawing area in units.

=item papersize

The size of paper to use, if C<xsize> or C<ysize> are not defined. This allows
a document to easily be created using a standard paper size without having to
remember the size of paper using PostScript points. Valid choices are currently
"C<A3>", "C<A4>", "C<A5>", and "C<Letter>".

=item landscape

Use the landscape option to rotate the page by 90 degrees. The paper dimensions
are also rotated, so that clipping will still work. (Note that the printer will
still think that the paper is portrait.) (Default: 0)

=item copies

Set the number of copies that should be printed. (Default: 1)

=item clip

If set to 1, the image will be clipped to the xsize and ysize. This is most
useful for an EPS image. (Default: 0)

=item colour

Specifies whether the image should be rendered in colour or not. If set to 0
(default) all requests for a colour are mapped to a greyscale. Otherwise the
colour requested with C<setcolour> or C<line> is used. This option is present
because most modern laser printers are only black and white. (Default: 0)

=item eps

Generate an EPS file, rather than a standard PostScript file. If set to 1, no
newpage methods will actually create a new page. This option is probably the
most useful for generating images to be imported into other applications, such
as TeX. (Default: 1)

=item page

Specifies the initial page number of the (multi page) document. The page number
is set with the Adobe DSC comments, and is used nowhere else. It only makes
finding your pages easier. See also the C<newpage> method. (Default: 1)

=item coordorigin

Defines the co-ordinate origin for each page produced. Valid arguments are
C<LeftBottom>, C<LeftTop>, C<RightBottom> and C<RightTop>. The default is
C<LeftBottom>.

=item direction

The direction the co-ordinates go from the origin. Values can be C<RightUp>,
C<RightDown>, C<LeftUp> and C<LeftDown>. The default value is C<RightUp>.

=item reencode

Requests that a font re-encode function be added and that the 13 standard
PostScript fonts get re-encoded in the specified encoding. The most popular
choice (other than undef) is 'ISOLatin1Encoding' which selects the iso8859-1
encoding and fits most of western Europe, including the Scandinavia. Refer to
Adobes Postscript documentation for other encodings.

The output file is, by default, re-encoded to ISOLatin1Encoding. To stop this
happening, use 'reencode => undef'. To use the re-encoded font, '-iso' must be
appended to the names of the fonts used, e.g. 'Helvetica-iso'.

=back

Example:

    $ref = new PostScript::Simple(landscape => 1,
                                  eps => 0,
                                  xsize => 4,
                                  ysize => 3,
                                  units => "in");

Create a document that is 4 by 3 inches and prints landscape on a page. It is
not an EPS file, and must therefore use the C<newpage> method.

    $ref = new PostScript::Simple(eps => 1,
                                  colour => 1,
                                  xsize => 12,
                                  ysize => 12,
                                  units => "cm",
                                  reencode => "ISOLatin1Encoding");

Create a 12 by 12 cm EPS image that is in colour. Note that "C<eps =E<gt> 1>"
did not have to be specified because this is the default. Re-encode the
standard fonts into the iso8859-1 encoding, providing all the special characters
used in Western Europe. The C<newpage> method should not be used.

=back

=cut

sub new
{
  my ($class, %data) = @_;
  my $self = {
    xsize          => undef,
    ysize          => undef,
    papersize      => undef,
    units          => "bp",     # measuring units (see below)
    landscape      => 0,        # rotate the page 90 degrees
    copies         => 1,        # number of copies
    colour         => 0,        # use colour
    clip           => 0,        # clip to the bounding box
    eps            => 1,        # create eps file
    page           => 1,        # page number to start at
    reencode       => "ISOLatin1Encoding", # Re-encode the 13 standard
                                           # fonts in this encoding

    bbx1           => 0,        # Bounding Box definitions
    bby1           => 0,
    bbx2           => 0,
    bby2           => 0,

    pscomments     => "",       # the following entries store data
    psprolog       => "",       # for the same DSC areas of the
    psresources    => {},       # postscript file.
    pssetup        => "",
    pspages        => [],
    pstrailer      => "",
    usedunits      => {},       # units that have been used

    lastfontsize   => 0,
    pspagecount    => 0,

    coordorigin    => 'LeftBottom',
    direction      => 'RightUp',

    lasterror      => undef,
  };

  foreach (keys %data) {
    $self->{$_} = $data{$_};
  }

  bless $self, $class;
  $self->init();

  return $self;
}


#-------------------------------------------------------------------------------

sub _u
{
  my ($self, $u, $rev) = @_;

  my $val;
  my $unit;

  # $u may be...
  #  a simple number, in which case the current units are used
  #  a listref of [number, "unit"], to force the unit
  #  a string "number unit", e.g. "4 mm" or "2.4in"

  if (ref($u) eq "ARRAY") {
    $val = $$u[0];
    $unit = $$u[1];
    confess "Invalid array" if @$u != 2;
  } else {
    if ($u =~ /^\s*(-?\d+(?:\.\d+)?)\s*([a-z][a-z])?\s*$/) {
      $val = $1;
      $unit = $2 || $self->{units};
    }
  }

  confess "Cannot determine length" unless defined $val;
  confess "Cannot determine unit (invalid array?)" unless defined $unit;

  croak "Invalid unit '$unit'" unless defined $psunits{$unit};

  unless (defined $self->{usedunits}{$unit}) {
    my ($m, $d) = @{$psunits{$unit}};

    my $c = "{";
    $c .= "$m mul " unless $m == 1;
    $c .= "$d div " unless $d == 1;
    $c =~ s/ $//;
    $c .="}";
    $self->{usedunits}{$unit} = "/u$unit $c def";
  }

  $val = $rev * $val if defined $rev;

  return "$val u$unit ";
}

sub _ux
{
  my ($self, $d) = @_;

  return $self->_u($d, $psdirs{$self->{direction}}[0]);
}

sub _uy
{
  my ($self, $d) = @_;

  return $self->_u($d, $psdirs{$self->{direction}}[1]);
}

sub _uxy
{
  my ($self, $x, $y) = @_;

  return $self->_ux($x) . $self->_uy($y);
}


sub init
{
  my $self = shift;

  my ($m, $d) = (1, 1);
  my ($u, $mm);

# Create a blank "page" for EPS
  if ($self->{eps}) {
    $self->{currentpage} = [];
    $self->{pspages} = [$self->{currentpage}];
  }


# Units
  $self->{units} = lc $self->{units};

  if (defined($psunits{$self->{units}})) {
    ($m, $d) = @{$psunits{$self->{units}}};
  } else {
    $self->_error( "unit '$self->{units}' undefined" );
  }


# Paper size
  if (defined $self->{papersize}) {
    $self->{papersize} = ucfirst lc $self->{papersize};
  }

  if (!defined $self->{xsize} || !defined $self->{ysize}) {
    if (defined $self->{papersize} && defined $pspaper{$self->{papersize}}) {
      ($self->{xsize}, $self->{ysize}) = @{$pspaper{$self->{papersize}}};
      $self->{bbx2} = int($self->{xsize});
      $self->{bby2} = int($self->{ysize});
      $self->{pscomments} .= "\%\%DocumentMedia: $self->{papersize} $self->{xsize} ";
      $self->{pscomments} .= "$self->{ysize} 0 ( ) ( )\n";
    } else {
      ($self->{xsize}, $self->{ysize}) = (100,100);
      $self->_error( "page size undefined" );
    }
  } else {
    $self->{bbx2} = int(($self->{xsize} * $m) / $d);
    $self->{bby2} = int(($self->{ysize} * $m) / $d);
  }

  if (!$self->{eps}) {
    $self->{pssetup} .= "ll 2 ge { << /PageSize [ $self->{xsize} " .
                        "$self->{ysize} ] /ImagingBBox null >>" .
                        " setpagedevice } if\n";
  }

# Landscape
  if ($self->{landscape}) {
    my $swap;

    $self->{psresources}{landscape} = <<"EOP";
/landscape {
  $self->{bbx2} 0 translate 90 rotate
} bind def
EOP

    # I now think that Portrait is the correct thing here, as the page is
    # rotated.
    $self->{pscomments} .= "\%\%Orientation: Portrait\n";
#    $self->{pscomments} .= "\%\%Orientation: Landscape\n";
    $swap = $self->{bbx2};
    $self->{bbx2} = $self->{bby2};
    $self->{bby2} = $swap;

    # for EPS files, change to landscape here, as there are no pages
    if ($self->{eps}) { $self->{pssetup} .= "landscape\n" }
  } else {
    $self->{pscomments} .= "\%\%Orientation: Portrait\n";
  }
  
# Clipping
  if ($self->{clip}) {
    $self->{psresources}{pageclip} = <<"EOP";
/pageclip {
  newpath
  $self->{bbx1} $self->{bby1} moveto
  $self->{bbx1} $self->{bby2} lineto
  $self->{bbx2} $self->{bby2} lineto
  $self->{bbx2} $self->{bby1} lineto
  $self->{bbx1} $self->{bby1} lineto
  closepath clip
} bind def
EOP
    if ($self->{eps}) { $self->{pssetup} .= "pageclip\n" }
  }

# Font reencoding
  if ($self->{reencode}) {
    my $encoding; # The name of the encoding
    my $ext;      # The extention to tack onto the std fontnames

    if (ref $self->{reencode} eq 'ARRAY') {
      die "Custom reencoding of fonts not really implemented yet, sorry...";
      $encoding = shift @{$self->{reencode}};
      $ext = shift @{$self->{reencode}};
      # TODO: Do something to add the actual encoding to the postscript code.
    } else {
      $encoding = $self->{reencode};
      $ext = '-iso';
    }

    $self->{psresources}{REENCODEFONT} = <<'EOP';
/STARTDIFFENC { mark } bind def
/ENDDIFFENC { 

% /NewEnc BaseEnc STARTDIFFENC number or glyphname ... ENDDIFFENC -
	counttomark 2 add -1 roll 256 array copy
	/TempEncode exch def

	% pointer for sequential encodings
	/EncodePointer 0 def
	{
		% Get the bottom object
		counttomark -1 roll
		% Is it a mark?
		dup type dup /marktype eq {
			% End of encoding
			pop pop exit
		} {
			/nametype eq {
			% Insert the name at EncodePointer 

			% and increment the pointer.
			TempEncode EncodePointer 3 -1 roll put
			/EncodePointer EncodePointer 1 add def
			} {
			% Set the EncodePointer to the number
			/EncodePointer exch def
			} ifelse
		} ifelse
	} loop

	TempEncode def
} bind def

% Define ISO Latin1 encoding if it doesnt exist
/ISOLatin1Encoding where {
%	(ISOLatin1 exists!) =
	pop
} {
	(ISOLatin1 does not exist, creating...) =
	/ISOLatin1Encoding StandardEncoding STARTDIFFENC
		144 /dotlessi /grave /acute /circumflex /tilde 
		/macron /breve /dotaccent /dieresis /.notdef /ring 
		/cedilla /.notdef /hungarumlaut /ogonek /caron /space 
		/exclamdown /cent /sterling /currency /yen /brokenbar 
		/section /dieresis /copyright /ordfeminine 
		/guillemotleft /logicalnot /hyphen /registered 
		/macron /degree /plusminus /twosuperior 
		/threesuperior /acute /mu /paragraph /periodcentered 
		/cedilla /onesuperior /ordmasculine /guillemotright 
		/onequarter /onehalf /threequarters /questiondown 
		/Agrave /Aacute /Acircumflex /Atilde /Adieresis 
		/Aring /AE /Ccedilla /Egrave /Eacute /Ecircumflex 
		/Edieresis /Igrave /Iacute /Icircumflex /Idieresis 
		/Eth /Ntilde /Ograve /Oacute /Ocircumflex /Otilde 
		/Odieresis /multiply /Oslash /Ugrave /Uacute 
		/Ucircumflex /Udieresis /Yacute /Thorn /germandbls 
		/agrave /aacute /acircumflex /atilde /adieresis 
		/aring /ae /ccedilla /egrave /eacute /ecircumflex 
		/edieresis /igrave /iacute /icircumflex /idieresis 
		/eth /ntilde /ograve /oacute /ocircumflex /otilde 
		/odieresis /divide /oslash /ugrave /uacute 
		/ucircumflex /udieresis /yacute /thorn /ydieresis
	ENDDIFFENC
} ifelse

% Name: Re-encode Font
% Description: Creates a new font using the named encoding. 

/REENCODEFONT { % /Newfont NewEncoding /Oldfont
	findfont dup length 4 add dict
	begin
		{ % forall
			1 index /FID ne 
			2 index /UniqueID ne and
			2 index /XUID ne and
			{ def } { pop pop } ifelse
		} forall
		/Encoding exch def
		% defs for DPS
		/BitmapWidths false def
		/ExactSize 0 def
		/InBetweenSize 0 def
		/TransformedChar 0 def
		currentdict
	end
	definefont pop
} bind def

% Reencode the std fonts: 
EOP

    for my $font (@fonts) {
      $self->{psresources}{REENCODEFONT} .= "/${font}$ext $encoding /$font REENCODEFONT\n";
    }
  }
}


#-------------------------------------------------------------------------------

=head1 OBJECT METHODS

Unless otherwise specified, object methods return 1 for success or 0 in some
error condition (e.g. insufficient arguments). Error message text is also
drawn on the page.

=over 4

=item C<newpage([number])>

Generates a new page on a PostScript file. If specified, C<number> gives the
number (or name) of the page. This method should not be used for EPS files.

The page number is automatically incremented each time this is called without
a new page number, or decremented if the current page number is negative.

Example:

    $p->newpage(1);
    $p->newpage;
    $p->newpage("hello");
    $p->newpage(-6);
    $p->newpage;

will generate five pages, numbered: 1, 2, "hello", -6, -7.

=cut

sub newpage
{
  my $self = shift;
  my $nextpage = shift;
  
  if (defined($nextpage)) { $self->{page} = $nextpage; }

  if ($self->{eps}) {
    # Cannot have multiple pages in an EPS file
    $self->_error("Do not use newpage for eps files!");
    return 0;
  }

  # close old page if required
  if ($self->{pspagecount} != 0) {
    $self->_closepage();
  }

  # start new page
  $self->_openpage();

  return 1;
}


sub _openpage
{
  my $self = shift;
  my ($x, $y);

  $self->{pspagecount}++;

  $self->{currentpage} = [];
  push @{$self->{pspages}}, $self->{currentpage};

  $self->_addtopage("\%\%Page: $self->{page} $self->{pspagecount}\n");

  if ($self->{page} >= 0) {    
    $self->{page} ++;
  } else {
    $self->{page} --;
  }

  $self->_addtopage("\%\%BeginPageSetup\n");
  $self->_addtopage("/pagelevel save def\n");

  if ($self->{landscape}) { $self->_addtopage("landscape\n"); }
  if ($self->{clip}) { $self->_addtopage("pageclip\n"); }

  ($x, $y) = @{$psorigin{$self->{coordorigin}}};
  $x = $self->{xsize} if ($x < 0);
  $y = $self->{ysize} if ($y < 0);
  $self->_addtopage("$x $y translate\n") if (($x != 0) || ($y != 0));
  $self->_addtopage("\%\%EndPageSetup\n");
}

sub _closepage
{
  my $self = shift;

  $self->_addtopage("\%\%PageTrailer\npagelevel restore\nshowpage\n");
}



#-------------------------------------------------------------------------------

=item C<output(filename)>

Writes the current PostScript out to the file named C<filename>. Will destroy
any existing file of the same name.

Use this method whenever output is required to disk. The current PostScript
document in memory is not cleared, and can still be extended.

=cut

sub _builddocument
{
  my $self = shift;
  my $title = shift;
  
  my $doc;
  my $date = scalar localtime;
  my $user;

  $title = 'undefined' unless $title;

  $doc = [];

# getlogin is unimplemented on some systems
  eval { $user = getlogin; };
  $user = 'Console' unless $user;

# Comments Section
  push @$doc, "%!PS-Adobe-3.0";
  push @$doc, " EPSF-1.2" if ($self->{eps});
  push @$doc, "\n";
  push @$doc, "\%\%Title: ($title)\n";
  push @$doc, "\%\%LanguageLevel: 1\n";
  push @$doc, "\%\%Creator: PostScript::Simple perl module version $VERSION\n";
  push @$doc, "\%\%CreationDate: $date\n";
  push @$doc, "\%\%For: $user\n";
  push @$doc, \$self->{pscomments};
#  push @$doc, "\%\%DocumentFonts: \n";
  if ($self->{eps}) {
    push @$doc, "\%\%BoundingBox: $self->{bbx1} $self->{bby1} $self->{bbx2} $self->{bby2}\n";
  } else {
    push @$doc, "\%\%Pages: $self->{pspagecount}\n";
  }
  push @$doc, "\%\%EndComments\n";
  
# Prolog Section
  push @$doc, "\%\%BeginProlog\n";
  push @$doc, "/ll 1 def systemdict /languagelevel known {\n";
  push @$doc, "/ll languagelevel def } if\n";
  push @$doc, \$self->{psprolog};
  foreach my $fn (sort keys %{$self->{psresources}}) {
    push @$doc, "\%\%BeginResource: PostScript::Simple-$fn\n";
    push @$doc, $self->{psresources}{$fn};
    push @$doc, "\%\%EndResource\n";
  }
  push @$doc, "\%\%EndProlog\n";

# Setup Section
  push @$doc, "\%\%BeginSetup\n";
  foreach my $un (sort keys %{$self->{usedunits}}) {
    push @$doc, $self->{usedunits}{$un} . "\n";
  }
  if ($self->{copies} > 1) {
    push @$doc, "/#copies " . $self->{copies} . " def\n";
  }
  push @$doc, \$self->{pssetup};
  push @$doc, "\%\%EndSetup\n";

# Pages
  if ((!$self->{eps}) && ($self->{pspagecount} > 0)) {
    $self->_closepage();
  }

  foreach my $page (@{$self->{pspages}}) {
    push @$doc, $self->_buildpage($page);
  }

# Trailer Section
  if (length($self->{pstrailer})) {
    push @$doc, "\%\%Trailer\n";
    push @$doc, \$self->{pstrailer};
  }
  push @$doc, "\%\%EOF\n";
  
  return $doc;
}

sub _buildpage
{
  my ($self, $page) = @_;

  my $data = "";

  foreach my $statement (@$page) {
    $data .= $$statement[1];
  }

  return $data;
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output
{
  my $self = shift;
  my $file = shift || die("Must supply a filename for output");
  my $page;
  my $i;
  
  $page = _builddocument($self, $file);

  local *OUT;
  open(OUT, '>', $file) or die("Cannot write to file $file: $!");

  foreach $i (@$page) {
    if (ref($i) eq "SCALAR") {
      print OUT $$i;
    } else {
      print OUT $i;
    }
  }

  close OUT;
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<get>

Returns the current document.

Use this method whenever output is required as a scalar. The current PostScript
document in memory is not cleared, and can still be extended.

=cut

sub get
{
  my $self = shift;
  my $page;
  my $i;
  my $doc;
  
  $page = _builddocument($self, "PostScript::Simple generated page");
  $doc = "";
  foreach $i (@$page) {
    if (ref($i) eq "SCALAR") {
      $doc .= $$i;
    } else {
      $doc .= $i;
    }
  }
  return $doc;
}


#-------------------------------------------------------------------------------

=item C<geteps>

Returns the current document as a PostScript::Simple::EPS object. Only works if
the current document is EPS.

This method calls new PostScript::Simple::EPS with all the default options. To
change these, call it yourself as below, rather than using this method.

  $eps = new PostScript::Simple::EPS(source => $ps->get);

=cut

sub geteps
{
  my $self = shift;
  my $page;
  my $i;
  my $doc;
  my $eps;
  
  croak "document is not EPS" unless ($$self{eps} == 1);

  $eps = new PostScript::Simple::EPS(source => $self->get);
  return $eps;
}


#-------------------------------------------------------------------------------

=item C<setcolour((red, green, blue)|(name))>

Sets the new drawing colour to the RGB values specified in C<red>, C<green> and
C<blue>. The values range from 0 to 255.

Alternatively, a colour name may be specified. Those currently defined are
listed at the top of the PostScript::Simple module in the C<%pscolours> hash
and include the standard X-Windows colour names.

Example:

    # set new colour to brown
    $p->setcolour(200,100,0);
    # set new colour to black
    $p->setcolour("black");

=cut

sub setcolour
{
  my $self = shift;
  my ($r, $g, $b) = @_;

  if ( @_ == 1 ) {
    $r = lc $r;
    if (defined $pscolours{$r}) {
      ($r, $g, $b) = @{$pscolours{$r}};
    } else {
      $self->_error( "bad colour name '$r'" );
      return 0;
    }
  }

  my $bad = 0;
  if (not defined $r) { $r = 'undef'; $bad = 1; }
  if (not defined $g) { $g = 'undef'; $bad = 1; }
  if (not defined $b) { $b = 'undef'; $bad = 1; }

  if ($bad) {
    $self->_error( "setcolour given invalid arguments: $r, $g, $b" );
    return 0;
  }

  # make sure floats aren't too long, and means the tests pass when
  # using a system with long doubles enabled by default
  $r = 0 + sprintf("%0.5f", $r / 255);
  $g = 0 + sprintf("%0.5f", $g / 255);
  $b = 0 + sprintf("%0.5f", $b / 255);

  if ($self->{colour}) {
    $self->_addtopage("$r $g $b setrgbcolor\n");
  } else {
    # Better colour->grey conversion than just 0.33 of each:
    $r = 0.3*$r + 0.59*$g + 0.11*$b;
    $r = 0 + sprintf("%0.5f", $r / 255);
    $self->_addtopage("$r setgray\n");
  }
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<setcmykcolour(cyan, magenta, yellow, black)>

Sets the new drawing colour to the CMYK values specified in C<cyan>,
C<magenta>, C<yellow} and C<black>. The values range from 0 to 1. Note that
PostScript::Simple does not do any colour management, so the output colour (as
also with C<setcolour>) may vary according to output device.

Example:

    # set new colour to a shade of blue
    $p->setcmykcolour(0.1, 0.5, 0, 0.2);
    # set new colour to black
    $p->setcmykcolour(0, 0, 0, 1);
    # set new colour to a rich black
    $p->setcmykcolour(0.5, 0.5, 0.5, 1);

=cut

sub setcmykcolour
{
  my $self = shift;
  my ($c, $m, $y, $k) = @_;

  if ( @_ != 4 ) {
    $self->_error( "setcmykcolour given incorrect number of arguments" );
    return 0;
  }

  # Don't currently convert to grey if colour is not set. Patches welcome for
  # something that gives a reasonable approximation...

  $self->_addtopage("$c $m $y $k setcmykcolor\n");
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<setlinewidth(width)>

Sets the new line width to C<width> units.

Example:

    # draw a line 10mm long and 4mm wide
    $p = new PostScript::Simple(units => "mm");
    $p->setlinewidth(4);
    $p->line(10,10, 20,10);

=cut

sub setlinewidth
{
  my $self = shift;
  my $width = shift || do {
    $self->_error( "setlinewidth not given a width" ); return 0;
  };

  $width = "0.4 bp" if $width eq "thin";

  $self->_addtopage($self->_u($width) . "setlinewidth\n");
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<line(x1,y1, x2,y2 [,red, green, blue])>

Draws a line from the co-ordinates (x1,x2) to (x2,y2). If values are specified
for C<red>, C<green> and C<blue>, then the colour is set before the line is drawn.

Example:

    # set the colour to black
    $p->setcolour("black");

    # draw a line in the current colour (black)
    $p->line(10,10, 10,20);
    
    # draw a line in red
    $p->line(20,10, 20,20, 255,0,0);

    # draw another line in red
    $p->line(30,10, 30,20);

=cut

sub line
{
  my $self = shift;
  my ($x1, $y1, $x2, $y2, $r, $g, $b) = @_;

  if ((!$self->{pspagecount}) and (!$self->{eps})) {
    # Cannot draw on to non-page when not an eps file
    return 0;
  }

  if ( @_ == 7 ) {
    $self->setcolour($r, $g, $b);
  } elsif ( @_ != 4 ) {
    $self->_error( "wrong number of args for line" );
    return 0;
  }
  
  $self->newpath;
  $self->moveto($x1, $y1);
  $self->_addtopage($self->_uxy($x2, $y2) . "lineto stroke\n");
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<linextend(x,y)>

Assuming the previous command was C<line>, C<linextend>, C<curve> or
C<curvextend>, extend that line to include another segment to the co-ordinates
(x,y). Behaviour after any other method is unspecified.

Example:

    $p->line(10,10, 10,20);
    $p->linextend(20,20);
    $p->linextend(20,10);
    $p->linextend(10,10);

Notes

The C<polygon> method may be more appropriate.

=cut

sub linextend
{
  my $self = shift;
  my ($x, $y) = @_;

  unless ( @_ == 2 ) {
    $self->_error( "wrong number of args for linextend" );
    return 0;
  }

  my $out = $self->_uxy($x, $y) . "lineto stroke\n";

  my $p = $self->{currentpage};
  my $last = pop @$p;
  $last = $$last[1];
  $last =~ s/eto stroke\n$/eto\n$out/;
  $self->_addtopage($last);

  # FIXMEFIXMEFIXME
  # perhaps we need something like $self->{_lastcommand} to know if operations
  # are valid, rather than using a regexp?

  return 1;
}


#-------------------------------------------------------------------------------

=item C<arc([options,] x,y, radius, start_angle, end_angle)>

Draws an arc on the circle of radius C<radius> with centre (C<x>,C<y>). The arc
starts at angle C<start_angle> and finishes at C<end_angle>. Angles are specified
in degrees, where 0 is at 3 o'clock, and the direction of travel is anti-clockwise.

Any options are passed in a hash reference as the first parameter. The available
option is:

=over 4

=item filled => 1

If C<filled> is 1 then the arc will be filled in.

=back

Example:

    # semi-circle
    $p->arc(10, 10, 5, 0, 180);

    # complete filled circle
    $p->arc({filled=>1}, 30, 30, 10, 0, 360);

=cut

sub arc
{
  my $self = shift;
  my %opt = ();

  if (ref($_[0])) {
    %opt = %{; shift};
  }

  if ((!$self->{pspagecount}) and (!$self->{eps})) {
    # Cannot draw on to non-page when not an eps file
    return 0;
  }

  my ($x, $y, $r, $sa, $ea) = @_;

  unless (@_ == 5) {
    $self->_error("arc: wrong number of arguments");
    return 0;
  }

  $self->newpath;
  $self->_addtopage($self->_uxy($x, $y) . $self->_u($r) . "$sa $ea arc ");
  if ($opt{'filled'}) {
    $self->_addtopage("fill\n");
  } else {
    $self->_addtopage("stroke\n");
  }
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<polygon([options,] x1,y1, x2,y2, ..., xn,yn)>

The C<polygon> method is multi-function, allowing many shapes to be created and
manipulated. Polygon draws lines from (x1,y1) to (x2,y2) and then from (x2,y2) to
(x3,y3) up to (xn-1,yn-1) to (xn,yn).

Any options are passed in a hash reference as the first parameter. The available
options are as follows:

=over 4

=item rotate => angle
=item rotate => [angle,x,y]

Rotate the polygon by C<angle> degrees anti-clockwise. If x and y are specified
then use the co-ordinate (x,y) as the centre of rotation, otherwise use the
co-ordinate (x1,y1) from the main polygon.

=item filled => 1

If C<filled> is 1 then the PostScript output is set to fill the object rather
than just draw the lines.

=item offset => [x,y]

Displace the object by the vector (x,y).

=back

Example:

    # draw a square with lower left point at (10,10)
    $p->polygon(10,10, 10,20, 20,20, 20,10, 10,10);

    # draw a filled square with lower left point at (20,20)
    $p->polygon( {offset => [10,10], filled => 1},
                10,10, 10,20, 20,20, 20,10, 10,10);

    # draw a filled square with lower left point at (10,10)
    # rotated 45 degrees (about the point (10,10))
    $p->polygon( {rotate => 45, filled => 1},
                10,10, 10,20, 20,20, 20,10, 10,10);

=cut

sub polygon
{
  my $self = shift;

  my %opt = ();
  my ($xoffset, $yoffset) = (0,0);
  my ($rotate, $rotatex, $rotatey) = (0,0,0);

  if ($#_ < 3) {
    # cannot have polygon with just one point...
    $self->_error( "bad polygon - not enough points" );
    return 0;
  }

  if (ref($_[0])) {
    %opt = %{; shift};
  }

  my $x = shift;
  my $y = shift;

  if (defined $opt{'rotate'}) {
    if (ref($opt{'rotate'})) {
      ($rotate, $rotatex, $rotatey) = @{$opt{'rotate'}};
    } else {
      ($rotate, $rotatex, $rotatey) = ($opt{'rotate'}, $x, $y);
    }
  }

  if (defined $opt{'offset'}) {
    if (ref($opt{'offset'})) {
      ($xoffset, $yoffset) = @{$opt{'offset'}};
    } else {
      $self->_error("polygon: bad offset option" );
      return 0;
    }
  }

  if (!defined $opt{'filled'}) {
    $opt{'filled'} = 0;
  }
  
  unless (defined($x) && defined($y)) {
    $self->_error("polygon: no start point");
    return 0;
  }

  my $savestate = ($xoffset || $yoffset || $rotate) ? 1 : 0 ;
  
  if ( $savestate ) {
    $self->_addtopage("gsave ");
  }

  if ($xoffset || $yoffset) {
    $self->_addtopage($self->_uxy($xoffset, $yoffset) . "translate\n");
  }

  if ($rotate) {
    unless (defined $self->{psresources}{rotabout}) {
      $self->{psresources}{rotabout} = <<'EOP';
/rotabout {
  3 copy pop translate rotate exch
  0 exch sub exch 0 exch sub translate
} def
EOP
    }

    $self->_addtopage($self->_uxy($rotatex, $rotatey) . "$rotate rotabout\n");
  }
  
  $self->newpath;
  $self->moveto($x, $y);
  
  while ($#_ > 0) {
    my $x = shift;
    my $y = shift;
    
    $self->_addtopage($self->_uxy($x, $y) . "lineto ");
  }

  if ($opt{'filled'}) {
    $self->_addtopage("fill\n");
  } else {
    $self->_addtopage("stroke\n");
  }

  if ( $savestate ) {
    $self->_addtopage("grestore\n");
  }
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<circle([options,] x,y, r)>

Plot a circle with centre at (x,y) and radius of r.

There is only one option.

=over 4

=item filled => 1

If C<filled> is 1 then the PostScript output is set to fill the object rather
than just draw the lines.

=back

Example:

    $p->circle(40,40, 20);
    $p->circle( {filled => 1}, 62,31, 15);

=cut

sub circle
{
  my $self = shift;
  my %opt = ();

  if (ref($_[0])) {
    %opt = %{; shift};
  }

  my ($x, $y, $r) = @_;

  unless (@_ == 3) {
    $self->_error("circle: wrong number of arguments");
    return 0;
  }

  unless (defined $self->{psresources}{circle}) {
    $self->{psresources}{circle} = "/circle {newpath 0 360 arc closepath} bind def\n";
  }

  $self->_addtopage($self->_uxy($x, $y) . $self->_u($r) . "circle ");
  if ($opt{'filled'}) {
    $self->_addtopage("fill\n");
  } else {
    $self->_addtopage("stroke\n");
  }
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<circletext([options,] x, y, r, a, text)>

Draw text in an arc centered about angle C<a> with circle midpoint (C<x>,C<y>)
and radius C<r>.

There is only one option.

=over 4

=item align => "alignment"

C<alignment> can be 'inside' or 'outside'. The default is 'inside'.

=back

Example:

    # outside the radius, centered at 90 degrees from the origin
    $p->circletext(40, 40, 20, 90, "Hello, Outside World!");
    # inside the radius centered at 270 degrees from the origin
    $p->circletext( {align => "inside"}, 40, 40, 20, 270, "Hello, Inside World!");

=cut

sub circletext
{
  my $self = shift;
  my %opt = ();

  if (ref($_[0])) {
    %opt = %{; shift};
  }

  my ($x, $y, $r, $a, $text) = @_;

  unless (@_ == 5) {
    $self->_error("circletext: wrong number of arguments");
    return 0;
  }

  unless (defined $self->{lastfontsize}) {
    $self->_error("circletext: must set font first");
    return 0;
  }

  unless (defined $self->{psresources}{circletext}) {
    $self->{psresources}{circletext} = <<'EOP';
/outsidecircletext
  { $circtextdict begin
      /radius exch def
      /centerangle exch def
      /ptsize exch def
      /str exch def
      /xradius radius ptsize 4 div add def
      gsave
        centerangle str findhalfangle add rotate
        str { /charcode exch def ( ) dup 0 charcode put outsideshowcharandrotate } forall
      grestore
    end
  } def
       
/insidecircletext
  { $circtextdict begin
      /radius exch def
      /centerangle exch def
      /ptsize exch def
      /str exch def
      /xradius radius ptsize 3 div sub def
      gsave
        centerangle str findhalfangle sub rotate
        str { /charcode exch def ( ) dup 0 charcode put insideshowcharandrotate } forall
      grestore
    end
  } def
/$circtextdict 16 dict def
$circtextdict begin
  /findhalfangle
    { stringwidth pop 2 div 2 xradius mul pi mul div 360 mul
    } def
  /outsideshowcharandrotate
    { /char exch def
      /halfangle char findhalfangle def
      gsave
        halfangle neg rotate radius 0 translate -90 rotate
        char stringwidth pop 2 div neg 0 moveto char show
      grestore
      halfangle 2 mul neg rotate
    } def
  /insideshowcharandrotate
    { /char exch def
      /halfangle char findhalfangle def
      gsave
        halfangle rotate radius 0 translate 90 rotate
        char stringwidth pop 2 div neg 0 moveto char show
      grestore
      halfangle 2 mul rotate
    } def
  /pi 3.1415926 def
end
EOP
  }

  $self->_addtopage("gsave\n");
  $self->_addtopage("  " . $self->_uxy($x, $y) . "translate\n");
  $self->_addtopage("  ($text) $self->{lastfontsize} $a " . $self->_u($r));
  if ($opt{'align'} && ($opt{'align'} eq "outside")) {
    $self->_addtopage("outsidecircletext\n");
  } else {
    $self->_addtopage("insidecircletext\n");
  }
  $self->_addtopage("grestore\n");
  
  return 1;
}


#-------------------------------------------------------------------------------

=item C<box(x1,y1, x2,y2 [, options])>

Draw a rectangle from lower left co-ordinates (x1,y1) to upper right
co-ordinates (y1,y2).

Options are:

=over 4

=item filled => 1

If C<filled> is 1 then fill the rectangle.

=back

Example:

    $p->box(10,10, 20,30);
    $p->box( {filled => 1}, 10,10, 20,30);

Notes

The C<polygon> method is far more flexible, but this method is quicker!

=cut

sub box
{
  my $self = shift;

  my %opt = ();

  if (ref($_[0])) {
    %opt = %{; shift};
  }

  my ($x1, $y1, $x2, $y2) = @_;

  unless (@_ == 4) {
    $self->_error("box: wrong number of arguments");
    return 0;
  }

  if (!defined($opt{'filled'})) {
    $opt{'filled'} = 0;
  }
  
  unless (defined $self->{psresources}{box}) {
    $self->{psresources}{box} = <<'EOP';
/box {
  newpath 3 copy pop exch 4 copy pop pop
  8 copy pop pop pop pop exch pop exch
  3 copy pop pop exch moveto lineto
  lineto lineto pop pop pop pop closepath
} bind def
EOP
  }

  $self->_addtopage($self->_uxy($x1, $y1));
  $self->_addtopage($self->_uxy($x2, $y2) . "box ");
  if ($opt{'filled'}) {
    $self->_addtopage("fill\n");
  } else {
    $self->_addtopage("stroke\n");
  }

  return 1;
}


#-------------------------------------------------------------------------------

=item C<setfont(font, size)>

Set the current font to the PostScript font C<font>. Set the size in PostScript
points to C<size>.

Notes

This method must be called on every page before the C<text> method is used.

=cut

sub setfont
{
  my $self = shift;
  my ($name, $size, $ysize) = @_;

  unless (@_ == 2) {
    $self->_error( "wrong number of arguments for setfont" );
    return 0;
  }

# set font y size XXXXX
  $self->_addtopage("/$name findfont $size scalefont setfont\n");

  $self->{lastfontsize} = $size;

  return 1;
}


#-------------------------------------------------------------------------------

=item C<text([options,] x,y, string)>

Plot text on the current page with the lower left co-ordinates at (x,y) and 
using the current font. The text is specified in C<string>.

Options are:

=over 4

=item align => "alignment"

alignment can be 'left', 'centre' or 'right'. The default is 'left'.

=item rotate => angle

"rotate" degrees of rotation, defaults to 0 (i.e. no rotation).
The angle to rotate the text, in degrees. Centres about (x,y) and rotates
clockwise. (?). Default 0 degrees.

=back

Example:

    $p->setfont("Times-Roman", 12);
    $p->text(40,40, "The frog sat on the leaf in the pond.");
    $p->text( {align => 'centre'}, 140,40, "This is centered.");
    $p->text( {rotate => 90}, 140,40, "This is rotated.");
    $p->text( {rotate => 90, align => 'centre'}, 140,40, "This is both.");

=cut

sub text
{
  my $self = shift;

  my $rot = "";
  my $rot_m = "";
  my $align = "";
  my %opt = ();

  if (ref($_[0])) {
    %opt = %{; shift};
  }
  
  unless ( @_ == 3 )
  { # check required params first
    $self->_error("text: wrong number of arguments");
    return 0;
  }
  
  my ($x, $y, $text) = @_;

  unless (defined($x) && defined($y) && defined($text)) {
    $self->_error("text: wrong number of arguments");
    return 0;
  }
  
  # Escape text to allow parentheses
  $text =~ s|([\\\(\)])|\\$1|g;
  $text =~ s/([\x00-\x1f\x7f-\xff])/sprintf('\\%03o',ord($1))/ge;

  $self->newpath;
  $self->moveto($x, $y);

  # rotation

  if (defined $opt{'rotate'}) {
    my $rot_a = $opt{ 'rotate' };
    if( $rot_a != 0 ) {
      $rot   = " $rot_a rotate ";
      $rot_a = -$rot_a;
      $rot_m = " $rot_a rotate ";
    };
  }

  # alignment

  $align = " show stroke"; 
  if (defined $opt{'align'}) {
    $align = " dup stringwidth pop neg 0 rmoveto show" 
        if $opt{ 'align' } eq 'right';
    $align = " dup stringwidth pop 2 div neg 0 rmoveto show"
        if $opt{ 'align' } eq 'center' or $opt{ 'align' } eq 'centre';
  }
  
  $self->_addtopage("($text) $rot $align $rot_m\n");

  return 1;
}


#-------------------------------------------------------------------------------

=item curve( x1, y1, x2, y2, x3, y3, x4, y4 )

Create a curve from (x1, y1) to (x4, y4). (x2, y2) and (x3, y3) are the
control points for the start- and end-points respectively.

=cut

sub curve
{
  my $self = shift;
  my ($x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4) = @_;

  unless ( @_ == 8 ) {
    $self->_error( "bad curve definition, wrong number of args" );
    return 0;
  }
  
  if ((!$self->{pspagecount}) and (!$self->{eps})) {
    # Cannot draw on to non-page when not an eps file
    return 0;
  }

  $self->newpath;
  $self->moveto($x1, $y1);
  $self->_addtopage($self->_uxy($x2, $y2));
  $self->_addtopage($self->_uxy($x3, $y3));
  $self->_addtopage($self->_uxy($x4, $y4) . "curveto stroke\n");

  return 1;
}


#-------------------------------------------------------------------------------

=item curvextend( x1, y1, x2, y2, x3, y3 )

Assuming the previous command was C<line>, C<linextend>, C<curve> or
C<curvextend>, extend that path with another curve segment to the co-ordinates
(x3, y3). (x1, y1) and (x2, y2) are the control points.  Behaviour after any
other method is unspecified.

=cut

sub curvextend
{
  my $self = shift;
  my ($x1, $y1, $x2, $y2, $x3, $y3) = @_;

  unless ( @_ == 6 ) {
    $self->_error( "bad curvextend definition, wrong number of args" );
    return 0;
  }
  
  my $out = $self->_uxy($x1, $y1);
  $out .= $self->_uxy($x2, $y2);
  $out .= $self->_uxy($x3, $y3) . "curveto stroke\n";

  # FIXMEFIXMEFIXME
  # curveto may follow a lineto etc...
  my $p = $self->{currentpage};
  my $last = pop @$p;
  $last = $$last[1];
  $last =~ s/eto stroke\n$/eto\n$out/;
  $self->_addtopage($last);
  
  return 1;
}


#-------------------------------------------------------------------------------

=item newpath

This method is used internally to begin a new drawing path - you should
generally NEVER use it.

=cut

sub newpath
{
  my $self = shift;

  $self->_addtopage("newpath\n");

  return 1;
}


#-------------------------------------------------------------------------------

=item moveto( x, y )

This method is used internally to move the cursor to a new point at (x, y) -
you will generally NEVER use this method.

=cut

sub moveto
{
  my $self = shift;
  my ($x, $y) = @_;

  $self->_addtopage($self->_uxy($x, $y) . "moveto\n");

  return 1;
}


#-------------------------------------------------------------------------------

=item C<importepsfile([options,] filename, x1,y1, x2,y2)>

Imports an EPS file and scales/translates its bounding box to fill
the area defined by lower left co-ordinates (x1,y1) and upper right
co-ordinates (x2,y2). By default, if the co-ordinates have a different
aspect ratio from the bounding box, the scaling is constrained on the
greater dimension to keep the EPS fully inside the area.

Options are:

=over 4

=item overlap => 1

If C<overlap> is 1 then the scaling is calculated on the lesser dimension
and the EPS can overlap the area.

=item stretch => 1

If C<stretch> is 1 then fill the entire area, ignoring the aspect ratio.
This option overrides C<overlap> if both are given.

=back

Example:

    # Assume smiley.eps is a round smiley face in a square bounding box

    # Scale it to a (10,10)(20,20) box
    $p->importepsfile("smiley.eps", 10,10, 20,20);

    # Keeps aspect ratio, constrained to smallest fit
    $p->importepsfile("smiley.eps", 10,10, 30,20);

    # Keeps aspect ratio, allowed to overlap for largest fit
    $p->importepsfile( {overlap => 1}, "smiley.eps", 10,10, 30,20);

    # Aspect ratio is changed to give exact fit
    $p->importepsfile( {stretch => 1}, "smiley.eps", 10,10, 30,20);

=cut

sub importepsfile
{
  my $self = shift;

  my $bbllx;
  my $bblly;
  my $bburx;
  my $bbury;
  my $bbw;
  my $bbh;
  my $pagew;
  my $pageh;
  my $scalex;
  my $scaley;
  my $line;
  my $eps;

  my %opt = ();

  if (ref($_[0])) {
    %opt = %{; shift};
  }

  my ($file, $x1, $y1, $x2, $y2) = @_;

  unless (@_ == 5) {
    $self->_error("importepsfile: wrong number of arguments");
    return 0;
  }

  $opt{'overlap'} = 0 if (!defined($opt{'overlap'}));
  $opt{'stretch'} = 0 if (!defined($opt{'stretch'}));
  
  $eps = new PostScript::Simple::EPS(file => $file);
  ($bbllx, $bblly, $bburx, $bbury) = $eps->get_bbox();

  $pagew = $x2 - $x1;
  $pageh = $y2 - $y1;

  $bbw = $bburx - $bbllx;
  $bbh = $bbury - $bblly;

  if (($bbw == 0) || ($bbh == 0)) {
    $self->_error("importeps: Bounding Box has zero dimension");
    return 0;
  }

  $scalex = $pagew / $bbw;
  $scaley = $pageh / $bbh;

  if ($opt{'stretch'} == 0) {
    if ($opt{'overlap'} == 0) {
      if ($scalex > $scaley) {
        $scalex = $scaley;
      } else {
        $scaley = $scalex;
      }
    } else {
      if ($scalex > $scaley) {
        $scaley = $scalex;
      } else {
        $scalex = $scaley;
      }
    }
  }

  $eps->scale($scalex, $scaley);
  $eps->translate(-$bbllx, -$bblly);
  $self->_add_eps($eps, $x1, $y1);

  return 1;
}


#-------------------------------------------------------------------------------

=item C<importeps(filename, x,y)>

Imports a PostScript::Simple::EPS object into the current document at position
C<(x,y)>.

Example:

    use PostScript::Simple;
    
    # create a new PostScript object
    $p = new PostScript::Simple(papersize => "A4",
                                colour => 1,
                                units => "in");
    
    # create a new page
    $p->newpage;
    
    # create an eps object
    $e = new PostScript::Simple::EPS(file => "test.eps");
    $e->rotate(90);
    $e->scale(0.5);

    # add eps to the current page
    $p->importeps($e, 10,50);

=cut

sub importeps
{
  my $self = shift;
  my ($epsobj, $xpos, $ypos) = @_;

  unless (@_ == 3) {
    $self->_error("importeps: wrong number of arguments");
    return 0;
  }

  $self->_add_eps($epsobj, $xpos, $ypos);

  return 1;
}


#-------------------------------------------------------------------------------

=item C<err()>

Returns the last error generated.

Example:

  unless ($ps->setcolour("purplewithyellowspots")) {
    print $ps->err();
  }

  # prints "bad colour name 'purplewithyellowspots'";

=cut

sub err {
  my $self = shift;

  return $self->{lasterror};
}


################################################################################
# PRIVATE methods

sub _addtopage
{
  my ($self, $data) = @_;

  if (defined $self->{currentpage}) {
    push @{$self->{currentpage}}, ["ps", $data];
  } else {
    confess "internal page error";
  }
}


#-------------------------------------------------------------------------------

sub _add_eps
{
  my $self = shift;
  my $epsobj;
  my $xpos;
  my $ypos;

  if (ref($_[0]) ne "PostScript::Simple::EPS") {
    croak "internal error: _add_eps[0] must be eps object";
  }

  if ((!$self->{pspagecount}) and (!$self->{eps})) {
    # Cannot draw on to non-page when not an eps file
    $self->_error("importeps: no current page");
    return 0;
  }

  if ( @_ != 3 ) {
    croak "internal error: wrong number of arguments for _add_eps";
    return 0;
  }

  unless (defined $self->{psresources}{importeps}) {
    $self->{psresources}{importeps} = <<'EOP';
/BeginEPSF { /b4_Inc_state save def /dict_count countdictstack def
/op_count count 1 sub def userdict begin /showpage { } def 0 setgray
0 setlinecap 1 setlinewidth 0 setlinejoin 10 setmiterlimit [ ]
0 setdash newpath /languagelevel where { pop languagelevel 1 ne {
false setstrokeadjust false setoverprint } if } if } bind def
/EndEPSF { count op_count sub {pop} repeat countdictstack dict_count
sub {end} repeat b4_Inc_state restore } bind def
EOP
  }

  ($epsobj, $xpos, $ypos) = @_;

  my $eps = "BeginEPSF\n";
  $eps .= $self->_uxy($xpos, $ypos) . "translate\n";
  $eps .= $self->_uxy(1, 1) . "scale\n";
  $eps .= $epsobj->_get_include_data($xpos, $ypos);
  $eps .= "EndEPSF\n";

  $self->_addtopage($eps);
  
  return 1;
}


#-------------------------------------------------------------------------------

sub _error {
  my $self = shift;
  my $msg = shift;

  $self->{lasterror} = $msg;
  $self->_addtopage("(error: $msg\n) print flush\n");
}


#-------------------------------------------------------------------------------

# Display method for debugging internal variables
#
#sub display {
#  my $self = shift;
#  my $i;
#
#  foreach $i (keys(%{$self}))
#  {
#    print "$i = $self->{$i}\n";
#  }
#}

=back

=head1 BUGS

Some current functionality may not be as expected, and/or may not work correctly.
That's the fun with using code in development!

=head1 AUTHOR

The PostScript::Simple module was created by Matthew Newton, with ideas
and suggestions from Mark Withall and many other people from around the world.
Thanks!

Please see the README file in the distribution for more information about
contributors.

Copyright (C) 2002-2014 Matthew C. Newton

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, version 2.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details,
available at http://www.gnu.org/licenses/gpl.html.

=head1 SEE ALSO

L<PostScript::Simple::EPS>

=cut

1;

# vim:foldmethod=marker:
