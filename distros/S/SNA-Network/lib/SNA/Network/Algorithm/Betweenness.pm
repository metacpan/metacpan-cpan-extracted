package SNA::Network::Algorithm::Betweenness;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(calculate_betweenness);


=head1 NAME

SNA::Network::Algorithm::Betweenness - Calculate betweenneess values for all nodes


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->load_from_pajek_net($filename);
    ...
    my $r = $net->calculate_betweenness;


=head1 METHODS

The following methods are added to L<SNA::Network>.

=head2 calculate_betweenness

Calculates exact betweenness centrality values for all nodes and edges.
Stores the values under the hash entry B<betweenness> for each node and edge object.
Uses the algorithm published by Ulrik Brandes in 2001.

You can pass named parameters to control the algorithm:
B<normalise> specifies whether you want the betweenness values as the plain number of shortest paths
going through the node or edge object (B<normalise => 0>),
or to be normalised to the interval between 0 and 1 (B<normalise => 1>).
It defaults to 1.

=cut

sub calculate_betweenness {
	my ($self, %options) = @_;
	$options{normalise} = 1 unless defined $options{normalise};

	foreach ($self->nodes, $self->edges) {
		$_->{betweenness} = 0;
	}
	
	foreach my $source ($self->nodes) {
		foreach ($self->nodes) {
			$_->{_pre} = [];
			$_->{_sigma} = 0;
			$_->{_delta} = 0;
			$_->{_distance} = -1;
		}
		$source->{_sigma} = 1;
		$source->{_distance} = 0;
		
		my @stack = ();
		my @queue = ($source);
		
		while (@queue) {
			my $v = shift @queue;
			push @stack, $v;
			
			foreach my $edge ($v->outgoing_edges) {
				my $succ = $edge->target;
				if ($succ->{_distance} < 0) {
					push @queue, $succ;
					$succ->{_distance} = $v->{_distance} + 1;
				}
				
				if ( $succ->{_distance} == $v->{_distance} + 1 ) {
					$succ->{_sigma} += $v->{_sigma};
					$edge->{_sigma} += $v->{_sigma};
					push @{ $succ->{_pre} }, $edge;
				}
			}
		}
		
		foreach my $w (reverse @stack) {
			foreach my $pre ( @{ $w->{_pre} } ) {
				$pre->{betweenness} += ( $pre->source->{_sigma} / $w->{_sigma} ) * ( 1 + $w->{_delta} );
				$pre->source->{_delta} += ( $pre->source->{_sigma} / $w->{_sigma} ) * ( 1 + $w->{_delta} );
			}
			$w->{betweenness} += $w->{_delta} if $w != $source;
		}
	}
	
	# normalise & clean up
	my $n = int $self->nodes;
	foreach ($self->nodes) {
		delete $_->{_pre};
		delete $_->{_sigma};
		delete $_->{_delta};
		delete $_->{_distance};
		if ($options{normalise} and $n > 2) {
			$_->{betweenness} /= ($n - 1) * ($n - 2);
		}
	}
	if ($options{normalise} and $n > 1) {
		$_->{betweenness} /= $n * ($n - 1) foreach ($self->edges);
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

