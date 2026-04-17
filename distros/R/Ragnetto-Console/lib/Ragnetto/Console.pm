# ------------------------------------------------------------------------------
#  Ragnetto-Console
# ------------------------------------------------------------------------------
#  File	: console.pm
#  Description	: ANSI console control utility
#  Language	: Perl
# ------------------------------------------------------------------------------
#  Project	: ragnetto-console
#  Author		: Gabriele Secci
#  Editor		: Ragnetto(R) Software
#  E-Mail		: ragnettosoftware@gmail.com
# ------------------------------------------------------------------------------
#  Notes
#  - This module provides terminal manipulation functions.
#  - It is part of the Ragnetto module suite.
# ------------------------------------------------------------------------------
#  Copyright (C) 2026 - All Rights Reserved
# ------------------------------------------------------------------------------

package Ragnetto::Console;
our $VERSION = '0.01';

use strict;
use warnings;
use utf8;
use Exporter 'import';
use IO::Handle;

our (@EXPORT_OK, %EXPORT_TAGS);

BEGIN {
    my @color_names = qw(BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GRAY LIGHT_RED LIGHT_GREEN LIGHT_YELLOW LIGHT_BLUE LIGHT_MAGENTA LIGHT_CYAN LIGHT_WHITE);
    my @state_names = qw(OFF ON);
    my @shape_names = qw(BLOCK_BLINK BLOCK_STEADY UNDER_BLINK UNDER_STEADY BAR_BLINK BAR_STEADY);
    my @func_names  = qw(clear forecolor backcolor cursor caret position write reset title width height getkey putkey);

    @EXPORT_OK = (@color_names, @state_names, @shape_names, @func_names);
    %EXPORT_TAGS = (
        colors => \@color_names,
        states => \@state_names,
        shapes => \@shape_names,
        all    => \@EXPORT_OK,
    );
}

# ------------------------------------------------------------------------------
#  CORE CONSTANTS
# ------------------------------------------------------------------------------

use constant {
    BLACK => 0, RED => 1, GREEN => 2, YELLOW => 3, BLUE => 4, MAGENTA => 5, CYAN => 6, WHITE => 7,
    GRAY => 8, LIGHT_RED => 9, LIGHT_GREEN => 10, LIGHT_YELLOW => 11, LIGHT_BLUE => 12, LIGHT_MAGENTA => 13, LIGHT_CYAN => 14, LIGHT_WHITE => 15,
    OFF => 0, ON => 1,
    BLOCK_BLINK => 1, BLOCK_STEADY => 2, UNDER_BLINK => 3, UNDER_STEADY => 4, BAR_BLINK => 5, BAR_STEADY => 6,
};

my %COLORS;
BEGIN {
    %COLORS = (
        BLACK => 0, RED => 1, GREEN => 2, YELLOW => 3, BLUE => 4, MAGENTA => 5, CYAN => 6, WHITE => 7,
        GRAY => 8, LIGHT_RED => 9, LIGHT_GREEN => 10, LIGHT_YELLOW => 11, LIGHT_BLUE => 12, LIGHT_MAGENTA => 13, LIGHT_CYAN => 14, LIGHT_WHITE => 15
    );
}

STDOUT->autoflush(1);

# ------------------------------------------------------------------------------
#  HELPER FUNCTION
# ------------------------------------------------------------------------------

sub _get_color_val {
    my ($val) = @_;

    return $val if $val =~ /^\d+$/;
    return $COLORS{uc($val)} if defined $val;
    return undef;
}

# ------------------------------------------------------------------------------
#  CORE FUNCTION
# ------------------------------------------------------------------------------

# Clears the screen completely and resets the cursor
sub clear {
    print "\e[2J\e[H";
}

# Set the background color (0-15)
sub backcolor {
    my ($color) = @_;
    my $c = _get_color_val($color);

    return unless defined $c;

    printf("\e[%dm", ($c < 8 ? 40 + $c : 100 + ($c - 8)));
}

# Set the text color (0-15)
sub forecolor {
    my ($color) = @_;
    my $c = _get_color_val($color);

    return unless defined $c;

    printf("\e[%dm", ($c < 8 ? 30 + $c : 90 + ($c - 8)));
}

