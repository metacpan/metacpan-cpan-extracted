package SRU;
{
  $SRU::VERSION = '1.01';
}
#ABSTRACT: Search and Retrieval by URL

use strict;
use warnings;


1;

__END__

=pod

=head1 NAME

SRU - Search and Retrieval by URL

=head1 SYNOPSIS

    ## a simple CGI example

    use SRU::Request;
    use SRU::Response;

    ## create CGI object
    my $cgi = CGI->new();

    ## create a SRU request object from the CGI object
    my $request = SRU::Request->newFromCGI( $cgi );

    ## create a SRU response based from the request
    my $response = SRU::Response->newFromRequest( $request );

    if ( $response->type() eq 'explain' ) {
        ...
    } elsif ( $response->type() eq 'scan' ) {
        ...
    } elsif ( $response->type() eq 'searchRetrieve' ) {
        ...
    }

    ## print out the response
    print $cgi->header( -type => 'text/xml' );
    print $response->asXML();


=head1 DESCRIPTION

The SRU package provides a framework for working with the Search and Retrieval
by URL (SRU) protocol developed by the Library of Congress. SRU defines
a web service for searching databases containing metadata and objects. SRU
often goes under the name SRW which is a SOAP version of the protocol. You
can think of SRU as a RESTful version of SRW, since all the requests are
simple URLs instead of XML documents being sent via some sort of transport
layer.

You might be interested in SRU if you want to provide a generic API for
searching a data repository and a mechanism for returning metadata records.
SRU defines three verbs: explain, scan and searchRetrieve which define the
requests and responses in a SRU interaction.

This set of modules attempts to provide a framework for building an SRU
service. The distribution is made up of two sets of Perl modules: modules in the
SRU::Request::* namespace which represent the three types of requests; and
modules in the SRU::Response::* namespace which represent the various responses.

Typical usage is that a request object is created using a factory method in the
SRU::Request module. The factory is given either a URI or a CGI object for
the HTTP request. SRU::Request will look at the URI and build the
appropriate request object: SRU::Request::Explain, SRU::Request::Scan or
SRU::Request::SearchRetrieve.

Once you've got a request object you can build a response object by using the
factory method newFromRequest() in SRU::Request. This method will examine the
request and build the corresponding result object which you can then populate
with result data appropriately. When you are finished populating the response
object with results you can call asXML() on it to get the full XML for your
response.

To understand the meaning of the various requests and their responses you'll
want to read the docs at the Library of Congress. A good place to start is
this simple introductory page: http://www.loc.gov/standards/sru/simple.html
For more information about working with the various request and response objects
in this distribution see the POD in the individual packages:

=over 4

=item * L<SRU::Request>

=item * L<SRU::Request::Explain>

=item * L<SRU::Request::Scan>

=item * L<SRU::Request::SearchRetrieve>

=item * L<SRU::Response>

=item * L<SRU::Response::Explain>

=item * L<SRU::Response::Scan>

=item * L<SRU::Response::SearchRetrieve>

=item * L<SRU::Server>

=back

Questions and comments are more than welcome. This software was developed as
part of a National Science Foundation grant for building distributed library
systems in the Ockham Project. More about Ockham can be found at
http://www.ockham.org.

=head1 DEPENDENCIES

To use L<SRU::Server> and L<Catalyst::Controller::SRU>, one must install
L<CGI::Application> and L<Catalyst>, respectively. In a future release
L<Catalyst::Controller::SRU> might be moved to an independent module.

=head1 TODO

=over 4

=item * create a client (SRU::Client)

=item * allow searchRetrieve responses to be retrieved as RSS

=item * make sure SRU::Server can function like real-world SRU interfaces

=item * handle CQL parsing errors

=item * better argument checking in response constructors

=back

=head1 AUTHORS

Ed Summers <ehs@pobox.com>

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
