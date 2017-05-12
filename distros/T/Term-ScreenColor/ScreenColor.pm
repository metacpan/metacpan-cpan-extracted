#!/usr/bin/env perl
#
##########################################################################
#
# Name:         Term::ScreenColor
# Version:      1.20
# Author:       Rene Uittenbogaard
# Date:         2010-10-04
# Usage:        require Term::ScreenColor;
# Requires:     Term::Screen
# Description:  Screen positioning and output coloring module
#
# Copyright:    (c) 1999-2010 Rene Uittenbogaard. All Rights Reserved.
#               This module is free software; you can redistribute it
#               and/or modify it under the same terms as Perl itself.

##########################################################################
# Term::ScreenColor

package Term::ScreenColor;

use strict;

our @ISA     = qw(Term::Screen::Fixes);
our $VERSION = '1.20';
our $AUTOLOAD;

our %ANSI_ATTRIBUTES = (
  'clear'      => 0,
  'reset'      => 0,
  'ansibold'   => 1,   'noansibold'   => 22,  # 1=on, 22=off
  'italic'     => 3,   'noitalic'     => 23,  # not widely supported
  'underscore' => 4,   'nounderscore' => 24,
  'blink'      => 5,   'noblink'      => 25,
  'inverse'    => 7,   'noinverse'    => 27,
  'concealed'  => 8,   'noconcealed'  => 28,

  'black'      => 30,  'on_black'     => 40,  # also 'on black' etc.
  'red'        => 31,  'on_red'       => 41,
  'green'      => 32,  'on_green'     => 42,
  'yellow'     => 33,  'on_yellow'    => 43,
  'blue'       => 34,  'on_blue'      => 44,
  'magenta'    => 35,  'on_magenta'   => 45,
  'cyan'       => 36,  'on_cyan'      => 46,
  'white'      => 37,  'on_white'     => 47,
);

##########################################################################
# start of manpage

=pod

=head1 NAME

Term::ScreenColor - Term::Screen based screen positioning and coloring module

=head1 SYNOPSIS

A Term::Screen based screen positioning module with ANSI
color support.

   use Term::ScreenColor;

   $scr = new Term::ScreenColor;
   $scr->colorizable(1);
   $scr->at(2,0)->red()->on_yellow()->puts("Hello, Tau Ceti!");
   $scr->putcolored('cyan bold on blue', 'Betelgeuse');
   $scr->putcolored('36;1;44', 'Altair');

=head1 DESCRIPTION

Term::ScreenColor adds ANSI coloring support, along with a few other useful
methods, to those provided in Term::Screen.

=head1 PUBLIC INTERFACE

Most methods return the Term::ScreenColor object so you can string things
together, I<e.g.>

    $scr->at(2,3)->cyan()->on_white()->puts("hello");

In addition to the methods described in Term::Screen(3pm),
Term::ScreenColor offers the following methods:

=over

=item I<new()>

Creates a new Term::ScreenColor object. Note that the constructor
of the inherited class Term::Screen homes the cursor and switches
the terminal to raw input mode.

=cut

sub new {
    my ($this) = @_;
    my $classname = ref($this) || $this;
    my $ob = Term::ScreenColor->SUPER::new();
    # Set colorizability based on terminal names which
    # we guess support color (ugly solution, fix this)
    $ob->{_is_colorizable} = $ENV{'TERM'} =~ /(^linux$|color|ansi)/i;
    bless $ob, $classname;
    # Find all attributes: termcap
    my %TERMCAP_ATTRIBUTES = (
        normal    => $ob->normal2esc(),
        bold      => $ob->bold2esc(),
        underline => $ob->underline2esc(),
       'reverse'  => $ob->reverse2esc(),
    );
    $ob->{_TERMCAP_ATTRIBUTES} = { %TERMCAP_ATTRIBUTES };
    # Find all attributes: ANSI by name and number
    $ob->{_ANSI_ATTRIBUTES}    = { %ANSI_ATTRIBUTES };
    @{
        $ob->{_ANSI_ATTRIBUTES}
    }{
        values %ANSI_ATTRIBUTES
    } = (
        values %ANSI_ATTRIBUTES
    );
    # replace termcap colors by ANSI equivalents
    # this is WAY faster than using termcap values when colorizable is on.
    @{
        $ob->{_ANSI_ATTRIBUTES}
    }{
        qw(normal bold underline reverse)
    } = @ANSI_ATTRIBUTES{qw(reset ansibold underscore inverse)};
    # Return the new object
    return $ob;
}

=item I<colorizable()>

=item I<colorizable($boolean)>

