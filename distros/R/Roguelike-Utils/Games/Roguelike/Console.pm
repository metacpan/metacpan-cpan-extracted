package Games::Roguelike::Console;

use strict;

use Exporter;
our @ISA=qw(Exporter);
use Carp qw(croak);
use warnings::register;

our $VERSION = '0.4.' . [qw$Revision: 256 $]->[1];

=head1 NAME

Games::Roguelike::Console - Platform-neutral console handling

=head1 SYNOPSIS

 use Games::Roguelike::Console;

 $con = Games::Roguelike::Console->new();
 $con->attron('bold yellow');
 $con->addstr('test');
 $con->attroff();
 $con->refresh();

=head1 DESCRIPTION

Attempts to figure out which Games::Roguelike::Console subclass to instantiate in order to provide console support.

=head2 METHODS

=over 4

=item new ([type=>$stype], [noinit=>1])

Create a new console, optionally specifying the subtype (win32, ansi, curses or dump:file[:keys]), and the noinit flag (which suppresses terminal initialization.)

If a type is not specified, a suitable default will be chosen.

=item addch ([$y, $x], $str);

=item addstr ([$y, $x], $str);

=item attrstr ($color, [$y, $x], $str);

Prints a string at the y, x positions or at the current cursor position (also positions the cursor at y, x+length(str))

=item attron ($color)

Turns on color attributes ie: bold blue, white, white on black, black on bold blue

=item attroff ()

Turns off color attributes

=item refresh ()

Draws the current screen

=item redraw ()

Redraws entire screen (if out of sync)

=item move ($y, $x)

Moves the cursor to y, x

=item getch ()

Reads a character from input

=item nbgetch ()

Reads a character from input, non-blocking

=item parsecolor ()

Helper function for subclass, parses an attribute then calls "nativecolor($fg, $bg, $bold)", caching the results.

Subclass can define this instead of nativecolor, if desired.

=item tagstr ([$y, $x,] $str)

Moves the cursor to y, x and writes the string $str, which can contain <color> tags

=item cursor([bool])

Changes the state of whether the cursor is shown, or returns the current state.

=item rect(x, y, w, h)

Sets the left margin (x) for things that parse out carraige returns, and is the 
rectangle used for scrolling.

=back

=head1 SEE ALSO

L<Games::Roguelike::Console::ANSI>, L<Games::Roguelike::Console::Win32>, L<Games::Roguelike::Console::Curses>

=head1 AUTHOR

Erik Aronesty C<earonesty@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html> or the included LICENSE file.

=cut


# platform independent
use Games::Roguelike::Console::ANSI;
use Games::Roguelike::Console::Dump;

our ($OK_WIN32, $OK_CURSES, $DUMPFILE, $DUMPKEYS);

my %CONDATA;

eval{require Games::Roguelike::Console::Win32};
$OK_WIN32 = !$@;

eval{require Games::Roguelike::Console::Curses};
$OK_CURSES = !$@;

# guess best package, and return "new of that package"

sub new {
        my $pkg = shift;
	my %opt = @_;

	if ($DUMPFILE) {
		# override params and just create a dump console
		return new Games::Roguelike::Console::Dump @_, file=>($DUMPFILE?$DUMPFILE:'>/dev/null'), keys=>$DUMPKEYS;
	}
	
	$opt{type} = '' if !defined $opt{type};

	if ($opt{type} eq '') {
		$opt{type} = 'win32' 	if $OK_WIN32;
		$opt{type} = 'curses' 	if $OK_CURSES;
	}

	$opt{type} = 'ansi' 	if $opt{type} eq '';

	if ($opt{type} eq 'ansi') {
		return new Games::Roguelike::Console::ANSI @_;
	}
	if ($opt{type} =~ /dump:?(.*):?(.*)/) {
		return new Games::Roguelike::Console::Dump @_, file=>$1, keys=>$2;
	}
	if ($opt{type} eq 'win32') {
		return new Games::Roguelike::Console::Win32 @_;
	}
	if ($opt{type} eq 'curses') {
		return new Games::Roguelike::Console::Curses @_;
	}
}

# this should be called by sublcass, unless they supply their own defcolor, rect defaults
sub init {
	my $self = shift;
	my %opts = @_;
	$self->defcolor($opts{defcolor});
	$self->rect($opts{x}, $opts{y}, $opts{w}, $opts{h});
}

sub DESTROY {
	croak "hey, this should never be called, override it!";
}

my %COLORMAP;
sub parsecolor {
	my $self = shift;
	my $pkg = ref($self);
	my ($attr, $parsedef) = @_;

	$attr = '' if ! defined $attr;
        if ($parsedef || !$COLORMAP{$pkg}{$attr}) {
                my $bg = $CONDATA{$self}->{bg};
                my $fg = $CONDATA{$self}->{fg};
                $bg = $1 if $attr=~ s/on[\s_]+(.*)$//;
                $fg = $attr;
                my $bold = 0;
		$bold = 1 if $fg =~ s/\s*bold\s*//;
		$fg = 'white' if !$fg;
		# trim spaces in color names
		$fg =~ s/ //g;
		$bg =~ s/ //g;
                ($fg, $bold) = ('black', 1) if $fg =~ /gray|grey/;
                ($bg, $bold) = ('black', 1) if $bg =~ /gray|grey/;
                $COLORMAP{$pkg}{$attr} = $self->nativecolor($fg, $bg, $bold);
		return ($COLORMAP{$pkg}{$attr}, $fg, $bg) if $parsedef;
	}
	return $COLORMAP{$pkg}{$attr};
}

sub nativecolor {
	my $self = shift;
	my ($fg, $bg, $bold) = @_;
	croak "nativecolor must be overridden in " . ref($self);
}

sub attrch {
        my $self = shift;
        my ($color, @args) = @_;

        if ($color) {
                $self->attron($color);
                $self->addch(@args);
                $self->attroff($color);
        } else {
                $self->addch(@args);
        }
}

sub attrstr {
        my $self = shift;
        my ($color, @args) = @_;

        if ($color) {
                $self->attron($color);
                $self->addstr(@args);
                $self->attroff($color);
        } else {
                $self->addch(@args);
        }
}

sub rect {
	my $self = shift;
	my ($x, $y, $w, $h) = @_;
	$CONDATA{$self}->{rx} = $x+0 if defined $x;
	$CONDATA{$self}->{ry} = $y+0 if defined $y;
	$CONDATA{$self}->{rw} = $w+0 if defined $w;
	$CONDATA{$self}->{rh} = $h+0 if defined $h;
	return ($CONDATA{$self}->{rx}, $CONDATA{$self}->{ry}, $CONDATA{$self}->{rw}, $CONDATA{$self}->{rh});
}

sub defcolor {
        my $self = shift;
	if (@_) {
        	my ($color, $fg, $bg) = $self->parsecolor(($_[0] ? $_[0] : 'white on black'), 1);
        	$CONDATA{$self}->{defcolor}= $color;
        	$CONDATA{$self}->{fg}= $fg;
        	$CONDATA{$self}->{bg}= $bg;
	} 
	return $CONDATA{$self}->{defcolor};
}

1;
