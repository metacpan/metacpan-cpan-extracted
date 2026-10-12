package Term::Chess;

use 5.014;
use strict;
use warnings;
use utf8;

use Carp ();
use Object::Proto::Sugar -types;

use Chess::Plisco qw(:all);
use Term::Chess::Game;
use Term::Chess::Bot;
use Getopt::Long ();

our $VERSION = '0.01';

my %OUTLINE = (
    CP_KING()   => "\x{2654}", CP_QUEEN()  => "\x{2655}", CP_ROOK() => "\x{2656}",
    CP_BISHOP() => "\x{2657}", CP_KNIGHT() => "\x{2658}", CP_PAWN() => "\x{2659}",
);

my %FILLED = (
    CP_KING()   => "\x{265A}", CP_QUEEN()  => "\x{265B}", CP_ROOK() => "\x{265C}",
    CP_BISHOP() => "\x{265D}", CP_KNIGHT() => "\x{265E}", CP_PAWN() => "\x{265F}",
);

my %LETTER = (
    CP_KING()   => 'K', CP_QUEEN()  => 'Q', CP_ROOK() => 'R',
    CP_BISHOP() => 'B', CP_KNIGHT() => 'N', CP_PAWN() => 'P',
);

my %WORD = (
    CP_KING()   => 'king',   CP_QUEEN()  => 'queen',  CP_ROOK() => 'rook',
    CP_BISHOP() => 'bishop', CP_KNIGHT() => 'knight', CP_PAWN() => 'pawn',
);

my %WHY = (
    checkmate             => 'checkmate',
    stalemate             => 'stalemate',
    fifty_moves           => 'fifty moves without a capture or a pawn move',
    insufficient_material => 'neither side can mate',
    repetition            => 'the same position three times',
    resignation           => 'resignation',
);

our %SEQUENCE = (
    'A' => 'up', 'B' => 'down', 'C' => 'right', 'D' => 'left',
    'H' => 'home', 'F' => 'end',
    '1~' => 'home', '4~' => 'end', '5~' => 'page_up', '6~' => 'page_down',
    '7~' => 'home', '8~' => 'end',
);

our %CONTROL = (
    "\r" => 'enter', "\n" => 'enter', "\t" => 'tab',
    "\x7f" => 'backspace', "\x08" => 'backspace',
    "\x03" => 'interrupt', "\x04" => 'eof',
);

my %PAINT = (
    white_piece => '38;5;231',
    black_piece => '38;5;16',
    light       => '48;5;180',
    dark        => '48;5;94',
);

use constant {
    CELL => 2,
    GAP  => 1,
};

has in => (is => 'rw', default => sub { \*STDIN });

has game => (is => 'rw');

has level => (is => 'ro');

has seat => (is => 'ro', isa => Str, default => 'p1');

has _fh => (is => 'rw', init_arg => 'out', private => 1, default => sub { \*STDOUT });

has _ascii => (is => 'rw', init_arg => 'ascii', private => 1, default => 0);

has _colour => (is => 'rw', init_arg => 'colour', private => 1);

has raw => (is => 'rw', isa => Any, default => 0);

has keysource => (is => 'rw', isa => Any);

has pending => (is => 'rw', isa => ArrayRef, default => sub { [] });

has _picking => (is => 'rw', isa => Any, init_arg => 'picking');

has _rewind => (is => 'rw', isa => Any, init_arg => 'rewind');

has _size => (is => 'rw', isa => Any, init_arg => 'size');

sub BUILD {
    my ($self) = @_;

    my $size = defined $self->_size ? $self->_size : 2;
    Carp::croak("Term::Chess: size is 1, 2 or 3, not '$size'")
        unless $size =~ /\A[123]\z/;
    $self->_size($size + 0);
    $self->_ascii($self->_ascii ? 1 : 0);
    $self->_colour(
        exists $ENV{NO_COLOR}      ? 0
      : defined $self->_colour     ? ($self->_colour ? 1 : 0)
      :                              1
    );
    $self->_encode_out;
    return;
}

sub _encode_out {
    my ($self) = @_;
    return $self if $self->_ascii;
    my $fh = $self->_fh;
    return $self unless $fh;
    return $self if grep { /encoding|utf8/i } PerlIO::get_layers($fh);
    eval { binmode $fh, ':encoding(UTF-8)'; 1 };
    return $self;
}

sub out    { my $s = shift; if (@_) { $s->_fh(shift); $s->_encode_out } $s->_fh }
sub ascii  { my $s = shift; if (@_) { $s->_ascii(shift() ? 1 : 0); $s->_encode_out } $s->_ascii }
sub colour { my $s = shift; $s->_colour(shift() ? 1 : 0) if @_; $s->_colour }
sub size   { $_[0]->_size }

sub _say { my ($self, @t) = @_; my $fh = $self->_fh; print {$fh} @t, "\n" }
sub _out { my ($self, @t) = @_; my $fh = $self->_fh; print {$fh} @t }

sub light {
    my ($self, $square) = @_;
    my ($file, $rank) = (ord(substr $square, 0, 1) - ord('a'), substr($square, 1, 1));
    return (($file + $rank) % 2) ? 0 : 1;
}

