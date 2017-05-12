package SNA::Network::Algorithm::PageRank;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(calculate_pageranks calculate_weighted_pageranks);

use List::Util qw(sum);


=head1 NAME

SNA::Network::Algorithm::PageRank - implementation of the PageRank algorithm


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->load_from_pajek_net($filename);
    ...
    $net->calculate_pageranks();


=head1 METHODS

The following methods are added to L<SNA::Network>.

=head2 calculate_pageranks

Calculates PageRank values for all nodes.
Stores the values under the hash entry B<pagerank> for each node object.

You can pass named parameters to control the algorithm:
B<iterations> specifies the number of iterations to use, and defaults to 20.
B<damping> specifies the damping factor of PageRank and defaults to 0.15.

=cut

sub calculate_pageranks {
	my ($self, %params) = @_;
	
	my $iterations = $params{iterations} || 20;
	my $damping = $params{damping};
	$damping = 0.15 unless defined $damping;

	my $num_nodes = int $self->nodes;

	# sink nodes (nodes without successors) result into a random jumo
	my @sink_nodes = grep { $_->out_degree == 0 } $self->nodes;
	my @non_sinks = grep { $_->out_degree > 0 } $self->nodes;
	
	# start with 1.0 for each node
	foreach my $node ($self->nodes) {
		$node->{pagerank} = 1.0;	}

	# iterative approximation
	for (1 .. $iterations) {
		my $sinks_pr = sum 0, map { $_->{pagerank} } @sink_nodes;
		my $pr_from_sinks = $sinks_pr / $num_nodes;
		my $flowing_pr = $num_nodes - $sinks_pr;
		my $pr_from_jumps = $flowing_pr * $damping / $num_nodes;
	
		foreach my $node ($self->nodes) {
			$node->{new_pr} = $pr_from_jumps + $pr_from_sinks;
		}

		foreach my $node (@non_sinks) {
			my $outgoing_pr = (1 - $damping) * $node->{pagerank} / $node->out_degree;
			foreach my $successor ($node->outgoing_nodes) {
				$successor->{new_pr} += $outgoing_pr;
			}
		}
		
		# copy new values
		foreach my $node ($self->nodes) {
			$node->{pagerank} = $node->{new_pr};
		}
	}
}


=head2 calculate_weighted_pageranks

Intuitive extension of PageRank to weighted networks.

Same as above, but treating edge weights as relative probabilities
for the node transitions.
Stores the values under the hash entry B<pagerank> for each node object,
the same key as above!

You can pass the same parameters as above.

On a weighted network, you usually want this method's values'.

=cut

sub calculate_weighted_pageranks {
	my ($self, %params) = @_;
	
	my $iterations = $params{iterations} || 20;
	my $damping = $params{damping};
	$damping = 0.15 unless defined $damping;

	my $num_nodes = int $self->nodes;

	# sink nodes (nodes without successors) result into a random jumo
	my @sink_nodes = grep { $_->out_degree == 0 } $self->nodes;
	my @non_sinks = grep { $_->out_degree > 0 } $self->nodes;
	
	# start with 1.0 for each node
	foreach my $node ($self->nodes) {
		$node->{pagerank} = 1.0;
	}

	# iterative approximation
	for (1 .. $iterations) {
		my $sinks_pr = sum 0, map { $_->{pagerank} } @sink_nodes;
		my $pr_from_sinks = $sinks_pr / $num_nodes;
		my $flowing_pr = $num_nodes - $sinks_pr;
		my $pr_from_jumps = $flowing_pr * $damping / $num_nodes;
	
		foreach my $node ($self->nodes) {
			$node->{new_pr} = $pr_from_jumps + $pr_from_sinks;
		}

		foreach my $node (@non_sinks) {
			my $outgoing_pr = (1 - $damping) * $node->{pagerank} / $node->weighted_out_degree;
			foreach my $outgoing_link ($node->outgoing_edges) {
				$outgoing_link->target->{new_pr} += $outgoing_pr * $outgoing_link->weight;
			}
		}
		
		# copy new values
		foreach my $node ($self->nodes) {
			$node->{pagerank} = $node->{new_pr};
		}
	}
}


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

1; # End of SNA::Network::Algorithm::PageRank

