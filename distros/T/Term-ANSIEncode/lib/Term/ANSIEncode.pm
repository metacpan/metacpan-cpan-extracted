package Term::ANSIEncode;

#######################################################################
#            _   _  _____ _____   ______                     _        #
#      ╱╲   | ╲ | |╱ ____|_   _| |  ____|                   | |       #
#     ╱  ╲  |  ╲| | (___   | |   | |__   _ __   ___ ___   __| | ___   #
#    ╱ ╱╲ ╲ | . ` |╲___ ╲  | |   |  __| | '_ ╲ ╱ __╱ _ \ / _` |╱ _ ╲  #
#   ╱ ____ ╲| |╲  |____) |_| |_  | |____| | | | (_| (_) | (_| |  __╱  #
#  ╱_╱    ╲_╲_| ╲_|_____╱|_____| |______|_| |_|╲___╲___╱ ╲__,_|╲___|  #
#######################################################################
#                     Written By Richard Kelsch                       #
#                  © Copyright 2025 Richard Kelsch                    #
#                        All Rights Reserved                          #
#                           Version 1.06                              #
#######################################################################
# This program is free software: you can redistribute it and/or       #
# modify it under the terms of the GNU General Public License as      #
# published by the Free Software Foundation, either version 3 of the  #
# License, or (at your option) any later version.                     #
#                                                                     #
# This program is distributed in the hope that it will be useful, but #
# WITHOUT ANY WARRANTY; without even the implied warranty of          #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU   #
# General Public License for more details.                            #
#                                                                     #
# You should have received a copy of the GNU General Public License   #
# along with this program.  If not, see:                              #
#                                     <http://www.gnu.org/licenses/>. #
#######################################################################

use strict;

use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use Time::HiRes qw( sleep );
use utf8;
use constant {
    TRUE  => 1,
    FALSE => 0,
    YES   => 1,
    NO    => 0,
};

binmode(STDOUT, ":encoding(UTF-8)");

BEGIN {
	our $VERSION = '1.05';
}

sub ansi_output {
    my $self  = shift;
    my $text  = shift;
    my $delay = shift;

    if (length($text) > 1) {
        foreach my $string (keys %{ $self->{'ansi_sequences'} }) {
            if ($string =~ /CLEAR|CLS/i) {
                my $ch = locate(1, 1) . cldown;
                $text =~ s/\[\%\s+$string\s+\%\]/$ch/gi;
            } else {
                $text =~ s/\[\%\s+$string\s+\%\]/$self->{'ansi_sequences'}->{$string}/gi;
            }
        } ## end foreach my $string (keys %{...})
    } ## end if (length($text) > 1)
    my $s_len = length($text);
    my $nl    = $self->{'ansi_sequences'}->{'NEWLINE'};
    my $found = FALSE;
    foreach my $count (0 .. $s_len) {
        my $char = substr($text, $count, 1);
        if ($char eq "\n") {
            if ($text !~ /$nl/) {    # translate only if the file doesn't have ASCII newlines
                $char = $nl;
            }
        } elsif ($char eq chr(27)) {    # Don't slow down ANSI sequences
            $found = TRUE;
        } elsif ($char eq 'm') {
            $found = FALSE;
        } elsif (!$found) {
            sleep $delay if ($delay);
        }
        print $char;
    } ## end foreach my $count (0 .. $s_len)
} ## end sub ansi_output