sub glyph {
    my ($self, $piece, $colour) = @_;
    return '' unless $piece;
    if ($self->_ascii) {
        my $l = $LETTER{$piece};
        return $colour == CP_WHITE ? $l : lc $l;
    }
    return $FILLED{$piece} if $self->_colour;
    return $colour == CP_WHITE ? $OUTLINE{$piece} : $FILLED{$piece};
}

sub _paint {
    my ($self, $text, $light, $colour) = @_;
    return $text unless $self->_colour;
    my $paint = $PAINT{ $light ? 'light' : 'dark' };
    $paint .= ';' . $PAINT{ $colour == CP_WHITE ? 'white_piece' : 'black_piece' } if defined $colour;
    return "\e[${paint}m$text\e[0m";
}

sub _cell {
    my ($self, $square, $piece, $colour, $spot, $glyph_row) = @_;
    my $light = $self->light($square);
    my $size  = $self->_size;
    my $w     = 2 * $size;
    my $char;
    if (!$glyph_row) { $char = ' ' }
    elsif ($piece)   { $char = $self->glyph($piece, $colour) }
    elsif ($spot)    { $char = '+' }
    else             { $char = $self->_colour ? ' ' : $light ? '.' : ':' }
    my $text = (' ' x $size) . $char . (' ' x ($w - $size - 1));
    return $self->_paint($text, $light, $piece && $glyph_row ? $colour : undef);
}

sub _marks {
    my ($self, $rank, $files, $o) = @_;
    my @gap = (' ') x 9;
    my $take = $self->_ascii ? 'x' : "\x{00D7}";

    for my $i (0 .. 7) {
        my $sq = $files->[$i] . $rank;
        next unless $o->{_take}{$sq};
        $gap[$i]     = $take;
        $gap[$i + 1] = $take;
    }
    for my $pair ([ $o->{from}, '(', ')' ], [ $o->{cursor}, '[', ']' ]) {
        my ($sq, $left, $right) = @$pair;
        next unless defined $sq && substr($sq, 1, 1) == $rank;
        my ($i) = grep { $files->[$_] eq substr($sq, 0, 1) } 0 .. 7;
        next unless defined $i;
        $gap[$i]     = $left;
        $gap[$i + 1] = $right;
    }
    return @gap;
}

sub board_lines {
    my ($self, %o) = @_;
    my $pos  = $o{position} || ($self->game ? $self->game->position : Chess::Plisco::Engine::Position->new);
    my $flip = $o{flip} ? 1 : 0;
    my $size = $self->_size;
    my $glyph_row = int($size / 2);

    my (%spot, %take);
    for my $sq (@{ $o{spots} || [] }) {
        my ($p) = $pos->pieceAtSquare($sq);
        $p || $o{_ep}{$sq} ? ($take{$sq} = 1) : ($spot{$sq} = 1);
    }
    $take{$_} = 1 for keys %{ $o{_ep} || {} };
    $o{_take} = \%take;

    my @ranks = $flip ? (1 .. 8) : reverse(1 .. 8);
    my @files = $flip ? reverse('a' .. 'h') : ('a' .. 'h');
    my @lines;

    for my $rank (@ranks) {
        my @marks = $self->_marks($rank, \@files, \%o);
        for my $r (0 .. $size - 1) {
            my $on  = $r == $glyph_row ? 1 : 0;
            my @gap = $on ? @marks : (' ') x 9;
            my $row = $on ? sprintf('%d ', $rank) : '  ';
            $row .= $self->_paint($gap[0], $self->light($files[0] . $rank));
            for my $i (0 .. 7) {
                my $sq = $files[$i] . $rank;
                my ($piece, $colour) = $pos->pieceAtSquare($sq);
                $row .= $self->_cell($sq, $piece, $colour, $spot{$sq}, $on);
                $row .= $self->_paint($gap[$i + 1], $self->light($sq));
            }
            push @lines, $row;
        }
    }

    my $legend = '   ';
    $legend .= (' ' x $size) . $_ . (' ' x $size) for @files;
    push @lines, $legend;
    return @lines;
}

sub draw {
    my ($self, %o) = @_;
    $self->_say($_) for $self->board_lines(%o);
    return $self;
}

sub clear {
    my ($self, @notice) = @_;
    $self->_out("\e[H\e[2J") if $self->rewind;
    $self->_say($_) for @notice;
    return $self;
}

