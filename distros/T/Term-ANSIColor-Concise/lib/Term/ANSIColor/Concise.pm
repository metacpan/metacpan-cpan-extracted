package Term::ANSIColor::Concise;

our $VERSION = "2.0201";

use v5.14;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(
    ansi_color ansi_color_24 ansi_code ansi_pair csi_code
    cached_ansi_color
    map_256_to_6 map_to_256
    );
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

use Carp;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Term::ANSIColor::Concise::Util;
use List::Util qw(min max first);

our $NO_NO_COLOR //= $ENV{ANSICOLOR_NO_NO_COLOR};
our $NO_COLOR    //= !$NO_NO_COLOR && defined $ENV{NO_COLOR};
our $RGB24       //= $ENV{ANSICOLOR_RGB24} // ($ENV{COLORTERM}//'' eq 'truecolor');
our $LINEAR_256  //= $ENV{ANSICOLOR_LINEAR_256};
our $LINEAR_GRAY //= $ENV{ANSICOLOR_LINEAR_GRAY};
our $NO_RESET_EL //= $ENV{ANSICOLOR_NO_RESET_EL};
our $SPLIT_ANSI  //= $ENV{ANSICOLOR_SPLIT_ANSI};

my @nonlinear = do {
    map { ( $_->[0] ) x $_->[1] } (
	[ 0, 75 ], #   0 ..  74
	[ 1, 40 ], #  75 .. 114
	[ 2, 40 ], # 115 .. 154
	[ 3, 40 ], # 155 .. 194
	[ 4, 40 ], # 195 .. 234
	[ 5, 21 ], # 235 .. 255
    );
};

sub map_256_to_6 {
    use integer;
    my $i = shift;
    if ($LINEAR_256) {
	5 * $i / 255;
    } else {
	# ( $i - 35 ) / 40;
	$nonlinear[$i];
    }
}

sub map_to_256 {
    my($base, $i) = @_;
    if    ($i == 0)     { 0 }
    elsif ($base ==  6) { $i * 40 + 55 }
    elsif ($base == 12) { $i * 20 + 35 }
    elsif ($base == 24) { $i * 10 + 25 }
    else  { die }
}

sub ansi256_number {
    my $code = shift;
    my($r, $g, $b, $gray);
    if ($code =~ /^([0-5])([0-5])([0-5])$/) {
	($r, $g, $b) = ($1, $2, $3);
    }
    elsif (my($n) = $code =~ /^L(\d+)/i) {
	$n > 25 and croak "Color spec error: $code.";
	if ($n == 0 or $n == 25) {
	    $r = $g = $b = $n / 5;
	} else {
	    $gray = $n - 1;
	}
    }
    else {
	croak "Color spec error: $code.";
    }
    defined $gray ? ($gray + 232) : ($r*36 + $g*6 + $b + 16);
}

sub rgb24_number {
    use integer;
    my($rx, $gx, $bx) = @_;
    my($r, $g, $b, $gray);
    if ($rx != 0 and $rx != 255 and $rx == $gx and $rx == $bx) {
	if ($LINEAR_GRAY) {
	    ##
	    ## Divide area into 25 segments, and map to BLACK and 24 GRAYS
	    ##
	    $gray = $rx * 25 / 255 - 1;
	    if ($gray < 0) {
		$r = $g = $b = 0;
		$gray = undef;
	    }
	} else {
	    ## map to 8, 18, 28, ... 238
	    $gray = min(23, ($rx - 3) / 10);
	}
    } else {
	($r, $g, $b) = map { map_256_to_6 $_ } $rx, $gx, $bx;
    }
    defined $gray ? ($gray + 232) : ($r*36 + $g*6 + $b + 16);
}

sub rgbhex {
    my $rgb = shift =~ s/^#//r;
    my $len = length $rgb;
    croak "$rgb: Invalid RGB value." if $len == 0 || $len % 3;
    $len /= 3;
    my $max = (2 ** ($len * 4)) - 1;
    my @rgb24 = map { hex($_) * 255 / $max } $rgb =~ /[0-9a-z]{$len}/gi or die;
    if ($RGB24) {
	return (2, @rgb24);
    } else {
	return (5, rgb24_number @rgb24);
    }
}