# Manages the visibility of the cursor
sub cursor {
    my ($state) = @_;
    my $s = uc($state // '');

    if ($s eq '1' || $s eq 'ON' || $s eq 'TRUE') {
        print "\e[?25h";
    }
    else {
        print "\e[?25l";
    }
}

# Change the shape of the cursor (Caret)
sub caret {
    my ($shape) = @_;
    my %shapes = (BLOCK_BLINK => 1, BLOCK_STEADY => 2, UNDER_BLINK => 3, UNDER_STEADY => 4, BAR_BLINK => 5, BAR_STEADY => 6);
    my $s = $shape =~ /^\d+$/ ? $shape : $shapes{uc($shape)};

    print "\e[$s q" if $s && $s >= 1 && $s <= 6;
}

# Move the cursor to a specific position
sub position {
    my ($x, $y) = @_;

    printf("\e[%d;%dH", $y, $x);
}

# Writes text with attributes and positioning
sub write {
    my ($text, $fore, $back, $x, $y) = @_;
    my $out = "";

    $out .= sprintf("\e[%d;%dH", $y, $x) if defined $x && defined $y;

    if (defined $back) {
        my $c = _get_color_val($back);

        $out .= sprintf("\e[%dm", ($c < 8 ? 40 + $c : 100 + ($c - 8))) if defined $c;
    }

    if (defined $fore) {
        my $c = _get_color_val($fore);

        $out .= sprintf("\e[%dm", ($c < 8 ? 30 + $c : 90 + ($c - 8))) if defined $c;
    }

    print $out . $text . "\e[0m";
}

# Reads a single character
sub getkey {
    my $char;

    if ($^O eq 'MSWin32') {
        $char = `powershell -Command "[console]::ReadKey(\$true).KeyChar"`;
        $char =~ s/[\r\n]+$//;
    }
    else {
        system("stty -icanon -echo");
        sysread(STDIN, $char, 1);
        system("stty icanon echo");
    }

    return $char;
}

# Reads a single character and prints it to the screen
sub putkey {
    my $char;

    if ($^O eq 'MSWin32') {
        $char = `powershell -Command "[console]::ReadKey(\$true).KeyChar"`;
        $char =~ s/[\r\n]+$//;
    }
    else {
        system("stty -icanon -echo");
        sysread(STDIN, $char, 1);
        system("stty icanon");
    }

    if (defined $char && $char ne '') {
        local $| = 1;

        print $char;
    }

    return $char;
}

# Set the terminal window title
sub title {
    my ($title) = @_;

    print "\e]0;$title\a" if defined $title;
}

# Gets the current width of the console (columns)
sub width {
    my $w;

    if ($^O eq 'MSWin32') {
        $w = `powershell -command "\$host.ui.rawui.WindowSize.Width"` || 80;
    }
    else {
        $w = `stty size 2>/dev/null` =~ /\d+\s+(\d+)/ ? $1 : 80;
    }

    return int($w);
}

# Gets the current height of the console (rows)
sub height {
    my $h;

    if ($^O eq 'MSWin32') {
        $h = `powershell -command "\$host.ui.rawui.WindowSize.Height"` || 24;
    }
    else {
        $h = `stty size 2>/dev/null` =~ /(\d+)/ ? $1 : 24;
    }

    return int($h);
}

# Reset all styles to default values
sub reset {
    print "\e[0m\e[?25h\e[0 q";
}

1;

__END__

=encoding utf-8

=head1 NAME

Ragnetto::Console - ANSI terminal control utility

=head1 SYNOPSIS

    use Ragnetto::Console qw(clear forecolor backcolor write);

    clear();
    forecolor('RED');
    print "RAGNETTO Gabriele Secci!\n";

    write("Positioned text", "GREEN", "BLACK", 10, 5);

=head1 DESCRIPTION

Ragnetto::Console provides terminal manipulation functions.
It is part of the Ragnetto module suite.

=head1 FUNCTIONS

=head2 clear()

Completely clears the screen and resets the cursor to the "Home" position (1,1).

=head2 forecolor($color)

Sets the text foreground color. Accepts a number (0-15) or a color name as a string (e.g., 'RED', 'LIGHT_BLUE').

=head2 backcolor($color)

Sets the background color. Accepts a number (0-15) or a color name as a string.

=head2 cursor($state)

Manages cursor visibility. Accepts boolean values (1/0), strings ('ON'/'OFF'), or module constants.

=head2 caret($shape)

Changes the cursor shape (Caret). Accepts IDs from 1 to 6 or constants (e.g., C<BLOCK_BLINK>, C<BAR_STEADY>).

=head2 position($x, $y)

Moves the cursor to the specified coordinates: column ($x) and row ($y).

=head2 write($text, $fore, $back, $x, $y)

Advanced function that writes text applying colors and position in a single command. It automatically resets attributes afterward.

=head2 title($title)

Sets the terminal window title.

=head2 width()

Returns the current width of the console (number of columns).

=head2 height()

Returns the current height of the console (number of rows).

=head2 getkey()

Reads a single character from the keyboard without waiting for Enter (raw mode) and without echoing it to the screen.

=head2 putkey()

Reads a single character from the keyboard and prints it to the screen.

=head2 reset()

Restores all terminal attributes to their default values (colors, cursor visibility, and shape).

=head1 LICENSE

Copyright (C) 2026 Gabriele Secci.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Gabriele Secci E<lt>ragnettosoftware@gmail.comE<gt>

=cut