sub keys_available {
    my ($self) = @_;
    return 1 if $self->keysource;
    return 0 unless eval { -t $self->in };
    return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub picking {
    my ($self, @set) = @_;
    $self->_picking($set[0] ? 1 : 0) if @set;
    return $self->_picking ? 1 : 0 if defined $self->_picking;
    return $self->keys_available;
}

sub rewind {
    my ($self, @set) = @_;
    $self->_rewind($set[0] ? 1 : 0) if @set;
    return $self->_rewind ? 1 : 0 if defined $self->_rewind;
    return eval { -t $self->_fh } ? 1 : 0;
}

sub enter_raw {
    my ($self) = @_;
    return $self if $self->raw;
    if ($self->keysource) { $self->raw(1); return $self }
    return undef unless $self->keys_available;
    return undef unless eval { Term::ReadKey::ReadMode(3, $self->in); 1 };
    $self->raw(1);
    return $self;
}

sub leave_raw {
    my ($self) = @_;
    return $self unless $self->raw;
    eval { Term::ReadKey::ReadMode(0, $self->in) } unless $self->keysource;
    $self->raw(0);
    return $self;
}

sub read_char {
    my ($self, $wait) = @_;
    my $pending = $self->pending;
    return shift @$pending if @$pending;
    return $self->keysource->($wait) if $self->keysource;
    my $char = Term::ReadKey::ReadKey($wait ? 0 : -1, $self->in);
    return $char if defined $char || $wait;
    select undef, undef, undef, 0.05;
    return Term::ReadKey::ReadKey(-1, $self->in);
}

sub read_key {
    my ($self) = @_;
    my $char = $self->read_char(1);
    return undef unless defined $char;
    return $CONTROL{$char} if $CONTROL{$char};
    return $self->read_sequence if $char eq "\e";
    return $char;
}

sub read_sequence {
    my ($self) = @_;
    my $opener = $self->read_char(0);
    return 'escape' unless defined $opener;
    unless ($opener eq '[' || $opener eq 'O') {
        unshift @{ $self->pending }, $opener;
        return 'escape';
    }
    my $tail = '';
    while (length $tail < 8) {
        my $char = $self->read_char(0);
        last unless defined $char;
        $tail .= $char;
        last if $char =~ /[A-Za-z~]/;
    }
    return $SEQUENCE{$tail} || 'escape';
}

sub piece_name {
    my ($self, $piece, $colour) = @_;
    return 'nothing' unless $piece;
    return ($colour == CP_WHITE ? 'white ' : 'black ') . $WORD{$piece};
}

sub describe {
    my ($self, $g, $uci, $lead) = @_;
    my $pos = $g->position;
    my $m = eval { $pos->parseMove($uci) };
    return "$lead $uci" unless $m;
    my $san = $pos->SAN($m);
    my $line = "$lead $san ($uci)";
    my $captured = $pos->moveCaptured($m);
    $line .= ', taking the ' . $WORD{ $pos->moveEnPassant($m) ? CP_PAWN() : $captured } if $captured;
    $line .= ', checkmate' if $san =~ /#\z/;
    $line .= ', check'     if $san =~ /\+\z/;
    return $line;
}

sub _drawn_order {
    my ($self, $flip, @squares) = @_;
    my $row = sub { my $r = substr($_[0], 1, 1); $flip ? $r : 9 - $r };
    my $col = sub { my $f = ord(substr $_[0], 0, 1) - ord('a'); $flip ? 7 - $f : $f };
    return [ sort { $row->($a) <=> $row->($b) || $col->($a) <=> $col->($b) } @squares ];
}

sub origins {
    my ($self, $pos, $flip) = @_;
    my %seen;
    my @from = grep { !$seen{$_}++ } map { $pos->shiftToSquare($pos->moveFrom($_)) } $pos->legalMoves;
    return $self->_drawn_order($flip, @from);
}

sub targets {
    my ($self, $pos, $from, $flip) = @_;
    my %seen;
    my @to = grep { !$seen{$_}++ }
             map  { $pos->shiftToSquare($pos->moveTo($_)) }
             grep { $pos->shiftToSquare($pos->moveFrom($_)) eq $from } $pos->legalMoves;
    return $self->_drawn_order($flip, @to);
}

sub moves_between {
    my ($self, $pos, $from, $to) = @_;
    return grep { $pos->shiftToSquare($pos->moveFrom($_)) eq $from
               && $pos->shiftToSquare($pos->moveTo($_)) eq $to } $pos->legalMoves;
}

sub step {
    my ($self, $squares, $at, $key, $flip) = @_;
    return 0 if $key eq 'home';
    return $#$squares if $key eq 'end';
    return ($at + 1) % @$squares if $key eq 'right' || $key eq 'tab';
    return ($at - 1) % @$squares if $key eq 'left';

    my $here = $squares->[$at];
    my $row  = sub { my $r = substr($_[0], 1, 1); $flip ? $r : 9 - $r };
    my $col  = sub { ord(substr $_[0], 0, 1) };
    my $want = $key eq 'up' ? -1 : 1;
    my ($pick, $near, $off);
    for my $i (0 .. $#$squares) {
        my $away = ($row->($squares->[$i]) - $row->($here)) * $want;
        next unless $away > 0;
        my $sideways = abs($col->($squares->[$i]) - $col->($here));
        next if defined $pick
            && ($away > $near || ($away == $near && $sideways >= $off));
        ($pick, $near, $off) = ($i, $away, $sideways);
    }
    return defined $pick ? $pick : $at;
}

sub victims {
    my ($self, $pos, $from) = @_;
    my %ep;
    for my $m (grep { $pos->shiftToSquare($pos->moveFrom($_)) eq $from } $pos->legalMoves) {
        next unless $pos->moveEnPassant($m);
        my $to = $pos->shiftToSquare($pos->moveTo($m));
        $ep{ substr($to, 0, 1) . substr($from, 1, 1) } = 1;
    }
    return \%ep;
}

sub move_line {
    my ($self, $pos, $from, $to) = @_;
    my @moves = $self->moves_between($pos, $from, $to);
    return "$to: not a move" unless @moves;
    my ($m) = sort { ($pos->movePromote($b) || 0) <=> ($pos->movePromote($a) || 0) } @moves;

    my $captured = $pos->moveCaptured($m);
    my ($prey, $prey_colour) = $pos->pieceAtSquare($to);
    my $line = "$to: ";
    if ($pos->moveEnPassant($m)) {
        $line .= 'takes the pawn en passant';
    }
    elsif ($captured) {
        $line .= 'takes the ' . $self->piece_name($prey, $prey_colour);
    }
    elsif ($pos->movePiece($m) == CP_KING
        && abs(ord(substr $from, 0, 1) - ord(substr $to, 0, 1)) == 2) {
        $line .= 'castles';
    }
    else {
        $line .= 'a quiet move';
    }
    $line .= ', and promotes' if @moves > 1;

    my $san = $pos->SAN($m);
    $line .= $san =~ /#\z/ ? ', and it is mate'
           : $san =~ /\+\z/ ? ', and it checks'
           :                  '';
    $line .= ', but it loses material' if $captured && $pos->SEE($m) < 0;
    return $line;
}

sub piece_line {
    my ($self, $pos, $from, $flip) = @_;
    my ($piece, $colour) = $pos->pieceAtSquare($from);
    my $n = scalar @{ $self->targets($pos, $from, $flip) };
    my $line = sprintf 'the %s on %s, %d %s',
        $self->piece_name($piece, $colour), $from, $n, ($n == 1 ? 'move' : 'moves');
    $line .= ', and it is attacked' if $pos->attacked($pos->squareToShift($from));
    return $line;
}

sub pick_move {
    my ($self, $g, $seat) = @_;
    my $pos  = $g->position;
    my $flip = $seat eq $g->black ? 1 : 0;
    my $from = $self->origins($pos, $flip);
    return undef unless @$from;

    my ($at, $held, $to, $toat, $asking, $drawn) = (0, undef, undef, 0, 0, 0);

    while (1) {
        my %o = (flip => $flip);
        if (defined $held) {
            $to = $self->targets($pos, $held, $flip);
            %o = (%o, from => $held, cursor => $to->[$toat], spots => $to,
                  _ep => $self->victims($pos, $held));
        }
        else {
            %o = (%o, cursor => $from->[$at]);
        }

        my @lines = $self->board_lines(%o);
        push @lines, ' ' . ($asking ? 'queen, rook, bishop or knight? (q r b n, enter is queen)'
                     : defined $held ? $self->move_line($pos, $held, $to->[$toat])
                     :                 $self->piece_line($pos, $from->[$at], $flip));
        push @lines, ' ' . ($asking ? 'escape to choose another square'
                     : defined $held ? 'arrows to choose, enter or space to play, escape to pick another'
                     :                 'arrows to choose a piece, enter or space to take it, ? for the keys');

        $self->_out(sprintf "\e[%dA\r", $drawn) if $drawn && $self->rewind;
        $self->_say($_) for @lines;
        $drawn = scalar @lines;

        my $key = $self->read_key;
        return 'quit' unless defined $key;
        return 'quit' if $key eq 'q' && !$asking;
        return 'quit' if $key eq 'interrupt' || $key eq 'eof';

        if ($asking) {
            if ($key eq 'escape' || $key eq 'backspace') { $asking = 0; next }
            my $letter = ($key eq 'enter' || $key eq ' ') ? 'q'
                       : $key =~ /\A[qrbn]\z/            ? $key
                       :                                   undef;
            next unless defined $letter;
            return $held . $to->[$toat] . $letter;
        }

        if ($key eq 'enter' || $key eq ' ') {
            if (!defined $held) { ($held, $toat) = ($from->[$at], 0); next }
            my @moves = $self->moves_between($pos, $held, $to->[$toat]);
            if (@moves > 1) { $asking = 1; next }
            return $pos->moveCoordinateNotation($moves[0]);
        }
        if ($key eq 'escape' || $key eq 'backspace') {
            $held = undef;
            next;
        }
        if ($key =~ /\A(?:up|down|left|right|home|end|tab)\z/) {
            defined $held
                ? ($toat = $self->step($to, $toat, $key, $flip))
                : ($at   = $self->step($from, $at, $key, $flip));
            next;
        }
        if ($key eq '?') { $self->_keys;                   $drawn = 0; next }
        if ($key eq 'l') { $self->_legal($g);              $drawn = 0; next }
        if ($key eq 'f') { $self->_say($pos->toFEN);       $drawn = 0; next }
        if ($key eq 'g') { $self->_history($g);            $drawn = 0; next }
        if ($key eq 'h') { $self->_hint($g, $seat);        $drawn = 0; next }
    }
}

sub _keys {
    my ($self) = @_;
    $self->_say($_) for
        'arrows  move the cursor; it only stops where a move is',
        'enter   take the piece under the cursor, then play to the square',
        'space   the same as enter',
        'escape  put the piece back and choose another',
        'tab     the next one, whichever you are choosing',
        'q r b n what a pawn becomes, when it is asked',
        'h       the strongest move this engine can find',
        'l f g   every move you have, the FEN, the moves so far',
        'q       give up and leave';
    return $self;
}


sub start {
    my ($self) = @_;

    my $g = $self->game;
    if (!$g) {
        $g = eval { Term::Chess::Game->new(
            seed => substr('chess-terminal-default' . ('.' x 32), 0, 32)) };
        $self->game($g);
    }
    return 2 unless $g;
    my $seat = $self->seat;
    my $bot  = $g->bot;
    my $flip = $seat eq $g->black ? 1 : 0;

    my $pick = $self->picking && $self->enter_raw ? 1 : 0;
    $self->picking(0) unless $pick;
    my $notice;
    $self->_say($pick
        ? 'chess. arrows to choose a move, enter or space to play it, ? for the keys.'
        : 'chess. a move is coordinates like e2e4, or SAN like Nf3. "help" for the rest.');
    $self->draw(flip => $flip) unless $pick;

    my $fh = $self->in;
    while ($g->status eq 'active') {
        if ($g->turn ne $seat) {
            my $mv = do { local $Term::Chess::Bot::LEVEL = $self->level;
                          $bot->choose($g, $g->turn) };
            last unless defined $mv;
            $notice = $self->describe($g, $mv, 'the bot plays');
            my $refusal = $g->play($mv);
            if ($refusal) {
                $self->_say($notice, "\n", 'the bot offered a move the game refused: ' . $refusal->code);
                last;
            }
            $self->clear($notice);
            $self->draw(flip => $flip) unless $pick;
            next;
        }

        if ($pick) {
            my $chosen = $self->pick_move($g, $seat);
            last if !defined $chosen || $chosen eq 'quit';
            my $refusal = $g->play($chosen);
            $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')')
                if $refusal;
            next;
        }

        $self->_out($self->_prompt($g));
        my $line = <$fh>;
        last unless defined $line;
        $line =~ s/\A\s+|\s+\z//g;
        next unless length $line;

        last                             if $line eq 'quit' || $line eq 'q';
        $self->_help,              next  if $line eq 'help' || $line eq '?';
        $self->_legal($g),         next  if $line eq 'legal';
        $self->_say($g->position->toFEN), next if $line eq 'fen';
        $self->_history($g),       next  if $line eq 'log';
        $self->draw(flip => $flip), next if $line eq 'board';
        $self->_hint($g, $seat),   next  if $line eq 'hint';
        if ($line eq 'resign') { $g->resign($seat); last }

        my $refusal = $g->play($line);
        if ($refusal) {
            $self->_say('no: ' . $refusal->message . ' (' . $refusal->code . ')');
            next;
        }
        $self->clear;
        $self->draw(flip => $flip);
    }

    $self->leave_raw;
    if ($pick) {
        $self->clear(defined $notice ? $notice : ());
        $self->draw(flip => $flip);
    }
    return $self->_verdict($g, $seat);
}