Returns (if called with no arguments) or sets (if called with one
boolean argument) whether the terminal is believed to support ANSI
color codes. If this is set to false, no ANSI codes will be printed
or generated. This provides an easy way for turning color on/off.

Note that the constructor above takes an initial guess at whether
the terminal supports color (based on the value of the C<TERM>
environment variable).

=cut

sub colorizable {
    my ($this, $request) = (@_);
    if (defined($request)) {
        $this->{_is_colorizable} = $request;
        return $this;
    } else {
        return $this->{_is_colorizable};
    }
}

=item I<black()>

=item I<red()>

=item I<on_white()>

=item I<on_cyan()>

=item I<inverse()>

I<etc.>

Prints an ANSI escape sequence for a specific color.

The color names understood are:

=for roff
.de Vp \" hack to hide ascii table from manpage

     ANSI color names:
    -----------------------------------
      0  clear
      0  reset
      1  ansibold     22  noansibold
      3  italic       23  noitalic
      4  underscore   24  nounderscore
      5  blink        25  noblink
      7  inverse      27  noinverse
      8  concealed    28  noconcealed
    -----------------------------------
     30  black        40  on_black
     31  red          41  on_red
     32  green        42  on_green
     33  yellow       43  on_yellow
     34  blue         44  on_blue
     35  magenta      45  on_magenta
     36  cyan         46  on_cyan
     37  white        47  on_white
    ------------------------------------

=for roff
.. \" end hack

=begin roff

.in +4n
.TS
lb s s s
n | l | n | l.
_
\0ANSI color names:
_
0	clear	\&	\&
0	reset	\&	\&
1	ansibold	22	noansibold
3	italic	23	noitalic
4	underscore	24	nounderscore
5	blink	25	noblink
7	inverse	27	noinverse
8	concealed	28	noconcealed
_
\030	black	40	on_black
\031	red	41	on_red
\032	green	42	on_green
\033	yellow	43	on_yellow
\034	blue	44	on_blue
\035	magenta	45	on_magenta
\036	cyan	46	on_cyan
\037	white	47	on_white
_
.TE
.in -4n

=end roff

Additionally, the following names are understood
(inherited from Term::Screen):

=for roff
.de Vp \" hack to hide ascii table from manpage

     termcap names:
    ---------------
     normal
     bold
     underline
     reverse
    ---------------

=for roff
.. \" end hack

=begin roff

.in +4n
.TS
lb
l.
_
\0termcap names:
_
\0normal
\0bold
\0underline
\0reverse
_
.TE
.in -4n

=end roff

These termcap names send termcap-based escapes, which are not
considered 'colors' and can therefore not be turned off by
colorizable().

As of version 1.12, underline() is termcap-based instead of
ANSI-based.

=cut

sub AUTOLOAD {
    my ($this) = @_;
    my $color = $AUTOLOAD;
    $color =~ s/.*:://;
    return if $color eq 'DESTROY';
    return $this->putcolor($color);
}

=item I<color2esc($colorstring)>

Creates a string containing the escape codes corresponding to the
color names or numbers given.

If the terminal is considered to be I<colorizable>, This method will
translate any termcap-names to their ANSI equivalents. This algorithm was
chosen to improve performance.

Examples:

    $scr->colorizable(1);
    $scr->color2esc('bold yellow');   # returns "\e[1;33m"
    $scr->color2esc('blue reverse');  # returns "\e[34;7m"
    $scr->color2esc('yellow on red'); # returns "\e[33;41m"
    $scr->color2esc('37;42');         # returns "\e[37;42m"

If the terminal is not I<colorizable>, the ANSI names are discarded
and only the termcap-names are respected. They will send the escape
sequences as defined in the termcap database.

Examples:

    $scr->colorizable(0);
    $scr->color2esc('bold yellow');
    # returns 'md' from termcap, probably "\e[1m"
    $scr->color2esc('blue reverse');
    # returns 'mr' from termcap, probably "\e[7m"
    $scr->color2esc('yellow on red');
    # returns ""

=cut

sub color2esc {
    # return color sequence
    my ($this, $color) = @_;
    return '' if $color eq '';
    if ($this->{_is_colorizable}) {
        return $this->_ansi2esc($color);
    } else {
        return $this->_termcap2esc($color);
    }
}

sub _ansi2esc {
    my ($this, $color) = @_;
    $color =~ s/on\s+/on_/go;
    # translation has been done in the constructor
    return "\e[" . join(
        ';',
        map { $this->{_ANSI_ATTRIBUTES}{$_} }
            split(/(?:\s+|;)/o, $color)
    ) . 'm';
}

