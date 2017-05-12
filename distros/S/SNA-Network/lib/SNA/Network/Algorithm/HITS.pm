package SNA::Network::Algorithm::HITS;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(calculate_authorities_and_hubs _kleinberg_iteration);

use List::Util qw(sum);


=head1 NAME

SNA::Network::Algorithm::HITS - implementation of Kleinberg's HITS algorithm


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->load_from_pajek_net($filename);
    ...
    $net->calculate_authorities_and_hubs();


=head1 METHODS

The following methods are added to L<SNA::Network>.

=head2 calculate_authorities_and_hubs

Calculates authority and hub coefficients for all nodes.
Stores the coefficients under the hash entries B<authority> and B<hub> for each node object.

=cut

sub calculate_authorities_and_hubs {
	my ($self) = @_;

	# arbitrary start vectors
	my $x = [ (1) x int $self->nodes() ];
	my $y = [ (1) x int $self->nodes() ];
	
	# 20 iterations by default, see paper
	for (1 .. 20) {
		($x, $y) = $self->_kleinberg_iteration($x, $y);
	}

	my $index = 0;	
	foreach my $node ($self->nodes()) {
		$node->{authority} = $x->[$index];
		$node->{hub} = $y->[$index++];
	}
}


sub _kleinberg_iteration {
	my ($self, $x_in, $y_in) = @_;

	# calculate new authority coefficients
	my @x_new = map {
		my $x_node = $self->node_at_index($_);
		sum(
			map {
				$y_in->[$_->index()] # y's current hub coefficient
			} $x_node->incoming_nodes()
		) || 0
	} (0 .. int $self->nodes() - 1);

	# calculate new hub coefficients
	my @y_new = map {
		my $y_node = $self->node_at_index($_);
		sum(
			map {
				$x_in->[$_->index()] # x's current authority coefficient
			} $y_node->outgoing_nodes()
		) || 0
	} (0 .. int $self->nodes() - 1);
	

	# _normalise vectors so sum of squares is 1
	_normalise(\@x_new);
	_normalise(\@y_new);
	
	return (\@x_new, \@y_new);
}


sub _normalise {
	my ($vector) = @_;
	my $squared_sum = sum(
		map { $_ ** 2 } @{$vector}
	);
	my $normalisation = 1 / sqrt $squared_sum;
	foreach (@{$vector}) {
		$_ *= $normalisation;
	}
	return $vector;
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

1; # End of SNA::Network::Algorithm::HITS

