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
    our $VERSION = '1.33';
}

sub ansi_description {
	my $self = shift;
	my $code = shift;
	my $name = shift;

	return($self->{'ansi_meta'}->{$code}->{$name}->{'desc'});
}

sub ansi_decode {
    my $self = shift;
    my $text = shift;

    if (length($text) > 1) {
        my $csi = $self->{'ansi_sequences'}->{'CSI'};
        while ($text =~ /\[\%\s+LOCATE (\d+),(\d+)\s+\%\]/) {
            my ($c, $r) = ($1, $2);
            my $replace = $csi . "$r;$c" . 'H';
            $text =~ s/\[\%\s+LOCATE $c,$r\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+SCROLL UP (\d+)\s+\%\]/) {
            my $s       = $1;
            my $replace = $csi . $s . 'S';
            $text =~ s/\[\%\s+SCROLL UP $s\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+SCROLL DOWN (\d+)\s+\%\]/) {
            my $s       = $1;
            my $replace = $csi . $s . 'T';
            $text =~ s/\[\%\s+SCROLL DOWN $s\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+RGB (\d+),(\d+),(\d+)\s+\%\]/) {
            my ($r, $g, $b) = ($1 & 255, $2 & 255, $3 & 255);
            my $replace = $csi . "38:2:$r:$g:$b" . 'm';
            $text =~ s/\[\%\s+RGB $r,$g,$b\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+B_RGB (\d+),(\d+),(\d+)\s+\%\]/) {
            my ($r, $g, $b) = ($1 & 255, $2 & 255, $3 & 255);
            my $replace = $csi . "48:2:$r:$g:$b" . 'm';
            $text =~ s/\[\%\s+B_RGB $r,$g,$b\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+(COLOR|COLOUR) (\d+)\s+\%\]/) {
            my $n       = $1;
            my $c       = $2 & 255;
            my $replace = $csi . "38:5:$c" . 'm';
            $text =~ s/\[\%\s+$n $c\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+(B_COLOR|B_COLOUR) (\d+)\s+\%\]/) {
            my $n       = $1;
            my $c       = $2 & 255;
            my $replace = $csi . "48:5:$c" . 'm';
            $text =~ s/\[\%\s+$n $c\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+GREY (\d+)\s+\%\]/) {
            my $g       = $1;
            my $replace = $csi . '38:5:' . (232 + $g) . 'm';
            $text =~ s/\[\%\s+GREY $g\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+B_GREY (\d+)\s+\%\]/) {
            my $g       = $1;
            my $replace = $csi . '48:5:' . (232 + $g) . 'm';
            $text =~ s/\[\%\s+B_GREY $g\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+BOX (.*?),(\d+),(\d+),(\d+),(\d+),(.*?)\s+\%\](.*?)\[\%\s+ENDBOX\s+\%\]/i) {
            my $replace = $self->box($1, $2, $3, $4, $5, $6, $7);
            $text =~ s/\[\%\s+BOX.*?\%\].*?\[\%\s+ENDBOX.*?\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+HORIZONTAL RULE (.*?)\s+\%\]/) {
            my $color = $1;
            my $new   = '[% RETURN %][% B_' . $color . ' %][% CLEAR LINE %][% RESET %]';
            $text =~ s/\[\%\s+HORIZONTAL RULE (.*?)\s+\%\]/$new/;
        }
		while ($text =~ /\[\%\s+(.*?)\s+\%\]/ && (exists($self->{'ansi_sequences'}->{$1}) || defined(charnames::string_vianame($1)))) {
			my $string = $1;
			if (exists($self->{'ansi_sequences'}->{$string})) {
				$text =~ s/\[\%\s+$string\s+\%\]/$self->{'ansi_sequences'}->{$string}/gsi;
			} else {
				my $char = charnames::string_vianame($string);
				$char = '?' unless (defined($char));
				$text =~ s/\[\%\s+$string\s+\%\]/$char/gi;
			}
		}
	} ## end if (length($text) > 1)
    return ($text);
} ## end sub ansi_decode

sub ansi_output {
    my $self = shift;
    my $text = shift;

    $text = $self->ansi_decode($text);
    $text =~ s/\[ \% TOKEN \% \]/\[\% TOKEN \%\]/;
    print $text;
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
    my $top = '═';
    my $bot = '═';
    my $vl  = '║';
    my $vr  = '║';

    if ($type =~ /THIN/i) {
        $tl  = '┌';
        $tr  = '┐';
        $bl  = '└';
        $br  = '┘';
        $top = '─';
        $bot = '─';
        $vl  = '│';
        $vr  = '│';
    } elsif ($type =~ /ROUND/i) {
        $tl  = '╭';
        $tr  = '╮';
        $bl  = '╰';
        $br  = '╯';
        $top = '─';
        $bot = '─';
        $vl  = '│';
        $vr  = '│';
    } elsif ($type =~ /THICK/i) {
        $tl  = '┏';
        $tr  = '┓';
        $bl  = '┗';
        $br  = '┛';
        $top = '━';
        $bot = '━';
        $vl  = '┃';
        $vl  = '┃';
    } elsif ($type =~ /BLOCK/i) {
        $tl  = '🬚';
        $tr  = '🬩';
        $bl  = '🬌';
        $br  = '🬍';
        $top = '🬋';
        $bot = '🬋';
        $vl  = '▌';
        $vr  = '▐';
    } elsif ($type =~ /WEDGE/i) {
        $tl  = '🭊';
        $tr  = '🬿';
        $bl  = '🭥';
        $br  = '🭚';
        $top = '▅';
        $bot = '🮄';
        $vl  = '█';
        $vr  = '█';
    } elsif ($type =~ /DOTS/i) {
        $tl  = '⏺';
        $tr  = '⏺';
        $bl  = '⏺';
        $br  = '⏺';
        $top = '⏺';
        $bot = '⏺';
        $vl  = '⏺';
        $vr  = '⏺';
    } elsif ($type =~ /DIAMOND/i) {
        $tl  = '🞙';
        $tr  = '🞙';
        $bl  = '🞙';
        $br  = '🞙';
        $top = '🞙';
        $bot = '🞙';
        $vl  = '🞙';
        $vr  = '🞙';
    } elsif ($type =~ /STAR/i) {
        $tl  = '⭑';
        $tr  = '⭑';
        $bl  = '⭑';
        $br  = '⭑';
        $top = '⭑';
        $bot = '⭑';
        $vl  = '⭑';
        $vr  = '⭑';
    } elsif ($type =~ /SQUARE/i) {
        $tl  = '⏹';
        $tr  = '⏹';
        $bl  = '⏹';
        $br  = '⏹';
        $top = '⏹';
        $bot = '⏹';
        $vl  = '⏹';
        $vr  = '⏹';
    } ## end elsif ($type =~ /SQUARE/i)
    my $text = '';
    my $xx   = $x;
    my $yy   = $y;
    $text .= locate($yy++, $xx) . $color . $tl . $top x ($w - 2) . $tr . '[% RESET %]';
    foreach my $count (1 .. ($h - 2)) {
        $text .= locate($yy++, $xx) . $color . $vl . '[% RESET %]' . ' ' x ($w - 2) . $color . $vr . '[% RESET %]';
    }
    $text .= locate($yy++,  $xx) . $color . $bl . $bot x ($w - 2) . $br . '[% RESET %]' . $self->{'ansi_sequences'}->{'SAVE'};
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
        'start'          => 0x20,
        'finish'         => 0x1FBFF,
        'ansi_meta' => {
            'special' => {
                'SS2' => {
                    'out'  => $esc . 'N',
                    'desc' => '',
                },
                'SS3' => {
                    'out'  => $esc . 'O',
                    'desc' => '',
                },
                'CSI' => {
                    'out'  => $esc . '[',
                    'desc' => 'Control Sequence Identifier',
                },
                'OSC' => {
                    'out'  => $esc . ']',
                    'desc' => '',
                },
                'SOS' => {
                    'out'  => $esc . 'X',
                    'desc' => '',
                },
                'ST' => {
                    'out'  => $esc . "\\",
                    'desc' => '',
                },
                'DCS' => {
                    'out'  => $esc . 'P',
                    'desc' => '',
                },
            },

           'clear' => {
                'CLS' => {
                    'out'  => $csi . '2J' . $csi . 'H',
                    'desc' => 'Clear screen and place cursor at the top of the screen',
                },
                'CLEAR' => {
                    'out'  => $csi . '2J',
                    'desc' => 'Clear screen and keep cursor location',
                },
                'CLEAR LINE' => {
                    'out'  => $csi . '0K',
                    'desc' => 'Clear the current line from cursor',
                },
                'CLEAR DOWN' => {
                    'out'  => $csi . '0J',
                    'desc' => 'Clear from cursor position to bottom of the screen',
                },
                'CLEAR UP' => {
                    'out'  => $csi . '1J',
                    'desc' => 'Clear to the top of the screen from cursor position',
                },
            },

            'cursor' => {
                'RETURN' => {
                    'out'  => chr(13),
                    'desc' => 'Carriage Return (ASCII 13)',
                },
                'LINEFEED' => {
                    'out'  => chr(10),
                    'desc' => 'Line feed (ASCII 10)',
                },
                'NEWLINE' => {
                    'out'  => chr(13) . chr(10),
                    'desc' => 'New line (ASCII 13 and ASCII 10)',
                },
                'HOME' => {
                    'out'  => $csi . 'H',
                    'desc' => 'Place cursor at top left of the screen',
                },
                'UP' => {
                    'out'  => $csi . 'A',
                    'desc' => 'Move cursor up one line',
                },
                'DOWN' => {
                    'out'  => $csi . 'B',
                    'desc' => 'Move cursor down one line',
                },
                'RIGHT' => {
                    'out'  => $csi . 'C',
                    'desc' => 'Move cursor right one space non-destructively',
                },
                'LEFT' => {
                    'out'  => $csi . 'D',
                    'desc' => 'Move cursor left one space non-destructively',
                },
                'NEXT LINE' => {
                    'out'  => $csi . 'E',
                    'desc' => '',
                },
                'PREVIOUS LINE' => {
                    'out'  => $csi . 'F',
                    'desc' => '',
                },
                'SAVE' => {
                    'out'  => $csi . 's',
                    'desc' => 'Save cureent cursor position',
                },
                'RESTORE' => {
                    'out'  => $csi . 'u',
                    'desc' => 'Restore the cursor to the saved position',
                },
                'CURSOR ON' => {
                    'out'  => $csi . '?25h',
                    'desc' => 'Turn the cursor on',
                },
                'CURSOR OFF' => {
                    'out'  => $csi . '?25l',
                    'desc' => 'Turn the cursor off',
                },
                'SCREEN 1' => {
                    'out'  => $csi . '?1049l',
                    'desc' => 'Set display to screen 1',
                },
                'SCREEN 2' => {
                    'out'  => $csi . '?1049h',
                    'desc' => 'Set display to screen 2',
                },
            },

            'attributes' => {
                'RESET' => {
                    'out'  => $csi . '0m',
                    'desc' => 'Restore all attributes and colors to their defaults',
                },
                'BOLD' => {
                    'out'  => $csi . '1m',
                    'desc' => 'Set to bold text',
                },
                'NORMAL' => {
                    'out'  => $csi . '22m',
                    'desc' => 'Turn off all attributes',
                },
                'FAINT' => {
                    'out'  => $csi . '2m',
                    'desc' => 'Set to faint (light) text',
                },
                'ITALIC' => {
                    'out'  => $csi . '3m',
                    'desc' => 'Set to italic text',
                },
                'UNDERLINE' => {
                    'out'  => $csi . '4m',
                    'desc' => 'Set to underlined text',
                },
                'FRAMED' => {
                    'out'  => $csi . '51m',
                    'desc' => 'Turn on framed text',
                },
                'FRAMED OFF' => {
                    'out'  => $csi . '54m',
                    'desc' => 'Turn off framed text',
                },
                'ENCIRCLED' => {
                    'out'  => $csi . '52m',
                    'desc' => 'Turn on encircled letters',
                },
                'ENCIRCLED OFF' => {
                    'out'  => $csi . '54m',
                    'desc' => 'Turn off encircled letters',
                },
                'OVERLINED' => {
                    'out'  => $csi . '53m',
                    'desc' => 'Turn on overlined text',
                },
                'OVERLINED OFF' => {
                    'out'  => $csi . '55m',
                    'desc' => 'Turn off overlined text',
                },
                'DEFAULT UNDERLINE COLOR' => {
                    'out'  => $csi . '59m',
                    'desc' => 'Set underline color to the default',
                },
                'SUPERSCRIPT' => {
                    'out'  => $csi . '73m',
                    'desc' => 'Turn on superscript',
                },
                'SUBSCRIPT' => {
                    'out'  => $csi . '74m',
                    'desc' => 'Turn on superscript',
                },
                'SUPERSCRIPT OFF' => {
                    'out'  => $csi . '75m',
                    'desc' => 'Turn off superscript',
                },
                'SUBSCRIPT OFF' => {
                    'out'  => $csi . '75m',
                    'desc' => 'Turn off subscript',
                },
                'SLOW BLINK' => {
                    'out'  => $csi . '5m',
                    'desc' => 'Set slow blink',
                },
                'RAPID BLINK' => {
                    'out'  => $csi . '6m',
                    'desc' => 'Set rapid blink',
                },
                'INVERT' => {
                    'out'  => $csi . '7m',
                    'desc' => 'Invert text',
                },
                'REVERSE' => {
                    'out'  => $csi . '7m',
                    'desc' => 'Invert text',
                },
                'HIDE' => {
                    'out'  => $csi . '8m',
                    'desc' => 'Hide enclosed text',
                },
                'REVEAL' => {
                    'out'  => $csi . '28m',
                    'desc' => 'Reveal hidden text',
                },
                'CROSSED OUT' => {
                    'out'  => $csi . '9m',
                    'desc' => 'Crossed out text',
                },
                'DEFAULT FONT' => {
                    'out'  => $csi . '10m',
                    'desc' => 'Set default font',
                },
                'PROPORTIONAL ON' => {
                    'out'  => $csi . '26m',
                    'desc' => 'Turn on proportional text',
                },
                'PROPORTIONAL OFF' => {
                    'out'  => $csi . '50m',
                    'desc' => 'Turn off proportional text',
                },
            },

            # Color

            'foreground' => {
                'DEFAULT' => {
                    'out'  => $csi . '39m',
                    'desc' => 'Default color',
                },
                'BLACK' => {
                    'out'  => $csi . '30m',
                    'desc' => 'Black',
                },
                'RED' => {
                    'out'  => $csi . '31m',
                    'desc' => 'Red',
                },
                'DARK RED' => {
                    'out'  => $csi . '38:2:139:0:0m',
                    'desc' => 'Dark red',
                },
                'PINK' => {
                    'out'  => $csi . '38;5;198m',
                    'desc' => 'Pink',
                },
                'ORANGE' => {
                    'out'  => $csi . '38;5;202m',
                    'desc' => 'Orange',
                },
                'NAVY' => {
                    'out'  => $csi . '38;5;17m',
                    'desc' => 'Navy',
                },
                'BROWN' => {
                    'out'  => $csi . '38:2:165:42:42m',
                    'desc' => 'Brown',
                },
                'MAROON' => {
                    'out'  => $csi . '38:2:128:0:0m',
                    'desc' => 'Maroon',
                },
                'OLIVE' => {
                    'out'  => $csi . '38:2:128:128:0m',
                    'desc' => 'Olive',
                },
                'PURPLE' => {
                    'out'  => $csi . '38:2:128:0:128m',
                    'desc' => 'Purple',
                },
                'TEAL' => {
                    'out'  => $csi . '38:2:0:128:128m',
                    'desc' => 'Teal',
                },
                'GREEN' => {
                    'out'  => $csi . '32m',
                    'desc' => 'Green',
                },
                'YELLOW' => {
                    'out'  => $csi . '33m',
                    'desc' => 'Yellow',
                },
                'BLUE' => {
                    'out'  => $csi . '34m',
                    'desc' => 'Blue',
                },
                'MAGENTA' => {
                    'out'  => $csi . '35m',
                    'desc' => 'Magenta',
                },
                'CYAN' => {
                    'out'  => $csi . '36m',
                    'desc' => 'Cyan',
                },
                'WHITE' => {
                    'out'  => $csi . '37m',
                    'desc' => 'White',
                },
                'BRIGHT BLACK' => {
                    'out'  => $csi . '90m',
                    'desc' => 'Bright black',
                },
                'BRIGHT RED' => {
                    'out'  => $csi . '91m',
                    'desc' => 'Bright red',
                },
                'BRIGHT GREEN' => {
                    'out'  => $csi . '92m',
                    'desc' => 'Bright green',
                },
                'BRIGHT YELLOW' => {
                    'out'  => $csi . '93m',
                    'desc' => 'Bright yellow',
                },
                'BRIGHT BLUE' => {
                    'out'  => $csi . '94m',
                    'desc' => 'Bright blue',
                },
                'BRIGHT MAGENTA' => {
                    'out'  => $csi . '95m',
                    'desc' => 'Bright magenta',
                },
                'BRIGHT CYAN' => {
                    'out'  => $csi . '96m',
                    'desc' => 'Bright cyan',
                },
                'BRIGHT WHITE' => {
                    'out'  => $csi . '97m',
                    'desc' => 'Bright white',
                },
                'FIREBRICK' => {
                    'out'  => $csi . '38:2:178:34:34m',
                    'desc' => 'Firebrick',
                },
                'CRIMSON' => {
                    'out'  => $csi . '38:2:220:20:60m',
                    'desc' => 'Crimson',
                },
                'TOMATO' => {
                    'out'  => $csi . '38:2:255:99:71m',
                    'desc' => 'Tomato',
                },
                'CORAL' => {
                    'out'  => $csi . '38:2:255:127:80m',
                    'desc' => 'Coral',
                },
                'INDIAN RED' => {
                    'out'  => $csi . '38:2:205:92:92m',
                    'desc' => 'Indian red',
                },
                'LIGHT CORAL' => {
                    'out'  => $csi . '38:2:240:128:128m',
                    'desc' => 'Light coral',
                },
                'DARK SALMON' => {
                    'out'  => $csi . '38:2:233:150:122m',
                    'desc' => 'Dark salmon',
                },
                'SALMON' => {
                    'out'  => $csi . '38:2:250:128:114m',
                    'desc' => 'Salmon',
                },
                'LIGHT SALMON' => {
                    'out'  => $csi . '38:2:255:160:122m',
                    'desc' => 'Light salmon',
                },
                'ORANGE RED' => {
                    'out'  => $csi . '38:2:255:69:0m',
                    'desc' => 'Orange red',
                },
                'DARK ORANGE' => {
                    'out'  => $csi . '38:2:255:140:0m',
                    'desc' => 'Dark orange',
                },
                'GOLD' => {
                    'out'  => $csi . '38:2:255:215:0m',
                    'desc' => 'Gold',
                },
                'DARK GOLDEN ROD' => {
                    'out'  => $csi . '38:2:184:134:11m',
                    'desc' => 'Dark golden rod',
                },
                'GOLDEN ROD' => {
                    'out'  => $csi . '38:2:218:165:32m',
                    'desc' => 'Golden rod',
                },
                'PALE GOLDEN ROD' => {
                    'out'  => $csi . '38:2:238:232:170m',
                    'desc' => 'Pale golden rod',
                },
                'DARK KHAKI' => {
                    'out'  => $csi . '38:2:189:183:107m',
                    'desc' => 'Dark khaki',
                },
                'KHAKI' => {
                    'out'  => $csi . '38:2:240:230:140m',
                    'desc' => 'Khaki',
                },
                'YELLOW GREEN' => {
                    'out'  => $csi . '38:2:154:205:50m',
                    'desc' => 'Yellow green',
                },
                'DARK OLIVE GREEN' => {
                    'out'  => $csi . '38:2:85:107:47m',
                    'desc' => 'Dark olive green',
                },
                'OLIVE DRAB' => {
                    'out'  => $csi . '38:2:107:142:35m',
                    'desc' => 'Olive drab',
                },
                'LAWN GREEN' => {
                    'out'  => $csi . '38:2:124:252:0m',
                    'desc' => 'Lawn green',
                },
                'CHARTREUSE' => {
                    'out'  => $csi . '38:2:127:255:0m',
                    'desc' => 'Chartreuse',
                },
                'GREEN YELLOW' => {
                    'out'  => $csi . '38:2:173:255:47m',
                    'desc' => 'Green yellow',
                },
                'DARK GREEN' => {
                    'out'  => $csi . '38:2:0:100:0m',
                    'desc' => 'Dark green',
                },
                'FOREST GREEN' => {
                    'out'  => $csi . '38:2:34:139:34m',
                    'desc' => 'Forest green',
                },
                'LIME GREEN' => {
                    'out'  => $csi . '38:2:50:205:50m',
                    'desc' => 'Lime Green',
                },
                'LIGHT GREEN' => {
                    'out'  => $csi . '38:2:144:238:144m',
                    'desc' => 'Light green',
                },
                'PALE GREEN' => {
                    'out'  => $csi . '38:2:152:251:152m',
                    'desc' => 'Pale green',
                },
                'DARK SEA GREEN' => {
                    'out'  => $csi . '38:2:143:188:143m',
                    'desc' => 'Dark sea green',
                },
                'MEDIUM SPRING GREEN' => {
                    'out'  => $csi . '38:2:0:250:154m',
                    'desc' => 'Medium spring green',
                },
                'SPRING GREEN' => {
                    'out'  => $csi . '38:2:0:255:127m',
                    'desc' => 'Spring green',
                },
                'SEA GREEN' => {
                    'out'  => $csi . '38:2:46:139:87m',
                    'desc' => 'Sea green',
                },
                'MEDIUM AQUA MARINE' => {
                    'out'  => $csi . '38:2:102:205:170m',
                    'desc' => 'Medium aqua marine',
                },
                'MEDIUM SEA GREEN' => {
                    'out'  => $csi . '38:2:60:179:113m',
                    'desc' => 'Medium sea green',
                },
                'LIGHT SEA GREEN' => {
                    'out'  => $csi . '38:2:32:178:170m',
                    'desc' => 'Light sea green',
                },
                'DARK SLATE GREY' => {
                    'out'  => $csi . '38:2:47:79:79m',
                    'desc' => 'Dark slate gray',
                },
                'DARK CYAN' => {
                    'out'  => $csi . '38:2:0:139:139m',
                    'desc' => 'Dark cyan',
                },
                'AQUA' => {
                    'out'  => $csi . '38:2:0:255:255m',
                    'desc' => 'Aqua',
                },
                'LIGHT CYAN' => {
                    'out'  => $csi . '38:2:224:255:255m',
                    'desc' => 'Light cyan',
                },
                'DARK TURQUOISE' => {
                    'out'  => $csi . '38:2:0:206:209m',
                    'desc' => 'Dark turquoise',
                },
                'TURQUOISE' => {
                    'out'  => $csi . '38:2:64:224:208m',
                    'desc' => 'Turquoise',
                },
                'MEDIUM TURQUOISE' => {
                    'out'  => $csi . '38:2:72:209:204m',
                    'desc' => 'Medium turquoise',
                },
                'PALE TURQUOISE' => {
                    'out'  => $csi . '38:2:175:238:238m',
                    'desc' => 'Pale turquoise',
                },
                'AQUA MARINE' => {
                    'out'  => $csi . '38:2:127:255:212m',
                    'desc' => 'Aqua marine',
                },
                'POWDER BLUE' => {
                    'out'  => $csi . '38:2:176:224:230m',
                    'desc' => 'Powder blue',
                },
                'CADET BLUE' => {
                    'out'  => $csi . '38:2:95:158:160m',
                    'desc' => 'Cadet blue',
                },
                'STEEL BLUE' => {
                    'out'  => $csi . '38:2:70:130:180m',
                    'desc' => 'Steel blue',
                },
                'CORN FLOWER BLUE' => {
                    'out'  => $csi . '38:2:100:149:237m',
                    'desc' => 'Corn flower blue',
                },
                'DEEP SKY BLUE' => {
                    'out'  => $csi . '38:2:0:191:255m',
                    'desc' => 'Deep sky blue',
                },
                'DODGER BLUE' => {
                    'out'  => $csi . '38:2:30:144:255m',
                    'desc' => 'Dodger blue',
                },
                'LIGHT BLUE' => {
                    'out'  => $csi . '38:2:173:216:230m',
                    'desc' => 'Light blue',
                },
                'SKY BLUE' => {
                    'out'  => $csi . '38:2:135:206:235m',
                    'desc' => 'Sky blue',
                },
                'LIGHT SKY BLUE' => {
                    'out'  => $csi . '38:2:135:206:250m',
                    'desc' => 'Light sky blue',
                },
                'MIDNIGHT BLUE' => {
                    'out'  => $csi . '38:2:25:25:112m',
                    'desc' => 'Midnight blue',
                },
                'DARK BLUE' => {
                    'out'  => $csi . '38:2:0:0:139m',
                    'desc' => 'Dark blue',
                },
                'MEDIUM BLUE' => {
                    'out'  => $csi . '38:2:0:0:205m',
                    'desc' => 'Medium blue',
                },
                'ROYAL BLUE' => {
                    'out'  => $csi . '38:2:65:105:225m',
                    'desc' => 'Royal blue',
                },
                'BLUE VIOLET' => {
                    'out'  => $csi . '38:2:138:43:226m',
                    'desc' => 'Blue violet',
                },
                'INDIGO' => {
                    'out'  => $csi . '38:2:75:0:130m',
                    'desc' => 'Indigo',
                },
                'DARK SLATE BLUE' => {
                    'out'  => $csi . '38:2:72:61:139m',
                    'desc' => 'Dark slate blue',
                },
                'SLATE BLUE' => {
                    'out'  => $csi . '38:2:106:90:205m',
                    'desc' => 'Slate blue',
                },
                'MEDIUM SLATE BLUE' => {
                    'out'  => $csi . '38:2:123:104:238m',
                    'desc' => 'Medium slate blue',
                },
                'MEDIUM PURPLE' => {
                    'out'  => $csi . '38:2:147:112:219m',
                    'desc' => 'Medium purple',
                },
                'DARK MAGENTA' => {
                    'out'  => $csi . '38:2:139:0:139m',
                    'desc' => 'Dark magenta',
                },
                'DARK VIOLET' => {
                    'out'  => $csi . '38:2:148:0:211m',
                    'desc' => 'Dark violet',
                },
                'DARK ORCHID' => {
                    'out'  => $csi . '38:2:153:50:204m',
                    'desc' => 'Dark orchid',
                },
                'MEDIUM ORCHID' => {
                    'out'  => $csi . '38:2:186:85:211m',
                    'desc' => 'Medium orchid',
                },
                'THISTLE' => {
                    'out'  => $csi . '38:2:216:191:216m',
                    'desc' => 'Thistle',
                },
                'PLUM' => {
                    'out'  => $csi . '38:2:221:160:221m',
                    'desc' => 'Plum',
                },
                'VIOLET' => {
                    'out'  => $csi . '38:2:238:130:238m',
                    'desc' => 'Violet',
                },
                'ORCHID' => {
                    'out'  => $csi . '38:2:218:112:214m',
                    'desc' => 'Orchid',
                },
                'MEDIUM VIOLET RED' => {
                    'out'  => $csi . '38:2:199:21:133m',
                    'desc' => 'Medium violet red',
                },
                'PALE VIOLET RED' => {
                    'out'  => $csi . '38:2:219:112:147m',
                    'desc' => 'Pale violet red',
                },
                'DEEP PINK' => {
                    'out'  => $csi . '38:2:255:20:147m',
                    'desc' => 'Deep pink',
                },
                'HOT PINK' => {
                    'out'  => $csi . '38:2:255:105:180m',
                    'desc' => 'Hot pink',
                },
                'LIGHT PINK' => {
                    'out'  => $csi . '38:2:255:182:193m',
                    'desc' => 'Light pink',
                },
                'ANTIQUE WHITE' => {
                    'out'  => $csi . '38:2:250:235:215m',
                    'desc' => 'Antique white',
                },
                'BEIGE' => {
                    'out'  => $csi . '38:2:245:245:220m',
                    'desc' => 'Beige',
                },
                'BISQUE' => {
                    'out'  => $csi . '38:2:255:228:196m',
                    'desc' => 'Bisque',
                },
                'BLANCHED ALMOND' => {
                    'out'  => $csi . '38:2:255:235:205m',
                    'desc' => 'Blanched almond',
                },
                'WHEAT' => {
                    'out'  => $csi . '38:2:245:222:179m',
                    'desc' => 'Wheat',
                },
                'CORN SILK' => {
                    'out'  => $csi . '38:2:255:248:220m',
                    'desc' => 'Corn silk',
                },
                'LEMON CHIFFON' => {
                    'out'  => $csi . '38:2:255:250:205m',
                    'desc' => 'Lemon chiffon',
                },
                'LIGHT GOLDEN ROD YELLOW' => {
                    'out'  => $csi . '38:2:250:250:210m',
                    'desc' => 'Light golden rod yellow',
                },
                'LIGHT YELLOW' => {
                    'out'  => $csi . '38:2:255:255:224m',
                    'desc' => 'Light yellow',
                },
                'SADDLE BROWN' => {
                    'out'  => $csi . '38:2:139:69:19m',
                    'desc' => 'Saddle brown',
                },
                'SIENNA' => {
                    'out'  => $csi . '38:2:160:82:45m',
                    'desc' => 'Sienna',
                },
                'CHOCOLATE' => {
                    'out'  => $csi . '38:2:210:105:30m',
                    'desc' => 'Chocolate',
                },
                'PERU' => {
                    'out'  => $csi . '38:2:205:133:63m',
                    'desc' => 'Peru',
                },
                'SANDY BROWN' => {
                    'out'  => $csi . '38:2:244:164:96m',
                    'desc' => 'Sandy brown',
                },
                'BURLY WOOD' => {
                    'out'  => $csi . '38:2:222:184:135m',
                    'desc' => 'Burly wood',
                },
                'TAN' => {
                    'out'  => $csi . '38:2:210:180:140m',
                    'desc' => 'Tan',
                },
                'ROSY BROWN' => {
                    'out'  => $csi . '38:2:188:143:143m',
                    'desc' => 'Rosy brown',
                },
                'MOCCASIN' => {
                    'out'  => $csi . '38:2:255:228:181m',
                    'desc' => 'Moccasin',
                },
                'NAVAJO WHITE' => {
                    'out'  => $csi . '38:2:255:222:173m',
                    'desc' => 'Navajo white',
                },
                'PEACH PUFF' => {
                    'out'  => $csi . '38:2:255:218:185m',
                    'desc' => 'Peach puff',
                },
                'MISTY ROSE' => {
                    'out'  => $csi . '38:2:255:228:225m',
                    'desc' => 'Misty rose',
                },
                'LAVENDER BLUSH' => {
                    'out'  => $csi . '38:2:255:240:245m',
                    'desc' => 'Lavender blush',
                },
                'LINEN' => {
                    'out'  => $csi . '38:2:250:240:230m',
                    'desc' => 'Linen',
                },
                'OLD LACE' => {
                    'out'  => $csi . '38:2:253:245:230m',
                    'desc' => 'Old lace',
                },
                'PAPAYA WHIP' => {
                    'out'  => $csi . '38:2:255:239:213m',
                    'desc' => 'Papaya whip',
                },
                'SEA SHELL' => {
                    'out'  => $csi . '38:2:255:245:238m',
                    'desc' => 'Sea shell',
                },
                'MINT CREAM' => {
                    'out'  => $csi . '38:2:245:255:250m',
                    'desc' => 'Mint green',
                },
                'SLATE GREY' => {
                    'out'  => $csi . '38:2:112:128:144m',
                    'desc' => 'Slate gray',
                },
                'LIGHT SLATE GREY' => {
                    'out'  => $csi . '38:2:119:136:153m',
                    'desc' => 'Lisght slate gray',
                },
                'LIGHT STEEL BLUE' => {
                    'out'  => $csi . '38:2:176:196:222m',
                    'desc' => 'Light steel blue',
                },
                'LAVENDER' => {
                    'out'  => $csi . '38:2:230:230:250m',
                    'desc' => 'Lavender',
                },
                'FLORAL WHITE' => {
                    'out'  => $csi . '38:2:255:250:240m',
                    'desc' => 'Floral white',
                },
                'ALICE BLUE' => {
                    'out'  => $csi . '38:2:240:248:255m',
                    'desc' => 'Alice blue',
                },
                'GHOST WHITE' => {
                    'out'  => $csi . '38:2:248:248:255m',
                    'desc' => 'Ghost white',
                },
                'HONEYDEW' => {
                    'out'  => $csi . '38:2:240:255:240m',
                    'desc' => 'Honeydew',
                },
                'IVORY' => {
                    'out'  => $csi . '38:2:255:255:240m',
                    'desc' => 'Ivory',
                },
                'AZURE' => {
                    'out'  => $csi . '38:2:240:255:255m',
                    'desc' => 'Azure',
                },
                'SNOW' => {
                    'out'  => $csi . '38:2:255:250:250m',
                    'desc' => 'Snow',
                },
                'DIM GREY' => {
                    'out'  => $csi . '38:2:105:105:105m',
                    'desc' => 'Dim gray',
                },
                'DARK GREY' => {
                    'out'  => $csi . '38:2:169:169:169m',
                    'desc' => 'Dark gray',
                },
                'SILVER' => {
                    'out'  => $csi . '38:2:192:192:192m',
                    'desc' => 'Silver',
                },
                'LIGHT GREY' => {
                    'out'  => $csi . '38:2:211:211:211m',
                    'desc' => 'Light gray',
                },
                'GAINSBORO' => {
                    'out'  => $csi . '38:2:220:220:220m',
                    'desc' => 'Gainsboro',
                },
                'WHITE SMOKE' => {
                    'out'  => $csi . '38:2:245:245:245m',
                    'desc' => 'White smoke',
                },
            },

            'background' => {
                'B_DEFAULT' => {
                    'out'  => $csi . '49m',
                    'desc' => 'Default color',
                },
                'B_BLACK' => {
                    'out'  => $csi . '40m',
                    'desc' => 'Black',
                },
                'B_RED' => {
                    'out'  => $csi . '41m',
                    'desc' => 'Red',
                },
                'B_DARK RED' => {
                    'out'  => $csi . '48:2:139:0:0m',
                    'desc' => 'Dark red',
                },
                'B_PINK' => {
                    'out'  => $csi . '48;5;198m',
                    'desc' => 'Pink',
                },
                'B_ORANGE' => {
                    'out'  => $csi . '48;5;202m',
                    'desc' => 'Orange',
                },
                'B_NAVY' => {
                    'out'  => $csi . '48;5;17m',
                    'desc' => 'Navy',
                },
                'B_BROWN' => {
                    'out'  => $csi . '48:2:165:42:42m',
                    'desc' => 'Brown',
                },
                'B_MAROON' => {
                    'out'  => $csi . '48:2:128:0:0m',
                    'desc' => 'Maroon',
                },
                'B_OLIVE' => {
                    'out'  => $csi . '48:2:128:128:0m',
                    'desc' => 'Olive',
                },
                'B_PURPLE' => {
                    'out'  => $csi . '48:2:128:0:128m',
                    'desc' => 'Purple',
                },
                'B_TEAL' => {
                    'out'  => $csi . '48:2:0:128:128m',
                    'desc' => 'Teal',
                },
                'B_GREEN' => {
                    'out'  => $csi . '42m',
                    'desc' => 'Green',
                },
                'B_YELLOW' => {
                    'out'  => $csi . '43m',
                    'desc' => 'Yellow',
                },
                'B_BLUE' => {
                    'out'  => $csi . '44m',
                    'desc' => 'Blue',
                },
                'B_MAGENTA' => {
                    'out'  => $csi . '45m',
                    'desc' => 'Magenta',
                },
                'B_CYAN' => {
                    'out'  => $csi . '46m',
                    'desc' => 'Cyan',
                },
                'B_WHITE' => {
                    'out'  => $csi . '47m',
                    'desc' => 'White',
                },
                'B_BRIGHT BLACK' => {
                    'out'  => $csi . '100m',
                    'desc' => 'Bright black',
                },
                'B_BRIGHT RED' => {
                    'out'  => $csi . '101m',
                    'desc' => 'Bright red',
                },
                'B_BRIGHT GREEN' => {
                    'out'  => $csi . '102m',
                    'desc' => 'Bright green',
                },
                'B_BRIGHT YELLOW' => {
                    'out'  => $csi . '103m',
                    'desc' => 'Bright yellow',
                },
                'B_BRIGHT BLUE' => {
                    'out'  => $csi . '104m',
                    'desc' => 'Bright blue',
                },
                'B_BRIGHT MAGENTA' => {
                    'out'  => $csi . '105m',
                    'desc' => 'Bright magenta',
                },
                'B_BRIGHT CYAN' => {
                    'out'  => $csi . '106m',
                    'desc' => 'Bright cyan',
                },
                'B_BRIGHT WHITE' => {
                    'out'  => $csi . '107m',
                    'desc' => 'Bright white',
                },
                'B_FIREBRICK' => {
                    'out'  => $csi . '48:2:178:34:34m',
                    'desc' => 'Firebrick',
                },
                'B_CRIMSON' => {
                    'out'  => $csi . '48:2:220:20:60m',
                    'desc' => 'Crimson',
                },
                'B_TOMATO' => {
                    'out'  => $csi . '48:2:255:99:71m',
                    'desc' => 'Tomato',
                },
                'B_CORAL' => {
                    'out'  => $csi . '48:2:255:127:80m',
                    'desc' => 'Coral',
                },
                'B_INDIAN RED' => {
                    'out'  => $csi . '48:2:205:92:92m',
                    'desc' => 'Indian red',
                },
                'B_LIGHT CORAL' => {
                    'out'  => $csi . '48:2:240:128:128m',
                    'desc' => 'Light coral',
                },
                'B_DARK SALMON' => {
                    'out'  => $csi . '48:2:233:150:122m',
                    'desc' => 'Dark salmon',
                },
                'B_SALMON' => {
                    'out'  => $csi . '48:2:250:128:114m',
                    'desc' => 'Salmon',
                },
                'B_LIGHT SALMON' => {
                    'out'  => $csi . '48:2:255:160:122m',
                    'desc' => 'Light salmon',
                },
                'B_ORANGE RED' => {
                    'out'  => $csi . '48:2:255:69:0m',
                    'desc' => 'Orange red',
                },
                'B_DARK ORANGE' => {
                    'out'  => $csi . '48:2:255:140:0m',
                    'desc' => 'Dark orange',
                },
                'B_GOLD' => {
                    'out'  => $csi . '48:2:255:215:0m',
                    'desc' => 'Gold',
                },
                'B_DARK GOLDEN ROD' => {
                    'out'  => $csi . '48:2:184:134:11m',
                    'desc' => 'Dark golden rod',
                },
                'B_GOLDEN ROD' => {
                    'out'  => $csi . '48:2:218:165:32m',
                    'desc' => 'Golden rod',
                },
                'B_PALE GOLDEN ROD' => {
                    'out'  => $csi . '48:2:238:232:170m',
                    'desc' => 'Pale golden rod',
                },
                'B_DARK KHAKI' => {
                    'out'  => $csi . '48:2:189:183:107m',
                    'desc' => 'Dark khaki',
                },
                'B_KHAKI' => {
                    'out'  => $csi . '48:2:240:230:140m',
                    'desc' => 'Khaki',
                },
                'B_YELLOW GREEN' => {
                    'out'  => $csi . '48:2:154:205:50m',
                    'desc' => 'Yellow green',
                },
                'B_DARK OLIVE GREEN' => {
                    'out'  => $csi . '48:2:85:107:47m',
                    'desc' => 'Dark olive green',
                },
                'B_OLIVE DRAB' => {
                    'out'  => $csi . '48:2:107:142:35m',
                    'desc' => 'Olive drab',
                },
                'B_LAWN GREEN' => {
                    'out'  => $csi . '48:2:124:252:0m',
                    'desc' => 'Lawn green',
                },
                'B_CHARTREUSE' => {
                    'out'  => $csi . '48:2:127:255:0m',
                    'desc' => 'Chartreuse',
                },
                'B_GREEN YELLOW' => {
                    'out'  => $csi . '48:2:173:255:47m',
                    'desc' => 'Green yellow',
                },
                'B_DARK GREEN' => {
                    'out'  => $csi . '48:2:0:100:0m',
                    'desc' => 'Dark green',
                },
                'B_FOREST GREEN' => {
                    'out'  => $csi . '48:2:34:139:34m',
                    'desc' => 'Forest green',
                },
                'B_LIME GREEN' => {
                    'out'  => $csi . '48:2:50:205:50m',
                    'desc' => 'Lime Green',
                },
                'B_LIGHT GREEN' => {
                    'out'  => $csi . '48:2:144:238:144m',
                    'desc' => 'Light green',
                },
                'B_PALE GREEN' => {
                    'out'  => $csi . '48:2:152:251:152m',
                    'desc' => 'Pale green',
                },
                'B_DARK SEA GREEN' => {
                    'out'  => $csi . '48:2:143:188:143m',
                    'desc' => 'Dark sea green',
                },
                'B_MEDIUM SPRING GREEN' => {
                    'out'  => $csi . '48:2:0:250:154m',
                    'desc' => 'Medium spring green',
                },
                'B_SPRING GREEN' => {
                    'out'  => $csi . '48:2:0:255:127m',
                    'desc' => 'Spring green',
                },
                'B_SEA GREEN' => {
                    'out'  => $csi . '48:2:46:139:87m',
                    'desc' => 'Sea green',
                },
                'B_MEDIUM AQUA MARINE' => {
                    'out'  => $csi . '48:2:102:205:170m',
                    'desc' => 'Medium aqua marine',
                },
                'B_MEDIUM SEA GREEN' => {
                    'out'  => $csi . '48:2:60:179:113m',
                    'desc' => 'Medium sea green',
                },
                'B_LIGHT SEA GREEN' => {
                    'out'  => $csi . '48:2:32:178:170m',
                    'desc' => 'Light sea green',
                },
                'B_DARK SLATE GREY' => {
                    'out'  => $csi . '48:2:47:79:79m',
                    'desc' => 'Dark slate gray',
                },
                'B_DARK CYAN' => {
                    'out'  => $csi . '48:2:0:139:139m',
                    'desc' => 'Dark cyan',
                },
                'B_AQUA' => {
                    'out'  => $csi . '48:2:0:255:255m',
                    'desc' => 'Aqua',
                },
                'B_LIGHT CYAN' => {
                    'out'  => $csi . '48:2:224:255:255m',
                    'desc' => 'Light cyan',
                },
                'B_DARK TURQUOISE' => {
                    'out'  => $csi . '48:2:0:206:209m',
                    'desc' => 'Dark turquoise',
                },
                'B_TURQUOISE' => {
                    'out'  => $csi . '48:2:64:224:208m',
                    'desc' => 'Turquoise',
                },
                'B_MEDIUM TURQUOISE' => {
                    'out'  => $csi . '48:2:72:209:204m',
                    'desc' => 'Medium turquoise',
                },
                'B_PALE TURQUOISE' => {
                    'out'  => $csi . '48:2:175:238:238m',
                    'desc' => 'Pale turquoise',
                },
                'B_AQUA MARINE' => {
                    'out'  => $csi . '48:2:127:255:212m',
                    'desc' => 'Aqua marine',
                },
                'B_POWDER BLUE' => {
                    'out'  => $csi . '48:2:176:224:230m',
                    'desc' => 'Powder blue',
                },
                'B_CADET BLUE' => {
                    'out'  => $csi . '48:2:95:158:160m',
                    'desc' => 'Cadet blue',
                },
                'B_STEEL BLUE' => {
                    'out'  => $csi . '48:2:70:130:180m',
                    'desc' => 'Steel blue',
                },
                'B_CORN FLOWER BLUE' => {
                    'out'  => $csi . '48:2:100:149:237m',
                    'desc' => 'Corn flower blue',
                },
                'B_DEEP SKY BLUE' => {
                    'out'  => $csi . '48:2:0:191:255m',
                    'desc' => 'Deep sky blue',
                },
                'B_DODGER BLUE' => {
                    'out'  => $csi . '48:2:30:144:255m',
                    'desc' => 'Dodger blue',
                },
                'B_LIGHT BLUE' => {
                    'out'  => $csi . '48:2:173:216:230m',
                    'desc' => 'Light blue',
                },
                'B_SKY BLUE' => {
                    'out'  => $csi . '48:2:135:206:235m',
                    'desc' => 'Sky blue',
                },
                'B_LIGHT SKY BLUE' => {
                    'out'  => $csi . '48:2:135:206:250m',
                    'desc' => 'Light sky blue',
                },
                'B_MIDNIGHT BLUE' => {
                    'out'  => $csi . '48:2:25:25:112m',
                    'desc' => 'Midnight blue',
                },
                'B_DARK BLUE' => {
                    'out'  => $csi . '48:2:0:0:139m',
                    'desc' => 'Dark blue',
                },
                'B_MEDIUM BLUE' => {
                    'out'  => $csi . '48:2:0:0:205m',
                    'desc' => 'Medium blue',
                },
                'B_ROYAL BLUE' => {
                    'out'  => $csi . '48:2:65:105:225m',
                    'desc' => 'Royal blue',
                },
                'B_BLUE VIOLET' => {
                    'out'  => $csi . '48:2:138:43:226m',
                    'desc' => 'Blue violet',
                },
                'B_INDIGO' => {
                    'out'  => $csi . '48:2:75:0:130m',
                    'desc' => 'Indigo',
                },
                'B_DARK SLATE BLUE' => {
                    'out'  => $csi . '48:2:72:61:139m',
                    'desc' => 'Dark slate blue',
                },
                'B_SLATE BLUE' => {
                    'out'  => $csi . '48:2:106:90:205m',
                    'desc' => 'Slate blue',
                },
                'B_MEDIUM SLATE BLUE' => {
                    'out'  => $csi . '48:2:123:104:238m',
                    'desc' => 'Medium slate blue',
                },
                'B_MEDIUM PURPLE' => {
                    'out'  => $csi . '48:2:147:112:219m',
                    'desc' => 'Medium purple',
                },
                'B_DARK MAGENTA' => {
                    'out'  => $csi . '48:2:139:0:139m',
                    'desc' => 'Dark magenta',
                },
                'B_DARK VIOLET' => {
                    'out'  => $csi . '48:2:148:0:211m',
                    'desc' => 'Dark violet',
                },
                'B_DARK ORCHID' => {
                    'out'  => $csi . '48:2:153:50:204m',
                    'desc' => 'Dark orchid',
                },
                'B_MEDIUM ORCHID' => {
                    'out'  => $csi . '48:2:186:85:211m',
                    'desc' => 'Medium orchid',
                },
                'B_THISTLE' => {
                    'out'  => $csi . '48:2:216:191:216m',
                    'desc' => 'Thistle',
                },
                'B_PLUM' => {
                    'out'  => $csi . '48:2:221:160:221m',
                    'desc' => 'Plum',
                },
                'B_VIOLET' => {
                    'out'  => $csi . '48:2:238:130:238m',
                    'desc' => 'Violet',
                },
                'B_ORCHID' => {
                    'out'  => $csi . '48:2:218:112:214m',
                    'desc' => 'Orchid',
                },
                'B_MEDIUM VIOLET RED' => {
                    'out'  => $csi . '48:2:199:21:133m',
                    'desc' => 'Medium violet red',
                },
                'B_PALE VIOLET RED' => {
                    'out'  => $csi . '48:2:219:112:147m',
                    'desc' => 'Pale violet red',
                },
                'B_DEEP PINK' => {
                    'out'  => $csi . '48:2:255:20:147m',
                    'desc' => 'Deep pink',
                },
                'B_HOT PINK' => {
                    'out'  => $csi . '48:2:255:105:180m',
                    'desc' => 'Hot pink',
                },
                'B_LIGHT PINK' => {
                    'out'  => $csi . '48:2:255:182:193m',
                    'desc' => 'Light pink',
                },
                'B_ANTIQUE WHITE' => {
                    'out'  => $csi . '48:2:250:235:215m',
                    'desc' => 'Antique white',
                },
                'B_BEIGE' => {
                    'out'  => $csi . '48:2:245:245:220m',
                    'desc' => 'Beige',
                },
                'B_BISQUE' => {
                    'out'  => $csi . '48:2:255:228:196m',
                    'desc' => 'Bisque',
                },
                'B_BLANCHED ALMOND' => {
                    'out'  => $csi . '48:2:255:235:205m',
                    'desc' => 'Blanched almond',
                },
                'B_WHEAT' => {
                    'out'  => $csi . '48:2:245:222:179m',
                    'desc' => 'Wheat',
                },
                'B_CORN SILK' => {
                    'out'  => $csi . '48:2:255:248:220m',
                    'desc' => 'Corn silk',
                },
                'B_LEMON CHIFFON' => {
                    'out'  => $csi . '48:2:255:250:205m',
                    'desc' => 'Lemon chiffon',
                },
                'B_LIGHT GOLDEN ROD YELLOW' => {
                    'out'  => $csi . '48:2:250:250:210m',
                    'desc' => 'Light golden rod yellow',
                },
                'B_LIGHT YELLOW' => {
                    'out'  => $csi . '48:2:255:255:224m',
                    'desc' => 'Light yellow',
                },
                'B_SADDLE BROWN' => {
                    'out'  => $csi . '48:2:139:69:19m',
                    'desc' => 'Saddle brown',
                },
                'B_SIENNA' => {
                    'out'  => $csi . '48:2:160:82:45m',
                    'desc' => 'Sienna',
                },
                'B_CHOCOLATE' => {
                    'out'  => $csi . '48:2:210:105:30m',
                    'desc' => 'Chocolate',
                },
                'B_PERU' => {
                    'out'  => $csi . '48:2:205:133:63m',
                    'desc' => 'Peru',
                },
                'B_SANDY BROWN' => {
                    'out'  => $csi . '48:2:244:164:96m',
                    'desc' => 'Sandy brown',
                },
                'B_BURLY WOOD' => {
                    'out'  => $csi . '48:2:222:184:135m',
                    'desc' => 'Burly wood',
                },
                'B_TAN' => {
                    'out'  => $csi . '48:2:210:180:140m',
                    'desc' => 'Tan',
                },
                'B_ROSY BROWN' => {
                    'out'  => $csi . '48:2:188:143:143m',
                    'desc' => 'Rosy brown',
                },
                'B_MOCCASIN' => {
                    'out'  => $csi . '48:2:255:228:181m',
                    'desc' => 'Moccasin',
                },
                'B_NAVAJO WHITE' => {
                    'out'  => $csi . '48:2:255:222:173m',
                    'desc' => 'Navajo white',
                },
                'B_PEACH PUFF' => {
                    'out'  => $csi . '48:2:255:218:185m',
                    'desc' => 'Peach puff',
                },
                'B_MISTY ROSE' => {
                    'out'  => $csi . '48:2:255:228:225m',
                    'desc' => 'Misty rose',
                },
                'B_LAVENDER BLUSH' => {
                    'out'  => $csi . '48:2:255:240:245m',
                    'desc' => 'Lavender blush',
                },
                'B_LINEN' => {
                    'out'  => $csi . '48:2:250:240:230m',
                    'desc' => 'Linen',
                },
                'B_OLD LACE' => {
                    'out'  => $csi . '48:2:253:245:230m',
                    'desc' => 'Old lace',
                },
                'B_PAPAYA WHIP' => {
                    'out'  => $csi . '48:2:255:239:213m',
                    'desc' => 'Papaya whip',
                },
                'B_SEA SHELL' => {
                    'out'  => $csi . '48:2:255:245:238m',
                    'desc' => 'Sea shell',
                },
                'B_MINT CREAM' => {
                    'out'  => $csi . '48:2:245:255:250m',
                    'desc' => 'Mint green',
                },
                'B_SLATE GREY' => {
                    'out'  => $csi . '48:2:112:128:144m',
                    'desc' => 'Slate gray',
                },
                'B_LIGHT SLATE GREY' => {
                    'out'  => $csi . '48:2:119:136:153m',
                    'desc' => 'Lisght slate gray',
                },
                'B_LIGHT STEEL BLUE' => {
                    'out'  => $csi . '48:2:176:196:222m',
                    'desc' => 'Light steel blue',
                },
                'B_LAVENDER' => {
                    'out'  => $csi . '48:2:230:230:250m',
                    'desc' => 'Lavender',
                },
                'B_FLORAL WHITE' => {
                    'out'  => $csi . '48:2:255:250:240m',
                    'desc' => 'Floral white',
                },
                'B_ALICE BLUE' => {
                    'out'  => $csi . '48:2:240:248:255m',
                    'desc' => 'Alice blue',
                },
                'B_GHOST WHITE' => {
                    'out'  => $csi . '48:2:248:248:255m',
                    'desc' => 'Ghost white',
                },
                'B_HONEYDEW' => {
                    'out'  => $csi . '48:2:240:255:240m',
                    'desc' => 'Honeydew',
                },
                'B_IVORY' => {
                    'out'  => $csi . '48:2:255:255:240m',
                    'desc' => 'Ivory',
                },
                'B_AZURE' => {
                    'out'  => $csi . '48:2:240:255:255m',
                    'desc' => 'Azure',
                },
                'B_SNOW' => {
                    'out'  => $csi . '48:2:255:250:250m',
                    'desc' => 'Snow',
                },
                'B_DIM GREY' => {
                    'out'  => $csi . '48:2:105:105:105m',
                    'desc' => 'Dim gray',
                },
                'B_DARK GREY' => {
                    'out'  => $csi . '48:2:169:169:169m',
                    'desc' => 'Dark gray',
                },
                'B_SILVER' => {
                    'out'  => $csi . '48:2:192:192:192m',
                    'desc' => 'Silver',
                },
                'B_LIGHT GREY' => {
                    'out'  => $csi . '48:2:211:211:211m',
                    'desc' => 'Light gray',
                },
                'B_GAINSBORO' => {
                    'out'  => $csi . '48:2:220:220:220m',
                    'desc' => 'Gainsboro',
                },
                'B_WHITE SMOKE' => {
                    'out'  => $csi . '48:2:245:245:245m',
                    'desc' => 'White smoke',
                },
            },
        },
        @_,
    };

    # Alternate Fonts
    foreach my $count (1 .. 9) {
        $self->{'ansi_sequences'}->{'FONT ' . $count } = $csi . ($count + 10);
    }
	foreach my $code (qw(special clear cursor attributes foreground background)) {
		foreach my $name (keys %{$self->{'ansi_meta'}->{$code}}) {
			$self->{'ansi_sequences'}->{$name} = $self->{'ansi_meta'}->{$code}->{$name}->{'out'};
		}
	}
    # Generate symbols

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
 LOCATE      = Set cursor position

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
 B_BRIGHT BLACK   = Bright black (grey)
 B_BRIGHT RED     = Bright red
 B_BRIGHT GREEN   = Lime
 B_BRIGHT YELLOW  = Bright yellow
 B_BRIGHT BLUE    = Bright blue
 B_BRIGHT MAGENTA = Bright magenta
 B_BRIGHT CYAN    = Bright cyan
 B_BRIGHT WHITE   = Bright white

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