sub _prompt {
    my ($self, $g) = @_;
    return $g->side . ' to move> ';
}

sub _help {
    my ($self) = @_;
    $self->_say($_) for
        'a move is coordinates, the from square then the to square, like e2e4',
        'or standard notation like Nf3, exd5, O-O, a8=Q',
        'board   draw it again',
        'legal   every move you have',
        'fen     the position as a FEN',
        'log     the moves so far',
        'hint    the strongest move this engine can find',
        'resign  give up the game',
        'quit    leave without finishing';
    return $self;
}

sub _legal {
    my ($self, $g) = @_;
    my @m = @{ $g->legal };
    $self->_say(scalar(@m) . ' moves: ' . join ' ', @m);
    return $self;
}

sub _history {
    my ($self, $g) = @_;
    my $san = $g->san_log;
    $self->_say(length $san ? $san : 'no moves yet');
    return $self;
}

sub _hint {
    my ($self, $g, $seat) = @_;
    my $mv = $g->bot->hint($g, $seat);
    $self->_say(defined $mv ? $self->describe($g, $mv, 'try') : 'nothing to suggest');
    return $self;
}

sub _verdict {
    my ($self, $g, $seat) = @_;
    return 0 if $g->status eq 'active';
    my $r   = $g->result;
    my $why = $WHY{ $r->{reason} || '' } || $r->{reason} || 'over';

    if (!defined $r->{winner}) { $self->_say("drawn: $why"); return 0 }
    if ($r->{winner} eq $seat) { $self->_say("you won: $why"); return 0 }
    $self->_say("you lost: $why");
    return 1;
}

