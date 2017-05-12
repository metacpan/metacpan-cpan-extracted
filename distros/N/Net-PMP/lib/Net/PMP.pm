package Net::PMP;
use strict;
use warnings;
use Net::PMP::Client;
use Net::PMP::CollectionDoc;

our $VERSION = '0.006';

sub client {
    my $class = shift;
    return Net::PMP::Client->new_with_config(@_); 
}

1;

__END__

=head1 NAME

Net::PMP - Perl SDK for the Public Media Platform

=head1 SYNOPSIS

 use Net::PMP;
 
 my $host = 'https://api-sandbox.pmp.io';
 my $client_id = 'i-am-a-client';
 my $client_secret = 'i-am-a-secret';

 # instantiate a client
 my $client = Net::PMP->client(
     host   => $host,
     id     => $client_id,
     secret => $client_secret,
 ); 

 # search
 my $search_results = $client->search({ tag => 'samplecontent', profile => 'story' });  
 my $results = $search_results->get_items();
 printf( "total: %s\n", $results->total );
 while ( my $r = $results->next ) { 
     printf( '%s: %s [%s]', $results->count, $r->get_uri, $r->get_title, ) );
 }   
 
=cut

=head1 DESCRIPTION

Net::PMP is a Perl client for the Public Media Platform API (http://docs.pmp.io/).

This class is mostly a namespace-holder and documentation, with one convenience method: client().

=head1 METHODS

=head2 client( I<args> )

Returns a new Net::PMP::Client object. 
See L<Net::PMP::Client> new() method for I<args> details.
Note that new_with_config() is the actual method called, as a convenience
via L<MooseX::SimpleConfig>. You can define a config file in
$ENV{HOME}/.pmp.yaml (default)  and it will be read automatically when
instantiating a Client. See L<MooseX::SimpleConfig> and L<Net::PMP::CLI> for
examples.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP


You can also look for information at:

=over 4

=item * IRC

Join #pmp on L<http://freenode.net>.

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut
