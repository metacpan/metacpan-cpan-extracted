package Search::OpenSearch::Server::Catalyst;
use MooseX::MethodAttributes::Role;
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';
use namespace::autoclean;

our $VERSION = '0.301';

sub log {
    my $self = shift;
    my $app  = $self->_app;
    my $msg  = shift or croak "No logger message supplied";
    my $lvl  = shift || 'debug';
    if ( $lvl eq 'debug' ) {
        $app->log->$lvl($msg) if $app->debug;
    }
    else {
        $app->log->$lvl($msg);
    }
}

sub process_request {
    my ( $self, $c, @args ) = @_;

    my $request  = $c->request;
    my $response = $c->response;

    my $path = join( '/', @args );
    $self->log("sos path=$path") if $c->debug;

    if ( $request->method eq 'GET'
        and ( !length $path or $path eq 'search' ) )
    {
        return $self->do_search( $request, $response );
    }
    elsif ( $request->method eq 'GET'
        and $self->engine->has_rest_api )
    {
        return $self->do_rest_api( $request, $response, $path );
    }
    if ( !$self->engine->has_rest_api && $request->method eq 'POST' ) {
        return $self->do_search( $request, $response );
    }
    elsif ( $self->engine->has_rest_api ) {
        return $self->do_rest_api( $request, $response, $path );
    }
    else {
        return $self->handle_no_query( $request, $response );
    }
}

sub default : Path {
    my ( $self, $c, @arg ) = @_;
    $self->process_request( $c, @arg );
}

1;

__END__

=head1 NAME

Search::OpenSearch::Server::Catalyst - serve OpenSearch results with Catalyst

=head1 SYNOPSIS

 package MyApp::Controller::API;
 use Moose;
 extends 'Catalyst::Controller';
 with 'Search::OpenSearch::Server';
 with 'Search::OpenSearch::Server::Catalyst';
 use MyStats;   # acts like a Dezi::Stats subclass
 
 __PACKAGE__->config(
    engine_config = {
        type   => 'Lucy',
        index  => ['path/to/your/index'],
        facets => {
            names       => [qw( topics people places orgs author )],
            sample_size => 10_000,
        },
        fields => [qw( topics people places orgs author )],
    },
    stats_logger => MyStats->new(),
 );

 1;

 # now you can:
 # GET  /api/search
 # POST /api/foo/bar
 
=head1 DESCRIPTION

B<NOTE> This class used to be a Controller subclass. It is Role
as of version 0.300.

Search::OpenSearch::Server::Catalyst is a consumable Role used
by L<CatalystX::Controller::OpenSearch>. If you just want a simple
controller, you probably want L<CatalystX::Controller::OpenSearch>.

=head1 METHODS

This class isa L<MooseX::MethodAttributes::Role>. Only
new or overridden methods are documented here.

=head2 default( I<ctx> )

This method registers a URL action in the controller namespace.

The default() action passes the I<ctx> and any other path args
to process_request(). Override this method to control what
your addressable URL(s) look like.

=head2 process_request( I<ctx>, I<args> )

Process the incoming request and create a response.
The algorithm is, briefly:

 GET -> do_search()
 POST, PUT, DELETE -> do_rest_api()

I<args> is an array joined with C</> to create an
actionable path. If that path is the string C<search>
or is empty, then do_search() is triggered on GET requests.
The path is ignored for all non-GET requests.

=head2 log( I<msg>, I<level> )

Passes I<msg> on to the app $ctx->log method. I<level> defaults
to C<debug> and will only be passed to $ctx->log if $ctx->debug
is true.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Server::Catalyst


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

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
