package SNA::Network::Algorithm::Cores;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(calculate_in_ccs);


=head1 NAME

SNA::Network::Algorithm::Cores - calculate core collapse sequences (CCS)


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->load_from_pajek_net($filename);
    ...
    my $k_max = $net->calculate_in_ccs();


=head1 METHODS

The following methods are added to L<SNA::Network>.


=head2 calculate_in_ccs

Calculates the in-core collapse sequence of the graph.
All nodes get a maximum core membership k, starting from 0 on.
Stores the k value under the hash entry B<k_in_core> for each node object.
Returns the maximum k in the network.

=cut

sub calculate_in_ccs {
	my ($self) = @_;
	
	foreach ($self->nodes) {
		undef $_->{k_in_core};
		$_->{_open_pres} = int $_->incoming_nodes;
	}
	
	my $k = 0;
	my @open = $self->nodes;
	
	do {
		$k += 1;
		my @recheck = ();
		
		foreach my $node (@open) {
			if ($node->{_open_pres} < $k) {
				$node->{k_in_core} = $k - 1;
				foreach ($node->outgoing_nodes) {
					$_->{_open_pres} -= 1; # unless $_->{k_in_core};
				}
				push @recheck, $node->outgoing_nodes;
				#TODO check with smaller id only
			}
		}

		RECHECK:
		while (@recheck) {
			my $node = shift @recheck;
			next RECHECK if defined $node->{k_in_core};
			
			if ($node->{_open_pres} < $k) {
				$node->{k_in_core} = $k - 1;
				foreach ($node->outgoing_nodes) {
					$_->{_open_pres} -= 1; # unless $_->{k_in_core};
				}
				push @recheck, $node->outgoing_nodes;
			}
		}
		
		@open = grep { !defined $_->{k_in_core} } @open;
		
	} while (@open);
	
	return $k - 1;
}

#TODO try counting


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

1; # End of SNA::Network::Algorithm::Cores

