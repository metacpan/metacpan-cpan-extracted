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
use utf8;
use charnames();
use constant {
    TRUE  => 1,
    FALSE => 0,
    YES   => 1,
    NO    => 0,
};

use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use Time::HiRes qw( sleep );
use Text::Wrap::Smart ':all';

# UTF-8 is required for special character handling
binmode(STDERR, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDIN,  ":encoding(UTF-8)");

BEGIN {
    our $VERSION = '1.29';
}

sub ansi_output {
    my $self = shift;
    my $text = shift;

    if (length($text) > 1) {
        while ($text =~ /\[\% (.*?) \%\]/) {
			while ($text =~ /\[\% SCROLL UP (\d+)\s+\%\]/) {
				my $s = $1;
				my $replace = $self->{'ansi_sequences'}->{'CSI'} . $s . 'S';
				$text =~ s/\[\% SCROLL UP $s\s+\%\]/$replace/g;
			}
			while ($text =~ /\[\% SCROLL DOWN (\d+)\s+\%\]/) {
				my $s = $1;
				my $replace = $self->{'ansi_sequences'}->{'CSI'} . $s . 'T';
				$text =~ s/\[\% SCROLL DOWN $s\s+\%\]/$replace/g;
			}
			while ($text =~ /\[\% RGB (\d+),(\d+),(\d+)\s+\%\]/) {
				my ($r,$g,$b) = ($1,$2,$3);
				my $replace = $self->{'ansi_sequences'}->{'CSI'} . "38:2:$r:$g:$b" . 'm';
				$text =~ s/\[\% RGB $r,$g,$b\s+\%\]/$replace/g;
			}
			while ($text =~ /\[\% B_RGB (\d+),(\d+),(\d+)\s+\%\]/) {
				my ($r,$g,$b) = ($1,$2,$3);
				my $replace = $self->{'ansi_sequences'}->{'CSI'} . "48:2:$r:$g:$b" . 'm';
				$text =~ s/\[\% B_RGB $r,$g,$b\s+\%\]/$replace/g;
			}
			while ($text =~ /\[\% COLOR (\d+)\s+\%\]/) {
				my $c = $1;
				my $replace = $self->{'ansi_sequences'}->{'CSI'} . "38:5:$c" . 'm';
				$text =~ s/\[\% COLOR $c\s+\%\]/$replace/g;
			}
			while ($text =~ /\[\% B_COLOR (\d+)\s+\%\]/) {
				my $c = $1;
				my $replace = $self->{'ansi_sequences'}->{'CSI'} . "48:5:$c" . 'm';
				$text =~ s/\[\% B_COLOR $c\s+\%\]/$replace/g;
			}
			while ($text =~ /\[\% GREY (\d+)\s+\%\]/) {
				my $g = $1;
				my $replace = $self->{'ansi_sequences'}->{'CSI'} . '38:5:' . (232 + $g) . 'm';
				$text =~ s/\[\% GREY $g\s+\%\]/$replace/g;
			}
			while ($text =~ /\[\% B_GREY (\d+)\s+\%\]/) {
				my $g = $1;
				my $replace = $self->{'ansi_sequences'}->{'CSI'} . '48:5:' . (232 + $g) . 'm';
				$text =~ s/\[\% B_GREY $g\s+\%\]/$replace/g;
			}
            while ($text =~ /\[\%\s+BOX (.*?),(\d+),(\d+),(\d+),(\d+),(.*?)\s+\%\](.*?)\[\%\s+ENDBOX\s+\%\]/i) {
                my $replace = $self->box($1, $2, $3, $4, $5, $6, $7);
                $text =~ s/\[\%\s+BOX.*?\%\].*?\[\%\s+ENDBOX.*?\%\]/$replace/i;
            }
            foreach my $string (keys %{ $self->{'ansi_sequences'} }) {
                $text =~ s/\[\%\s+$string\s+\%\]/$self->{'ansi_sequences'}->{$string}/gi;
            }
            foreach my $string (keys %{ $self->{'characters'}->{'NAME'} }) {
                $text =~ s/\[\%\s+$string\s+\%\]/$self->{'characters'}->{'NAME'}->{$string}/gi;
            }
            foreach my $string (keys %{ $self->{'characters'}->{'UNICODE'} }) {
                $text =~ s/\[\%\s+$string\s+\%\]/$self->{'characters'}->{'UNICODE'}->{$string}/gi;
            }
        } ## end while ($text =~ /\[\% (.*?) \%\]/)
        $text =~ s/\[ \% TOKEN \% \]/\[\% TOKEN \%\]/;
        print $text;
    } ## end if (length($text) > 1)
    return (TRUE);
} ## end sub ansi_output