sub _usage {
    return <<'USAGE';
chess - chess on a terminal, against a bot

usage: chess [options]

  --level N      node budget for the bot, or a rung index into the ladder
  --white SEAT   p1 or p2; whoever is White moves first
  --seat SEAT    which seat you play (default p1)
  --seed STR     up to thirty-two bytes, for a reproducible game
  --fen FEN      start from a position instead of the opening
  --moves LIST   play these moves first, coordinates or SAN, comma or space separated
  --size N       1, 2 or 3: squares of 2, 4 or 6 columns and as many rows (default 2)
  --ascii        the FEN letters instead of the pieces
  --ansi         colour; --no-ansi turns it off (NO_COLOR beats both)
  --pick         choose a move with the arrow keys; --no-pick to type it
  --help         this

exit status:
  0   you won, or the game drew, or you quit
  1   you lost
  2   a bad option

With a terminal and Term::ReadKey the arrow keys walk the pieces that have a
move and then that piece's squares, with the caption saying what each one does.
Without either, or with --no-pick, a move is typed as coordinates, like e2e4,
or in standard notation, like Nf3 or O-O, and "help" lists the rest.

The engine is Chess::Plisco, bounded in NODES and never in seconds, so the
same position answers the same on a busy machine as on an idle one.
USAGE
}

