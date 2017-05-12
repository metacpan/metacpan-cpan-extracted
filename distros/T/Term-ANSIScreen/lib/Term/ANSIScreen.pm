use 5.005;
package Term::ANSIScreen;
$Term::ANSIScreen::VERSION = '1.50';

use strict;
use vars qw/@ISA @EXPORT %EXPORT_TAGS $VERSION $AUTOLOAD
            %attributes %attributes_r %sequences $AUTORESET $EACHLINE/;
use Exporter;

=head1 NAME

Term::ANSIScreen - Terminal control using ANSI escape sequences

=head1 SYNOPSIS

    # qw/:color/ is exported by default, i.e. color() & colored()

    use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;

    print setmode(1), setkey('a','b');
    print "40x25 mode now, with 'a' mapped to 'b'.";
    <STDIN>; resetkey; setmode 3; cls;

    locate 1, 1; print "@ This is (1,1)", savepos;
    print locate(24,60), "@ This is (24,60)"; loadpos;
    print down(2), clline, "@ This is (3,15)\n";

    setscroll 1, 20;

    color 'black on white'; clline;
    print "This line is black on white.\n";
    print color 'reset'; print "This text is normal.\n";

    print colored ("This text is bold blue.\n", 'bold blue');
    print "This text is normal.\n";
    print colored ['bold blue'], "This text is bold blue.\n";
    print "This text is normal.\n";

    use Term::ANSIScreen qw/:constants/; # constants mode
    print BLUE ON GREEN . "Blue on green.\n";

    $Term::ANSIScreen::AUTORESET = 1;
    print BOLD GREEN . ON_BLUE "Bold green on blue.", CLEAR;
    print "\nThis text is normal.\n";

    # Win32::Console emulation mode
    # this returns a Win32::Console object on a Win32 platform
    my $console = Term::ANSIScreen->new;
    $console->Cls;	# also works on non-Win32 platform

=cut

# -----------------------
# Internal data structure
# -----------------------

%attributes = (
    'clear'      => 0,    'reset'      => 0,
    'bold'       => 1,    'dark'       => 2,
    'underline'  => 4,    'underscore' => 4,
    'blink'      => 5,    'reverse'    => 7,
    'concealed'  => 8,

    'black'      => 30,   'on_black'   => 40,
    'red'        => 31,   'on_red'     => 41,
    'green'      => 32,   'on_green'   => 42,
    'yellow'     => 33,   'on_yellow'  => 43,
    'blue'       => 34,   'on_blue'    => 44,
    'magenta'    => 35,   'on_magenta' => 45,
    'cyan'       => 36,   'on_cyan'    => 46,
    'white'      => 37,   'on_white'   => 47,
);

%sequences = (
    'up'        => '?A',      'down'      => '?B',
    'right'     => '?C',      'left'      => '?D',
    'savepos'   => 's',       'loadpos'   => 'u',
    'cls'       => '2J',      'clline'    => 'K',
    'cldown'    => '0J',      'clup'      => '1J',
    'locate'    => '?;?H',    'setmode'   => '?h',
    'wrapon'    => '7h',      'wrapoff'   => '7l',
    'setscroll'	=> '?;?r',
);

my %mapped;

# ----------------
# Exporter section
# ----------------

@ISA         = qw/Exporter/;
%EXPORT_TAGS = (
    'color'     => [qw/color colored uncolor/],
    'cursor'    => [qw/locate up down right left savepos loadpos/],
    'screen'    => [qw/cls clline cldown clup setmode wrapon wrapoff setscroll/],
    'keyboard'  => [qw/setkey resetkey/],
    'constants' => [map {uc($_)} keys(%attributes), 'ON'],
);

$EXPORT_TAGS{all} = [map {@{$_}} values (%EXPORT_TAGS)];

@EXPORT = qw(color colored);
Exporter::export_ok_tags (keys(%EXPORT_TAGS));