sub box {
    my $self   = shift;
    my $color  = '[% ' . shift . ' %]';
    my $x      = shift;
    my $y      = shift;
    my $w      = shift;
    my $h      = shift;
    my $type   = shift;
    my $string = shift;

    my $tl  = '╔';
    my $tr  = '╗';
    my $bl  = '╚';
    my $br  = '╝';
    my $mid = '═';
    my $v   = '║';
    if ($type =~ /THIN/i) {
        $tl  = '┌';
        $tr  = '┐';
        $bl  = '└';
        $br  = '┘';
        $mid = '─';
        $v   = '│';
    } elsif ($type =~ /ROUND/i) {
        $tl  = '╭';
        $tr  = '╮';
        $bl  = '╰';
        $br  = '╯';
        $mid = '─';
        $v   = '│';
    } elsif ($type =~ /THICK/i) {
        $tl  = '┏';
        $tr  = '┓';
        $bl  = '┗';
        $br  = '┛';
        $mid = '━';
        $v   = '┃';
    } ## end elsif ($type =~ /THICK/i)
    my $text = '';
    my $xx   = $x;
    my $yy   = $y;
    $text .= locate($yy++, $xx) . $color . $tl . $mid x ($w - 2) . $tr . '[% RESET %]';
    foreach my $count (1 .. ($h - 2)) {
        $text .= locate($yy++, $xx) . $color . $v . '[% RESET %]' . ' ' x ($w - 2) . $color . $v . '[% RESET %]';
    }
    $text .= locate($yy++,  $xx) . $color . $bl . $mid x ($w - 2) . $br . '[% RESET %]' . $self->{'ansi_sequences'}->{'SAVE'};
    $text .= locate($y + 1, $x + 1);
    chomp(my @lines = fuzzy_wrap($string, ($w - 3)));
    $xx = $x + 1;
    $yy = $y + 1;
    foreach my $line (@lines) {
        $text .= locate($yy++, $xx) . $line;
    }
    $text .= $self->{'ansi_sequences'}->{'RESTORE'};
    return ($text);
} ## end sub box