sub new {
    my $class = shift;
	my $self;

    my $esc = chr(27) . '[';

    $self->{'ansi_prefix'}    = $esc;
    $self->{'ansi_sequences'} = {
        'RETURN'   => chr(13),
        'LINEFEED' => chr(10),
        'NEWLINE'  => chr(13) . chr(10),

        'CLEAR'      => locate(1, 1) . cls,
        'CLS'        => locate(1, 1) . cls,
        'CLEAR LINE' => clline,
        'CLEAR DOWN' => cldown,
        'CLEAR UP'   => clup,

        # Cursor
        'UP'          => $esc . 'A',
        'DOWN'        => $esc . 'B',
        'RIGHT'       => $esc . 'C',
        'LEFT'        => $esc . 'D',
        'SAVE'        => $esc . 's',
        'RESTORE'     => $esc . 'u',
        'RESET'       => $esc . '0m',
        'BOLD'        => $esc . '1m',
        'FAINT'       => $esc . '2m',
        'ITALIC'      => $esc . '3m',
        'UNDERLINE'   => $esc . '4m',
        'SLOW BLINK'  => $esc . '5m',
        'RAPID BLINK' => $esc . '6m',

        # Attributes
        'INVERT'       => $esc . '7m',
        'REVERSE'      => $esc . '7m',
        'CROSSED OUT'  => $esc . '9m',
        'DEFAULT FONT' => $esc . '10m',
        'FONT1'        => $esc . '11m',
        'FONT2'        => $esc . '12m',
        'FONT3'        => $esc . '13m',
        'FONT4'        => $esc . '14m',
        'FONT5'        => $esc . '15m',
        'FONT6'        => $esc . '16m',
        'FONT7'        => $esc . '17m',
        'FONT8'        => $esc . '18m',
        'FONT9'        => $esc . '19m',

        # Color
        'NORMAL' => $esc . '21m',

        # Foreground color
        'BLACK'          => $esc . '30m',
        'RED'            => $esc . '31m',
        'PINK'           => $esc . '38;5;198m',
        'ORANGE'         => $esc . '38;5;202m',
        'NAVY'           => $esc . '38;5;17m',
        'GREEN'          => $esc . '32m',
        'YELLOW'         => $esc . '33m',
        'BLUE'           => $esc . '34m',
        'MAGENTA'        => $esc . '35m',
        'CYAN'           => $esc . '36m',
        'WHITE'          => $esc . '37m',
        'DEFAULT'        => $esc . '39m',
        'BRIGHT BLACK'   => $esc . '90m',
        'BRIGHT RED'     => $esc . '91m',
        'BRIGHT GREEN'   => $esc . '92m',
        'BRIGHT YELLOW'  => $esc . '93m',
        'BRIGHT BLUE'    => $esc . '94m',
        'BRIGHT MAGENTA' => $esc . '95m',
        'BRIGHT CYAN'    => $esc . '96m',
        'BRIGHT WHITE'   => $esc . '97m',

        # Background color
        'B_BLACK'          => $esc . '40m',
        'B_RED'            => $esc . '41m',
        'B_GREEN'          => $esc . '42m',
        'B_YELLOW'         => $esc . '43m',
        'B_BLUE'           => $esc . '44m',
        'B_MAGENTA'        => $esc . '45m',
        'B_CYAN'           => $esc . '46m',
        'B_WHITE'          => $esc . '47m',
        'B_DEFAULT'        => $esc . '49m',
        'B_PINK'           => $esc . '48;5;198m',
        'B_ORANGE'         => $esc . '48;5;202m',
        'B_NAVY'           => $esc . '48;5;17m',
        'BRIGHT B_BLACK'   => $esc . '100m',
        'BRIGHT B_RED'     => $esc . '101m',
        'BRIGHT B_GREEN'   => $esc . '102m',
        'BRIGHT B_YELLOW'  => $esc . '103m',
        'BRIGHT B_BLUE'    => $esc . '104m',
        'BRIGHT B_MAGENTA' => $esc . '105m',
        'BRIGHT B_CYAN'    => $esc . '106m',
        'BRIGHT B_WHITE'   => $esc . '107m',

        'EURO'                             => '€',
        'ELIPSIS'                          => '…',
        'BULLET DOT'                       => chr(149),
        'HOLLOW BULLET DOT'                => '○',
        'BIG HYPHEN'                       => chr(150),
        'BIGGEST HYPHEN'                   => chr(151),
        'TRADEMARK'                        => '™',
        'CENTS'                            => '¢',
        'POUND'                            => '£',
        'YEN'                              => '¥',
        'COPYRIGHT'                        => '©',
        'DOUBLE LT'                        => chr(171),
        'REGISTERED'                       => '®',
        'OVERLINE'                         => chr(175),
        'DEGREE'                           => '°',
        'SQUARED'                          => chr(178),
        'CUBED'                            => chr(179),
        'MICRO'                            => chr(181),
        'PARAGRAPH'                        => chr(182),
        'MIDDLE DOT'                       => chr(183),
        'SUPERSCRIPT ONE'                  => chr(185),
        'SUPERSCRIPT TWO'                  => chr(186),
        'DOUBLE GT'                        => chr(187),
        'QUARTER'                          => '¼',
        'HALF'                             => '½',
        'THREE QUARTERS'                   => '¾',
        'INVERTED QUESTION'                => '¿',
        'DIVISION'                         => '÷',
        'HEART'                            => '♥',
        'CLUB'                             => '♣',
        'DIAMOND'                          => '♦',
        'LARGE PLUS'                       => '┼',
        'LARGE VERTICAL BAR'               => '│',
        'LARGE OVERLINE'                   => '▔',
        'LARGE UNDERLINE'                  => '▁',
        'BULLET RIGHT'                     => '▶',
        'BULLET LEFT'                      => '◀',
        'SMALL BULLET RIGHT'               => '▸',
        'SMALL BULLET LEFT'                => '◂',
        'BIG BULLET RIGHT'                 => '►',
        'BIG BULLET LEFT'                  => '◄',
        'BULLET DOWN'                      => '▼',
        'BULLET UP'                        => '▲',
        'WEDGE TOP LEFT'                   => '◢',
        'WEDGE TOP RIGHT'                  => '◣',
        'WEDGE BOTTOM LEFT'                => '◥',
        'WEDGE BOTTOM RIGHT'               => '◤',
        'LOWER ONE EIGHT BLOCK'            => '▁',
        'LOWER ONE QUARTER BLOCK'          => '▂',
        'LOWER THREE EIGHTHS BLOCK'        => '▃',
        'LOWER FIVE EIGTHS BLOCK'          => '▅',
        'LOWER THREE QUARTERS BLOCK'       => '▆',
        'LOWER SEVEN EIGHTHS BLOCK'        => '▇',
        'LEFT SEVEN EIGHTHS BLOCK'         => '▉',
        'LEFT THREE QUARTERS BLOCK'        => '▊',
        'LEFT FIVE EIGHTHS BLOCK'          => '▋',
        'LEFT THREE EIGHTHS BLOCK'         => '▍',
        'LEFT ONE QUARTER BLOCK'           => '▎',
        'LEFT ONE EIGHTH BLOCK'            => '▏',
        'MEDIUM SHADE'                     => '▒',
        'DARK SHADE'                       => ' ',
        'UPPER ONE EIGHTH BLOCK'           => '▔',
        'RIGHT ONE EIGHTH BLOCK'           => '▕',
        'LOWER LEFT QUADRANT'              => '▖',
        'LOWER RIGHT QUADRANT'             => '▗',
        'UPPER LEFT QUADRANT'              => '▘',
        'LEFT LOWER RIGHT QUADRANTS'       => '▙',
        'UPPER LEFT LOWER RIGHT QUADRANTS' => '▚',
        'LEFT UPPER RIGHT QUADRANTS'       => '▛',
        'UPPER LEFT RIGHT QUADRANTS'       => '▜',
        'UPPER RIGHT QUADRANT'             => '▝',
        'UPPER RIGHT LOWER LEFT QUADRANTS' => '▞',
        'RIGHT LOWER LEFT QUADRANTS'       => '▟',
        'THICK VERTICAL BAR'               => chr(0xA6),
        'THIN HORIZONTAL BAR'              => '─',
        'THICK HORIZONTAL BAR'             => '━',
        'THIN VERTICAL BAR'                => '│',
        'MEDIUM VERTICAL BAR'              => '┃',
        'THIN DASHED HORIZONTAL BAR'       => '┄',
        'THICK DASHED HORIZONTAL BAR'      => '┅',
        'THIN DASHED VERTICAL BAR'         => '┆',
        'THICK DASHED VERTICAL BAR'        => '┇',
        'THIN DOTTED HORIZONTAL BAR'       => '┈',
        'THICK DOTTED HORIZONTAL BAR'      => '┉',
        'MEDIUM DASHED VERTICAL BAR'       => '┊',
        'THICK DASHED VERTICAL BAR'        => '┋',
        'U250C'                            => '┌',
        'U250D'                            => '┍',
        'U250E'                            => '┎',
        'U250F'                            => '┏',
        'U2510'                            => '┐',
        'U2511'                            => '┑',
        'U2512'                            => '┒',
        'U2513'                            => '┓',
        'U2514'                            => '└',
        'U2515'                            => '┕',
        'U2516'                            => '┖',
        'U2517'                            => '┗',
        'U2518'                            => '┘',
        'U2519'                            => '┙',
        'U251A'                            => '┚',
        'U251B'                            => '┛',
        'U251C'                            => '├',
        'U251D'                            => '┝',
        'U251E'                            => '┞',
        'U251F'                            => '┟',
        'U2520'                            => '┠',
        'U2521'                            => '┡',
        'U2522'                            => '┢',
        'U2523'                            => '┣',
        'U2524'                            => '┤',
        'U2525'                            => '┥',
        'U2526'                            => '┦',
        'U2527'                            => '┧',
        'U2528'                            => '┨',
        'U2529'                            => '┩',
        'U252A'                            => '┪',
        'U252B'                            => '┫',
        'U252C'                            => '┬',
        'U252D'                            => '┭',
        'U252E'                            => '┮',
        'U252F'                            => '┯',
        'U2530'                            => '┰',
        'U2531'                            => '┱',
        'U2532'                            => '┲',
        'U2533'                            => '┳',
        'U2534'                            => '┴',
        'U2535'                            => '┵',
        'U2536'                            => '┶',
        'U2537'                            => '┷',
        'U2538'                            => '┸',
        'U2539'                            => '┹',
        'U253A'                            => '┺',
        'U253B'                            => '┻',
        'U235C'                            => '┼',
        'U253D'                            => '┽',
        'U253E'                            => '┾',
        'U253F'                            => '┿',
        'U2540'                            => '╀',
        'U2541'                            => '╁',
        'U2542'                            => '╂',
        'U2543'                            => '╃',
        'U2544'                            => '╄',
        'U2545'                            => '╅',
        'U2546'                            => '╆',
        'U2547'                            => '╇',
        'U2548'                            => '╈',
        'U2549'                            => '╉',
        'U254A'                            => '╊',
        'U254B'                            => '╋',
        'U254C'                            => '╌',
        'U254D'                            => '╍',
        'U254E'                            => '╎',
        'U254F'                            => '╏',
        'STAR'                             => '★',
        'MAPLE LEAF'                       => '🍁',
        'CHECK'                            => '✓',
        'PIE'                              => 'π',
        'TOP LEFT ROUNDED'                 => '╭',
        'TOP RIGHT ROUNDED'                => '╮',
        'BOTTOM RIGHT ROUNDED'             => '╯',
        'BOTTOM LEFT ROUNDED'              => '╰',
        'FULL FORWARD SLASH'               => '╱',
        'FULL BACKWZARD SLASH'             => '╲',
        'FULL X'                           => '╳',
        'THIN LEFT HALF HYPHEN'            => '╴',
        'THIN TOP HALF BAR'                => '╵',
        'THIN RIGHT HALF HYPHEN'           => '╶',
        'THIN BOTTOM HALF BAR'             => '╷',
        'THICK LEFT HALF HYPHEN'           => '╸',
        'THICK TOP HALF BAR'               => '╹',
        'THICK RIGHT HALF HYPHEN'          => '╺',
        'THICK BOTTOM HALF BAR'            => '╻',
        'RIGHT TELESCOPE'                  => '╼',
        'DOWN TELESCOPE'                   => '╽',
        'LEFT TELESCOPE'                   => '╾',
        'UP TELESCOPE'                     => '╿',
        'HORIZONTAL RULE RED'              => "\r" . $self->{'ansi_sequences'}->{'B_RED'} . clline . $self->{'ansi_sequences'}->{'RESET'},
        'HORIZONTAL RULE GREEN'            => "\r" . $self->{'ansi_sequences'}->{'B_GREEN'} . clline . $self->{'ansi_sequences'}->{'RESET'},
        'HORIZONTAL RULE YELLOW'           => "\r" . $self->{'ansi_sequences'}->{'B_YELLOW'} . clline . $self->{'ansi_sequences'}->{'RESET'},
        'HORIZONTAL RULE BLUE'             => "\r" . $self->{'ansi_sequences'}->{'B_BLUE'} . clline . $self->{'ansi_sequences'}->{'RESET'},
        'HORIZONTAL RULE MAGENTA'          => "\r" . $self->{'ansi_sequences'}->{'B_MAGENTA'} . clline . $self->{'ansi_sequences'}->{'RESET'},
        'HORIZONTAL RULE CYAN'             => "\r" . $self->{'ansi_sequences'}->{'B_CYAN'} . clline . $self->{'ansi_sequences'}->{'RESET'},
        'HORIZONTAL RULE WHITE'            => "\r" . $self->{'ansi_sequences'}->{'B_WHITE'} . clline . $self->{'ansi_sequences'}->{'RESET'},
    };
    foreach my $count (0 .. 255) {
        $self->{'ansi_sequences'}->{"ANSI$count"}   = $esc . '38;5;' . $count . 'm';
        $self->{'ansi_sequences'}->{"B_ANSI$count"} = $esc . '48;5;' . $count . 'm';
		if ($count >= 232 && $count <= 255) {
			my $num = $count - 232;
			$self->{'ansi_sequences'}->{"GREY$num"} = $esc . '38;5;' . $count . 'm'; 
			$self->{'ansi_sequences'}->{"B_GREY$num"} = $esc . '48;5;' . $count . 'm'; 
		}
    }
	bless($self,$class);
    return ($self);
}

