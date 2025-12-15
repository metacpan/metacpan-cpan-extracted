package Term::ANSIEncode 1.53;

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
use warnings;
use utf8;    # REQUIRED
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

# use Term::Drawille;

# UTF-8 is required for special character handling
binmode(STDERR, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDIN,  ":encoding(UTF-8)");

# Package-level caches so large tables are built only once per process.
our $GLOBAL_ANSI_META = _global_ansi_meta();

# Table of styles. Each entry is [tl,tr,bl,br,top,bot,vl,vr]
our %STYLES = (
    DEFAULT       => ['╔', '╗', '╚', '╝', '═', '═', '║', '║'],
    THIN          => ['┌', '┐', '└', '┘', '─', '─', '│', '│'],
    ROUND         => ['╭', '╮', '╰', '╯', '─', '─', '│', '│'],
    THICK         => ['┏', '┓', '┗', '┛', '━', '━', '┃', '┃'],
    BLOCK         => ['🬚', '🬩', '🬌', '🬍', '🬋', '🬋', '▌', '▐'],
    WEDGE         => ['🭊', '🬿', '🭥', '🭚', '▅', '🮄', '█', '█'],
    'BIG WEDGE'   => ['◢', '◣', '◥', '◤', '█', '█', '█', '█'],
    DOTS          => ['🞄', '🞄', '🞄', '🞄', '🞄', '🞄', '🞄', '🞄'],
    DIAMOND       => ['⧫', '⧫', '⧫', '⧫', '⧫', '⧫', '⧫', '⧫'],
    STAR          => ['⭑', '⭑', '⭑', '⭑', '⭑', '⭑', '⭑', '⭑'],
    CIRCLE        => ['○', '○', '○', '○', '○', '○', '○', '○'],
    SQUARE        => ['∎', '∎', '∎', '∎', '∎', '∎', '∎', '∎'],
    DITHERED      => ['▒', '▒', '▒', '▒', '▒', '▒', '▒', '▒'],
    HEART         => ['♥', '♥', '♥', '♥', '♥', '♥', '♥', '♥'],
    CHRISTIAN     => ['🕇', '🕇', '🕇', '🕇', '🕇', '🕇', '🕇', '🕇'],
    NOTES         => ['♪', '♪', '♪', '♪', '♪', '♪', '♪', '♪'],
    PARALLELOGRAM => ['▰', '▰', '▰', '▰', '▰', '▰', '▰', '▰'],
    'BIG ARROWS'  => ['▶', '▶', '◀', '◀', '▶', '◀', '▲', '▼'],
    ARROWS        => ['🡕', '🡖', '🡔', '🡗', '🡒', '🡐', '🡑', '🡓'],
);

# Returns a description of a token using the meta data.
sub ansi_description {
    my ($self, $code, $name) = @_;

    return ($self->{'ansi_meta'}->{$code}->{$name}->{'desc'});
}

# This was far easier to read with my original code.  However, AI actually did
# optimize and shrink the code quite well and it seems to be much faster.
sub ansi_decode {
    my ($self, $text) = @_;

    # Nothing to do for very short strings
    return $text unless defined $text && length($text) > 1;

    # If a literal screen reset token exists, remove it and run reset once.
    if ($text =~ /\[\%\s*SCREEN\s+RESET\s*\%\]/i) {
        $text =~ s/\[\%\s*SCREEN\s+RESET\s*\%\]//gis;
        system('reset');
    }

    # Convenience CSI
    my $csi = $self->{'ansi_meta'}->{special}->{CSI}->{out};

    #
    # BOX blocks (BOX ... ENDBOX) - handle first.
    # Use a while loop and plain Perl code for replacements (avoid s///e/do-block in-place),
    # so we don't accidentally create replacement-string interpolation warnings.
    #
    while ($text =~ m{\[\%\s*BOX\s*(.*?)\s*\%\](.*?)\[\%\s*ENDBOX\s*\%\]}is) {
        my ($params, $body) = ($1, $2);

        # split into up to 6 params: color,x,y,w,h,type
        my @parts = split(/\s*,\s*/, (defined $params ? $params : ''), 6);

        # normalize empty strings to undef and ensure six elements
        for (@parts) { $_ = undef if defined $_ && $_ eq '' }
        push @parts, undef while @parts < 6;

        my $replace = $self->box($parts[0], $parts[1], $parts[2], $parts[3], $parts[4], $parts[5], $body);

        # replace the first occurrence of the matched block. Use \Q...\E to avoid any regex
        # metacharacter pitfalls when substituting the exact matched substring ($&).
        my $matched = $&;    # exact substring matched by the pattern
        $text =~ s/\Q$matched\E/$replace/;
    } ## end while ($text =~ m{\[\%\s*BOX\s*(.*?)\s*\%\](.*?)\[\%\s*ENDBOX\s*\%\]}is)

    #
    # Targeted parameterized tokens (single-pass). These are simple Regex -> CSI conversions.
    #
    $text =~ s/\[\%\s*LOCATE\s+(\d+)\s*,\s*(\d+)\s*\%\]/ $csi . "$2;$1" . 'H' /eigs;
    $text =~ s/\[\%\s*SCROLL\s+UP\s+(\d+)\s*\%\]/     $csi . $1 . 'S'           /eigs;
    $text =~ s/\[\%\s*SCROLL\s+DOWN\s+(\d+)\s*\%\]/   $csi . $1 . 'T'           /eigs;

    # HORIZONTAL RULE expands into a sequence of meta-tokens (resolved later).
    $text =~ s/\[\%\s*HORIZONTAL\s+RULE\s+(.*?)\s*\%\]/
              do {
                              my $color = defined $1 && $1 ne '' ? uc $1 : 'DEFAULT';
                              '[% RETURN %][% B_' . $color . ' %][% CLEAR LINE %][% RESET %]';
                          }/eigs;

	while($text =~ /\[\%\s+UNDERLINE COLOR RGB (\d+),(\d+),(\d+)\s+\%\]/) {
		my ($red, $green, $blue) = ($1, $2, $3);
		my $new = "\e[58;2;${red};${green};${blue}m";
		$text =~ s/\[\%\s+UNDERLINE COLOR RGB $red,$green,$blue\s+\%\]/$new/gs;
	}
	while($text =~ /\[\%\s+UNDERLINE COLOR (.*?)\s+\%\]/) {
		my $color = $1;
		my $new;
		$new = "\e[58;5;" . substr($self->{'ansi_meta'}->{'foreground'}->{$color}->{'out'},3);
		$text =~ s/\[\%\s+UNDERLINE COLOR $color\s+\%\]/$new/gs;
	}

	# 24-bit RGB foreground/background
    $text =~ s/\[\%\s*RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\%\]/
              do { my ($r,$g,$b)=($1&255,$2&255,$3&255); $csi . "38:2:$r:$g:$b" . 'm' }/eigs;
    $text =~ s/\[\%\s*B_RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\%\]/
              do { my ($r,$g,$b)=($1&255,$2&255,$3&255); $csi . "48:2:$r:$g:$b" . 'm' }/eigs;

    #
    # Flatten the ansi_meta lookup to a simple, case-insensitive hash for a single-pass
    # substitution of tokens like [% RED %], [% RESET %], etc.
    #
    my %lookup;
    for my $code (qw(foreground background special clear cursor attributes)) {
        my $map = $self->{'ansi_meta'}->{$code} or next;
        while (my ($name, $info) = each %{$map}) {
            next unless defined $info->{out};
            $lookup{ lc $name } = $info->{out};
        }
    } ## end for my $code (qw(foreground background special clear cursor attributes))

    # Final single-pass replacement for remaining [% ... %] tokens.
    # If token matches a lookup entry, substitute; otherwise if it's a named char use charnames;
    # else leave token visible.
###
    $text =~ s/\[\%\s*(.+?)\s*\%\]/
        do {
            my $tok = $1;
            my $key = lc $tok;
            if ( exists $lookup{$key} ) {
                $lookup{$key};
            } elsif ( defined( my $char = charnames::string_vianame($tok) ) ) {
                $char;
            } else {
                $&;    # leave the original token intact
            }
        }/egis;
###
    return $text;
} ## end sub ansi_decode

sub ansi_output {
    my ($self, $text) = @_;

    $text = $self->ansi_decode($text);
    $text =~ s/\[ \% TOKEN \% \]/\[\% TOKEN \%\]/;    # Special token to show [% TOKEN %] on output
    print $text;
    return (TRUE);
} ## end sub ansi_output

