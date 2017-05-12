package SNA::Network::Generator::ConfigurationModel;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(generate_by_configuration_model);

use List::Util qw(min shuffle);


=head1 NAME

SNA::Network::Generator::ConfigurationModel - Generate random networks according to the configuration model


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->generate_by_configuration_model( $other_network );
    ...


=head1 METHODS

The following methods are added to L<SNA::Network>.


=head2 generate_by_configuration_model

Generates a network according to the configuration model.
This means that the random network will have the same degree sequence
as the base network which is passed as a parameter.
So for each node from the base network, the random network
will have a corresponding node with the same in- and outdegree.

Note however that this method is prone to produce a few edges less,
that cannot be matched in the end because they would introduce cycles
or double edges otherwise.
So in practice the random network will be only very close to the base networks degree sequence
in most cases.

=cut

sub generate_by_configuration_model {
	my ($self, $base_network) = @_;

	# create nodes and stubs
	foreach my $base_node ($base_network->nodes) {
		my $random_node = $self->create_node_at_index(
			index => $base_node->index,
			name => 'random',
			_missing_inbound_links => $base_node->in_degree,
			_target_out_degree => $base_node->out_degree,
		);
	}
	
	# create edges
	foreach my $node (shuffle $self->nodes) {
		my @destinations = grep {
			$_->{_missing_inbound_links} > 0 && $_->{index} != $node->{index}
		} shuffle $self->nodes;

		my $last_index = min(@destinations - 1, $node->{_target_out_degree} - 1);
		
		foreach ( @destinations[0 .. $last_index] ) {
			$self->create_edge( source_index => $node->{index}, target_index => $_->index );
			$_->{_missing_inbound_links} -= 1;
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

1; # End of SNA::Network::Generator::ConfigurationModel