sub new {
    my $class = shift;

    my $esc = chr(27);
    my $csi = $esc . '[';

    my $self = {
        'ansi_prefix'    => $csi,
        'mode'           => 'long',
        'ansi_sequences' => {
            'SS2'      => $esc . 'N',
            'SS3'      => $esc . 'O',
            'CSI'      => $esc . '[',
            'OSC'      => $esc . ']',
            'SOS'      => $esc . 'X',
            'ST'       => $esc . "\\",
            'DCS'      => $esc . 'P',
            'RETURN'   => chr(13),
            'LINEFEED' => chr(10),
            'NEWLINE'  => chr(13) . chr(10),

            'CLS'        => $csi . '2J' . $csi . 'H',
            'CLEAR'      => $csi . '2J',
            'CLEAR LINE' => $csi . '0K',
            'CLEAR DOWN' => $csi . '0J',
            'CLEAR UP'   => $csi . '1J',
            'HOME'       => $csi . 'H',

            # Cursor
            'UP'            => $csi . 'A',
            'DOWN'          => $csi . 'B',
            'RIGHT'         => $csi . 'C',
            'LEFT'          => $csi . 'D',
            'NEXT LINE'     => $csi . 'E',
            'PREVIOUS LINE' => $csi . 'F',
            'SAVE'          => $csi . 's',
            'RESTORE'       => $csi . 'u',
            'RESET'         => $csi . '0m',
            'CURSOR ON'     => $csi . '?25h',
            'CURSOR OFF'    => $csi . '?25l',
            'SCREEN 1'      => $csi . '?1049l',
            'SCREEN 2'      => $csi . '?1049h',

            # Attributes
            'BOLD'                    => $csi . '1m',
            'NORMAL'                  => $csi . '22m',
            'FAINT'                   => $csi . '2m',
            'ITALIC'                  => $csi . '3m',
            'UNDERLINE'               => $csi . '4m',
            'FRAMED'                  => $csi . '51m',
            'FRAMED OFF'              => $csi . '54m',
            'ENCIRCLED'               => $csi . '52m',
            'ENCIRCLED OFF'           => $csi . '54m',
            'OVERLINED'               => $csi . '53m',
            'OVERLINED OFF'           => $csi . '55m',
            'DEFAULT UNDERLINE COLOR' => $csi . '59m',
            'SUPERSCRIPT'             => $csi . '73m',
            'SUBSCRIPT'               => $csi . '74m',
            'SUPERSCRIPT OFF'         => $csi . '75m',
            'SUBSCRIPT OFF'           => $csi . '75m',
            'SLOW BLINK'              => $csi . '5m',
            'RAPID BLINK'             => $csi . '6m',
            'INVERT'                  => $csi . '7m',
            'REVERSE'                 => $csi . '7m',
            'HIDE'                    => $csi . '8m',
            'REVEAL'                  => $csi . '28m',
            'CROSSED OUT'             => $csi . '9m',
            'DEFAULT FONT'            => $csi . '10m',
            'PROPORTIONAL ON'         => $csi . '26m',
            'PROPORTIONAL OFF'        => $csi . '50m',

            # Color

            # Foreground color
            'DEFAULT'        => $csi . '39m',
            'BLACK'          => $csi . '30m',
            'RED'            => $csi . '31m',
            'PINK'           => $csi . '38;5;198m',
            'ORANGE'         => $csi . '38;5;202m',
            'NAVY'           => $csi . '38;5;17m',
            'GREEN'          => $csi . '32m',
            'YELLOW'         => $csi . '33m',
            'BLUE'           => $csi . '34m',
            'MAGENTA'        => $csi . '35m',
            'CYAN'           => $csi . '36m',
            'WHITE'          => $csi . '37m',
            'BRIGHT BLACK'   => $csi . '90m',
            'BRIGHT RED'     => $csi . '91m',
            'BRIGHT GREEN'   => $csi . '92m',
            'BRIGHT YELLOW'  => $csi . '93m',
            'BRIGHT BLUE'    => $csi . '94m',
            'BRIGHT MAGENTA' => $csi . '95m',
            'BRIGHT CYAN'    => $csi . '96m',
            'BRIGHT WHITE'   => $csi . '97m',

            # Background color
            'B_DEFAULT'        => $csi . '49m',
            'B_BLACK'          => $csi . '40m',
            'B_RED'            => $csi . '41m',
            'B_GREEN'          => $csi . '42m',
            'B_YELLOW'         => $csi . '43m',
            'B_BLUE'           => $csi . '44m',
            'B_MAGENTA'        => $csi . '45m',
            'B_CYAN'           => $csi . '46m',
            'B_WHITE'          => $csi . '47m',
            'B_DEFAULT'        => $csi . '49m',
            'B_PINK'           => $csi . '48;5;198m',
            'B_ORANGE'         => $csi . '48;5;202m',
            'B_NAVY'           => $csi . '48;5;17m',
            'BRIGHT B_BLACK'   => $csi . '100m',
            'BRIGHT B_RED'     => $csi . '101m',
            'BRIGHT B_GREEN'   => $csi . '102m',
            'BRIGHT B_YELLOW'  => $csi . '103m',
            'BRIGHT B_BLUE'    => $csi . '104m',
            'BRIGHT B_MAGENTA' => $csi . '105m',
            'BRIGHT B_CYAN'    => $csi . '106m',
            'BRIGHT B_WHITE'   => $csi . '107m',

            # MACROS
            'HORIZONTAL RULE ORANGE'         => '[% RETURN %][% B_ORANGE %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE PINK'           => '[% RETURN %][% B_PINK %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE RED'            => '[% RETURN %][% B_RED %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE BRIGHT RED'     => '[% RETURN %][% BRIGHT B_RED %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE GREEN'          => '[% RETURN %][% B_GREEN %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE BRIGHT GREEN'   => '[% RETURN %][% BRIGHT B_GREEN %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE YELLOW'         => '[% RETURN %][% B_YELLOW %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE BRIGHT YELLOW'  => '[% RETURN %][% BRIGHT B_YELLOW %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE BLUE'           => '[% RETURN %][% B_BLUE %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE BRIGHT BLUE'    => '[% RETURN %][% BRIGHT B_BLUE %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE MAGENTA'        => '[% RETURN %][% B_MAGENTA %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE BRIGHT MAGENTA' => '[% RETURN %][% BRIGHT B_MAGENTA %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE CYAN'           => '[% RETURN %][% B_CYAN %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE BRIGHT CYAN'    => '[% RETURN %][% BRIGHT B_CYAN %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE WHITE'          => '[% RETURN %][% B_WHITE %][% CLEAR LINE %][% RESET %]',
            'HORIZONTAL RULE BRIGHT WHITE'   => '[% RETURN %][% BRIGHT B_WHITE %][% CLEAR LINE %][% RESET %]',
        },
        @_,
    };

    # Alternate Fonts
    foreach my $count (1 .. 9) {
        $self->{ 'FONT ' . $count } = $csi . ($count + 10);
    }

    # 20D0 - 20EF
    # 2100 - 218B
    # 2190 - 23FF
    # 2500 - 27FF
    # 2900 - 2BFE
    # 3001 - 3030
    # 1F300 - 1F5FF
    # 1F600 - 1F64F
    # 1F680 - 1F6F8
    # 1F780 - 1F7D8
    # 1F800 - 1F8B1
    # 1F900 - 1F997
    # 1F9D0 - 1F9E6

    # Generate symbols
    my $start  = 0x2400;
    my $finish = 0x2605;
    if ($self->{'mode'} =~ /full|long/i) {
        $start  = 0x2010;
        $finish = 0x2BFF;
    }

    my $name = charnames::viacode(0x1F341);    # Maple Leaf
    $self->{'characters'}->{'NAME'}->{$name} = charnames::string_vianame($name);
    $self->{'characters'}->{'UNICODE'}->{'U1F341'} = charnames::string_vianame($name);
    foreach my $u ($start .. $finish) {
        $name = charnames::viacode($u);
        next if ($name eq '');
        my $char = charnames::string_vianame($name);
        $char = '?' unless (defined($char));
        $self->{'characters'}->{'NAME'}->{$name} = $char;
        $self->{'characters'}->{'UNICODE'}->{ sprintf('U%05X', $u) } = $char;
    } ## end foreach my $u ($start .. $finish)
    if ($self->{'mode'} =~ /full|long/i) {
        $start  = 0x1F300;
        $finish = 0x1FBFF;
        foreach my $u ($start .. $finish) {
            $name = charnames::viacode($u);
            next if ($name eq '');
            my $char = charnames::string_vianame($name);
            $char = '?' unless (defined($char));
            $self->{'characters'}->{'NAME'}->{$name} = $char;
            $self->{'characters'}->{'UNICODE'}->{ sprintf('U%05X', $u) } = $char;
        } ## end foreach my $u ($start .. $finish)
    } ## end if ($self->{'mode'} =~...)
    bless($self, $class);
    return ($self);
} ## end sub new