sub box {
    my ($self, $color, $x, $y, $w, $h, $type, $string) = @_;

    # Basic validation/fallbacks
    $w ||= 3;
    $h ||= 3;
    $w = (int($w) < 3) ? 3 : int($w);
    $h = (int($h) < 3) ? 3 : int($h);

    $color = '[% ' . ($color // 'DEFAULT') . ' %]';

    # Normalize type and pick style (fall back to DEFAULT)
    my $key = (defined($type)) ? uc($type) : 'DEFAULT';
    $key =~ s/^\s+|\s+$//g;
    $key = ($key eq '') ? 'DEFAULT' : $key;

    my $style = $STYLES{$key} // $STYLES{DEFAULT};
    my ($tl, $tr, $bl, $br, $top, $bot, $vl, $vr) = @{$style};

    # Build the box text efficiently
    my $text = '';

    # Top line
    $text .= locate($y, $x) . $color . $tl . ($top x ($w - 2)) . $tr . '[% RESET %]';

    # Middle lines
    for my $row (1 .. ($h - 2)) {
        $text .= locate($y + $row, $x) . $color . $vl . '[% RESET %]' . (' ' x ($w - 2)) . $color . $vr . '[% RESET %]';
    }

    # Bottom line + save cursor
    $text .= locate($y + $h - 1, $x) . $color . $bl . ($bot x ($w - 2)) . $br . '[% RESET %]' . $self->{'ansi_meta'}->{'cursor'}->{'SAVE'}->{'out'};

    # Position cursor inside box and wrap text
    $text .= locate($y + 1, $x + 1);
    chomp(my @lines = fuzzy_wrap($string // '', ($w - 3)));

    my $line_y = $y + 1;
    foreach my $line (@lines) {
        last if $line_y >= ($y + $h - 1);    # avoid writing outside the box
        $text .= locate($line_y++, $x + 1) . $line;
    }

    # Restore cursor
    $text .= $self->{'ansi_meta'}->{'cursor'}->{'RESTORE'}->{'out'};

    return ($text);
} ## end sub box

sub new {
    my ($class) = @_;
    my $esc     = chr(27);
    my $csi     = $esc . '[';

    my $self = {
        'ansi_prefix' => $csi,
        'list'        => [(0x20 .. 0x7F, 0xA0 .. 0xFF, 0x2010 .. 0x205F, 0x2070 .. 0x242F, 0x2440 .. 0x244F, 0x2460 .. 0x29FF, 0x1F300 .. 0x1F8BF, 0x1F900 .. 0x1FBBF, 0x1F900 .. 0x1FBCF, 0x1FBF0 .. 0x1FBFF)],
        'ansi_meta'   => $GLOBAL_ANSI_META,
    };

    bless($self, $class);
    return ($self);
} ## end sub new

sub _global_ansi_meta {    # prefills the hash cache
    my $esc = chr(27);
    my $csi = $esc . '[';
    my $tmp = {
        'special' => {
            'APC' => {
                'out'  => $esc . '_',
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
            'FONT DOUBLE-HEIGHT TOP' => {
                'out'  => $esc . '#3',
                'desc' => 'Double-Height Font Top Portion',
            },
            'FONT DOUBLE-HEIGHT BOTTOM' => {
                'out'  => $esc . '#4',
                'desc' => 'Double-Height Font Bottom Portion',
            },
            'FONT DOUBLE-WIDTH' => {
                'out'  => $esc . '#6',
                'desc' => 'Double-Width Font',
            },
            'FONT DEFAULT' => {
                'out'  => $esc . '#5',
                'desc' => 'Default Font Size',
            },
			'RING BELL' => {
				'out' => chr(7),
				'desc' => 'Console Bell',
			},
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
            'DARK SLATE GRAY' => {
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
            'SLATE GRAY' => {
                'out'  => $csi . '38:2:112:128:144m',
                'desc' => 'Slate gray',
            },
            'LIGHT SLATE GRAY' => {
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
            'DIM GRAY' => {
                'out'  => $csi . '38:2:105:105:105m',
                'desc' => 'Dim gray',
            },
            'DARK GRAY' => {
                'out'  => $csi . '38:2:169:169:169m',
                'desc' => 'Dark gray',
            },
            'SILVER' => {
                'out'  => $csi . '38:2:192:192:192m',
                'desc' => 'Silver',
            },
            'LIGHT GRAY' => {
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
            'AIR FORCE BLUE' => {
                'desc' => 'Air Force blue',
                'out'  => $csi . '38:2:93:138:168m',
            },
            'ALICE BLUE' => {
                'desc' => 'Alice blue',
                'out'  => $csi . '38:2:240:248:255m',
            },
            'ALIZARIN CRIMSON' => {
                'desc' => 'Alizarin crimson',
                'out'  => $csi . '38:2:227:38:54m',
            },
            'ALMOND' => {
                'desc' => 'Almond',
                'out'  => $csi . '38:2:239:222:205m',
            },
            'AMARANTH' => {
                'desc' => 'Amaranth',
                'out'  => $csi . '38:2:229:43:80m',
            },
            'AMBER' => {
                'desc' => 'Amber',
                'out'  => $csi . '38:2:255:191:0m',
            },
            'AMERICAN ROSE' => {
                'desc' => 'American rose',
                'out'  => $csi . '38:2:255:3:62m',
            },
            'AMETHYST' => {
                'desc' => 'Amethyst',
                'out'  => $csi . '38:2:153:102:204m',
            },
            'ANDROID GREEN' => {
                'desc' => 'Android Green',
                'out'  => $csi . '38:2:164:198:57m',
            },
            'ANTI-FLASH WHITE' => {
                'desc' => 'Anti-flash white',
                'out'  => $csi . '38:2:242:243:244m',
            },
            'ANTIQUE BRASS' => {
                'desc' => 'Antique brass',
                'out'  => $csi . '38:2:205:149:117m',
            },
            'ANTIQUE FUCHSIA' => {
                'desc' => 'Antique fuchsia',
                'out'  => $csi . '38:2:145:92:131m',
            },
            'ANTIQUE WHITE' => {
                'desc' => 'Antique white',
                'out'  => $csi . '38:2:250:235:215m',
            },
            'AO' => {
                'desc' => 'Ao',
                'out'  => $csi . '38:2:0:128:0m',
            },
            'APPLE GREEN' => {
                'desc' => 'Apple green',
                'out'  => $csi . '38:2:141:182:0m',
            },
            'APRICOT' => {
                'desc' => 'Apricot',
                'out'  => $csi . '38:2:251:206:177m',
            },
            'AQUA' => {
                'desc' => 'Aqua',
                'out'  => $csi . '38:2:0:255:255m',
            },
            'AQUAMARINE' => {
                'desc' => 'Aquamarine',
                'out'  => $csi . '38:2:127:255:212m',
            },
            'ARMY GREEN' => {
                'desc' => 'Army green',
                'out'  => $csi . '38:2:75:83:32m',
            },
            'ARYLIDE YELLOW' => {
                'desc' => 'Arylide yellow',
                'out'  => $csi . '38:2:233:214:107m',
            },
            'ASH GRAY' => {
                'desc' => 'Ash grey',
                'out'  => $csi . '38:2:178:190:181m',
            },
            'ASPARAGUS' => {
                'desc' => 'Asparagus',
                'out'  => $csi . '38:2:135:169:107m',
            },
            'ATOMIC TANGERINE' => {
                'desc' => 'Atomic tangerine',
                'out'  => $csi . '38:2:255:153:102m',
            },
            'AUBURN' => {
                'desc' => 'Auburn',
                'out'  => $csi . '38:2:165:42:42m',
            },
            'AUREOLIN' => {
                'desc' => 'Aureolin',
                'out'  => $csi . '38:2:253:238:0m',
            },
            'AUROMETALSAURUS' => {
                'desc' => 'AuroMetalSaurus',
                'out'  => $csi . '38:2:110:127:128m',
            },
            'AWESOME' => {
                'desc' => 'Awesome',
                'out'  => $csi . '38:2:255:32:82m',
            },
            'AZURE' => {
                'desc' => 'Azure',
                'out'  => $csi . '38:2:0:127:255m',
            },
            'AZURE MIST' => {
                'desc' => 'Azure mist',
                'out'  => $csi . '38:2:240:255:255m',
            },
            'BABY BLUE' => {
                'desc' => 'Baby blue',
                'out'  => $csi . '38:2:137:207:240m',
            },
            'BABY BLUE EYES' => {
                'desc' => 'Baby blue eyes',
                'out'  => $csi . '38:2:161:202:241m',
            },
            'BABY PINK' => {
                'desc' => 'Baby pink',
                'out'  => $csi . '38:2:244:194:194m',
            },
            'BALL BLUE' => {
                'desc' => 'Ball Blue',
                'out'  => $csi . '38:2:33:171:205m',
            },
            'BANANA MANIA' => {
                'desc' => 'Banana Mania',
                'out'  => $csi . '38:2:250:231:181m',
            },
            'BANANA YELLOW' => {
                'desc' => 'Banana yellow',
                'out'  => $csi . '38:2:255:225:53m',
            },
            'BATTLESHIP GRAY' => {
                'desc' => 'Battleship grey',
                'out'  => $csi . '38:2:132:132:130m',
            },
            'BAZAAR' => {
                'desc' => 'Bazaar',
                'out'  => $csi . '38:2:152:119:123m',
            },
            'BEAU BLUE' => {
                'desc' => 'Beau blue',
                'out'  => $csi . '38:2:188:212:230m',
            },
            'BEAVER' => {
                'desc' => 'Beaver',
                'out'  => $csi . '38:2:159:129:112m',
            },
            'BEIGE' => {
                'desc' => 'Beige',
                'out'  => $csi . '38:2:245:245:220m',
            },
            'BISQUE' => {
                'desc' => 'Bisque',
                'out'  => $csi . '38:2:255:228:196m',
            },
            'BISTRE' => {
                'desc' => 'Bistre',
                'out'  => $csi . '38:2:61:43:31m',
            },
            'BITTERSWEET' => {
                'desc' => 'Bittersweet',
                'out'  => $csi . '38:2:254:111:94m',
            },
            'BLANCHED ALMOND' => {
                'desc' => 'Blanched Almond',
                'out'  => $csi . '38:2:255:235:205m',
            },
            'BLEU DE FRANCE' => {
                'desc' => 'Bleu de France',
                'out'  => $csi . '38:2:49:140:231m',
            },
            'BLIZZARD BLUE' => {
                'desc' => 'Blizzard Blue',
                'out'  => $csi . '38:2:172:229:238m',
            },
            'BLOND' => {
                'desc' => 'Blond',
                'out'  => $csi . '38:2:250:240:190m',
            },
            'BLUE BELL' => {
                'desc' => 'Blue Bell',
                'out'  => $csi . '38:2:162:162:208m',
            },
            'BLUE GRAY' => {
                'desc' => 'Blue Gray',
                'out'  => $csi . '38:2:102:153:204m',
            },
            'BLUE GREEN' => {
                'desc' => 'Blue green',
                'out'  => $csi . '38:2:13:152:186m',
            },
            'BLUE PURPLE' => {
                'desc' => 'Blue purple',
                'out'  => $csi . '38:2:138:43:226m',
            },
            'BLUE VIOLET' => {
                'desc' => 'Blue violet',
                'out'  => $csi . '38:2:138:43:226m',
            },
            'BLUSH' => {
                'desc' => 'Blush',
                'out'  => $csi . '38:2:222:93:131m',
            },
            'BOLE' => {
                'desc' => 'Bole',
                'out'  => $csi . '38:2:121:68:59m',
            },
            'BONDI BLUE' => {
                'desc' => 'Bondi blue',
                'out'  => $csi . '38:2:0:149:182m',
            },
            'BONE' => {
                'desc' => 'Bone',
                'out'  => $csi . '38:2:227:218:201m',
            },
            'BOSTON UNIVERSITY RED' => {
                'desc' => 'Boston University Red',
                'out'  => $csi . '38:2:204:0:0m',
            },
            'BOTTLE GREEN' => {
                'desc' => 'Bottle green',
                'out'  => $csi . '38:2:0:106:78m',
            },
            'BOYSENBERRY' => {
                'desc' => 'Boysenberry',
                'out'  => $csi . '38:2:135:50:96m',
            },
            'BRANDEIS BLUE' => {
                'desc' => 'Brandeis blue',
                'out'  => $csi . '38:2:0:112:255m',
            },
            'BRASS' => {
                'desc' => 'Brass',
                'out'  => $csi . '38:2:181:166:66m',
            },
            'BRICK RED' => {
                'desc' => 'Brick red',
                'out'  => $csi . '38:2:203:65:84m',
            },
            'BRIGHT CERULEAN' => {
                'desc' => 'Bright cerulean',
                'out'  => $csi . '38:2:29:172:214m',
            },
            'BRIGHT GREEN' => {
                'desc' => 'Bright green',
                'out'  => $csi . '38:2:102:255:0m',
            },
            'BRIGHT LAVENDER' => {
                'desc' => 'Bright lavender',
                'out'  => $csi . '38:2:191:148:228m',
            },
            'BRIGHT MAROON' => {
                'desc' => 'Bright maroon',
                'out'  => $csi . '38:2:195:33:72m',
            },
            'BRIGHT PINK' => {
                'desc' => 'Bright pink',
                'out'  => $csi . '38:2:255:0:127m',
            },
            'BRIGHT TURQUOISE' => {
                'desc' => 'Bright turquoise',
                'out'  => $csi . '38:2:8:232:222m',
            },
            'BRIGHT UBE' => {
                'desc' => 'Bright ube',
                'out'  => $csi . '38:2:209:159:232m',
            },
            'BRILLIANT LAVENDER' => {
                'desc' => 'Brilliant lavender',
                'out'  => $csi . '38:2:244:187:255m',
            },
            'BRILLIANT ROSE' => {
                'desc' => 'Brilliant rose',
                'out'  => $csi . '38:2:255:85:163m',
            },
            'BRINK PINK' => {
                'desc' => 'Brink pink',
                'out'  => $csi . '38:2:251:96:127m',
            },
            'BRITISH RACING GREEN' => {
                'desc' => 'British racing green',
                'out'  => $csi . '38:2:0:66:37m',
            },
            'BRONZE' => {
                'desc' => 'Bronze',
                'out'  => $csi . '38:2:205:127:50m',
            },
            'BROWN' => {
                'desc' => 'Brown',
                'out'  => $csi . '38:2:165:42:42m',
            },
            'BUBBLE GUM' => {
                'desc' => 'Bubble gum',
                'out'  => $csi . '38:2:255:193:204m',
            },
            'BUBBLES' => {
                'desc' => 'Bubbles',
                'out'  => $csi . '38:2:231:254:255m',
            },
            'BUFF' => {
                'desc' => 'Buff',
                'out'  => $csi . '38:2:240:220:130m',
            },
            'BULGARIAN ROSE' => {
                'desc' => 'Bulgarian rose',
                'out'  => $csi . '38:2:72:6:7m',
            },
            'BURGUNDY' => {
                'desc' => 'Burgundy',
                'out'  => $csi . '38:2:128:0:32m',
            },
            'BURLYWOOD' => {
                'desc' => 'Burlywood',
                'out'  => $csi . '38:2:222:184:135m',
            },
            'BURNT ORANGE' => {
                'desc' => 'Burnt orange',
                'out'  => $csi . '38:2:204:85:0m',
            },
            'BURNT SIENNA' => {
                'desc' => 'Burnt sienna',
                'out'  => $csi . '38:2:233:116:81m',
            },
            'BURNT UMBER' => {
                'desc' => 'Burnt umber',
                'out'  => $csi . '38:2:138:51:36m',
            },
            'BYZANTINE' => {
                'desc' => 'Byzantine',
                'out'  => $csi . '38:2:189:51:164m',
            },
            'BYZANTIUM' => {
                'desc' => 'Byzantium',
                'out'  => $csi . '38:2:112:41:99m',
            },
            'CADET' => {
                'desc' => 'Cadet',
                'out'  => $csi . '38:2:83:104:114m',
            },
            'CADET BLUE' => {
                'desc' => 'Cadet blue',
                'out'  => $csi . '38:2:95:158:160m',
            },
            'CADET GRAY' => {
                'desc' => 'Cadet grey',
                'out'  => $csi . '38:2:145:163:176m',
            },
            'CADMIUM GREEN' => {
                'desc' => 'Cadmium green',
                'out'  => $csi . '38:2:0:107:60m',
            },
            'CADMIUM ORANGE' => {
                'desc' => 'Cadmium orange',
                'out'  => $csi . '38:2:237:135:45m',
            },
            'CADMIUM RED' => {
                'desc' => 'Cadmium red',
                'out'  => $csi . '38:2:227:0:34m',
            },
            'CADMIUM YELLOW' => {
                'desc' => 'Cadmium yellow',
                'out'  => $csi . '38:2:255:246:0m',
            },
            'CAFE AU LAIT' => {
                'desc' => 'Caf\303\251 au lait',
                'out'  => $csi . '38:2:166:123:91m',
            },
            'CAFE NOIR' => {
                'desc' => 'Caf\303\251 noir',
                'out'  => $csi . '38:2:75:54:33m',
            },
            'CAL POLY POMONA GREEN' => {
                'desc' => 'Cal Poly Pomona green',
                'out'  => $csi . '38:2:30:77:43m',
            },
            'UNIVERSITY OF CALIFORNIA GOLD' => {
                'desc' => 'University of California Gold',
                'out'  => $csi . '38:2:183:135:39m',
            },
            'CAMBRIDGE BLUE' => {
                'desc' => 'Cambridge Blue',
                'out'  => $csi . '38:2:163:193:173m',
            },
            'CAMEL' => {
                'desc' => 'Camel',
                'out'  => $csi . '38:2:193:154:107m',
            },
            'CAMOUFLAGE GREEN' => {
                'desc' => 'Camouflage green',
                'out'  => $csi . '38:2:120:134:107m',
            },
            'CANARY' => {
                'desc' => 'Canary',
                'out'  => $csi . '38:2:255:255:153m',
            },
            'CANARY YELLOW' => {
                'desc' => 'Canary yellow',
                'out'  => $csi . '38:2:255:239:0m',
            },
            'CANDY APPLE RED' => {
                'desc' => 'Candy apple red',
                'out'  => $csi . '38:2:255:8:0m',
            },
            'CANDY PINK' => {
                'desc' => 'Candy pink',
                'out'  => $csi . '38:2:228:113:122m',
            },
            'CAPRI' => {
                'desc' => 'Capri',
                'out'  => $csi . '38:2:0:191:255m',
            },
            'CAPUT MORTUUM' => {
                'desc' => 'Caput mortuum',
                'out'  => $csi . '38:2:89:39:32m',
            },
            'CARDINAL' => {
                'desc' => 'Cardinal',
                'out'  => $csi . '38:2:196:30:58m',
            },
            'CARIBBEAN GREEN' => {
                'desc' => 'Caribbean green',
                'out'  => $csi . '38:2:0:204:153m',
            },
            'CARMINE' => {
                'desc' => 'Carmine',
                'out'  => $csi . '38:2:255:0:64m',
            },
            'CARMINE PINK' => {
                'desc' => 'Carmine pink',
                'out'  => $csi . '38:2:235:76:66m',
            },
            'CARMINE RED' => {
                'desc' => 'Carmine red',
                'out'  => $csi . '38:2:255:0:56m',
            },
            'CARNATION PINK' => {
                'desc' => 'Carnation pink',
                'out'  => $csi . '38:2:255:166:201m',
            },
            'CARNELIAN' => {
                'desc' => 'Carnelian',
                'out'  => $csi . '38:2:179:27:27m',
            },
            'CAROLINA BLUE' => {
                'desc' => 'Carolina blue',
                'out'  => $csi . '38:2:153:186:221m',
            },
            'CARROT ORANGE' => {
                'desc' => 'Carrot orange',
                'out'  => $csi . '38:2:237:145:33m',
            },
            'CELADON' => {
                'desc' => 'Celadon',
                'out'  => $csi . '38:2:172:225:175m',
            },
            'CELESTE' => {
                'desc' => 'Celeste',
                'out'  => $csi . '38:2:178:255:255m',
            },
            'CELESTIAL BLUE' => {
                'desc' => 'Celestial blue',
                'out'  => $csi . '38:2:73:151:208m',
            },
            'CERISE' => {
                'desc' => 'Cerise',
                'out'  => $csi . '38:2:222:49:99m',
            },
            'CERISE PINK' => {
                'desc' => 'Cerise pink',
                'out'  => $csi . '38:2:236:59:131m',
            },
            'CERULEAN' => {
                'desc' => 'Cerulean',
                'out'  => $csi . '38:2:0:123:167m',
            },
            'CERULEAN BLUE' => {
                'desc' => 'Cerulean blue',
                'out'  => $csi . '38:2:42:82:190m',
            },
            'CG BLUE' => {
                'desc' => 'CG Blue',
                'out'  => $csi . '38:2:0:122:165m',
            },
            'CG RED' => {
                'desc' => 'CG Red',
                'out'  => $csi . '38:2:224:60:49m',
            },
            'CHAMOISEE' => {
                'desc' => 'Chamoisee',
                'out'  => $csi . '38:2:160:120:90m',
            },
            'CHAMPAGNE' => {
                'desc' => 'Champagne',
                'out'  => $csi . '38:2:250:214:165m',
            },
            'CHARCOAL' => {
                'desc' => 'Charcoal',
                'out'  => $csi . '38:2:54:69:79m',
            },
            'CHARTREUSE' => {
                'desc' => 'Chartreuse',
                'out'  => $csi . '38:2:127:255:0m',
            },
            'CHERRY' => {
                'desc' => 'Cherry',
                'out'  => $csi . '38:2:222:49:99m',
            },
            'CHERRY BLOSSOM PINK' => {
                'desc' => 'Cherry blossom pink',
                'out'  => $csi . '38:2:255:183:197m',
            },
            'CHESTNUT' => {
                'desc' => 'Chestnut',
                'out'  => $csi . '38:2:205:92:92m',
            },
            'CHOCOLATE' => {
                'desc' => 'Chocolate',
                'out'  => $csi . '38:2:210:105:30m',
            },
            'CHROME YELLOW' => {
                'desc' => 'Chrome yellow',
                'out'  => $csi . '38:2:255:167:0m',
            },
            'CINEREOUS' => {
                'desc' => 'Cinereous',
                'out'  => $csi . '38:2:152:129:123m',
            },
            'CINNABAR' => {
                'desc' => 'Cinnabar',
                'out'  => $csi . '38:2:227:66:52m',
            },
            'CINNAMON' => {
                'desc' => 'Cinnamon',
                'out'  => $csi . '38:2:210:105:30m',
            },
            'CITRINE' => {
                'desc' => 'Citrine',
                'out'  => $csi . '38:2:228:208:10m',
            },
            'CLASSIC ROSE' => {
                'desc' => 'Classic rose',
                'out'  => $csi . '38:2:251:204:231m',
            },
            'COBALT' => {
                'desc' => 'Cobalt',
                'out'  => $csi . '38:2:0:71:171m',
            },
            'COCOA BROWN' => {
                'desc' => 'Cocoa brown',
                'out'  => $csi . '38:2:210:105:30m',
            },
            'COFFEE' => {
                'desc' => 'Coffee',
                'out'  => $csi . '38:2:111:78:55m',
            },
            'COLUMBIA BLUE' => {
                'desc' => 'Columbia blue',
                'out'  => $csi . '38:2:155:221:255m',
            },
            'COOL BLACK' => {
                'desc' => 'Cool black',
                'out'  => $csi . '38:2:0:46:99m',
            },
            'COOL GRAY' => {
                'desc' => 'Cool grey',
                'out'  => $csi . '38:2:140:146:172m',
            },
            'COPPER' => {
                'desc' => 'Copper',
                'out'  => $csi . '38:2:184:115:51m',
            },
            'COPPER ROSE' => {
                'desc' => 'Copper rose',
                'out'  => $csi . '38:2:153:102:102m',
            },
            'COQUELICOT' => {
                'desc' => 'Coquelicot',
                'out'  => $csi . '38:2:255:56:0m',
            },
            'CORAL' => {
                'desc' => 'Coral',
                'out'  => $csi . '38:2:255:127:80m',
            },
            'CORAL PINK' => {
                'desc' => 'Coral pink',
                'out'  => $csi . '38:2:248:131:121m',
            },
            'CORAL RED' => {
                'desc' => 'Coral red',
                'out'  => $csi . '38:2:255:64:64m',
            },
            'CORDOVAN' => {
                'desc' => 'Cordovan',
                'out'  => $csi . '38:2:137:63:69m',
            },
            'CORN' => {
                'desc' => 'Corn',
                'out'  => $csi . '38:2:251:236:93m',
            },
            'CORNELL RED' => {
                'desc' => 'Cornell Red',
                'out'  => $csi . '38:2:179:27:27m',
            },
            'CORNFLOWER' => {
                'desc' => 'Cornflower',
                'out'  => $csi . '38:2:154:206:235m',
            },
            'CORNFLOWER BLUE' => {
                'desc' => 'Cornflower blue',
                'out'  => $csi . '38:2:100:149:237m',
            },
            'CORNSILK' => {
                'desc' => 'Cornsilk',
                'out'  => $csi . '38:2:255:248:220m',
            },
            'COSMIC LATTE' => {
                'desc' => 'Cosmic latte',
                'out'  => $csi . '38:2:255:248:231m',
            },
            'COTTON CANDY' => {
                'desc' => 'Cotton candy',
                'out'  => $csi . '38:2:255:188:217m',
            },
            'CREAM' => {
                'desc' => 'Cream',
                'out'  => $csi . '38:2:255:253:208m',
            },
            'CRIMSON' => {
                'desc' => 'Crimson',
                'out'  => $csi . '38:2:220:20:60m',
            },
            'CRIMSON GLORY' => {
                'desc' => 'Crimson glory',
                'out'  => $csi . '38:2:190:0:50m',
            },
            'CRIMSON RED' => {
                'desc' => 'Crimson Red',
                'out'  => $csi . '38:2:153:0:0m',
            },
            'DAFFODIL' => {
                'desc' => 'Daffodil',
                'out'  => $csi . '38:2:255:255:49m',
            },
            'DANDELION' => {
                'desc' => 'Dandelion',
                'out'  => $csi . '38:2:240:225:48m',
            },
            'DARK BLUE' => {
                'desc' => 'Dark blue',
                'out'  => $csi . '38:2:0:0:139m',
            },
            'DARK BROWN' => {
                'desc' => 'Dark brown',
                'out'  => $csi . '38:2:101:67:33m',
            },
            'DARK BYZANTIUM' => {
                'desc' => 'Dark byzantium',
                'out'  => $csi . '38:2:93:57:84m',
            },
            'DARK CANDY APPLE RED' => {
                'desc' => 'Dark candy apple red',
                'out'  => $csi . '38:2:164:0:0m',
            },
            'DARK CERULEAN' => {
                'desc' => 'Dark cerulean',
                'out'  => $csi . '38:2:8:69:126m',
            },
            'DARK CHESTNUT' => {
                'desc' => 'Dark chestnut',
                'out'  => $csi . '38:2:152:105:96m',
            },
            'DARK CORAL' => {
                'desc' => 'Dark coral',
                'out'  => $csi . '38:2:205:91:69m',
            },
            'DARK CYAN' => {
                'desc' => 'Dark cyan',
                'out'  => $csi . '38:2:0:139:139m',
            },
            'DARK ELECTRIC BLUE' => {
                'desc' => 'Dark electric blue',
                'out'  => $csi . '38:2:83:104:120m',
            },
            'DARK GOLDENROD' => {
                'desc' => 'Dark goldenrod',
                'out'  => $csi . '38:2:184:134:11m',
            },
            'DARK GRAY' => {
                'desc' => 'Dark gray',
                'out'  => $csi . '38:2:169:169:169m',
            },
            'DARK GREEN' => {
                'desc' => 'Dark green',
                'out'  => $csi . '38:2:1:50:32m',
            },
            'DARK JUNGLE GREEN' => {
                'desc' => 'Dark jungle green',
                'out'  => $csi . '38:2:26:36:33m',
            },
            'DARK KHAKI' => {
                'desc' => 'Dark khaki',
                'out'  => $csi . '38:2:189:183:107m',
            },
            'DARK LAVA' => {
                'desc' => 'Dark lava',
                'out'  => $csi . '38:2:72:60:50m',
            },
            'DARK LAVENDER' => {
                'desc' => 'Dark lavender',
                'out'  => $csi . '38:2:115:79:150m',
            },
            'DARK MAGENTA' => {
                'desc' => 'Dark magenta',
                'out'  => $csi . '38:2:139:0:139m',
            },
            'DARK MIDNIGHT BLUE' => {
                'desc' => 'Dark midnight blue',
                'out'  => $csi . '38:2:0:51:102m',
            },
            'DARK OLIVE GREEN' => {
                'desc' => 'Dark olive green',
                'out'  => $csi . '38:2:85:107:47m',
            },
            'DARK ORANGE' => {
                'desc' => 'Dark orange',
                'out'  => $csi . '38:2:255:140:0m',
            },
            'DARK ORCHID' => {
                'desc' => 'Dark orchid',
                'out'  => $csi . '38:2:153:50:204m',
            },
            'DARK PASTEL BLUE' => {
                'desc' => 'Dark pastel blue',
                'out'  => $csi . '38:2:119:158:203m',
            },
            'DARK PASTEL GREEN' => {
                'desc' => 'Dark pastel green',
                'out'  => $csi . '38:2:3:192:60m',
            },
            'DARK PASTEL PURPLE' => {
                'desc' => 'Dark pastel purple',
                'out'  => $csi . '38:2:150:111:214m',
            },
            'DARK PASTEL RED' => {
                'desc' => 'Dark pastel red',
                'out'  => $csi . '38:2:194:59:34m',
            },
            'DARK PINK' => {
                'desc' => 'Dark pink',
                'out'  => $csi . '38:2:231:84:128m',
            },
            'DARK POWDER BLUE' => {
                'desc' => 'Dark powder blue',
                'out'  => $csi . '38:2:0:51:153m',
            },
            'DARK RASPBERRY' => {
                'desc' => 'Dark raspberry',
                'out'  => $csi . '38:2:135:38:87m',
            },
            'DARK RED' => {
                'desc' => 'Dark red',
                'out'  => $csi . '38:2:139:0:0m',
            },
            'DARK SALMON' => {
                'desc' => 'Dark salmon',
                'out'  => $csi . '38:2:233:150:122m',
            },
            'DARK SCARLET' => {
                'desc' => 'Dark scarlet',
                'out'  => $csi . '38:2:86:3:25m',
            },
            'DARK SEA GREEN' => {
                'desc' => 'Dark sea green',
                'out'  => $csi . '38:2:143:188:143m',
            },
            'DARK SIENNA' => {
                'desc' => 'Dark sienna',
                'out'  => $csi . '38:2:60:20:20m',
            },
            'DARK SLATE BLUE' => {
                'desc' => 'Dark slate blue',
                'out'  => $csi . '38:2:72:61:139m',
            },
            'DARK SLATE GRAY' => {
                'desc' => 'Dark slate gray',
                'out'  => $csi . '38:2:47:79:79m',
            },
            'DARK SPRING GREEN' => {
                'desc' => 'Dark spring green',
                'out'  => $csi . '38:2:23:114:69m',
            },
            'DARK TAN' => {
                'desc' => 'Dark tan',
                'out'  => $csi . '38:2:145:129:81m',
            },
            'DARK TANGERINE' => {
                'desc' => 'Dark tangerine',
                'out'  => $csi . '38:2:255:168:18m',
            },
            'DARK TAUPE' => {
                'desc' => 'Dark taupe',
                'out'  => $csi . '38:2:72:60:50m',
            },
            'DARK TERRA COTTA' => {
                'desc' => 'Dark terra cotta',
                'out'  => $csi . '38:2:204:78:92m',
            },
            'DARK TURQUOISE' => {
                'desc' => 'Dark turquoise',
                'out'  => $csi . '38:2:0:206:209m',
            },
            'DARK VIOLET' => {
                'desc' => 'Dark violet',
                'out'  => $csi . '38:2:148:0:211m',
            },
            'DARTMOUTH GREEN' => {
                'desc' => 'Dartmouth green',
                'out'  => $csi . '38:2:0:105:62m',
            },
            'DAVY GRAY' => {
                'desc' => 'Davy grey',
                'out'  => $csi . '38:2:85:85:85m',
            },
            'DEBIAN RED' => {
                'desc' => 'Debian red',
                'out'  => $csi . '38:2:215:10:83m',
            },
            'DEEP CARMINE' => {
                'desc' => 'Deep carmine',
                'out'  => $csi . '38:2:169:32:62m',
            },
            'DEEP CARMINE PINK' => {
                'desc' => 'Deep carmine pink',
                'out'  => $csi . '38:2:239:48:56m',
            },
            'DEEP CARROT ORANGE' => {
                'desc' => 'Deep carrot orange',
                'out'  => $csi . '38:2:233:105:44m',
            },
            'DEEP CERISE' => {
                'desc' => 'Deep cerise',
                'out'  => $csi . '38:2:218:50:135m',
            },
            'DEEP CHAMPAGNE' => {
                'desc' => 'Deep champagne',
                'out'  => $csi . '38:2:250:214:165m',
            },
            'DEEP CHESTNUT' => {
                'desc' => 'Deep chestnut',
                'out'  => $csi . '38:2:185:78:72m',
            },
            'DEEP COFFEE' => {
                'desc' => 'Deep coffee',
                'out'  => $csi . '38:2:112:66:65m',
            },
            'DEEP FUCHSIA' => {
                'desc' => 'Deep fuchsia',
                'out'  => $csi . '38:2:193:84:193m',
            },
            'DEEP JUNGLE GREEN' => {
                'desc' => 'Deep jungle green',
                'out'  => $csi . '38:2:0:75:73m',
            },
            'DEEP LILAC' => {
                'desc' => 'Deep lilac',
                'out'  => $csi . '38:2:153:85:187m',
            },
            'DEEP MAGENTA' => {
                'desc' => 'Deep magenta',
                'out'  => $csi . '38:2:204:0:204m',
            },
            'DEEP PEACH' => {
                'desc' => 'Deep peach',
                'out'  => $csi . '38:2:255:203:164m',
            },
            'DEEP PINK' => {
                'desc' => 'Deep pink',
                'out'  => $csi . '38:2:255:20:147m',
            },
            'DEEP SAFFRON' => {
                'desc' => 'Deep saffron',
                'out'  => $csi . '38:2:255:153:51m',
            },
            'DEEP SKY BLUE' => {
                'desc' => 'Deep sky blue',
                'out'  => $csi . '38:2:0:191:255m',
            },
            'DENIM' => {
                'desc' => 'Denim',
                'out'  => $csi . '38:2:21:96:189m',
            },
            'DESERT' => {
                'desc' => 'Desert',
                'out'  => $csi . '38:2:193:154:107m',
            },
            'DESERT SAND' => {
                'desc' => 'Desert sand',
                'out'  => $csi . '38:2:237:201:175m',
            },
            'DIM GRAY' => {
                'desc' => 'Dim gray',
                'out'  => $csi . '38:2:105:105:105m',
            },
            'DODGER BLUE' => {
                'desc' => 'Dodger blue',
                'out'  => $csi . '38:2:30:144:255m',
            },
            'DOGWOOD ROSE' => {
                'desc' => 'Dogwood rose',
                'out'  => $csi . '38:2:215:24:104m',
            },
            'DOLLAR BILL' => {
                'desc' => 'Dollar bill',
                'out'  => $csi . '38:2:133:187:101m',
            },
            'DRAB' => {
                'desc' => 'Drab',
                'out'  => $csi . '38:2:150:113:23m',
            },
            'DUKE BLUE' => {
                'desc' => 'Duke blue',
                'out'  => $csi . '38:2:0:0:156m',
            },
            'EARTH YELLOW' => {
                'desc' => 'Earth yellow',
                'out'  => $csi . '38:2:225:169:95m',
            },
            'ECRU' => {
                'desc' => 'Ecru',
                'out'  => $csi . '38:2:194:178:128m',
            },
            'EGGPLANT' => {
                'desc' => 'Eggplant',
                'out'  => $csi . '38:2:97:64:81m',
            },
            'EGGSHELL' => {
                'desc' => 'Eggshell',
                'out'  => $csi . '38:2:240:234:214m',
            },
            'EGYPTIAN BLUE' => {
                'desc' => 'Egyptian blue',
                'out'  => $csi . '38:2:16:52:166m',
            },
            'ELECTRIC BLUE' => {
                'desc' => 'Electric blue',
                'out'  => $csi . '38:2:125:249:255m',
            },
            'ELECTRIC CRIMSON' => {
                'desc' => 'Electric crimson',
                'out'  => $csi . '38:2:255:0:63m',
            },
            'ELECTRIC CYAN' => {
                'desc' => 'Electric cyan',
                'out'  => $csi . '38:2:0:255:255m',
            },
            'ELECTRIC GREEN' => {
                'desc' => 'Electric green',
                'out'  => $csi . '38:2:0:255:0m',
            },
            'ELECTRIC INDIGO' => {
                'desc' => 'Electric indigo',
                'out'  => $csi . '38:2:111:0:255m',
            },
            'ELECTRIC LAVENDER' => {
                'desc' => 'Electric lavender',
                'out'  => $csi . '38:2:244:187:255m',
            },
            'ELECTRIC LIME' => {
                'desc' => 'Electric lime',
                'out'  => $csi . '38:2:204:255:0m',
            },
            'ELECTRIC PURPLE' => {
                'desc' => 'Electric purple',
                'out'  => $csi . '38:2:191:0:255m',
            },
            'ELECTRIC ULTRAMARINE' => {
                'desc' => 'Electric ultramarine',
                'out'  => $csi . '38:2:63:0:255m',
            },
            'ELECTRIC VIOLET' => {
                'desc' => 'Electric violet',
                'out'  => $csi . '38:2:143:0:255m',
            },
            'ELECTRIC YELLOW' => {
                'desc' => 'Electric yellow',
                'out'  => $csi . '38:2:255:255:0m',
            },
            'EMERALD' => {
                'desc' => 'Emerald',
                'out'  => $csi . '38:2:80:200:120m',
            },
            'ETON BLUE' => {
                'desc' => 'Eton blue',
                'out'  => $csi . '38:2:150:200:162m',
            },
            'FALLOW' => {
                'desc' => 'Fallow',
                'out'  => $csi . '38:2:193:154:107m',
            },
            'FALU RED' => {
                'desc' => 'Falu red',
                'out'  => $csi . '38:2:128:24:24m',
            },
            'FAMOUS' => {
                'desc' => 'Famous',
                'out'  => $csi . '38:2:255:0:255m',
            },
            'FANDANGO' => {
                'desc' => 'Fandango',
                'out'  => $csi . '38:2:181:51:137m',
            },
            'FASHION FUCHSIA' => {
                'desc' => 'Fashion fuchsia',
                'out'  => $csi . '38:2:244:0:161m',
            },
            'FAWN' => {
                'desc' => 'Fawn',
                'out'  => $csi . '38:2:229:170:112m',
            },
            'FELDGRAU' => {
                'desc' => 'Feldgrau',
                'out'  => $csi . '38:2:77:93:83m',
            },
            'FERN' => {
                'desc' => 'Fern',
                'out'  => $csi . '38:2:113:188:120m',
            },
            'FERN GREEN' => {
                'desc' => 'Fern green',
                'out'  => $csi . '38:2:79:121:66m',
            },
            'FERRARI RED' => {
                'desc' => 'Ferrari Red',
                'out'  => $csi . '38:2:255:40:0m',
            },
            'FIELD DRAB' => {
                'desc' => 'Field drab',
                'out'  => $csi . '38:2:108:84:30m',
            },
            'FIRE ENGINE RED' => {
                'desc' => 'Fire engine red',
                'out'  => $csi . '38:2:206:32:41m',
            },
            'FIREBRICK' => {
                'desc' => 'Firebrick',
                'out'  => $csi . '38:2:178:34:34m',
            },
            'FLAME' => {
                'desc' => 'Flame',
                'out'  => $csi . '38:2:226:88:34m',
            },
            'FLAMINGO PINK' => {
                'desc' => 'Flamingo pink',
                'out'  => $csi . '38:2:252:142:172m',
            },
            'FLAVESCENT' => {
                'desc' => 'Flavescent',
                'out'  => $csi . '38:2:247:233:142m',
            },
            'FLAX' => {
                'desc' => 'Flax',
                'out'  => $csi . '38:2:238:220:130m',
            },
            'FLORAL WHITE' => {
                'desc' => 'Floral white',
                'out'  => $csi . '38:2:255:250:240m',
            },
            'FLUORESCENT ORANGE' => {
                'desc' => 'Fluorescent orange',
                'out'  => $csi . '38:2:255:191:0m',
            },
            'FLUORESCENT PINK' => {
                'desc' => 'Fluorescent pink',
                'out'  => $csi . '38:2:255:20:147m',
            },
            'FLUORESCENT YELLOW' => {
                'desc' => 'Fluorescent yellow',
                'out'  => $csi . '38:2:204:255:0m',
            },
            'FOLLY' => {
                'desc' => 'Folly',
                'out'  => $csi . '38:2:255:0:79m',
            },
            'FOREST GREEN' => {
                'desc' => 'Forest green',
                'out'  => $csi . '38:2:34:139:34m',
            },
            'FRENCH BEIGE' => {
                'desc' => 'French beige',
                'out'  => $csi . '38:2:166:123:91m',
            },
            'FRENCH BLUE' => {
                'desc' => 'French blue',
                'out'  => $csi . '38:2:0:114:187m',
            },
            'FRENCH LILAC' => {
                'desc' => 'French lilac',
                'out'  => $csi . '38:2:134:96:142m',
            },
            'FRENCH ROSE' => {
                'desc' => 'French rose',
                'out'  => $csi . '38:2:246:74:138m',
            },
            'FUCHSIA' => {
                'desc' => 'Fuchsia',
                'out'  => $csi . '38:2:255:0:255m',
            },
            'FUCHSIA PINK' => {
                'desc' => 'Fuchsia pink',
                'out'  => $csi . '38:2:255:119:255m',
            },
            'FULVOUS' => {
                'desc' => 'Fulvous',
                'out'  => $csi . '38:2:228:132:0m',
            },
            'FUZZY WUZZY' => {
                'desc' => 'Fuzzy Wuzzy',
                'out'  => $csi . '38:2:204:102:102m',
            },
            'GAINSBORO' => {
                'desc' => 'Gainsboro',
                'out'  => $csi . '38:2:220:220:220m',
            },
            'GAMBOGE' => {
                'desc' => 'Gamboge',
                'out'  => $csi . '38:2:228:155:15m',
            },
            'GHOST WHITE' => {
                'desc' => 'Ghost white',
                'out'  => $csi . '38:2:248:248:255m',
            },
            'GINGER' => {
                'desc' => 'Ginger',
                'out'  => $csi . '38:2:176:101:0m',
            },
            'GLAUCOUS' => {
                'desc' => 'Glaucous',
                'out'  => $csi . '38:2:96:130:182m',
            },
            'GLITTER' => {
                'desc' => 'Glitter',
                'out'  => $csi . '38:2:230:232:250m',
            },
            'GOLD' => {
                'desc' => 'Gold',
                'out'  => $csi . '38:2:255:215:0m',
            },
            'GOLDEN BROWN' => {
                'desc' => 'Golden brown',
                'out'  => $csi . '38:2:153:101:21m',
            },
            'GOLDEN POPPY' => {
                'desc' => 'Golden poppy',
                'out'  => $csi . '38:2:252:194:0m',
            },
            'GOLDEN YELLOW' => {
                'desc' => 'Golden yellow',
                'out'  => $csi . '38:2:255:223:0m',
            },
            'GOLDENROD' => {
                'desc' => 'Goldenrod',
                'out'  => $csi . '38:2:218:165:32m',
            },
            'GRANNY SMITH APPLE' => {
                'desc' => 'Granny Smith Apple',
                'out'  => $csi . '38:2:168:228:160m',
            },
            'GRAY' => {
                'desc' => 'Gray',
                'out'  => $csi . '38:2:128:128:128m',
            },
            'GRAY ASPARAGUS' => {
                'desc' => 'Gray asparagus',
                'out'  => $csi . '38:2:70:89:69m',
            },
            'GREEN BLUE' => {
                'desc' => 'Green Blue',
                'out'  => $csi . '38:2:17:100:180m',
            },
            'GREEN YELLOW' => {
                'desc' => 'Green yellow',
                'out'  => $csi . '38:2:173:255:47m',
            },
            'GRULLO' => {
                'desc' => 'Grullo',
                'out'  => $csi . '38:2:169:154:134m',
            },
            'GUPPIE GREEN' => {
                'desc' => 'Guppie green',
                'out'  => $csi . '38:2:0:255:127m',
            },
            'HALAYA UBE' => {
                'desc' => 'Halaya ube',
                'out'  => $csi . '38:2:102:56:84m',
            },
            'HAN BLUE' => {
                'desc' => 'Han blue',
                'out'  => $csi . '38:2:68:108:207m',
            },
            'HAN PURPLE' => {
                'desc' => 'Han purple',
                'out'  => $csi . '38:2:82:24:250m',
            },
            'HANSA YELLOW' => {
                'desc' => 'Hansa yellow',
                'out'  => $csi . '38:2:233:214:107m',
            },
            'HARLEQUIN' => {
                'desc' => 'Harlequin',
                'out'  => $csi . '38:2:63:255:0m',
            },
            'HARVARD CRIMSON' => {
                'desc' => 'Harvard crimson',
                'out'  => $csi . '38:2:201:0:22m',
            },
            'HARVEST GOLD' => {
                'desc' => 'Harvest Gold',
                'out'  => $csi . '38:2:218:145:0m',
            },
            'HEART GOLD' => {
                'desc' => 'Heart Gold',
                'out'  => $csi . '38:2:128:128:0m',
            },
            'HELIOTROPE' => {
                'desc' => 'Heliotrope',
                'out'  => $csi . '38:2:223:115:255m',
            },
            'HOLLYWOOD CERISE' => {
                'desc' => 'Hollywood cerise',
                'out'  => $csi . '38:2:244:0:161m',
            },
            'HONEYDEW' => {
                'desc' => 'Honeydew',
                'out'  => $csi . '38:2:240:255:240m',
            },
            'HOOKER GREEN' => {
                'desc' => 'Hooker green',
                'out'  => $csi . '38:2:73:121:107m',
            },
            'HOT MAGENTA' => {
                'desc' => 'Hot magenta',
                'out'  => $csi . '38:2:255:29:206m',
            },
            'HOT PINK' => {
                'desc' => 'Hot pink',
                'out'  => $csi . '38:2:255:105:180m',
            },
            'HUNTER GREEN' => {
                'desc' => 'Hunter green',
                'out'  => $csi . '38:2:53:94:59m',
            },
            'ICTERINE' => {
                'desc' => 'Icterine',
                'out'  => $csi . '38:2:252:247:94m',
            },
            'INCHWORM' => {
                'desc' => 'Inchworm',
                'out'  => $csi . '38:2:178:236:93m',
            },
            'INDIA GREEN' => {
                'desc' => 'India green',
                'out'  => $csi . '38:2:19:136:8m',
            },
            'INDIAN RED' => {
                'desc' => 'Indian red',
                'out'  => $csi . '38:2:205:92:92m',
            },
            'INDIAN YELLOW' => {
                'desc' => 'Indian yellow',
                'out'  => $csi . '38:2:227:168:87m',
            },
            'INDIGO' => {
                'desc' => 'Indigo',
                'out'  => $csi . '38:2:75:0:130m',
            },
            'INTERNATIONAL KLEIN' => {
                'desc' => 'International Klein',
                'out'  => $csi . '38:2:0:47:167m',
            },
            'INTERNATIONAL ORANGE' => {
                'desc' => 'International orange',
                'out'  => $csi . '38:2:255:79:0m',
            },
            'IRIS' => {
                'desc' => 'Iris',
                'out'  => $csi . '38:2:90:79:207m',
            },
            'ISABELLINE' => {
                'desc' => 'Isabelline',
                'out'  => $csi . '38:2:244:240:236m',
            },
            'ISLAMIC GREEN' => {
                'desc' => 'Islamic green',
                'out'  => $csi . '38:2:0:144:0m',
            },
            'IVORY' => {
                'desc' => 'Ivory',
                'out'  => $csi . '38:2:255:255:240m',
            },
            'JADE' => {
                'desc' => 'Jade',
                'out'  => $csi . '38:2:0:168:107m',
            },
            'JASMINE' => {
                'desc' => 'Jasmine',
                'out'  => $csi . '38:2:248:222:126m',
            },
            'JASPER' => {
                'desc' => 'Jasper',
                'out'  => $csi . '38:2:215:59:62m',
            },
            'JAZZBERRY JAM' => {
                'desc' => 'Jazzberry jam',
                'out'  => $csi . '38:2:165:11:94m',
            },
            'JONQUIL' => {
                'desc' => 'Jonquil',
                'out'  => $csi . '38:2:250:218:94m',
            },
            'JUNE BUD' => {
                'desc' => 'June bud',
                'out'  => $csi . '38:2:189:218:87m',
            },
            'JUNGLE GREEN' => {
                'desc' => 'Jungle green',
                'out'  => $csi . '38:2:41:171:135m',
            },
            'KELLY GREEN' => {
                'desc' => 'Kelly green',
                'out'  => $csi . '38:2:76:187:23m',
            },
            'KHAKI' => {
                'desc' => 'Khaki',
                'out'  => $csi . '38:2:195:176:145m',
            },
            'KU CRIMSON' => {
                'desc' => 'KU Crimson',
                'out'  => $csi . '38:2:232:0:13m',
            },
            'LA SALLE GREEN' => {
                'desc' => 'La Salle Green',
                'out'  => $csi . '38:2:8:120:48m',
            },
            'LANGUID LAVENDER' => {
                'desc' => 'Languid lavender',
                'out'  => $csi . '38:2:214:202:221m',
            },
            'LAPIS LAZULI' => {
                'desc' => 'Lapis lazuli',
                'out'  => $csi . '38:2:38:97:156m',
            },
            'LASER LEMON' => {
                'desc' => 'Laser Lemon',
                'out'  => $csi . '38:2:254:254:34m',
            },
            'LAUREL GREEN' => {
                'desc' => 'Laurel green',
                'out'  => $csi . '38:2:169:186:157m',
            },
            'LAVA' => {
                'desc' => 'Lava',
                'out'  => $csi . '38:2:207:16:32m',
            },
            'LAVENDER' => {
                'desc' => 'Lavender',
                'out'  => $csi . '38:2:230:230:250m',
            },
            'LAVENDER BLUE' => {
                'desc' => 'Lavender blue',
                'out'  => $csi . '38:2:204:204:255m',
            },
            'LAVENDER BLUSH' => {
                'desc' => 'Lavender blush',
                'out'  => $csi . '38:2:255:240:245m',
            },
            'LAVENDER GRAY' => {
                'desc' => 'Lavender gray',
                'out'  => $csi . '38:2:196:195:208m',
            },
            'LAVENDER INDIGO' => {
                'desc' => 'Lavender indigo',
                'out'  => $csi . '38:2:148:87:235m',
            },
            'LAVENDER MAGENTA' => {
                'desc' => 'Lavender magenta',
                'out'  => $csi . '38:2:238:130:238m',
            },
            'LAVENDER MIST' => {
                'desc' => 'Lavender mist',
                'out'  => $csi . '38:2:230:230:250m',
            },
            'LAVENDER PINK' => {
                'desc' => 'Lavender pink',
                'out'  => $csi . '38:2:251:174:210m',
            },
            'LAVENDER PURPLE' => {
                'desc' => 'Lavender purple',
                'out'  => $csi . '38:2:150:123:182m',
            },
            'LAVENDER ROSE' => {
                'desc' => 'Lavender rose',
                'out'  => $csi . '38:2:251:160:227m',
            },
            'LAWN GREEN' => {
                'desc' => 'Lawn green',
                'out'  => $csi . '38:2:124:252:0m',
            },
            'LEMON' => {
                'desc' => 'Lemon',
                'out'  => $csi . '38:2:255:247:0m',
            },
            'LEMON CHIFFON' => {
                'desc' => 'Lemon chiffon',
                'out'  => $csi . '38:2:255:250:205m',
            },
            'LEMON LIME' => {
                'desc' => 'Lemon lime',
                'out'  => $csi . '38:2:191:255:0m',
            },
            'LEMON YELLOW' => {
                'desc' => 'Lemon Yellow',
                'out'  => $csi . '38:2:255:244:79m',
            },
            'LIGHT APRICOT' => {
                'desc' => 'Light apricot',
                'out'  => $csi . '38:2:253:213:177m',
            },
            'LIGHT BLUE' => {
                'desc' => 'Light blue',
                'out'  => $csi . '38:2:173:216:230m',
            },
            'LIGHT BROWN' => {
                'desc' => 'Light brown',
                'out'  => $csi . '38:2:181:101:29m',
            },
            'LIGHT CARMINE PINK' => {
                'desc' => 'Light carmine pink',
                'out'  => $csi . '38:2:230:103:113m',
            },
            'LIGHT CORAL' => {
                'desc' => 'Light coral',
                'out'  => $csi . '38:2:240:128:128m',
            },
            'LIGHT CORNFLOWER BLUE' => {
                'desc' => 'Light cornflower blue',
                'out'  => $csi . '38:2:147:204:234m',
            },
            'LIGHT CRIMSON' => {
                'desc' => 'Light Crimson',
                'out'  => $csi . '38:2:245:105:145m',
            },
            'LIGHT CYAN' => {
                'desc' => 'Light cyan',
                'out'  => $csi . '38:2:224:255:255m',
            },
            'LIGHT FUCHSIA PINK' => {
                'desc' => 'Light fuchsia pink',
                'out'  => $csi . '38:2:249:132:239m',
            },
            'LIGHT GOLDENROD YELLOW' => {
                'desc' => 'Light goldenrod yellow',
                'out'  => $csi . '38:2:250:250:210m',
            },
            'LIGHT GRAY' => {
                'desc' => 'Light gray',
                'out'  => $csi . '38:2:211:211:211m',
            },
            'LIGHT GREEN' => {
                'desc' => 'Light green',
                'out'  => $csi . '38:2:144:238:144m',
            },
            'LIGHT KHAKI' => {
                'desc' => 'Light khaki',
                'out'  => $csi . '38:2:240:230:140m',
            },
            'LIGHT PASTEL PURPLE' => {
                'desc' => 'Light pastel purple',
                'out'  => $csi . '38:2:177:156:217m',
            },
            'LIGHT PINK' => {
                'desc' => 'Light pink',
                'out'  => $csi . '38:2:255:182:193m',
            },
            'LIGHT SALMON' => {
                'desc' => 'Light salmon',
                'out'  => $csi . '38:2:255:160:122m',
            },
            'LIGHT SALMON PINK' => {
                'desc' => 'Light salmon pink',
                'out'  => $csi . '38:2:255:153:153m',
            },
            'LIGHT SEA GREEN' => {
                'desc' => 'Light sea green',
                'out'  => $csi . '38:2:32:178:170m',
            },
            'LIGHT SKY BLUE' => {
                'desc' => 'Light sky blue',
                'out'  => $csi . '38:2:135:206:250m',
            },
            'LIGHT SLATE GRAY' => {
                'desc' => 'Light slate gray',
                'out'  => $csi . '38:2:119:136:153m',
            },
            'LIGHT TAUPE' => {
                'desc' => 'Light taupe',
                'out'  => $csi . '38:2:179:139:109m',
            },
            'LIGHT THULIAN PINK' => {
                'desc' => 'Light Thulian pink',
                'out'  => $csi . '38:2:230:143:172m',
            },
            'LIGHT YELLOW' => {
                'desc' => 'Light yellow',
                'out'  => $csi . '38:2:255:255:237m',
            },
            'LILAC' => {
                'desc' => 'Lilac',
                'out'  => $csi . '38:2:200:162:200m',
            },
            'LIME' => {
                'desc' => 'Lime',
                'out'  => $csi . '38:2:191:255:0m',
            },
            'LIME GREEN' => {
                'desc' => 'Lime green',
                'out'  => $csi . '38:2:50:205:50m',
            },
            'LINCOLN GREEN' => {
                'desc' => 'Lincoln green',
                'out'  => $csi . '38:2:25:89:5m',
            },
            'LINEN' => {
                'desc' => 'Linen',
                'out'  => $csi . '38:2:250:240:230m',
            },
            'LION' => {
                'desc' => 'Lion',
                'out'  => $csi . '38:2:193:154:107m',
            },
            'LIVER' => {
                'desc' => 'Liver',
                'out'  => $csi . '38:2:83:75:79m',
            },
            'LUST' => {
                'desc' => 'Lust',
                'out'  => $csi . '38:2:230:32:32m',
            },
            'MACARONI AND CHEESE' => {
                'desc' => 'Macaroni and Cheese',
                'out'  => $csi . '38:2:255:189:136m',
            },
            'MAGIC MINT' => {
                'desc' => 'Magic mint',
                'out'  => $csi . '38:2:170:240:209m',
            },
            'MAGNOLIA' => {
                'desc' => 'Magnolia',
                'out'  => $csi . '38:2:248:244:255m',
            },
            'MAHOGANY' => {
                'desc' => 'Mahogany',
                'out'  => $csi . '38:2:192:64:0m',
            },
            'MAIZE' => {
                'desc' => 'Maize',
                'out'  => $csi . '38:2:251:236:93m',
            },
            'MAJORELLE BLUE' => {
                'desc' => 'Majorelle Blue',
                'out'  => $csi . '38:2:96:80:220m',
            },
            'MALACHITE' => {
                'desc' => 'Malachite',
                'out'  => $csi . '38:2:11:218:81m',
            },
            'MANATEE' => {
                'desc' => 'Manatee',
                'out'  => $csi . '38:2:151:154:170m',
            },
            'MANGO TANGO' => {
                'desc' => 'Mango Tango',
                'out'  => $csi . '38:2:255:130:67m',
            },
            'MANTIS' => {
                'desc' => 'Mantis',
                'out'  => $csi . '38:2:116:195:101m',
            },
            'MAROON' => {
                'desc' => 'Maroon',
                'out'  => $csi . '38:2:128:0:0m',
            },
            'MAUVE' => {
                'desc' => 'Mauve',
                'out'  => $csi . '38:2:224:176:255m',
            },
            'MAUVE TAUPE' => {
                'desc' => 'Mauve taupe',
                'out'  => $csi . '38:2:145:95:109m',
            },
            'MAUVELOUS' => {
                'desc' => 'Mauvelous',
                'out'  => $csi . '38:2:239:152:170m',
            },
            'MAYA BLUE' => {
                'desc' => 'Maya blue',
                'out'  => $csi . '38:2:115:194:251m',
            },
            'MEAT BROWN' => {
                'desc' => 'Meat brown',
                'out'  => $csi . '38:2:229:183:59m',
            },
            'MEDIUM AQUAMARINE' => {
                'desc' => 'Medium aquamarine',
                'out'  => $csi . '38:2:102:221:170m',
            },
            'MEDIUM BLUE' => {
                'desc' => 'Medium blue',
                'out'  => $csi . '38:2:0:0:205m',
            },
            'MEDIUM CANDY APPLE RED' => {
                'desc' => 'Medium candy apple red',
                'out'  => $csi . '38:2:226:6:44m',
            },
            'MEDIUM CARMINE' => {
                'desc' => 'Medium carmine',
                'out'  => $csi . '38:2:175:64:53m',
            },
            'MEDIUM CHAMPAGNE' => {
                'desc' => 'Medium champagne',
                'out'  => $csi . '38:2:243:229:171m',
            },
            'MEDIUM ELECTRIC BLUE' => {
                'desc' => 'Medium electric blue',
                'out'  => $csi . '38:2:3:80:150m',
            },
            'MEDIUM JUNGLE GREEN' => {
                'desc' => 'Medium jungle green',
                'out'  => $csi . '38:2:28:53:45m',
            },
            'MEDIUM LAVENDER MAGENTA' => {
                'desc' => 'Medium lavender magenta',
                'out'  => $csi . '38:2:221:160:221m',
            },
            'MEDIUM ORCHID' => {
                'desc' => 'Medium orchid',
                'out'  => $csi . '38:2:186:85:211m',
            },
            'MEDIUM PERSIAN BLUE' => {
                'desc' => 'Medium Persian blue',
                'out'  => $csi . '38:2:0:103:165m',
            },
            'MEDIUM PURPLE' => {
                'desc' => 'Medium purple',
                'out'  => $csi . '38:2:147:112:219m',
            },
            'MEDIUM RED VIOLET' => {
                'desc' => 'Medium red violet',
                'out'  => $csi . '38:2:187:51:133m',
            },
            'MEDIUM SEA GREEN' => {
                'desc' => 'Medium sea green',
                'out'  => $csi . '38:2:60:179:113m',
            },
            'MEDIUM SLATE BLUE' => {
                'desc' => 'Medium slate blue',
                'out'  => $csi . '38:2:123:104:238m',
            },
            'MEDIUM SPRING BUD' => {
                'desc' => 'Medium spring bud',
                'out'  => $csi . '38:2:201:220:135m',
            },
            'MEDIUM SPRING GREEN' => {
                'desc' => 'Medium spring green',
                'out'  => $csi . '38:2:0:250:154m',
            },
            'MEDIUM TAUPE' => {
                'desc' => 'Medium taupe',
                'out'  => $csi . '38:2:103:76:71m',
            },
            'MEDIUM TEAL BLUE' => {
                'desc' => 'Medium teal blue',
                'out'  => $csi . '38:2:0:84:180m',
            },
            'MEDIUM TURQUOISE' => {
                'desc' => 'Medium turquoise',
                'out'  => $csi . '38:2:72:209:204m',
            },
            'MEDIUM VIOLET RED' => {
                'desc' => 'Medium violet red',
                'out'  => $csi . '38:2:199:21:133m',
            },
            'MELON' => {
                'desc' => 'Melon',
                'out'  => $csi . '38:2:253:188:180m',
            },
            'MIDNIGHT BLUE' => {
                'desc' => 'Midnight blue',
                'out'  => $csi . '38:2:25:25:112m',
            },
            'MIDNIGHT GREEN' => {
                'desc' => 'Midnight green',
                'out'  => $csi . '38:2:0:73:83m',
            },
            'MIKADO YELLOW' => {
                'desc' => 'Mikado yellow',
                'out'  => $csi . '38:2:255:196:12m',
            },
            'MINT' => {
                'desc' => 'Mint',
                'out'  => $csi . '38:2:62:180:137m',
            },
            'MINT CREAM' => {
                'desc' => 'Mint cream',
                'out'  => $csi . '38:2:245:255:250m',
            },
            'MINT GREEN' => {
                'desc' => 'Mint green',
                'out'  => $csi . '38:2:152:255:152m',
            },
            'MISTY ROSE' => {
                'desc' => 'Misty rose',
                'out'  => $csi . '38:2:255:228:225m',
            },
            'MOCCASIN' => {
                'desc' => 'Moccasin',
                'out'  => $csi . '38:2:250:235:215m',
            },
            'MODE BEIGE' => {
                'desc' => 'Mode beige',
                'out'  => $csi . '38:2:150:113:23m',
            },
            'MOONSTONE BLUE' => {
                'desc' => 'Moonstone blue',
                'out'  => $csi . '38:2:115:169:194m',
            },
            'MORDANT RED 19' => {
                'desc' => 'Mordant red 19',
                'out'  => $csi . '38:2:174:12:0m',
            },
            'MOSS GREEN' => {
                'desc' => 'Moss green',
                'out'  => $csi . '38:2:173:223:173m',
            },
            'MOUNTAIN MEADOW' => {
                'desc' => 'Mountain Meadow',
                'out'  => $csi . '38:2:48:186:143m',
            },
            'MOUNTBATTEN PINK' => {
                'desc' => 'Mountbatten pink',
                'out'  => $csi . '38:2:153:122:141m',
            },
            'MSU GREEN' => {
                'desc' => 'MSU Green',
                'out'  => $csi . '38:2:24:69:59m',
            },
            'MULBERRY' => {
                'desc' => 'Mulberry',
                'out'  => $csi . '38:2:197:75:140m',
            },
            'MUNSELL' => {
                'desc' => 'Munsell',
                'out'  => $csi . '38:2:242:243:244m',
            },
            'MUSTARD' => {
                'desc' => 'Mustard',
                'out'  => $csi . '38:2:255:219:88m',
            },
            'MYRTLE' => {
                'desc' => 'Myrtle',
                'out'  => $csi . '38:2:33:66:30m',
            },
            'NADESHIKO PINK' => {
                'desc' => 'Nadeshiko pink',
                'out'  => $csi . '38:2:246:173:198m',
            },
            'NAPIER GREEN' => {
                'desc' => 'Napier green',
                'out'  => $csi . '38:2:42:128:0m',
            },
            'NAPLES YELLOW' => {
                'desc' => 'Naples yellow',
                'out'  => $csi . '38:2:250:218:94m',
            },
            'NAVAJO WHITE' => {
                'desc' => 'Navajo white',
                'out'  => $csi . '38:2:255:222:173m',
            },
            'NAVY BLUE' => {
                'desc' => 'Navy blue',
                'out'  => $csi . '38:2:0:0:128m',
            },
            'NEON CARROT' => {
                'desc' => 'Neon Carrot',
                'out'  => $csi . '38:2:255:163:67m',
            },
            'NEON FUCHSIA' => {
                'desc' => 'Neon fuchsia',
                'out'  => $csi . '38:2:254:89:194m',
            },
            'NEON GREEN' => {
                'desc' => 'Neon green',
                'out'  => $csi . '38:2:57:255:20m',
            },
            'NON-PHOTO BLUE' => {
                'desc' => 'Non-photo blue',
                'out'  => $csi . '38:2:164:221:237m',
            },
            'NORTH TEXAS GREEN' => {
                'desc' => 'North Texas Green',
                'out'  => $csi . '38:2:5:144:51m',
            },
            'OCEAN BOAT BLUE' => {
                'desc' => 'Ocean Boat Blue',
                'out'  => $csi . '38:2:0:119:190m',
            },
            'OCHRE' => {
                'desc' => 'Ochre',

                'out' => $csi . '38:2:204:119:34m',
            },
            'OFFICE GREEN' => {
                'desc' => 'Office green',

                'out' => $csi . '38:2:0:128:0m',
            },
            'OLD GOLD' => {
                'desc' => 'Old gold',

                'out' => $csi . '38:2:207:181:59m',
            },
            'OLD LACE' => {
                'desc' => 'Old lace',

                'out' => $csi . '38:2:253:245:230m',
            },
            'OLD LAVENDER' => {
                'desc' => 'Old lavender',

                'out' => $csi . '38:2:121:104:120m',
            },
            'OLD MAUVE' => {
                'desc' => 'Old mauve',

                'out' => $csi . '38:2:103:49:71m',
            },
            'OLD ROSE' => {
                'desc' => 'Old rose',

                'out' => $csi . '38:2:192:128:129m',
            },
            'OLIVE' => {
                'desc' => 'Olive',

                'out' => $csi . '38:2:128:128:0m',
            },
            'OLIVE DRAB' => {
                'desc' => 'Olive Drab',

                'out' => $csi . '38:2:107:142:35m',
            },
            'OLIVE GREEN' => {
                'desc' => 'Olive Green',

                'out' => $csi . '38:2:186:184:108m',
            },
            'OLIVINE' => {
                'desc' => 'Olivine',

                'out' => $csi . '38:2:154:185:115m',
            },
            'ONYX' => {
                'desc' => 'Onyx',

                'out' => $csi . '38:2:15:15:15m',
            },
            'OPERA MAUVE' => {
                'desc' => 'Opera mauve',

                'out' => $csi . '38:2:183:132:167m',
            },
            'ORANGE PEEL' => {
                'desc' => 'Orange peel',

                'out' => $csi . '38:2:255:159:0m',
            },
            'ORANGE RED' => {
                'desc' => 'Orange red',

                'out' => $csi . '38:2:255:69:0m',
            },
            'ORANGE YELLOW' => {
                'desc' => 'Orange Yellow',

                'out' => $csi . '38:2:248:213:104m',
            },
            'ORCHID' => {
                'desc' => 'Orchid',

                'out' => $csi . '38:2:218:112:214m',
            },
            'OTTER BROWN' => {
                'desc' => 'Otter brown',

                'out' => $csi . '38:2:101:67:33m',
            },
            'OUTER SPACE' => {
                'desc' => 'Outer Space',

                'out' => $csi . '38:2:65:74:76m',
            },
            'OUTRAGEOUS ORANGE' => {
                'desc' => 'Outrageous Orange',

                'out' => $csi . '38:2:255:110:74m',
            },
            'OXFORD BLUE' => {
                'desc' => 'Oxford Blue',

                'out' => $csi . '38:2:0:33:71m',
            },
            'PACIFIC BLUE' => {
                'desc' => 'Pacific Blue',

                'out' => $csi . '38:2:28:169:201m',
            },
            'PAKISTAN GREEN' => {
                'desc' => 'Pakistan green',

                'out' => $csi . '38:2:0:102:0m',
            },
            'PALATINATE BLUE' => {
                'desc' => 'Palatinate blue',

                'out' => $csi . '38:2:39:59:226m',
            },
            'PALATINATE PURPLE' => {
                'desc' => 'Palatinate purple',

                'out' => $csi . '38:2:104:40:96m',
            },
            'PALE AQUA' => {
                'desc' => 'Pale aqua',

                'out' => $csi . '38:2:188:212:230m',
            },
            'PALE BLUE' => {
                'desc' => 'Pale blue',

                'out' => $csi . '38:2:175:238:238m',
            },
            'PALE BROWN' => {
                'desc' => 'Pale brown',

                'out' => $csi . '38:2:152:118:84m',
            },
            'PALE CARMINE' => {
                'desc' => 'Pale carmine',

                'out' => $csi . '38:2:175:64:53m',
            },
            'PALE CERULEAN' => {
                'desc' => 'Pale cerulean',

                'out' => $csi . '38:2:155:196:226m',
            },
            'PALE CHESTNUT' => {
                'desc' => 'Pale chestnut',

                'out' => $csi . '38:2:221:173:175m',
            },
            'PALE COPPER' => {
                'desc' => 'Pale copper',

                'out' => $csi . '38:2:218:138:103m',
            },
            'PALE CORNFLOWER BLUE' => {
                'desc' => 'Pale cornflower blue',

                'out' => $csi . '38:2:171:205:239m',
            },
            'PALE GOLD' => {
                'desc' => 'Pale gold',

                'out' => $csi . '38:2:230:190:138m',
            },
            'PALE GOLDENROD' => {
                'desc' => 'Pale goldenrod',

                'out' => $csi . '38:2:238:232:170m',
            },
            'PALE GREEN' => {
                'desc' => 'Pale green',

                'out' => $csi . '38:2:152:251:152m',
            },
            'PALE LAVENDER' => {
                'desc' => 'Pale lavender',

                'out' => $csi . '38:2:220:208:255m',
            },
            'PALE MAGENTA' => {
                'desc' => 'Pale magenta',

                'out' => $csi . '38:2:249:132:229m',
            },
            'PALE PINK' => {
                'desc' => 'Pale pink',

                'out' => $csi . '38:2:250:218:221m',
            },
            'PALE PLUM' => {
                'desc' => 'Pale plum',

                'out' => $csi . '38:2:221:160:221m',
            },
            'PALE RED VIOLET' => {
                'desc' => 'Pale red violet',

                'out' => $csi . '38:2:219:112:147m',
            },
            'PALE ROBIN EGG BLUE' => {
                'desc' => 'Pale robin egg blue',

                'out' => $csi . '38:2:150:222:209m',
            },
            'PALE SILVER' => {
                'desc' => 'Pale silver',

                'out' => $csi . '38:2:201:192:187m',
            },
            'PALE SPRING BUD' => {
                'desc' => 'Pale spring bud',

                'out' => $csi . '38:2:236:235:189m',
            },
            'PALE TAUPE' => {
                'desc' => 'Pale taupe',

                'out' => $csi . '38:2:188:152:126m',
            },
            'PALE VIOLET RED' => {
                'desc' => 'Pale violet red',

                'out' => $csi . '38:2:219:112:147m',
            },
            'PANSY PURPLE' => {
                'desc' => 'Pansy purple',

                'out' => $csi . '38:2:120:24:74m',
            },
            'PAPAYA WHIP' => {
                'desc' => 'Papaya whip',

                'out' => $csi . '38:2:255:239:213m',
            },
            'PARIS GREEN' => {
                'desc' => 'Paris Green',

                'out' => $csi . '38:2:80:200:120m',
            },
            'PASTEL BLUE' => {
                'desc' => 'Pastel blue',

                'out' => $csi . '38:2:174:198:207m',
            },
            'PASTEL BROWN' => {
                'desc' => 'Pastel brown',

                'out' => $csi . '38:2:131:105:83m',
            },
            'PASTEL GRAY' => {
                'desc' => 'Pastel gray',

                'out' => $csi . '38:2:207:207:196m',
            },
            'PASTEL GREEN' => {
                'desc' => 'Pastel green',

                'out' => $csi . '38:2:119:221:119m',
            },
            'PASTEL MAGENTA' => {
                'desc' => 'Pastel magenta',

                'out' => $csi . '38:2:244:154:194m',
            },
            'PASTEL ORANGE' => {
                'desc' => 'Pastel orange',

                'out' => $csi . '38:2:255:179:71m',
            },
            'PASTEL PINK' => {
                'desc' => 'Pastel pink',

                'out' => $csi . '38:2:255:209:220m',
            },
            'PASTEL PURPLE' => {
                'desc' => 'Pastel purple',

                'out' => $csi . '38:2:179:158:181m',
            },
            'PASTEL RED' => {
                'desc' => 'Pastel red',

                'out' => $csi . '38:2:255:105:97m',
            },
            'PASTEL VIOLET' => {
                'desc' => 'Pastel violet',

                'out' => $csi . '38:2:203:153:201m',
            },
            'PASTEL YELLOW' => {
                'desc' => 'Pastel yellow',

                'out' => $csi . '38:2:253:253:150m',
            },
            'PATRIARCH' => {
                'desc' => 'Patriarch',

                'out' => $csi . '38:2:128:0:128m',
            },
            'PAYNE GRAY' => {
                'desc' => 'Payne grey',

                'out' => $csi . '38:2:83:104:120m',
            },
            'PEACH' => {
                'desc' => 'Peach',

                'out' => $csi . '38:2:255:229:180m',
            },
            'PEACH PUFF' => {
                'desc' => 'Peach puff',

                'out' => $csi . '38:2:255:218:185m',
            },
            'PEACH YELLOW' => {
                'desc' => 'Peach yellow',

                'out' => $csi . '38:2:250:223:173m',
            },
            'PEAR' => {
                'desc' => 'Pear',

                'out' => $csi . '38:2:209:226:49m',
            },
            'PEARL' => {
                'desc' => 'Pearl',

                'out' => $csi . '38:2:234:224:200m',
            },
            'PEARL AQUA' => {
                'desc' => 'Pearl Aqua',

                'out' => $csi . '38:2:136:216:192m',
            },
            'PERIDOT' => {
                'desc' => 'Peridot',

                'out' => $csi . '38:2:230:226:0m',
            },
            'PERIWINKLE' => {
                'desc' => 'Periwinkle',

                'out' => $csi . '38:2:204:204:255m',
            },
            'PERSIAN BLUE' => {
                'desc' => 'Persian blue',

                'out' => $csi . '38:2:28:57:187m',
            },
            'PERSIAN INDIGO' => {
                'desc' => 'Persian indigo',

                'out' => $csi . '38:2:50:18:122m',
            },
            'PERSIAN ORANGE' => {
                'desc' => 'Persian orange',

                'out' => $csi . '38:2:217:144:88m',
            },
            'PERSIAN PINK' => {
                'desc' => 'Persian pink',

                'out' => $csi . '38:2:247:127:190m',
            },
            'PERSIAN PLUM' => {
                'desc' => 'Persian plum',

                'out' => $csi . '38:2:112:28:28m',
            },
            'PERSIAN RED' => {
                'desc' => 'Persian red',

                'out' => $csi . '38:2:204:51:51m',
            },
            'PERSIAN ROSE' => {
                'desc' => 'Persian rose',

                'out' => $csi . '38:2:254:40:162m',
            },
            'PHLOX' => {
                'desc' => 'Phlox',

                'out' => $csi . '38:2:223:0:255m',
            },
            'PHTHALO BLUE' => {
                'desc' => 'Phthalo blue',

                'out' => $csi . '38:2:0:15:137m',
            },
            'PHTHALO GREEN' => {
                'desc' => 'Phthalo green',

                'out' => $csi . '38:2:18:53:36m',
            },
            'PIGGY PINK' => {
                'desc' => 'Piggy pink',

                'out' => $csi . '38:2:253:221:230m',
            },
            'PINE GREEN' => {
                'desc' => 'Pine green',

                'out' => $csi . '38:2:1:121:111m',
            },
            'PINK FLAMINGO' => {
                'desc' => 'Pink Flamingo',

                'out' => $csi . '38:2:252:116:253m',
            },
            'PINK PEARL' => {
                'desc' => 'Pink pearl',

                'out' => $csi . '38:2:231:172:207m',
            },
            'PINK SHERBET' => {
                'desc' => 'Pink Sherbet',

                'out' => $csi . '38:2:247:143:167m',
            },
            'PISTACHIO' => {
                'desc' => 'Pistachio',

                'out' => $csi . '38:2:147:197:114m',
            },
            'PLATINUM' => {
                'desc' => 'Platinum',

                'out' => $csi . '38:2:229:228:226m',
            },
            'PLUM' => {
                'desc' => 'Plum',

                'out' => $csi . '38:2:221:160:221m',
            },
            'PORTLAND ORANGE' => {
                'desc' => 'Portland Orange',

                'out' => $csi . '38:2:255:90:54m',
            },
            'POWDER BLUE' => {
                'desc' => 'Powder blue',

                'out' => $csi . '38:2:176:224:230m',
            },
            'PRINCETON ORANGE' => {
                'desc' => 'Princeton orange',

                'out' => $csi . '38:2:255:143:0m',
            },
            'PRUSSIAN BLUE' => {
                'desc' => 'Prussian blue',

                'out' => $csi . '38:2:0:49:83m',
            },
            'PSYCHEDELIC PURPLE' => {
                'desc' => 'Psychedelic purple',

                'out' => $csi . '38:2:223:0:255m',
            },
            'PUCE' => {
                'desc' => 'Puce',

                'out' => $csi . '38:2:204:136:153m',
            },
            'PUMPKIN' => {
                'desc' => 'Pumpkin',

                'out' => $csi . '38:2:255:117:24m',
            },
            'PURPLE' => {
                'desc' => 'Purple',

                'out' => $csi . '38:2:128:0:128m',
            },
            'PURPLE HEART' => {
                'desc' => 'Purple Heart',

                'out' => $csi . '38:2:105:53:156m',
            },
            'PURPLE MOUNTAIN MAJESTY' => {
                'desc' => 'Purple mountain majesty',

                'out' => $csi . '38:2:150:120:182m',
            },
            'PURPLE MOUNTAINS' => {
                'desc' => 'Purple Mountains',

                'out' => $csi . '38:2:157:129:186m',
            },
            'PURPLE PIZZAZZ' => {
                'desc' => 'Purple pizzazz',

                'out' => $csi . '38:2:254:78:218m',
            },
            'PURPLE TAUPE' => {
                'desc' => 'Purple taupe',

                'out' => $csi . '38:2:80:64:77m',
            },
            'RACKLEY' => {
                'desc' => 'Rackley',

                'out' => $csi . '38:2:93:138:168m',
            },
            'RADICAL RED' => {
                'desc' => 'Radical Red',

                'out' => $csi . '38:2:255:53:94m',
            },
            'RASPBERRY' => {
                'desc' => 'Raspberry',

                'out' => $csi . '38:2:227:11:93m',
            },
            'RASPBERRY GLACE' => {
                'desc' => 'Raspberry glace',

                'out' => $csi . '38:2:145:95:109m',
            },
            'RASPBERRY PINK' => {
                'desc' => 'Raspberry pink',

                'out' => $csi . '38:2:226:80:152m',
            },
            'RASPBERRY ROSE' => {
                'desc' => 'Raspberry rose',

                'out' => $csi . '38:2:179:68:108m',
            },
            'RAW SIENNA' => {
                'desc' => 'Raw Sienna',

                'out' => $csi . '38:2:214:138:89m',
            },
            'RAZZLE DAZZLE ROSE' => {
                'desc' => 'Razzle dazzle rose',

                'out' => $csi . '38:2:255:51:204m',
            },
            'RAZZMATAZZ' => {
                'desc' => 'Razzmatazz',

                'out' => $csi . '38:2:227:37:107m',
            },
            'RED BROWN' => {
                'desc' => 'Red brown',

                'out' => $csi . '38:2:165:42:42m',
            },
            'RED ORANGE' => {
                'desc' => 'Red Orange',

                'out' => $csi . '38:2:255:83:73m',
            },
            'RED VIOLET' => {
                'desc' => 'Red violet',

                'out' => $csi . '38:2:199:21:133m',
            },
            'RICH BLACK' => {
                'desc' => 'Rich black',

                'out' => $csi . '38:2:0:64:64m',
            },
            'RICH CARMINE' => {
                'desc' => 'Rich carmine',

                'out' => $csi . '38:2:215:0:64m',
            },
            'RICH ELECTRIC BLUE' => {
                'desc' => 'Rich electric blue',

                'out' => $csi . '38:2:8:146:208m',
            },
            'RICH LILAC' => {
                'desc' => 'Rich lilac',

                'out' => $csi . '38:2:182:102:210m',
            },
            'RICH MAROON' => {
                'desc' => 'Rich maroon',

                'out' => $csi . '38:2:176:48:96m',
            },
            'RIFLE GREEN' => {
                'desc' => 'Rifle green',

                'out' => $csi . '38:2:65:72:51m',
            },
            'ROBINS EGG BLUE' => {
                'desc' => 'Robins Egg Blue',

                'out' => $csi . '38:2:31:206:203m',
            },
            'ROSE' => {
                'desc' => 'Rose',

                'out' => $csi . '38:2:255:0:127m',
            },
            'ROSE BONBON' => {
                'desc' => 'Rose bonbon',

                'out' => $csi . '38:2:249:66:158m',
            },
            'ROSE EBONY' => {
                'desc' => 'Rose ebony',

                'out' => $csi . '38:2:103:72:70m',
            },
            'ROSE GOLD' => {
                'desc' => 'Rose gold',

                'out' => $csi . '38:2:183:110:121m',
            },
            'ROSE MADDER' => {
                'desc' => 'Rose madder',

                'out' => $csi . '38:2:227:38:54m',
            },
            'ROSE PINK' => {
                'desc' => 'Rose pink',

                'out' => $csi . '38:2:255:102:204m',
            },
            'ROSE QUARTZ' => {
                'desc' => 'Rose quartz',

                'out' => $csi . '38:2:170:152:169m',
            },
            'ROSE TAUPE' => {
                'desc' => 'Rose taupe',

                'out' => $csi . '38:2:144:93:93m',
            },
            'ROSE VALE' => {
                'desc' => 'Rose vale',

                'out' => $csi . '38:2:171:78:82m',
            },
            'ROSEWOOD' => {
                'desc' => 'Rosewood',

                'out' => $csi . '38:2:101:0:11m',
            },
            'ROSSO CORSA' => {
                'desc' => 'Rosso corsa',

                'out' => $csi . '38:2:212:0:0m',
            },
            'ROSY BROWN' => {
                'desc' => 'Rosy brown',

                'out' => $csi . '38:2:188:143:143m',
            },
            'ROYAL AZURE' => {
                'desc' => 'Royal azure',

                'out' => $csi . '38:2:0:56:168m',
            },
            'ROYAL BLUE' => {
                'desc' => 'Royal blue',

                'out' => $csi . '38:2:65:105:225m',
            },
            'ROYAL FUCHSIA' => {
                'desc' => 'Royal fuchsia',

                'out' => $csi . '38:2:202:44:146m',
            },
            'ROYAL PURPLE' => {
                'desc' => 'Royal purple',

                'out' => $csi . '38:2:120:81:169m',
            },
            'RUBY' => {
                'desc' => 'Ruby',

                'out' => $csi . '38:2:224:17:95m',
            },
            'RUDDY' => {
                'desc' => 'Ruddy',

                'out' => $csi . '38:2:255:0:40m',
            },
            'RUDDY BROWN' => {
                'desc' => 'Ruddy brown',

                'out' => $csi . '38:2:187:101:40m',
            },
            'RUDDY PINK' => {
                'desc' => 'Ruddy pink',

                'out' => $csi . '38:2:225:142:150m',
            },
            'RUFOUS' => {
                'desc' => 'Rufous',

                'out' => $csi . '38:2:168:28:7m',
            },
            'RUSSET' => {
                'desc' => 'Russet',

                'out' => $csi . '38:2:128:70:27m',
            },
            'RUST' => {
                'desc' => 'Rust',

                'out' => $csi . '38:2:183:65:14m',
            },
            'SACRAMENTO STATE GREEN' => {
                'desc' => 'Sacramento State green',

                'out' => $csi . '38:2:0:86:63m',
            },
            'SADDLE BROWN' => {
                'desc' => 'Saddle brown',

                'out' => $csi . '38:2:139:69:19m',
            },
            'SAFETY ORANGE' => {
                'desc' => 'Safety orange',

                'out' => $csi . '38:2:255:103:0m',
            },
            'SAFFRON' => {
                'desc' => 'Saffron',

                'out' => $csi . '38:2:244:196:48m',
            },
            'SAINT PATRICK BLUE' => {
                'desc' => 'Saint Patrick Blue',

                'out' => $csi . '38:2:35:41:122m',
            },
            'SALMON' => {
                'desc' => 'Salmon',

                'out' => $csi . '38:2:255:140:105m',
            },
            'SALMON PINK' => {
                'desc' => 'Salmon pink',

                'out' => $csi . '38:2:255:145:164m',
            },
            'SAND' => {
                'desc' => 'Sand',

                'out' => $csi . '38:2:194:178:128m',
            },
            'SAND DUNE' => {
                'desc' => 'Sand dune',

                'out' => $csi . '38:2:150:113:23m',
            },
            'SANDSTORM' => {
                'desc' => 'Sandstorm',

                'out' => $csi . '38:2:236:213:64m',
            },
            'SANDY BROWN' => {
                'desc' => 'Sandy brown',

                'out' => $csi . '38:2:244:164:96m',
            },
            'SANDY TAUPE' => {
                'desc' => 'Sandy taupe',

                'out' => $csi . '38:2:150:113:23m',
            },
            'SAP GREEN' => {
                'desc' => 'Sap green',

                'out' => $csi . '38:2:80:125:42m',
            },
            'SAPPHIRE' => {
                'desc' => 'Sapphire',

                'out' => $csi . '38:2:15:82:186m',
            },
            'SATIN SHEEN GOLD' => {
                'desc' => 'Satin sheen gold',

                'out' => $csi . '38:2:203:161:53m',
            },
            'SCARLET' => {
                'desc' => 'Scarlet',

                'out' => $csi . '38:2:255:36:0m',
            },
            'SCHOOL BUS YELLOW' => {
                'desc' => 'School bus yellow',

                'out' => $csi . '38:2:255:216:0m',
            },
            'SCREAMIN GREEN' => {
                'desc' => 'Screamin Green',

                'out' => $csi . '38:2:118:255:122m',
            },
            'SEA BLUE' => {
                'desc' => 'Sea blue',

                'out' => $csi . '38:2:0:105:148m',
            },
            'SEA GREEN' => {
                'desc' => 'Sea green',

                'out' => $csi . '38:2:46:139:87m',
            },
            'SEAL BROWN' => {
                'desc' => 'Seal brown',

                'out' => $csi . '38:2:50:20:20m',
            },
            'SEASHELL' => {
                'desc' => 'Seashell',

                'out' => $csi . '38:2:255:245:238m',
            },
            'SELECTIVE YELLOW' => {
                'desc' => 'Selective yellow',

                'out' => $csi . '38:2:255:186:0m',
            },
            'SEPIA' => {
                'desc' => 'Sepia',

                'out' => $csi . '38:2:112:66:20m',
            },
            'SHADOW' => {
                'desc' => 'Shadow',

                'out' => $csi . '38:2:138:121:93m',
            },
            'SHAMROCK' => {
                'desc' => 'Shamrock',

                'out' => $csi . '38:2:69:206:162m',
            },
            'SHAMROCK GREEN' => {
                'desc' => 'Shamrock green',

                'out' => $csi . '38:2:0:158:96m',
            },
            'SHOCKING PINK' => {
                'desc' => 'Shocking pink',

                'out' => $csi . '38:2:252:15:192m',
            },
            'SIENNA' => {
                'desc' => 'Sienna',

                'out' => $csi . '38:2:136:45:23m',
            },
            'SILVER' => {
                'desc' => 'Silver',

                'out' => $csi . '38:2:192:192:192m',
            },
            'SINOPIA' => {
                'desc' => 'Sinopia',

                'out' => $csi . '38:2:203:65:11m',
            },
            'SKOBELOFF' => {
                'desc' => 'Skobeloff',

                'out' => $csi . '38:2:0:116:116m',
            },
            'SKY BLUE' => {
                'desc' => 'Sky blue',

                'out' => $csi . '38:2:135:206:235m',
            },
            'SKY MAGENTA' => {
                'desc' => 'Sky magenta',

                'out' => $csi . '38:2:207:113:175m',
            },
            'SLATE BLUE' => {
                'desc' => 'Slate blue',

                'out' => $csi . '38:2:106:90:205m',
            },
            'SLATE GRAY' => {
                'desc' => 'Slate gray',

                'out' => $csi . '38:2:112:128:144m',
            },
            'SMALT' => {
                'desc' => 'Smalt',

                'out' => $csi . '38:2:0:51:153m',
            },
            'SMOKEY TOPAZ' => {
                'desc' => 'Smokey topaz',

                'out' => $csi . '38:2:147:61:65m',
            },
            'SMOKY BLACK' => {
                'desc' => 'Smoky black',

                'out' => $csi . '38:2:16:12:8m',
            },
            'SNOW' => {
                'desc' => 'Snow',

                'out' => $csi . '38:2:255:250:250m',
            },
            'SPIRO DISCO BALL' => {
                'desc' => 'Spiro Disco Ball',

                'out' => $csi . '38:2:15:192:252m',
            },
            'SPRING BUD' => {
                'desc' => 'Spring bud',

                'out' => $csi . '38:2:167:252:0m',
            },
            'SPRING GREEN' => {
                'desc' => 'Spring green',

                'out' => $csi . '38:2:0:255:127m',
            },
            'STEEL BLUE' => {
                'desc' => 'Steel blue',

                'out' => $csi . '38:2:70:130:180m',
            },
            'STIL DE GRAIN YELLOW' => {
                'desc' => 'Stil de grain yellow',

                'out' => $csi . '38:2:250:218:94m',
            },
            'STIZZA' => {
                'desc' => 'Stizza',

                'out' => $csi . '38:2:153:0:0m',
            },
            'STORMCLOUD' => {
                'desc' => 'Stormcloud',

                'out' => $csi . '38:2:0:128:128m',
            },
            'STRAW' => {
                'desc' => 'Straw',

                'out' => $csi . '38:2:228:217:111m',
            },
            'SUNGLOW' => {
                'desc' => 'Sunglow',

                'out' => $csi . '38:2:255:204:51m',
            },
            'SUNSET' => {
                'desc' => 'Sunset',

                'out' => $csi . '38:2:250:214:165m',
            },
            'SUNSET ORANGE' => {
                'desc' => 'Sunset Orange',

                'out' => $csi . '38:2:253:94:83m',
            },
            'TAN' => {
                'desc' => 'Tan',

                'out' => $csi . '38:2:210:180:140m',
            },
            'TANGELO' => {
                'desc' => 'Tangelo',

                'out' => $csi . '38:2:249:77:0m',
            },
            'TANGERINE' => {
                'desc' => 'Tangerine',

                'out' => $csi . '38:2:242:133:0m',
            },
            'TANGERINE YELLOW' => {
                'desc' => 'Tangerine yellow',

                'out' => $csi . '38:2:255:204:0m',
            },
            'TAUPE' => {
                'desc' => 'Taupe',

                'out' => $csi . '38:2:72:60:50m',
            },
            'TAUPE GRAY' => {
                'desc' => 'Taupe gray',

                'out' => $csi . '38:2:139:133:137m',
            },
            'TAWNY' => {
                'desc' => 'Tawny',

                'out' => $csi . '38:2:205:87:0m',
            },
            'TEA GREEN' => {
                'desc' => 'Tea green',

                'out' => $csi . '38:2:208:240:192m',
            },
            'TEA ROSE' => {
                'desc' => 'Tea rose',

                'out' => $csi . '38:2:244:194:194m',
            },
            'TEAL' => {
                'desc' => 'Teal',

                'out' => $csi . '38:2:0:128:128m',
            },
            'TEAL BLUE' => {
                'desc' => 'Teal blue',

                'out' => $csi . '38:2:54:117:136m',
            },
            'TEAL GREEN' => {
                'desc' => 'Teal green',

                'out' => $csi . '38:2:0:109:91m',
            },
            'TERRA COTTA' => {
                'desc' => 'Terra cotta',

                'out' => $csi . '38:2:226:114:91m',
            },
            'THISTLE' => {
                'desc' => 'Thistle',

                'out' => $csi . '38:2:216:191:216m',
            },
            'THULIAN PINK' => {
                'desc' => 'Thulian pink',

                'out' => $csi . '38:2:222:111:161m',
            },
            'TICKLE ME PINK' => {
                'desc' => 'Tickle Me Pink',

                'out' => $csi . '38:2:252:137:172m',
            },
            'TIFFANY BLUE' => {
                'desc' => 'Tiffany Blue',

                'out' => $csi . '38:2:10:186:181m',
            },
            'TIGER EYE' => {
                'desc' => 'Tiger eye',

                'out' => $csi . '38:2:224:141:60m',
            },
            'TIMBERWOLF' => {
                'desc' => 'Timberwolf',

                'out' => $csi . '38:2:219:215:210m',
            },
            'TITANIUM YELLOW' => {
                'desc' => 'Titanium yellow',

                'out' => $csi . '38:2:238:230:0m',
            },
            'TOMATO' => {
                'desc' => 'Tomato',

                'out' => $csi . '38:2:255:99:71m',
            },
            'TOOLBOX' => {
                'desc' => 'Toolbox',

                'out' => $csi . '38:2:116:108:192m',
            },
            'TOPAZ' => {
                'desc' => 'Topaz',

                'out' => $csi . '38:2:255:200:124m',
            },
            'TRACTOR RED' => {
                'desc' => 'Tractor red',

                'out' => $csi . '38:2:253:14:53m',
            },
            'TROLLEY GRAY' => {
                'desc' => 'Trolley Grey',

                'out' => $csi . '38:2:128:128:128m',
            },
            'TROPICAL RAIN FOREST' => {
                'desc' => 'Tropical rain forest',

                'out' => $csi . '38:2:0:117:94m',
            },
            'TRUE BLUE' => {
                'desc' => 'True Blue',

                'out' => $csi . '38:2:0:115:207m',
            },
            'TUFTS BLUE' => {
                'desc' => 'Tufts Blue',

                'out' => $csi . '38:2:65:125:193m',
            },
            'TUMBLEWEED' => {
                'desc' => 'Tumbleweed',

                'out' => $csi . '38:2:222:170:136m',
            },
            'TURKISH ROSE' => {
                'desc' => 'Turkish rose',

                'out' => $csi . '38:2:181:114:129m',
            },
            'TURQUOISE' => {
                'desc' => 'Turquoise',

                'out' => $csi . '38:2:48:213:200m',
            },
            'TURQUOISE BLUE' => {
                'desc' => 'Turquoise blue',

                'out' => $csi . '38:2:0:255:239m',
            },
            'TURQUOISE GREEN' => {
                'desc' => 'Turquoise green',

                'out' => $csi . '38:2:160:214:180m',
            },
            'TUSCAN RED' => {
                'desc' => 'Tuscan red',

                'out' => $csi . '38:2:102:66:77m',
            },
            'TWILIGHT LAVENDER' => {
                'desc' => 'Twilight lavender',

                'out' => $csi . '38:2:138:73:107m',
            },
            'TYRIAN PURPLE' => {
                'desc' => 'Tyrian purple',

                'out' => $csi . '38:2:102:2:60m',
            },
            'UA BLUE' => {
                'desc' => 'UA blue',

                'out' => $csi . '38:2:0:51:170m',
            },
            'UA RED' => {
                'desc' => 'UA red',

                'out' => $csi . '38:2:217:0:76m',
            },
            'UBE' => {
                'desc' => 'Ube',

                'out' => $csi . '38:2:136:120:195m',
            },
            'UCLA BLUE' => {
                'desc' => 'UCLA Blue',

                'out' => $csi . '38:2:83:104:149m',
            },
            'UCLA GOLD' => {
                'desc' => 'UCLA Gold',

                'out' => $csi . '38:2:255:179:0m',
            },
            'UFO GREEN' => {
                'desc' => 'UFO Green',

                'out' => $csi . '38:2:60:208:112m',
            },
            'ULTRA PINK' => {
                'desc' => 'Ultra pink',

                'out' => $csi . '38:2:255:111:255m',
            },
            'ULTRAMARINE' => {
                'desc' => 'Ultramarine',

                'out' => $csi . '38:2:18:10:143m',
            },
            'ULTRAMARINE BLUE' => {
                'desc' => 'Ultramarine blue',

                'out' => $csi . '38:2:65:102:245m',
            },
            'UMBER' => {
                'desc' => 'Umber',

                'out' => $csi . '38:2:99:81:71m',
            },
            'UNITED NATIONS BLUE' => {
                'desc' => 'United Nations blue',

                'out' => $csi . '38:2:91:146:229m',
            },
            'UNIVERSITY OF' => {
                'desc' => 'University of',

                'out' => $csi . '38:2:183:135:39m',
            },
            'UNMELLOW YELLOW' => {
                'desc' => 'Unmellow Yellow',

                'out' => $csi . '38:2:255:255:102m',
            },
            'UP FOREST GREEN' => {
                'desc' => 'UP Forest green',

                'out' => $csi . '38:2:1:68:33m',
            },
            'UP MAROON' => {
                'desc' => 'UP Maroon',

                'out' => $csi . '38:2:123:17:19m',
            },
            'UPSDELL RED' => {
                'desc' => 'Upsdell red',

                'out' => $csi . '38:2:174:32:41m',
            },
            'UROBILIN' => {
                'desc' => 'Urobilin',

                'out' => $csi . '38:2:225:173:33m',
            },
            'USC CARDINAL' => {
                'desc' => 'USC Cardinal',

                'out' => $csi . '38:2:153:0:0m',
            },
            'USC GOLD' => {
                'desc' => 'USC Gold',

                'out' => $csi . '38:2:255:204:0m',
            },
            'UTAH CRIMSON' => {
                'desc' => 'Utah Crimson',

                'out' => $csi . '38:2:211:0:63m',
            },
            'VANILLA' => {
                'desc' => 'Vanilla',

                'out' => $csi . '38:2:243:229:171m',
            },
            'VEGAS GOLD' => {
                'desc' => 'Vegas gold',

                'out' => $csi . '38:2:197:179:88m',
            },
            'VENETIAN RED' => {
                'desc' => 'Venetian red',

                'out' => $csi . '38:2:200:8:21m',
            },
            'VERDIGRIS' => {
                'desc' => 'Verdigris',

                'out' => $csi . '38:2:67:179:174m',
            },
            'VERMILION' => {
                'desc' => 'Vermilion',

                'out' => $csi . '38:2:227:66:52m',
            },
            'VERONICA' => {
                'desc' => 'Veronica',

                'out' => $csi . '38:2:160:32:240m',
            },
            'VIOLET' => {
                'desc' => 'Violet',

                'out' => $csi . '38:2:238:130:238m',
            },
            'VIOLET BLUE' => {
                'desc' => 'Violet Blue',

                'out' => $csi . '38:2:50:74:178m',
            },
            'VIOLET RED' => {
                'desc' => 'Violet Red',

                'out' => $csi . '38:2:247:83:148m',
            },
            'VIRIDIAN' => {
                'desc' => 'Viridian',

                'out' => $csi . '38:2:64:130:109m',
            },
            'VIVID AUBURN' => {
                'desc' => 'Vivid auburn',

                'out' => $csi . '38:2:146:39:36m',
            },
            'VIVID BURGUNDY' => {
                'desc' => 'Vivid burgundy',

                'out' => $csi . '38:2:159:29:53m',
            },
            'VIVID CERISE' => {
                'desc' => 'Vivid cerise',

                'out' => $csi . '38:2:218:29:129m',
            },
            'VIVID TANGERINE' => {
                'desc' => 'Vivid tangerine',

                'out' => $csi . '38:2:255:160:137m',
            },
            'VIVID VIOLET' => {
                'desc' => 'Vivid violet',

                'out' => $csi . '38:2:159:0:255m',
            },
            'WARM BLACK' => {
                'desc' => 'Warm black',

                'out' => $csi . '38:2:0:66:66m',
            },
            'WATERSPOUT' => {
                'desc' => 'Waterspout',

                'out' => $csi . '38:2:0:255:255m',
            },
            'WENGE' => {
                'desc' => 'Wenge',

                'out' => $csi . '38:2:100:84:82m',
            },
            'WHEAT' => {
                'desc' => 'Wheat',

                'out' => $csi . '38:2:245:222:179m',
            },
            'WHITE SMOKE' => {
                'desc' => 'White smoke',

                'out' => $csi . '38:2:245:245:245m',
            },
            'WILD BLUE YONDER' => {
                'desc' => 'Wild blue yonder',

                'out' => $csi . '38:2:162:173:208m',
            },
            'WILD STRAWBERRY' => {
                'desc' => 'Wild Strawberry',

                'out' => $csi . '38:2:255:67:164m',
            },
            'WILD WATERMELON' => {
                'desc' => 'Wild Watermelon',

                'out' => $csi . '38:2:252:108:133m',
            },
            'WINE' => {
                'desc' => 'Wine',

                'out' => $csi . '38:2:114:47:55m',
            },
            'WISTERIA' => {
                'desc' => 'Wisteria',

                'out' => $csi . '38:2:201:160:220m',
            },
            'XANADU' => {
                'desc' => 'Xanadu',

                'out' => $csi . '38:2:115:134:120m',
            },
            'YALE BLUE' => {
                'desc' => 'Yale Blue',

                'out' => $csi . '38:2:15:77:146m',
            },
            'YELLOW GREEN' => {
                'desc' => 'Yellow green',

                'out' => $csi . '38:2:154:205:50m',
            },
            'YELLOW ORANGE' => {
                'desc' => 'Yellow Orange',

                'out' => $csi . '38:2:255:174:66m',
            },
            'ZAFFRE' => {
                'desc' => 'Zaffre',

                'out' => $csi . '38:2:0:20:168m',
            },
            'ZINNWALDITE BROWN' => {
                'desc' => 'Zinnwaldite brown',

                'out' => $csi . '38:2:44:22:8m',
            },
        },

        'background' => {
            'B_DEFAULT' => {
                'out'  => $csi . '49m',
                'desc' => 'Default background color',

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
            'B_DARK SLATE GRAY' => {
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
            'B_SLATE GRAY' => {
                'out'  => $csi . '48:2:112:128:144m',
                'desc' => 'Slate gray',

            },
            'B_LIGHT SLATE GRAY' => {
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
            'B_DIM GRAY' => {
                'out'  => $csi . '48:2:105:105:105m',
                'desc' => 'Dim gray',

            },
            'B_DARK GRAY' => {
                'out'  => $csi . '48:2:169:169:169m',
                'desc' => 'Dark gray',

            },
            'B_SILVER' => {
                'out'  => $csi . '48:2:192:192:192m',
                'desc' => 'Silver',

            },
            'B_LIGHT GRAY' => {
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
            'B_AIR FORCE BLUE' => {
                'desc' => 'Air Force blue',

                'out' => $csi . '48:2:93:138:168m',
            },
            'B_ALICE BLUE' => {
                'desc' => 'Alice blue',

                'out' => $csi . '48:2:240:248:255m',
            },
            'B_ALIZARIN CRIMSON' => {
                'desc' => 'Alizarin crimson',

                'out' => $csi . '48:2:227:38:54m',
            },
            'B_ALMOND' => {
                'desc' => 'Almond',

                'out' => $csi . '48:2:239:222:205m',
            },
            'B_AMARANTH' => {
                'desc' => 'Amaranth',

                'out' => $csi . '48:2:229:43:80m',
            },
            'B_AMBER' => {
                'desc' => 'Amber',

                'out' => $csi . '48:2:255:191:0m',
            },
            'B_AMERICAN ROSE' => {
                'desc' => 'American rose',

                'out' => $csi . '48:2:255:3:62m',
            },
            'B_AMETHYST' => {
                'desc' => 'Amethyst',

                'out' => $csi . '48:2:153:102:204m',
            },
            'B_ANDROID GREEN' => {
                'desc' => 'Android Green',

                'out' => $csi . '48:2:164:198:57m',
            },
            'B_ANTI-FLASH WHITE' => {
                'desc' => 'Anti-flash white',

                'out' => $csi . '48:2:242:243:244m',
            },
            'B_ANTIQUE BRASS' => {
                'desc' => 'Antique brass',

                'out' => $csi . '48:2:205:149:117m',
            },
            'B_ANTIQUE FUCHSIA' => {
                'desc' => 'Antique fuchsia',

                'out' => $csi . '48:2:145:92:131m',
            },
            'B_ANTIQUE WHITE' => {
                'desc' => 'Antique white',

                'out' => $csi . '48:2:250:235:215m',
            },
            'B_AO' => {
                'desc' => 'Ao',

                'out' => $csi . '48:2:0:128:0m',
            },
            'B_APPLE GREEN' => {
                'desc' => 'Apple green',

                'out' => $csi . '48:2:141:182:0m',
            },
            'B_APRICOT' => {
                'desc' => 'Apricot',

                'out' => $csi . '48:2:251:206:177m',
            },
            'B_AQUA' => {
                'desc' => 'Aqua',

                'out' => $csi . '48:2:0:255:255m',
            },
            'B_AQUAMARINE' => {
                'desc' => 'Aquamarine',

                'out' => $csi . '48:2:127:255:212m',
            },
            'B_ARMY GREEN' => {
                'desc' => 'Army green',

                'out' => $csi . '48:2:75:83:32m',
            },
            'B_ARYLIDE YELLOW' => {
                'desc' => 'Arylide yellow',

                'out' => $csi . '48:2:233:214:107m',
            },
            'B_ASH GRAY' => {
                'desc' => 'Ash grey',

                'out' => $csi . '48:2:178:190:181m',
            },
            'B_ASPARAGUS' => {
                'desc' => 'Asparagus',

                'out' => $csi . '48:2:135:169:107m',
            },
            'B_ATOMIC TANGERINE' => {
                'desc' => 'Atomic tangerine',

                'out' => $csi . '48:2:255:153:102m',
            },
            'B_AUBURN' => {
                'desc' => 'Auburn',

                'out' => $csi . '48:2:165:42:42m',
            },
            'B_AUREOLIN' => {
                'desc' => 'Aureolin',

                'out' => $csi . '48:2:253:238:0m',
            },
            'B_AUROMETALSAURUS' => {
                'desc' => 'AuroMetalSaurus',

                'out' => $csi . '48:2:110:127:128m',
            },
            'B_AWESOME' => {
                'desc' => 'Awesome',

                'out' => $csi . '48:2:255:32:82m',
            },
            'B_AZURE' => {
                'desc' => 'Azure',

                'out' => $csi . '48:2:0:127:255m',
            },
            'B_AZURE MIST' => {
                'desc' => 'Azure mist',

                'out' => $csi . '48:2:240:255:255m',
            },
            'B_BABY BLUE' => {
                'desc' => 'Baby blue',

                'out' => $csi . '48:2:137:207:240m',
            },
            'B_BABY BLUE EYES' => {
                'desc' => 'Baby blue eyes',

                'out' => $csi . '48:2:161:202:241m',
            },
            'B_BABY PINK' => {
                'desc' => 'Baby pink',

                'out' => $csi . '48:2:244:194:194m',
            },
            'B_BALL BLUE' => {
                'desc' => 'Ball Blue',

                'out' => $csi . '48:2:33:171:205m',
            },
            'B_BANANA MANIA' => {
                'desc' => 'Banana Mania',

                'out' => $csi . '48:2:250:231:181m',
            },
            'B_BANANA YELLOW' => {
                'desc' => 'Banana yellow',

                'out' => $csi . '48:2:255:225:53m',
            },
            'B_BATTLESHIP GRAY' => {
                'desc' => 'Battleship grey',

                'out' => $csi . '48:2:132:132:130m',
            },
            'B_BAZAAR' => {
                'desc' => 'Bazaar',

                'out' => $csi . '48:2:152:119:123m',
            },
            'B_BEAU BLUE' => {
                'desc' => 'Beau blue',

                'out' => $csi . '48:2:188:212:230m',
            },
            'B_BEAVER' => {
                'desc' => 'Beaver',

                'out' => $csi . '48:2:159:129:112m',
            },
            'B_BEIGE' => {
                'desc' => 'Beige',

                'out' => $csi . '48:2:245:245:220m',
            },
            'B_BISQUE' => {
                'desc' => 'Bisque',

                'out' => $csi . '48:2:255:228:196m',
            },
            'B_BISTRE' => {
                'desc' => 'Bistre',

                'out' => $csi . '48:2:61:43:31m',
            },
            'B_BITTERSWEET' => {
                'desc' => 'Bittersweet',

                'out' => $csi . '48:2:254:111:94m',
            },
            'B_BLANCHED ALMOND' => {
                'desc' => 'Blanched Almond',

                'out' => $csi . '48:2:255:235:205m',
            },
            'B_BLEU DE FRANCE' => {
                'desc' => 'Bleu de France',

                'out' => $csi . '48:2:49:140:231m',
            },
            'B_BLIZZARD BLUE' => {
                'desc' => 'Blizzard Blue',

                'out' => $csi . '48:2:172:229:238m',
            },
            'B_BLOND' => {
                'desc' => 'Blond',

                'out' => $csi . '48:2:250:240:190m',
            },
            'B_BLUE BELL' => {
                'desc' => 'Blue Bell',

                'out' => $csi . '48:2:162:162:208m',
            },
            'B_BLUE GRAY' => {
                'desc' => 'Blue Gray',

                'out' => $csi . '48:2:102:153:204m',
            },
            'B_BLUE GREEN' => {
                'desc' => 'Blue green',

                'out' => $csi . '48:2:13:152:186m',
            },
            'B_BLUE PURPLE' => {
                'desc' => 'Blue purple',

                'out' => $csi . '48:2:138:43:226m',
            },
            'B_BLUE VIOLET' => {
                'desc' => 'Blue violet',

                'out' => $csi . '48:2:138:43:226m',
            },
            'B_BLUSH' => {
                'desc' => 'Blush',

                'out' => $csi . '48:2:222:93:131m',
            },
            'B_BOLE' => {
                'desc' => 'Bole',

                'out' => $csi . '48:2:121:68:59m',
            },
            'B_BONDI BLUE' => {
                'desc' => 'Bondi blue',

                'out' => $csi . '48:2:0:149:182m',
            },
            'B_BONE' => {
                'desc' => 'Bone',

                'out' => $csi . '48:2:227:218:201m',
            },
            'B_BOSTON UNIVERSITY RED' => {
                'desc' => 'Boston University Red',

                'out' => $csi . '48:2:204:0:0m',
            },
            'B_BOTTLE GREEN' => {
                'desc' => 'Bottle green',

                'out' => $csi . '48:2:0:106:78m',
            },
            'B_BOYSENBERRY' => {
                'desc' => 'Boysenberry',

                'out' => $csi . '48:2:135:50:96m',
            },
            'B_BRANDEIS BLUE' => {
                'desc' => 'Brandeis blue',

                'out' => $csi . '48:2:0:112:255m',
            },
            'B_BRASS' => {
                'desc' => 'Brass',

                'out' => $csi . '48:2:181:166:66m',
            },
            'B_BRICK RED' => {
                'desc' => 'Brick red',

                'out' => $csi . '48:2:203:65:84m',
            },
            'B_BRIGHT CERULEAN' => {
                'desc' => 'Bright cerulean',

                'out' => $csi . '48:2:29:172:214m',
            },
            'B_BRIGHT GREEN' => {
                'desc' => 'Bright green',

                'out' => $csi . '48:2:102:255:0m',
            },
            'B_BRIGHT LAVENDER' => {
                'desc' => 'Bright lavender',

                'out' => $csi . '48:2:191:148:228m',
            },
            'B_BRIGHT MAROON' => {
                'desc' => 'Bright maroon',

                'out' => $csi . '48:2:195:33:72m',
            },
            'B_BRIGHT PINK' => {
                'desc' => 'Bright pink',

                'out' => $csi . '48:2:255:0:127m',
            },
            'B_BRIGHT TURQUOISE' => {
                'desc' => 'Bright turquoise',

                'out' => $csi . '48:2:8:232:222m',
            },
            'B_BRIGHT UBE' => {
                'desc' => 'Bright ube',

                'out' => $csi . '48:2:209:159:232m',
            },
            'B_BRILLIANT LAVENDER' => {
                'desc' => 'Brilliant lavender',

                'out' => $csi . '48:2:244:187:255m',
            },
            'B_BRILLIANT ROSE' => {
                'desc' => 'Brilliant rose',

                'out' => $csi . '48:2:255:85:163m',
            },
            'B_BRINK PINK' => {
                'desc' => 'Brink pink',

                'out' => $csi . '48:2:251:96:127m',
            },
            'B_BRITISH RACING GREEN' => {
                'desc' => 'British racing green',

                'out' => $csi . '48:2:0:66:37m',
            },
            'B_BRONZE' => {
                'desc' => 'Bronze',

                'out' => $csi . '48:2:205:127:50m',
            },
            'B_BROWN' => {
                'desc' => 'Brown',

                'out' => $csi . '48:2:165:42:42m',
            },
            'B_BUBBLE GUM' => {
                'desc' => 'Bubble gum',

                'out' => $csi . '48:2:255:193:204m',
            },
            'B_BUBBLES' => {
                'desc' => 'Bubbles',

                'out' => $csi . '48:2:231:254:255m',
            },
            'B_BUFF' => {
                'desc' => 'Buff',

                'out' => $csi . '48:2:240:220:130m',
            },
            'B_BULGARIAN ROSE' => {
                'desc' => 'Bulgarian rose',

                'out' => $csi . '48:2:72:6:7m',
            },
            'B_BURGUNDY' => {
                'desc' => 'Burgundy',

                'out' => $csi . '48:2:128:0:32m',
            },
            'B_BURLYWOOD' => {
                'desc' => 'Burlywood',

                'out' => $csi . '48:2:222:184:135m',
            },
            'B_BURNT ORANGE' => {
                'desc' => 'Burnt orange',

                'out' => $csi . '48:2:204:85:0m',
            },
            'B_BURNT SIENNA' => {
                'desc' => 'Burnt sienna',

                'out' => $csi . '48:2:233:116:81m',
            },
            'B_BURNT UMBER' => {
                'desc' => 'Burnt umber',

                'out' => $csi . '48:2:138:51:36m',
            },
            'B_BYZANTINE' => {
                'desc' => 'Byzantine',

                'out' => $csi . '48:2:189:51:164m',
            },
            'B_BYZANTIUM' => {
                'desc' => 'Byzantium',

                'out' => $csi . '48:2:112:41:99m',
            },
            'B_CADET' => {
                'desc' => 'Cadet',

                'out' => $csi . '48:2:83:104:114m',
            },
            'B_CADET BLUE' => {
                'desc' => 'Cadet blue',

                'out' => $csi . '48:2:95:158:160m',
            },
            'B_CADET GRAY' => {
                'desc' => 'Cadet grey',

                'out' => $csi . '48:2:145:163:176m',
            },
            'B_CADMIUM GREEN' => {
                'desc' => 'Cadmium green',

                'out' => $csi . '48:2:0:107:60m',
            },
            'B_CADMIUM ORANGE' => {
                'desc' => 'Cadmium orange',

                'out' => $csi . '48:2:237:135:45m',
            },
            'B_CADMIUM RED' => {
                'desc' => 'Cadmium red',

                'out' => $csi . '48:2:227:0:34m',
            },
            'B_CADMIUM YELLOW' => {
                'desc' => 'Cadmium yellow',

                'out' => $csi . '48:2:255:246:0m',
            },
            'B_CAFE AU LAIT' => {
                'desc' => 'Caf\303\251 au lait',

                'out' => $csi . '48:2:166:123:91m',
            },
            'B_CAFE NOIR' => {
                'desc' => 'Caf\303\251 noir',

                'out' => $csi . '48:2:75:54:33m',
            },
            'B_CAL POLY POMONA GREEN' => {
                'desc' => 'Cal Poly Pomona green',

                'out' => $csi . '48:2:30:77:43m',
            },
            'B_UNIVERSITY OF CALIFORNIA GOLD' => {
                'desc' => 'University of California Gold',
                'out'  => $csi . '48:2:183:135:39m',
            },
            'B_CAMBRIDGE BLUE' => {
                'desc' => 'Cambridge Blue',

                'out' => $csi . '48:2:163:193:173m',
            },
            'B_CAMEL' => {
                'desc' => 'Camel',

                'out' => $csi . '48:2:193:154:107m',
            },
            'B_CAMOUFLAGE GREEN' => {
                'desc' => 'Camouflage green',

                'out' => $csi . '48:2:120:134:107m',
            },
            'B_CANARY' => {
                'desc' => 'Canary',

                'out' => $csi . '48:2:255:255:153m',
            },
            'B_CANARY YELLOW' => {
                'desc' => 'Canary yellow',

                'out' => $csi . '48:2:255:239:0m',
            },
            'B_CANDY APPLE RED' => {
                'desc' => 'Candy apple red',

                'out' => $csi . '48:2:255:8:0m',
            },
            'B_CANDY PINK' => {
                'desc' => 'Candy pink',

                'out' => $csi . '48:2:228:113:122m',
            },
            'B_CAPRI' => {
                'desc' => 'Capri',

                'out' => $csi . '48:2:0:191:255m',
            },
            'B_CAPUT MORTUUM' => {
                'desc' => 'Caput mortuum',

                'out' => $csi . '48:2:89:39:32m',
            },
            'B_CARDINAL' => {
                'desc' => 'Cardinal',

                'out' => $csi . '48:2:196:30:58m',
            },
            'B_CARIBBEAN GREEN' => {
                'desc' => 'Caribbean green',

                'out' => $csi . '48:2:0:204:153m',
            },
            'B_CARMINE' => {
                'desc' => 'Carmine',

                'out' => $csi . '48:2:255:0:64m',
            },
            'B_CARMINE PINK' => {
                'desc' => 'Carmine pink',

                'out' => $csi . '48:2:235:76:66m',
            },
            'B_CARMINE RED' => {
                'desc' => 'Carmine red',

                'out' => $csi . '48:2:255:0:56m',
            },
            'B_CARNATION PINK' => {
                'desc' => 'Carnation pink',

                'out' => $csi . '48:2:255:166:201m',
            },
            'B_CARNELIAN' => {
                'desc' => 'Carnelian',

                'out' => $csi . '48:2:179:27:27m',
            },
            'B_CAROLINA BLUE' => {
                'desc' => 'Carolina blue',

                'out' => $csi . '48:2:153:186:221m',
            },
            'B_CARROT ORANGE' => {
                'desc' => 'Carrot orange',

                'out' => $csi . '48:2:237:145:33m',
            },
            'B_CELADON' => {
                'desc' => 'Celadon',

                'out' => $csi . '48:2:172:225:175m',
            },
            'B_CELESTE' => {
                'desc' => 'Celeste',

                'out' => $csi . '48:2:178:255:255m',
            },
            'B_CELESTIAL BLUE' => {
                'desc' => 'Celestial blue',

                'out' => $csi . '48:2:73:151:208m',
            },
            'B_CERISE' => {
                'desc' => 'Cerise',

                'out' => $csi . '48:2:222:49:99m',
            },
            'B_CERISE PINK' => {
                'desc' => 'Cerise pink',

                'out' => $csi . '48:2:236:59:131m',
            },
            'B_CERULEAN' => {
                'desc' => 'Cerulean',

                'out' => $csi . '48:2:0:123:167m',
            },
            'B_CERULEAN BLUE' => {
                'desc' => 'Cerulean blue',

                'out' => $csi . '48:2:42:82:190m',
            },
            'B_CG BLUE' => {
                'desc' => 'CG Blue',

                'out' => $csi . '48:2:0:122:165m',
            },
            'B_CG RED' => {
                'desc' => 'CG Red',

                'out' => $csi . '48:2:224:60:49m',
            },
            'B_CHAMOISEE' => {
                'desc' => 'Chamoisee',

                'out' => $csi . '48:2:160:120:90m',
            },
            'B_CHAMPAGNE' => {
                'desc' => 'Champagne',

                'out' => $csi . '48:2:250:214:165m',
            },
            'B_CHARCOAL' => {
                'desc' => 'Charcoal',

                'out' => $csi . '48:2:54:69:79m',
            },
            'B_CHARTREUSE' => {
                'desc' => 'Chartreuse',

                'out' => $csi . '48:2:127:255:0m',
            },
            'B_CHERRY' => {
                'desc' => 'Cherry',

                'out' => $csi . '48:2:222:49:99m',
            },
            'B_CHERRY BLOSSOM PINK' => {
                'desc' => 'Cherry blossom pink',

                'out' => $csi . '48:2:255:183:197m',
            },
            'B_CHESTNUT' => {
                'desc' => 'Chestnut',

                'out' => $csi . '48:2:205:92:92m',
            },
            'B_CHOCOLATE' => {
                'desc' => 'Chocolate',

                'out' => $csi . '48:2:210:105:30m',
            },
            'B_CHROME YELLOW' => {
                'desc' => 'Chrome yellow',

                'out' => $csi . '48:2:255:167:0m',
            },
            'B_CINEREOUS' => {
                'desc' => 'Cinereous',

                'out' => $csi . '48:2:152:129:123m',
            },
            'B_CINNABAR' => {
                'desc' => 'Cinnabar',

                'out' => $csi . '48:2:227:66:52m',
            },
            'B_CINNAMON' => {
                'desc' => 'Cinnamon',

                'out' => $csi . '48:2:210:105:30m',
            },
            'B_CITRINE' => {
                'desc' => 'Citrine',

                'out' => $csi . '48:2:228:208:10m',
            },
            'B_CLASSIC ROSE' => {
                'desc' => 'Classic rose',

                'out' => $csi . '48:2:251:204:231m',
            },
            'B_COBALT' => {
                'desc' => 'Cobalt',

                'out' => $csi . '48:2:0:71:171m',
            },
            'B_COCOA BROWN' => {
                'desc' => 'Cocoa brown',

                'out' => $csi . '48:2:210:105:30m',
            },
            'B_COFFEE' => {
                'desc' => 'Coffee',

                'out' => $csi . '48:2:111:78:55m',
            },
            'B_COLUMBIA BLUE' => {
                'desc' => 'Columbia blue',

                'out' => $csi . '48:2:155:221:255m',
            },
            'B_COOL BLACK' => {
                'desc' => 'Cool black',

                'out' => $csi . '48:2:0:46:99m',
            },
            'B_COOL GRAY' => {
                'desc' => 'Cool grey',

                'out' => $csi . '48:2:140:146:172m',
            },
            'B_COPPER' => {
                'desc' => 'Copper',

                'out' => $csi . '48:2:184:115:51m',
            },
            'B_COPPER ROSE' => {
                'desc' => 'Copper rose',

                'out' => $csi . '48:2:153:102:102m',
            },
            'B_COQUELICOT' => {
                'desc' => 'Coquelicot',

                'out' => $csi . '48:2:255:56:0m',
            },
            'B_CORAL' => {
                'desc' => 'Coral',

                'out' => $csi . '48:2:255:127:80m',
            },
            'B_CORAL PINK' => {
                'desc' => 'Coral pink',

                'out' => $csi . '48:2:248:131:121m',
            },
            'B_CORAL RED' => {
                'desc' => 'Coral red',

                'out' => $csi . '48:2:255:64:64m',
            },
            'B_CORDOVAN' => {
                'desc' => 'Cordovan',

                'out' => $csi . '48:2:137:63:69m',
            },
            'B_CORN' => {
                'desc' => 'Corn',

                'out' => $csi . '48:2:251:236:93m',
            },
            'B_CORNELL RED' => {
                'desc' => 'Cornell Red',

                'out' => $csi . '48:2:179:27:27m',
            },
            'B_CORNFLOWER' => {
                'desc' => 'Cornflower',

                'out' => $csi . '48:2:154:206:235m',
            },
            'B_CORNFLOWER BLUE' => {
                'desc' => 'Cornflower blue',

                'out' => $csi . '48:2:100:149:237m',
            },
            'B_CORNSILK' => {
                'desc' => 'Cornsilk',

                'out' => $csi . '48:2:255:248:220m',
            },
            'B_COSMIC LATTE' => {
                'desc' => 'Cosmic latte',

                'out' => $csi . '48:2:255:248:231m',
            },
            'B_COTTON CANDY' => {
                'desc' => 'Cotton candy',

                'out' => $csi . '48:2:255:188:217m',
            },
            'B_CREAM' => {
                'desc' => 'Cream',

                'out' => $csi . '48:2:255:253:208m',
            },
            'B_CRIMSON' => {
                'desc' => 'Crimson',

                'out' => $csi . '48:2:220:20:60m',
            },
            'B_CRIMSON GLORY' => {
                'desc' => 'Crimson glory',

                'out' => $csi . '48:2:190:0:50m',
            },
            'B_CRIMSON RED' => {
                'desc' => 'Crimson Red',

                'out' => $csi . '48:2:153:0:0m',
            },
            'B_DAFFODIL' => {
                'desc' => 'Daffodil',

                'out' => $csi . '48:2:255:255:49m',
            },
            'B_DANDELION' => {
                'desc' => 'Dandelion',

                'out' => $csi . '48:2:240:225:48m',
            },
            'B_DARK BLUE' => {
                'desc' => 'Dark blue',

                'out' => $csi . '48:2:0:0:139m',
            },
            'B_DARK BROWN' => {
                'desc' => 'Dark brown',

                'out' => $csi . '48:2:101:67:33m',
            },
            'B_DARK BYZANTIUM' => {
                'desc' => 'Dark byzantium',

                'out' => $csi . '48:2:93:57:84m',
            },
            'B_DARK CANDY APPLE RED' => {
                'desc' => 'Dark candy apple red',

                'out' => $csi . '48:2:164:0:0m',
            },
            'B_DARK CERULEAN' => {
                'desc' => 'Dark cerulean',

                'out' => $csi . '48:2:8:69:126m',
            },
            'B_DARK CHESTNUT' => {
                'desc' => 'Dark chestnut',

                'out' => $csi . '48:2:152:105:96m',
            },
            'B_DARK CORAL' => {
                'desc' => 'Dark coral',

                'out' => $csi . '48:2:205:91:69m',
            },
            'B_DARK CYAN' => {
                'desc' => 'Dark cyan',

                'out' => $csi . '48:2:0:139:139m',
            },
            'B_DARK ELECTRIC BLUE' => {
                'desc' => 'Dark electric blue',

                'out' => $csi . '48:2:83:104:120m',
            },
            'B_DARK GOLDENROD' => {
                'desc' => 'Dark goldenrod',

                'out' => $csi . '48:2:184:134:11m',
            },
            'B_DARK GRAY' => {
                'desc' => 'Dark gray',

                'out' => $csi . '48:2:169:169:169m',
            },
            'B_DARK GREEN' => {
                'desc' => 'Dark green',

                'out' => $csi . '48:2:1:50:32m',
            },
            'B_DARK JUNGLE GREEN' => {
                'desc' => 'Dark jungle green',

                'out' => $csi . '48:2:26:36:33m',
            },
            'B_DARK KHAKI' => {
                'desc' => 'Dark khaki',

                'out' => $csi . '48:2:189:183:107m',
            },
            'B_DARK LAVA' => {
                'desc' => 'Dark lava',

                'out' => $csi . '48:2:72:60:50m',
            },
            'B_DARK LAVENDER' => {
                'desc' => 'Dark lavender',

                'out' => $csi . '48:2:115:79:150m',
            },
            'B_DARK MAGENTA' => {
                'desc' => 'Dark magenta',

                'out' => $csi . '48:2:139:0:139m',
            },
            'B_DARK MIDNIGHT BLUE' => {
                'desc' => 'Dark midnight blue',

                'out' => $csi . '48:2:0:51:102m',
            },
            'B_DARK OLIVE GREEN' => {
                'desc' => 'Dark olive green',

                'out' => $csi . '48:2:85:107:47m',
            },
            'B_DARK ORANGE' => {
                'desc' => 'Dark orange',

                'out' => $csi . '48:2:255:140:0m',
            },
            'B_DARK ORCHID' => {
                'desc' => 'Dark orchid',

                'out' => $csi . '48:2:153:50:204m',
            },
            'B_DARK PASTEL BLUE' => {
                'desc' => 'Dark pastel blue',

                'out' => $csi . '48:2:119:158:203m',
            },
            'B_DARK PASTEL GREEN' => {
                'desc' => 'Dark pastel green',

                'out' => $csi . '48:2:3:192:60m',
            },
            'B_DARK PASTEL PURPLE' => {
                'desc' => 'Dark pastel purple',

                'out' => $csi . '48:2:150:111:214m',
            },
            'B_DARK PASTEL RED' => {
                'desc' => 'Dark pastel red',

                'out' => $csi . '48:2:194:59:34m',
            },
            'B_DARK PINK' => {
                'desc' => 'Dark pink',

                'out' => $csi . '48:2:231:84:128m',
            },
            'B_DARK POWDER BLUE' => {
                'desc' => 'Dark powder blue',

                'out' => $csi . '48:2:0:51:153m',
            },
            'B_DARK RASPBERRY' => {
                'desc' => 'Dark raspberry',

                'out' => $csi . '48:2:135:38:87m',
            },
            'B_DARK RED' => {
                'desc' => 'Dark red',

                'out' => $csi . '48:2:139:0:0m',
            },
            'B_DARK SALMON' => {
                'desc' => 'Dark salmon',

                'out' => $csi . '48:2:233:150:122m',
            },
            'B_DARK SCARLET' => {
                'desc' => 'Dark scarlet',

                'out' => $csi . '48:2:86:3:25m',
            },
            'B_DARK SEA GREEN' => {
                'desc' => 'Dark sea green',

                'out' => $csi . '48:2:143:188:143m',
            },
            'B_DARK SIENNA' => {
                'desc' => 'Dark sienna',

                'out' => $csi . '48:2:60:20:20m',
            },
            'B_DARK SLATE BLUE' => {
                'desc' => 'Dark slate blue',

                'out' => $csi . '48:2:72:61:139m',
            },
            'B_DARK SLATE GRAY' => {
                'desc' => 'Dark slate gray',

                'out' => $csi . '48:2:47:79:79m',
            },
            'B_DARK SPRING GREEN' => {
                'desc' => 'Dark spring green',

                'out' => $csi . '48:2:23:114:69m',
            },
            'B_DARK TAN' => {
                'desc' => 'Dark tan',

                'out' => $csi . '48:2:145:129:81m',
            },
            'B_DARK TANGERINE' => {
                'desc' => 'Dark tangerine',

                'out' => $csi . '48:2:255:168:18m',
            },
            'B_DARK TAUPE' => {
                'desc' => 'Dark taupe',

                'out' => $csi . '48:2:72:60:50m',
            },
            'B_DARK TERRA COTTA' => {
                'desc' => 'Dark terra cotta',

                'out' => $csi . '48:2:204:78:92m',
            },
            'B_DARK TURQUOISE' => {
                'desc' => 'Dark turquoise',

                'out' => $csi . '48:2:0:206:209m',
            },
            'B_DARK VIOLET' => {
                'desc' => 'Dark violet',

                'out' => $csi . '48:2:148:0:211m',
            },
            'B_DARTMOUTH GREEN' => {
                'desc' => 'Dartmouth green',

                'out' => $csi . '48:2:0:105:62m',
            },
            'B_DAVY GRAY' => {
                'desc' => 'Davy grey',

                'out' => $csi . '48:2:85:85:85m',
            },
            'B_DEBIAN RED' => {
                'desc' => 'Debian red',

                'out' => $csi . '48:2:215:10:83m',
            },
            'B_DEEP CARMINE' => {
                'desc' => 'Deep carmine',

                'out' => $csi . '48:2:169:32:62m',
            },
            'B_DEEP CARMINE PINK' => {
                'desc' => 'Deep carmine pink',

                'out' => $csi . '48:2:239:48:56m',
            },
            'B_DEEP CARROT ORANGE' => {
                'desc' => 'Deep carrot orange',

                'out' => $csi . '48:2:233:105:44m',
            },
            'B_DEEP CERISE' => {
                'desc' => 'Deep cerise',

                'out' => $csi . '48:2:218:50:135m',
            },
            'B_DEEP CHAMPAGNE' => {
                'desc' => 'Deep champagne',

                'out' => $csi . '48:2:250:214:165m',
            },
            'B_DEEP CHESTNUT' => {
                'desc' => 'Deep chestnut',

                'out' => $csi . '48:2:185:78:72m',
            },
            'B_DEEP COFFEE' => {
                'desc' => 'Deep coffee',

                'out' => $csi . '48:2:112:66:65m',
            },
            'B_DEEP FUCHSIA' => {
                'desc' => 'Deep fuchsia',

                'out' => $csi . '48:2:193:84:193m',
            },
            'B_DEEP JUNGLE GREEN' => {
                'desc' => 'Deep jungle green',

                'out' => $csi . '48:2:0:75:73m',
            },
            'B_DEEP LILAC' => {
                'desc' => 'Deep lilac',

                'out' => $csi . '48:2:153:85:187m',
            },
            'B_DEEP MAGENTA' => {
                'desc' => 'Deep magenta',

                'out' => $csi . '48:2:204:0:204m',
            },
            'B_DEEP PEACH' => {
                'desc' => 'Deep peach',

                'out' => $csi . '48:2:255:203:164m',
            },
            'B_DEEP PINK' => {
                'desc' => 'Deep pink',

                'out' => $csi . '48:2:255:20:147m',
            },
            'B_DEEP SAFFRON' => {
                'desc' => 'Deep saffron',

                'out' => $csi . '48:2:255:153:51m',
            },
            'B_DEEP SKY BLUE' => {
                'desc' => 'Deep sky blue',

                'out' => $csi . '48:2:0:191:255m',
            },
            'B_DENIM' => {
                'desc' => 'Denim',

                'out' => $csi . '48:2:21:96:189m',
            },
            'B_DESERT' => {
                'desc' => 'Desert',

                'out' => $csi . '48:2:193:154:107m',
            },
            'B_DESERT SAND' => {
                'desc' => 'Desert sand',

                'out' => $csi . '48:2:237:201:175m',
            },
            'B_DIM GRAY' => {
                'desc' => 'Dim gray',

                'out' => $csi . '48:2:105:105:105m',
            },
            'B_DODGER BLUE' => {
                'desc' => 'Dodger blue',

                'out' => $csi . '48:2:30:144:255m',
            },
            'B_DOGWOOD ROSE' => {
                'desc' => 'Dogwood rose',

                'out' => $csi . '48:2:215:24:104m',
            },
            'B_DOLLAR BILL' => {
                'desc' => 'Dollar bill',

                'out' => $csi . '48:2:133:187:101m',
            },
            'B_DRAB' => {
                'desc' => 'Drab',

                'out' => $csi . '48:2:150:113:23m',
            },
            'B_DUKE BLUE' => {
                'desc' => 'Duke blue',

                'out' => $csi . '48:2:0:0:156m',
            },
            'B_EARTH YELLOW' => {
                'desc' => 'Earth yellow',

                'out' => $csi . '48:2:225:169:95m',
            },
            'B_ECRU' => {
                'desc' => 'Ecru',

                'out' => $csi . '48:2:194:178:128m',
            },
            'B_EGGPLANT' => {
                'desc' => 'Eggplant',

                'out' => $csi . '48:2:97:64:81m',
            },
            'B_EGGSHELL' => {
                'desc' => 'Eggshell',

                'out' => $csi . '48:2:240:234:214m',
            },
            'B_EGYPTIAN BLUE' => {
                'desc' => 'Egyptian blue',

                'out' => $csi . '48:2:16:52:166m',
            },
            'B_ELECTRIC BLUE' => {
                'desc' => 'Electric blue',

                'out' => $csi . '48:2:125:249:255m',
            },
            'B_ELECTRIC CRIMSON' => {
                'desc' => 'Electric crimson',

                'out' => $csi . '48:2:255:0:63m',
            },
            'B_ELECTRIC CYAN' => {
                'desc' => 'Electric cyan',

                'out' => $csi . '48:2:0:255:255m',
            },
            'B_ELECTRIC GREEN' => {
                'desc' => 'Electric green',

                'out' => $csi . '48:2:0:255:0m',
            },
            'B_ELECTRIC INDIGO' => {
                'desc' => 'Electric indigo',

                'out' => $csi . '48:2:111:0:255m',
            },
            'B_ELECTRIC LAVENDER' => {
                'desc' => 'Electric lavender',

                'out' => $csi . '48:2:244:187:255m',
            },
            'B_ELECTRIC LIME' => {
                'desc' => 'Electric lime',

                'out' => $csi . '48:2:204:255:0m',
            },
            'B_ELECTRIC PURPLE' => {
                'desc' => 'Electric purple',

                'out' => $csi . '48:2:191:0:255m',
            },
            'B_ELECTRIC ULTRAMARINE' => {
                'desc' => 'Electric ultramarine',

                'out' => $csi . '48:2:63:0:255m',
            },
            'B_ELECTRIC VIOLET' => {
                'desc' => 'Electric violet',

                'out' => $csi . '48:2:143:0:255m',
            },
            'B_ELECTRIC YELLOW' => {
                'desc' => 'Electric yellow',

                'out' => $csi . '48:2:255:255:0m',
            },
            'B_EMERALD' => {
                'desc' => 'Emerald',

                'out' => $csi . '48:2:80:200:120m',
            },
            'B_ETON BLUE' => {
                'desc' => 'Eton blue',

                'out' => $csi . '48:2:150:200:162m',
            },
            'B_FALLOW' => {
                'desc' => 'Fallow',

                'out' => $csi . '48:2:193:154:107m',
            },
            'B_FALU RED' => {
                'desc' => 'Falu red',

                'out' => $csi . '48:2:128:24:24m',
            },
            'B_FAMOUS' => {
                'desc' => 'Famous',

                'out' => $csi . '48:2:255:0:255m',
            },
            'B_FANDANGO' => {
                'desc' => 'Fandango',

                'out' => $csi . '48:2:181:51:137m',
            },
            'B_FASHION FUCHSIA' => {
                'desc' => 'Fashion fuchsia',

                'out' => $csi . '48:2:244:0:161m',
            },
            'B_FAWN' => {
                'desc' => 'Fawn',

                'out' => $csi . '48:2:229:170:112m',
            },
            'B_FELDGRAU' => {
                'desc' => 'Feldgrau',

                'out' => $csi . '48:2:77:93:83m',
            },
            'B_FERN' => {
                'desc' => 'Fern',

                'out' => $csi . '48:2:113:188:120m',
            },
            'B_FERN GREEN' => {
                'desc' => 'Fern green',

                'out' => $csi . '48:2:79:121:66m',
            },
            'B_FERRARI RED' => {
                'desc' => 'Ferrari Red',

                'out' => $csi . '48:2:255:40:0m',
            },
            'B_FIELD DRAB' => {
                'desc' => 'Field drab',

                'out' => $csi . '48:2:108:84:30m',
            },
            'B_FIRE ENGINE RED' => {
                'desc' => 'Fire engine red',

                'out' => $csi . '48:2:206:32:41m',
            },
            'B_FIREBRICK' => {
                'desc' => 'Firebrick',

                'out' => $csi . '48:2:178:34:34m',
            },
            'B_FLAME' => {
                'desc' => 'Flame',

                'out' => $csi . '48:2:226:88:34m',
            },
            'B_FLAMINGO PINK' => {
                'desc' => 'Flamingo pink',

                'out' => $csi . '48:2:252:142:172m',
            },
            'B_FLAVESCENT' => {
                'desc' => 'Flavescent',

                'out' => $csi . '48:2:247:233:142m',
            },
            'B_FLAX' => {
                'desc' => 'Flax',

                'out' => $csi . '48:2:238:220:130m',
            },
            'B_FLORAL WHITE' => {
                'desc' => 'Floral white',

                'out' => $csi . '48:2:255:250:240m',
            },
            'B_FLUORESCENT ORANGE' => {
                'desc' => 'Fluorescent orange',

                'out' => $csi . '48:2:255:191:0m',
            },
            'B_FLUORESCENT PINK' => {
                'desc' => 'Fluorescent pink',

                'out' => $csi . '48:2:255:20:147m',
            },
            'B_FLUORESCENT YELLOW' => {
                'desc' => 'Fluorescent yellow',

                'out' => $csi . '48:2:204:255:0m',
            },
            'B_FOLLY' => {
                'desc' => 'Folly',

                'out' => $csi . '48:2:255:0:79m',
            },
            'B_FOREST GREEN' => {
                'desc' => 'Forest green',

                'out' => $csi . '48:2:34:139:34m',
            },
            'B_FRENCH BEIGE' => {
                'desc' => 'French beige',

                'out' => $csi . '48:2:166:123:91m',
            },
            'B_FRENCH BLUE' => {
                'desc' => 'French blue',

                'out' => $csi . '48:2:0:114:187m',
            },
            'B_FRENCH LILAC' => {
                'desc' => 'French lilac',

                'out' => $csi . '48:2:134:96:142m',
            },
            'B_FRENCH ROSE' => {
                'desc' => 'French rose',

                'out' => $csi . '48:2:246:74:138m',
            },
            'B_FUCHSIA' => {
                'desc' => 'Fuchsia',

                'out' => $csi . '48:2:255:0:255m',
            },
            'B_FUCHSIA PINK' => {
                'desc' => 'Fuchsia pink',

                'out' => $csi . '48:2:255:119:255m',
            },
            'B_FULVOUS' => {
                'desc' => 'Fulvous',

                'out' => $csi . '48:2:228:132:0m',
            },
            'B_FUZZY WUZZY' => {
                'desc' => 'Fuzzy Wuzzy',

                'out' => $csi . '48:2:204:102:102m',
            },
            'B_GAINSBORO' => {
                'desc' => 'Gainsboro',

                'out' => $csi . '48:2:220:220:220m',
            },
            'B_GAMBOGE' => {
                'desc' => 'Gamboge',

                'out' => $csi . '48:2:228:155:15m',
            },
            'B_GHOST WHITE' => {
                'desc' => 'Ghost white',

                'out' => $csi . '48:2:248:248:255m',
            },
            'B_GINGER' => {
                'desc' => 'Ginger',

                'out' => $csi . '48:2:176:101:0m',
            },
            'B_GLAUCOUS' => {
                'desc' => 'Glaucous',

                'out' => $csi . '48:2:96:130:182m',
            },
            'B_GLITTER' => {
                'desc' => 'Glitter',

                'out' => $csi . '48:2:230:232:250m',
            },
            'B_GOLD' => {
                'desc' => 'Gold',

                'out' => $csi . '48:2:255:215:0m',
            },
            'B_GOLDEN BROWN' => {
                'desc' => 'Golden brown',

                'out' => $csi . '48:2:153:101:21m',
            },
            'B_GOLDEN POPPY' => {
                'desc' => 'Golden poppy',

                'out' => $csi . '48:2:252:194:0m',
            },
            'B_GOLDEN YELLOW' => {
                'desc' => 'Golden yellow',

                'out' => $csi . '48:2:255:223:0m',
            },
            'B_GOLDENROD' => {
                'desc' => 'Goldenrod',

                'out' => $csi . '48:2:218:165:32m',
            },
            'B_GRANNY SMITH APPLE' => {
                'desc' => 'Granny Smith Apple',

                'out' => $csi . '48:2:168:228:160m',
            },
            'B_GRAY' => {
                'desc' => 'Gray',

                'out' => $csi . '48:2:128:128:128m',
            },
            'B_GRAY ASPARAGUS' => {
                'desc' => 'Gray asparagus',

                'out' => $csi . '48:2:70:89:69m',
            },
            'B_GREEN BLUE' => {
                'desc' => 'Green Blue',

                'out' => $csi . '48:2:17:100:180m',
            },
            'B_GREEN YELLOW' => {
                'desc' => 'Green yellow',

                'out' => $csi . '48:2:173:255:47m',
            },
            'B_GRULLO' => {
                'desc' => 'Grullo',

                'out' => $csi . '48:2:169:154:134m',
            },
            'B_GUPPIE GREEN' => {
                'desc' => 'Guppie green',

                'out' => $csi . '48:2:0:255:127m',
            },
            'B_HALAYA UBE' => {
                'desc' => 'Halaya ube',

                'out' => $csi . '48:2:102:56:84m',
            },
            'B_HAN BLUE' => {
                'desc' => 'Han blue',

                'out' => $csi . '48:2:68:108:207m',
            },
            'B_HAN PURPLE' => {
                'desc' => 'Han purple',

                'out' => $csi . '48:2:82:24:250m',
            },
            'B_HANSA YELLOW' => {
                'desc' => 'Hansa yellow',

                'out' => $csi . '48:2:233:214:107m',
            },
            'B_HARLEQUIN' => {
                'desc' => 'Harlequin',

                'out' => $csi . '48:2:63:255:0m',
            },
            'B_HARVARD CRIMSON' => {
                'desc' => 'Harvard crimson',

                'out' => $csi . '48:2:201:0:22m',
            },
            'B_HARVEST GOLD' => {
                'desc' => 'Harvest Gold',

                'out' => $csi . '48:2:218:145:0m',
            },
            'B_HEART GOLD' => {
                'desc' => 'Heart Gold',

                'out' => $csi . '48:2:128:128:0m',
            },
            'B_HELIOTROPE' => {
                'desc' => 'Heliotrope',

                'out' => $csi . '48:2:223:115:255m',
            },
            'B_HOLLYWOOD CERISE' => {
                'desc' => 'Hollywood cerise',

                'out' => $csi . '48:2:244:0:161m',
            },
            'B_HONEYDEW' => {
                'desc' => 'Honeydew',

                'out' => $csi . '48:2:240:255:240m',
            },
            'B_HOOKER GREEN' => {
                'desc' => 'Hooker green',

                'out' => $csi . '48:2:73:121:107m',
            },
            'B_HOT MAGENTA' => {
                'desc' => 'Hot magenta',

                'out' => $csi . '48:2:255:29:206m',
            },
            'B_HOT PINK' => {
                'desc' => 'Hot pink',

                'out' => $csi . '48:2:255:105:180m',
            },
            'B_HUNTER GREEN' => {
                'desc' => 'Hunter green',

                'out' => $csi . '48:2:53:94:59m',
            },
            'B_ICTERINE' => {
                'desc' => 'Icterine',

                'out' => $csi . '48:2:252:247:94m',
            },
            'B_INCHWORM' => {
                'desc' => 'Inchworm',

                'out' => $csi . '48:2:178:236:93m',
            },
            'B_INDIA GREEN' => {
                'desc' => 'India green',

                'out' => $csi . '48:2:19:136:8m',
            },
            'B_INDIAN RED' => {
                'desc' => 'Indian red',

                'out' => $csi . '48:2:205:92:92m',
            },
            'B_INDIAN YELLOW' => {
                'desc' => 'Indian yellow',

                'out' => $csi . '48:2:227:168:87m',
            },
            'B_INDIGO' => {
                'desc' => 'Indigo',

                'out' => $csi . '48:2:75:0:130m',
            },
            'B_INTERNATIONAL KLEIN' => {
                'desc' => 'International Klein',

                'out' => $csi . '48:2:0:47:167m',
            },
            'B_INTERNATIONAL ORANGE' => {
                'desc' => 'International orange',

                'out' => $csi . '48:2:255:79:0m',
            },
            'B_IRIS' => {
                'desc' => 'Iris',

                'out' => $csi . '48:2:90:79:207m',
            },
            'B_ISABELLINE' => {
                'desc' => 'Isabelline',

                'out' => $csi . '48:2:244:240:236m',
            },
            'B_ISLAMIC GREEN' => {
                'desc' => 'Islamic green',

                'out' => $csi . '48:2:0:144:0m',
            },
            'B_IVORY' => {
                'desc' => 'Ivory',

                'out' => $csi . '48:2:255:255:240m',
            },
            'B_JADE' => {
                'desc' => 'Jade',

                'out' => $csi . '48:2:0:168:107m',
            },
            'B_JASMINE' => {
                'desc' => 'Jasmine',

                'out' => $csi . '48:2:248:222:126m',
            },
            'B_JASPER' => {
                'desc' => 'Jasper',

                'out' => $csi . '48:2:215:59:62m',
            },
            'B_JAZZBERRY JAM' => {
                'desc' => 'Jazzberry jam',

                'out' => $csi . '48:2:165:11:94m',
            },
            'B_JONQUIL' => {
                'desc' => 'Jonquil',

                'out' => $csi . '48:2:250:218:94m',
            },
            'B_JUNE BUD' => {
                'desc' => 'June bud',

                'out' => $csi . '48:2:189:218:87m',
            },
            'B_JUNGLE GREEN' => {
                'desc' => 'Jungle green',

                'out' => $csi . '48:2:41:171:135m',
            },
            'B_KELLY GREEN' => {
                'desc' => 'Kelly green',

                'out' => $csi . '48:2:76:187:23m',
            },
            'B_KHAKI' => {
                'desc' => 'Khaki',

                'out' => $csi . '48:2:195:176:145m',
            },
            'B_KU CRIMSON' => {
                'desc' => 'KU Crimson',

                'out' => $csi . '48:2:232:0:13m',
            },
            'B_LA SALLE GREEN' => {
                'desc' => 'La Salle Green',

                'out' => $csi . '48:2:8:120:48m',
            },
            'B_LANGUID LAVENDER' => {
                'desc' => 'Languid lavender',

                'out' => $csi . '48:2:214:202:221m',
            },
            'B_LAPIS LAZULI' => {
                'desc' => 'Lapis lazuli',

                'out' => $csi . '48:2:38:97:156m',
            },
            'B_LASER LEMON' => {
                'desc' => 'Laser Lemon',

                'out' => $csi . '48:2:254:254:34m',
            },
            'B_LAUREL GREEN' => {
                'desc' => 'Laurel green',

                'out' => $csi . '48:2:169:186:157m',
            },
            'B_LAVA' => {
                'desc' => 'Lava',

                'out' => $csi . '48:2:207:16:32m',
            },
            'B_LAVENDER' => {
                'desc' => 'Lavender',

                'out' => $csi . '48:2:230:230:250m',
            },
            'B_LAVENDER BLUE' => {
                'desc' => 'Lavender blue',

                'out' => $csi . '48:2:204:204:255m',
            },
            'B_LAVENDER BLUSH' => {
                'desc' => 'Lavender blush',

                'out' => $csi . '48:2:255:240:245m',
            },
            'B_LAVENDER GRAY' => {
                'desc' => 'Lavender gray',

                'out' => $csi . '48:2:196:195:208m',
            },
            'B_LAVENDER INDIGO' => {
                'desc' => 'Lavender indigo',

                'out' => $csi . '48:2:148:87:235m',
            },
            'B_LAVENDER MAGENTA' => {
                'desc' => 'Lavender magenta',

                'out' => $csi . '48:2:238:130:238m',
            },
            'B_LAVENDER MIST' => {
                'desc' => 'Lavender mist',

                'out' => $csi . '48:2:230:230:250m',
            },
            'B_LAVENDER PINK' => {
                'desc' => 'Lavender pink',

                'out' => $csi . '48:2:251:174:210m',
            },
            'B_LAVENDER PURPLE' => {
                'desc' => 'Lavender purple',

                'out' => $csi . '48:2:150:123:182m',
            },
            'B_LAVENDER ROSE' => {
                'desc' => 'Lavender rose',

                'out' => $csi . '48:2:251:160:227m',
            },
            'B_LAWN GREEN' => {
                'desc' => 'Lawn green',

                'out' => $csi . '48:2:124:252:0m',
            },
            'B_LEMON' => {
                'desc' => 'Lemon',

                'out' => $csi . '48:2:255:247:0m',
            },
            'B_LEMON CHIFFON' => {
                'desc' => 'Lemon chiffon',

                'out' => $csi . '48:2:255:250:205m',
            },
            'B_LEMON LIME' => {
                'desc' => 'Lemon lime',

                'out' => $csi . '48:2:191:255:0m',
            },
            'B_LEMON YELLOW' => {
                'desc' => 'Lemon Yellow',

                'out' => $csi . '48:2:255:244:79m',
            },
            'B_LIGHT APRICOT' => {
                'desc' => 'Light apricot',

                'out' => $csi . '48:2:253:213:177m',
            },
            'B_LIGHT BLUE' => {
                'desc' => 'Light blue',

                'out' => $csi . '48:2:173:216:230m',
            },
            'B_LIGHT BROWN' => {
                'desc' => 'Light brown',

                'out' => $csi . '48:2:181:101:29m',
            },
            'B_LIGHT CARMINE PINK' => {
                'desc' => 'Light carmine pink',

                'out' => $csi . '48:2:230:103:113m',
            },
            'B_LIGHT CORAL' => {
                'desc' => 'Light coral',

                'out' => $csi . '48:2:240:128:128m',
            },
            'B_LIGHT CORNFLOWER BLUE' => {
                'desc' => 'Light cornflower blue',

                'out' => $csi . '48:2:147:204:234m',
            },
            'B_LIGHT CRIMSON' => {
                'desc' => 'Light Crimson',

                'out' => $csi . '48:2:245:105:145m',
            },
            'B_LIGHT CYAN' => {
                'desc' => 'Light cyan',

                'out' => $csi . '48:2:224:255:255m',
            },
            'B_LIGHT FUCHSIA PINK' => {
                'desc' => 'Light fuchsia pink',

                'out' => $csi . '48:2:249:132:239m',
            },
            'B_LIGHT GOLDENROD YELLOW' => {
                'desc' => 'Light goldenrod yellow',

                'out' => $csi . '48:2:250:250:210m',
            },
            'B_LIGHT GRAY' => {
                'desc' => 'Light gray',

                'out' => $csi . '48:2:211:211:211m',
            },
            'B_LIGHT GREEN' => {
                'desc' => 'Light green',

                'out' => $csi . '48:2:144:238:144m',
            },
            'B_LIGHT KHAKI' => {
                'desc' => 'Light khaki',

                'out' => $csi . '48:2:240:230:140m',
            },
            'B_LIGHT PASTEL PURPLE' => {
                'desc' => 'Light pastel purple',

                'out' => $csi . '48:2:177:156:217m',
            },
            'B_LIGHT PINK' => {
                'desc' => 'Light pink',

                'out' => $csi . '48:2:255:182:193m',
            },
            'B_LIGHT SALMON' => {
                'desc' => 'Light salmon',

                'out' => $csi . '48:2:255:160:122m',
            },
            'B_LIGHT SALMON PINK' => {
                'desc' => 'Light salmon pink',

                'out' => $csi . '48:2:255:153:153m',
            },
            'B_LIGHT SEA GREEN' => {
                'desc' => 'Light sea green',

                'out' => $csi . '48:2:32:178:170m',
            },
            'B_LIGHT SKY BLUE' => {
                'desc' => 'Light sky blue',

                'out' => $csi . '48:2:135:206:250m',
            },
            'B_LIGHT SLATE GRAY' => {
                'desc' => 'Light slate gray',

                'out' => $csi . '48:2:119:136:153m',
            },
            'B_LIGHT TAUPE' => {
                'desc' => 'Light taupe',

                'out' => $csi . '48:2:179:139:109m',
            },
            'B_LIGHT THULIAN PINK' => {
                'desc' => 'Light Thulian pink',

                'out' => $csi . '48:2:230:143:172m',
            },
            'B_LIGHT YELLOW' => {
                'desc' => 'Light yellow',

                'out' => $csi . '48:2:255:255:237m',
            },
            'B_LILAC' => {
                'desc' => 'Lilac',

                'out' => $csi . '48:2:200:162:200m',
            },
            'B_LIME' => {
                'desc' => 'Lime',

                'out' => $csi . '48:2:191:255:0m',
            },
            'B_LIME GREEN' => {
                'desc' => 'Lime green',

                'out' => $csi . '48:2:50:205:50m',
            },
            'B_LINCOLN GREEN' => {
                'desc' => 'Lincoln green',

                'out' => $csi . '48:2:25:89:5m',
            },
            'B_LINEN' => {
                'desc' => 'Linen',

                'out' => $csi . '48:2:250:240:230m',
            },
            'B_LION' => {
                'desc' => 'Lion',

                'out' => $csi . '48:2:193:154:107m',
            },
            'B_LIVER' => {
                'desc' => 'Liver',

                'out' => $csi . '48:2:83:75:79m',
            },
            'B_LUST' => {
                'desc' => 'Lust',

                'out' => $csi . '48:2:230:32:32m',
            },
            'B_MACARONI AND CHEESE' => {
                'desc' => 'Macaroni and Cheese',

                'out' => $csi . '48:2:255:189:136m',
            },
            'B_MAGENTA' => {
                'desc' => 'Magenta',

                'out' => $csi . '48:2:255:0:255m',
            },
            'B_MAGIC MINT' => {
                'desc' => 'Magic mint',

                'out' => $csi . '48:2:170:240:209m',
            },
            'B_MAGNOLIA' => {
                'desc' => 'Magnolia',

                'out' => $csi . '48:2:248:244:255m',
            },
            'B_MAHOGANY' => {
                'desc' => 'Mahogany',

                'out' => $csi . '48:2:192:64:0m',
            },
            'B_MAIZE' => {
                'desc' => 'Maize',

                'out' => $csi . '48:2:251:236:93m',
            },
            'B_MAJORELLE BLUE' => {
                'desc' => 'Majorelle Blue',

                'out' => $csi . '48:2:96:80:220m',
            },
            'B_MALACHITE' => {
                'desc' => 'Malachite',

                'out' => $csi . '48:2:11:218:81m',
            },
            'B_MANATEE' => {
                'desc' => 'Manatee',

                'out' => $csi . '48:2:151:154:170m',
            },
            'B_MANGO TANGO' => {
                'desc' => 'Mango Tango',

                'out' => $csi . '48:2:255:130:67m',
            },
            'B_MANTIS' => {
                'desc' => 'Mantis',

                'out' => $csi . '48:2:116:195:101m',
            },
            'B_MAROON' => {
                'desc' => 'Maroon',

                'out' => $csi . '48:2:128:0:0m',
            },
            'B_MAUVE' => {
                'desc' => 'Mauve',

                'out' => $csi . '48:2:224:176:255m',
            },
            'B_MAUVE TAUPE' => {
                'desc' => 'Mauve taupe',

                'out' => $csi . '48:2:145:95:109m',
            },
            'B_MAUVELOUS' => {
                'desc' => 'Mauvelous',

                'out' => $csi . '48:2:239:152:170m',
            },
            'B_MAYA BLUE' => {
                'desc' => 'Maya blue',

                'out' => $csi . '48:2:115:194:251m',
            },
            'B_MEAT BROWN' => {
                'desc' => 'Meat brown',

                'out' => $csi . '48:2:229:183:59m',
            },
            'B_MEDIUM AQUAMARINE' => {
                'desc' => 'Medium aquamarine',

                'out' => $csi . '48:2:102:221:170m',
            },
            'B_MEDIUM BLUE' => {
                'desc' => 'Medium blue',

                'out' => $csi . '48:2:0:0:205m',
            },
            'B_MEDIUM CANDY APPLE RED' => {
                'desc' => 'Medium candy apple red',

                'out' => $csi . '48:2:226:6:44m',
            },
            'B_MEDIUM CARMINE' => {
                'desc' => 'Medium carmine',

                'out' => $csi . '48:2:175:64:53m',
            },
            'B_MEDIUM CHAMPAGNE' => {
                'desc' => 'Medium champagne',

                'out' => $csi . '48:2:243:229:171m',
            },
            'B_MEDIUM ELECTRIC BLUE' => {
                'desc' => 'Medium electric blue',

                'out' => $csi . '48:2:3:80:150m',
            },
            'B_MEDIUM JUNGLE GREEN' => {
                'desc' => 'Medium jungle green',

                'out' => $csi . '48:2:28:53:45m',
            },
            'B_MEDIUM LAVENDER MAGENTA' => {
                'desc' => 'Medium lavender magenta',

                'out' => $csi . '48:2:221:160:221m',
            },
            'B_MEDIUM ORCHID' => {
                'desc' => 'Medium orchid',

                'out' => $csi . '48:2:186:85:211m',
            },
            'B_MEDIUM PERSIAN BLUE' => {
                'desc' => 'Medium Persian blue',

                'out' => $csi . '48:2:0:103:165m',
            },
            'B_MEDIUM PURPLE' => {
                'desc' => 'Medium purple',

                'out' => $csi . '48:2:147:112:219m',
            },
            'B_MEDIUM RED VIOLET' => {
                'desc' => 'Medium red violet',

                'out' => $csi . '48:2:187:51:133m',
            },
            'B_MEDIUM SEA GREEN' => {
                'desc' => 'Medium sea green',

                'out' => $csi . '48:2:60:179:113m',
            },
            'B_MEDIUM SLATE BLUE' => {
                'desc' => 'Medium slate blue',

                'out' => $csi . '48:2:123:104:238m',
            },
            'B_MEDIUM SPRING BUD' => {
                'desc' => 'Medium spring bud',

                'out' => $csi . '48:2:201:220:135m',
            },
            'B_MEDIUM SPRING GREEN' => {
                'desc' => 'Medium spring green',

                'out' => $csi . '48:2:0:250:154m',
            },
            'B_MEDIUM TAUPE' => {
                'desc' => 'Medium taupe',

                'out' => $csi . '48:2:103:76:71m',
            },
            'B_MEDIUM TEAL BLUE' => {
                'desc' => 'Medium teal blue',

                'out' => $csi . '48:2:0:84:180m',
            },
            'B_MEDIUM TURQUOISE' => {
                'desc' => 'Medium turquoise',

                'out' => $csi . '48:2:72:209:204m',
            },
            'B_MEDIUM VIOLET RED' => {
                'desc' => 'Medium violet red',

                'out' => $csi . '48:2:199:21:133m',
            },
            'B_MELON' => {
                'desc' => 'Melon',

                'out' => $csi . '48:2:253:188:180m',
            },
            'B_MIDNIGHT BLUE' => {
                'desc' => 'Midnight blue',

                'out' => $csi . '48:2:25:25:112m',
            },
            'B_MIDNIGHT GREEN' => {
                'desc' => 'Midnight green',

                'out' => $csi . '48:2:0:73:83m',
            },
            'B_MIKADO YELLOW' => {
                'desc' => 'Mikado yellow',

                'out' => $csi . '48:2:255:196:12m',
            },
            'B_MINT' => {
                'desc' => 'Mint',

                'out' => $csi . '48:2:62:180:137m',
            },
            'B_MINT CREAM' => {
                'desc' => 'Mint cream',

                'out' => $csi . '48:2:245:255:250m',
            },
            'B_MINT GREEN' => {
                'desc' => 'Mint green',

                'out' => $csi . '48:2:152:255:152m',
            },
            'B_MISTY ROSE' => {
                'desc' => 'Misty rose',

                'out' => $csi . '48:2:255:228:225m',
            },
            'B_MOCCASIN' => {
                'desc' => 'Moccasin',

                'out' => $csi . '48:2:250:235:215m',
            },
            'B_MODE BEIGE' => {
                'desc' => 'Mode beige',

                'out' => $csi . '48:2:150:113:23m',
            },
            'B_MOONSTONE BLUE' => {
                'desc' => 'Moonstone blue',

                'out' => $csi . '48:2:115:169:194m',
            },
            'B_MORDANT RED 19' => {
                'desc' => 'Mordant red 19',

                'out' => $csi . '48:2:174:12:0m',
            },
            'B_MOSS GREEN' => {
                'desc' => 'Moss green',

                'out' => $csi . '48:2:173:223:173m',
            },
            'B_MOUNTAIN MEADOW' => {
                'desc' => 'Mountain Meadow',

                'out' => $csi . '48:2:48:186:143m',
            },
            'B_MOUNTBATTEN PINK' => {
                'desc' => 'Mountbatten pink',

                'out' => $csi . '48:2:153:122:141m',
            },
            'B_MSU GREEN' => {
                'desc' => 'MSU Green',

                'out' => $csi . '48:2:24:69:59m',
            },
            'B_MULBERRY' => {
                'desc' => 'Mulberry',

                'out' => $csi . '48:2:197:75:140m',
            },
            'B_MUNSELL' => {
                'desc' => 'Munsell',

                'out' => $csi . '48:2:242:243:244m',
            },
            'B_MUSTARD' => {
                'desc' => 'Mustard',

                'out' => $csi . '48:2:255:219:88m',
            },
            'B_MYRTLE' => {
                'desc' => 'Myrtle',

                'out' => $csi . '48:2:33:66:30m',
            },
            'B_NADESHIKO PINK' => {
                'desc' => 'Nadeshiko pink',

                'out' => $csi . '48:2:246:173:198m',
            },
            'B_NAPIER GREEN' => {
                'desc' => 'Napier green',

                'out' => $csi . '48:2:42:128:0m',
            },
            'B_NAPLES YELLOW' => {
                'desc' => 'Naples yellow',

                'out' => $csi . '48:2:250:218:94m',
            },
            'B_NAVAJO WHITE' => {
                'desc' => 'Navajo white',

                'out' => $csi . '48:2:255:222:173m',
            },
            'B_NAVY BLUE' => {
                'desc' => 'Navy blue',

                'out' => $csi . '48:2:0:0:128m',
            },
            'B_NEON CARROT' => {
                'desc' => 'Neon Carrot',

                'out' => $csi . '48:2:255:163:67m',
            },
            'B_NEON FUCHSIA' => {
                'desc' => 'Neon fuchsia',

                'out' => $csi . '48:2:254:89:194m',
            },
            'B_NEON GREEN' => {
                'desc' => 'Neon green',

                'out' => $csi . '48:2:57:255:20m',
            },
            'B_NON-PHOTO BLUE' => {
                'desc' => 'Non-photo blue',

                'out' => $csi . '48:2:164:221:237m',
            },
            'B_NORTH TEXAS GREEN' => {
                'desc' => 'North Texas Green',

                'out' => $csi . '48:2:5:144:51m',
            },
            'B_OCEAN BOAT BLUE' => {
                'desc' => 'Ocean Boat Blue',

                'out' => $csi . '48:2:0:119:190m',
            },
            'B_OCHRE' => {
                'desc' => 'Ochre',

                'out' => $csi . '48:2:204:119:34m',
            },
            'B_OFFICE GREEN' => {
                'desc' => 'Office green',

                'out' => $csi . '48:2:0:128:0m',
            },
            'B_OLD GOLD' => {
                'desc' => 'Old gold',

                'out' => $csi . '48:2:207:181:59m',
            },
            'B_OLD LACE' => {
                'desc' => 'Old lace',

                'out' => $csi . '48:2:253:245:230m',
            },
            'B_OLD LAVENDER' => {
                'desc' => 'Old lavender',

                'out' => $csi . '48:2:121:104:120m',
            },
            'B_OLD MAUVE' => {
                'desc' => 'Old mauve',

                'out' => $csi . '48:2:103:49:71m',
            },
            'B_OLD ROSE' => {
                'desc' => 'Old rose',

                'out' => $csi . '48:2:192:128:129m',
            },
            'B_OLIVE' => {
                'desc' => 'Olive',

                'out' => $csi . '48:2:128:128:0m',
            },
            'B_OLIVE DRAB' => {
                'desc' => 'Olive Drab',

                'out' => $csi . '48:2:107:142:35m',
            },
            'B_OLIVE GREEN' => {
                'desc' => 'Olive Green',

                'out' => $csi . '48:2:186:184:108m',
            },
            'B_OLIVINE' => {
                'desc' => 'Olivine',

                'out' => $csi . '48:2:154:185:115m',
            },
            'B_ONYX' => {
                'desc' => 'Onyx',

                'out' => $csi . '48:2:15:15:15m',
            },
            'B_OPERA MAUVE' => {
                'desc' => 'Opera mauve',

                'out' => $csi . '48:2:183:132:167m',
            },
            'B_ORANGE PEEL' => {
                'desc' => 'Orange peel',

                'out' => $csi . '48:2:255:159:0m',
            },
            'B_ORANGE RED' => {
                'desc' => 'Orange red',

                'out' => $csi . '48:2:255:69:0m',
            },
            'B_ORANGE YELLOW' => {
                'desc' => 'Orange Yellow',

                'out' => $csi . '48:2:248:213:104m',
            },
            'B_ORCHID' => {
                'desc' => 'Orchid',

                'out' => $csi . '48:2:218:112:214m',
            },
            'B_OTTER BROWN' => {
                'desc' => 'Otter brown',

                'out' => $csi . '48:2:101:67:33m',
            },
            'B_OUTER SPACE' => {
                'desc' => 'Outer Space',

                'out' => $csi . '48:2:65:74:76m',
            },
            'B_OUTRAGEOUS ORANGE' => {
                'desc' => 'Outrageous Orange',

                'out' => $csi . '48:2:255:110:74m',
            },
            'B_OXFORD BLUE' => {
                'desc' => 'Oxford Blue',

                'out' => $csi . '48:2:0:33:71m',
            },
            'B_PACIFIC BLUE' => {
                'desc' => 'Pacific Blue',

                'out' => $csi . '48:2:28:169:201m',
            },
            'B_PAKISTAN GREEN' => {
                'desc' => 'Pakistan green',

                'out' => $csi . '48:2:0:102:0m',
            },
            'B_PALATINATE BLUE' => {
                'desc' => 'Palatinate blue',

                'out' => $csi . '48:2:39:59:226m',
            },
            'B_PALATINATE PURPLE' => {
                'desc' => 'Palatinate purple',

                'out' => $csi . '48:2:104:40:96m',
            },
            'B_PALE AQUA' => {
                'desc' => 'Pale aqua',

                'out' => $csi . '48:2:188:212:230m',
            },
            'B_PALE BLUE' => {
                'desc' => 'Pale blue',

                'out' => $csi . '48:2:175:238:238m',
            },
            'B_PALE BROWN' => {
                'desc' => 'Pale brown',

                'out' => $csi . '48:2:152:118:84m',
            },
            'B_PALE CARMINE' => {
                'desc' => 'Pale carmine',

                'out' => $csi . '48:2:175:64:53m',
            },
            'B_PALE CERULEAN' => {
                'desc' => 'Pale cerulean',

                'out' => $csi . '48:2:155:196:226m',
            },
            'B_PALE CHESTNUT' => {
                'desc' => 'Pale chestnut',

                'out' => $csi . '48:2:221:173:175m',
            },
            'B_PALE COPPER' => {
                'desc' => 'Pale copper',

                'out' => $csi . '48:2:218:138:103m',
            },
            'B_PALE CORNFLOWER BLUE' => {
                'desc' => 'Pale cornflower blue',

                'out' => $csi . '48:2:171:205:239m',
            },
            'B_PALE GOLD' => {
                'desc' => 'Pale gold',

                'out' => $csi . '48:2:230:190:138m',
            },
            'B_PALE GOLDENROD' => {
                'desc' => 'Pale goldenrod',

                'out' => $csi . '48:2:238:232:170m',
            },
            'B_PALE GREEN' => {
                'desc' => 'Pale green',

                'out' => $csi . '48:2:152:251:152m',
            },
            'B_PALE LAVENDER' => {
                'desc' => 'Pale lavender',

                'out' => $csi . '48:2:220:208:255m',
            },
            'B_PALE MAGENTA' => {
                'desc' => 'Pale magenta',

                'out' => $csi . '48:2:249:132:229m',
            },
            'B_PALE PINK' => {
                'desc' => 'Pale pink',

                'out' => $csi . '48:2:250:218:221m',
            },
            'B_PALE PLUM' => {
                'desc' => 'Pale plum',

                'out' => $csi . '48:2:221:160:221m',
            },
            'B_PALE RED VIOLET' => {
                'desc' => 'Pale red violet',

                'out' => $csi . '48:2:219:112:147m',
            },
            'B_PALE ROBIN EGG BLUE' => {
                'desc' => 'Pale robin egg blue',

                'out' => $csi . '48:2:150:222:209m',
            },
            'B_PALE SILVER' => {
                'desc' => 'Pale silver',

                'out' => $csi . '48:2:201:192:187m',
            },
            'B_PALE SPRING BUD' => {
                'desc' => 'Pale spring bud',

                'out' => $csi . '48:2:236:235:189m',
            },
            'B_PALE TAUPE' => {
                'desc' => 'Pale taupe',

                'out' => $csi . '48:2:188:152:126m',
            },
            'B_PALE VIOLET RED' => {
                'desc' => 'Pale violet red',

                'out' => $csi . '48:2:219:112:147m',
            },
            'B_PANSY PURPLE' => {
                'desc' => 'Pansy purple',

                'out' => $csi . '48:2:120:24:74m',
            },
            'B_PAPAYA WHIP' => {
                'desc' => 'Papaya whip',

                'out' => $csi . '48:2:255:239:213m',
            },
            'B_PARIS GREEN' => {
                'desc' => 'Paris Green',

                'out' => $csi . '48:2:80:200:120m',
            },
            'B_PASTEL BLUE' => {
                'desc' => 'Pastel blue',

                'out' => $csi . '48:2:174:198:207m',
            },
            'B_PASTEL BROWN' => {
                'desc' => 'Pastel brown',

                'out' => $csi . '48:2:131:105:83m',
            },
            'B_PASTEL GRAY' => {
                'desc' => 'Pastel gray',

                'out' => $csi . '48:2:207:207:196m',
            },
            'B_PASTEL GREEN' => {
                'desc' => 'Pastel green',

                'out' => $csi . '48:2:119:221:119m',
            },
            'B_PASTEL MAGENTA' => {
                'desc' => 'Pastel magenta',

                'out' => $csi . '48:2:244:154:194m',
            },
            'B_PASTEL ORANGE' => {
                'desc' => 'Pastel orange',

                'out' => $csi . '48:2:255:179:71m',
            },
            'B_PASTEL PINK' => {
                'desc' => 'Pastel pink',

                'out' => $csi . '48:2:255:209:220m',
            },
            'B_PASTEL PURPLE' => {
                'desc' => 'Pastel purple',

                'out' => $csi . '48:2:179:158:181m',
            },
            'B_PASTEL RED' => {
                'desc' => 'Pastel red',

                'out' => $csi . '48:2:255:105:97m',
            },
            'B_PASTEL VIOLET' => {
                'desc' => 'Pastel violet',

                'out' => $csi . '48:2:203:153:201m',
            },
            'B_PASTEL YELLOW' => {
                'desc' => 'Pastel yellow',

                'out' => $csi . '48:2:253:253:150m',
            },
            'B_PATRIARCH' => {
                'desc' => 'Patriarch',

                'out' => $csi . '48:2:128:0:128m',
            },
            'B_PAYNE GRAY' => {
                'desc' => 'Payne grey',

                'out' => $csi . '48:2:83:104:120m',
            },
            'B_PEACH' => {
                'desc' => 'Peach',

                'out' => $csi . '48:2:255:229:180m',
            },
            'B_PEACH PUFF' => {
                'desc' => 'Peach puff',

                'out' => $csi . '48:2:255:218:185m',
            },
            'B_PEACH YELLOW' => {
                'desc' => 'Peach yellow',

                'out' => $csi . '48:2:250:223:173m',
            },
            'B_PEAR' => {
                'desc' => 'Pear',

                'out' => $csi . '48:2:209:226:49m',
            },
            'B_PEARL' => {
                'desc' => 'Pearl',

                'out' => $csi . '48:2:234:224:200m',
            },
            'B_PEARL AQUA' => {
                'desc' => 'Pearl Aqua',

                'out' => $csi . '48:2:136:216:192m',
            },
            'B_PERIDOT' => {
                'desc' => 'Peridot',

                'out' => $csi . '48:2:230:226:0m',
            },
            'B_PERIWINKLE' => {
                'desc' => 'Periwinkle',

                'out' => $csi . '48:2:204:204:255m',
            },
            'B_PERSIAN BLUE' => {
                'desc' => 'Persian blue',

                'out' => $csi . '48:2:28:57:187m',
            },
            'B_PERSIAN INDIGO' => {
                'desc' => 'Persian indigo',

                'out' => $csi . '48:2:50:18:122m',
            },
            'B_PERSIAN ORANGE' => {
                'desc' => 'Persian orange',

                'out' => $csi . '48:2:217:144:88m',
            },
            'B_PERSIAN PINK' => {
                'desc' => 'Persian pink',

                'out' => $csi . '48:2:247:127:190m',
            },
            'B_PERSIAN PLUM' => {
                'desc' => 'Persian plum',

                'out' => $csi . '48:2:112:28:28m',
            },
            'B_PERSIAN RED' => {
                'desc' => 'Persian red',

                'out' => $csi . '48:2:204:51:51m',
            },
            'B_PERSIAN ROSE' => {
                'desc' => 'Persian rose',

                'out' => $csi . '48:2:254:40:162m',
            },
            'B_PHLOX' => {
                'desc' => 'Phlox',

                'out' => $csi . '48:2:223:0:255m',
            },
            'B_PHTHALO BLUE' => {
                'desc' => 'Phthalo blue',

                'out' => $csi . '48:2:0:15:137m',
            },
            'B_PHTHALO GREEN' => {
                'desc' => 'Phthalo green',

                'out' => $csi . '48:2:18:53:36m',
            },
            'B_PIGGY PINK' => {
                'desc' => 'Piggy pink',

                'out' => $csi . '48:2:253:221:230m',
            },
            'B_PINE GREEN' => {
                'desc' => 'Pine green',

                'out' => $csi . '48:2:1:121:111m',
            },
            'B_PINK FLAMINGO' => {
                'desc' => 'Pink Flamingo',

                'out' => $csi . '48:2:252:116:253m',
            },
            'B_PINK PEARL' => {
                'desc' => 'Pink pearl',

                'out' => $csi . '48:2:231:172:207m',
            },
            'B_PINK SHERBET' => {
                'desc' => 'Pink Sherbet',

                'out' => $csi . '48:2:247:143:167m',
            },
            'B_PISTACHIO' => {
                'desc' => 'Pistachio',

                'out' => $csi . '48:2:147:197:114m',
            },
            'B_PLATINUM' => {
                'desc' => 'Platinum',

                'out' => $csi . '48:2:229:228:226m',
            },
            'B_PLUM' => {
                'desc' => 'Plum',

                'out' => $csi . '48:2:221:160:221m',
            },
            'B_PORTLAND ORANGE' => {
                'desc' => 'Portland Orange',

                'out' => $csi . '48:2:255:90:54m',
            },
            'B_POWDER BLUE' => {
                'desc' => 'Powder blue',

                'out' => $csi . '48:2:176:224:230m',
            },
            'B_PRINCETON ORANGE' => {
                'desc' => 'Princeton orange',

                'out' => $csi . '48:2:255:143:0m',
            },
            'B_PRUSSIAN BLUE' => {
                'desc' => 'Prussian blue',

                'out' => $csi . '48:2:0:49:83m',
            },
            'B_PSYCHEDELIC PURPLE' => {
                'desc' => 'Psychedelic purple',

                'out' => $csi . '48:2:223:0:255m',
            },
            'B_PUCE' => {
                'desc' => 'Puce',

                'out' => $csi . '48:2:204:136:153m',
            },
            'B_PUMPKIN' => {
                'desc' => 'Pumpkin',

                'out' => $csi . '48:2:255:117:24m',
            },
            'B_PURPLE' => {
                'desc' => 'Purple',

                'out' => $csi . '48:2:128:0:128m',
            },
            'B_PURPLE HEART' => {
                'desc' => 'Purple Heart',

                'out' => $csi . '48:2:105:53:156m',
            },
            'B_PURPLE MOUNTAIN MAJESTY' => {
                'desc' => 'Purple mountain majesty',

                'out' => $csi . '48:2:150:120:182m',
            },
            'B_PURPLE MOUNTAINS' => {
                'desc' => 'Purple Mountains',

                'out' => $csi . '48:2:157:129:186m',
            },
            'B_PURPLE PIZZAZZ' => {
                'desc' => 'Purple pizzazz',

                'out' => $csi . '48:2:254:78:218m',
            },
            'B_PURPLE TAUPE' => {
                'desc' => 'Purple taupe',

                'out' => $csi . '48:2:80:64:77m',
            },
            'B_RACKLEY' => {
                'desc' => 'Rackley',

                'out' => $csi . '48:2:93:138:168m',
            },
            'B_RADICAL RED' => {
                'desc' => 'Radical Red',

                'out' => $csi . '48:2:255:53:94m',
            },
            'B_RASPBERRY' => {
                'desc' => 'Raspberry',

                'out' => $csi . '48:2:227:11:93m',
            },
            'B_RASPBERRY GLACE' => {
                'desc' => 'Raspberry glace',

                'out' => $csi . '48:2:145:95:109m',
            },
            'B_RASPBERRY PINK' => {
                'desc' => 'Raspberry pink',

                'out' => $csi . '48:2:226:80:152m',
            },
            'B_RASPBERRY ROSE' => {
                'desc' => 'Raspberry rose',

                'out' => $csi . '48:2:179:68:108m',
            },
            'B_RAW SIENNA' => {
                'desc' => 'Raw Sienna',

                'out' => $csi . '48:2:214:138:89m',
            },
            'B_RAZZLE DAZZLE ROSE' => {
                'desc' => 'Razzle dazzle rose',

                'out' => $csi . '48:2:255:51:204m',
            },
            'B_RAZZMATAZZ' => {
                'desc' => 'Razzmatazz',

                'out' => $csi . '48:2:227:37:107m',
            },
            'B_RED BROWN' => {
                'desc' => 'Red brown',

                'out' => $csi . '48:2:165:42:42m',
            },
            'B_RED ORANGE' => {
                'desc' => 'Red Orange',

                'out' => $csi . '48:2:255:83:73m',
            },
            'B_RED VIOLET' => {
                'desc' => 'Red violet',

                'out' => $csi . '48:2:199:21:133m',
            },
            'B_RICH BLACK' => {
                'desc' => 'Rich black',

                'out' => $csi . '48:2:0:64:64m',
            },
            'B_RICH CARMINE' => {
                'desc' => 'Rich carmine',

                'out' => $csi . '48:2:215:0:64m',
            },
            'B_RICH ELECTRIC BLUE' => {
                'desc' => 'Rich electric blue',

                'out' => $csi . '48:2:8:146:208m',
            },
            'B_RICH LILAC' => {
                'desc' => 'Rich lilac',

                'out' => $csi . '48:2:182:102:210m',
            },
            'B_RICH MAROON' => {
                'desc' => 'Rich maroon',

                'out' => $csi . '48:2:176:48:96m',
            },
            'B_RIFLE GREEN' => {
                'desc' => 'Rifle green',

                'out' => $csi . '48:2:65:72:51m',
            },
            'B_ROBINS EGG BLUE' => {
                'desc' => 'Robins Egg Blue',

                'out' => $csi . '48:2:31:206:203m',
            },
            'B_ROSE' => {
                'desc' => 'Rose',

                'out' => $csi . '48:2:255:0:127m',
            },
            'B_ROSE BONBON' => {
                'desc' => 'Rose bonbon',

                'out' => $csi . '48:2:249:66:158m',
            },
            'B_ROSE EBONY' => {
                'desc' => 'Rose ebony',

                'out' => $csi . '48:2:103:72:70m',
            },
            'B_ROSE GOLD' => {
                'desc' => 'Rose gold',

                'out' => $csi . '48:2:183:110:121m',
            },
            'B_ROSE MADDER' => {
                'desc' => 'Rose madder',

                'out' => $csi . '48:2:227:38:54m',
            },
            'B_ROSE PINK' => {
                'desc' => 'Rose pink',

                'out' => $csi . '48:2:255:102:204m',
            },
            'B_ROSE QUARTZ' => {
                'desc' => 'Rose quartz',

                'out' => $csi . '48:2:170:152:169m',
            },
            'B_ROSE TAUPE' => {
                'desc' => 'Rose taupe',

                'out' => $csi . '48:2:144:93:93m',
            },
            'B_ROSE VALE' => {
                'desc' => 'Rose vale',

                'out' => $csi . '48:2:171:78:82m',
            },
            'B_ROSEWOOD' => {
                'desc' => 'Rosewood',

                'out' => $csi . '48:2:101:0:11m',
            },
            'B_ROSSO CORSA' => {
                'desc' => 'Rosso corsa',

                'out' => $csi . '48:2:212:0:0m',
            },
            'B_ROSY BROWN' => {
                'desc' => 'Rosy brown',

                'out' => $csi . '48:2:188:143:143m',
            },
            'B_ROYAL AZURE' => {
                'desc' => 'Royal azure',

                'out' => $csi . '48:2:0:56:168m',
            },
            'B_ROYAL BLUE' => {
                'desc' => 'Royal blue',

                'out' => $csi . '48:2:65:105:225m',
            },
            'B_ROYAL FUCHSIA' => {
                'desc' => 'Royal fuchsia',

                'out' => $csi . '48:2:202:44:146m',
            },
            'B_ROYAL PURPLE' => {
                'desc' => 'Royal purple',

                'out' => $csi . '48:2:120:81:169m',
            },
            'B_RUBY' => {
                'desc' => 'Ruby',

                'out' => $csi . '48:2:224:17:95m',
            },
            'B_RUDDY' => {
                'desc' => 'Ruddy',

                'out' => $csi . '48:2:255:0:40m',
            },
            'B_RUDDY BROWN' => {
                'desc' => 'Ruddy brown',

                'out' => $csi . '48:2:187:101:40m',
            },
            'B_RUDDY PINK' => {
                'desc' => 'Ruddy pink',

                'out' => $csi . '48:2:225:142:150m',
            },
            'B_RUFOUS' => {
                'desc' => 'Rufous',

                'out' => $csi . '48:2:168:28:7m',
            },
            'B_RUSSET' => {
                'desc' => 'Russet',

                'out' => $csi . '48:2:128:70:27m',
            },
            'B_RUST' => {
                'desc' => 'Rust',

                'out' => $csi . '48:2:183:65:14m',
            },
            'B_SACRAMENTO STATE GREEN' => {
                'desc' => 'Sacramento State green',

                'out' => $csi . '48:2:0:86:63m',
            },
            'B_SADDLE BROWN' => {
                'desc' => 'Saddle brown',

                'out' => $csi . '48:2:139:69:19m',
            },
            'B_SAFETY ORANGE' => {
                'desc' => 'Safety orange',

                'out' => $csi . '48:2:255:103:0m',
            },
            'B_SAFFRON' => {
                'desc' => 'Saffron',

                'out' => $csi . '48:2:244:196:48m',
            },
            'B_SAINT PATRICK BLUE' => {
                'desc' => 'Saint Patrick Blue',

                'out' => $csi . '48:2:35:41:122m',
            },
            'B_SALMON' => {
                'desc' => 'Salmon',

                'out' => $csi . '48:2:255:140:105m',
            },
            'B_SALMON PINK' => {
                'desc' => 'Salmon pink',

                'out' => $csi . '48:2:255:145:164m',
            },
            'B_SAND' => {
                'desc' => 'Sand',

                'out' => $csi . '48:2:194:178:128m',
            },
            'B_SAND DUNE' => {
                'desc' => 'Sand dune',

                'out' => $csi . '48:2:150:113:23m',
            },
            'B_SANDSTORM' => {
                'desc' => 'Sandstorm',

                'out' => $csi . '48:2:236:213:64m',
            },
            'B_SANDY BROWN' => {
                'desc' => 'Sandy brown',

                'out' => $csi . '48:2:244:164:96m',
            },
            'B_SANDY TAUPE' => {
                'desc' => 'Sandy taupe',

                'out' => $csi . '48:2:150:113:23m',
            },
            'B_SAP GREEN' => {
                'desc' => 'Sap green',

                'out' => $csi . '48:2:80:125:42m',
            },
            'B_SAPPHIRE' => {
                'desc' => 'Sapphire',

                'out' => $csi . '48:2:15:82:186m',
            },
            'B_SATIN SHEEN GOLD' => {
                'desc' => 'Satin sheen gold',

                'out' => $csi . '48:2:203:161:53m',
            },
            'B_SCARLET' => {
                'desc' => 'Scarlet',

                'out' => $csi . '48:2:255:36:0m',
            },
            'B_SCHOOL BUS YELLOW' => {
                'desc' => 'School bus yellow',

                'out' => $csi . '48:2:255:216:0m',
            },
            'B_SCREAMIN GREEN' => {
                'desc' => 'Screamin Green',

                'out' => $csi . '48:2:118:255:122m',
            },
            'B_SEA BLUE' => {
                'desc' => 'Sea blue',

                'out' => $csi . '48:2:0:105:148m',
            },
            'B_SEA GREEN' => {
                'desc' => 'Sea green',

                'out' => $csi . '48:2:46:139:87m',
            },
            'B_SEAL BROWN' => {
                'desc' => 'Seal brown',

                'out' => $csi . '48:2:50:20:20m',
            },
            'B_SEASHELL' => {
                'desc' => 'Seashell',

                'out' => $csi . '48:2:255:245:238m',
            },
            'B_SELECTIVE YELLOW' => {
                'desc' => 'Selective yellow',

                'out' => $csi . '48:2:255:186:0m',
            },
            'B_SEPIA' => {
                'desc' => 'Sepia',

                'out' => $csi . '48:2:112:66:20m',
            },
            'B_SHADOW' => {
                'desc' => 'Shadow',

                'out' => $csi . '48:2:138:121:93m',
            },
            'B_SHAMROCK' => {
                'desc' => 'Shamrock',

                'out' => $csi . '48:2:69:206:162m',
            },
            'B_SHAMROCK GREEN' => {
                'desc' => 'Shamrock green',

                'out' => $csi . '48:2:0:158:96m',
            },
            'B_SHOCKING PINK' => {
                'desc' => 'Shocking pink',

                'out' => $csi . '48:2:252:15:192m',
            },
            'B_SIENNA' => {
                'desc' => 'Sienna',

                'out' => $csi . '48:2:136:45:23m',
            },
            'B_SILVER' => {
                'desc' => 'Silver',

                'out' => $csi . '48:2:192:192:192m',
            },
            'B_SINOPIA' => {
                'desc' => 'Sinopia',

                'out' => $csi . '48:2:203:65:11m',
            },
            'B_SKOBELOFF' => {
                'desc' => 'Skobeloff',

                'out' => $csi . '48:2:0:116:116m',
            },
            'B_SKY BLUE' => {
                'desc' => 'Sky blue',

                'out' => $csi . '48:2:135:206:235m',
            },
            'B_SKY MAGENTA' => {
                'desc' => 'Sky magenta',

                'out' => $csi . '48:2:207:113:175m',
            },
            'B_SLATE BLUE' => {
                'desc' => 'Slate blue',

                'out' => $csi . '48:2:106:90:205m',
            },
            'B_SLATE GRAY' => {
                'desc' => 'Slate gray',

                'out' => $csi . '48:2:112:128:144m',
            },
            'B_SMALT' => {
                'desc' => 'Smalt',

                'out' => $csi . '48:2:0:51:153m',
            },
            'B_SMOKEY TOPAZ' => {
                'desc' => 'Smokey topaz',

                'out' => $csi . '48:2:147:61:65m',
            },
            'B_SMOKY BLACK' => {
                'desc' => 'Smoky black',

                'out' => $csi . '48:2:16:12:8m',
            },
            'B_SNOW' => {
                'desc' => 'Snow',

                'out' => $csi . '48:2:255:250:250m',
            },
            'B_SPIRO DISCO BALL' => {
                'desc' => 'Spiro Disco Ball',

                'out' => $csi . '48:2:15:192:252m',
            },
            'B_SPRING BUD' => {
                'desc' => 'Spring bud',

                'out' => $csi . '48:2:167:252:0m',
            },
            'B_SPRING GREEN' => {
                'desc' => 'Spring green',

                'out' => $csi . '48:2:0:255:127m',
            },
            'B_STEEL BLUE' => {
                'desc' => 'Steel blue',

                'out' => $csi . '48:2:70:130:180m',
            },
            'B_STIL DE GRAIN YELLOW' => {
                'desc' => 'Stil de grain yellow',

                'out' => $csi . '48:2:250:218:94m',
            },
            'B_STIZZA' => {
                'desc' => 'Stizza',

                'out' => $csi . '48:2:153:0:0m',
            },
            'B_STORMCLOUD' => {
                'desc' => 'Stormcloud',

                'out' => $csi . '48:2:0:128:128m',
            },
            'B_STRAW' => {
                'desc' => 'Straw',

                'out' => $csi . '48:2:228:217:111m',
            },
            'B_SUNGLOW' => {
                'desc' => 'Sunglow',

                'out' => $csi . '48:2:255:204:51m',
            },
            'B_SUNSET' => {
                'desc' => 'Sunset',

                'out' => $csi . '48:2:250:214:165m',
            },
            'B_SUNSET ORANGE' => {
                'desc' => 'Sunset Orange',

                'out' => $csi . '48:2:253:94:83m',
            },
            'B_TAN' => {
                'desc' => 'Tan',

                'out' => $csi . '48:2:210:180:140m',
            },
            'B_TANGELO' => {
                'desc' => 'Tangelo',

                'out' => $csi . '48:2:249:77:0m',
            },
            'B_TANGERINE' => {
                'desc' => 'Tangerine',

                'out' => $csi . '48:2:242:133:0m',
            },
            'B_TANGERINE YELLOW' => {
                'desc' => 'Tangerine yellow',

                'out' => $csi . '48:2:255:204:0m',
            },
            'B_TAUPE' => {
                'desc' => 'Taupe',

                'out' => $csi . '48:2:72:60:50m',
            },
            'B_TAUPE GRAY' => {
                'desc' => 'Taupe gray',

                'out' => $csi . '48:2:139:133:137m',
            },
            'B_TAWNY' => {
                'desc' => 'Tawny',

                'out' => $csi . '48:2:205:87:0m',
            },
            'B_TEA GREEN' => {
                'desc' => 'Tea green',

                'out' => $csi . '48:2:208:240:192m',
            },
            'B_TEA ROSE' => {
                'desc' => 'Tea rose',

                'out' => $csi . '48:2:244:194:194m',
            },
            'B_TEAL' => {
                'desc' => 'Teal',

                'out' => $csi . '48:2:0:128:128m',
            },
            'B_TEAL BLUE' => {
                'desc' => 'Teal blue',

                'out' => $csi . '48:2:54:117:136m',
            },
            'B_TEAL GREEN' => {
                'desc' => 'Teal green',

                'out' => $csi . '48:2:0:109:91m',
            },
            'B_TERRA COTTA' => {
                'desc' => 'Terra cotta',

                'out' => $csi . '48:2:226:114:91m',
            },
            'B_THISTLE' => {
                'desc' => 'Thistle',

                'out' => $csi . '48:2:216:191:216m',
            },
            'B_THULIAN PINK' => {
                'desc' => 'Thulian pink',

                'out' => $csi . '48:2:222:111:161m',
            },
            'B_TICKLE ME PINK' => {
                'desc' => 'Tickle Me Pink',

                'out' => $csi . '48:2:252:137:172m',
            },
            'B_TIFFANY BLUE' => {
                'desc' => 'Tiffany Blue',

                'out' => $csi . '48:2:10:186:181m',
            },
            'B_TIGER EYE' => {
                'desc' => 'Tiger eye',

                'out' => $csi . '48:2:224:141:60m',
            },
            'B_TIMBERWOLF' => {
                'desc' => 'Timberwolf',

                'out' => $csi . '48:2:219:215:210m',
            },
            'B_TITANIUM YELLOW' => {
                'desc' => 'Titanium yellow',

                'out' => $csi . '48:2:238:230:0m',
            },
            'B_TOMATO' => {
                'desc' => 'Tomato',

                'out' => $csi . '48:2:255:99:71m',
            },
            'B_TOOLBOX' => {
                'desc' => 'Toolbox',

                'out' => $csi . '48:2:116:108:192m',
            },
            'B_TOPAZ' => {
                'desc' => 'Topaz',

                'out' => $csi . '48:2:255:200:124m',
            },
            'B_TRACTOR RED' => {
                'desc' => 'Tractor red',

                'out' => $csi . '48:2:253:14:53m',
            },
            'B_TROLLEY GRAY' => {
                'desc' => 'Trolley Grey',

                'out' => $csi . '48:2:128:128:128m',
            },
            'B_TROPICAL RAIN FOREST' => {
                'desc' => 'Tropical rain forest',

                'out' => $csi . '48:2:0:117:94m',
            },
            'B_TRUE BLUE' => {
                'desc' => 'True Blue',

                'out' => $csi . '48:2:0:115:207m',
            },
            'B_TUFTS BLUE' => {
                'desc' => 'Tufts Blue',

                'out' => $csi . '48:2:65:125:193m',
            },
            'B_TUMBLEWEED' => {
                'desc' => 'Tumbleweed',

                'out' => $csi . '48:2:222:170:136m',
            },
            'B_TURKISH ROSE' => {
                'desc' => 'Turkish rose',

                'out' => $csi . '48:2:181:114:129m',
            },
            'B_TURQUOISE' => {
                'desc' => 'Turquoise',

                'out' => $csi . '48:2:48:213:200m',
            },
            'B_TURQUOISE BLUE' => {
                'desc' => 'Turquoise blue',

                'out' => $csi . '48:2:0:255:239m',
            },
            'B_TURQUOISE GREEN' => {
                'desc' => 'Turquoise green',

                'out' => $csi . '48:2:160:214:180m',
            },
            'B_TUSCAN RED' => {
                'desc' => 'Tuscan red',

                'out' => $csi . '48:2:102:66:77m',
            },
            'B_TWILIGHT LAVENDER' => {
                'desc' => 'Twilight lavender',

                'out' => $csi . '48:2:138:73:107m',
            },
            'B_TYRIAN PURPLE' => {
                'desc' => 'Tyrian purple',

                'out' => $csi . '48:2:102:2:60m',
            },
            'B_UA BLUE' => {
                'desc' => 'UA blue',

                'out' => $csi . '48:2:0:51:170m',
            },
            'B_UA RED' => {
                'desc' => 'UA red',

                'out' => $csi . '48:2:217:0:76m',
            },
            'B_UBE' => {
                'desc' => 'Ube',

                'out' => $csi . '48:2:136:120:195m',
            },
            'B_UCLA BLUE' => {
                'desc' => 'UCLA Blue',

                'out' => $csi . '48:2:83:104:149m',
            },
            'B_UCLA GOLD' => {
                'desc' => 'UCLA Gold',

                'out' => $csi . '48:2:255:179:0m',
            },
            'B_UFO GREEN' => {
                'desc' => 'UFO Green',

                'out' => $csi . '48:2:60:208:112m',
            },
            'B_ULTRA PINK' => {
                'desc' => 'Ultra pink',

                'out' => $csi . '48:2:255:111:255m',
            },
            'B_ULTRAMARINE' => {
                'desc' => 'Ultramarine',

                'out' => $csi . '48:2:18:10:143m',
            },
            'B_ULTRAMARINE BLUE' => {
                'desc' => 'Ultramarine blue',

                'out' => $csi . '48:2:65:102:245m',
            },
            'B_UMBER' => {
                'desc' => 'Umber',

                'out' => $csi . '48:2:99:81:71m',
            },
            'B_UNITED NATIONS BLUE' => {
                'desc' => 'United Nations blue',

                'out' => $csi . '48:2:91:146:229m',
            },
            'B_UNIVERSITY OF' => {
                'desc' => 'University of',

                'out' => $csi . '48:2:183:135:39m',
            },
            'B_UNMELLOW YELLOW' => {
                'desc' => 'Unmellow Yellow',

                'out' => $csi . '48:2:255:255:102m',
            },
            'B_UP FOREST GREEN' => {
                'desc' => 'UP Forest green',

                'out' => $csi . '48:2:1:68:33m',
            },
            'B_UP MAROON' => {
                'desc' => 'UP Maroon',

                'out' => $csi . '48:2:123:17:19m',
            },
            'B_UPSDELL RED' => {
                'desc' => 'Upsdell red',

                'out' => $csi . '48:2:174:32:41m',
            },
            'B_UROBILIN' => {
                'desc' => 'Urobilin',

                'out' => $csi . '48:2:225:173:33m',
            },
            'B_USC CARDINAL' => {
                'desc' => 'USC Cardinal',

                'out' => $csi . '48:2:153:0:0m',
            },
            'B_USC GOLD' => {
                'desc' => 'USC Gold',

                'out' => $csi . '48:2:255:204:0m',
            },
            'B_UTAH CRIMSON' => {
                'desc' => 'Utah Crimson',

                'out' => $csi . '48:2:211:0:63m',
            },
            'B_VANILLA' => {
                'desc' => 'Vanilla',

                'out' => $csi . '48:2:243:229:171m',
            },
            'B_VEGAS GOLD' => {
                'desc' => 'Vegas gold',

                'out' => $csi . '48:2:197:179:88m',
            },
            'B_VENETIAN RED' => {
                'desc' => 'Venetian red',

                'out' => $csi . '48:2:200:8:21m',
            },
            'B_VERDIGRIS' => {
                'desc' => 'Verdigris',

                'out' => $csi . '48:2:67:179:174m',
            },
            'B_VERMILION' => {
                'desc' => 'Vermilion',

                'out' => $csi . '48:2:227:66:52m',
            },
            'B_VERONICA' => {
                'desc' => 'Veronica',

                'out' => $csi . '48:2:160:32:240m',
            },
            'B_VIOLET' => {
                'desc' => 'Violet',

                'out' => $csi . '48:2:238:130:238m',
            },
            'B_VIOLET BLUE' => {
                'desc' => 'Violet Blue',

                'out' => $csi . '48:2:50:74:178m',
            },
            'B_VIOLET RED' => {
                'desc' => 'Violet Red',

                'out' => $csi . '48:2:247:83:148m',
            },
            'B_VIRIDIAN' => {
                'desc' => 'Viridian',

                'out' => $csi . '48:2:64:130:109m',
            },
            'B_VIVID AUBURN' => {
                'desc' => 'Vivid auburn',

                'out' => $csi . '48:2:146:39:36m',
            },
            'B_VIVID BURGUNDY' => {
                'desc' => 'Vivid burgundy',

                'out' => $csi . '48:2:159:29:53m',
            },
            'B_VIVID CERISE' => {
                'desc' => 'Vivid cerise',

                'out' => $csi . '48:2:218:29:129m',
            },
            'B_VIVID TANGERINE' => {
                'desc' => 'Vivid tangerine',

                'out' => $csi . '48:2:255:160:137m',
            },
            'B_VIVID VIOLET' => {
                'desc' => 'Vivid violet',

                'out' => $csi . '48:2:159:0:255m',
            },
            'B_WARM BLACK' => {
                'desc' => 'Warm black',

                'out' => $csi . '48:2:0:66:66m',
            },
            'B_WATERSPOUT' => {
                'desc' => 'Waterspout',

                'out' => $csi . '48:2:0:255:255m',
            },
            'B_WENGE' => {
                'desc' => 'Wenge',

                'out' => $csi . '48:2:100:84:82m',
            },
            'B_WHEAT' => {
                'desc' => 'Wheat',

                'out' => $csi . '48:2:245:222:179m',
            },
            'B_WHITE SMOKE' => {
                'desc' => 'White smoke',

                'out' => $csi . '48:2:245:245:245m',
            },
            'B_WILD BLUE YONDER' => {
                'desc' => 'Wild blue yonder',

                'out' => $csi . '48:2:162:173:208m',
            },
            'B_WILD STRAWBERRY' => {
                'desc' => 'Wild Strawberry',

                'out' => $csi . '48:2:255:67:164m',
            },
            'B_WILD WATERMELON' => {
                'desc' => 'Wild Watermelon',

                'out' => $csi . '48:2:252:108:133m',
            },
            'B_WINE' => {
                'desc' => 'Wine',

                'out' => $csi . '48:2:114:47:55m',
            },
            'B_WISTERIA' => {
                'desc' => 'Wisteria',

                'out' => $csi . '48:2:201:160:220m',
            },
            'B_XANADU' => {
                'desc' => 'Xanadu',

                'out' => $csi . '48:2:115:134:120m',
            },
            'B_YALE BLUE' => {
                'desc' => 'Yale Blue',
                'out'  => $csi . '48:2:15:77:146m',
            },
            'B_YELLOW GREEN' => {
                'desc' => 'Yellow green',
                'out'  => $csi . '48:2:154:205:50m',
            },
            'B_YELLOW ORANGE' => {
                'desc' => 'Yellow Orange',
                'out'  => $csi . '48:2:255:174:66m',
            },
            'B_ZAFFRE' => {
                'desc' => 'Zaffre',
                'out'  => $csi . '48:2:0:20:168m',
            },
            'B_ZINNWALDITE BROWN' => {
                'desc' => 'Zinnwaldite brown',
                'out'  => $csi . '48:2:44:22:8m',
            },
        },
    };

    # Alternate Fonts
    foreach my $count (1 .. 9) {
        $tmp->{'attributes'}->{ 'FONT ' . $count } = {
            'desc' => "ANSI Font $count",
            'out'  => $csi . ($count + 10) . 'm',
        };
    } ## end foreach my $count (1 .. 9)
    foreach my $count (16 .. 231) {
        $tmp->{'foreground'}->{ 'COLOR ' . $count } = {
            'desc' => "ANSI256 Color $count",
            'out'  => $csi . "38;5;$count" . 'm',
        };
        $tmp->{'background'}->{ 'B_COLOR ' . $count } = {
            'desc' => "ANSI256 Color $count",
            'out'  => $csi . "48;5;$count" . 'm',
        };
    } ## end foreach my $count (16 .. 231)
    foreach my $count (232 .. 255) {
        $tmp->{'foreground'}->{ 'GRAY ' . ($count - 232) } = {
            'desc' => "ANSI256 grey level " . ($count - 232),
            'out'  => $csi . "38;5;$count" . 'm',
        };
        $tmp->{'background'}->{ 'B_GRAY ' . ($count - 232) } = {
            'desc' => "ANSI256 grey level " . ($count - 232),
            'out'  => $csi . "48;5;$count" . 'm',
        };
    } ## end foreach my $count (232 .. 255)
    return ($tmp);
} ## end sub _global_ansi_meta

1;

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

There are many more foreground colors available than the sixteen below.  However, the ones below should work on any color terminal.  Other colors may requite 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have 'Term256' features.  You can used the '-t' option for all of the color tokens available or use the 'RGB' token for access to 16 million colors.

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

There are many more background colors available than the sixteen below.  However, the ones below should work on any color terminal.  Other colors may requite 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have 'Term256' features.  You can used the '-t' option for all of the color tokens available or use the 'B_RGB' token for access to 16 million colors.

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