sub run {
    my ($class, @argv) = @_;
    my %opt = (seat => 'p1', white => 'p1');

    my $ok = eval {
        local $SIG{__WARN__} = sub { print STDERR "chess: $_[0]" };
        Getopt::Long::GetOptionsFromArray(\@argv, \%opt,
            'level=i', 'white=s', 'seat=s', 'seed=s', 'fen=s', 'moves=s',
            'size=i', 'ascii', 'ansi!', 'pick!', 'help');
    };
    if (!$ok) { print STDERR _usage(); return 2 }
    if ($opt{help}) { print _usage(); return 0 }
    if (@argv)      { print STDERR "chess: not an option: $argv[0]\n", _usage(); return 2 }

    for my $k (qw(white seat)) {
        next if $opt{$k} eq 'p1' || $opt{$k} eq 'p2';
        print STDERR "chess: --$k takes p1 or p2, not '$opt{$k}'\n";
        return 2;
    }

    my @ladder = Term::Chess::Bot->ladder;
    my $level;
    if (defined $opt{level}) {
        if ($opt{level} < 0) { print STDERR "chess: --level must not be negative\n"; return 2 }
        if ($opt{level} >= scalar @ladder && $opt{level} < $ladder[0]) {
            printf STDERR
                "chess: --level %d is neither a rung nor a budget: a rung is 0 to %d, "
                . "and a budget is %d nodes or more\n",
                $opt{level}, $#ladder, $ladder[0];
            return 2;
        }
        $level = $opt{level} < scalar @ladder ? $ladder[ $opt{level} ] : $opt{level};
    }

    if (defined $opt{size} && $opt{size} !~ /\A[123]\z/) {
        print STDERR "chess: --size takes 1, 2 or 3, not '$opt{size}'\n";
        return 2;
    }

    my $terminal = $class->new(
        size    => $opt{size},
        ascii   => $opt{ascii},
        colour  => defined $opt{ansi} ? $opt{ansi} : undef,
        picking => $opt{pick},
        level   => $level,
        seat    => $opt{seat},
    );

    my $seed = defined $opt{seed} ? $opt{seed} : 'chess-terminal-default-seed32';
    $seed = substr($seed . ('.' x 32), 0, 32);

    my %new = (seed => $seed, white => $opt{white});
    $new{position} = $opt{fen} if defined $opt{fen};

    my $game = eval { Term::Chess::Game->new(%new) };
    if (!$game) {
        my $why = $@;
        $why =~ s/\s+at \S+ line \d+\.?\s*\z//;
        $why =~ s/\ATerm::Chess::Game: //;
        print STDERR "chess: could not start a game: $why\n";
        return 2;
    }

    if (defined $opt{moves}) {
        for my $mv (grep { length } split /[\s,]+/, $opt{moves}) {
            my $refusal = $game->play($mv);
            next unless $refusal;
            print STDERR "chess: --moves refused at '$mv': ", $refusal->code, "\n";
            return 2;
        }
    }

    $terminal->game($game);

    local @SIG{qw(INT TERM HUP)};
    for my $sig (qw(INT TERM HUP)) {
        $SIG{$sig} = sub { $terminal->leave_raw; $SIG{$sig} = 'DEFAULT'; kill $sig, $$ };
    }

    my $status = eval { $terminal->start };
    my $died = $@;
    $terminal->leave_raw;
    die $died if $died;
    return $status;
}


1;

__END__

=encoding utf8

=head1 NAME

Term::Chess - chess on the terminal against a bot

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $t = Term::Chess->new(level => 10_000);
    my $status = $t->start;          # RETURNS the exit status; never exits

    Term::Chess->new(ascii => 1)->draw;

=head1 DESCRIPTION

Everything that knows about a screen, and nothing that knows a rule of chess.
The rules are L<Chess::Plisco>'s, behind L<Term::Chess::Game>; the opponent is
L<Term::Chess::Bot>. C<in> and C<out> are read-write properties defaulting to
C<STDIN> and C<STDOUT>, so a test can hand it a pair of in-memory handles and
read back exactly what it drew.

B<C<start> returns and never calls C<exit>.> Its return value is the exit
status F<bin/chess> should use: C<0> if you won, drew or quit, C<1> if you
lost.

=head2 The board is drawn in fixed cells, with a margin for the marks

A square is C<size> rows tall and twice C<size> columns wide, with one gap
column between squares: 2 by 1 at size 1, 4 by 2 at size 2 (the default) and
6 by 3 at size 3. A rank is therefore always the same width whatever stands
on it, 27, 43 or 59 columns with the rank label and the two margins, and
nothing measures a string to decide how to pad it. The glyph sits on the
middle row of its square (the lower of two) and the rank label beside it.

There is B<one spare column at each side>, which is what the picker's marks go
in. A mark replaces the gap character beside a square and never a column of
the square itself, and files a and h have no gap on their outer side, so
without the margins a bracket on either edge would add a column to one row
and skew the board.

