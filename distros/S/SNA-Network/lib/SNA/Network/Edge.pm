package SNA::Network::Edge;

use warnings;
use strict;

use Carp qw(croak);
use Object::Tiny::XS qw(source target weight);

=head1 NAME

SNA::Network::Edge - Edge class for SNA::Network


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SNA::Network::Edge;

    my $foo = SNA::Network::Edge->new();
    ...


=head1 METHODS

=head2 new

Create a new edge with source, target and weight.

=cut

sub new {
	my ($package, %params) = @_;
	croak unless defined $params{source};
	croak unless defined $params{target};
	croak unless defined $params{index};
	$params{weight} = 1 unless defined $params{weight};
	return bless { %params }, $package;
}


=head2 source

Returns the source node object of the edge.


=head2 target

Returns the target node object of the edge.

=head2 weight

Returns the weight of the edge.


=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sna-network-edge at rt.cpan.org>, or through
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

1; # End of SNA::Network::Edge