__END__

=head1 NAME

ANSI Encode

=head1 SYNOPSIS

A markup language to generate basic ANSI text

=head1 AUTHOR & COPYRIGHT

Richard Kelsch

 Copyright (C) 2025 Richard Kelsch
 All Rights Reserved
 GNU Public License 3.0

=head1 USAGE

 ansi_encode.pl file

=head1 OPTIONS

=over 4

=item --B<version> or -B<v>

Shows name, version information and brief licensing information.

=item --B<help> or -B<h>

Simple usage and options documentation

=item --B<tokens> or -B<y>

Shows the most used tokens available.  A token is encapsulated within [% and %] (with one space on each side)

For example:

=back

=over 8

[% RED %]This is written in red[% RESET %]

B<RESET> changes output text to normal.

=back

=head1 TOKENS

=head2 GENERAL

 RETURN     = ASCII RETURN (13)
 LINEFEED   = ASCII LINEFEED (10)
 NEWLINE    = RETURN + LINEFEED (13 + 10)
 CLEAR      = Places cursor at top left, screen cleared
 CLS        = Same as CLEAR
 CLEAR LINE = Clear to the end of line
 CLEAR DOWN = Clear down from current cursor position
 CLEAR UP   = Clear up from current cursor position
 RESET      = Reset all colors and attributes

