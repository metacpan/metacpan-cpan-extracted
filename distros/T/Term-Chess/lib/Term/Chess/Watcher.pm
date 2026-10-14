package Term::Chess::Watcher;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.02';

sub new {
    my ($class, $budget) = @_;
    return bless { budget => $budget }, $class;
}

sub budget { $_[0]->{budget} }

sub check {
    my ($self, $tree) = @_;
    $tree->{stop_requested} = 1 if ($tree->{nodes} // 0) >= $self->{budget};
    return;
}

1;

__END__

=head1 NAME

Term::Chess::Watcher - stops a Plisco search at a node budget

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $tree = Chess::Plisco::Engine::Tree->new(
        watcher => Term::Chess::Watcher->new(40_000), ...);

=head1 DESCRIPTION

L<Chess::Plisco::Engine::Tree> asks its watcher to C<check> every few
thousand nodes, which in the UCI engine reads standard input for a C<stop>.
Setting C<max_nodes> on the tree does B<not> end a search in Plisco v1.0.3:
it only recalibrates when the clock is checked and never aborts, so the
deepening runs on to the ply limit. This watcher is the budget: once the
tree's node count reaches it, it asks for the stop the way a UCI C<stop>
would, and the tree returns the best line it has. A search bounded this way
is a property of the position and never of the clock.

=head1 METHODS

=head2 new

    Term::Chess::Watcher->new($nodes);

=head2 budget

The node count it stops at.

=head2 check

    $watcher->check($tree);

Requests a stop once C<< $tree->{nodes} >> has reached the budget.

=cut
