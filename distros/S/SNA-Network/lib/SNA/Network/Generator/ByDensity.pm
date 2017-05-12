package SNA::Network::Generator::ByDensity;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(generate_by_density);


=head1 NAME

SNA::Network::Generator::ByDensity - Generate random networks by density


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->generate_by_density( nodes => 100, density => 0.05);
    # or
    $net->generate_by_density( nodes => 100, edges => 445);
    ...


=head1 METHODS

The following methods are added to L<SNA::Network>.


=head2 generate_by_density

Generates a network with the given number of nodes
and the given density OR number of edges.
The network is not guaranteed to have the resulting number of edges,
but it it stochasticly expected to have them.
Expected Degrees are the same for all nodes.

=cut

sub generate_by_density {
	my ($self, %params) = @_;

	for (0 .. $params{nodes} - 1) {
		$self->create_node_at_index(index => $_);
	}
	
	my $density = $params{density};
	$density ||= $params{edges} / ($params{nodes} ** 2 - $params{nodes});
		
	for my $s (0 .. $params{nodes} - 1) {
		for my $t (0 .. $params{nodes} - 1) {
			next if $s == $t;
			if ( rand()  < $density ) {
				$self->create_edge( source_index => $s, target_index => $t );
			}
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

1; # End of SNA::Network::Generator::ByDensity

