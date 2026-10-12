package Term::Chess::Error;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our @FLAGS;
BEGIN {
    @FLAGS = qw(
        bad_move
        game_over
        not_your_turn
        no_piece
        bad_promotion
        in_check
        not_legal
    );
}

our %MESSAGE;
BEGIN {
    %MESSAGE = (
        bad_move      => 'that is not a move',
        game_over     => 'the game is already over',
        not_your_turn => 'that piece is not yours to move',
        no_piece      => 'there is no piece there',
        bad_promotion => 'a pawn reaching the last rank must say what it becomes',
        in_check      => 'that would leave your king in check',
        not_legal     => 'that piece cannot move there',
    );
}

has [@FLAGS] => (is => 'ro');

has error => (is => 'ro', default => 1);

has message => (is => 'ro', isa => Str, default => '');

has legal => (is => 'ro', isa => ArrayRef, default => []);

sub throw {
    my ($class, $flag, %extra) = @_;
    die "Term::Chess::Error: no such flag '$flag'" unless exists $MESSAGE{$flag};
    return $class->new(
        $flag   => 1,
        error   => 1,
        message => $MESSAGE{$flag},
        %extra,
    );
}

sub code {
    my ($self) = @_;
    for my $flag (@FLAGS) {
        return $flag if $self->$flag;
    }
    return undef;
}

sub stringify { $_[0]->message }

sub flags { @FLAGS }

sub message_for { $MESSAGE{ $_[1] } }

sub known { exists $MESSAGE{ $_[1] } ? 1 : 0 }

1;

__END__

=head1 NAME

Term::Chess::Error - a refused move: a code, a sentence, and the legal list

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $refusal = $game->play('e2e5');

    if ($refusal) {
        say $refusal->code;         # 'not_legal'
        say $refusal->message;      # 'that piece cannot move there'
        say 1 if $refusal->not_legal;
    }

=head1 DESCRIPTION

A refused move comes back as one of these. It is B<not> thrown: a refused
move is an ordinary thing for a player to do, and unwinding the stack for it
would make every caller wrap every move in an C<eval>. C<die> is kept for
programmer error, which here is a flag that does not exist.

Seven flags, exactly one of them set. The rules of chess themselves are
L<Chess::Plisco>'s and are never judged here; the flag says why a move that
Plisco did not list was refused, from what the board and the list say about
the near misses.

=head1 ATTRIBUTES

=head2 bad_move

Not a move at all: a string Plisco could not read, or a promotion written
without its piece where Plisco cannot tell what was meant.

=head2 game_over

The game has finished.

=head2 not_your_turn

The piece on the from-square belongs to the side not on move.

=head2 no_piece

The from-square is empty.

=head2 bad_promotion

A pawn move to the last rank with no piece named, or the wrong one.

=head2 in_check

The piece can make that move, and only the king forbids it: the side to
move is in check and the move leaves it there, or the piece is pinned.

=head2 not_legal

Everything else: the piece does not move that way, or something stands in
the road.

=head2 error

Always true, so a refusal is true in boolean context and C<0> from C<play>
means the move was played.

=head2 message

One sentence for a person.

=head2 legal

The legal moves as coordinates, carried by C<in_check> and C<not_legal> so a
caller can list what was possible instead.

=head1 METHODS

=head2 throw

    Term::Chess::Error->throw('not_legal', legal => \@moves);

Builds a refusal with that flag set. Despite the name it returns the object
and dies only for a flag that does not exist.

=head2 code

The one flag that is set, as a string.

=head2 stringify

The message. There is no C<""> overload on purpose: a refusal that quietly
turns into a string hides the code that says what happened.

=head2 flags

Every flag, in the order C<code> checks them.

=head2 message_for

    Term::Chess::Error->message_for('in_check');

The sentence for a flag.

=head2 known

Whether a string is a flag.

=cut