B<With colour on, the gaps and the margins are painted too>, each in the
colour of the square to its left, so the board is one block and not eight
stripes with the terminal's background showing between them. A square then
appears one column wider than its cell, and the marks sit on that colour.

The board is drawn from White's side for the seat that is White and turned
round, files and all, for the seat that is Black, so a player's own king is at
the bottom right as it is over a real board.

=head2 The shade of a square is a character

Without colour an empty light square is C< .> and an empty dark square C< :>,
so the board reads under C<NO_COLOR>, through C<ascii> and in a file. With
colour on the background carries the shade and an empty square is blank. B<a1 is dark>: a
square whose file and rank are of the same parity is dark, and C<light> is the
one place that rule is written.

=head2 The glyphs

The chess pieces come in two sets in Unicode, outline (U+2654 to U+2659) and
filled (U+265A to U+265F), named white and black. On a dark terminal the
filled glyph is the one that looks white, so the names are not trusted: B<with
colour on, both sides use the filled set> and the colour says the side; B<with
colour off, White is the outline set and Black the filled set>, because then
shape is all there is. C<ascii =E<gt> 1> is the FEN letters, C<KQRBNP> for
White and C<kqrbnp> for Black.

=head2 Colour, and NO_COLOR beating everything

If C<NO_COLOR> is present in the environment, output is uncoloured whatever
else was asked for, including an explicit C<colour =E<gt> 1>. Its B<presence>
is what counts and not its value, so C<NO_COLOR=0> still means no colour.

=head2 The output handle gets a UTF-8 layer

Unless C<ascii> is set, C<out> is given an C<:encoding(UTF-8)> layer when it
is set. Without one, every glyph raises "Wide character in print", which is a
warning and not an error: the board still appears, mangled, and the test that
goes red is some later one watching for warnings.

=head2 The picker

With a terminal and L<Term::ReadKey>, C<start> offers the arrow keys instead
of asking for a typed move. It is B<two phases, and a third for a pawn>: the
cursor walks the pieces that have a legal move, enter or space picks one up,
then the cursor walks that piece's squares and enter or space plays. When the
square is on the last rank and the piece is a pawn, the caption asks which
piece it becomes: C<q>, C<r>, C<b> or C<n>, enter or space for the queen,
escape back to the squares. Escape in the second phase puts the piece back.

B<While the picker is running it is the only thing that draws a board.> Its
first frame is the position, so C<start> draws one itself only when there is
no picker and once more at the end.

B<The cursor only ever stops where a move is.> The sets it walks are
Plisco's own: the distinct from-squares of the legal moves and then one
piece's to-squares, both in the order the board is drawn, which turns over
with the board for the seat that is Black. Left and right are a ring through
that order; up and down go to the nearest square on another rank, preferring
the closest file, and stay put at the edges.

The marks are characters and never colours: C<[ ]> round the cursor, C<( )>
round the held piece, C<+> on an empty square it may go to and C<x> on both
sides of a square where there is something to take. B<The pawn taken en
passant is marked where it stands>, which is not the destination.

The caption under the board is Plisco's vocabulary and not arithmetic done
here: what the move takes, whether it castles, promotes, checks or mates (from
the SAN), whether a capture loses material (from C<SEE>), and whether the
piece under the cursor is attacked (from C<attacked>, which reports the
attacks of the side not on move).

=head2 Typed play

Without a terminal, without L<Term::ReadKey>, or with C<picking> set false, a
move is typed at a prompt: coordinates like C<e2e4>, or standard algebraic
notation like C<Nf3>, C<exd5>, C<O-O> or C<a8=Q>. The commands are C<board>,
C<legal>, C<fen>, C<log>, C<hint>, C<resign>, C<help> and C<quit>. A refused
move is answered with the reason and its code.

On a terminal the screen is cleared before each new position is drawn, and
the bot's announcement is printed above the board. The announcement is the
move in SAN with the coordinates beside it, what it took, and whether it
checks or mates, all read from Plisco. A move the bot
offers and the game refuses ends the game with the code rather than asking the
same deterministic bot the same question for ever.

=head1 METHODS

=head2 new

    Term::Chess->new(in => $fh, out => $fh, game => $g, ascii => 0,
                     colour => undef, size => 2, level => 10_000, seat => 'p1');

C<in> and C<out> default to C<STDIN> and C<STDOUT>. C<colour> left undefined
means colour unless C<NO_COLOR> is set; C<level> is a node budget for the
opponent, and C<undef> lets the game's seed draw a rung.

=head2 in

=head2 out

Read-write properties. Setting C<out> also gives it a UTF-8 layer unless
C<ascii> is on, and does so at most once per handle.

=head2 game

Read-write. The L<Term::Chess::Game> being played; C<start> makes one if there
is none.

=head2 size

1, 2 or 3: how many rows tall a square is drawn, and half how many columns
wide. Read-only; anything else croaks in C<new>.

=head2 ascii

=head2 colour

Read-write. C<colour> can be turned on and off, but C<NO_COLOR> in the
environment has already won by the time C<new> returns.

=head2 level

The node budget handed to the opponent, or C<undef> to let the game's seed
draw a rung. Read-only: it is a property of the sitting, not of a turn.

=head2 seat

The seat the person at the keyboard plays, C<'p1'> or C<'p2'>. Read-only. The
board is drawn from that seat's side.

