package Resource::Silo::Metadata::DAG;

use strict;
use warnings;

=head1 NAME

Resource::Silo::Metadata::DAG - Generic directed (acyclic) graph for dependency tracking

=head1 DESCRIPTION

This class is an internal part of L<Resource::Silo> and is subject to change.
Its main purpose is to track incomplete resources and detect dependency loops.

=cut

use Moo;
use Carp;

=head1 ATTRIBUTES

=over

=item * edges_out

=item * edges_in

=back

=cut

# use directed graph: "consumer -> producer"
# edges_out { consumer } { producer } = 1;
# edges_in  { producer } { consumer } = 1;

has edges_out => is => 'ro', default => sub { {} };
has edges_in  => is => 'ro', default => sub { {} };

=head1 METHODS

=cut

=head2 size

Number of vertices in the graph.

=cut

sub size {
    # should be true when resource declaration is complete
    my $self = shift;
    return scalar $self->list;
}

=head2 list

Lists vertices.

=cut

sub list {
    my $self = shift;
    my %uniq;
    @uniq{ keys %{$self->edges_out}, keys %{$self->edges_in} } = ();
    return keys %uniq;
}

=head2 list_sinks

List only vertices with no outgoing edges.

=cut

sub list_sinks {
    my $self = shift;

    return grep { !$self->edges_out->{$_} } keys %{$self->edges_in};
}

=head2 list_predecessors(\@list)

Given a list of vertices, return the list of all their predecessors
without the vertices themselves.

=cut

sub list_predecessors {
    my ($self, $list) = @_;
    my %uniq;
    foreach my $node (@$list) {
        next unless $self->edges_in->{$node};
        @uniq{ keys %{$self->edges_in->{$node}} } = ();
    };
    delete $uniq{$_} for @$list; # remove self-references
    return keys %uniq;
}

=head2 contains($name)

Returns true if a vertex named C<$name> is present.

=cut

sub contains {
    my ($self, $name) = @_;
    return exists $self->edges_out->{$name}
        || exists $self->edges_in->{$name};
}

=head2 add_edges (\@from, \@to)

Add edges from first vertex to the following ones.

=cut

sub add_edges {
    my ($self, $from, $to) = @_;

    foreach my $consumer (@$from) {
        foreach my $producer (@$to) {
            next if $consumer eq $producer; # self-dependency is ignored
            $self->edges_out->{$consumer}->{$producer} = 1;
            $self->edges_in->{$producer}->{$consumer} = 1;
        }
    }
    return;
}

=head2 drop_sink_cascade($name)

If $name is a sink, remove it along with any vertex which becomes
a sink as a result of the operation, propagating along the edges.

Otherwise do nothing.

=cut

sub drop_sink_cascade {
    my ($self, $arriving) = @_;

    my @queue = ($arriving);
    while (@queue) {
        my $producer = shift @queue;
        next if $self->edges_out->{$producer}; # producer is not independent => skip
        my $node = delete $self->edges_in->{$producer};
        next unless $node; # no one is waiting => skip

        foreach my $consumer (keys %$node) {
            my $still_waiting = $self->edges_out->{$consumer};
            delete $still_waiting->{$producer};
            if (keys %$still_waiting == 0) {
                delete $self->edges_out->{$consumer};
                push @queue, $consumer;
            }
        }
    }
}

=head2 find_loop ($start, \@list, \%seen)

Find out whether calling C<< $self->add_dependency([$start], $list) >>
would cause a loop in the graph.

Due to the usage scenario, it's disjoint from adding vertices/edges.

=cut

sub find_loop {
    # before inserting a new edge, check if it would create a loop
    my ($self, $start, $list, $seen) = @_;

    foreach my $next (@$list) {
        return [$start] if $next eq $start; # loop found
        next if $seen->{$next}++;
        my $out = $self->edges_out->{$next} or next;
        my $loop = $self->find_loop($start, [ keys %$out ], $seen);
        return [$next, @$loop] if $loop;
    }

    return;
}

=head2 self_check

Check the internal structure of the graph, returning C<undef> if its intact,
or an arrayref containing the list of discrepancies otherwise.

=cut

sub self_check {
    my $self = shift;

    my @mismatch; # "consumer -> producer" or "producer <- consumer"

    foreach my $consumer (keys %{$self->edges_out}) {
        foreach my $producer (keys %{$self->edges_out->{$consumer}}) {
            push @mismatch, "$consumer <- $producer"
                unless $self->edges_in->{$producer}
                && $self->edges_in->{$producer}->{$consumer};
        }
    }

    foreach my $producer (keys %{$self->edges_in}) {
        foreach my $consumer (keys %{$self->edges_in->{$producer}}) {
            push @mismatch, "$consumer -> $producer"
                unless $self->edges_out->{$consumer}
                && $self->edges_out->{$consumer}->{$producer};
        }
    }

    # hunt down empty nodes as "produces <- ?" or "consumer -> ?"
    foreach my $name (keys %{$self->edges_out}) {
        push @mismatch, "$name -> ?"
            if keys %{$self->edges_out->{$name}} == 0;
    }
    foreach my $name (keys %{$self->edges_in}) {
        push @mismatch, "$name <- ?"
            if keys %{$self->edges_in->{$name}} == 0;
    }

    return @mismatch ? \@mismatch : undef;
}

=head1 SEE ALSO

L<Graph>.

=cut

1;