sub _termcap2esc {
    # return color sequence
    my ($this, $color) = @_;
    my @elements =
        grep { defined }
            map { $this->{_TERMCAP_ATTRIBUTES}{$_} }
                split(/(?:\s+|;)/o, $color);
    return '' unless @elements;
    return join '', @elements;
}

=item I<color($colorstring)>

(Deprecated). Identical to putcolor($colorstring).

=cut

sub color {
    # for backward compatibility
    goto &putcolor;
}

=item I<putcolor($colorstring)>

Prints the escape sequence corresponding to this color string,
in other words: the escape sequence that color2esc() generates.

=cut

sub putcolor {
    # print color sequence
    my ($this, $color) = @_;
    print $this->color2esc($color);
    return $this;
}

=item I<colored($colorstring, @>I<strings)>

Returns a string containing a concatenation of the string parts,
wrapped in ANSI color sequences, using the first argument as
color specification.

Example:

   # the next two lines return "\e[36;1;44mSirius\e[0m"
   $scr->colored('cyan bold on blue', 'Sirius');
   $scr->colored('36;1;44', 'Sirius');

=cut

sub colored {
    # return string wrapped in color sequence
    my ($this, $color, @args) = @_;
    return join('', @args) if $color eq '';
    my $initstring = $this->color2esc($color);
    return join('', @args) unless $initstring;
    return join('', $initstring, @args, "\e[0m");
}

=item I<putcolored($colorstring, @>I<strings)>

Identical to puts(), but wraps its arguments in ANSI color
sequences first, using the first argument as color specification.

Example:

   # the next two lines print "\e[32;40mSirius\e[0m"
   $scr->colored('green on black', 'Sirius');
   $scr->colored('32;40', 'Sirius');

=cut

sub putcolored {
    # print string wrapped in color sequence
    my ($this, $color, @args) = @_;
    print $this->colored($color, @args);
    return $this;
}

##########################################################################
# return true

1;

##########################################################################
# manpage transition

=back

=head1 FIXES TO Term::Screen

As of version 1.11, Term::ScreenColor is bundled with some bugfixes,
enhancements and convenience functions that should have gone in
Term::Screen. They are therefore contained in a separate package
Term::Screen::Fixes.

=head1 PUBLIC INTERFACE

Term::Screen::Fixes offers the following methods:

=over

=cut

##########################################################################
# Term::Screen::Fixes

package Term::Screen::Fixes;

require Term::Screen;

use strict;

our @ISA = qw(Term::Screen);

=item I<new()>

Creates a new object. Initializes a timeout property, used for keys
that generate escape sequences.

=cut

sub new
{
    my ( $prototype, @args ) = @_;

    my $classname = ref($prototype) || $prototype;

    my $this = Term::Screen::Fixes->SUPER::new();
    bless $this, $prototype;
    $this->{FN_TIMEOUT} = 0.4;  # timeout for FN keys, in seconds
    $this->get_more_fn_keys();  # define function key table from defaults
    return $this;
}

=item I<timeout()>

=item I<timeout($float)>

Returns (if called with no arguments) or sets (if called with one float
argument) the function key timeout.

=cut

sub timeout
{
    my ( $self, $timeout ) = @_;

    if ( defined $timeout )
    {
        $self->{FN_TIMEOUT} = $timeout;
    }

    return $self->{FN_TIMEOUT};
}

=item I<getch()>

This duplicates the functionality of Term::Screen::getch(), but makes
the following improvements:

=over 2

=item *

getc() was replaced by sysread(). Since getc() does internal buffering,
it does not work well with select(). This led in certain cases to the
application not receiving input as soon as it was available.

=item *

If the received characterZ<>(s) started off as a possible function
key escape sequence, but turn out not to be one after all, then the
keys are put back in the input buffer in the correct order.
(Term::Screen::getch() put them back at the wrong end of the buffer).

=item *

If the first received characterZ<>(s) are part of a possible function
key escape sequence, it will wait the I<timeout> number of seconds for
a next character. This eliminates the need to press escape twice.

=back

=cut

# Unfortunately, for our fixes and extensions, we need to
# duplicate the entire subroutine here.

