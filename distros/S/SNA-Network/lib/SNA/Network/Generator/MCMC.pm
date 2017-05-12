package SNA::Network::Generator::MCMC;

use strict;
use warnings;

require Exporter;
use base 'Exporter';
our @EXPORT = qw(shuffle);

use List::MoreUtils qw(uniq none);


=head1 NAME

SNA::Network::Generator::MCMC - Generate random networks by a series of edge swaps according to the Markov Chain Monte Carlo principle


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new_from_pajek_net($filename);
    $net->shuffle;
    ...
    for (1.100) {
    	say $net->shuffle->identify_weakly_connected_components;
    }


=head1 METHODS

The following methods are added to L<SNA::Network>.


=head2 shuffle

Generates a random networks by a series of edge swaps on an existing network according to the Markov Chain Monte Carlo principle. This means that the initial network will be changed and have a totally new, random edge structure.

This method will exactly preserve all in- and outdegrees, and is guaranteed to sample uniformly at random from all possible simple graph configurations.

You may optionally pass the number of steps to perform. By default, the currently best known number is used, namely the number of edges in the network multiplied by its logarithm.

Returns the network reference again, in order to enable method chaining.

=cut

sub shuffle {
	my ($self, $steps) = @_;
		
	$steps ||= int (int $self->edges * log int $self->edges);

	for (1 .. $steps) {
		_swap_random_edges($self);
	}
	
	return $self;
}


sub _swap_random_edges {
	my ($self) = @_;

	my $index_one = int rand int $self->edges;
	my $index_two = int rand int $self->edges;

	my $edge_one = $self->{edges}->[$index_one];
	my $edge_two = $self->{edges}->[$index_two];
	
	if (
		    uniq($edge_one->source, $edge_one->target, $edge_two->source, $edge_two->target) == 4
		and none { $_ == $edge_two->target } $edge_one->source->outgoing_nodes
		and none { $_ == $edge_one->target } $edge_two->source->outgoing_nodes
	) {
		# swap target nodes
		my $edge_one_target = $edge_one->target;
		$edge_one->{target} = $edge_two->target;
		$edge_two->{target} = $edge_one_target;
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

1; # End of SNA::Network::Generator::MCMC