sub new {
    my $class = shift;

    if ($^O eq 'MSWin32' and eval { require Win32::Console } ) {
        return Win32::Console->new(@_);
    }

    no strict 'refs';
    unless ($main::FG_WHITE) {
        foreach my $color (grep { $attributes{$_} >= 30 } keys %attributes) {
            my $name = "FG_\U$color";
            $name =~ s/^FG_ON_/BG_/;
            ${"main::$name"} = color($color);
            $name =~ s/_/_LIGHT/;
            ${"main::$name"} = color('bold', $color);
        }
        $main::FG_LIGHTWHITE = $main::FG_WHITE;
        $main::FG_BROWN      = $main::FG_YELLOW;
        $main::FG_YELLOW     = $main::FG_LIGHTYELLOW;
        $main::FG_WHITE      = color('clear');
    }
    
    return bless([ @_ ], $class);
}

sub Attr {
    shift;
    print STDERR @_;
}

sub Cls {
    print STDERR cls();
}

sub Cursor {
    shift;
    print STDERR locate($_[1]+1, $_[0]+1);
}

sub Write {
    shift;
    print STDERR @_;
}

sub Display {
}


# --------------
# Implementation
# --------------

sub AUTOLOAD {
    my $enable_colors = !defined $ENV{ANSI_COLORS_DISABLED};
    my $sub = $AUTOLOAD;
    $sub =~ s/^.*:://;

    if (my $seq = $sequences{$sub}) {
	return '' unless $enable_colors;

        $seq =~ s/\?/defined($_[0]) ? shift(@_) : 1/eg;
        return((defined wantarray) ? "\e[$seq"
                                   : print("\e[$seq"));
    }
    elsif (defined(my $attr = $attributes{lc($sub)}) and $sub =~ /^[A-Z_]+$/) {
	my $out = "@_";
	if ($enable_colors) {
	    $out = "\e[${attr}m" . $out;
	    $out .= "\e[0m" if ($AUTORESET and @_ and $out !~ /\e\[0m$/s);
	}
        return((defined wantarray) ? $out
                                   : print($out));
    }
    else {
	require Carp;
        Carp::croak("Undefined subroutine &$AUTOLOAD called");
    }
}

# ------------------------------------------------
# Convert foreground constants to background ones,
# for sequences like (XXX ON YYY "text")
# ------------------------------------------------

sub ON {
    return '' if defined $ENV{ANSI_COLORS_DISABLED};

    my $out = "@_";
    $out =~ s/^\e\[3(\d)m/\e\[4$1m/;
    return $out;
}

# ---------------------------------------
# Color subroutines, from Term::ANSIColor
# ---------------------------------------

sub color {
    return '' if defined $ENV{ANSI_COLORS_DISABLED};

    my @codes = map { split } @_;
    my $attribute;

    no warnings 'uninitialized';
    while (my $code = lc(shift(@codes))) {
        $code .= '_' . shift(@codes) if ($code eq 'on');

        if (defined $attributes{$code}) {
            $attribute .= $attributes{$code} . ';';
        }
        else {
            warn "Invalid attribute name $code";
        }
    }

    if ($attribute) {
        chop $attribute;
        return (defined wantarray) ? "\e[${attribute}m"
                                   : print("\e[${attribute}m");
    }
}

sub colored {
    my $output;
    my ($string, $attr) = (ref $_[0])
        ? (join('', @_[1..$#_]), color(@{$_[0]}))
        : (+shift, color(@_));

    return $string if defined $ENV{ANSI_COLORS_DISABLED};

    if (defined $EACHLINE) {
        $output  = join '',
            map { ($_ && $_ ne $EACHLINE) ? $attr . $_ . "\e[0m" : $_ }
                split (/(\Q$EACHLINE\E)/, $string);
    } else {
        $output = "$attr$string\e[0m";
    }

    return (defined wantarray) ? $output
                               : print($output);
}

sub uncolor {
    my (@nums, @result);

    foreach my $seq (@_) {
        my $escape = $seq;
        $escape =~ s/^\e\[//;
        $escape =~ s/m$//;
        unless ($escape =~ /^((?:\d+;)*\d*)$/) {
            require Carp;
            Carp::croak("Bad escape sequence $seq");
        }
        push (@nums, split (/;/, $1));
    }

    _init_attributes_r();

    foreach my $num (@nums) {
        $num += 0; # Strip leading zeroes
        my $name = $attributes_r{$num};
        if (!defined $name) {
            require Carp;
            Carp::croak("No name for escape sequence $num" );
        }
        push (@result, $name);
    }

    return @result;
}

sub _init_attributes_r {
    return if %attributes_r;

    # Reverse lookup.  Alphabetically first name for a sequence is preferred.
    for (reverse sort keys %attributes) {
	$attributes_r{$attributes{$_}} = $_;
    }
}

sub setkey {
    my ($key, $mapto) = @_;

    if ($key eq $mapto) {
        delete $mapped{$key} if exists $mapped{$key};
    }
    else {
        $mapped{$key} = 1;
    }

    $key   = ord($key)    unless ($key =~ /^\d+;\d+$/);
    $mapto = qq("$mapto") unless ($mapto =~ /^\d+;\d+$/);

    return (defined wantarray) ? "\e[$key;${mapto}p"
                               : print("\e[$key;${mapto}p");
}

sub resetkey {
    my $output;

    foreach my $key (@_ ? @_ : keys(%mapped)) {
        $output .= setkey($key, $key);
    }

    return (defined wantarray) ? $output
                               : print($output);
}

sub DESTROY {
    return;
}

1;

__END__

=head1 DESCRIPTION

Term::ANSIScreen is a superset of B<Term::ANSIColor> (as of version 1.04
of that module).  In addition to color-sequence generating subroutines
exported by C<:color> and C<:constants>, this module also features
C<:cursor> for cursor positioning, C<:screen> for screen control, as
well as C<:keyboard> for key mapping.

=head2 NOTES

=over 4

=item *

All subroutines in B<Term::ANSIScreen> will print its return value if
called under a void context.

=item *

The cursor position, current color, screen mode and keyboard
mappings affected by B<Term::ANSIScreen> will last after the program
terminates. You might want to reset them before the end of
your program.

=back

=head1 FUNCTIONS

=head2 B<Win32::Console> emulation mode

When used in a object-oriented fashion, B<Term::ANSIScreen> acts as a
B<Win32::Console> clone:

    use Term::ANSIScreen;
    my $console = Term::ANSIScreen->new;
    $console->Cls();		# unbuffered
    $console->Cursor(0, 0);	# same as locate(1, 1)
    $console->Display();	# really a no-op

On the Win32 platform, the C<new> constructor simply returns a geniune
B<Win32::Console> object, if that module exists in the system.

This feature is intended for people who has to port Win32 console
applications to other platforms, or to write cross-platform application
that needs terminal controls.

=head2 The C<:color> function set (exported by default)

B<Term::ANSIScreen> recognizes (case-insensitively) following color
attributes: clear, reset, bold, underline, underscore, blink,
reverse, concealed, black, red, green, blue, white, yellow, magenta,
cyan, on_black, on_red, on_green, on_blue, on_white, on_yellow,
on_magenta, and on_cyan.

The color alone sets the foreground color, and on_color sets
the background color. You may also use on_color without the
underscore, e.g. "black on white".

=over 4

=item color LIST

Takes any number of strings as arguments and considers them
to be space-separated lists of attributes.  It then forms
and returns the escape sequence to set those attributes.

=item colored EXPR, LIST

Takes a scalar as the first argument and any number of
attribute strings as the second argument, then returns the
scalar wrapped in escape codes so that the attributes will
be set as requested before the string and reset to normal
after the string.

Alternately, you can pass a reference to an array as the
first argument, and then the contents of that array will
be taken as attributes and color codes and the remainder
of the arguments as text to colorize.

Normally, this function just puts attribute codes at the
beginning and end of the string, but if you set
$Term::ANSIScreen::EACHLINE to some string, that string will
be considered the line delimiter and the attribute will be set
at the beginning of each line of the passed string and reset
at the end of each line.  This is often desirable if the
output is being sent to a program like a pager, which can
be confused by attributes that span lines.

Normally you'll want to set C<$Term::ANSIScreen::EACHLINE> to
C<"\n"> to use this feature.

=back

=head2 The C<:constants> function set

If you import C<:constants> you can use the constants CLEAR,
RESET, BOLD, UNDERLINE, UNDERSCORE, BLINK, REVERSE, CONCEALED,
BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, ON_BLACK, ON_RED,
ON_GREEN, ON_YELLOW, ON_BLUE, ON_MAGENTA, ON_CYAN, and ON_WHITE
directly.  These are the same as color('attribute') and can be
used if you prefer typing:

    print BOLD BLUE ON_WHITE "Text\n", RESET;
    print BOLD BLUE ON WHITE "Text\n", RESET; # _ is optional

to
    print colored ("Text\n", 'bold blue on_white');

When using the constants, if you don't want to have to remember
to add the C<, RESET> at the end of each print line, you can set
C<$Term::ANSIScreen::AUTORESET> to a true value.  Then, the display
mode will automatically be reset if there is no comma after the
constant.  In other words, with that variable set:

    print BOLD BLUE "Text\n";

will reset the display mode afterwards, whereas:

    print BOLD, BLUE, "Text\n";

will not.

=head2 The C<:cursor> function set

=over 4

=item locate [EXPR, EXPR]

Sets the cursor position. The first argument is its row number,
and the second one its column number.  If omitted, the cursor
will be located at (1,1).

=item up    [EXPR]

=item down  [EXPR]

=item left  [EXPR]

=item right [EXPR]

Moves the cursor toward any direction for EXPR characters. If
omitted, EXPR is 1.

=item savepos

=item loadpos

Saves/restores the current cursor position.

=back

=head2 The C<:screen> function set

=over 4

=item cls

Clears the screen with the current background color, and set
cursor to (1,1).

=item clline

Clears the current row with the current background color, and
set cursor to the 1st column.

=item clup

Clears everything above the cursor.

=item cldown

Clears everything below the cursor.

=item setmode EXPR

Sets the screen mode to EXPR. Under DOS, ANSI.SYS recognizes
following values:

     0:  40 x  25 x   2 (text)   1:  40 x  25 x 16 (text)
     2:  80 x  25 x   2 (text)   3:  80 x  25 x 16 (text)
     4: 320 x 200 x   4          5: 320 x 200 x  2
     6: 640 x 200 x   2          7: Enables line wrapping
    13: 320 x 200 x   4         14: 640 x 200 x 16
    15: 640 x 350 x   2         16: 640 x 350 x 16
    17: 640 x 480 x   2         18: 640 x 480 x 16
    19: 320 x 200 x 256

=item wrapon

=item wrapoff

Enables/disables the line-wraping mode.

=item setscroll EXPR, EXPR

Causes scrolling to occur only on the lines numbered between
the first and second arguments, inclusive.

=back

=head2 The C<:keyboard> function set

=over 4

=item setkey EXPR, EXPR

Takes a scalar representing a single keystroke as the first
argument (either a character or an escape sequence in the
form of C<"num1;num2">), and maps it to a string defined by
the second argument.  Afterwards, when the user presses the
mapped key, the string will get outputed instead.

=item resetkey [LIST]

Resets each keys in the argument list to its original mapping.
If called without an argument, resets all previously mapped
keys.

=back

=head1 DIAGNOSTICS

=over 4

=item Invalid attribute name %s

You passed an invalid attribute name to either color() or
colored().

=item Identifier %s used only once: possible typo

You probably mistyped a constant color name such as:

    print FOOBAR "This text is color FOOBAR\n";

It's probably better to always use commas after constant names
in order to force the next error.

=item No comma allowed after filehandle

You probably mistyped a constant color name such as:

    print FOOBAR, "This text is color FOOBAR\n";

Generating this fatal compile error is one of the main advantages
of using the constants interface, since you'll immediately know
if you mistype a color name.

=item Bareword %s not allowed while "strict subs" in use

You probably mistyped a constant color name such as:

    $Foobar = FOOBAR . "This line should be blue\n";

or:

    @Foobar = FOOBAR, "This line should be blue\n";

This will only show up under use strict (another good reason
to run under use strict).

=back

=head1 SEE ALSO

L<Term::ANSIColor>, L<Win32::Console>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to Term-ANSIScreen.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