sub getch
{
    my $this = shift;
    my ( $c, $nc, $fn_flag) = ('', '', 0);
    my $partial_fn_str = '';

    if ( $this->{IN} ) { $c = chop( $this->{IN} ); }
    else { sysread( STDIN, $c, 1 ); }

    $partial_fn_str = $c;
    while ( exists( $this->{KEYS}{$partial_fn_str} ) )
    {    # in a possible function key sequence
        $fn_flag = 1;
        if ( $this->{KEYS}{$partial_fn_str} )    # key found
        {
            $c              = $this->{KEYS}{$partial_fn_str};
            $partial_fn_str = '';
            last;
        }
        else    # wait for another key to see if were in FN yet
        {
            if ( $this->{IN} ) { $partial_fn_str .= chop( $this->{IN} ); }
            elsif ( !$this->key_pressed(0) && !$this->key_pressed( $this->{FN_TIMEOUT} ) )
            {
                last;
            }
            else
            {
                sysread(STDIN, $nc, 1);
                $partial_fn_str .= $nc;
            }
        }
    }
    if ($fn_flag)    # seemed like a fn key
    {
        if ($partial_fn_str)    # oops not a fn key
        {
            # buffer up the received chars
            $this->{IN} = $this->{IN} . CORE::reverse($partial_fn_str);
            $c = chop( $this->{IN} );
            $this->puts($c) if ( $this->{ECHO} && ( $c ne "\e" ) );
        }

        # if fn_key then never echo so do nothing here
    }
    elsif ( $this->{ECHO} && ( $c ne "\e" ) ) { $this->puts($c); } # regular key
    return $c;
}

=item I<normal()>

Sends the escape sequence to turn off any highlightling (bold, reverse).

=cut

sub normal
{
    my $this = shift;
    print $this->normal2esc();
    return $this;
}

=item I<bold()>

Sends the B<md> value from termcap, which usually turns on bold.

=cut

sub bold
{
    my $this = shift;
    print $this->bold2esc();
    return $this;
}

=item I<reverse()>

Sends the B<mr> value from termcap, which often turns on reverse text.

=cut

sub reverse
{
    my $this = shift;
    print $this->reverse2esc();
    return $this;
}

=item I<underline()>

Turns on underline using the B<us> value from termcap.

=cut

sub underline
{
    my $this = shift;
    print $this->underline2esc();
    return $this;
}

=item I<flash()>

Sends the visual bell escape sequence to the terminal.

=cut

sub flash {
    my $this = shift;
    print $this->flash2esc();
    return $this;
}

=item I<normal2esc()>

=item I<bold2esc()>

=item I<reverse2esc()>

=item I<underline2esc()>

=item I<flash2esc()>

Return the termcap definitions for normal, bold, reverse, underline and
visual bell.

It was attested that on OpenSolaris 11, Term::Cap cannot provide
the properties B<normal>, B<bold>, and B<reverse> because there is
no F<termcap> and C<infocmp -C> does not provide these properties
(even though C<infocmp> does).  In that case, fall back on terminfo.

=cut

sub normal2esc
{
    my $this = shift;
    my $prop = $this->{'_me'};
    if (!defined $prop) {
        $prop = $this->term()->{'_me'};
        if (!defined $prop) {
            # fallback on terminfo
            eval { $prop = `tput sgr0` };
        }
    }
    # cache it
    $this->{'_me'} = $prop;
    return $prop;
}

sub bold2esc
{
    my $this = shift;
    my $prop = $this->{'_md'};
    if (!defined $prop) {
        $prop = $this->term()->{'_md'};
        if (!defined $prop) {
            # fallback on terminfo
            eval { $prop = `tput bold` };
        }
    }
    # cache it
    $this->{'_md'} = $prop;
    return $prop;
}

sub reverse2esc
{
    my $this = shift;
    my $prop = $this->{'_mr'};
    if (!defined $prop) {
        $prop = $this->term()->{'_mr'};
        if (!defined $prop) {
            # fallback on terminfo
            eval { $prop = `tput rev` };
        }
    }
    # cache it
    $this->{'_mr'} = $prop;
    return $prop;
}

sub underline2esc
{
    my $this = shift;
    my $prop = $this->{'_us'};
    if (!defined $prop) {
        $prop = $this->term()->{'_us'};
        if (!defined $prop) {
            # fallback on terminfo
            eval { $prop = `tput smul` };
        }
    }
    # cache it
    $this->{'_us'} = $prop;
    return $prop;
}

sub flash2esc
{
    my $this = shift;
    my $prop = $this->{'_vb'};
    if (!defined $prop) {
        $prop = $this->term()->{'_vb'};
        if (!defined $prop) {
            # fallback on terminfo
            eval { $prop = `tput flash` };
        }
    }
    # cache it
    $this->{'_vb'} = $prop;
    return $prop;
}

=item I<raw()>

Sets raw input mode using stty(1).

=cut

sub raw
{
    my $this = shift;
    eval { system qw(stty raw -echo) };
    return $this;
}

=item I<cooked()>

Sets cooked input mode using stty(1).

=cut

sub cooked
{
    my $this = shift;
    eval { system qw(stty -raw echo) };
    return $this;
}

