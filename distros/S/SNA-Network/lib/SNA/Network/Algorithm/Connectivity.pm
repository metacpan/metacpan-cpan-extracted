package SNA::Network::Algorithm::Connectivity;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(identify_weak_components);


=head1 NAME

SNA::Network::Algorithm::Connectivity - identify network components


=head1 SYNOPSIS

    use SNA::Network;

    my $net = SNA::Network->new();
    $net->load_from_pajek_net($filename);
    ...
    my $number_of_weak_components = $net->identify_weak_components();


=head1 METHODS

The following methods are added to L<SNA::Network>.


=head2 identify_weak_components

Identifies the weak components in the graph.
All componets get an id, starting from 0 on.
Stores the component id under the hash entry B<weak_component_id> for each node object.
Returns the number of weak components found in the network.

=cut

sub identify_weak_components {
	my ($self) = @_;
	
	foreach ($self->nodes) {
		undef $_->{weak_component_id};
	}
	
	my $weak_component_id = 0;
	my @remainder = $self->nodes();
	do {
		_weakly_expand_node($remainder[0], $weak_component_id);
		$weak_component_id += 1;
		@remainder = grep { !defined $_->{weak_component_id} } @remainder;
	} while (@remainder > 0);
	
	return $weak_component_id;
}


sub _weakly_expand_node {
	my ($node, $weak_component_id) = @_;
	
	$node->{weak_component_id} = $weak_component_id;
	my @to_expand = ($node);

	while (@to_expand) {
		my $next_node = shift @to_expand;
		my @unassigned_related_nodes = grep { !defined $_->{weak_component_id} } $next_node->related_nodes();
		foreach (@unassigned_related_nodes) {
			$_->{weak_component_id} = $weak_component_id;		
		}
		push @to_expand, @unassigned_related_nodes;
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

1; # End of SNA::Network::Algorithm::Connectivity

