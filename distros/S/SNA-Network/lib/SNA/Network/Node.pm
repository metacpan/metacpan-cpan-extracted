package SNA::Network::Node;

use warnings;
use strict;

use List::Util qw(sum first);
use Object::Tiny::XS qw(index community);


use Module::List::Pluggable qw(import_modules);
import_modules('SNA::Network::Node::Plugin');


=head1 NAME

SNA::Network::Node - Node class for SNA::Network


=head1 SYNOPSIS

    my $node = $net->node_at_index(0);
    my @neighbours = $node->related_nodes;
    ...
    ...


=head1 METHODS

=head2 new

Creates a new node with the given named parameters.
Not intended for external use.

=cut

sub new {
	my ($package, %params) = @_;
	return bless { %params, outgoing_edges => [], incoming_edges => [] }, $package;
}


=head2 index

Returns the index of the node


=head2 edges

Returns the list of L<SNA::Network::Edge> objects associated with this node.

=cut

sub edges {
	my ($self) = @_;
	#FIXME why does that not work???
	return map { $_ } $self->outgoing_edges, $self->incoming_edges;
#	return($self->outgoing_edges, $self->incoming_edges);
}


=head2 related_nodes

Returns the list of L<SNA::Network::Node> objects that are linked to this node in any direction via an edge.

=cut

sub related_nodes {
	my ($self) = @_;
	return (map { $_->source } $self->incoming_edges), map { $_->target } $self->outgoing_edges;
}


=head2 incoming_edges

Returns the list of L<SNA::Network::Edge> objects that point to this node.

=cut

sub incoming_edges {
	my ($self) = @_;
	return @{ $self->{incoming_edges} };
}


=head2 incoming_nodes

Returns the list of L<SNA::Network::Node> objects that point to this node via an edge.

=cut

sub incoming_nodes {
	my ($self) = @_;
	return map { $_->source } $self->incoming_edges;

}


=head2 outgoing_edges

Returns the list of L<SNA::Network::Edge> objects pointing from this node to other nodes.

=cut

sub outgoing_edges {
	my ($self) = @_;
	return @{ $self->{outgoing_edges} };
}


=head2 outgoing_nodes

Returns the list of L<SNA::Network::Node> objects that this node points to via an edge.

=cut

sub outgoing_nodes {
	my ($self) = @_;
	return map { $_->target } $self->outgoing_edges;

}


=head2 in_degree

Returns the in-degree of this node, i.e. the number of incoming edges.

=cut

sub in_degree {
	my ($self) = @_;
	return int $self->incoming_edges;
}


=head2 out_degree

Returns the out-degree of this node, i.e. the number of outgoing edges.

=cut

sub out_degree {
	my ($self) = @_;
	return int $self->outgoing_edges;
}


=head2 summed_degree

Returns the summed degree of this node, i.e. the number of associated edges.

=cut

sub summed_degree {
	my ($self) = @_;
	return int $self->edges;
}


=head2 weighted_in_degree

Returns the weighted in-degree of this node, i.e. the sum of all incoming edge weights.

=cut

sub weighted_in_degree {
	my ($self) = @_;
	return 0 unless $self->incoming_edges;
	return sum map { $_->weight } $self->incoming_edges;
}


=head2 weighted_out_degree

Returns the weighted out-degree of this node, i.e. the sum of all outgoing edge weights.

=cut

sub weighted_out_degree {
	my ($self) = @_;
	return 0 unless $self->outgoing_edges;
	return sum map { $_->weight } $self->outgoing_edges;
}


=head2 weighted_summed_degree

Returns the summed weighted degree of this node,
i.e. the sum of all incoming and all outgoing edgeweights.

=cut

sub weighted_summed_degree {
	my ($self) = @_;
	return 0 unless $self->edges;
	return sum map { $_->weight() } $self->edges;
}


=head2 loop

Returns the L<SNA::Network::Edge> object that connects this node with itself, a so-called loop, it such one exitst. Otherwise returns C<undef>.

=cut

sub loop {
	my ($self) = @_;
	return first { $_->target == $self } $self->outgoing_edges;
}


=head2 community

Returns the index of the community the node belongs to after community identification by L<SNA::Network::Algorithm::Louvain>



=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sna-network-node at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNA-Network>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNA::Network


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNA-Network>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNA-Network>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNA-Network>

=item * Search CPAN

L<http://search.cpan.org/dist/SNA-Network>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SNA::Network::Node