__END__

=head1 NAME

ANSI Encode

=head1 SYNOPSIS

A markup language to generate basic ANSI text
This module is for use with the executable file

=head1 USAGE

 my $obj = Term::ANSIEncode->new();
 $obj->output($string); # $string contains the markup to be converted and sent to STDOUT.

See the manual for "ansi-encode" to use a script to load a file directly.

Use this version for a full list of symbols:
 my $obj = Term::ANSIEncode->new('mode' => 'long');

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

 HOME        = Moves the cursor home to location 1,1.
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

=head2 FRAMES

 BOX & ENDBOX = Draw a frame

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

=head2 HORIZONAL RULES

Makes a solid blank line, the full width of the screen with the selected background color

 HORIZONTAL RULE RED             = A solid line of red background
 HORIZONTAL RULE GREEN           = A solid line of green background
 HORIZONTAL RULE YELLOW          = A solid line of yellow background
 HORIZONTAL RULE BLUE            = A solid line of blue background
 HORIZONTAL RULE MAGENTA         = A solid line of magenta background
 HORIZONTAL RULE CYAN            = A solid line of cyan background
 HORIZONTAL RULE PINK            = A solid line of hot pink background
 HORIZONTAL RULE ORANGE          = A solid line of orange background
 HORIZONTAL RULE WHITE           = A solid line of white background
 HORIZONTAL RULE BRIGHT RED      = A solid line of bright red background
 HORIZONTAL RULE BRIGHT GREEN    = A solid line of bright green background
 HORIZONTAL RULE BRIGHT YELLOW   = A solid line of bright yellow background
 HORIZONTAL RULE BRIGHT BLUE     = A solid line of bright blue background
 HORIZONTAL RULE BRIGHT MAGENTA  = A solid line of bright magenta background
 HORIZONTAL RULE BRIGHT CYAN     = A solid line of bright cyan background
 HORIZONTAL RULE BRIGHT WHITE    = A solid line of bright white background

=head1 AUTHOR & COPYRIGHT

Richard Kelsch

 Copyright (C) 2025 Richard Kelsch
 All Rights Reserved
 Perl Artistic License

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut
