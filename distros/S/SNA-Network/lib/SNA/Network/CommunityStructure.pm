package SNA::Network::CommunityStructure;

use strict;
use warnings;

use Carp;
use List::Util qw(sum);


=head1 NAME

SNA::Network::CommunityStructure - Community structure class for SNA::Network


=head1 SYNOPSIS

	$n->identify_communities_with_louvain
	
	# output the number of hierarchical levels
	say int @{$n->community_levels}
	
	# print the number of communities on the first, finest-granular level
	say int $n->community_levels->[0]->communities
	
	# print the modularity of the first-level structure
	say int $n->community_levels->[0]->modularity

	
	

=head1 METHODS

=head2 new

Creates a new community  structure with a passed list of L<SNA::Network::Community> objects.

=cut

sub new {
	my ($package, @communities) = @_;
	my $self = bless [ @communities ], $package;
	return $self;
}


=head2 communities

Returns a list of L<SNA::Network::Community> objects, which are part of this structure.

=cut

sub communities {
	my ($self) = @_;
	return @{ $self };
}


=head2 modularity

Returns the network modularity value of this community structure

=cut

sub modularity {
	my ($self) = @_;
	return sum map { $_->module_value } @$self;
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

Copyright 2014 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;