=item I<flush_input()>

Duplicates the functionality of Term::Screen::flush_input(), but
replaces getc() with sysread().

=cut

sub flush_input
{
    my $this = shift;
    my $discard;
    $this->{IN} = '';
    while ( $this->key_pressed() ) { sysread(STDIN, $discard, 1); }
    return $this;
}

=item I<get_more_fn_keys()>

Adds more function key escape sequences.

=cut

sub get_more_fn_keys
{
    my $this = shift;
    my $term = $this->term();
    my ($fn, $count, %keys);

#    $this->def_key( "ku", "\e[A" );   # vt100
#    $this->def_key( "kd", "\e[B" );   # vt100
#    $this->def_key( "kr", "\e[C" );   # vt100
#    $this->def_key( "kl", "\e[D" );   # vt100

    $this->def_key( "ku", "\eOA" );   # xterm
    $this->def_key( "kd", "\eOB" );   # xterm
    $this->def_key( "kr", "\eOC" );   # xterm
    $this->def_key( "kl", "\eOD" );   # xterm

#    $this->def_key( "k1",  "\e[11~" ); # vt100
#    $this->def_key( "k2",  "\e[12~" ); # vt100
#    $this->def_key( "k3",  "\e[13~" ); # vt100
#    $this->def_key( "k4",  "\e[14~" ); # vt100
#    $this->def_key( "k5",  "\e[15~" ); # vt100
#    $this->def_key( "k6",  "\e[17~" ); # vt100
#    $this->def_key( "k7",  "\e[18~" ); # vt100
#    $this->def_key( "k8",  "\e[19~" ); # vt100
#    $this->def_key( "k9",  "\e[20~" ); # vt100
#    $this->def_key( "k10", "\e[21~" ); # vt100
#    $this->def_key( "k11", "\e[23~" ); # vt100
#    $this->def_key( "k12", "\e[24~" ); # vt100

    $this->def_key( "k1", "\eOP" );   # xterm
    $this->def_key( "k2", "\eOQ" );   # xterm
    $this->def_key( "k3", "\eOR" );   # xterm
    $this->def_key( "k4", "\eOS" );   # xterm

    $this->def_key( "k1", "\e[[A" );  # Linux console
    $this->def_key( "k2", "\e[[B" );  # Linux console
    $this->def_key( "k3", "\e[[C" );  # Linux console
    $this->def_key( "k4", "\e[[D" );  # Linux console
    $this->def_key( "k5", "\e[[E" );  # Linux console

#    $this->def_key( "ins",  "\e[2~" );  # vt100
#    $this->def_key( "del",  "\e[3~" );  # vt100
#    $this->def_key( "pgup", "\e[5~" );  # vt100
#    $this->def_key( "pgdn", "\e[6~" );  # vt100

    $this->def_key( "home", "\e[H" );   # vt100
    $this->def_key( "end",  "\e[F" );   # vt100

    $this->def_key( "home", "\eOH" );   # xterm
    $this->def_key( "end",  "\eOF" );   # xterm

    $this->def_key( "home", "\e[1~" );  # Linux console
    $this->def_key( "end",  "\e[4~" );  # Linux console

    $this->def_key( "home", "\eO" );
    $this->def_key( "end",  "\eOw" );
    $this->def_key( "end",  "\eOe" );

    # try to get more useful things out of termcap

    %keys = (
        kI  => "ins",
        kD  => "del",
        kh  => "home",
       '@7' => "end",
        kP  => "pgup",
        kN  => "pgdn",
       'k;' => "k10",
        F1  => "k11",
        F2  => "k12",
    );

    $count = "0 but true";
    foreach $fn (keys %keys) {
        if (exists $term->{"_$fn"}) {
#            print "Defining $keys{$fn} as $term->{\"_$fn\"}\n";
            $this->def_key($keys{$fn}, $term->{"_$fn"});
            $count++;
        }
    }
    return $count;
}

##########################################################################
# return true

1;

##########################################################################
# end of manpage

=back

=head1 AUTHOR

Rene Uittenbogaard (ruittenb@users.sourceforge.net)

Term::ScreenColor was based on:

=over

=item Term::Screen

Originally by Mark Kaehny (kaehny@execpc.com),
now maintained by Jonathan Stowe (jns@gellyfish.co.uk).

=item Term::ANSIColor

By Russ Allbery (rra@cs.stanford.edu) and Zenin (zenin@best.com).

=back

=head1 SEE ALSO

Term::Screen(3pm), Term::Cap(3pm), termcap(5), stty(1)

=cut

# vim: set tabstop=4 shiftwidth=4 expandtab:

