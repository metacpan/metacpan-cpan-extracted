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
# modify it under the terms of the Perl Artistic License which can be #
# viewed here:                                                        #
#                  http://www.perlfoundation.org/artistic_license_2_0 #
#######################################################################

use strict;
use utf8; # REQUIRED
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
    our $VERSION = '1.37';
}

# Returns a description of a token using the meta data.
sub ansi_description {
	my $self = shift;
	my $code = shift;
	my $name = shift;

	return($self->{'ansi_meta'}->{$code}->{$name}->{'desc'});
}

sub ansi_decode {
    my $self = shift;
    my $text = shift;

    if (length($text) > 1) { # Special token handling requiring "smarts"
        my $csi = $self->{'ansi_sequences'}->{'CSI'};
        while ($text =~ /\[\%\s+LOCATE (\d+),(\d+)\s+\%\]/) { # Sets the cursor to a specific location.
            my ($c, $r) = ($1, $2);
            my $replace = $csi . "$r;$c" . 'H';
            $text =~ s/\[\%\s+LOCATE $c,$r\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+HORIZONTAL RULE (.*?)\s+\%\]/) { # Generates a horizontal rule in the specified color
            my $color = $1;
            my $new   = '[% RETURN %][% B_' . $color . ' %][% CLEAR LINE %][% RESET %]';
            $text =~ s/\[\%\s+HORIZONTAL RULE (.*?)\s+\%\]/$new/;
        }
        while ($text =~ /\[\%\s+SCROLL UP (\d+)\s+\%\]/) { # Scrolls the screen up the specified number of lines
            my $s       = $1;
            my $replace = $csi . $s . 'S';
            $text =~ s/\[\%\s+SCROLL UP $s\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+SCROLL DOWN (\d+)\s+\%\]/) { # Scrolls the screen down a specified number of lines
            my $s       = $1;
            my $replace = $csi . $s . 'T';
            $text =~ s/\[\%\s+SCROLL DOWN $s\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+RGB (\d+),(\d+),(\d+)\s+\%\]/) { # Sets the foreground color to a specific Red, Green and BLue value
            my ($r, $g, $b) = ($1 & 255, $2 & 255, $3 & 255);
            my $replace = $csi . "38:2:$r:$g:$b" . 'm';
            $text =~ s/\[\%\s+RGB $r,$g,$b\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+B_RGB (\d+),(\d+),(\d+)\s+\%\]/) { # Sets the background color to a specific Red, Green and BLue value
            my ($r, $g, $b) = ($1 & 255, $2 & 255, $3 & 255);
            my $replace = $csi . "48:2:$r:$g:$b" . 'm';
            $text =~ s/\[\%\s+B_RGB $r,$g,$b\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+(COLOR|COLOUR) (\d+)\s+\%\]/) { # Sets the foreground color to a 256 color specific.  Use -c to see the codes
            my $n       = $1;
            my $c       = $2 & 255;
            my $replace = $csi . "38:5:$c" . 'm';
            $text =~ s/\[\%\s+$n $c\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+(B_COLOR|B_COLOUR) (\d+)\s+\%\]/) { # Sets the background color to a 256 color specific.  Use -c to see the codes
            my $n       = $1;
            my $c       = $2 & 255;
            my $replace = $csi . "48:5:$c" . 'm';
            $text =~ s/\[\%\s+$n $c\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+GREY (\d+)\s+\%\]/) { # Sets the foreground color to a specific shade of grey.  Use -c to see the codes.
            my $g       = $1;
            my $replace = $csi . '38:5:' . (232 + $g) . 'm';
            $text =~ s/\[\%\s+GREY $g\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+B_GREY (\d+)\s+\%\]/) { # Sets the background color to a specific shade of grey.  Use -c to see the codes.
            my $g       = $1;
            my $replace = $csi . '48:5:' . (232 + $g) . 'm';
            $text =~ s/\[\%\s+B_GREY $g\s+\%\]/$replace/;
        }
        while ($text =~ /\[\%\s+BOX (.*?),(\d+),(\d+),(\d+),(\d+),(.*?)\s+\%\](.*?)\[\%\s+ENDBOX\s+\%\]/i) { # Parses the BOX token.
            my $replace = $self->box($1, $2, $3, $4, $5, $6, $7);
            $text =~ s/\[\%\s+BOX.*?\%\].*?\[\%\s+ENDBOX.*?\%\]/$replace/;
        }
		while ($text =~ /\[\%\s+(.*?)\s+\%\]/ && (exists($self->{'ansi_sequences'}->{$1}) || defined(charnames::string_vianame($1)))) { # Parse the rest of the tokens
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
    $text =~ s/\[ \% TOKEN \% \]/\[\% TOKEN \%\]/; # Special token to show [% TOKEN %] on output
    print $text;
    return (TRUE);
} ## end sub ansi_output

# Draws a box with text in it.
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
		'list'           => [(0x20 .. 0x7F, 0xA0 .. 0xFF, 0x2010 .. 0x205F, 0x2070 .. 0x242F, 0x2440 .. 0x244F, 0x2460 .. 0x29FF, 0x1F300 .. 0x1F8BF, 0x1F900 .. 0x1FBBF, 0x1F900 .. 0x1FBCF, 0x1FBF0 .. 0x1FBFF)],
        'ansi_meta' => {
            'special' => {
				'FONT DOUBLE-HEIGHT TOP' => {
					'out' => $esc . '#3',
					'desc' => 'Double-Height Font Top Portion',
				},
				'FONT DOUBLE-HEIGHT BOTTOM' => {
					'out' => $esc . '#4',
					'desc' => 'Double-Height Font Bottom Portion',
				},
				'FONT DOUBLE-WIDTH' => {
					'out' => $esc . '#6',
					'desc' => 'Double-Width Font',
				},
				'FONT DEFAULT' => {
					'out' => $esc . '#5',
					'desc' => 'Default Font Size',
				},
				'APC' => {
					'out' => $esc . '_',
					'desc' => 'Application Program Command',
				},
                'SS2' => {
                    'out'  => $esc . 'N',
                    'desc' => 'Single Shift 2',
                },
                'SS3' => {
                    'out'  => $esc . 'O',
                    'desc' => 'Single Shift 3',
                },
                'CSI' => {
                    'out'  => $esc . '[',
                    'desc' => 'Control Sequence Introducer',
                },
                'OSC' => {
                    'out'  => $esc . ']',
                    'desc' => 'Operating System Command',
                },
                'SOS' => {
                    'out'  => $esc . 'X',
                    'desc' => 'Start Of String',
                },
                'ST' => {
                    'out'  => $esc . "\\",
                    'desc' => 'String Terminator',
                },
                'DCS' => {
                    'out'  => $esc . 'P',
                    'desc' => 'Device Control String',
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
                    'desc' => 'Place the cursor at the beginning of the next line',
                 },
                'PREVIOUS LINE' => {
                    'out'  => $csi . 'F',
                    'desc' => 'Place the cursor at the beginning of the previous line',
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
                    'desc' => 'Default foreground color',
					'orig' => TRUE,
                },
                'BLACK' => {
                    'out'  => $csi . '30m',
                    'desc' => 'Black',
					'orig' => TRUE,
                },
                'RED' => {
                    'out'  => $csi . '31m',
                    'desc' => 'Red',
					'orig' => TRUE,
                },
                'DARK RED' => {
                    'out'  => $csi . '38:2:139:0:0m',
                    'desc' => 'Dark red',
					'orig' => FALSE,
                },
                'PINK' => {
                    'out'  => $csi . '38;5;198m',
                    'desc' => 'Pink',
					'orig' => FALSE,
                },
                'ORANGE' => {
                    'out'  => $csi . '38;5;202m',
                    'desc' => 'Orange',
					'orig' => FALSE,
                },
                'NAVY' => {
                    'out'  => $csi . '38;5;17m',
                    'desc' => 'Navy',
					'orig' => FALSE,
                },
                'BROWN' => {
                    'out'  => $csi . '38:2:165:42:42m',
                    'desc' => 'Brown',
					'orig' => FALSE,
                },
                'MAROON' => {
                    'out'  => $csi . '38:2:128:0:0m',
                    'desc' => 'Maroon',
					'orig' => FALSE,
                },
                'OLIVE' => {
                    'out'  => $csi . '38:2:128:128:0m',
                    'desc' => 'Olive',
					'orig' => FALSE,
                },
                'PURPLE' => {
                    'out'  => $csi . '38:2:128:0:128m',
                    'desc' => 'Purple',
					'orig' => FALSE,
                },
                'TEAL' => {
                    'out'  => $csi . '38:2:0:128:128m',
                    'desc' => 'Teal',
					'orig' => FALSE,
                },
                'GREEN' => {
                    'out'  => $csi . '32m',
                    'desc' => 'Green',
					'orig' => TRUE,
                },
                'YELLOW' => {
                    'out'  => $csi . '33m',
                    'desc' => 'Yellow',
					'orig' => TRUE,
                },
                'BLUE' => {
                    'out'  => $csi . '34m',
                    'desc' => 'Blue',
					'orig' => TRUE,
                },
                'MAGENTA' => {
                    'out'  => $csi . '35m',
                    'desc' => 'Magenta',
					'orig' => TRUE,
                },
                'CYAN' => {
                    'out'  => $csi . '36m',
                    'desc' => 'Cyan',
					'orig' => TRUE,
                },
                'WHITE' => {
                    'out'  => $csi . '37m',
                    'desc' => 'White',
					'orig' => TRUE,
                },
                'BRIGHT BLACK' => {
                    'out'  => $csi . '90m',
                    'desc' => 'Bright black',
					'orig' => TRUE,
                },
                'BRIGHT RED' => {
                    'out'  => $csi . '91m',
                    'desc' => 'Bright red',
					'orig' => TRUE,
                },
                'BRIGHT GREEN' => {
                    'out'  => $csi . '92m',
                    'desc' => 'Bright green',
					'orig' => TRUE,
                },
                'BRIGHT YELLOW' => {
                    'out'  => $csi . '93m',
                    'desc' => 'Bright yellow',
					'orig' => TRUE,
                },
                'BRIGHT BLUE' => {
                    'out'  => $csi . '94m',
                    'desc' => 'Bright blue',
					'orig' => TRUE,
                },
                'BRIGHT MAGENTA' => {
                    'out'  => $csi . '95m',
                    'desc' => 'Bright magenta',
					'orig' => TRUE,
                },
                'BRIGHT CYAN' => {
                    'out'  => $csi . '96m',
                    'desc' => 'Bright cyan',
					'orig' => TRUE,
                },
                'BRIGHT WHITE' => {
                    'out'  => $csi . '97m',
                    'desc' => 'Bright white',
					'orig' => TRUE,
                },
                'FIREBRICK' => {
                    'out'  => $csi . '38:2:178:34:34m',
                    'desc' => 'Firebrick',
					'orig' => FALSE,
                },
                'CRIMSON' => {
                    'out'  => $csi . '38:2:220:20:60m',
                    'desc' => 'Crimson',
					'orig' => FALSE,
                },
                'TOMATO' => {
                    'out'  => $csi . '38:2:255:99:71m',
                    'desc' => 'Tomato',
					'orig' => FALSE,
                },
                'CORAL' => {
                    'out'  => $csi . '38:2:255:127:80m',
                    'desc' => 'Coral',
					'orig' => FALSE,
                },
                'INDIAN RED' => {
                    'out'  => $csi . '38:2:205:92:92m',
                    'desc' => 'Indian red',
					'orig' => FALSE,
                },
                'LIGHT CORAL' => {
                    'out'  => $csi . '38:2:240:128:128m',
                    'desc' => 'Light coral',
					'orig' => FALSE,
                },
                'DARK SALMON' => {
                    'out'  => $csi . '38:2:233:150:122m',
                    'desc' => 'Dark salmon',
					'orig' => FALSE,
                },
                'SALMON' => {
                    'out'  => $csi . '38:2:250:128:114m',
                    'desc' => 'Salmon',
					'orig' => FALSE,
                },
                'LIGHT SALMON' => {
                    'out'  => $csi . '38:2:255:160:122m',
                    'desc' => 'Light salmon',
					'orig' => FALSE,
                },
                'ORANGE RED' => {
                    'out'  => $csi . '38:2:255:69:0m',
                    'desc' => 'Orange red',
					'orig' => FALSE,
                },
                'DARK ORANGE' => {
                    'out'  => $csi . '38:2:255:140:0m',
                    'desc' => 'Dark orange',
					'orig' => FALSE,
                },
                'GOLD' => {
                    'out'  => $csi . '38:2:255:215:0m',
                    'desc' => 'Gold',
					'orig' => FALSE,
                },
                'DARK GOLDEN ROD' => {
                    'out'  => $csi . '38:2:184:134:11m',
                    'desc' => 'Dark golden rod',
					'orig' => FALSE,
                },
                'GOLDEN ROD' => {
                    'out'  => $csi . '38:2:218:165:32m',
                    'desc' => 'Golden rod',
					'orig' => FALSE,
                },
                'PALE GOLDEN ROD' => {
                    'out'  => $csi . '38:2:238:232:170m',
                    'desc' => 'Pale golden rod',
					'orig' => FALSE,
                },
                'DARK KHAKI' => {
                    'out'  => $csi . '38:2:189:183:107m',
                    'desc' => 'Dark khaki',
					'orig' => FALSE,
                },
                'KHAKI' => {
                    'out'  => $csi . '38:2:240:230:140m',
                    'desc' => 'Khaki',
					'orig' => FALSE,
                },
                'YELLOW GREEN' => {
                    'out'  => $csi . '38:2:154:205:50m',
                    'desc' => 'Yellow green',
					'orig' => FALSE,
                },
                'DARK OLIVE GREEN' => {
                    'out'  => $csi . '38:2:85:107:47m',
                    'desc' => 'Dark olive green',
					'orig' => FALSE,
                },
                'OLIVE DRAB' => {
                    'out'  => $csi . '38:2:107:142:35m',
                    'desc' => 'Olive drab',
					'orig' => FALSE,
                },
                'LAWN GREEN' => {
                    'out'  => $csi . '38:2:124:252:0m',
                    'desc' => 'Lawn green',
					'orig' => FALSE,
                },
                'CHARTREUSE' => {
                    'out'  => $csi . '38:2:127:255:0m',
                    'desc' => 'Chartreuse',
					'orig' => FALSE,
                },
                'GREEN YELLOW' => {
                    'out'  => $csi . '38:2:173:255:47m',
                    'desc' => 'Green yellow',
					'orig' => FALSE,
                },
                'DARK GREEN' => {
                    'out'  => $csi . '38:2:0:100:0m',
                    'desc' => 'Dark green',
					'orig' => FALSE,
                },
                'FOREST GREEN' => {
                    'out'  => $csi . '38:2:34:139:34m',
                    'desc' => 'Forest green',
					'orig' => FALSE,
                },
                'LIME GREEN' => {
                    'out'  => $csi . '38:2:50:205:50m',
                    'desc' => 'Lime Green',
					'orig' => FALSE,
                },
                'LIGHT GREEN' => {
                    'out'  => $csi . '38:2:144:238:144m',
                    'desc' => 'Light green',
					'orig' => FALSE,
                },
                'PALE GREEN' => {
                    'out'  => $csi . '38:2:152:251:152m',
                    'desc' => 'Pale green',
					'orig' => FALSE,
                },
                'DARK SEA GREEN' => {
                    'out'  => $csi . '38:2:143:188:143m',
                    'desc' => 'Dark sea green',
					'orig' => FALSE,
                },
                'MEDIUM SPRING GREEN' => {
                    'out'  => $csi . '38:2:0:250:154m',
                    'desc' => 'Medium spring green',
					'orig' => FALSE,
                },
                'SPRING GREEN' => {
                    'out'  => $csi . '38:2:0:255:127m',
                    'desc' => 'Spring green',
					'orig' => FALSE,
                },
                'SEA GREEN' => {
                    'out'  => $csi . '38:2:46:139:87m',
                    'desc' => 'Sea green',
					'orig' => FALSE,
                },
                'MEDIUM AQUA MARINE' => {
                    'out'  => $csi . '38:2:102:205:170m',
                    'desc' => 'Medium aqua marine',
					'orig' => FALSE,
                },
                'MEDIUM SEA GREEN' => {
                    'out'  => $csi . '38:2:60:179:113m',
                    'desc' => 'Medium sea green',
					'orig' => FALSE,
                },
                'LIGHT SEA GREEN' => {
                    'out'  => $csi . '38:2:32:178:170m',
                    'desc' => 'Light sea green',
					'orig' => FALSE,
                },
                'DARK SLATE GREY' => {
                    'out'  => $csi . '38:2:47:79:79m',
                    'desc' => 'Dark slate gray',
					'orig' => FALSE,
                },
                'DARK CYAN' => {
                    'out'  => $csi . '38:2:0:139:139m',
                    'desc' => 'Dark cyan',
					'orig' => FALSE,
                },
                'AQUA' => {
                    'out'  => $csi . '38:2:0:255:255m',
                    'desc' => 'Aqua',
					'orig' => FALSE,
                },
                'LIGHT CYAN' => {
                    'out'  => $csi . '38:2:224:255:255m',
                    'desc' => 'Light cyan',
					'orig' => FALSE,
                },
                'DARK TURQUOISE' => {
                    'out'  => $csi . '38:2:0:206:209m',
                    'desc' => 'Dark turquoise',
					'orig' => FALSE,
                },
                'TURQUOISE' => {
                    'out'  => $csi . '38:2:64:224:208m',
                    'desc' => 'Turquoise',
					'orig' => FALSE,
                },
                'MEDIUM TURQUOISE' => {
                    'out'  => $csi . '38:2:72:209:204m',
                    'desc' => 'Medium turquoise',
					'orig' => FALSE,
                },
                'PALE TURQUOISE' => {
                    'out'  => $csi . '38:2:175:238:238m',
                    'desc' => 'Pale turquoise',
					'orig' => FALSE,
                },
                'AQUA MARINE' => {
                    'out'  => $csi . '38:2:127:255:212m',
                    'desc' => 'Aqua marine',
					'orig' => FALSE,
                },
                'POWDER BLUE' => {
                    'out'  => $csi . '38:2:176:224:230m',
                    'desc' => 'Powder blue',
					'orig' => FALSE,
                },
                'CADET BLUE' => {
                    'out'  => $csi . '38:2:95:158:160m',
                    'desc' => 'Cadet blue',
					'orig' => FALSE,
                },
                'STEEL BLUE' => {
                    'out'  => $csi . '38:2:70:130:180m',
                    'desc' => 'Steel blue',
					'orig' => FALSE,
                },
                'CORN FLOWER BLUE' => {
                    'out'  => $csi . '38:2:100:149:237m',
                    'desc' => 'Corn flower blue',
					'orig' => FALSE,
                },
                'DEEP SKY BLUE' => {
                    'out'  => $csi . '38:2:0:191:255m',
                    'desc' => 'Deep sky blue',
					'orig' => FALSE,
                },
                'DODGER BLUE' => {
                    'out'  => $csi . '38:2:30:144:255m',
                    'desc' => 'Dodger blue',
					'orig' => FALSE,
                },
                'LIGHT BLUE' => {
                    'out'  => $csi . '38:2:173:216:230m',
                    'desc' => 'Light blue',
					'orig' => FALSE,
                },
                'SKY BLUE' => {
                    'out'  => $csi . '38:2:135:206:235m',
                    'desc' => 'Sky blue',
					'orig' => FALSE,
                },
                'LIGHT SKY BLUE' => {
                    'out'  => $csi . '38:2:135:206:250m',
                    'desc' => 'Light sky blue',
					'orig' => FALSE,
                },
                'MIDNIGHT BLUE' => {
                    'out'  => $csi . '38:2:25:25:112m',
                    'desc' => 'Midnight blue',
					'orig' => FALSE,
                },
                'DARK BLUE' => {
                    'out'  => $csi . '38:2:0:0:139m',
                    'desc' => 'Dark blue',
					'orig' => FALSE,
                },
                'MEDIUM BLUE' => {
                    'out'  => $csi . '38:2:0:0:205m',
                    'desc' => 'Medium blue',
					'orig' => FALSE,
                },
                'ROYAL BLUE' => {
                    'out'  => $csi . '38:2:65:105:225m',
                    'desc' => 'Royal blue',
					'orig' => FALSE,
                },
                'BLUE VIOLET' => {
                    'out'  => $csi . '38:2:138:43:226m',
                    'desc' => 'Blue violet',
					'orig' => FALSE,
                },
                'INDIGO' => {
                    'out'  => $csi . '38:2:75:0:130m',
                    'desc' => 'Indigo',
					'orig' => FALSE,
                },
                'DARK SLATE BLUE' => {
                    'out'  => $csi . '38:2:72:61:139m',
                    'desc' => 'Dark slate blue',
					'orig' => FALSE,
                },
                'SLATE BLUE' => {
                    'out'  => $csi . '38:2:106:90:205m',
                    'desc' => 'Slate blue',
					'orig' => FALSE,
                },
                'MEDIUM SLATE BLUE' => {
                    'out'  => $csi . '38:2:123:104:238m',
                    'desc' => 'Medium slate blue',
					'orig' => FALSE,
                },
                'MEDIUM PURPLE' => {
                    'out'  => $csi . '38:2:147:112:219m',
                    'desc' => 'Medium purple',
					'orig' => FALSE,
                },
                'DARK MAGENTA' => {
                    'out'  => $csi . '38:2:139:0:139m',
                    'desc' => 'Dark magenta',
					'orig' => FALSE,
                },
                'DARK VIOLET' => {
                    'out'  => $csi . '38:2:148:0:211m',
                    'desc' => 'Dark violet',
					'orig' => FALSE,
                },
                'DARK ORCHID' => {
                    'out'  => $csi . '38:2:153:50:204m',
                    'desc' => 'Dark orchid',
					'orig' => FALSE,
                },
                'MEDIUM ORCHID' => {
                    'out'  => $csi . '38:2:186:85:211m',
                    'desc' => 'Medium orchid',
					'orig' => FALSE,
                },
                'THISTLE' => {
                    'out'  => $csi . '38:2:216:191:216m',
                    'desc' => 'Thistle',
					'orig' => FALSE,
                },
                'PLUM' => {
                    'out'  => $csi . '38:2:221:160:221m',
                    'desc' => 'Plum',
					'orig' => FALSE,
                },
                'VIOLET' => {
                    'out'  => $csi . '38:2:238:130:238m',
                    'desc' => 'Violet',
					'orig' => FALSE,
                },
                'ORCHID' => {
                    'out'  => $csi . '38:2:218:112:214m',
                    'desc' => 'Orchid',
					'orig' => FALSE,
                },
                'MEDIUM VIOLET RED' => {
                    'out'  => $csi . '38:2:199:21:133m',
                    'desc' => 'Medium violet red',
					'orig' => FALSE,
                },
                'PALE VIOLET RED' => {
                    'out'  => $csi . '38:2:219:112:147m',
                    'desc' => 'Pale violet red',
					'orig' => FALSE,
                },
                'DEEP PINK' => {
                    'out'  => $csi . '38:2:255:20:147m',
                    'desc' => 'Deep pink',
					'orig' => FALSE,
                },
                'HOT PINK' => {
                    'out'  => $csi . '38:2:255:105:180m',
                    'desc' => 'Hot pink',
					'orig' => FALSE,
                },
                'LIGHT PINK' => {
                    'out'  => $csi . '38:2:255:182:193m',
                    'desc' => 'Light pink',
					'orig' => FALSE,
                },
                'ANTIQUE WHITE' => {
                    'out'  => $csi . '38:2:250:235:215m',
                    'desc' => 'Antique white',
					'orig' => FALSE,
                },
                'BEIGE' => {
                    'out'  => $csi . '38:2:245:245:220m',
                    'desc' => 'Beige',
					'orig' => FALSE,
                },
                'BISQUE' => {
                    'out'  => $csi . '38:2:255:228:196m',
                    'desc' => 'Bisque',
					'orig' => FALSE,
                },
                'BLANCHED ALMOND' => {
                    'out'  => $csi . '38:2:255:235:205m',
                    'desc' => 'Blanched almond',
					'orig' => FALSE,
                },
                'WHEAT' => {
                    'out'  => $csi . '38:2:245:222:179m',
                    'desc' => 'Wheat',
					'orig' => FALSE,
                },
                'CORN SILK' => {
                    'out'  => $csi . '38:2:255:248:220m',
                    'desc' => 'Corn silk',
					'orig' => FALSE,
                },
                'LEMON CHIFFON' => {
                    'out'  => $csi . '38:2:255:250:205m',
                    'desc' => 'Lemon chiffon',
					'orig' => FALSE,
                },
                'LIGHT GOLDEN ROD YELLOW' => {
                    'out'  => $csi . '38:2:250:250:210m',
                    'desc' => 'Light golden rod yellow',
					'orig' => FALSE,
                },
                'LIGHT YELLOW' => {
                    'out'  => $csi . '38:2:255:255:224m',
                    'desc' => 'Light yellow',
					'orig' => FALSE,
                },
                'SADDLE BROWN' => {
                    'out'  => $csi . '38:2:139:69:19m',
                    'desc' => 'Saddle brown',
					'orig' => FALSE,
                },
                'SIENNA' => {
                    'out'  => $csi . '38:2:160:82:45m',
                    'desc' => 'Sienna',
					'orig' => FALSE,
                },
                'CHOCOLATE' => {
                    'out'  => $csi . '38:2:210:105:30m',
                    'desc' => 'Chocolate',
					'orig' => FALSE,
                },
                'PERU' => {
                    'out'  => $csi . '38:2:205:133:63m',
                    'desc' => 'Peru',
					'orig' => FALSE,
                },
                'SANDY BROWN' => {
                    'out'  => $csi . '38:2:244:164:96m',
                    'desc' => 'Sandy brown',
					'orig' => FALSE,
                },
                'BURLY WOOD' => {
                    'out'  => $csi . '38:2:222:184:135m',
                    'desc' => 'Burly wood',
					'orig' => FALSE,
                },
                'TAN' => {
                    'out'  => $csi . '38:2:210:180:140m',
                    'desc' => 'Tan',
					'orig' => FALSE,
                },
                'ROSY BROWN' => {
                    'out'  => $csi . '38:2:188:143:143m',
                    'desc' => 'Rosy brown',
					'orig' => FALSE,
                },
                'MOCCASIN' => {
                    'out'  => $csi . '38:2:255:228:181m',
                    'desc' => 'Moccasin',
					'orig' => FALSE,
                },
                'NAVAJO WHITE' => {
                    'out'  => $csi . '38:2:255:222:173m',
                    'desc' => 'Navajo white',
					'orig' => FALSE,
                },
                'PEACH PUFF' => {
                    'out'  => $csi . '38:2:255:218:185m',
                    'desc' => 'Peach puff',
					'orig' => FALSE,
                },
                'MISTY ROSE' => {
                    'out'  => $csi . '38:2:255:228:225m',
                    'desc' => 'Misty rose',
					'orig' => FALSE,
                },
                'LAVENDER BLUSH' => {
                    'out'  => $csi . '38:2:255:240:245m',
                    'desc' => 'Lavender blush',
					'orig' => FALSE,
                },
                'LINEN' => {
                    'out'  => $csi . '38:2:250:240:230m',
                    'desc' => 'Linen',
					'orig' => FALSE,
                },
                'OLD LACE' => {
                    'out'  => $csi . '38:2:253:245:230m',
                    'desc' => 'Old lace',
					'orig' => FALSE,
                },
                'PAPAYA WHIP' => {
                    'out'  => $csi . '38:2:255:239:213m',
                    'desc' => 'Papaya whip',
					'orig' => FALSE,
                },
                'SEA SHELL' => {
                    'out'  => $csi . '38:2:255:245:238m',
                    'desc' => 'Sea shell',
					'orig' => FALSE,
                },
                'MINT CREAM' => {
                    'out'  => $csi . '38:2:245:255:250m',
                    'desc' => 'Mint green',
					'orig' => FALSE,
                },
                'SLATE GREY' => {
                    'out'  => $csi . '38:2:112:128:144m',
                    'desc' => 'Slate gray',
					'orig' => FALSE,
                },
                'LIGHT SLATE GREY' => {
                    'out'  => $csi . '38:2:119:136:153m',
                    'desc' => 'Lisght slate gray',
					'orig' => FALSE,
                },
                'LIGHT STEEL BLUE' => {
                    'out'  => $csi . '38:2:176:196:222m',
                    'desc' => 'Light steel blue',
					'orig' => FALSE,
                },
                'LAVENDER' => {
                    'out'  => $csi . '38:2:230:230:250m',
                    'desc' => 'Lavender',
					'orig' => FALSE,
                },
                'FLORAL WHITE' => {
                    'out'  => $csi . '38:2:255:250:240m',
                    'desc' => 'Floral white',
					'orig' => FALSE,
                },
                'ALICE BLUE' => {
                    'out'  => $csi . '38:2:240:248:255m',
                    'desc' => 'Alice blue',
					'orig' => FALSE,
                },
                'GHOST WHITE' => {
                    'out'  => $csi . '38:2:248:248:255m',
                    'desc' => 'Ghost white',
					'orig' => FALSE,
                },
                'HONEYDEW' => {
                    'out'  => $csi . '38:2:240:255:240m',
                    'desc' => 'Honeydew',
					'orig' => FALSE,
                },
                'IVORY' => {
                    'out'  => $csi . '38:2:255:255:240m',
                    'desc' => 'Ivory',
					'orig' => FALSE,
                },
                'AZURE' => {
                    'out'  => $csi . '38:2:240:255:255m',
                    'desc' => 'Azure',
					'orig' => FALSE,
                },
                'SNOW' => {
                    'out'  => $csi . '38:2:255:250:250m',
                    'desc' => 'Snow',
					'orig' => FALSE,
                },
                'DIM GREY' => {
                    'out'  => $csi . '38:2:105:105:105m',
                    'desc' => 'Dim gray',
					'orig' => FALSE,
                },
                'DARK GREY' => {
                    'out'  => $csi . '38:2:169:169:169m',
                    'desc' => 'Dark gray',
					'orig' => FALSE,
                },
                'SILVER' => {
                    'out'  => $csi . '38:2:192:192:192m',
                    'desc' => 'Silver',
					'orig' => FALSE,
                },
                'LIGHT GREY' => {
                    'out'  => $csi . '38:2:211:211:211m',
                    'desc' => 'Light gray',
					'orig' => FALSE,
                },
                'GAINSBORO' => {
                    'out'  => $csi . '38:2:220:220:220m',
                    'desc' => 'Gainsboro',
					'orig' => FALSE,
                },
                'WHITE SMOKE' => {
                    'out'  => $csi . '38:2:245:245:245m',
                    'desc' => 'White smoke',
					'orig' => FALSE,
                },
            },

            'background' => {
                'B_DEFAULT' => {
                    'out'  => $csi . '49m',
                    'desc' => 'Default background color',
					'orig' => TRUE,
                },
                'B_BLACK' => {
                    'out'  => $csi . '40m',
                    'desc' => 'Black',
					'orig' => TRUE,
                },
                'B_RED' => {
                    'out'  => $csi . '41m',
                    'desc' => 'Red',
					'orig' => TRUE,
                },
                'B_DARK RED' => {
                    'out'  => $csi . '48:2:139:0:0m',
                    'desc' => 'Dark red',
					'orig' => FALSE,
                },
                'B_PINK' => {
                    'out'  => $csi . '48;5;198m',
                    'desc' => 'Pink',
					'orig' => FALSE,
                },
                'B_ORANGE' => {
                    'out'  => $csi . '48;5;202m',
                    'desc' => 'Orange',
					'orig' => FALSE,
                },
                'B_NAVY' => {
                    'out'  => $csi . '48;5;17m',
                    'desc' => 'Navy',
					'orig' => FALSE,
                },
                'B_BROWN' => {
                    'out'  => $csi . '48:2:165:42:42m',
                    'desc' => 'Brown',
					'orig' => FALSE,
                },
                'B_MAROON' => {
                    'out'  => $csi . '48:2:128:0:0m',
                    'desc' => 'Maroon',
					'orig' => FALSE,
                },
                'B_OLIVE' => {
                    'out'  => $csi . '48:2:128:128:0m',
                    'desc' => 'Olive',
					'orig' => FALSE,
                },
                'B_PURPLE' => {
                    'out'  => $csi . '48:2:128:0:128m',
                    'desc' => 'Purple',
					'orig' => FALSE,
                },
                'B_TEAL' => {
                    'out'  => $csi . '48:2:0:128:128m',
                    'desc' => 'Teal',
					'orig' => FALSE,
                },
                'B_GREEN' => {
                    'out'  => $csi . '42m',
                    'desc' => 'Green',
					'orig' => TRUE,
                },
                'B_YELLOW' => {
                    'out'  => $csi . '43m',
                    'desc' => 'Yellow',
					'orig' => TRUE,
                },
                'B_BLUE' => {
                    'out'  => $csi . '44m',
                    'desc' => 'Blue',
					'orig' => TRUE,
                },
                'B_MAGENTA' => {
                    'out'  => $csi . '45m',
                    'desc' => 'Magenta',
					'orig' => TRUE,
                },
                'B_CYAN' => {
                    'out'  => $csi . '46m',
                    'desc' => 'Cyan',
					'orig' => TRUE,
                },
                'B_WHITE' => {
                    'out'  => $csi . '47m',
                    'desc' => 'White',
					'orig' => TRUE,
                },
                'B_BRIGHT BLACK' => {
                    'out'  => $csi . '100m',
                    'desc' => 'Bright black',
					'orig' => TRUE,
                },
                'B_BRIGHT RED' => {
                    'out'  => $csi . '101m',
                    'desc' => 'Bright red',
					'orig' => TRUE,
                },
                'B_BRIGHT GREEN' => {
                    'out'  => $csi . '102m',
                    'desc' => 'Bright green',
					'orig' => TRUE,
                },
                'B_BRIGHT YELLOW' => {
                    'out'  => $csi . '103m',
                    'desc' => 'Bright yellow',
					'orig' => TRUE,
                },
                'B_BRIGHT BLUE' => {
                    'out'  => $csi . '104m',
                    'desc' => 'Bright blue',
					'orig' => TRUE,
                },
                'B_BRIGHT MAGENTA' => {
                    'out'  => $csi . '105m',
                    'desc' => 'Bright magenta',
					'orig' => TRUE,
                },
                'B_BRIGHT CYAN' => {
                    'out'  => $csi . '106m',
                    'desc' => 'Bright cyan',
					'orig' => TRUE,
                },
                'B_BRIGHT WHITE' => {
                    'out'  => $csi . '107m',
                    'desc' => 'Bright white',
					'orig' => TRUE,
                },
                'B_FIREBRICK' => {
                    'out'  => $csi . '48:2:178:34:34m',
                    'desc' => 'Firebrick',
					'orig' => FALSE,
                },
                'B_CRIMSON' => {
                    'out'  => $csi . '48:2:220:20:60m',
                    'desc' => 'Crimson',
					'orig' => FALSE,
                },
                'B_TOMATO' => {
                    'out'  => $csi . '48:2:255:99:71m',
                    'desc' => 'Tomato',
					'orig' => FALSE,
                },
                'B_CORAL' => {
                    'out'  => $csi . '48:2:255:127:80m',
                    'desc' => 'Coral',
					'orig' => FALSE,
                },
                'B_INDIAN RED' => {
                    'out'  => $csi . '48:2:205:92:92m',
                    'desc' => 'Indian red',
					'orig' => FALSE,
                },
                'B_LIGHT CORAL' => {
                    'out'  => $csi . '48:2:240:128:128m',
                    'desc' => 'Light coral',
					'orig' => FALSE,
                },
                'B_DARK SALMON' => {
                    'out'  => $csi . '48:2:233:150:122m',
                    'desc' => 'Dark salmon',
					'orig' => FALSE,
                },
                'B_SALMON' => {
                    'out'  => $csi . '48:2:250:128:114m',
                    'desc' => 'Salmon',
					'orig' => FALSE,
                },
                'B_LIGHT SALMON' => {
                    'out'  => $csi . '48:2:255:160:122m',
                    'desc' => 'Light salmon',
					'orig' => FALSE,
                },
                'B_ORANGE RED' => {
                    'out'  => $csi . '48:2:255:69:0m',
                    'desc' => 'Orange red',
					'orig' => FALSE,
                },
                'B_DARK ORANGE' => {
                    'out'  => $csi . '48:2:255:140:0m',
                    'desc' => 'Dark orange',
					'orig' => FALSE,
                },
                'B_GOLD' => {
                    'out'  => $csi . '48:2:255:215:0m',
                    'desc' => 'Gold',
					'orig' => FALSE,
                },
                'B_DARK GOLDEN ROD' => {
                    'out'  => $csi . '48:2:184:134:11m',
                    'desc' => 'Dark golden rod',
					'orig' => FALSE,
                },
                'B_GOLDEN ROD' => {
                    'out'  => $csi . '48:2:218:165:32m',
                    'desc' => 'Golden rod',
					'orig' => FALSE,
                },
                'B_PALE GOLDEN ROD' => {
                    'out'  => $csi . '48:2:238:232:170m',
                    'desc' => 'Pale golden rod',
					'orig' => FALSE,
                },
                'B_DARK KHAKI' => {
                    'out'  => $csi . '48:2:189:183:107m',
                    'desc' => 'Dark khaki',
					'orig' => FALSE,
                },
                'B_KHAKI' => {
                    'out'  => $csi . '48:2:240:230:140m',
                    'desc' => 'Khaki',
					'orig' => FALSE,
                },
                'B_YELLOW GREEN' => {
                    'out'  => $csi . '48:2:154:205:50m',
                    'desc' => 'Yellow green',
					'orig' => FALSE,
                },
                'B_DARK OLIVE GREEN' => {
                    'out'  => $csi . '48:2:85:107:47m',
                    'desc' => 'Dark olive green',
					'orig' => FALSE,
                },
                'B_OLIVE DRAB' => {
                    'out'  => $csi . '48:2:107:142:35m',
                    'desc' => 'Olive drab',
					'orig' => FALSE,
                },
                'B_LAWN GREEN' => {
                    'out'  => $csi . '48:2:124:252:0m',
                    'desc' => 'Lawn green',
					'orig' => FALSE,
                },
                'B_CHARTREUSE' => {
                    'out'  => $csi . '48:2:127:255:0m',
                    'desc' => 'Chartreuse',
					'orig' => FALSE,
                },
                'B_GREEN YELLOW' => {
                    'out'  => $csi . '48:2:173:255:47m',
                    'desc' => 'Green yellow',
					'orig' => FALSE,
                },
                'B_DARK GREEN' => {
                    'out'  => $csi . '48:2:0:100:0m',
                    'desc' => 'Dark green',
					'orig' => FALSE,
                },
                'B_FOREST GREEN' => {
                    'out'  => $csi . '48:2:34:139:34m',
                    'desc' => 'Forest green',
					'orig' => FALSE,
                },
                'B_LIME GREEN' => {
                    'out'  => $csi . '48:2:50:205:50m',
                    'desc' => 'Lime Green',
					'orig' => FALSE,
                },
                'B_LIGHT GREEN' => {
                    'out'  => $csi . '48:2:144:238:144m',
                    'desc' => 'Light green',
					'orig' => FALSE,
                },
                'B_PALE GREEN' => {
                    'out'  => $csi . '48:2:152:251:152m',
                    'desc' => 'Pale green',
					'orig' => FALSE,
                },
                'B_DARK SEA GREEN' => {
                    'out'  => $csi . '48:2:143:188:143m',
                    'desc' => 'Dark sea green',
					'orig' => FALSE,
                },
                'B_MEDIUM SPRING GREEN' => {
                    'out'  => $csi . '48:2:0:250:154m',
                    'desc' => 'Medium spring green',
					'orig' => FALSE,
                },
                'B_SPRING GREEN' => {
                    'out'  => $csi . '48:2:0:255:127m',
                    'desc' => 'Spring green',
					'orig' => FALSE,
                },
                'B_SEA GREEN' => {
                    'out'  => $csi . '48:2:46:139:87m',
                    'desc' => 'Sea green',
					'orig' => FALSE,
                },
                'B_MEDIUM AQUA MARINE' => {
                    'out'  => $csi . '48:2:102:205:170m',
                    'desc' => 'Medium aqua marine',
					'orig' => FALSE,
                },
                'B_MEDIUM SEA GREEN' => {
                    'out'  => $csi . '48:2:60:179:113m',
                    'desc' => 'Medium sea green',
					'orig' => FALSE,
                },
                'B_LIGHT SEA GREEN' => {
                    'out'  => $csi . '48:2:32:178:170m',
                    'desc' => 'Light sea green',
					'orig' => FALSE,
                },
                'B_DARK SLATE GREY' => {
                    'out'  => $csi . '48:2:47:79:79m',
                    'desc' => 'Dark slate gray',
					'orig' => FALSE,
                },
                'B_DARK CYAN' => {
                    'out'  => $csi . '48:2:0:139:139m',
                    'desc' => 'Dark cyan',
					'orig' => FALSE,
                },
                'B_AQUA' => {
                    'out'  => $csi . '48:2:0:255:255m',
                    'desc' => 'Aqua',
					'orig' => FALSE,
                },
                'B_LIGHT CYAN' => {
                    'out'  => $csi . '48:2:224:255:255m',
                    'desc' => 'Light cyan',
					'orig' => FALSE,
                },
                'B_DARK TURQUOISE' => {
                    'out'  => $csi . '48:2:0:206:209m',
                    'desc' => 'Dark turquoise',
					'orig' => FALSE,
                },
                'B_TURQUOISE' => {
                    'out'  => $csi . '48:2:64:224:208m',
                    'desc' => 'Turquoise',
					'orig' => FALSE,
                },
                'B_MEDIUM TURQUOISE' => {
                    'out'  => $csi . '48:2:72:209:204m',
                    'desc' => 'Medium turquoise',
					'orig' => FALSE,
                },
                'B_PALE TURQUOISE' => {
                    'out'  => $csi . '48:2:175:238:238m',
                    'desc' => 'Pale turquoise',
					'orig' => FALSE,
                },
                'B_AQUA MARINE' => {
                    'out'  => $csi . '48:2:127:255:212m',
                    'desc' => 'Aqua marine',
					'orig' => FALSE,
                },
                'B_POWDER BLUE' => {
                    'out'  => $csi . '48:2:176:224:230m',
                    'desc' => 'Powder blue',
					'orig' => FALSE,
                },
                'B_CADET BLUE' => {
                    'out'  => $csi . '48:2:95:158:160m',
                    'desc' => 'Cadet blue',
					'orig' => FALSE,
                },
                'B_STEEL BLUE' => {
                    'out'  => $csi . '48:2:70:130:180m',
                    'desc' => 'Steel blue',
					'orig' => FALSE,
                },
                'B_CORN FLOWER BLUE' => {
                    'out'  => $csi . '48:2:100:149:237m',
                    'desc' => 'Corn flower blue',
					'orig' => FALSE,
                },
                'B_DEEP SKY BLUE' => {
                    'out'  => $csi . '48:2:0:191:255m',
                    'desc' => 'Deep sky blue',
					'orig' => FALSE,
                },
                'B_DODGER BLUE' => {
                    'out'  => $csi . '48:2:30:144:255m',
                    'desc' => 'Dodger blue',
					'orig' => FALSE,
                },
                'B_LIGHT BLUE' => {
                    'out'  => $csi . '48:2:173:216:230m',
                    'desc' => 'Light blue',
					'orig' => FALSE,
                },
                'B_SKY BLUE' => {
                    'out'  => $csi . '48:2:135:206:235m',
                    'desc' => 'Sky blue',
					'orig' => FALSE,
                },
                'B_LIGHT SKY BLUE' => {
                    'out'  => $csi . '48:2:135:206:250m',
                    'desc' => 'Light sky blue',
					'orig' => FALSE,
                },
                'B_MIDNIGHT BLUE' => {
                    'out'  => $csi . '48:2:25:25:112m',
                    'desc' => 'Midnight blue',
					'orig' => FALSE,
                },
                'B_DARK BLUE' => {
                    'out'  => $csi . '48:2:0:0:139m',
                    'desc' => 'Dark blue',
					'orig' => FALSE,
                },
                'B_MEDIUM BLUE' => {
                    'out'  => $csi . '48:2:0:0:205m',
                    'desc' => 'Medium blue',
					'orig' => FALSE,
                },
                'B_ROYAL BLUE' => {
                    'out'  => $csi . '48:2:65:105:225m',
                    'desc' => 'Royal blue',
					'orig' => FALSE,
                },
                'B_BLUE VIOLET' => {
                    'out'  => $csi . '48:2:138:43:226m',
                    'desc' => 'Blue violet',
					'orig' => FALSE,
                },
                'B_INDIGO' => {
                    'out'  => $csi . '48:2:75:0:130m',
                    'desc' => 'Indigo',
					'orig' => FALSE,
                },
                'B_DARK SLATE BLUE' => {
                    'out'  => $csi . '48:2:72:61:139m',
                    'desc' => 'Dark slate blue',
					'orig' => FALSE,
                },
                'B_SLATE BLUE' => {
                    'out'  => $csi . '48:2:106:90:205m',
                    'desc' => 'Slate blue',
					'orig' => FALSE,
                },
                'B_MEDIUM SLATE BLUE' => {
                    'out'  => $csi . '48:2:123:104:238m',
                    'desc' => 'Medium slate blue',
					'orig' => FALSE,
                },
                'B_MEDIUM PURPLE' => {
                    'out'  => $csi . '48:2:147:112:219m',
                    'desc' => 'Medium purple',
					'orig' => FALSE,
                },
                'B_DARK MAGENTA' => {
                    'out'  => $csi . '48:2:139:0:139m',
                    'desc' => 'Dark magenta',
					'orig' => FALSE,
                },
                'B_DARK VIOLET' => {
                    'out'  => $csi . '48:2:148:0:211m',
                    'desc' => 'Dark violet',
					'orig' => FALSE,
                },
                'B_DARK ORCHID' => {
                    'out'  => $csi . '48:2:153:50:204m',
                    'desc' => 'Dark orchid',
					'orig' => FALSE,
                },
                'B_MEDIUM ORCHID' => {
                    'out'  => $csi . '48:2:186:85:211m',
                    'desc' => 'Medium orchid',
					'orig' => FALSE,
                },
                'B_THISTLE' => {
                    'out'  => $csi . '48:2:216:191:216m',
                    'desc' => 'Thistle',
					'orig' => FALSE,
                },
                'B_PLUM' => {
                    'out'  => $csi . '48:2:221:160:221m',
                    'desc' => 'Plum',
					'orig' => FALSE,
                },
                'B_VIOLET' => {
                    'out'  => $csi . '48:2:238:130:238m',
                    'desc' => 'Violet',
					'orig' => FALSE,
                },
                'B_ORCHID' => {
                    'out'  => $csi . '48:2:218:112:214m',
                    'desc' => 'Orchid',
					'orig' => FALSE,
                },
                'B_MEDIUM VIOLET RED' => {
                    'out'  => $csi . '48:2:199:21:133m',
                    'desc' => 'Medium violet red',
					'orig' => FALSE,
                },
                'B_PALE VIOLET RED' => {
                    'out'  => $csi . '48:2:219:112:147m',
                    'desc' => 'Pale violet red',
					'orig' => FALSE,
                },
                'B_DEEP PINK' => {
                    'out'  => $csi . '48:2:255:20:147m',
                    'desc' => 'Deep pink',
					'orig' => FALSE,
                },
                'B_HOT PINK' => {
                    'out'  => $csi . '48:2:255:105:180m',
                    'desc' => 'Hot pink',
					'orig' => FALSE,
                },
                'B_LIGHT PINK' => {
                    'out'  => $csi . '48:2:255:182:193m',
                    'desc' => 'Light pink',
					'orig' => FALSE,
                },
                'B_ANTIQUE WHITE' => {
                    'out'  => $csi . '48:2:250:235:215m',
                    'desc' => 'Antique white',
					'orig' => FALSE,
                },
                'B_BEIGE' => {
                    'out'  => $csi . '48:2:245:245:220m',
                    'desc' => 'Beige',
					'orig' => FALSE,
                },
                'B_BISQUE' => {
                    'out'  => $csi . '48:2:255:228:196m',
                    'desc' => 'Bisque',
					'orig' => FALSE,
                },
                'B_BLANCHED ALMOND' => {
                    'out'  => $csi . '48:2:255:235:205m',
                    'desc' => 'Blanched almond',
					'orig' => FALSE,
                },
                'B_WHEAT' => {
                    'out'  => $csi . '48:2:245:222:179m',
                    'desc' => 'Wheat',
					'orig' => FALSE,
                },
                'B_CORN SILK' => {
                    'out'  => $csi . '48:2:255:248:220m',
                    'desc' => 'Corn silk',
					'orig' => FALSE,
                },
                'B_LEMON CHIFFON' => {
                    'out'  => $csi . '48:2:255:250:205m',
                    'desc' => 'Lemon chiffon',
					'orig' => FALSE,
                },
                'B_LIGHT GOLDEN ROD YELLOW' => {
                    'out'  => $csi . '48:2:250:250:210m',
                    'desc' => 'Light golden rod yellow',
					'orig' => FALSE,
                },
                'B_LIGHT YELLOW' => {
                    'out'  => $csi . '48:2:255:255:224m',
                    'desc' => 'Light yellow',
					'orig' => FALSE,
                },
                'B_SADDLE BROWN' => {
                    'out'  => $csi . '48:2:139:69:19m',
                    'desc' => 'Saddle brown',
					'orig' => FALSE,
                },
                'B_SIENNA' => {
                    'out'  => $csi . '48:2:160:82:45m',
                    'desc' => 'Sienna',
					'orig' => FALSE,
                },
                'B_CHOCOLATE' => {
                    'out'  => $csi . '48:2:210:105:30m',
                    'desc' => 'Chocolate',
					'orig' => FALSE,
                },
                'B_PERU' => {
                    'out'  => $csi . '48:2:205:133:63m',
                    'desc' => 'Peru',
					'orig' => FALSE,
                },
                'B_SANDY BROWN' => {
                    'out'  => $csi . '48:2:244:164:96m',
                    'desc' => 'Sandy brown',
					'orig' => FALSE,
                },
                'B_BURLY WOOD' => {
                    'out'  => $csi . '48:2:222:184:135m',
                    'desc' => 'Burly wood',
					'orig' => FALSE,
                },
                'B_TAN' => {
                    'out'  => $csi . '48:2:210:180:140m',
                    'desc' => 'Tan',
					'orig' => FALSE,
                },
                'B_ROSY BROWN' => {
                    'out'  => $csi . '48:2:188:143:143m',
                    'desc' => 'Rosy brown',
					'orig' => FALSE,
                },
                'B_MOCCASIN' => {
                    'out'  => $csi . '48:2:255:228:181m',
                    'desc' => 'Moccasin',
					'orig' => FALSE,
                },
                'B_NAVAJO WHITE' => {
                    'out'  => $csi . '48:2:255:222:173m',
                    'desc' => 'Navajo white',
					'orig' => FALSE,
                },
                'B_PEACH PUFF' => {
                    'out'  => $csi . '48:2:255:218:185m',
                    'desc' => 'Peach puff',
					'orig' => FALSE,
                },
                'B_MISTY ROSE' => {
                    'out'  => $csi . '48:2:255:228:225m',
                    'desc' => 'Misty rose',
					'orig' => FALSE,
                },
                'B_LAVENDER BLUSH' => {
                    'out'  => $csi . '48:2:255:240:245m',
                    'desc' => 'Lavender blush',
					'orig' => FALSE,
                },
                'B_LINEN' => {
                    'out'  => $csi . '48:2:250:240:230m',
                    'desc' => 'Linen',
					'orig' => FALSE,
                },
                'B_OLD LACE' => {
                    'out'  => $csi . '48:2:253:245:230m',
                    'desc' => 'Old lace',
					'orig' => FALSE,
                },
                'B_PAPAYA WHIP' => {
                    'out'  => $csi . '48:2:255:239:213m',
                    'desc' => 'Papaya whip',
					'orig' => FALSE,
                },
                'B_SEA SHELL' => {
                    'out'  => $csi . '48:2:255:245:238m',
                    'desc' => 'Sea shell',
					'orig' => FALSE,
                },
                'B_MINT CREAM' => {
                    'out'  => $csi . '48:2:245:255:250m',
                    'desc' => 'Mint green',
					'orig' => FALSE,
                },
                'B_SLATE GREY' => {
                    'out'  => $csi . '48:2:112:128:144m',
                    'desc' => 'Slate gray',
					'orig' => FALSE,
                },
                'B_LIGHT SLATE GREY' => {
                    'out'  => $csi . '48:2:119:136:153m',
                    'desc' => 'Lisght slate gray',
					'orig' => FALSE,
                },
                'B_LIGHT STEEL BLUE' => {
                    'out'  => $csi . '48:2:176:196:222m',
                    'desc' => 'Light steel blue',
					'orig' => FALSE,
                },
                'B_LAVENDER' => {
                    'out'  => $csi . '48:2:230:230:250m',
                    'desc' => 'Lavender',
					'orig' => FALSE,
                },
                'B_FLORAL WHITE' => {
                    'out'  => $csi . '48:2:255:250:240m',
                    'desc' => 'Floral white',
					'orig' => FALSE,
                },
                'B_ALICE BLUE' => {
                    'out'  => $csi . '48:2:240:248:255m',
                    'desc' => 'Alice blue',
					'orig' => FALSE,
                },
                'B_GHOST WHITE' => {
                    'out'  => $csi . '48:2:248:248:255m',
                    'desc' => 'Ghost white',
					'orig' => FALSE,
                },
                'B_HONEYDEW' => {
                    'out'  => $csi . '48:2:240:255:240m',
                    'desc' => 'Honeydew',
					'orig' => FALSE,
                },
                'B_IVORY' => {
                    'out'  => $csi . '48:2:255:255:240m',
                    'desc' => 'Ivory',
					'orig' => FALSE,
                },
                'B_AZURE' => {
                    'out'  => $csi . '48:2:240:255:255m',
                    'desc' => 'Azure',
					'orig' => FALSE,
                },
                'B_SNOW' => {
                    'out'  => $csi . '48:2:255:250:250m',
                    'desc' => 'Snow',
					'orig' => FALSE,
                },
                'B_DIM GREY' => {
                    'out'  => $csi . '48:2:105:105:105m',
                    'desc' => 'Dim gray',
					'orig' => FALSE,
                },
                'B_DARK GREY' => {
                    'out'  => $csi . '48:2:169:169:169m',
                    'desc' => 'Dark gray',
					'orig' => FALSE,
                },
                'B_SILVER' => {
                    'out'  => $csi . '48:2:192:192:192m',
                    'desc' => 'Silver',
					'orig' => FALSE,
                },
                'B_LIGHT GREY' => {
                    'out'  => $csi . '48:2:211:211:211m',
                    'desc' => 'Light gray',
					'orig' => FALSE,
                },
                'B_GAINSBORO' => {
                    'out'  => $csi . '48:2:220:220:220m',
                    'desc' => 'Gainsboro',
					'orig' => FALSE,
                },
                'B_WHITE SMOKE' => {
                    'out'  => $csi . '48:2:245:245:245m',
                    'desc' => 'White smoke',
					'orig' => FALSE,
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

Term::ANSIEncode

=head1 SYNOPSIS

A markup language to generate basic ANSI text.  A terminal that supports UTF-8 is required if you wish to have special characters, both graphical and international.

=head1 USAGE

 my $ansi = Term::ANSIEncode->new;

 my $string = '[% CLS %]Some markup encoded string';

 $ansi->ansi_output($string);

=head1 TOKENS

=head2 GENERAL

=over 4

=item B<[% RETURN %]>

ASCII RETURN (13)

=item B<[% LINEFEED %]>

ASCII LINEFEED (10)

=item B<[% NEWLINE %]>

RETURN + LINEFEED (13 + 10)

=item B<[% CLS %]>

Places cursor at top left, screen cleared

=item B<[% CLEAR %]>

Clear screen only, cursor remains where it was

=item B<[% CLEAR LINE %]>

Clear to the end of line

=item B<[% CLEAR DOWN %]>

Clear down from current cursor position

=item B<[% CLEAR UP %]>

Clear up from current cursor position

=item B<[% RESET %]>

Reset all colors and attributes

=back

=head2 CURSOR

=over 4

=item B<[% HOME %]>

Moves the cursor to the location 1,1.

=item B<[% UP %]>

Moves cursor up one step

=item B<[% DOWN %]>

Moves cursor down one step

=item B<[% RIGHT %]>

Moves cursor right one step

=item B<[% LEFT %]>

Moves cursor left one step

=item B<[% SAVE %]>

Save cursor position

=item B<[% RESTORE %]>

Place cursor at saved position

=item B<[% BOLD %]>

Bold text (not all terminals support this)

=item B<[% FAINT %]>

Faded text (not all terminals support this)

=item B<[% ITALIC %]>

Italicized text (not all terminals support this)

=item B<[% UNDERLINE %]>

Underlined text

=item B<[% SLOW BLINK %]>

Slow cursor blink

=item B<[% RAPID BLINK %]>

Rapid cursor blink

=item B<[% LOCATE column,row %]>

Set cursor position

=back

=head2 ATTRIBUTES

=over 4

=item B<[% INVERT %]>

Invert text (flip background and foreground attributes)

=item B<[% REVERSE %]>

Reverse

=item B<[% CROSSED OUT %]>

Crossed out

=item B<{% DEFAULT FONT %]>

Default font

=back

=head2 FRAMES

=over 4

=item B<[% BOX color,x,y,width,height,type %]> text here B<[% ENDBOX %]>

Draw a frame around text

Types = THIN, ROUND, THICK, BLOCK, WEDGE, DOTS, DIAMOND, STAR, SQUARE

=back

=head2 COLORS

=over 4

=item B<[% NORMAL %]>

Sets colors to default

=back

=head2 FOREGROUND

There are many more foreground colors available than the sixteen below.  However, the ones below should work on any color terminal.  Other colors may requite 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have "Term256" features.  You can used the "-t" option for all of the color tokens available or use the "RGB" token for access to 16 million colors.

=over 4

=item BLACK          = Black
=item RED            = Red
=item GREEN          = Green
=item YELLOW         = Yellow
=item BLUE           = Blue
=item MAGENTA        = Magenta
=item CYAN           = Cyan
=item WHITE          = White
=item DEFAULT        = Default foreground color
=item BRIGHT BLACK   = Bright black (dim grey)
=item BRIGHT RED     = Bright red
=item BRIGHT GREEN   = Lime
=item BRIGHT YELLOW  = Bright Yellow
=item BRIGHT BLUE    = Bright blue
=item BRIGHT MAGENTA = Bright magenta
=item BRIGHT CYAN    = Bright cyan
=item BRIGHT WHITE   = Bright white

=back

=head2 BACKGROUND

There are many more background colors available than the sixteen below.  However, the ones below should work on any color terminal.  Other colors may requite 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have "Term256" features.  You can used the "-t" option for all of the color tokens available or use the "B_RGB" token for access to 16 million colors.

=over 4

=item B_BLACK          = Black
=item B_RED            = Red
=item B_GREEN          = Green
=item B_YELLOW         = Yellow
=item B_BLUE           = Blue
=item B_MAGENTA        = Magenta
=item B_CYAN           = Cyan
=item B_WHITE          = White
=item B_DEFAULT        = Default background color
=item BRIGHT B_BLACK   = Bright black (grey)
=item BRIGHT B_RED     = Bright red
=item BRIGHT B_GREEN   = Lime
=item BRIGHT B_YELLOW  = Bright yellow
=item BRIGHT B_BLUE    = Bright blue
=item BRIGHT B_MAGENTA = Bright magenta
=item BRIGHT B_CYAN    = Bright cyan
=item BRIGHT B_WHITE   = Bright white

=back

=head2 HORIZONAL RULES

Makes a solid blank line, the full width of the screen with the selected color

For example, for a color of blue, use the following

  [% HORIZONTAL RULE BLUE %]

=over 4

=item HORIZONTAL RULE [color]             = A solid line of [color] background

=back

=head1 AUTHOR & COPYRIGHT

Richard Kelsch

 Copyright (C) 2025 Richard Kelsch
 All Rights Reserved
 Perl Artistic License

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut
