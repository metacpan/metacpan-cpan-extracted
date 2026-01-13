package Term::ANSIEncode 1.74;

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
use Text::Format;

# use Data::Dumper::Simple;$Data::Dumper::Terse=TRUE;$Data::Dumper::Indent=TRUE;$Data::Dumper::Useqq=TRUE;$Data::Dumper::Deparse=TRUE;$Data::Dumper::Quotekeys=TRUE;$Data::Dumper::Trailingcomma=TRUE;$Data::Dumper::Sortkeys=TRUE;$Data::Dumper::Purity=TRUE;$Data::Dumper::Deparse=TRUE;
# use Term::Drawille;

# UTF-8 is required for special character handling
binmode(STDERR, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDIN,  ":encoding(UTF-8)");

BEGIN {
    require Exporter;

    # Inherit from Exporter to export functions and variables
    our @ISA = qw(Exporter);

    # Functions and variables which are exported by default
    our @EXPORT = qw(
      ansi_description
      ansi_decode
      ansi_output
      ansi_box
    );

    # Functions and variables which can be optionally exported
    our @EXPORT_OK = qw(ansi_colors);
} ## end BEGIN

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

sub ansi_colors {
    my $self = shift;

    my $grey   = '[% GRAY 8 %]';
    my $off    = '[% RESET %]';
    my $string = qq(\[\% CLS \%\]\[\% BRIGHT YELLOW \%\] 3 BIT     4 BIT            24 BIT\[\% RESET \%\]\n) . ('─' x 59) . "\n";

    # Define subroutine references for color blocks
    my %actions = (
        0 => sub { my ($count, $next_count) = @_; return "\[\% B_RGB $count,0,0 \%\]\[\% RGB $next_count,0,0 \%\]▐"; },
        1 => sub { my ($count, $next_count) = @_; return "\[\% B_RGB $count,$count,0 \%\]\[\% RGB $next_count,$next_count,0 \%\]▐"; },
        2 => sub { my ($count, $next_count) = @_; return "\[\% B_RGB 0,$count,0 \%\]\[\% RGB 0,$next_count,0 \%\]▐"; },
        3 => sub { my ($count, $next_count) = @_; return "\[\% B_RGB 0,$count,$count \%\]\[\% RGB 0,$next_count,$next_count \%\]▐"; },
        4 => sub { my ($count, $next_count) = @_; return "\[\% B_RGB 0,0,$count \%\]\[\% RGB 0,0,$next_count \%\]▐"; },
        5 => sub { my ($count, $next_count) = @_; return "\[\% B_RGB $count,0,$count \%\]\[\% RGB $next_count,0,$next_count \%\]▐"; },
        6 => sub { my ($count, $next_count) = @_; return "\[\% B_RGB $count,$count,$count \%\]\[\% RGB $next_count,$next_count,$next_count \%\]▐"; },
    );

    my $index = 0;
    foreach my $color (qw(RED YELLOW GREEN CYAN BLUE MAGENTA WHITE BLACK)) {
        if ($color eq 'BLACK') {
            $string .= sprintf('%s %-7s %s %s %-14s %s', "\[\% WHITE \%\]\[\% B_$color \%\]", $color, $off, "\[\% WHITE \%\]\[\% B_BRIGHT $color \%\]", "BRIGHT $color", $off) . ' ';
            $string .= "$off\n";
        } else {
            $string .= sprintf('%s %-7s %s %s %-14s %s', "\[\% BLACK \%\]\[\% B_$color \%\]", $color, $off, "\[\% BLACK \%\]\[\% B_BRIGHT $color \%\]", "BRIGHT $color", $off) . ' ';
            # Loop through color ranges and call appropriate subroutine for blocks
            foreach my $range ([0, 64, 2], [128, 64, -2], [128, 192, 2], [255, 192, -2]) {
                if ($range->[0] < $range->[1]) {
                    for (my $count = $range->[0]; $count < $range->[1]; $count += $range->[2]) {
                        # Pass arguments to the subroutine and append the result
                        $string .= $actions{$index}->($count, $count + $range->[2]);
                    }
                } else {
                    for (my $count = $range->[0]; $count > $range->[1]; $count += $range->[2]) {
                        # Pass arguments to the subroutine and append the result
                        $string .= $actions{$index}->($count, $count + $range->[2]);
                    }
                }
                $string .= "\n" . sprintf('%s %-7s %s %s %-14s %s', "\[\% BLACK \%\]\[\% B_$color \%\]", ' ', $off, "\[\% BLACK \%\]\[\% B_BRIGHT $color \%\]", ' ', $off) . ' ' if ($range->[0] != 255);
            } ## end foreach my $range ([0, 64, ...])
            $index++;
            $string .= '[% RESET %]' . "\n";
        }
    } ## end foreach my $color (@colors)

    $string .= "\n[% BRIGHT YELLOW %] 8 BIT$off\n" . ('─' x 60) . _generate_8bit_colors();
    return ($string);
} ## end sub ansi_colors

sub _generate_8bit_colors {
    my $output = ''; # "\n";
    foreach my $i (0 .. 5) {
        my $_i = ($i * 36) + 16;     # 16, 28, 40
        $output .= "\n";
        foreach my $j (0 .. 11) {    # 35
            if (($_i + $j) <= 21) {
                $output .= '[% WHITE %][% B_COLOR ' . ($_i + $j) . ' %]' . sprintf(' %3d ', ($_i + $j)) . '[% RESET %]';
            } else {
                $output .= '[% BLACK %][% B_COLOR ' . ($_i + $j) . ' %]' . sprintf(' %3d ', ($_i + $j)) . '[% RESET %]';
            }
        } ## end foreach my $j (0 .. 11)
    } ## end foreach my $i (0 .. 5)
    foreach my $i (0 .. 5) {
        my $_i = ($i * 36) + 28;     # 16, 28, 40
        $output .= "\n";
        foreach my $j (0 .. 11) {    # 35
            if (($_i + $j) <= 21) {
                $output .= '[% WHITE %][% B_COLOR ' . ($_i + $j) . ' %]' . sprintf(' %3d ', ($_i + $j)) . '[% RESET %]';
            } else {
                $output .= '[% BLACK %][% B_COLOR ' . ($_i + $j) . ' %]' . sprintf(' %3d ', ($_i + $j)) . '[% RESET %]';
            }
        } ## end foreach my $j (0 .. 11)
    } ## end foreach my $i (0 .. 5)
    foreach my $i (0 .. 5) {
        my $_i = ($i * 36) + 40;     # 16, 28, 40
        $output .= "\n";
        if ($i == 6) {
            $output .= "\n\[\% BRIGHT YELLOW \%\] GRAY \[\% RESET \%\]\n";
        }
        foreach my $j (0 .. 11) {    # 35
            if (($_i + $j) <= 21) {
                $output .= '[% WHITE %][% B_COLOR ' . ($_i + $j) . ' %]' . sprintf(' %3d ', ($_i + $j)) . '[% RESET %]';
            } else {
                $output .= '[% BLACK %][% B_COLOR ' . ($_i + $j) . ' %]' . sprintf(' %3d ', ($_i + $j)) . '[% RESET %]';
            }
        } ## end foreach my $j (0 .. 11)
    } ## end foreach my $i (0 .. 6)
    $output .= "\n" . '[% BRIGHT YELLOW %] GRAY[% RESET %]' . "\n";
    foreach my $count (0 .. 23) {
        if ($count < 12) {
            $output .= '[% WHITE %][% B_GRAY ' . $count . ' %]' . sprintf(' %3d ', $count) . '[% RESET %]';
        } else {
            $output .= "\n" if ($count == 12);
            $output .= '[% BLACK %][% B_GRAY ' . $count . ' %]' . sprintf(' %3d ', $count) . '[% RESET %]';
        }
    }
    $output .= "\n\n";
    return $output;
} ## end sub _generate_8bit_colors

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

        my $replace = $self->ansi_box($parts[0], $parts[1], $parts[2], $parts[3], $parts[4], $parts[5], $body);

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

    while ($text =~ /\[\%\s+UNDERLINE COLOR RGB (\d+),(\d+),(\d+)\s+\%\]/) {
        my ($red, $green, $blue) = ($1, $2, $3);
        my $new = "\e[58;2;${red};${green};${blue}m";
        $text =~ s/\[\%\s+UNDERLINE COLOR RGB $red,$green,$blue\s+\%\]/$new/gs;
    }
    while ($text =~ /\[\%\s+UNDERLINE COLOR (.*?)\s+\%\]/) {
        my $color = $1;
        my $new;
        $new = "\e[58;5;" . substr($self->{'ansi_meta'}->{'foreground'}->{$color}->{'out'}, 3);
        $text =~ s/\[\%\s+UNDERLINE COLOR $color\s+\%\]/$new/gs;
    } ## end while ($text =~ /\[\%\s+UNDERLINE COLOR (.*?)\s+\%\]/)

    # 24-bit RGB foreground/background
    $text =~ s/\[\%\s*RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\%\]/
      do { my ($r,$g,$b)=($1&255,$2&255,$3&255); $csi . "38:2:$r:$g:$b" . 'm' }/eigs;
    $text =~ s/\[\%\s*B_RGB\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\%\]/
      do { my ($r,$g,$b)=($1&255,$2&255,$3&255); $csi . "48:2:$r:$g:$b" . 'm' }/eigs;

    while ($text =~ /\[\%\s+WRAP\s+\%\](.*?)\[\%\s+ENDWRAP\s+\%\]/si) {
        my $wrapped = $1;
        my $format  = Text::Format->new(
            'columns'     => $self->{'columns'} - 1,
            'tabstop'     => 4,
            'extraSpace'  => TRUE,
            'firstIndent' => 0,
        );
        $wrapped = $format->format($wrapped);
        chomp($wrapped);
        $text =~ s/\[\%\s+WRAP\s+\%\].*?\[\%\s+ENDWRAP\s+\%\]/$wrapped/s;
    } ## end while ($text =~ /\[\%\s+WRAP\s+\%\](.*?)\[\%\s+ENDWRAP\s+\%\]/si)

    while ($text =~ /\[\%\s+JUSTIFIED\s+\%\](.*?)\[\%\s+ENDJUSTIFIED\s+\%\]/si) {
        my $wrapped = $1;
        my $format  = Text::Format->new(
            'columns'     => $self->{'columns'} - 1,
            'tabstop'     => 4,
            'extraSpace'  => TRUE,
            'firstIndent' => 0,
            'justify'     => TRUE,
        );
        $wrapped = $format->format($wrapped);
        chomp($wrapped);
        $text =~ s/\[\%\s+JUSTIFIED\s+\%\].*?\[\%\s+ENDJUSTIFIED\s+\%\]/$wrapped/s;
    } ## end while ($text =~ /\[\%\s+JUSTIFIED\s+\%\](.*?)\[\%\s+ENDJUSTIFIED\s+\%\]/si)

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
    my $speed = $self->{'speed'};
    if ($speed == 0) {
        print $text;
    } else {
        for (my $index = 0; $index < length($text); $index++) {
            print substr($text, $index, 1);
            sleep $speed;
        }
    } ## end else [ if ($speed == 0) ]
    return (TRUE);
} ## end sub ansi_output

sub ansi_box {
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

    my $format = Text::Format->new(
        'columns'     => $w - 3,
        'tabstop'     => 4,
        'extraSpace'  => TRUE,
        'firstIndent' => 0,
    );
    $string = $format->format($string);
    chomp($string);
    my @lines = split(/\n/, $string);

    my $line_y = $y + 1;
    foreach my $line (@lines) {
        last if $line_y >= ($y + $h - 1);    # avoid writing outside the box
        $text .= locate($line_y++, $x + 1) . $line;
    }

    # Restore cursor
    $text .= $self->{'ansi_meta'}->{'cursor'}->{'RESTORE'}->{'out'};

    return ($text);
} ## end sub ansi_box

sub new {
    my $class = shift;
    my $esc   = chr(27);
    my $csi   = $esc . '[';

    my $self = {
        'ansi_prefix' => $csi,
        'list'        => [(0x20 .. 0x7F, 0xA0 .. 0xFF, 0x2010 .. 0x205F, 0x2070 .. 0x242F, 0x2440 .. 0x244F, 0x2460 .. 0x29FF, 0x1F300 .. 0x1F8BF, 0x1F900 .. 0x1FBBF, 0x1F900 .. 0x1FBCF, 0x1FBF0 .. 0x1FBFF)],
        'ansi_meta'   => $GLOBAL_ANSI_META,
        'baud'        => 'FULL',
        'columns'     => 80,
        @_,
    };

    bless($self, $class);
    return ($self);
} ## end sub new

sub _global_ansi_meta {    # prefills the hash cache
    my $esc = chr(27);
    my $csi = $esc . '[';

###
    my $tmp = {
        'special' => {
            'APC' => { 'out' => $esc . '_',  'desc' => 'Application Program Command' },
            'CSI' => { 'out' => $esc . '[',  'desc' => 'Control Sequence Introducer' },
            'DCS' => { 'out' => $esc . 'P',  'desc' => 'Device Control String' },
            'OSC' => { 'out' => $esc . ']',  'desc' => 'Operating System Command' },
            'SOS' => { 'out' => $esc . 'X',  'desc' => 'Start Of String' },
            'SS2' => { 'out' => $esc . 'N',  'desc' => 'Single Shift 2' },
            'SS3' => { 'out' => $esc . 'O',  'desc' => 'Single Shift 3' },
            'ST'  => { 'out' => $esc . "\\", 'desc' => 'String Terminator' },
        },

        'clear' => {
            'CLEAR'      => { 'out' => $csi . '2J',              'desc' => 'Clear screen and keep cursor location' },
            'CLEAR LINE' => { 'out' => $csi . '0K',              'desc' => 'Clear the current line from cursor' },
            'CLEAR DOWN' => { 'out' => $csi . '0J',              'desc' => 'Clear from cursor position to bottom of the screen' },
            'CLEAR UP'   => { 'out' => $csi . '1J',              'desc' => 'Clear to the top of the screen from cursor position' },
            'CLS'        => { 'out' => $csi . '2J' . $csi . 'H', 'desc' => 'Clear screen and place cursor at the top of the screen' },
        },

        'cursor' => {
            'CURSOR OFF'    => { 'out' => $csi . '?25l',     'desc' => 'Turn the cursor off' },
            'CURSOR ON'     => { 'out' => $csi . '?25h',     'desc' => 'Turn the cursor on' },
            'DOWN'          => { 'out' => $csi . 'B',        'desc' => 'Move cursor down one line' },
            'HOME'          => { 'out' => $csi . 'H',        'desc' => 'Place cursor at top left of the screen' },
            'LEFT'          => { 'out' => $csi . 'D',        'desc' => 'Move cursor left one space non-destructively' },
            'LINEFEED'      => { 'out' => chr(10),           'desc' => 'Line feed (ASCII 10)' },
            'NEWLINE'       => { 'out' => chr(13) . chr(10), 'desc' => 'New line (ASCII 13 and ASCII 10)' },
            'NEXT LINE'     => { 'out' => $csi . 'E',        'desc' => 'Place the cursor at the beginning of the next line' },
            'PREVIOUS LINE' => { 'out' => $csi . 'F',        'desc' => 'Place the cursor at the beginning of the previous line' },
            'RESTORE'       => { 'out' => $csi . 'u',        'desc' => 'Restore the cursor to the saved position' },
            'RETURN'        => { 'out' => chr(13),           'desc' => 'Carriage Return (ASCII 13)' },
            'RIGHT'         => { 'out' => $csi . 'C',        'desc' => 'Move cursor right one space non-destructively' },
            'SAVE'          => { 'out' => $csi . 's',        'desc' => 'Save cureent cursor position' },
            'SCREEN 1'      => { 'out' => $csi . '?1049l',   'desc' => 'Set display to screen 1' },
            'SCREEN 2'      => { 'out' => $csi . '?1049h',   'desc' => 'Set display to screen 2' },
            'UP'            => { 'out' => $csi . 'A',        'desc' => 'Move cursor up one line' },
        },

        'attributes' => {
            'BOLD'                      => { 'out' => $csi . '1m',  'desc' => 'Set to bold text' },
            'CROSSED OUT'               => { 'out' => $csi . '9m',  'desc' => 'Crossed out text' },
            'DEFAULT FONT'              => { 'out' => $csi . '10m', 'desc' => 'Set default font' },
            'DEFAULT UNDERLINE COLOR'   => { 'out' => $csi . '59m', 'desc' => 'Set underline color to the default' },
            'ENCIRCLED'                 => { 'out' => $csi . '52m', 'desc' => 'Turn on encircled letters' },
            'ENCIRCLED OFF'             => { 'out' => $csi . '54m', 'desc' => 'Turn off encircled letters' },
            'FAINT'                     => { 'out' => $csi . '2m',  'desc' => 'Set to faint (light) text' },
            'FONT DEFAULT'              => { 'out' => $esc . '#5',  'desc' => 'Default Font Size' },
            'FONT DOUBLE-HEIGHT BOTTOM' => { 'out' => $esc . '#4',  'desc' => 'Double-Height Font Bottom Portion' },
            'FONT DOUBLE-HEIGHT TOP'    => { 'out' => $esc . '#3',  'desc' => 'Double-Height Font Top Portion' },
            'FONT DOUBLE-WIDTH'         => { 'out' => $esc . '#6',  'desc' => 'Double-Width Font' },
            'FRAMED'                    => { 'out' => $csi . '51m', 'desc' => 'Turn on framed text' },
            'FRAMED OFF'                => { 'out' => $csi . '54m', 'desc' => 'Turn off framed text' },
            'HIDE'                      => { 'out' => $csi . '8m',  'desc' => 'Hide enclosed text' },
            'INVERT'                    => { 'out' => $csi . '7m',  'desc' => 'Invert text' },
            'ITALIC'                    => { 'out' => $csi . '3m',  'desc' => 'Set to italic text' },
            'NORMAL'                    => { 'out' => $csi . '22m', 'desc' => 'Turn off all attributes' },
            'OVERLINED'                 => { 'out' => $csi . '53m', 'desc' => 'Turn on overlined text' },
            'OVERLINED OFF'             => { 'out' => $csi . '55m', 'desc' => 'Turn off overlined text' },
            'PROPORTIONAL OFF'          => { 'out' => $csi . '50m', 'desc' => 'Turn off proportional text' },
            'PROPORTIONAL ON'           => { 'out' => $csi . '26m', 'desc' => 'Turn on proportional text' },
            'RAPID BLINK'               => { 'out' => $csi . '6m',  'desc' => 'Set rapid blink' },
            'RESET'                     => { 'out' => $csi . '0m',  'desc' => 'Restore all attributes and colors to their defaults' },
            'REVEAL'                    => { 'out' => $csi . '28m', 'desc' => 'Reveal hidden text' },
            'REVERSE'                   => { 'out' => $csi . '7m',  'desc' => 'Invert text' },
            'RING BELL'                 => { 'out' => chr(7),       'desc' => 'Console Bell' },
            'SLOW BLINK'                => { 'out' => $csi . '5m',  'desc' => 'Set slow blink' },
            'SUBSCRIPT'                 => { 'out' => $csi . '74m', 'desc' => 'Turn on superscript' },
            'SUBSCRIPT OFF'             => { 'out' => $csi . '75m', 'desc' => 'Turn off subscript' },
            'SUPERSCRIPT'               => { 'out' => $csi . '73m', 'desc' => 'Turn on superscript' },
            'SUPERSCRIPT OFF'           => { 'out' => $csi . '75m', 'desc' => 'Turn off superscript' },
            'UNDERLINE'                 => { 'out' => $csi . '4m',  'desc' => 'Set to underlined text' },
        },

        # Color

        'foreground' => {
            'AIR FORCE BLUE'                => { 'out' => $csi . '38;2;93;138;168m',  'desc' => 'Air Force blue' },
            'ALICE BLUE'                    => { 'out' => $csi . '38;2;240;248;255m', 'desc' => 'Alice blue' },
            'ALICE BLUE'                    => { 'out' => $csi . '38;2;240;248;255m', 'desc' => 'Alice blue' },
            'ALIZARIN CRIMSON'              => { 'out' => $csi . '38;2;227;38;54m',   'desc' => 'Alizarin crimson' },
            'ALMOND'                        => { 'out' => $csi . '38;2;239;222;205m', 'desc' => 'Almond' },
            'AMARANTH'                      => { 'out' => $csi . '38;2;229;43;80m',   'desc' => 'Amaranth' },
            'AMBER'                         => { 'out' => $csi . '38;2;255;191;0m',   'desc' => 'Amber' },
            'AMERICAN ROSE'                 => { 'out' => $csi . '38;2;255;3;62m',    'desc' => 'American rose' },
            'AMETHYST'                      => { 'out' => $csi . '38;2;153;102;204m', 'desc' => 'Amethyst' },
            'ANDROID GREEN'                 => { 'out' => $csi . '38;2;164;198;57m',  'desc' => 'Android Green' },
            'ANTI-FLASH WHITE'              => { 'out' => $csi . '38;2;242;243;244m', 'desc' => 'Anti-flash white' },
            'ANTIQUE BRASS'                 => { 'out' => $csi . '38;2;205;149;117m', 'desc' => 'Antique brass' },
            'ANTIQUE FUCHSIA'               => { 'out' => $csi . '38;2;145;92;131m',  'desc' => 'Antique fuchsia' },
            'ANTIQUE WHITE'                 => { 'out' => $csi . '38;2;250;235;215m', 'desc' => 'Antique white' },
            'ANTIQUE WHITE'                 => { 'out' => $csi . '38;2;250;235;215m', 'desc' => 'Antique white' },
            'AO'                            => { 'out' => $csi . '38;2;0;128;0m',     'desc' => 'Ao' },
            'APPLE GREEN'                   => { 'out' => $csi . '38;2;141;182;0m',   'desc' => 'Apple green' },
            'APRICOT'                       => { 'out' => $csi . '38;2;251;206;177m', 'desc' => 'Apricot' },
            'AQUA'                          => { 'out' => $csi . '38;2;0;255;255m',   'desc' => 'Aqua' },
            'AQUA'                          => { 'out' => $csi . '38;2;0;255;255m',   'desc' => 'Aqua' },
            'AQUA MARINE'                   => { 'out' => $csi . '38;2;127;255;212m', 'desc' => 'Aqua marine' },
            'AQUAMARINE'                    => { 'out' => $csi . '38;2;127;255;212m', 'desc' => 'Aquamarine' },
            'ARMY GREEN'                    => { 'out' => $csi . '38;2;75;83;32m',    'desc' => 'Army green' },
            'ARYLIDE YELLOW'                => { 'out' => $csi . '38;2;233;214;107m', 'desc' => 'Arylide yellow' },
            'ASH GRAY'                      => { 'out' => $csi . '38;2;178;190;181m', 'desc' => 'Ash grey' },
            'ASPARAGUS'                     => { 'out' => $csi . '38;2;135;169;107m', 'desc' => 'Asparagus' },
            'ATOMIC TANGERINE'              => { 'out' => $csi . '38;2;255;153;102m', 'desc' => 'Atomic tangerine' },
            'AUBURN'                        => { 'out' => $csi . '38;2;165;42;42m',   'desc' => 'Auburn' },
            'AUREOLIN'                      => { 'out' => $csi . '38;2;253;238;0m',   'desc' => 'Aureolin' },
            'AUROMETALSAURUS'               => { 'out' => $csi . '38;2;110;127;128m', 'desc' => 'AuroMetalSaurus' },
            'AWESOME'                       => { 'out' => $csi . '38;2;255;32;82m',   'desc' => 'Awesome' },
            'AZURE'                         => { 'out' => $csi . '38;2;0;127;255m',   'desc' => 'Azure' },
            'AZURE'                         => { 'out' => $csi . '38;2;240;255;255m', 'desc' => 'Azure' },
            'AZURE MIST'                    => { 'out' => $csi . '38;2;240;255;255m', 'desc' => 'Azure mist' },
            'BABY BLUE'                     => { 'out' => $csi . '38;2;137;207;240m', 'desc' => 'Baby blue' },
            'BABY BLUE EYES'                => { 'out' => $csi . '38;2;161;202;241m', 'desc' => 'Baby blue eyes' },
            'BABY PINK'                     => { 'out' => $csi . '38;2;244;194;194m', 'desc' => 'Baby pink' },
            'BALL BLUE'                     => { 'out' => $csi . '38;2;33;171;205m',  'desc' => 'Ball Blue' },
            'BANANA MANIA'                  => { 'out' => $csi . '38;2;250;231;181m', 'desc' => 'Banana Mania' },
            'BANANA YELLOW'                 => { 'out' => $csi . '38;2;255;225;53m',  'desc' => 'Banana yellow' },
            'BATTLESHIP GRAY'               => { 'out' => $csi . '38;2;132;132;130m', 'desc' => 'Battleship grey' },
            'BAZAAR'                        => { 'out' => $csi . '38;2;152;119;123m', 'desc' => 'Bazaar' },
            'BEAU BLUE'                     => { 'out' => $csi . '38;2;188;212;230m', 'desc' => 'Beau blue' },
            'BEAVER'                        => { 'out' => $csi . '38;2;159;129;112m', 'desc' => 'Beaver' },
            'BEIGE'                         => { 'out' => $csi . '38;2;245;245;220m', 'desc' => 'Beige' },
            'BEIGE'                         => { 'out' => $csi . '38;2;245;245;220m', 'desc' => 'Beige' },
            'BISQUE'                        => { 'out' => $csi . '38;2;255;228;196m', 'desc' => 'Bisque' },
            'BISQUE'                        => { 'out' => $csi . '38;2;255;228;196m', 'desc' => 'Bisque' },
            'BISTRE'                        => { 'out' => $csi . '38;2;61;43;31m',    'desc' => 'Bistre' },
            'BITTERSWEET'                   => { 'out' => $csi . '38;2;254;111;94m',  'desc' => 'Bittersweet' },
            'BLACK'                         => { 'out' => $csi . '30m',               'desc' => 'Black' },
            'BLANCHED ALMOND'               => { 'out' => $csi . '38;2;255;235;205m', 'desc' => 'Blanched almond' },
            'BLANCHED ALMOND'               => { 'out' => $csi . '38;2;255;235;205m', 'desc' => 'Blanched Almond' },
            'BLEU DE FRANCE'                => { 'out' => $csi . '38;2;49;140;231m',  'desc' => 'Bleu de France' },
            'BLIZZARD BLUE'                 => { 'out' => $csi . '38;2;172;229;238m', 'desc' => 'Blizzard Blue' },
            'BLOND'                         => { 'out' => $csi . '38;2;250;240;190m', 'desc' => 'Blond' },
            'BLUE'                          => { 'out' => $csi . '34m',               'desc' => 'Blue' },
            'BLUE BELL'                     => { 'out' => $csi . '38;2;162;162;208m', 'desc' => 'Blue Bell' },
            'BLUE GRAY'                     => { 'out' => $csi . '38;2;102;153;204m', 'desc' => 'Blue Gray' },
            'BLUE GREEN'                    => { 'out' => $csi . '38;2;13;152;186m',  'desc' => 'Blue green' },
            'BLUE PURPLE'                   => { 'out' => $csi . '38;2;138;43;226m',  'desc' => 'Blue purple' },
            'BLUE VIOLET'                   => { 'out' => $csi . '38;2;138;43;226m',  'desc' => 'Blue violet' },
            'BLUE VIOLET'                   => { 'out' => $csi . '38;2;138;43;226m',  'desc' => 'Blue violet' },
            'BLUSH'                         => { 'out' => $csi . '38;2;222;93;131m',  'desc' => 'Blush' },
            'BOLE'                          => { 'out' => $csi . '38;2;121;68;59m',   'desc' => 'Bole' },
            'BONDI BLUE'                    => { 'out' => $csi . '38;2;0;149;182m',   'desc' => 'Bondi blue' },
            'BONE'                          => { 'out' => $csi . '38;2;227;218;201m', 'desc' => 'Bone' },
            'BOSTON UNIVERSITY RED'         => { 'out' => $csi . '38;2;204;0;0m',     'desc' => 'Boston University Red' },
            'BOTTLE GREEN'                  => { 'out' => $csi . '38;2;0;106;78m',    'desc' => 'Bottle green' },
            'BOYSENBERRY'                   => { 'out' => $csi . '38;2;135;50;96m',   'desc' => 'Boysenberry' },
            'BRANDEIS BLUE'                 => { 'out' => $csi . '38;2;0;112;255m',   'desc' => 'Brandeis blue' },
            'BRASS'                         => { 'out' => $csi . '38;2;181;166;66m',  'desc' => 'Brass' },
            'BRICK RED'                     => { 'out' => $csi . '38;2;203;65;84m',   'desc' => 'Brick red' },
            'BRIGHT BLACK'                  => { 'out' => $csi . '90m',               'desc' => 'Bright black' },
            'BRIGHT BLUE'                   => { 'out' => $csi . '94m',               'desc' => 'Bright blue' },
            'BRIGHT CERULEAN'               => { 'out' => $csi . '38;2;29;172;214m',  'desc' => 'Bright cerulean' },
            'BRIGHT CYAN'                   => { 'out' => $csi . '96m',               'desc' => 'Bright cyan' },
            'BRIGHT GREEN'                  => { 'out' => $csi . '38;2;102;255;0m',   'desc' => 'Bright green' },
            'BRIGHT GREEN'                  => { 'out' => $csi . '92m',               'desc' => 'Bright green' },
            'BRIGHT LAVENDER'               => { 'out' => $csi . '38;2;191;148;228m', 'desc' => 'Bright lavender' },
            'BRIGHT MAGENTA'                => { 'out' => $csi . '95m',               'desc' => 'Bright magenta' },
            'BRIGHT MAROON'                 => { 'out' => $csi . '38;2;195;33;72m',   'desc' => 'Bright maroon' },
            'BRIGHT PINK'                   => { 'out' => $csi . '38;2;255;0;127m',   'desc' => 'Bright pink' },
            'BRIGHT RED'                    => { 'out' => $csi . '91m',               'desc' => 'Bright red' },
            'BRIGHT TURQUOISE'              => { 'out' => $csi . '38;2;8;232;222m',   'desc' => 'Bright turquoise' },
            'BRIGHT UBE'                    => { 'out' => $csi . '38;2;209;159;232m', 'desc' => 'Bright ube' },
            'BRIGHT WHITE'                  => { 'out' => $csi . '97m',               'desc' => 'Bright white' },
            'BRIGHT YELLOW'                 => { 'out' => $csi . '93m',               'desc' => 'Bright yellow' },
            'BRILLIANT LAVENDER'            => { 'out' => $csi . '38;2;244;187;255m', 'desc' => 'Brilliant lavender' },
            'BRILLIANT ROSE'                => { 'out' => $csi . '38;2;255;85;163m',  'desc' => 'Brilliant rose' },
            'BRINK PINK'                    => { 'out' => $csi . '38;2;251;96;127m',  'desc' => 'Brink pink' },
            'BRITISH RACING GREEN'          => { 'out' => $csi . '38;2;0;66;37m',     'desc' => 'British racing green' },
            'BRONZE'                        => { 'out' => $csi . '38;2;205;127;50m',  'desc' => 'Bronze' },
            'BROWN'                         => { 'out' => $csi . '38;2;165;42;42m',   'desc' => 'Brown' },
            'BROWN'                         => { 'out' => $csi . '38;2;165;42;42m',   'desc' => 'Brown' },
            'BUBBLE GUM'                    => { 'out' => $csi . '38;2;255;193;204m', 'desc' => 'Bubble gum' },
            'BUBBLES'                       => { 'out' => $csi . '38;2;231;254;255m', 'desc' => 'Bubbles' },
            'BUFF'                          => { 'out' => $csi . '38;2;240;220;130m', 'desc' => 'Buff' },
            'BULGARIAN ROSE'                => { 'out' => $csi . '38;2;72;6;7m',      'desc' => 'Bulgarian rose' },
            'BURGUNDY'                      => { 'out' => $csi . '38;2;128;0;32m',    'desc' => 'Burgundy' },
            'BURLY WOOD'                    => { 'out' => $csi . '38;2;222;184;135m', 'desc' => 'Burly wood' },
            'BURLYWOOD'                     => { 'out' => $csi . '38;2;222;184;135m', 'desc' => 'Burlywood' },
            'BURNT ORANGE'                  => { 'out' => $csi . '38;2;204;85;0m',    'desc' => 'Burnt orange' },
            'BURNT SIENNA'                  => { 'out' => $csi . '38;2;233;116;81m',  'desc' => 'Burnt sienna' },
            'BURNT UMBER'                   => { 'out' => $csi . '38;2;138;51;36m',   'desc' => 'Burnt umber' },
            'BYZANTINE'                     => { 'out' => $csi . '38;2;189;51;164m',  'desc' => 'Byzantine' },
            'BYZANTIUM'                     => { 'out' => $csi . '38;2;112;41;99m',   'desc' => 'Byzantium' },
            'CADET'                         => { 'out' => $csi . '38;2;83;104;114m',  'desc' => 'Cadet' },
            'CADET BLUE'                    => { 'out' => $csi . '38;2;95;158;160m',  'desc' => 'Cadet blue' },
            'CADET BLUE'                    => { 'out' => $csi . '38;2;95;158;160m',  'desc' => 'Cadet blue' },
            'CADET GRAY'                    => { 'out' => $csi . '38;2;145;163;176m', 'desc' => 'Cadet grey' },
            'CADMIUM GREEN'                 => { 'out' => $csi . '38;2;0;107;60m',    'desc' => 'Cadmium green' },
            'CADMIUM ORANGE'                => { 'out' => $csi . '38;2;237;135;45m',  'desc' => 'Cadmium orange' },
            'CADMIUM RED'                   => { 'out' => $csi . '38;2;227;0;34m',    'desc' => 'Cadmium red' },
            'CADMIUM YELLOW'                => { 'out' => $csi . '38;2;255;246;0m',   'desc' => 'Cadmium yellow' },
            'CAFE AU LAIT'                  => { 'out' => $csi . '38;2;166;123;91m',  'desc' => 'Cafe au lait' },
            'CAFE NOIR'                     => { 'out' => $csi . '38;2;75;54;33m',    'desc' => 'Cafe noir' },
            'CAL POLY POMONA GREEN'         => { 'out' => $csi . '38;2;30;77;43m',    'desc' => 'Cal Poly Pomona green' },
            'CAMBRIDGE BLUE'                => { 'out' => $csi . '38;2;163;193;173m', 'desc' => 'Cambridge Blue' },
            'CAMEL'                         => { 'out' => $csi . '38;2;193;154;107m', 'desc' => 'Camel' },
            'CAMOUFLAGE GREEN'              => { 'out' => $csi . '38;2;120;134;107m', 'desc' => 'Camouflage green' },
            'CANARY'                        => { 'out' => $csi . '38;2;255;255;153m', 'desc' => 'Canary' },
            'CANARY YELLOW'                 => { 'out' => $csi . '38;2;255;239;0m',   'desc' => 'Canary yellow' },
            'CANDY APPLE RED'               => { 'out' => $csi . '38;2;255;8;0m',     'desc' => 'Candy apple red' },
            'CANDY PINK'                    => { 'out' => $csi . '38;2;228;113;122m', 'desc' => 'Candy pink' },
            'CAPRI'                         => { 'out' => $csi . '38;2;0;191;255m',   'desc' => 'Capri' },
            'CAPUT MORTUUM'                 => { 'out' => $csi . '38;2;89;39;32m',    'desc' => 'Caput mortuum' },
            'CARDINAL'                      => { 'out' => $csi . '38;2;196;30;58m',   'desc' => 'Cardinal' },
            'CARIBBEAN GREEN'               => { 'out' => $csi . '38;2;0;204;153m',   'desc' => 'Caribbean green' },
            'CARMINE'                       => { 'out' => $csi . '38;2;255;0;64m',    'desc' => 'Carmine' },
            'CARMINE PINK'                  => { 'out' => $csi . '38;2;235;76;66m',   'desc' => 'Carmine pink' },
            'CARMINE RED'                   => { 'out' => $csi . '38;2;255;0;56m',    'desc' => 'Carmine red' },
            'CARNATION PINK'                => { 'out' => $csi . '38;2;255;166;201m', 'desc' => 'Carnation pink' },
            'CARNELIAN'                     => { 'out' => $csi . '38;2;179;27;27m',   'desc' => 'Carnelian' },
            'CAROLINA BLUE'                 => { 'out' => $csi . '38;2;153;186;221m', 'desc' => 'Carolina blue' },
            'CARROT ORANGE'                 => { 'out' => $csi . '38;2;237;145;33m',  'desc' => 'Carrot orange' },
            'CELADON'                       => { 'out' => $csi . '38;2;172;225;175m', 'desc' => 'Celadon' },
            'CELESTE'                       => { 'out' => $csi . '38;2;178;255;255m', 'desc' => 'Celeste' },
            'CELESTIAL BLUE'                => { 'out' => $csi . '38;2;73;151;208m',  'desc' => 'Celestial blue' },
            'CERISE'                        => { 'out' => $csi . '38;2;222;49;99m',   'desc' => 'Cerise' },
            'CERISE PINK'                   => { 'out' => $csi . '38;2;236;59;131m',  'desc' => 'Cerise pink' },
            'CERULEAN'                      => { 'out' => $csi . '38;2;0;123;167m',   'desc' => 'Cerulean' },
            'CERULEAN BLUE'                 => { 'out' => $csi . '38;2;42;82;190m',   'desc' => 'Cerulean blue' },
            'CG BLUE'                       => { 'out' => $csi . '38;2;0;122;165m',   'desc' => 'CG Blue' },
            'CG RED'                        => { 'out' => $csi . '38;2;224;60;49m',   'desc' => 'CG Red' },
            'CHAMOISEE'                     => { 'out' => $csi . '38;2;160;120;90m',  'desc' => 'Chamoisee' },
            'CHAMPAGNE'                     => { 'out' => $csi . '38;2;250;214;165m', 'desc' => 'Champagne' },
            'CHARCOAL'                      => { 'out' => $csi . '38;2;54;69;79m',    'desc' => 'Charcoal' },
            'CHARTREUSE'                    => { 'out' => $csi . '38;2;127;255;0m',   'desc' => 'Chartreuse' },
            'CHARTREUSE'                    => { 'out' => $csi . '38;2;127;255;0m',   'desc' => 'Chartreuse' },
            'CHERRY'                        => { 'out' => $csi . '38;2;222;49;99m',   'desc' => 'Cherry' },
            'CHERRY BLOSSOM PINK'           => { 'out' => $csi . '38;2;255;183;197m', 'desc' => 'Cherry blossom pink' },
            'CHESTNUT'                      => { 'out' => $csi . '38;2;205;92;92m',   'desc' => 'Chestnut' },
            'CHOCOLATE'                     => { 'out' => $csi . '38;2;210;105;30m',  'desc' => 'Chocolate' },
            'CHOCOLATE'                     => { 'out' => $csi . '38;2;210;105;30m',  'desc' => 'Chocolate' },
            'CHROME YELLOW'                 => { 'out' => $csi . '38;2;255;167;0m',   'desc' => 'Chrome yellow' },
            'CINEREOUS'                     => { 'out' => $csi . '38;2;152;129;123m', 'desc' => 'Cinereous' },
            'CINNABAR'                      => { 'out' => $csi . '38;2;227;66;52m',   'desc' => 'Cinnabar' },
            'CINNAMON'                      => { 'out' => $csi . '38;2;210;105;30m',  'desc' => 'Cinnamon' },
            'CITRINE'                       => { 'out' => $csi . '38;2;228;208;10m',  'desc' => 'Citrine' },
            'CLASSIC ROSE'                  => { 'out' => $csi . '38;2;251;204;231m', 'desc' => 'Classic rose' },
            'COBALT'                        => { 'out' => $csi . '38;2;0;71;171m',    'desc' => 'Cobalt' },
            'COCOA BROWN'                   => { 'out' => $csi . '38;2;210;105;30m',  'desc' => 'Cocoa brown' },
            'COFFEE'                        => { 'out' => $csi . '38;2;111;78;55m',   'desc' => 'Coffee' },
            'COLUMBIA BLUE'                 => { 'out' => $csi . '38;2;155;221;255m', 'desc' => 'Columbia blue' },
            'COOL BLACK'                    => { 'out' => $csi . '38;2;0;46;99m',     'desc' => 'Cool black' },
            'COOL GRAY'                     => { 'out' => $csi . '38;2;140;146;172m', 'desc' => 'Cool grey' },
            'COPPER'                        => { 'out' => $csi . '38;2;184;115;51m',  'desc' => 'Copper' },
            'COPPER ROSE'                   => { 'out' => $csi . '38;2;153;102;102m', 'desc' => 'Copper rose' },
            'COQUELICOT'                    => { 'out' => $csi . '38;2;255;56;0m',    'desc' => 'Coquelicot' },
            'CORAL'                         => { 'out' => $csi . '38;2;255;127;80m',  'desc' => 'Coral' },
            'CORAL'                         => { 'out' => $csi . '38;2;255;127;80m',  'desc' => 'Coral' },
            'CORAL PINK'                    => { 'out' => $csi . '38;2;248;131;121m', 'desc' => 'Coral pink' },
            'CORAL RED'                     => { 'out' => $csi . '38;2;255;64;64m',   'desc' => 'Coral red' },
            'CORDOVAN'                      => { 'out' => $csi . '38;2;137;63;69m',   'desc' => 'Cordovan' },
            'CORN'                          => { 'out' => $csi . '38;2;251;236;93m',  'desc' => 'Corn' },
            'CORN FLOWER BLUE'              => { 'out' => $csi . '38;2;100;149;237m', 'desc' => 'Corn flower blue' },
            'CORN SILK'                     => { 'out' => $csi . '38;2;255;248;220m', 'desc' => 'Corn silk' },
            'CORNELL RED'                   => { 'out' => $csi . '38;2;179;27;27m',   'desc' => 'Cornell Red' },
            'CORNFLOWER'                    => { 'out' => $csi . '38;2;154;206;235m', 'desc' => 'Cornflower' },
            'CORNFLOWER BLUE'               => { 'out' => $csi . '38;2;100;149;237m', 'desc' => 'Cornflower blue' },
            'CORNSILK'                      => { 'out' => $csi . '38;2;255;248;220m', 'desc' => 'Cornsilk' },
            'COSMIC LATTE'                  => { 'out' => $csi . '38;2;255;248;231m', 'desc' => 'Cosmic latte' },
            'COTTON CANDY'                  => { 'out' => $csi . '38;2;255;188;217m', 'desc' => 'Cotton candy' },
            'CREAM'                         => { 'out' => $csi . '38;2;255;253;208m', 'desc' => 'Cream' },
            'CRIMSON'                       => { 'out' => $csi . '38;2;220;20;60m',   'desc' => 'Crimson' },
            'CRIMSON'                       => { 'out' => $csi . '38;2;220;20;60m',   'desc' => 'Crimson' },
            'CRIMSON GLORY'                 => { 'out' => $csi . '38;2;190;0;50m',    'desc' => 'Crimson glory' },
            'CRIMSON RED'                   => { 'out' => $csi . '38;2;153;0;0m',     'desc' => 'Crimson Red' },
            'CYAN'                          => { 'out' => $csi . '36m',               'desc' => 'Cyan' },
            'DAFFODIL'                      => { 'out' => $csi . '38;2;255;255;49m',  'desc' => 'Daffodil' },
            'DANDELION'                     => { 'out' => $csi . '38;2;240;225;48m',  'desc' => 'Dandelion' },
            'DARK BLUE'                     => { 'out' => $csi . '38;2;0;0;139m',     'desc' => 'Dark blue' },
            'DARK BLUE'                     => { 'out' => $csi . '38;2;0;0;139m',     'desc' => 'Dark blue' },
            'DARK BROWN'                    => { 'out' => $csi . '38;2;101;67;33m',   'desc' => 'Dark brown' },
            'DARK BYZANTIUM'                => { 'out' => $csi . '38;2;93;57;84m',    'desc' => 'Dark byzantium' },
            'DARK CANDY APPLE RED'          => { 'out' => $csi . '38;2;164;0;0m',     'desc' => 'Dark candy apple red' },
            'DARK CERULEAN'                 => { 'out' => $csi . '38;2;8;69;126m',    'desc' => 'Dark cerulean' },
            'DARK CHESTNUT'                 => { 'out' => $csi . '38;2;152;105;96m',  'desc' => 'Dark chestnut' },
            'DARK CORAL'                    => { 'out' => $csi . '38;2;205;91;69m',   'desc' => 'Dark coral' },
            'DARK CYAN'                     => { 'out' => $csi . '38;2;0;139;139m',   'desc' => 'Dark cyan' },
            'DARK CYAN'                     => { 'out' => $csi . '38;2;0;139;139m',   'desc' => 'Dark cyan' },
            'DARK ELECTRIC BLUE'            => { 'out' => $csi . '38;2;83;104;120m',  'desc' => 'Dark electric blue' },
            'DARK GOLDEN ROD'               => { 'out' => $csi . '38;2;184;134;11m',  'desc' => 'Dark golden rod' },
            'DARK GOLDENROD'                => { 'out' => $csi . '38;2;184;134;11m',  'desc' => 'Dark goldenrod' },
            'DARK GRAY'                     => { 'out' => $csi . '38;2;169;169;169m', 'desc' => 'Dark gray' },
            'DARK GRAY'                     => { 'out' => $csi . '38;2;169;169;169m', 'desc' => 'Dark gray' },
            'DARK GREEN'                    => { 'out' => $csi . '38;2;0;100;0m',     'desc' => 'Dark green' },
            'DARK GREEN'                    => { 'out' => $csi . '38;2;1;50;32m',     'desc' => 'Dark green' },
            'DARK JUNGLE GREEN'             => { 'out' => $csi . '38;2;26;36;33m',    'desc' => 'Dark jungle green' },
            'DARK KHAKI'                    => { 'out' => $csi . '38;2;189;183;107m', 'desc' => 'Dark khaki' },
            'DARK KHAKI'                    => { 'out' => $csi . '38;2;189;183;107m', 'desc' => 'Dark khaki' },
            'DARK LAVA'                     => { 'out' => $csi . '38;2;72;60;50m',    'desc' => 'Dark lava' },
            'DARK LAVENDER'                 => { 'out' => $csi . '38;2;115;79;150m',  'desc' => 'Dark lavender' },
            'DARK MAGENTA'                  => { 'out' => $csi . '38;2;139;0;139m',   'desc' => 'Dark magenta' },
            'DARK MAGENTA'                  => { 'out' => $csi . '38;2;139;0;139m',   'desc' => 'Dark magenta' },
            'DARK MIDNIGHT BLUE'            => { 'out' => $csi . '38;2;0;51;102m',    'desc' => 'Dark midnight blue' },
            'DARK OLIVE GREEN'              => { 'out' => $csi . '38;2;85;107;47m',   'desc' => 'Dark olive green' },
            'DARK OLIVE GREEN'              => { 'out' => $csi . '38;2;85;107;47m',   'desc' => 'Dark olive green' },
            'DARK ORANGE'                   => { 'out' => $csi . '38;2;255;140;0m',   'desc' => 'Dark orange' },
            'DARK ORANGE'                   => { 'out' => $csi . '38;2;255;140;0m',   'desc' => 'Dark orange' },
            'DARK ORCHID'                   => { 'out' => $csi . '38;2;153;50;204m',  'desc' => 'Dark orchid' },
            'DARK ORCHID'                   => { 'out' => $csi . '38;2;153;50;204m',  'desc' => 'Dark orchid' },
            'DARK PASTEL BLUE'              => { 'out' => $csi . '38;2;119;158;203m', 'desc' => 'Dark pastel blue' },
            'DARK PASTEL GREEN'             => { 'out' => $csi . '38;2;3;192;60m',    'desc' => 'Dark pastel green' },
            'DARK PASTEL PURPLE'            => { 'out' => $csi . '38;2;150;111;214m', 'desc' => 'Dark pastel purple' },
            'DARK PASTEL RED'               => { 'out' => $csi . '38;2;194;59;34m',   'desc' => 'Dark pastel red' },
            'DARK PINK'                     => { 'out' => $csi . '38;2;231;84;128m',  'desc' => 'Dark pink' },
            'DARK POWDER BLUE'              => { 'out' => $csi . '38;2;0;51;153m',    'desc' => 'Dark powder blue' },
            'DARK RASPBERRY'                => { 'out' => $csi . '38;2;135;38;87m',   'desc' => 'Dark raspberry' },
            'DARK RED'                      => { 'out' => $csi . '38;2;139;0;0m',     'desc' => 'Dark red' },
            'DARK RED'                      => { 'out' => $csi . '38;2;139;0;0m',     'desc' => 'Dark red' },
            'DARK SALMON'                   => { 'out' => $csi . '38;2;233;150;122m', 'desc' => 'Dark salmon' },
            'DARK SALMON'                   => { 'out' => $csi . '38;2;233;150;122m', 'desc' => 'Dark salmon' },
            'DARK SCARLET'                  => { 'out' => $csi . '38;2;86;3;25m',     'desc' => 'Dark scarlet' },
            'DARK SEA GREEN'                => { 'out' => $csi . '38;2;143;188;143m', 'desc' => 'Dark sea green' },
            'DARK SEA GREEN'                => { 'out' => $csi . '38;2;143;188;143m', 'desc' => 'Dark sea green' },
            'DARK SIENNA'                   => { 'out' => $csi . '38;2;60;20;20m',    'desc' => 'Dark sienna' },
            'DARK SLATE BLUE'               => { 'out' => $csi . '38;2;72;61;139m',   'desc' => 'Dark slate blue' },
            'DARK SLATE BLUE'               => { 'out' => $csi . '38;2;72;61;139m',   'desc' => 'Dark slate blue' },
            'DARK SLATE GRAY'               => { 'out' => $csi . '38;2;47;79;79m',    'desc' => 'Dark slate gray' },
            'DARK SLATE GRAY'               => { 'out' => $csi . '38;2;47;79;79m',    'desc' => 'Dark slate gray' },
            'DARK SPRING GREEN'             => { 'out' => $csi . '38;2;23;114;69m',   'desc' => 'Dark spring green' },
            'DARK TAN'                      => { 'out' => $csi . '38;2;145;129;81m',  'desc' => 'Dark tan' },
            'DARK TANGERINE'                => { 'out' => $csi . '38;2;255;168;18m',  'desc' => 'Dark tangerine' },
            'DARK TAUPE'                    => { 'out' => $csi . '38;2;72;60;50m',    'desc' => 'Dark taupe' },
            'DARK TERRA COTTA'              => { 'out' => $csi . '38;2;204;78;92m',   'desc' => 'Dark terra cotta' },
            'DARK TURQUOISE'                => { 'out' => $csi . '38;2;0;206;209m',   'desc' => 'Dark turquoise' },
            'DARK TURQUOISE'                => { 'out' => $csi . '38;2;0;206;209m',   'desc' => 'Dark turquoise' },
            'DARK VIOLET'                   => { 'out' => $csi . '38;2;148;0;211m',   'desc' => 'Dark violet' },
            'DARK VIOLET'                   => { 'out' => $csi . '38;2;148;0;211m',   'desc' => 'Dark violet' },
            'DARTMOUTH GREEN'               => { 'out' => $csi . '38;2;0;105;62m',    'desc' => 'Dartmouth green' },
            'DAVY GRAY'                     => { 'out' => $csi . '38;2;85;85;85m',    'desc' => 'Davy grey' },
            'DEBIAN RED'                    => { 'out' => $csi . '38;2;215;10;83m',   'desc' => 'Debian red' },
            'DEEP CARMINE'                  => { 'out' => $csi . '38;2;169;32;62m',   'desc' => 'Deep carmine' },
            'DEEP CARMINE PINK'             => { 'out' => $csi . '38;2;239;48;56m',   'desc' => 'Deep carmine pink' },
            'DEEP CARROT ORANGE'            => { 'out' => $csi . '38;2;233;105;44m',  'desc' => 'Deep carrot orange' },
            'DEEP CERISE'                   => { 'out' => $csi . '38;2;218;50;135m',  'desc' => 'Deep cerise' },
            'DEEP CHAMPAGNE'                => { 'out' => $csi . '38;2;250;214;165m', 'desc' => 'Deep champagne' },
            'DEEP CHESTNUT'                 => { 'out' => $csi . '38;2;185;78;72m',   'desc' => 'Deep chestnut' },
            'DEEP COFFEE'                   => { 'out' => $csi . '38;2;112;66;65m',   'desc' => 'Deep coffee' },
            'DEEP FUCHSIA'                  => { 'out' => $csi . '38;2;193;84;193m',  'desc' => 'Deep fuchsia' },
            'DEEP JUNGLE GREEN'             => { 'out' => $csi . '38;2;0;75;73m',     'desc' => 'Deep jungle green' },
            'DEEP LILAC'                    => { 'out' => $csi . '38;2;153;85;187m',  'desc' => 'Deep lilac' },
            'DEEP MAGENTA'                  => { 'out' => $csi . '38;2;204;0;204m',   'desc' => 'Deep magenta' },
            'DEEP PEACH'                    => { 'out' => $csi . '38;2;255;203;164m', 'desc' => 'Deep peach' },
            'DEEP PINK'                     => { 'out' => $csi . '38;2;255;20;147m',  'desc' => 'Deep pink' },
            'DEEP PINK'                     => { 'out' => $csi . '38;2;255;20;147m',  'desc' => 'Deep pink' },
            'DEEP SAFFRON'                  => { 'out' => $csi . '38;2;255;153;51m',  'desc' => 'Deep saffron' },
            'DEEP SKY BLUE'                 => { 'out' => $csi . '38;2;0;191;255m',   'desc' => 'Deep sky blue' },
            'DEEP SKY BLUE'                 => { 'out' => $csi . '38;2;0;191;255m',   'desc' => 'Deep sky blue' },
            'DEFAULT'                       => { 'out' => $csi . '39m',               'desc' => 'Default Foreground/Background Color' },
            'DENIM'                         => { 'out' => $csi . '38;2;21;96;189m',   'desc' => 'Denim' },
            'DESERT'                        => { 'out' => $csi . '38;2;193;154;107m', 'desc' => 'Desert' },
            'DESERT SAND'                   => { 'out' => $csi . '38;2;237;201;175m', 'desc' => 'Desert sand' },
            'DIM GRAY'                      => { 'out' => $csi . '38;2;105;105;105m', 'desc' => 'Dim gray' },
            'DIM GRAY'                      => { 'out' => $csi . '38;2;105;105;105m', 'desc' => 'Dim gray' },
            'DODGER BLUE'                   => { 'out' => $csi . '38;2;30;144;255m',  'desc' => 'Dodger blue' },
            'DODGER BLUE'                   => { 'out' => $csi . '38;2;30;144;255m',  'desc' => 'Dodger blue' },
            'DOGWOOD ROSE'                  => { 'out' => $csi . '38;2;215;24;104m',  'desc' => 'Dogwood rose' },
            'DOLLAR BILL'                   => { 'out' => $csi . '38;2;133;187;101m', 'desc' => 'Dollar bill' },
            'DRAB'                          => { 'out' => $csi . '38;2;150;113;23m',  'desc' => 'Drab' },
            'DUKE BLUE'                     => { 'out' => $csi . '38;2;0;0;156m',     'desc' => 'Duke blue' },
            'EARTH YELLOW'                  => { 'out' => $csi . '38;2;225;169;95m',  'desc' => 'Earth yellow' },
            'ECRU'                          => { 'out' => $csi . '38;2;194;178;128m', 'desc' => 'Ecru' },
            'EGGPLANT'                      => { 'out' => $csi . '38;2;97;64;81m',    'desc' => 'Eggplant' },
            'EGGSHELL'                      => { 'out' => $csi . '38;2;240;234;214m', 'desc' => 'Eggshell' },
            'EGYPTIAN BLUE'                 => { 'out' => $csi . '38;2;16;52;166m',   'desc' => 'Egyptian blue' },
            'ELECTRIC BLUE'                 => { 'out' => $csi . '38;2;125;249;255m', 'desc' => 'Electric blue' },
            'ELECTRIC CRIMSON'              => { 'out' => $csi . '38;2;255;0;63m',    'desc' => 'Electric crimson' },
            'ELECTRIC CYAN'                 => { 'out' => $csi . '38;2;0;255;255m',   'desc' => 'Electric cyan' },
            'ELECTRIC GREEN'                => { 'out' => $csi . '38;2;0;255;0m',     'desc' => 'Electric green' },
            'ELECTRIC INDIGO'               => { 'out' => $csi . '38;2;111;0;255m',   'desc' => 'Electric indigo' },
            'ELECTRIC LAVENDER'             => { 'out' => $csi . '38;2;244;187;255m', 'desc' => 'Electric lavender' },
            'ELECTRIC LIME'                 => { 'out' => $csi . '38;2;204;255;0m',   'desc' => 'Electric lime' },
            'ELECTRIC PURPLE'               => { 'out' => $csi . '38;2;191;0;255m',   'desc' => 'Electric purple' },
            'ELECTRIC ULTRAMARINE'          => { 'out' => $csi . '38;2;63;0;255m',    'desc' => 'Electric ultramarine' },
            'ELECTRIC VIOLET'               => { 'out' => $csi . '38;2;143;0;255m',   'desc' => 'Electric violet' },
            'ELECTRIC YELLOW'               => { 'out' => $csi . '38;2;255;255;0m',   'desc' => 'Electric yellow' },
            'EMERALD'                       => { 'out' => $csi . '38;2;80;200;120m',  'desc' => 'Emerald' },
            'ETON BLUE'                     => { 'out' => $csi . '38;2;150;200;162m', 'desc' => 'Eton blue' },
            'FALLOW'                        => { 'out' => $csi . '38;2;193;154;107m', 'desc' => 'Fallow' },
            'FALU RED'                      => { 'out' => $csi . '38;2;128;24;24m',   'desc' => 'Falu red' },
            'FAMOUS'                        => { 'out' => $csi . '38;2;255;0;255m',   'desc' => 'Famous' },
            'FANDANGO'                      => { 'out' => $csi . '38;2;181;51;137m',  'desc' => 'Fandango' },
            'FASHION FUCHSIA'               => { 'out' => $csi . '38;2;244;0;161m',   'desc' => 'Fashion fuchsia' },
            'FAWN'                          => { 'out' => $csi . '38;2;229;170;112m', 'desc' => 'Fawn' },
            'FELDGRAU'                      => { 'out' => $csi . '38;2;77;93;83m',    'desc' => 'Feldgrau' },
            'FERN'                          => { 'out' => $csi . '38;2;113;188;120m', 'desc' => 'Fern' },
            'FERN GREEN'                    => { 'out' => $csi . '38;2;79;121;66m',   'desc' => 'Fern green' },
            'FERRARI RED'                   => { 'out' => $csi . '38;2;255;40;0m',    'desc' => 'Ferrari Red' },
            'FIELD DRAB'                    => { 'out' => $csi . '38;2;108;84;30m',   'desc' => 'Field drab' },
            'FIRE ENGINE RED'               => { 'out' => $csi . '38;2;206;32;41m',   'desc' => 'Fire engine red' },
            'FIREBRICK'                     => { 'out' => $csi . '38;2;178;34;34m',   'desc' => 'Firebrick' },
            'FIREBRICK'                     => { 'out' => $csi . '38;2;178;34;34m',   'desc' => 'Firebrick' },
            'FLAME'                         => { 'out' => $csi . '38;2;226;88;34m',   'desc' => 'Flame' },
            'FLAMINGO PINK'                 => { 'out' => $csi . '38;2;252;142;172m', 'desc' => 'Flamingo pink' },
            'FLAVESCENT'                    => { 'out' => $csi . '38;2;247;233;142m', 'desc' => 'Flavescent' },
            'FLAX'                          => { 'out' => $csi . '38;2;238;220;130m', 'desc' => 'Flax' },
            'FLORAL WHITE'                  => { 'out' => $csi . '38;2;255;250;240m', 'desc' => 'Floral white' },
            'FLORAL WHITE'                  => { 'out' => $csi . '38;2;255;250;240m', 'desc' => 'Floral white' },
            'FLUORESCENT ORANGE'            => { 'out' => $csi . '38;2;255;191;0m',   'desc' => 'Fluorescent orange' },
            'FLUORESCENT PINK'              => { 'out' => $csi . '38;2;255;20;147m',  'desc' => 'Fluorescent pink' },
            'FLUORESCENT YELLOW'            => { 'out' => $csi . '38;2;204;255;0m',   'desc' => 'Fluorescent yellow' },
            'FOLLY'                         => { 'out' => $csi . '38;2;255;0;79m',    'desc' => 'Folly' },
            'FOREST GREEN'                  => { 'out' => $csi . '38;2;34;139;34m',   'desc' => 'Forest green' },
            'FOREST GREEN'                  => { 'out' => $csi . '38;2;34;139;34m',   'desc' => 'Forest green' },
            'FRENCH BEIGE'                  => { 'out' => $csi . '38;2;166;123;91m',  'desc' => 'French beige' },
            'FRENCH BLUE'                   => { 'out' => $csi . '38;2;0;114;187m',   'desc' => 'French blue' },
            'FRENCH LILAC'                  => { 'out' => $csi . '38;2;134;96;142m',  'desc' => 'French lilac' },
            'FRENCH ROSE'                   => { 'out' => $csi . '38;2;246;74;138m',  'desc' => 'French rose' },
            'FUCHSIA'                       => { 'out' => $csi . '38;2;255;0;255m',   'desc' => 'Fuchsia' },
            'FUCHSIA PINK'                  => { 'out' => $csi . '38;2;255;119;255m', 'desc' => 'Fuchsia pink' },
            'FULVOUS'                       => { 'out' => $csi . '38;2;228;132;0m',   'desc' => 'Fulvous' },
            'FUZZY WUZZY'                   => { 'out' => $csi . '38;2;204;102;102m', 'desc' => 'Fuzzy Wuzzy' },
            'GAINSBORO'                     => { 'out' => $csi . '38;2;220;220;220m', 'desc' => 'Gainsboro' },
            'GAINSBORO'                     => { 'out' => $csi . '38;2;220;220;220m', 'desc' => 'Gainsboro' },
            'GAMBOGE'                       => { 'out' => $csi . '38;2;228;155;15m',  'desc' => 'Gamboge' },
            'GHOST WHITE'                   => { 'out' => $csi . '38;2;248;248;255m', 'desc' => 'Ghost white' },
            'GHOST WHITE'                   => { 'out' => $csi . '38;2;248;248;255m', 'desc' => 'Ghost white' },
            'GINGER'                        => { 'out' => $csi . '38;2;176;101;0m',   'desc' => 'Ginger' },
            'GLAUCOUS'                      => { 'out' => $csi . '38;2;96;130;182m',  'desc' => 'Glaucous' },
            'GLITTER'                       => { 'out' => $csi . '38;2;230;232;250m', 'desc' => 'Glitter' },
            'GOLD'                          => { 'out' => $csi . '38;2;255;215;0m',   'desc' => 'Gold' },
            'GOLD'                          => { 'out' => $csi . '38;2;255;215;0m',   'desc' => 'Gold' },
            'GOLDEN BROWN'                  => { 'out' => $csi . '38;2;153;101;21m',  'desc' => 'Golden brown' },
            'GOLDEN POPPY'                  => { 'out' => $csi . '38;2;252;194;0m',   'desc' => 'Golden poppy' },
            'GOLDEN ROD'                    => { 'out' => $csi . '38;2;218;165;32m',  'desc' => 'Golden rod' },
            'GOLDEN YELLOW'                 => { 'out' => $csi . '38;2;255;223;0m',   'desc' => 'Golden yellow' },
            'GOLDENROD'                     => { 'out' => $csi . '38;2;218;165;32m',  'desc' => 'Goldenrod' },
            'GRANNY SMITH APPLE'            => { 'out' => $csi . '38;2;168;228;160m', 'desc' => 'Granny Smith Apple' },
            'GRAY'                          => { 'out' => $csi . '38;2;128;128;128m', 'desc' => 'Gray' },
            'GRAY ASPARAGUS'                => { 'out' => $csi . '38;2;70;89;69m',    'desc' => 'Gray asparagus' },
            'GREEN'                         => { 'out' => $csi . '32m',               'desc' => 'Green' },
            'GREEN BLUE'                    => { 'out' => $csi . '38;2;17;100;180m',  'desc' => 'Green Blue' },
            'GREEN YELLOW'                  => { 'out' => $csi . '38;2;173;255;47m',  'desc' => 'Green yellow' },
            'GREEN YELLOW'                  => { 'out' => $csi . '38;2;173;255;47m',  'desc' => 'Green yellow' },
            'GRULLO'                        => { 'out' => $csi . '38;2;169;154;134m', 'desc' => 'Grullo' },
            'GUPPIE GREEN'                  => { 'out' => $csi . '38;2;0;255;127m',   'desc' => 'Guppie green' },
            'HALAYA UBE'                    => { 'out' => $csi . '38;2;102;56;84m',   'desc' => 'Halaya ube' },
            'HAN BLUE'                      => { 'out' => $csi . '38;2;68;108;207m',  'desc' => 'Han blue' },
            'HAN PURPLE'                    => { 'out' => $csi . '38;2;82;24;250m',   'desc' => 'Han purple' },
            'HANSA YELLOW'                  => { 'out' => $csi . '38;2;233;214;107m', 'desc' => 'Hansa yellow' },
            'HARLEQUIN'                     => { 'out' => $csi . '38;2;63;255;0m',    'desc' => 'Harlequin' },
            'HARVARD CRIMSON'               => { 'out' => $csi . '38;2;201;0;22m',    'desc' => 'Harvard crimson' },
            'HARVEST GOLD'                  => { 'out' => $csi . '38;2;218;145;0m',   'desc' => 'Harvest Gold' },
            'HEART GOLD'                    => { 'out' => $csi . '38;2;128;128;0m',   'desc' => 'Heart Gold' },
            'HELIOTROPE'                    => { 'out' => $csi . '38;2;223;115;255m', 'desc' => 'Heliotrope' },
            'HOLLYWOOD CERISE'              => { 'out' => $csi . '38;2;244;0;161m',   'desc' => 'Hollywood cerise' },
            'HONEYDEW'                      => { 'out' => $csi . '38;2;240;255;240m', 'desc' => 'Honeydew' },
            'HONEYDEW'                      => { 'out' => $csi . '38;2;240;255;240m', 'desc' => 'Honeydew' },
            'HOOKER GREEN'                  => { 'out' => $csi . '38;2;73;121;107m',  'desc' => 'Hooker green' },
            'HOT MAGENTA'                   => { 'out' => $csi . '38;2;255;29;206m',  'desc' => 'Hot magenta' },
            'HOT PINK'                      => { 'out' => $csi . '38;2;255;105;180m', 'desc' => 'Hot pink' },
            'HOT PINK'                      => { 'out' => $csi . '38;2;255;105;180m', 'desc' => 'Hot pink' },
            'HUNTER GREEN'                  => { 'out' => $csi . '38;2;53;94;59m',    'desc' => 'Hunter green' },
            'ICTERINE'                      => { 'out' => $csi . '38;2;252;247;94m',  'desc' => 'Icterine' },
            'INCHWORM'                      => { 'out' => $csi . '38;2;178;236;93m',  'desc' => 'Inchworm' },
            'INDIA GREEN'                   => { 'out' => $csi . '38;2;19;136;8m',    'desc' => 'India green' },
            'INDIAN RED'                    => { 'out' => $csi . '38;2;205;92;92m',   'desc' => 'Indian red' },
            'INDIAN RED'                    => { 'out' => $csi . '38;2;205;92;92m',   'desc' => 'Indian red' },
            'INDIAN YELLOW'                 => { 'out' => $csi . '38;2;227;168;87m',  'desc' => 'Indian yellow' },
            'INDIGO'                        => { 'out' => $csi . '38;2;75;0;130m',    'desc' => 'Indigo' },
            'INDIGO'                        => { 'out' => $csi . '38;2;75;0;130m',    'desc' => 'Indigo' },
            'INTERNATIONAL KLEIN'           => { 'out' => $csi . '38;2;0;47;167m',    'desc' => 'International Klein' },
            'INTERNATIONAL ORANGE'          => { 'out' => $csi . '38;2;255;79;0m',    'desc' => 'International orange' },
            'IRIS'                          => { 'out' => $csi . '38;2;90;79;207m',   'desc' => 'Iris' },
            'ISABELLINE'                    => { 'out' => $csi . '38;2;244;240;236m', 'desc' => 'Isabelline' },
            'ISLAMIC GREEN'                 => { 'out' => $csi . '38;2;0;144;0m',     'desc' => 'Islamic green' },
            'IVORY'                         => { 'out' => $csi . '38;2;255;255;240m', 'desc' => 'Ivory' },
            'IVORY'                         => { 'out' => $csi . '38;2;255;255;240m', 'desc' => 'Ivory' },
            'JADE'                          => { 'out' => $csi . '38;2;0;168;107m',   'desc' => 'Jade' },
            'JASMINE'                       => { 'out' => $csi . '38;2;248;222;126m', 'desc' => 'Jasmine' },
            'JASPER'                        => { 'out' => $csi . '38;2;215;59;62m',   'desc' => 'Jasper' },
            'JAZZBERRY JAM'                 => { 'out' => $csi . '38;2;165;11;94m',   'desc' => 'Jazzberry jam' },
            'JONQUIL'                       => { 'out' => $csi . '38;2;250;218;94m',  'desc' => 'Jonquil' },
            'JUNE BUD'                      => { 'out' => $csi . '38;2;189;218;87m',  'desc' => 'June bud' },
            'JUNGLE GREEN'                  => { 'out' => $csi . '38;2;41;171;135m',  'desc' => 'Jungle green' },
            'KELLY GREEN'                   => { 'out' => $csi . '38;2;76;187;23m',   'desc' => 'Kelly green' },
            'KHAKI'                         => { 'out' => $csi . '38;2;195;176;145m', 'desc' => 'Khaki' },
            'KHAKI'                         => { 'out' => $csi . '38;2;240;230;140m', 'desc' => 'Khaki' },
            'KU CRIMSON'                    => { 'out' => $csi . '38;2;232;0;13m',    'desc' => 'KU Crimson' },
            'LA SALLE GREEN'                => { 'out' => $csi . '38;2;8;120;48m',    'desc' => 'La Salle Green' },
            'LANGUID LAVENDER'              => { 'out' => $csi . '38;2;214;202;221m', 'desc' => 'Languid lavender' },
            'LAPIS LAZULI'                  => { 'out' => $csi . '38;2;38;97;156m',   'desc' => 'Lapis lazuli' },
            'LASER LEMON'                   => { 'out' => $csi . '38;2;254;254;34m',  'desc' => 'Laser Lemon' },
            'LAUREL GREEN'                  => { 'out' => $csi . '38;2;169;186;157m', 'desc' => 'Laurel green' },
            'LAVA'                          => { 'out' => $csi . '38;2;207;16;32m',   'desc' => 'Lava' },
            'LAVENDER'                      => { 'out' => $csi . '38;2;230;230;250m', 'desc' => 'Lavender' },
            'LAVENDER'                      => { 'out' => $csi . '38;2;230;230;250m', 'desc' => 'Lavender' },
            'LAVENDER BLUE'                 => { 'out' => $csi . '38;2;204;204;255m', 'desc' => 'Lavender blue' },
            'LAVENDER BLUSH'                => { 'out' => $csi . '38;2;255;240;245m', 'desc' => 'Lavender blush' },
            'LAVENDER BLUSH'                => { 'out' => $csi . '38;2;255;240;245m', 'desc' => 'Lavender blush' },
            'LAVENDER GRAY'                 => { 'out' => $csi . '38;2;196;195;208m', 'desc' => 'Lavender gray' },
            'LAVENDER INDIGO'               => { 'out' => $csi . '38;2;148;87;235m',  'desc' => 'Lavender indigo' },
            'LAVENDER MAGENTA'              => { 'out' => $csi . '38;2;238;130;238m', 'desc' => 'Lavender magenta' },
            'LAVENDER MIST'                 => { 'out' => $csi . '38;2;230;230;250m', 'desc' => 'Lavender mist' },
            'LAVENDER PINK'                 => { 'out' => $csi . '38;2;251;174;210m', 'desc' => 'Lavender pink' },
            'LAVENDER PURPLE'               => { 'out' => $csi . '38;2;150;123;182m', 'desc' => 'Lavender purple' },
            'LAVENDER ROSE'                 => { 'out' => $csi . '38;2;251;160;227m', 'desc' => 'Lavender rose' },
            'LAWN GREEN'                    => { 'out' => $csi . '38;2;124;252;0m',   'desc' => 'Lawn green' },
            'LAWN GREEN'                    => { 'out' => $csi . '38;2;124;252;0m',   'desc' => 'Lawn green' },
            'LEMON'                         => { 'out' => $csi . '38;2;255;247;0m',   'desc' => 'Lemon' },
            'LEMON CHIFFON'                 => { 'out' => $csi . '38;2;255;250;205m', 'desc' => 'Lemon chiffon' },
            'LEMON CHIFFON'                 => { 'out' => $csi . '38;2;255;250;205m', 'desc' => 'Lemon chiffon' },
            'LEMON LIME'                    => { 'out' => $csi . '38;2;191;255;0m',   'desc' => 'Lemon lime' },
            'LEMON YELLOW'                  => { 'out' => $csi . '38;2;255;244;79m',  'desc' => 'Lemon Yellow' },
            'LIGHT APRICOT'                 => { 'out' => $csi . '38;2;253;213;177m', 'desc' => 'Light apricot' },
            'LIGHT BLUE'                    => { 'out' => $csi . '38;2;173;216;230m', 'desc' => 'Light blue' },
            'LIGHT BLUE'                    => { 'out' => $csi . '38;2;173;216;230m', 'desc' => 'Light blue', },
            'LIGHT BROWN'                   => { 'out' => $csi . '38;2;181;101;29m',  'desc' => 'Light brown' },
            'LIGHT CARMINE PINK'            => { 'out' => $csi . '38;2;230;103;113m', 'desc' => 'Light carmine pink' },
            'LIGHT CORAL'                   => { 'out' => $csi . '38;2;240;128;128m', 'desc' => 'Light coral' },
            'LIGHT CORAL'                   => { 'out' => $csi . '38;2;240;128;128m', 'desc' => 'Light coral' },
            'LIGHT CORNFLOWER BLUE'         => { 'out' => $csi . '38;2;147;204;234m', 'desc' => 'Light cornflower blue' },
            'LIGHT CRIMSON'                 => { 'out' => $csi . '38;2;245;105;145m', 'desc' => 'Light Crimson' },
            'LIGHT CYAN'                    => { 'out' => $csi . '38;2;224;255;255m', 'desc' => 'Light cyan' },
            'LIGHT CYAN'                    => { 'out' => $csi . '38;2;224;255;255m', 'desc' => 'Light cyan' },
            'LIGHT FUCHSIA PINK'            => { 'out' => $csi . '38;2;249;132;239m', 'desc' => 'Light fuchsia pink' },
            'LIGHT GOLDEN ROD YELLOW'       => { 'out' => $csi . '38;2;250;250;210m', 'desc' => 'Light golden rod yellow' },
            'LIGHT GOLDENROD YELLOW'        => { 'out' => $csi . '38;2;250;250;210m', 'desc' => 'Light goldenrod yellow' },
            'LIGHT GRAY'                    => { 'out' => $csi . '38;2;211;211;211m', 'desc' => 'Light gray' },
            'LIGHT GRAY'                    => { 'out' => $csi . '38;2;211;211;211m', 'desc' => 'Light gray' },
            'LIGHT GREEN'                   => { 'out' => $csi . '38;2;144;238;144m', 'desc' => 'Light green' },
            'LIGHT GREEN'                   => { 'out' => $csi . '38;2;144;238;144m', 'desc' => 'Light green' },
            'LIGHT KHAKI'                   => { 'out' => $csi . '38;2;240;230;140m', 'desc' => 'Light khaki' },
            'LIGHT PASTEL PURPLE'           => { 'out' => $csi . '38;2;177;156;217m', 'desc' => 'Light pastel purple' },
            'LIGHT PINK'                    => { 'out' => $csi . '38;2;255;182;193m', 'desc' => 'Light pink' },
            'LIGHT PINK'                    => { 'out' => $csi . '38;2;255;182;193m', 'desc' => 'Light pink' },
            'LIGHT SALMON'                  => { 'out' => $csi . '38;2;255;160;122m', 'desc' => 'Light salmon' },
            'LIGHT SALMON'                  => { 'out' => $csi . '38;2;255;160;122m', 'desc' => 'Light salmon' },
            'LIGHT SALMON PINK'             => { 'out' => $csi . '38;2;255;153;153m', 'desc' => 'Light salmon pink' },
            'LIGHT SEA GREEN'               => { 'out' => $csi . '38;2;32;178;170m',  'desc' => 'Light sea green' },
            'LIGHT SEA GREEN'               => { 'out' => $csi . '38;2;32;178;170m',  'desc' => 'Light sea green' },
            'LIGHT SKY BLUE'                => { 'out' => $csi . '38;2;135;206;250m', 'desc' => 'Light sky blue' },
            'LIGHT SKY BLUE'                => { 'out' => $csi . '38;2;135;206;250m', 'desc' => 'Light sky blue' },
            'LIGHT SLATE GRAY'              => { 'out' => $csi . '38;2;119;136;153m', 'desc' => 'Light slate gray' },
            'LIGHT SLATE GRAY'              => { 'out' => $csi . '38;2;119;136;153m', 'desc' => 'Lisght slate gray' },
            'LIGHT STEEL BLUE'              => { 'out' => $csi . '38;2;176;196;222m', 'desc' => 'Light steel blue' },
            'LIGHT TAUPE'                   => { 'out' => $csi . '38;2;179;139;109m', 'desc' => 'Light taupe' },
            'LIGHT THULIAN PINK'            => { 'out' => $csi . '38;2;230;143;172m', 'desc' => 'Light Thulian pink' },
            'LIGHT YELLOW'                  => { 'out' => $csi . '38;2;255;255;224m', 'desc' => 'Light yellow' },
            'LIGHT YELLOW'                  => { 'out' => $csi . '38;2;255;255;237m', 'desc' => 'Light yellow' },
            'LILAC'                         => { 'out' => $csi . '38;2;200;162;200m', 'desc' => 'Lilac' },
            'LIME'                          => { 'out' => $csi . '38;2;191;255;0m',   'desc' => 'Lime' },
            'LIME GREEN'                    => { 'out' => $csi . '38;2;50;205;50m',   'desc' => 'Lime green' },
            'LIME GREEN'                    => { 'out' => $csi . '38;2;50;205;50m',   'desc' => 'Lime Green' },
            'LINCOLN GREEN'                 => { 'out' => $csi . '38;2;25;89;5m',     'desc' => 'Lincoln green' },
            'LINEN'                         => { 'out' => $csi . '38;2;250;240;230m', 'desc' => 'Linen' },
            'LINEN'                         => { 'out' => $csi . '38;2;250;240;230m', 'desc' => 'Linen' },
            'LION'                          => { 'out' => $csi . '38;2;193;154;107m', 'desc' => 'Lion' },
            'LIVER'                         => { 'out' => $csi . '38;2;83;75;79m',    'desc' => 'Liver' },
            'LUST'                          => { 'out' => $csi . '38;2;230;32;32m',   'desc' => 'Lust' },
            'MACARONI AND CHEESE'           => { 'out' => $csi . '38;2;255;189;136m', 'desc' => 'Macaroni and Cheese' },
            'MAGENTA'                       => { 'out' => $csi . '35m',               'desc' => 'Magenta' },
            'MAGIC MINT'                    => { 'out' => $csi . '38;2;170;240;209m', 'desc' => 'Magic mint' },
            'MAGNOLIA'                      => { 'out' => $csi . '38;2;248;244;255m', 'desc' => 'Magnolia' },
            'MAHOGANY'                      => { 'out' => $csi . '38;2;192;64;0m',    'desc' => 'Mahogany' },
            'MAIZE'                         => { 'out' => $csi . '38;2;251;236;93m',  'desc' => 'Maize' },
            'MAJORELLE BLUE'                => { 'out' => $csi . '38;2;96;80;220m',   'desc' => 'Majorelle Blue' },
            'MALACHITE'                     => { 'out' => $csi . '38;2;11;218;81m',   'desc' => 'Malachite' },
            'MANATEE'                       => { 'out' => $csi . '38;2;151;154;170m', 'desc' => 'Manatee' },
            'MANGO TANGO'                   => { 'out' => $csi . '38;2;255;130;67m',  'desc' => 'Mango Tango' },
            'MANTIS'                        => { 'out' => $csi . '38;2;116;195;101m', 'desc' => 'Mantis' },
            'MAROON'                        => { 'out' => $csi . '38;2;128;0;0m',     'desc' => 'Maroon' },
            'MAROON'                        => { 'out' => $csi . '38;2;128;0;0m',     'desc' => 'Maroon' },
            'MAUVE'                         => { 'out' => $csi . '38;2;224;176;255m', 'desc' => 'Mauve' },
            'MAUVE TAUPE'                   => { 'out' => $csi . '38;2;145;95;109m',  'desc' => 'Mauve taupe' },
            'MAUVELOUS'                     => { 'out' => $csi . '38;2;239;152;170m', 'desc' => 'Mauvelous' },
            'MAYA BLUE'                     => { 'out' => $csi . '38;2;115;194;251m', 'desc' => 'Maya blue' },
            'MEAT BROWN'                    => { 'out' => $csi . '38;2;229;183;59m',  'desc' => 'Meat brown' },
            'MEDIUM AQUA MARINE'            => { 'out' => $csi . '38;2;102;205;170m', 'desc' => 'Medium aqua marine' },
            'MEDIUM AQUAMARINE'             => { 'out' => $csi . '38;2;102;221;170m', 'desc' => 'Medium aquamarine' },
            'MEDIUM BLUE'                   => { 'out' => $csi . '38;2;0;0;205m',     'desc' => 'Medium blue' },
            'MEDIUM BLUE'                   => { 'out' => $csi . '38;2;0;0;205m',     'desc' => 'Medium blue' },
            'MEDIUM CANDY APPLE RED'        => { 'out' => $csi . '38;2;226;6;44m',    'desc' => 'Medium candy apple red' },
            'MEDIUM CARMINE'                => { 'out' => $csi . '38;2;175;64;53m',   'desc' => 'Medium carmine' },
            'MEDIUM CHAMPAGNE'              => { 'out' => $csi . '38;2;243;229;171m', 'desc' => 'Medium champagne' },
            'MEDIUM ELECTRIC BLUE'          => { 'out' => $csi . '38;2;3;80;150m',    'desc' => 'Medium electric blue' },
            'MEDIUM JUNGLE GREEN'           => { 'out' => $csi . '38;2;28;53;45m',    'desc' => 'Medium jungle green' },
            'MEDIUM LAVENDER MAGENTA'       => { 'out' => $csi . '38;2;221;160;221m', 'desc' => 'Medium lavender magenta' },
            'MEDIUM ORCHID'                 => { 'out' => $csi . '38;2;186;85;211m',  'desc' => 'Medium orchid' },
            'MEDIUM ORCHID'                 => { 'out' => $csi . '38;2;186;85;211m',  'desc' => 'Medium orchid' },
            'MEDIUM PERSIAN BLUE'           => { 'out' => $csi . '38;2;0;103;165m',   'desc' => 'Medium Persian blue' },
            'MEDIUM PURPLE'                 => { 'out' => $csi . '38;2;147;112;219m', 'desc' => 'Medium purple' },
            'MEDIUM PURPLE'                 => { 'out' => $csi . '38;2;147;112;219m', 'desc' => 'Medium purple' },
            'MEDIUM RED VIOLET'             => { 'out' => $csi . '38;2;187;51;133m',  'desc' => 'Medium red violet' },
            'MEDIUM SEA GREEN'              => { 'out' => $csi . '38;2;60;179;113m',  'desc' => 'Medium sea green' },
            'MEDIUM SEA GREEN'              => { 'out' => $csi . '38;2;60;179;113m',  'desc' => 'Medium sea green' },
            'MEDIUM SLATE BLUE'             => { 'out' => $csi . '38;2;123;104;238m', 'desc' => 'Medium slate blue' },
            'MEDIUM SLATE BLUE'             => { 'out' => $csi . '38;2;123;104;238m', 'desc' => 'Medium slate blue' },
            'MEDIUM SPRING BUD'             => { 'out' => $csi . '38;2;201;220;135m', 'desc' => 'Medium spring bud' },
            'MEDIUM SPRING GREEN'           => { 'out' => $csi . '38;2;0;250;154m',   'desc' => 'Medium spring green' },
            'MEDIUM SPRING GREEN'           => { 'out' => $csi . '38;2;0;250;154m',   'desc' => 'Medium spring green' },
            'MEDIUM TAUPE'                  => { 'out' => $csi . '38;2;103;76;71m',   'desc' => 'Medium taupe' },
            'MEDIUM TEAL BLUE'              => { 'out' => $csi . '38;2;0;84;180m',    'desc' => 'Medium teal blue' },
            'MEDIUM TURQUOISE'              => { 'out' => $csi . '38;2;72;209;204m',  'desc' => 'Medium turquoise' },
            'MEDIUM TURQUOISE'              => { 'out' => $csi . '38;2;72;209;204m',  'desc' => 'Medium turquoise' },
            'MEDIUM VIOLET RED'             => { 'out' => $csi . '38;2;199;21;133m',  'desc' => 'Medium violet red' },
            'MEDIUM VIOLET RED'             => { 'out' => $csi . '38;2;199;21;133m',  'desc' => 'Medium violet red' },
            'MELON'                         => { 'out' => $csi . '38;2;253;188;180m', 'desc' => 'Melon' },
            'MIDNIGHT BLUE'                 => { 'out' => $csi . '38;2;25;25;112m',   'desc' => 'Midnight blue' },
            'MIDNIGHT BLUE'                 => { 'out' => $csi . '38;2;25;25;112m',   'desc' => 'Midnight blue' },
            'MIDNIGHT GREEN'                => { 'out' => $csi . '38;2;0;73;83m',     'desc' => 'Midnight green' },
            'MIKADO YELLOW'                 => { 'out' => $csi . '38;2;255;196;12m',  'desc' => 'Mikado yellow' },
            'MINT'                          => { 'out' => $csi . '38;2;62;180;137m',  'desc' => 'Mint' },
            'MINT CREAM'                    => { 'out' => $csi . '38;2;245;255;250m', 'desc' => 'Mint cream' },
            'MINT CREAM'                    => { 'out' => $csi . '38;2;245;255;250m', 'desc' => 'Mint green' },
            'MINT GREEN'                    => { 'out' => $csi . '38;2;152;255;152m', 'desc' => 'Mint green' },
            'MISTY ROSE'                    => { 'out' => $csi . '38;2;255;228;225m', 'desc' => 'Misty rose' },
            'MISTY ROSE'                    => { 'out' => $csi . '38;2;255;228;225m', 'desc' => 'Misty rose' },
            'MOCCASIN'                      => { 'out' => $csi . '38;2;250;235;215m', 'desc' => 'Moccasin' },
            'MOCCASIN'                      => { 'out' => $csi . '38;2;255;228;181m', 'desc' => 'Moccasin' },
            'MODE BEIGE'                    => { 'out' => $csi . '38;2;150;113;23m',  'desc' => 'Mode beige' },
            'MOONSTONE BLUE'                => { 'out' => $csi . '38;2;115;169;194m', 'desc' => 'Moonstone blue' },
            'MORDANT RED 19'                => { 'out' => $csi . '38;2;174;12;0m',    'desc' => 'Mordant red 19' },
            'MOSS GREEN'                    => { 'out' => $csi . '38;2;173;223;173m', 'desc' => 'Moss green' },
            'MOUNTAIN MEADOW'               => { 'out' => $csi . '38;2;48;186;143m',  'desc' => 'Mountain Meadow' },
            'MOUNTBATTEN PINK'              => { 'out' => $csi . '38;2;153;122;141m', 'desc' => 'Mountbatten pink' },
            'MSU GREEN'                     => { 'out' => $csi . '38;2;24;69;59m',    'desc' => 'MSU Green' },
            'MULBERRY'                      => { 'out' => $csi . '38;2;197;75;140m',  'desc' => 'Mulberry' },
            'MUNSELL'                       => { 'out' => $csi . '38;2;242;243;244m', 'desc' => 'Munsell' },
            'MUSTARD'                       => { 'out' => $csi . '38;2;255;219;88m',  'desc' => 'Mustard' },
            'MYRTLE'                        => { 'out' => $csi . '38;2;33;66;30m',    'desc' => 'Myrtle' },
            'NADESHIKO PINK'                => { 'out' => $csi . '38;2;246;173;198m', 'desc' => 'Nadeshiko pink' },
            'NAPIER GREEN'                  => { 'out' => $csi . '38;2;42;128;0m',    'desc' => 'Napier green' },
            'NAPLES YELLOW'                 => { 'out' => $csi . '38;2;250;218;94m',  'desc' => 'Naples yellow' },
            'NAVAJO WHITE'                  => { 'out' => $csi . '38;2;255;222;173m', 'desc' => 'Navajo white' },
            'NAVAJO WHITE'                  => { 'out' => $csi . '38;2;255;222;173m', 'desc' => 'Navajo white' },
            'NAVY'                          => { 'out' => $csi . '38;5;17m',          'desc' => 'Navy' },
            'NAVY BLUE'                     => { 'out' => $csi . '38;2;0;0;128m',     'desc' => 'Navy blue' },
            'NEON CARROT'                   => { 'out' => $csi . '38;2;255;163;67m',  'desc' => 'Neon Carrot' },
            'NEON FUCHSIA'                  => { 'out' => $csi . '38;2;254;89;194m',  'desc' => 'Neon fuchsia' },
            'NEON GREEN'                    => { 'out' => $csi . '38;2;57;255;20m',   'desc' => 'Neon green' },
            'NON-PHOTO BLUE'                => { 'out' => $csi . '38;2;164;221;237m', 'desc' => 'Non-photo blue' },
            'NORTH TEXAS GREEN'             => { 'out' => $csi . '38;2;5;144;51m',    'desc' => 'North Texas Green' },
            'OCEAN BOAT BLUE'               => { 'out' => $csi . '38;2;0;119;190m',   'desc' => 'Ocean Boat Blue' },
            'OCHRE'                         => { 'out' => $csi . '38;2;204;119;34m',  'desc' => 'Ochre' },
            'OFFICE GREEN'                  => { 'out' => $csi . '38;2;0;128;0m',     'desc' => 'Office green' },
            'OLD GOLD'                      => { 'out' => $csi . '38;2;207;181;59m',  'desc' => 'Old gold' },
            'OLD LACE'                      => { 'out' => $csi . '38;2;253;245;230m', 'desc' => 'Old lace' },
            'OLD LACE'                      => { 'out' => $csi . '38;2;253;245;230m', 'desc' => 'Old lace' },
            'OLD LAVENDER'                  => { 'out' => $csi . '38;2;121;104;120m', 'desc' => 'Old lavender' },
            'OLD MAUVE'                     => { 'out' => $csi . '38;2;103;49;71m',   'desc' => 'Old mauve' },
            'OLD ROSE'                      => { 'out' => $csi . '38;2;192;128;129m', 'desc' => 'Old rose' },
            'OLIVE'                         => { 'out' => $csi . '38;2;128;128;0m',   'desc' => 'Olive' },
            'OLIVE'                         => { 'out' => $csi . '38;2;128;128;0m',   'desc' => 'Olive' },
            'OLIVE DRAB'                    => { 'out' => $csi . '38;2;107;142;35m',  'desc' => 'Olive drab' },
            'OLIVE DRAB'                    => { 'out' => $csi . '38;2;107;142;35m',  'desc' => 'Olive Drab' },
            'OLIVE GREEN'                   => { 'out' => $csi . '38;2;186;184;108m', 'desc' => 'Olive Green' },
            'OLIVINE'                       => { 'out' => $csi . '38;2;154;185;115m', 'desc' => 'Olivine' },
            'ONYX'                          => { 'out' => $csi . '38;2;15;15;15m',    'desc' => 'Onyx' },
            'OPERA MAUVE'                   => { 'out' => $csi . '38;2;183;132;167m', 'desc' => 'Opera mauve' },
            'ORANGE'                        => { 'out' => $csi . '38;5;202m',         'desc' => 'Orange' },
            'ORANGE PEEL'                   => { 'out' => $csi . '38;2;255;159;0m',   'desc' => 'Orange peel' },
            'ORANGE RED'                    => { 'out' => $csi . '38;2;255;69;0m',    'desc' => 'Orange red' },
            'ORANGE RED'                    => { 'out' => $csi . '38;2;255;69;0m',    'desc' => 'Orange red' },
            'ORANGE YELLOW'                 => { 'out' => $csi . '38;2;248;213;104m', 'desc' => 'Orange Yellow' },
            'ORCHID'                        => { 'out' => $csi . '38;2;218;112;214m', 'desc' => 'Orchid' },
            'ORCHID'                        => { 'out' => $csi . '38;2;218;112;214m', 'desc' => 'Orchid' },
            'OTTER BROWN'                   => { 'out' => $csi . '38;2;101;67;33m',   'desc' => 'Otter brown' },
            'OUTER SPACE'                   => { 'out' => $csi . '38;2;65;74;76m',    'desc' => 'Outer Space' },
            'OUTRAGEOUS ORANGE'             => { 'out' => $csi . '38;2;255;110;74m',  'desc' => 'Outrageous Orange' },
            'OXFORD BLUE'                   => { 'out' => $csi . '38;2;0;33;71m',     'desc' => 'Oxford Blue' },
            'PACIFIC BLUE'                  => { 'out' => $csi . '38;2;28;169;201m',  'desc' => 'Pacific Blue' },
            'PAKISTAN GREEN'                => { 'out' => $csi . '38;2;0;102;0m',     'desc' => 'Pakistan green' },
            'PALATINATE BLUE'               => { 'out' => $csi . '38;2;39;59;226m',   'desc' => 'Palatinate blue' },
            'PALATINATE PURPLE'             => { 'out' => $csi . '38;2;104;40;96m',   'desc' => 'Palatinate purple' },
            'PALE AQUA'                     => { 'out' => $csi . '38;2;188;212;230m', 'desc' => 'Pale aqua' },
            'PALE BLUE'                     => { 'out' => $csi . '38;2;175;238;238m', 'desc' => 'Pale blue' },
            'PALE BROWN'                    => { 'out' => $csi . '38;2;152;118;84m',  'desc' => 'Pale brown' },
            'PALE CARMINE'                  => { 'out' => $csi . '38;2;175;64;53m',   'desc' => 'Pale carmine' },
            'PALE CERULEAN'                 => { 'out' => $csi . '38;2;155;196;226m', 'desc' => 'Pale cerulean' },
            'PALE CHESTNUT'                 => { 'out' => $csi . '38;2;221;173;175m', 'desc' => 'Pale chestnut' },
            'PALE COPPER'                   => { 'out' => $csi . '38;2;218;138;103m', 'desc' => 'Pale copper' },
            'PALE CORNFLOWER BLUE'          => { 'out' => $csi . '38;2;171;205;239m', 'desc' => 'Pale cornflower blue' },
            'PALE GOLD'                     => { 'out' => $csi . '38;2;230;190;138m', 'desc' => 'Pale gold' },
            'PALE GOLDEN ROD'               => { 'out' => $csi . '38;2;238;232;170m', 'desc' => 'Pale golden rod' },
            'PALE GOLDENROD'                => { 'out' => $csi . '38;2;238;232;170m', 'desc' => 'Pale goldenrod' },
            'PALE GREEN'                    => { 'out' => $csi . '38;2;152;251;152m', 'desc' => 'Pale green' },
            'PALE GREEN'                    => { 'out' => $csi . '38;2;152;251;152m', 'desc' => 'Pale green' },
            'PALE LAVENDER'                 => { 'out' => $csi . '38;2;220;208;255m', 'desc' => 'Pale lavender' },
            'PALE MAGENTA'                  => { 'out' => $csi . '38;2;249;132;229m', 'desc' => 'Pale magenta' },
            'PALE PINK'                     => { 'out' => $csi . '38;2;250;218;221m', 'desc' => 'Pale pink' },
            'PALE PLUM'                     => { 'out' => $csi . '38;2;221;160;221m', 'desc' => 'Pale plum' },
            'PALE RED VIOLET'               => { 'out' => $csi . '38;2;219;112;147m', 'desc' => 'Pale red violet' },
            'PALE ROBIN EGG BLUE'           => { 'out' => $csi . '38;2;150;222;209m', 'desc' => 'Pale robin egg blue' },
            'PALE SILVER'                   => { 'out' => $csi . '38;2;201;192;187m', 'desc' => 'Pale silver' },
            'PALE SPRING BUD'               => { 'out' => $csi . '38;2;236;235;189m', 'desc' => 'Pale spring bud' },
            'PALE TAUPE'                    => { 'out' => $csi . '38;2;188;152;126m', 'desc' => 'Pale taupe' },
            'PALE TURQUOISE'                => { 'out' => $csi . '38;2;175;238;238m', 'desc' => 'Pale turquoise' },
            'PALE VIOLET RED'               => { 'out' => $csi . '38;2;219;112;147m', 'desc' => 'Pale violet red' },
            'PALE VIOLET RED'               => { 'out' => $csi . '38;2;219;112;147m', 'desc' => 'Pale violet red' },
            'PANSY PURPLE'                  => { 'out' => $csi . '38;2;120;24;74m',   'desc' => 'Pansy purple' },
            'PAPAYA WHIP'                   => { 'out' => $csi . '38;2;255;239;213m', 'desc' => 'Papaya whip' },
            'PAPAYA WHIP'                   => { 'out' => $csi . '38;2;255;239;213m', 'desc' => 'Papaya whip' },
            'PARIS GREEN'                   => { 'out' => $csi . '38;2;80;200;120m',  'desc' => 'Paris Green' },
            'PASTEL BLUE'                   => { 'out' => $csi . '38;2;174;198;207m', 'desc' => 'Pastel blue' },
            'PASTEL BROWN'                  => { 'out' => $csi . '38;2;131;105;83m',  'desc' => 'Pastel brown' },
            'PASTEL GRAY'                   => { 'out' => $csi . '38;2;207;207;196m', 'desc' => 'Pastel gray' },
            'PASTEL GREEN'                  => { 'out' => $csi . '38;2;119;221;119m', 'desc' => 'Pastel green' },
            'PASTEL MAGENTA'                => { 'out' => $csi . '38;2;244;154;194m', 'desc' => 'Pastel magenta' },
            'PASTEL ORANGE'                 => { 'out' => $csi . '38;2;255;179;71m',  'desc' => 'Pastel orange' },
            'PASTEL PINK'                   => { 'out' => $csi . '38;2;255;209;220m', 'desc' => 'Pastel pink' },
            'PASTEL PURPLE'                 => { 'out' => $csi . '38;2;179;158;181m', 'desc' => 'Pastel purple' },
            'PASTEL RED'                    => { 'out' => $csi . '38;2;255;105;97m',  'desc' => 'Pastel red' },
            'PASTEL VIOLET'                 => { 'out' => $csi . '38;2;203;153;201m', 'desc' => 'Pastel violet' },
            'PASTEL YELLOW'                 => { 'out' => $csi . '38;2;253;253;150m', 'desc' => 'Pastel yellow' },
            'PATRIARCH'                     => { 'out' => $csi . '38;2;128;0;128m',   'desc' => 'Patriarch' },
            'PAYNE GRAY'                    => { 'out' => $csi . '38;2;83;104;120m',  'desc' => 'Payne grey' },
            'PEACH'                         => { 'out' => $csi . '38;2;255;229;180m', 'desc' => 'Peach' },
            'PEACH PUFF'                    => { 'out' => $csi . '38;2;255;218;185m', 'desc' => 'Peach puff' },
            'PEACH PUFF'                    => { 'out' => $csi . '38;2;255;218;185m', 'desc' => 'Peach puff' },
            'PEACH YELLOW'                  => { 'out' => $csi . '38;2;250;223;173m', 'desc' => 'Peach yellow' },
            'PEAR'                          => { 'out' => $csi . '38;2;209;226;49m',  'desc' => 'Pear' },
            'PEARL'                         => { 'out' => $csi . '38;2;234;224;200m', 'desc' => 'Pearl' },
            'PEARL AQUA'                    => { 'out' => $csi . '38;2;136;216;192m', 'desc' => 'Pearl Aqua' },
            'PERIDOT'                       => { 'out' => $csi . '38;2;230;226;0m',   'desc' => 'Peridot' },
            'PERIWINKLE'                    => { 'out' => $csi . '38;2;204;204;255m', 'desc' => 'Periwinkle' },
            'PERSIAN BLUE'                  => { 'out' => $csi . '38;2;28;57;187m',   'desc' => 'Persian blue' },
            'PERSIAN INDIGO'                => { 'out' => $csi . '38;2;50;18;122m',   'desc' => 'Persian indigo' },
            'PERSIAN ORANGE'                => { 'out' => $csi . '38;2;217;144;88m',  'desc' => 'Persian orange' },
            'PERSIAN PINK'                  => { 'out' => $csi . '38;2;247;127;190m', 'desc' => 'Persian pink' },
            'PERSIAN PLUM'                  => { 'out' => $csi . '38;2;112;28;28m',   'desc' => 'Persian plum' },
            'PERSIAN RED'                   => { 'out' => $csi . '38;2;204;51;51m',   'desc' => 'Persian red' },
            'PERSIAN ROSE'                  => { 'out' => $csi . '38;2;254;40;162m',  'desc' => 'Persian rose' },
            'PERU'                          => { 'out' => $csi . '38;2;205;133;63m',  'desc' => 'Peru' },
            'PHLOX'                         => { 'out' => $csi . '38;2;223;0;255m',   'desc' => 'Phlox' },
            'PHTHALO BLUE'                  => { 'out' => $csi . '38;2;0;15;137m',    'desc' => 'Phthalo blue' },
            'PHTHALO GREEN'                 => { 'out' => $csi . '38;2;18;53;36m',    'desc' => 'Phthalo green' },
            'PIGGY PINK'                    => { 'out' => $csi . '38;2;253;221;230m', 'desc' => 'Piggy pink' },
            'PINE GREEN'                    => { 'out' => $csi . '38;2;1;121;111m',   'desc' => 'Pine green' },
            'PINK'                          => { 'out' => $csi . '38;5;198m',         'desc' => 'Pink' },
            'PINK FLAMINGO'                 => { 'out' => $csi . '38;2;252;116;253m', 'desc' => 'Pink Flamingo' },
            'PINK PEARL'                    => { 'out' => $csi . '38;2;231;172;207m', 'desc' => 'Pink pearl' },
            'PINK SHERBET'                  => { 'out' => $csi . '38;2;247;143;167m', 'desc' => 'Pink Sherbet' },
            'PISTACHIO'                     => { 'out' => $csi . '38;2;147;197;114m', 'desc' => 'Pistachio' },
            'PLATINUM'                      => { 'out' => $csi . '38;2;229;228;226m', 'desc' => 'Platinum' },
            'PLUM'                          => { 'out' => $csi . '38;2;221;160;221m', 'desc' => 'Plum' },
            'PLUM'                          => { 'out' => $csi . '38;2;221;160;221m', 'desc' => 'Plum' },
            'PORTLAND ORANGE'               => { 'out' => $csi . '38;2;255;90;54m',   'desc' => 'Portland Orange' },
            'POWDER BLUE'                   => { 'out' => $csi . '38;2;176;224;230m', 'desc' => 'Powder blue' },
            'POWDER BLUE'                   => { 'out' => $csi . '38;2;176;224;230m', 'desc' => 'Powder blue' },
            'PRINCETON ORANGE'              => { 'out' => $csi . '38;2;255;143;0m',   'desc' => 'Princeton orange' },
            'PRUSSIAN BLUE'                 => { 'out' => $csi . '38;2;0;49;83m',     'desc' => 'Prussian blue' },
            'PSYCHEDELIC PURPLE'            => { 'out' => $csi . '38;2;223;0;255m',   'desc' => 'Psychedelic purple' },
            'PUCE'                          => { 'out' => $csi . '38;2;204;136;153m', 'desc' => 'Puce' },
            'PUMPKIN'                       => { 'out' => $csi . '38;2;255;117;24m',  'desc' => 'Pumpkin' },
            'PURPLE'                        => { 'out' => $csi . '38;2;128;0;128m',   'desc' => 'Purple' },
            'PURPLE'                        => { 'out' => $csi . '38;2;128;0;128m',   'desc' => 'Purple' },
            'PURPLE HEART'                  => { 'out' => $csi . '38;2;105;53;156m',  'desc' => 'Purple Heart' },
            'PURPLE MOUNTAIN MAJESTY'       => { 'out' => $csi . '38;2;150;120;182m', 'desc' => 'Purple mountain majesty' },
            'PURPLE MOUNTAINS'              => { 'out' => $csi . '38;2;157;129;186m', 'desc' => 'Purple Mountains' },
            'PURPLE PIZZAZZ'                => { 'out' => $csi . '38;2;254;78;218m',  'desc' => 'Purple pizzazz' },
            'PURPLE TAUPE'                  => { 'out' => $csi . '38;2;80;64;77m',    'desc' => 'Purple taupe' },
            'RACKLEY'                       => { 'out' => $csi . '38;2;93;138;168m',  'desc' => 'Rackley' },
            'RADICAL RED'                   => { 'out' => $csi . '38;2;255;53;94m',   'desc' => 'Radical Red' },
            'RASPBERRY'                     => { 'out' => $csi . '38;2;227;11;93m',   'desc' => 'Raspberry' },
            'RASPBERRY GLACE'               => { 'out' => $csi . '38;2;145;95;109m',  'desc' => 'Raspberry glace' },
            'RASPBERRY PINK'                => { 'out' => $csi . '38;2;226;80;152m',  'desc' => 'Raspberry pink' },
            'RASPBERRY ROSE'                => { 'out' => $csi . '38;2;179;68;108m',  'desc' => 'Raspberry rose' },
            'RAW SIENNA'                    => { 'out' => $csi . '38;2;214;138;89m',  'desc' => 'Raw Sienna' },
            'RAZZLE DAZZLE ROSE'            => { 'out' => $csi . '38;2;255;51;204m',  'desc' => 'Razzle dazzle rose' },
            'RAZZMATAZZ'                    => { 'out' => $csi . '38;2;227;37;107m',  'desc' => 'Razzmatazz' },
            'RED'                           => { 'out' => $csi . '31m',               'desc' => 'Red' },
            'RED BROWN'                     => { 'out' => $csi . '38;2;165;42;42m',   'desc' => 'Red brown' },
            'RED ORANGE'                    => { 'out' => $csi . '38;2;255;83;73m',   'desc' => 'Red Orange' },
            'RED VIOLET'                    => { 'out' => $csi . '38;2;199;21;133m',  'desc' => 'Red violet' },
            'RICH BLACK'                    => { 'out' => $csi . '38;2;0;64;64m',     'desc' => 'Rich black' },
            'RICH CARMINE'                  => { 'out' => $csi . '38;2;215;0;64m',    'desc' => 'Rich carmine' },
            'RICH ELECTRIC BLUE'            => { 'out' => $csi . '38;2;8;146;208m',   'desc' => 'Rich electric blue' },
            'RICH LILAC'                    => { 'out' => $csi . '38;2;182;102;210m', 'desc' => 'Rich lilac' },
            'RICH MAROON'                   => { 'out' => $csi . '38;2;176;48;96m',   'desc' => 'Rich maroon' },
            'RIFLE GREEN'                   => { 'out' => $csi . '38;2;65;72;51m',    'desc' => 'Rifle green' },
            'ROBINS EGG BLUE'               => { 'out' => $csi . '38;2;31;206;203m',  'desc' => 'Robins Egg Blue' },
            'ROSE'                          => { 'out' => $csi . '38;2;255;0;127m',   'desc' => 'Rose' },
            'ROSE BONBON'                   => { 'out' => $csi . '38;2;249;66;158m',  'desc' => 'Rose bonbon' },
            'ROSE EBONY'                    => { 'out' => $csi . '38;2;103;72;70m',   'desc' => 'Rose ebony' },
            'ROSE GOLD'                     => { 'out' => $csi . '38;2;183;110;121m', 'desc' => 'Rose gold' },
            'ROSE MADDER'                   => { 'out' => $csi . '38;2;227;38;54m',   'desc' => 'Rose madder' },
            'ROSE PINK'                     => { 'out' => $csi . '38;2;255;102;204m', 'desc' => 'Rose pink' },
            'ROSE QUARTZ'                   => { 'out' => $csi . '38;2;170;152;169m', 'desc' => 'Rose quartz' },
            'ROSE TAUPE'                    => { 'out' => $csi . '38;2;144;93;93m',   'desc' => 'Rose taupe' },
            'ROSE VALE'                     => { 'out' => $csi . '38;2;171;78;82m',   'desc' => 'Rose vale' },
            'ROSEWOOD'                      => { 'out' => $csi . '38;2;101;0;11m',    'desc' => 'Rosewood' },
            'ROSSO CORSA'                   => { 'out' => $csi . '38;2;212;0;0m',     'desc' => 'Rosso corsa' },
            'ROSY BROWN'                    => { 'out' => $csi . '38;2;188;143;143m', 'desc' => 'Rosy brown' },
            'ROSY BROWN'                    => { 'out' => $csi . '38;2;188;143;143m', 'desc' => 'Rosy brown' },
            'ROYAL AZURE'                   => { 'out' => $csi . '38;2;0;56;168m',    'desc' => 'Royal azure' },
            'ROYAL BLUE'                    => { 'out' => $csi . '38;2;65;105;225m',  'desc' => 'Royal blue' },
            'ROYAL BLUE'                    => { 'out' => $csi . '38;2;65;105;225m',  'desc' => 'Royal blue' },
            'ROYAL FUCHSIA'                 => { 'out' => $csi . '38;2;202;44;146m',  'desc' => 'Royal fuchsia' },
            'ROYAL PURPLE'                  => { 'out' => $csi . '38;2;120;81;169m',  'desc' => 'Royal purple' },
            'RUBY'                          => { 'out' => $csi . '38;2;224;17;95m',   'desc' => 'Ruby' },
            'RUDDY'                         => { 'out' => $csi . '38;2;255;0;40m',    'desc' => 'Ruddy' },
            'RUDDY BROWN'                   => { 'out' => $csi . '38;2;187;101;40m',  'desc' => 'Ruddy brown' },
            'RUDDY PINK'                    => { 'out' => $csi . '38;2;225;142;150m', 'desc' => 'Ruddy pink' },
            'RUFOUS'                        => { 'out' => $csi . '38;2;168;28;7m',    'desc' => 'Rufous' },
            'RUSSET'                        => { 'out' => $csi . '38;2;128;70;27m',   'desc' => 'Russet' },
            'RUST'                          => { 'out' => $csi . '38;2;183;65;14m',   'desc' => 'Rust' },
            'SACRAMENTO STATE GREEN'        => { 'out' => $csi . '38;2;0;86;63m',     'desc' => 'Sacramento State green' },
            'SADDLE BROWN'                  => { 'out' => $csi . '38;2;139;69;19m',   'desc' => 'Saddle brown' },
            'SADDLE BROWN'                  => { 'out' => $csi . '38;2;139;69;19m',   'desc' => 'Saddle brown' },
            'SAFETY ORANGE'                 => { 'out' => $csi . '38;2;255;103;0m',   'desc' => 'Safety orange' },
            'SAFFRON'                       => { 'out' => $csi . '38;2;244;196;48m',  'desc' => 'Saffron' },
            'SAINT PATRICK BLUE'            => { 'out' => $csi . '38;2;35;41;122m',   'desc' => 'Saint Patrick Blue' },
            'SALMON'                        => { 'out' => $csi . '38;2;250;128;114m', 'desc' => 'Salmon' },
            'SALMON'                        => { 'out' => $csi . '38;2;255;140;105m', 'desc' => 'Salmon' },
            'SALMON PINK'                   => { 'out' => $csi . '38;2;255;145;164m', 'desc' => 'Salmon pink' },
            'SAND'                          => { 'out' => $csi . '38;2;194;178;128m', 'desc' => 'Sand' },
            'SAND DUNE'                     => { 'out' => $csi . '38;2;150;113;23m',  'desc' => 'Sand dune' },
            'SANDSTORM'                     => { 'out' => $csi . '38;2;236;213;64m',  'desc' => 'Sandstorm' },
            'SANDY BROWN'                   => { 'out' => $csi . '38;2;244;164;96m',  'desc' => 'Sandy brown' },
            'SANDY BROWN'                   => { 'out' => $csi . '38;2;244;164;96m',  'desc' => 'Sandy brown' },
            'SANDY TAUPE'                   => { 'out' => $csi . '38;2;150;113;23m',  'desc' => 'Sandy taupe' },
            'SAP GREEN'                     => { 'out' => $csi . '38;2;80;125;42m',   'desc' => 'Sap green' },
            'SAPPHIRE'                      => { 'out' => $csi . '38;2;15;82;186m',   'desc' => 'Sapphire' },
            'SATIN SHEEN GOLD'              => { 'out' => $csi . '38;2;203;161;53m',  'desc' => 'Satin sheen gold' },
            'SCARLET'                       => { 'out' => $csi . '38;2;255;36;0m',    'desc' => 'Scarlet' },
            'SCHOOL BUS YELLOW'             => { 'out' => $csi . '38;2;255;216;0m',   'desc' => 'School bus yellow' },
            'SCREAMIN GREEN'                => { 'out' => $csi . '38;2;118;255;122m', 'desc' => 'Screamin Green' },
            'SEA BLUE'                      => { 'out' => $csi . '38;2;0;105;148m',   'desc' => 'Sea blue' },
            'SEA GREEN'                     => { 'out' => $csi . '38;2;46;139;87m',   'desc' => 'Sea green' },
            'SEA GREEN'                     => { 'out' => $csi . '38;2;46;139;87m',   'desc' => 'Sea green' },
            'SEA SHELL'                     => { 'out' => $csi . '38;2;255;245;238m', 'desc' => 'Sea shell' },
            'SEAL BROWN'                    => { 'out' => $csi . '38;2;50;20;20m',    'desc' => 'Seal brown' },
            'SEASHELL'                      => { 'out' => $csi . '38;2;255;245;238m', 'desc' => 'Seashell' },
            'SELECTIVE YELLOW'              => { 'out' => $csi . '38;2;255;186;0m',   'desc' => 'Selective yellow' },
            'SEPIA'                         => { 'out' => $csi . '38;2;112;66;20m',   'desc' => 'Sepia' },
            'SHADOW'                        => { 'out' => $csi . '38;2;138;121;93m',  'desc' => 'Shadow' },
            'SHAMROCK'                      => { 'out' => $csi . '38;2;69;206;162m',  'desc' => 'Shamrock' },
            'SHAMROCK GREEN'                => { 'out' => $csi . '38;2;0;158;96m',    'desc' => 'Shamrock green' },
            'SHOCKING PINK'                 => { 'out' => $csi . '38;2;252;15;192m',  'desc' => 'Shocking pink' },
            'SIENNA'                        => { 'out' => $csi . '38;2;136;45;23m',   'desc' => 'Sienna' },
            'SIENNA'                        => { 'out' => $csi . '38;2;160;82;45m',   'desc' => 'Sienna' },
            'SILVER'                        => { 'out' => $csi . '38;2;192;192;192m', 'desc' => 'Silver' },
            'SILVER'                        => { 'out' => $csi . '38;2;192;192;192m', 'desc' => 'Silver' },
            'SINOPIA'                       => { 'out' => $csi . '38;2;203;65;11m',   'desc' => 'Sinopia' },
            'SKOBELOFF'                     => { 'out' => $csi . '38;2;0;116;116m',   'desc' => 'Skobeloff' },
            'SKY BLUE'                      => { 'out' => $csi . '38;2;135;206;235m', 'desc' => 'Sky blue' },
            'SKY BLUE'                      => { 'out' => $csi . '38;2;135;206;235m', 'desc' => 'Sky blue' },
            'SKY MAGENTA'                   => { 'out' => $csi . '38;2;207;113;175m', 'desc' => 'Sky magenta' },
            'SLATE BLUE'                    => { 'out' => $csi . '38;2;106;90;205m',  'desc' => 'Slate blue' },
            'SLATE BLUE'                    => { 'out' => $csi . '38;2;106;90;205m',  'desc' => 'Slate blue' },
            'SLATE GRAY'                    => { 'out' => $csi . '38;2;112;128;144m', 'desc' => 'Slate gray' },
            'SLATE GRAY'                    => { 'out' => $csi . '38;2;112;128;144m', 'desc' => 'Slate gray' },
            'SMALT'                         => { 'out' => $csi . '38;2;0;51;153m',    'desc' => 'Smalt' },
            'SMOKEY TOPAZ'                  => { 'out' => $csi . '38;2;147;61;65m',   'desc' => 'Smokey topaz' },
            'SMOKY BLACK'                   => { 'out' => $csi . '38;2;16;12;8m',     'desc' => 'Smoky black' },
            'SNOW'                          => { 'out' => $csi . '38;2;255;250;250m', 'desc' => 'Snow' },
            'SNOW'                          => { 'out' => $csi . '38;2;255;250;250m', 'desc' => 'Snow' },
            'SPIRO DISCO BALL'              => { 'out' => $csi . '38;2;15;192;252m',  'desc' => 'Spiro Disco Ball' },
            'SPRING BUD'                    => { 'out' => $csi . '38;2;167;252;0m',   'desc' => 'Spring bud' },
            'SPRING GREEN'                  => { 'out' => $csi . '38;2;0;255;127m',   'desc' => 'Spring green' },
            'SPRING GREEN'                  => { 'out' => $csi . '38;2;0;255;127m',   'desc' => 'Spring green' },
            'STEEL BLUE'                    => { 'out' => $csi . '38;2;70;130;180m',  'desc' => 'Steel blue' },
            'STEEL BLUE'                    => { 'out' => $csi . '38;2;70;130;180m',  'desc' => 'Steel blue' },
            'STIL DE GRAIN YELLOW'          => { 'out' => $csi . '38;2;250;218;94m',  'desc' => 'Stil de grain yellow' },
            'STIZZA'                        => { 'out' => $csi . '38;2;153;0;0m',     'desc' => 'Stizza' },
            'STORMCLOUD'                    => { 'out' => $csi . '38;2;0;128;128m',   'desc' => 'Stormcloud' },
            'STRAW'                         => { 'out' => $csi . '38;2;228;217;111m', 'desc' => 'Straw' },
            'SUNGLOW'                       => { 'out' => $csi . '38;2;255;204;51m',  'desc' => 'Sunglow' },
            'SUNSET'                        => { 'out' => $csi . '38;2;250;214;165m', 'desc' => 'Sunset' },
            'SUNSET ORANGE'                 => { 'out' => $csi . '38;2;253;94;83m',   'desc' => 'Sunset Orange' },
            'TAN'                           => { 'out' => $csi . '38;2;210;180;140m', 'desc' => 'Tan' },
            'TAN'                           => { 'out' => $csi . '38;2;210;180;140m', 'desc' => 'Tan' },
            'TANGELO'                       => { 'out' => $csi . '38;2;249;77;0m',    'desc' => 'Tangelo' },
            'TANGERINE'                     => { 'out' => $csi . '38;2;242;133;0m',   'desc' => 'Tangerine' },
            'TANGERINE YELLOW'              => { 'out' => $csi . '38;2;255;204;0m',   'desc' => 'Tangerine yellow' },
            'TAUPE'                         => { 'out' => $csi . '38;2;72;60;50m',    'desc' => 'Taupe' },
            'TAUPE GRAY'                    => { 'out' => $csi . '38;2;139;133;137m', 'desc' => 'Taupe gray' },
            'TAWNY'                         => { 'out' => $csi . '38;2;205;87;0m',    'desc' => 'Tawny' },
            'TEA GREEN'                     => { 'out' => $csi . '38;2;208;240;192m', 'desc' => 'Tea green' },
            'TEA ROSE'                      => { 'out' => $csi . '38;2;244;194;194m', 'desc' => 'Tea rose' },
            'TEAL'                          => { 'out' => $csi . '38;2;0;128;128m',   'desc' => 'Teal' },
            'TEAL'                          => { 'out' => $csi . '38;2;0;128;128m',   'desc' => 'Teal' },
            'TEAL BLUE'                     => { 'out' => $csi . '38;2;54;117;136m',  'desc' => 'Teal blue' },
            'TEAL GREEN'                    => { 'out' => $csi . '38;2;0;109;91m',    'desc' => 'Teal green' },
            'TERRA COTTA'                   => { 'out' => $csi . '38;2;226;114;91m',  'desc' => 'Terra cotta' },
            'THISTLE'                       => { 'out' => $csi . '38;2;216;191;216m', 'desc' => 'Thistle' },
            'THISTLE'                       => { 'out' => $csi . '38;2;216;191;216m', 'desc' => 'Thistle' },
            'THULIAN PINK'                  => { 'out' => $csi . '38;2;222;111;161m', 'desc' => 'Thulian pink' },
            'TICKLE ME PINK'                => { 'out' => $csi . '38;2;252;137;172m', 'desc' => 'Tickle Me Pink' },
            'TIFFANY BLUE'                  => { 'out' => $csi . '38;2;10;186;181m',  'desc' => 'Tiffany Blue' },
            'TIGER EYE'                     => { 'out' => $csi . '38;2;224;141;60m',  'desc' => 'Tiger eye' },
            'TIMBERWOLF'                    => { 'out' => $csi . '38;2;219;215;210m', 'desc' => 'Timberwolf' },
            'TITANIUM YELLOW'               => { 'out' => $csi . '38;2;238;230;0m',   'desc' => 'Titanium yellow' },
            'TOMATO'                        => { 'out' => $csi . '38;2;255;99;71m',   'desc' => 'Tomato' },
            'TOMATO'                        => { 'out' => $csi . '38;2;255;99;71m',   'desc' => 'Tomato' },
            'TOOLBOX'                       => { 'out' => $csi . '38;2;116;108;192m', 'desc' => 'Toolbox' },
            'TOPAZ'                         => { 'out' => $csi . '38;2;255;200;124m', 'desc' => 'Topaz' },
            'TRACTOR RED'                   => { 'out' => $csi . '38;2;253;14;53m',   'desc' => 'Tractor red' },
            'TROLLEY GRAY'                  => { 'out' => $csi . '38;2;128;128;128m', 'desc' => 'Trolley Grey' },
            'TROPICAL RAIN FOREST'          => { 'out' => $csi . '38;2;0;117;94m',    'desc' => 'Tropical rain forest' },
            'TRUE BLUE'                     => { 'out' => $csi . '38;2;0;115;207m',   'desc' => 'True Blue' },
            'TUFTS BLUE'                    => { 'out' => $csi . '38;2;65;125;193m',  'desc' => 'Tufts Blue' },
            'TUMBLEWEED'                    => { 'out' => $csi . '38;2;222;170;136m', 'desc' => 'Tumbleweed' },
            'TURKISH ROSE'                  => { 'out' => $csi . '38;2;181;114;129m', 'desc' => 'Turkish rose' },
            'TURQUOISE'                     => { 'out' => $csi . '38;2;48;213;200m',  'desc' => 'Turquoise' },
            'TURQUOISE'                     => { 'out' => $csi . '38;2;64;224;208m',  'desc' => 'Turquoise' },
            'TURQUOISE BLUE'                => { 'out' => $csi . '38;2;0;255;239m',   'desc' => 'Turquoise blue' },
            'TURQUOISE GREEN'               => { 'out' => $csi . '38;2;160;214;180m', 'desc' => 'Turquoise green' },
            'TUSCAN RED'                    => { 'out' => $csi . '38;2;102;66;77m',   'desc' => 'Tuscan red' },
            'TWILIGHT LAVENDER'             => { 'out' => $csi . '38;2;138;73;107m',  'desc' => 'Twilight lavender' },
            'TYRIAN PURPLE'                 => { 'out' => $csi . '38;2;102;2;60m',    'desc' => 'Tyrian purple' },
            'UA BLUE'                       => { 'out' => $csi . '38;2;0;51;170m',    'desc' => 'UA blue' },
            'UA RED'                        => { 'out' => $csi . '38;2;217;0;76m',    'desc' => 'UA red' },
            'UBE'                           => { 'out' => $csi . '38;2;136;120;195m', 'desc' => 'Ube' },
            'UCLA BLUE'                     => { 'out' => $csi . '38;2;83;104;149m',  'desc' => 'UCLA Blue' },
            'UCLA GOLD'                     => { 'out' => $csi . '38;2;255;179;0m',   'desc' => 'UCLA Gold' },
            'UFO GREEN'                     => { 'out' => $csi . '38;2;60;208;112m',  'desc' => 'UFO Green' },
            'ULTRA PINK'                    => { 'out' => $csi . '38;2;255;111;255m', 'desc' => 'Ultra pink' },
            'ULTRAMARINE'                   => { 'out' => $csi . '38;2;18;10;143m',   'desc' => 'Ultramarine' },
            'ULTRAMARINE BLUE'              => { 'out' => $csi . '38;2;65;102;245m',  'desc' => 'Ultramarine blue' },
            'UMBER'                         => { 'out' => $csi . '38;2;99;81;71m',    'desc' => 'Umber' },
            'UNITED NATIONS BLUE'           => { 'out' => $csi . '38;2;91;146;229m',  'desc' => 'United Nations blue' },
            'UNIVERSITY OF'                 => { 'out' => $csi . '38;2;183;135;39m',  'desc' => 'University of' },
            'UNIVERSITY OF CALIFORNIA GOLD' => { 'out' => $csi . '38;2;183;135;39m',  'desc' => 'University of California Gold' },
            'UNMELLOW YELLOW'               => { 'out' => $csi . '38;2;255;255;102m', 'desc' => 'Unmellow Yellow' },
            'UP FOREST GREEN'               => { 'out' => $csi . '38;2;1;68;33m',     'desc' => 'UP Forest green' },
            'UP MAROON'                     => { 'out' => $csi . '38;2;123;17;19m',   'desc' => 'UP Maroon' },
            'UPSDELL RED'                   => { 'out' => $csi . '38;2;174;32;41m',   'desc' => 'Upsdell red' },
            'UROBILIN'                      => { 'out' => $csi . '38;2;225;173;33m',  'desc' => 'Urobilin' },
            'USC CARDINAL'                  => { 'out' => $csi . '38;2;153;0;0m',     'desc' => 'USC Cardinal' },
            'USC GOLD'                      => { 'out' => $csi . '38;2;255;204;0m',   'desc' => 'USC Gold' },
            'UTAH CRIMSON'                  => { 'out' => $csi . '38;2;211;0;63m',    'desc' => 'Utah Crimson' },
            'VANILLA'                       => { 'out' => $csi . '38;2;243;229;171m', 'desc' => 'Vanilla' },
            'VEGAS GOLD'                    => { 'out' => $csi . '38;2;197;179;88m',  'desc' => 'Vegas gold' },
            'VENETIAN RED'                  => { 'out' => $csi . '38;2;200;8;21m',    'desc' => 'Venetian red' },
            'VERDIGRIS'                     => { 'out' => $csi . '38;2;67;179;174m',  'desc' => 'Verdigris' },
            'VERMILION'                     => { 'out' => $csi . '38;2;227;66;52m',   'desc' => 'Vermilion' },
            'VERONICA'                      => { 'out' => $csi . '38;2;160;32;240m',  'desc' => 'Veronica' },
            'VIOLET'                        => { 'out' => $csi . '38;2;238;130;238m', 'desc' => 'Violet' },
            'VIOLET'                        => { 'out' => $csi . '38;2;238;130;238m', 'desc' => 'Violet' },
            'VIOLET BLUE'                   => { 'out' => $csi . '38;2;50;74;178m',   'desc' => 'Violet Blue' },
            'VIOLET RED'                    => { 'out' => $csi . '38;2;247;83;148m',  'desc' => 'Violet Red' },
            'VIRIDIAN'                      => { 'out' => $csi . '38;2;64;130;109m',  'desc' => 'Viridian' },
            'VIVID AUBURN'                  => { 'out' => $csi . '38;2;146;39;36m',   'desc' => 'Vivid auburn' },
            'VIVID BURGUNDY'                => { 'out' => $csi . '38;2;159;29;53m',   'desc' => 'Vivid burgundy' },
            'VIVID CERISE'                  => { 'out' => $csi . '38;2;218;29;129m',  'desc' => 'Vivid cerise' },
            'VIVID TANGERINE'               => { 'out' => $csi . '38;2;255;160;137m', 'desc' => 'Vivid tangerine' },
            'VIVID VIOLET'                  => { 'out' => $csi . '38;2;159;0;255m',   'desc' => 'Vivid violet' },
            'WARM BLACK'                    => { 'out' => $csi . '38;2;0;66;66m',     'desc' => 'Warm black' },
            'WATERSPOUT'                    => { 'out' => $csi . '38;2;0;255;255m',   'desc' => 'Waterspout' },
            'WENGE'                         => { 'out' => $csi . '38;2;100;84;82m',   'desc' => 'Wenge' },
            'WHEAT'                         => { 'out' => $csi . '38;2;245;222;179m', 'desc' => 'Wheat' },
            'WHEAT'                         => { 'out' => $csi . '38;2;245;222;179m', 'desc' => 'Wheat' },
            'WHITE'                         => { 'out' => $csi . '37m',               'desc' => 'White' },
            'WHITE SMOKE'                   => { 'out' => $csi . '38;2;245;245;245m', 'desc' => 'White smoke' },
            'WHITE SMOKE'                   => { 'out' => $csi . '38;2;245;245;245m', 'desc' => 'White smoke' },
            'WILD BLUE YONDER'              => { 'out' => $csi . '38;2;162;173;208m', 'desc' => 'Wild blue yonder' },
            'WILD STRAWBERRY'               => { 'out' => $csi . '38;2;255;67;164m',  'desc' => 'Wild Strawberry' },
            'WILD WATERMELON'               => { 'out' => $csi . '38;2;252;108;133m', 'desc' => 'Wild Watermelon' },
            'WINE'                          => { 'out' => $csi . '38;2;114;47;55m',   'desc' => 'Wine' },
            'WISTERIA'                      => { 'out' => $csi . '38;2;201;160;220m', 'desc' => 'Wisteria' },
            'XANADU'                        => { 'out' => $csi . '38;2;115;134;120m', 'desc' => 'Xanadu' },
            'YALE BLUE'                     => { 'out' => $csi . '38;2;15;77;146m',   'desc' => 'Yale Blue' },
            'YELLOW'                        => { 'out' => $csi . '33m',               'desc' => 'Yellow' },
            'YELLOW GREEN'                  => { 'out' => $csi . '38;2;154;205;50m',  'desc' => 'Yellow green' },
            'YELLOW GREEN'                  => { 'out' => $csi . '38;2;154;205;50m',  'desc' => 'Yellow green' },
            'YELLOW ORANGE'                 => { 'out' => $csi . '38;2;255;174;66m',  'desc' => 'Yellow Orange' },
            'ZAFFRE'                        => { 'out' => $csi . '38;2;0;20;168m',    'desc' => 'Zaffre' },
            'ZINNWALDITE BROWN'             => { 'out' => $csi . '38;2;44;22;8m',     'desc' => 'Zinnwaldite brown' },
        },
    };
###

    foreach my $name (keys %{ $tmp->{'foreground'} }) {
        $tmp->{'background'}->{"B_$name"}->{'desc'} = $tmp->{'foreground'}->{$name}->{'desc'};
        $tmp->{'background'}->{"B_$name"}->{'out'}  = $csi . '4' . substr($tmp->{'foreground'}->{$name}->{'out'}, 3);
    }

    # Alternate Fonts
    foreach my $count (1 .. 9) {
        $tmp->{'attributes'}->{ 'FONT ' . $count } = {
            'desc' => "ANSI Font $count",
            'out'  => $csi . ($count + 10) . 'm',
        };
    } ## end foreach my $count (1 .. 9)
    foreach my $count (16 .. 231) {
        $tmp->{'foreground'}->{ 'COLOR ' . $count } = {
            'desc' => "ANSI 8 Bit Color $count",
            'out'  => $csi . "38;5;$count" . 'm',
        };
        $tmp->{'background'}->{ 'B_COLOR ' . $count } = {
            'desc' => "ANSI 8 Bit Color $count",
            'out'  => $csi . "48;5;$count" . 'm',
        };
    } ## end foreach my $count (16 .. 231)
    foreach my $count (232 .. 255) {
        $tmp->{'foreground'}->{ 'GRAY ' . ($count - 232) } = {
            'desc' => "ANSI 8 Bit Gray level " . ($count - 232),
            'out'  => $csi . "38;5;$count" . 'm',
        };
        $tmp->{'background'}->{ 'B_GRAY ' . ($count - 232) } = {
            'desc' => "ANSI 8 Bit Gray level " . ($count - 232),
            'out'  => $csi . "48;5;$count" . 'm',
        };
    } ## end foreach my $count (232 .. 255)

    return ($tmp);
} ## end sub _global_ansi_meta

1;

=head1 NAME

Term;;ANSIEncode

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

There are many more foreground colors available than the sixteen below.  However, the ones below should work on any color terminal.  Other colors may require 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have 'Term256' and 'truecolor' features.  You can used the '-t' option (in the executable "ansi-encode" file) for all of the color tokens available or use the 'RGB' token for access to 16 million colors.

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

=head2 FRAMES

Makes a "dialog box" at the selected location and type

For example:   [% BOX BLUE,10,10,40,4,DOUBLE %]Text that will be wrapped inside the box[% ENDBOX %]

=over 4

=item BOX color,column,row,width,height,type

Begins the frame definition

=item ENDBOX

Ends the frame definition

=back

=head1 AUTHOR & COPYRIGHT

Richard Kelsch

 Copyright (C) 2025 Richard Kelsch
 All Rights Reserved
 Perl Artistic License

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at;

L<http://www.perlfoundation.org/artistic_license_2_0>