my %numbers = (
    ';' => undef,	# ; : NOP
    N   => undef,	# N : None (NOP)
    E => 'EL',		# E : Erase Line
    Z => 0,		# Z : Zero (Reset)
    D => 1,		# D : Double Strike (Bold)
    P => 2,		# P : Pale (Dark)
    I => 3,		# I : Italic
    U => 4,		# U : Underline
    F => 5,		# F : Flash (Blink: Slow)
    Q => 6,		# Q : Quick (Blink: Rapid)
    S => 7,		# S : Stand out (Reverse)
    H => 8,		# H : Hide (Concealed)
    X => 9,		# X : Cross out
    K => 30, k => 90,	# K : Kuro (Black)
    R => 31, r => 91,	# R : Red  
    G => 32, g => 92,	# G : Green
    Y => 33, y => 93,	# Y : Yellow
    B => 34, b => 94,	# B : Blue 
    M => 35, m => 95,	# M : Magenta
    C => 36, c => 96,	# C : Cyan 
    W => 37, w => 97,	# W : White
    );

my $colorspec_re = qr{
      (?<toggle> /)			 # /
    | (?<reset> \^)			 # ^
    | (?<hex>	 [0-9a-f]{6}		 # 24bit hex
	     | \#[0-9a-f]{3,} )		 # generic hex
    | (?<rgb>  \(\d+,\d+,\d+\) )	 # 24bit decimal
    | (?<c256>	 [0-5][0-5][0-5]	 # 216 (6x6x6) colors
	     | L(?:[01][0-9]|[2][0-5]) ) # 24 gray levels + B/W
    | (?<c16>  [KRGYBMCW] )		 # 16 colors
    | (?<efct> ~?[;NZDPIUFQSHX] )	 # effects
    | (?<csi>  { (?<csi_name>[A-Z]+)	 # other CSI
		 (?<P> \( )?		 # optional (
		 (?<csi_param>[\d,;]*)	 # 0;1;2
		 (?(<P>) \) )		 # closing )
	       }
	     | (?<csi_abbr>[E]) )	 # abbreviation
    | < (?<name> \w+ ) >		 # <colorname>
}xi;

sub ansi_numbers {
    local $_ = shift // '';
    my @numbers;
    my $toggle = ToggleValue->new(value => 10);

    while (m{\G (?: $colorspec_re | (?<err> .+ ) ) }xig) {
	if ($+{toggle}) {
	    $toggle->toggle;
	}
	elsif ($+{reset}) {
	    $toggle->reset;
	}
	elsif ($+{hex}) {
	    push @numbers, 38 + $toggle->value, rgbhex($+{hex});
	}
	elsif (my $rgb = $+{rgb}) {
	    my @rgb = $rgb =~ /(\d+)/g;
	    croak "Unexpected value: $rgb." if grep { $_ > 255 } @rgb;
	    my $hex = sprintf "%02X%02X%02X", @rgb;
	    push @numbers, 38 + $toggle->value, rgbhex($hex);
	}
	elsif ($+{c256}) {
	    push @numbers, 38 + $toggle->value, 5, ansi256_number $+{c256};
	}
	elsif ($+{c16}) {
	    push @numbers, $numbers{$+{c16}} + $toggle->value;
	}
	elsif ($+{efct}) {
	    my $efct = uc $+{efct};
	    my $offset = $efct =~ s/^~// ? 20 : 0;
	    if (defined (my $n = $numbers{$efct})) {
		push @numbers, $n + $offset;
	    }
	}
	elsif ($+{csi}) {
	    push @numbers, do {
		if ($+{csi_abbr}) {
		    [ $numbers{uc $+{csi_abbr}} ];
		} else {
		    [ uc $+{csi_name}, $+{csi_param} =~ /\d+/g ];
		}
	    };
	}
	elsif ($+{name}) {
	    state $colornames = do {
		require Graphics::ColorNames;
		Graphics::ColorNames->new;
	    };
	    if (my $rgb = $colornames->hex($+{name})) {
		push @numbers, 38 + $toggle->value, rgbhex($rgb);
	    } else {
		croak "Unknown color name: $+{name}.";
	    }
	}
	elsif (my $err = $+{err}) {
	    croak "Color spec error: \"$err\" in \"$_\"."
	}
	else {
	    croak "$_: Something strange.";
	}
    } continue {
	if ($SPLIT_ANSI) {
	    my $index = first { not ref $numbers[$_] } 0 .. $#numbers;
	    if (defined $index) {
		my @sgr = splice @numbers, $index;
		push @numbers, [ 'SGR', @sgr ];
	    }
	}
    }
    @numbers;
}

use constant {
    CSI   => "\e[",	# Control Sequence Introducer
    RESET => "\e[m",	# SGR Reset
    EL    => "\e[K",	# Erase Line
};

my %csi_terminator = (
    CUU => 'A',	 # Cursor up
    CUD => 'B',	 # Cursor Down
    CUF => 'C',	 # Cursor Forward
    CUB => 'D',	 # Cursor Back
    CNL => 'E',	 # Cursor Next Line
    CPL => 'F',	 # Cursor Previous line
    CHA => 'G',	 # Cursor Horizontal Absolute
    CUP => 'H',	 # Cursor Position
    ED  => 'J',	 # Erase in Display (0 after, 1 before, 2 entire, 3 w/buffer)
    EL  => 'K',	 # Erase in Line (0 after, 1 before, 2 entire)
    SU  => 'S',	 # Scroll Up
    SD  => 'T',	 # Scroll Down
    HVP => 'f',	 # Horizontal Vertical Position
    SGR => 'm',	 # Select Graphic Rendition
    SCP => 's',	 # Save Cursor Position
    RCP => 'u',	 # Restore Cursor Position
    );

my %other_sequence = (
    RIS   => "\ec",  # Reset to Initial State
    DECSC => "\e7",  # DEC Save Cursor
    DECRC => "\e8",  # DEC Restore Cursor
    );

sub csi_code {
    my $name = shift;
    if (my $seq = $other_sequence{$name}) {
	return $seq;
    }
    my $c = $csi_terminator{$name} or do {
	warn "$name: Unknown ANSI name.\n";
	return '';
    };
    if ($name eq 'SGR' and @_ == 1 and $_[0] == 0) {
	@_ = ();
    }
    CSI . join(';', @_) . $c;
}

sub ansi_code {
    my $spec = shift;
    my @numbers = ansi_numbers $spec;
    my @code;
    while (@numbers) {
	my $item = shift @numbers;
	if (ref($item) eq 'ARRAY') {
	    push @code, csi_code @$item;
	} else {
	    my @sgr = ($item);
	    while (@numbers and not ref $numbers[0]) {
		push @sgr, shift @numbers;
	    }
	    push @code, csi_code 'SGR', @sgr;
	}
    }
    join '', @code;
}

sub ansi_pair {
    my $spec = shift;
    my $el = 0;
    my $start = ansi_code $spec // '';
    my $end = $start eq '' ? '' : do {
	if ($start =~ /(.*)(\e\[[0;]*K)(.*)/) {
	    $el = 1;
	    if ($3) {
		$1 . EL . RESET;
	    } else {
		EL . RESET;
	    }
	} else {
	    if ($NO_RESET_EL) {
		RESET;
	    } else {
		RESET . EL;
	    }
	}
    };
    ($start, $end, $el);
}

sub ansi_color {
    cached_ansi_color(state $cache = {}, @_);
}

sub ansi_color_24 {
    local $RGB24 = 1;
    cached_ansi_color(state $cache = {}, @_);
}

sub cached_ansi_color {
    my $cache = shift;
    my @result;
    while (@_ >= 2) {
	my($spec, $text) = splice @_, 0, 2;
	for my $color (ref $spec eq 'ARRAY' ? @$spec : $spec) {
	    $text = apply_color($cache, $color, $text);
	}
	push @result, $text;
    }
    croak "Wrong number of parameters." if @_;
    join '', @result;
}

use Scalar::Util qw(blessed);

sub apply_color {
    my($cache, $color, $text) = @_;
    if (ref $color eq 'CODE') {
	return $color->($text);
    }
    elsif (blessed $color and $color->can('call')) {
	return $color->call for $text;
    }
    elsif ($NO_COLOR) {
        return $text;
    }
    else {
	my($s, $e, $el) = @{ $cache->{$color} //= [ ansi_pair($color) ] };
	state $reset = qr{ \e\[[0;]*m (?: \e\[[0;]*[Km] )* }x;
	if ($el) {
	    $text =~ s/(\A|(?<=[\r\n])|$reset)([^\e\r\n]*)/${1}${s}${2}${e}/mg;
	} else {
	    $text =~ s/(\A|(?<=[\r\n])|$reset)([^\e\r\n]+)/${1}${s}${2}${e}/mg;
	}
	return $text;
    }
}

1;

__END__


=head1 NAME

Term::ANSIColor::Concise - Produce ANSI terminal sequence by concise notation


=head1 SYNOPSIS

  use v5.14;
  use Term::ANSIColor::Concise qw(ansi_color);

  say ansi_color('R', 'This is Red');

  say ansi_color('SDG', 'This is Reverse Bold Green');

  say ansi_color('FUDI<Gold>/L10E',
                 'Flashing Underlined Bold Italic Gold on Gray10 Bar');

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/synopsis.png">

=end html


=head1 VERSION

Version 2.0201


=head1 DESCRIPTION

This module provides a simple concise format to describe complicated
colors and effects for ANSI terminals.  These notations are supposed to
be used in command line option parameters.

This module used to be a part of L<Getopt::EX::Colormap> module, which
provide easy handling interface for command line options.

=head2 256 or 24bit COLORS

By default, this library produces ANSI 256 color sequence.  That is
eight standard colors, eight high intensity colors, 6x6x6 216 colors,
and gray scales in 24 steps.

Color described by 12bit/24bit RGB values are converted to 6x6x6 216
colors, or 24 gray scales if all RGB values are same.

For a terminal which can display 24bit colors, full-color sequence can
be produced.  See L</ENVIRONMENT> section.


=head1 FUNCTION

=over 4

=item B<ansi_color>(I<spec>, I<text>)

Return colorized version of given text.  Produces 256 or 24bit colors
depending on the setting.

In the result, given I<text> is enclosed by appropriate open/close
sequences.  Close sequence can vary according to the open sequence.
See L</RESET SEQUENCE> section.

If the I<text> already includes colored regions, they remain untouched
and only non-colored parts are colored.

Actually, I<spec> and I<text> pair can be repeated as many as
possible.  It is same as calling the function multiple times with
single pair and join results.

=item B<ansi_color>([ I<spec1>, I<spec2>, ... ], I<text>)

If I<spec> parameter is ARRAYREF, multiple I<spec>s can be specified
at once.  This is not useful for color spec because they can be simply
joined, but may be useful when mixed with L</FUNCTION SPEC>.

=item B<ansi_color_24>(I<spec>, I<text>)

=item B<ansi_color_24>([ I<spec1>, I<spec2>, ... ], I<text>)

Function B<ansi_color_24> always produces 24bit color sequence for
12bit/24bit color spec.

=item B<cached_ansi_color>(I<cache>, I<spec>, I<text>)

Backend interface for B<ansi_color>.  First parameter is a hash object
used to cache data.  If you concern about cache mismatch situation,
use this interface with original cache.

=item B<ansi_pair>(I<color_spec>)

Produces introducer and recover sequences for given spec.

Additional third value indicates if the introducer includes Erase Line
sequence.  It gives a hint the sequence is necessary for empty string.
See L</RESET SEQUENCE>.

=item B<ansi_code>(I<color_spec>)

Produces introducer sequence for given spec.  Reset code can be taken
by B<ansi_code("Z")>.

=item B<csi_code>(I<name>, I<params>)

Produce CSI (Control Sequence Introducer) sequence by name with
numeric parameters.  Parameter I<name> is one of standard (CUU, CUD,
CUF, CUB, CNL, CPL, CHA, CUP, ED, EL, SU, SD, HVP, SGR, SCP, RCP) or
non-standard (RIS, DECSC, DECRC).

=back


=head1 COLOR SPEC

At first the color is considered as foreground, and slash (C</>)
switches foreground and background.  You can declare any number of
components in arbitrary order, and sequences will be produced in the
order of their presence.  So if they conflicts, the later one
overrides the earlier.

Color specification is a combination of following components:

=head2 BASIC 8+8

Single uppercase character representing 8 colors, and alternative
(usually brighter) colors in lowercase :

    R  r  Red
    G  g  Green
    B  b  Blue
    C  c  Cyan
    M  m  Magenta
    Y  y  Yellow
    K  k  Black
    W  w  White

=head2 EFFECTS and CONTROLS

Single case-insensitive character for special effects :

    N    None
    Z  0 Zero (reset)
    D  1 Double strike (boldface)
    P  2 Pale (dark)
    I  3 Italic
    U  4 Underline
    F  5 Flash (blink: slow)
    Q  6 Quick (blink: rapid)
    S  7 Stand out (reverse video)
    H  8 Hide (conceal)
    X  9 Cross out

    E    Erase Line (fill by background color)

    ;    No effect
    /    Toggle foreground/background
    ^    Reset to foreground
    ~    Cancel following effect

Tilde (C<~>) negates following effect; C<~S> reset the effect of C<S>.
There is a discussion about negation of C<D> (Track Wikipedia link in
SEE ALSO), and Apple_Terminal (v2.10 433) does not reset at least.

Single C<E> is an abbreviation for C<{EL}> (Erase Line).  This is
different from other attributes, but have an effect of painting the
rest of line by background color.

=head2 6x6x6 216 COLORS

Combination of 0..5 for 216 RGB values :

    Deep          Light
    <----------------->
    000 111 222 333 444 : Black
    500 511 522 533 544 : Red
    050 151 252 353 454 : Green
    005 115 225 335 445 : Blue
    055 155 255 355 455 : Cyan
    505 515 525 535 545 : Magenta
    550 551 552 553 554 : Yellow
    555 444 333 222 111 : White

=head2 24 GRAY SCALES + 2

24 gray scales are described by C<L01> (dark) to C<L24> (bright).
Black and White can be described as C<L00> and C<L25>, those are
aliases for C<000> and C<555>.

    L00 : Level  0 (Black)
    L01 : Level  1
     :
    L24 : Level 24
    L25 : Level 25 (White)

=head2 RGB

12bit/24bit RGB :

    (255,255,255)      : 24bit decimal RGB colors
    #000000 .. #FFFFFF : 24bit hex RGB colors
    #000    .. #FFF    : 12bit hex RGB 4096 colors

=over 4

Beginning C<#> can be omitted in 24bit hex RGB notation.  So 6
consecutive digits means 24bit color, and 3 digits means 6x6x6 color,
if they do not begin with C<#>.

=back

=head2 COLOR NAMES

Color names enclosed by angle bracket :

    <red> <blue> <green> <cyan> <magenta> <yellow>
    <aliceblue> <honeydew> <hotpink> <moccasin>
    <medium_aqua_marine>

These colors are defined in 24bit RGB.  Names are case insensitive and
underscore (C<_>) is ignored, but space and punctuation are not
allowed.  So C<< <aliceblue> >>, C<< <AliceBlue> >>, C<< <ALICE_BLUE>
>> are all valid but C<< <Alice Blue> >> is not.  See L</COLOR NAMES>
section for detail.

=head2 CSI SEQUENCES and OTHERS

Native CSI (Control Sequence Introducer) sequences in the form of
C<{NAME}>.

    CUU n   Cursor up
    CUD n   Cursor Down
    CUF n   Cursor Forward
    CUB n   Cursor Back
    CNL n   Cursor Next Line
    CPL n   Cursor Previous line
    CHA n   Cursor Horizontal Absolute
    CUP n,m Cursor Position
    ED  n   Erase in Display (0 after, 1 before, 2 entire, 3 w/buffer)
    EL  n   Erase in Line (0 after, 1 before, 2 entire)
    SU  n   Scroll Up
    SD  n   Scroll Down
    HVP n,m Horizontal Vertical Position
    SGR n*  Select Graphic Rendition
    SCP     Save Cursor Position
    RCP     Restore Cursor Position

These names can be followed by optional numerical parameters, using
comma (C<,>) or semicolon (C<;>) to separate multiple ones, with
optional parentheses.  For example, color spec C<DK/544> can be
described as C<{SGR1;30;48;5;224}> or more readable
C<{SGR(1,30,48,5,224)}>.

Some other escape sequences are supported in the form of C<{NAME}>.
These sequences do not start with CSI, and do not take parameters.
VT100 compatible terminal usually support these, and does not support
C<SCP> and C<RCP> CSI code.

    RIS     Reset to Initial State
    DECSC   DEC Save Cursor
    DECRC   DEC Restore Cursor

=head2 EXAMPLES

    8+8  6x6x6    12bit      24bit            names
    ===  =======  =========  =============    ==================
    B    005      #00F       (0,0,255)        <blue>
     /M     /505      /#F0F     /(255,0,255)  /<magenta>
    K/W  000/555  #000/#FFF  #000000/#FFFFFF  <black>/<white>
    R/G  500/050  #F00/#0F0  #FF0000/#00FF00  <red>/<green>
    W/w  L03/L20  #333/#ccc  #333333/#cccccc  <gray20>/<gray80>

=head1 COLOR NAMES

Color names listed in L<Graphics::ColorNames::X> module can be used.
See L<https://en.wikipedia.org/wiki/X11_color_names>.

    aliceblue antiquewhite aqua aquamarine azure beige bisque black
    blanchedalmond blue blueviolet brown burlywood cadetblue
    chartreuse chocolate coral cornflowerblue cornsilk crimson cyan
    darkolivegreen dimgray dimgrey dodgerblue firebrick floralwhite
    forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray green
    greenyellow grey honeydew hotpink indianred indigo ivory khaki
    lavender lavenderblush lawngreen lemonchiffon lightgoldenrodyellow
    lime limegreen linen magenta maroon midnightblue mintcream
    mistyrose moccasin navajowhite navy navyblue oldlace olive
    olivedrab orange orangered orchid papayawhip peachpuff peru pink
    plum powderblue purple rebeccapurple red rosybrown royalblue
    saddlebrown salmon sandybrown seagreen seashell sienna silver
    skyblue slateblue slategray slategrey snow springgreen steelblue
    tan teal thistle tomato turquoise violet violetred webgray
    webgreen webgrey webmaroon webpurple wheat white whitesmoke
    x11gray x11green x11grey x11maroon x11purple yellow yellowgreen

In the above list, next colors have variants with prefix of C<dark>,
C<light>, C<medium>, C<pale>, C<deep>.

    aquamarine   medium_aquamarine
    blue         dark_blue light_blue medium_blue
    coral        light_coral
    cyan         dark_cyan light_cyan
    goldenrod    dark_goldenrod light_goldenrod pale_goldenrod
    gray         dark_gray light_gray
    green        dark_green light_green pale_green
    grey         dark_grey light_grey
    khaki        dark_khaki
    magenta      dark_magenta
    orange       dark_orange
    orchid       dark_orchid medium_orchid
    pink         deep_pink light_pink
    purple       medium_purple
    red          dark_red
    salmon       dark_salmon light_salmon
    seagreen     dark_seagreen light_seagreen medium_seagreen
    skyblue      deep_skyblue light_skyblue
    slateblue    dark_slateblue light_slateblue medium_slateblue
    slategray    dark_slategray light_slategray
    slategrey    dark_slategrey light_slategrey
    springgreen  medium_springgreen
    steelblue    light_steelblue
    turquoise    dark_turquoise medium_turquoise pale_turquoise
    violet       dark_violet
    violetred    medium_violetred pale_violetred
    yellow       light_yellow

Next colors have four variants.  For example, color C<brown> has
C<brown1>, C<brown2>, C<brown3>, C<brown4>.

    antiquewhite aquamarine azure bisque blue brown burlywood
    cadetblue chartreuse chocolate coral cornsilk cyan darkgoldenrod
    darkolivegreen darkorange darkorchid darkseagreen darkslategray
    deeppink deepskyblue dodgerblue firebrick gold goldenrod green
    honeydew hotpink indianred ivory khaki lavenderblush lemonchiffon
    lightblue lightcyan lightgoldenrod lightpink lightsalmon
    lightskyblue lightsteelblue lightyellow magenta maroon
    mediumorchid mediumpurple mistyrose navajowhite olivedrab orange
    orangered orchid palegreen paleturquoise palevioletred peachpuff
    pink plum purple red rosybrown royalblue salmon seagreen seashell
    sienna skyblue slateblue slategray snow springgreen steelblue tan
    thistle tomato turquoise violetred wheat yellow

C<gray> and C<grey> have 100 steps of variants.

    gray gray0 .. gray100
    grey grey0 .. grey100

See L<https://en.wikipedia.org/wiki/X11_color_names#Color_variations>
for detail.


=head1 FUNCTION SPEC

Color spec can be CODEREF or object.  If it is a CODEREF, that code is
called with text as an argument, and return the result.

If it is an object which has method C<call>, it is called with the
variable C<$_> set as target text.


=head1 RESET SEQUENCE

This module produces I<RESET> and I<Erase Line> sequence to recover
from colored text.  This is preferable to clear background color set
by scrolling in the middle of colored text at the bottom of the
terminal.

However, on some terminal, including Apple_Terminal, I<Erase Line>
sequence clear the text on the cursor position when it is at the
rightmost column of the screen.  In other words, rightmost character
sometimes mysteriously disappear when it is the last character in the
colored region.  If you do not like this behavior, set module variable
C<$NO_RESET_EL> or C<ANSICOLOR_NO_RESET_EL> environment.

I<Erase Line> sequence C<{EL}> clears the line from cursor position to
the end of the line, which means filling the area by background color.
When I<Erase Line> is explicitly found in the start sequence, it is
copied to just before (not after) ending reset sequence, with
preceding sequence if necessary, to keep the effect of filling line
even if the text is wrapped to multiple lines.

See L</ENVIRONMENT> section.

=head2 LESS

Because I<Erase Line> sequence end with C<K>, it is a good idea to
tell B<less> command so, if you want to see the output using it.

    LESS=-cR
    LESSANSIENDCHARS=mK


=head1 ENVIRONMENT

If the environment variable C<NO_COLOR> is set, regardless of its
value, colorization interface in this module never produce color
sequence.  Primitive function such as C<ansi_code> is not the case.
See L<https://no-color.org/>.

=for comment
If the module variable C<$NO_NO_COLOR> or C<ANSICOLOR_NO_NO_COLOR>
environment is true, C<NO_COLOR> value is ignored.

Function B<ansi_color> produces 256 or 24bit colors depending on the
value of C<$RGB24> module variable.  Also 24bit mode is enabled when
environment C<ANSICOLOR_RGB24> is set or C<COLORTERM> is C<truecolor>.

If the module variable C<$NO_RESET_EL> set, or
C<ANSICOLOR_NO_RESET_EL> environment, I<Erase Line> sequence is not
produced with RESET code.  See L<RESET SEQUENCE>.


=head1 COLOR TABLE

Color table can be shown by other module
L<Term::ANSIColor::Concise::Table>.  Next command will show table of
256 colors.

  $ perl -MTerm::ANSIColor::Concise::Table=:all -e colortable

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/colortable-s.png">

=end html

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/colortable-rev-s.png">

=end html


=head1 SEE ALSO

=head2 L<Getopt::EX::Colormap>

This module is originally implemented in L<Getopt::EX::Colormap>
module.  It provides an easy way to maintain labeled and indexed list
for color handling in command line option.

You can take care of user option like this:

    use Getopt::Long;
    my @opt_colormap;
    GetOptions('colormap|cm:s' => @opt_colormap);
    
    require Getopt::EX::Colormap;
    my %label = ( FILE => 'DR', LINE => 'Y', TEXT => '' );
    my @index = qw( /544 /545 /445 /455 /545 /554 );
    my $cm = Getopt::EX::Colormap
        ->new(HASH => \%label, LIST => \@index)
        ->load_params(@opt_colormap);  

And then program can use it in two ways:

    print $cm->color('FILE', $filename);

    print $cm->index_color($index, $pattern);

This interface provides a simple uniform way to handle coloring
options for various tools.

=head2 L<App::ansiecho>

To use this module's function directly from a command line,
L<App::ansiecho> is a good one.  You can apply colors and effects for
echoing argument.

=head2 L<App::Greple>

This code and L<Getopt::EX> was implemented as a part of
L<App::Greple> command originally.  It is still a intensive user of
this module capability and would be a good use-case.

=head2 OTHERS

L<https://en.wikipedia.org/wiki/ANSI_escape_code>

L<Graphics::ColorNames::X>

L<https://en.wikipedia.org/wiki/X11_color_names>

L<https://no-color.org/>

https://www.ecma-international.org/wp-content/uploads/ECMA-48_5th_edition_june_1991.pdf

=head1 AUTHOR

Kazumasa Utashiro


=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2015-2023 Kazumasa Utashiro


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  colormap colorize Cyan RGB cyan Wikipedia CSI ansi
#  LocalWords:  SGR
