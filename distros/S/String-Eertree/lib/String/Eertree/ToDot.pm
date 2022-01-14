package String::Eertree::ToDot;
use Moo;
extends 'String::Eertree';

sub to_dot {
    my ($self) = @_;
    my @lines = ('digraph { rankdir = BT;');
    for my $i (0 .. $self->Last) {
        my $node = $self->node($i);
        push @lines, qq($i [shape=record, label="$i|)
            . ($node->string($self) || $i - 1) . '"]';
        push @lines, $i . '->' . $node->link . '[color=blue]';
    }
    for my $i (0 .. $self->Last) {
        my $node = $self->node($i);
        for my $ch (sort keys %{ $node->edge }) {
            push @lines, $i . '->' . $node->edge->{$ch}
                         . "[label=$ch, constraint=false]";
        }
    }
    push @lines, '}';
    return @lines
}

=head1 NAME

String::Eertree::ToDot - Draw the Eertree graph using graphviz

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This class behaves exactly the same as C<String::Eertree>, but it adds
a new method C<to_dot>.

    my $tree = 'String::Eertree::ToDot(string => 'eertree');
    print $tree->to_dot;

The method returns a list of lines you can send to graphviz to draw
the graph.

=cut

__PACKAGE__
