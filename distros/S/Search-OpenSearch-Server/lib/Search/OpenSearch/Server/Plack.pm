package Search::OpenSearch::Server::Plack;
use Moose;
extends 'Plack::Component';
with 'Search::OpenSearch::Server';
use Carp;
use Search::OpenSearch;
use Search::OpenSearch::Result;
use Plack::Request;
use Data::Dump qw( dump );
use JSON;
use Scalar::Util qw( weaken );
use Time::HiRes qw( time );

our $VERSION = '0.301';

sub log {
    my $self = shift;
    my $req  = $self->{_this_req};
    my $msg  = shift or croak "No logger message supplied";
    my $lvl  = shift || 'debug';
    if ( $req->can('logger') and $req->logger ) {
        $req->logger->( { level => $lvl, message => $msg } );
    }
}

sub call {
    my ( $self, $env ) = @_;
    my $request = Plack::Request->new($env);

    # stash this request object for log() to work
    $self->{_this_req} = $request;
    weaken( $self->{_this_req} );

    my $path = $request->path;
    if ( $request->method eq 'GET' and length $path == 1 ) {
        return $self->do_search( $request, $request->new_response() );
    }
    elsif ( $request->method eq 'GET'
        and $self->engine->has_rest_api )
    {
        return $self->do_rest_api( $request, $request->new_response() );
    }
    if ( !$self->engine->has_rest_api && $request->method eq 'POST' ) {
        return $self->do_search( $request, $request->new_response() );
    }
    elsif ( $self->engine->has_rest_api ) {
        return $self->do_rest_api( $request, $request->new_response() );
    }
    else {
        return $self->handle_no_query( $request, $request->new_response() )
            ->finalize();
    }
}

around 'do_search' => sub {
    my ( $orig, $self, $req, $response ) = @_;
    $self->$orig( $req, $response );
    return $response->finalize();
};

around 'do_rest_api' => sub {
    my ( $orig, $self, $req, $response ) = @_;
    $self->$orig( $req, $response );
    return $response->finalize();
};

1;

__END__

=head1 NAME

Search::OpenSearch::Server::Plack - serve OpenSearch results with Plack

=head1 SYNOPSIS

 # write a PSGI application in yourapp.psgi
 use strict;
 use warnings;
 use Plack::Builder;
 use Search::OpenSearch::Server::Plack;
 
 my $engine_config = {
    type   => 'Lucy',
    index  => ['path/to/your/index'],
    facets => {
        names       => [qw( topics people places orgs author )],
        sample_size => 10_000,
    },
    fields => [qw( topics people places orgs author )],
 };

 my $app = Search::OpenSearch::Server::Plack->new( 
    engine_config => $engine_config,
    stats_logger  => MyStats->new(),
 )->to_app;

 builder {
    mount '/' => $app;
 };

 
 # run the app
 % plackup yourapp.psgi
 
=head1 DESCRIPTION

Search::OpenSearch::Server::Plack is a L<Plack::Component> application.
This module implements a HTTP-ready L<Search::OpenSearch> server using L<Plack>.

=head1 METHODS

This class inherits from Search::OpenSearch::Server and Plack::Component. Only
new or overridden methods are documented here.

=head2 new( I<params> )

Inherits from Plack::Component. I<params> can be:

=over

=item engine

Should be a L<Search::OpenSearch::Engine> instance. 

=item engine_config

A hashref passed to the Search::OpenSearch->engine method.

=item stats_logger

An object that implements at least one method called B<log>. The object's
B<log> method is invoked with 2 arguments: the Plack::Request object,
and either the Search::OpenSearch::Response object or the REST response
hashref, on each request.

=back

=head2 call

Implements the required Middleware method. The default behavior is to
instantiate a L<Plack::Request> and pass it into do_search().

=head2 log( I<msg>, I<level> )

Passes I<msg> on to the Plack::Request->logger object, if any.

=head2 do_rest_api( I<request>, I<response> )

Overrides base Server method to call finalize() on I<response>.

=head2 do_search( I<request>, I<response> )

Overrides base Server method to call finalize() on I<response>.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Server


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-Server/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