=head2 CURSOR

 UP          = Moves cursor up one step
 DOWN        = Moves cursor down one step
 RIGHT       = Moves cursor right one step
 LEFT        = Moves cursor left one step
 SAVE        = Save cursor position
 RESTORE     = Place cursor at saved position
 BOLD        = Bold text (not all terminals support this)
 FAINT       = Faded text (not all terminals support this)
 ITALIC      = Italicized text (not all terminals support this)
 UNDERLINE   = Underlined text
 SLOW BLINK  = Slow cursor blink
 RAPID BLINK = Rapid cursor blink

=head2 ATTRIBUTES

 INVERT       = Invert text (flip background and foreground attributes)
 REVERSE      = Reverse
 CROSSED OUT  = Crossed out
 DEFAULT FONT = Default font

=head2 COLORS

 NORMAL = Sets colors to default

=head2 FOREGROUND

 BLACK          = Black
 RED            = Red
 PINK           = Hot pink
 ORANGE         = Orange
 NAVY           = Deep blue
 GREEN          = Green
 YELLOW         = Yellow
 BLUE           = Blue
 MAGENTA        = Magenta
 CYAN           = Cyan
 WHITE          = White
 DEFAULT        = Default foreground color
 BRIGHT BLACK   = Bright black (dim grey)
 BRIGHT RED     = Bright red
 BRIGHT GREEN   = Lime
 BRIGHT YELLOW  = Bright Yellow
 BRIGHT BLUE    = Bright blue
 BRIGHT MAGENTA = Bright magenta
 BRIGHT CYAN    = Bright cyan
 BRIGHT WHITE   = Bright white

=head2 BACKGROUND

 B_BLACK          = Black
 B_RED            = Red
 B_GREEN          = Green
 B_YELLOW         = Yellow
 B_BLUE           = Blue
 B_MAGENTA        = Magenta
 B_CYAN           = Cyan
 B_WHITE          = White
 B_DEFAULT        = Default background color
 B_PINK           = Hot pink
 B_ORANGE         = Orange
 B_NAVY           = Deep blue
 BRIGHT B_BLACK   = Bright black (grey)
 BRIGHT B_RED     = Bright red
 BRIGHT B_GREEN   = Lime
 BRIGHT B_YELLOW  = Bright yellow
 BRIGHT B_BLUE    = Bright blue
 BRIGHT B_MAGENTA = Bright magenta
 BRIGHT B_CYAN    = Bright cyan
 BRIGHT B_WHITE   = Bright white

=cut