=head2 light

    $t->light('h1');    # 1

Whether a square is light. The one place the parity rule is written.

=head2 glyph

    $t->glyph($piece, $colour);

The character for a Plisco piece and colour under the current C<ascii> and
C<colour> settings, or C<''> for no piece.

=head2 piece_name

C<'white knight'>, or C<'nothing'>.

=head2 board_lines

    my @lines = $t->board_lines(position => $pos, flip => 1);
    my @lines = $t->board_lines(cursor => 'e2', from => 'e2', spots => ['e3', 'e4']);

The board as a list of lines, without printing anything. White is at the
bottom unless C<flip>. Every line is the same number of display columns.
C<cursor> and C<from> are single squares and C<spots> a list of them; a spot
with a piece on it is framed as something to take and an empty one is drawn as
a target. The cursor's bracket wins over the held piece's parenthesis if both
are on one square.

=head2 draw

The same, printed to C<out>. Returns the terminal.

=head2 clear

    $t->clear('the bot plays Nf3 (g1f3)');

Clears the screen when C<out> is a terminal (when L</rewind> is true) and
prints the lines given, so what was just said survives the clear. C<start>
calls it before every new position: after the bot's move with its
announcement, after a typed move, and once more at the end. Under a pipe it
only prints the lines.

=head2 describe

    $t->describe($game, 'g1f3', 'the bot plays');

One line for a move: the lead, the SAN, the coordinates, what it takes, and
whether it checks or mates.

=head2 start

Plays a game against the bot on C<in> and C<out> until somebody quits or the
game ends. B<Returns the exit status and never calls C<exit>>: C<0> if you
won, drew or quit, C<1> if you lost, C<2> if a game could not be built.

=head2 pick_move

    my $uci = $t->pick_move($game, 'p1');

Runs the picker until a move is chosen and returns it as coordinates, or the
string C<'quit'>. Draws to C<out> and reads from C<keysource> or the
terminal; it does B<not> play the move, so a caller still gets the game's
refusal if it somehow offers one.

=head2 origins, targets

    my $squares = $t->origins($pos, $flip);
    my $squares = $t->targets($pos, 'e2', $flip);

The squares the side to move may move B<from>, and the squares one piece may
move B<to>, each once and in the drawn order for C<$flip>. Both come from
Plisco's legal moves; a square whose piece cannot move is not in the first
and the four promotions are one square in the second.

=head2 moves_between

    my @moves = $t->moves_between($pos, 'a7', 'a8');

Plisco's legal moves from one square to another: one, or four for a
promotion, or none.

=head2 step

    my $i = $t->step(\@squares, $at, 'up', $flip);

The index the cursor lands on. Left, right and tab are a ring; up and down go
to the nearest square on another drawn rank and then to the closest file, and
stay put at the top and the bottom. Home and end are the first and the last.

=head2 victims

    my $squares = $t->victims($pos, 'e5');

The squares of pawns that piece would take en passant, as a hash of square to
true. Empty for everything but a pawn with that capture.

=head2 move_line, piece_line

The caption under the board: what the move from one square to another does,
and what the piece on a square is and how many moves it has. Both read
Plisco rather than working anything out here.

=head2 run

    exit Term::Chess->run(@ARGV);

The whole command line program as a class method: parses the options
F<bin/chess> documents, builds the game and the terminal, plays, and
B<returns the exit status rather than calling C<exit>>: C<0> if you won, drew
or quit, C<1> if you lost, C<2> for a bad option or a refused value, with the
usage on C<STDERR>. C<--help> prints the usage on C<STDOUT> and returns C<0>.
Options are read from the list passed in and never from C<@ARGV>. Signal
handlers are local to the call and the terminal is left in cooked mode on
every way out, so a launcher such as L<Game::Terminal> can call it in its own
process and carry on afterwards.

C<--level> takes a rung index into L<Term::Chess::Bot>'s ladder or a node
budget outright, and tells them apart by size; a number that is neither is
refused naming both ranges.

=head2 picking

Whether the arrow keys are offered. Set it false to type moves instead; left
unset it follows L</keys_available>, and C<start> turns it off for the rest of
the game if C<enter_raw> fails.

=head2 rewind

Whether a redrawn board is written over the last one instead of under it.
Unset it follows whether C<out> is a terminal.

=head2 keys_available

Whether a key can be read at all: a C<keysource>, or C<in> being a terminal
with L<Term::ReadKey> installed. B<Term::ReadKey is a recommendation and not a
prerequisite>, so this is false on a perfectly good installation and the typed
prompt is what that installation gets.

=head2 enter_raw, leave_raw

The cbreak mode round the picker. B<Cbreak and not raw>, so an interrupt is
still an interrupt. C<leave_raw> is safe to call from a signal handler and
more than once; C<start> calls it on the way out.

=head2 keysource, pending, raw

The seam a test drives the picker through, the pushback queue for an escape
sequence that turned out not to be one, and the cbreak state. C<keysource> is
a coderef returning B<one character per call>.

=head2 read_char, read_key, read_sequence

One character, one named key, and the tail of an escape sequence. C<read_key>
returns C<'up'>, C<'enter'>, C<'escape'> and so on, or the character itself.

=cut
