package Search::OpenSearch::Server;
use Moose::Role;
use Types::Standard qw( InstanceOf Bool Str HashRef ArrayRef Object );
use Carp;
use Search::OpenSearch;
use Search::OpenSearch::Result;
use Data::Dump qw( dump );
use JSON;
use Time::HiRes qw( time );
use Scalar::Util qw( blessed );
use Try::Tiny;

our $VERSION = '0.301';

has 'engine' => (
    is      => 'rw',
    isa     => InstanceOf ['Search::OpenSearch::Engine'],
    lazy    => 1,
    builder => 'init_engine'
);
has 'engine_config' => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => 'init_engine_config'
);
has 'stats_logger' => ( is => 'rw', isa => Object );
has 'http_allow'   => ( is => 'rw', isa => ArrayRef );

sub init_engine_config { {} }

sub init_engine {
    my $self = shift;
    return Search::OpenSearch->engine(
        logger => $self,
        %{ $self->engine_config },
    );
}

# no-op for back-compat
sub setup_engine { }

my %formats = (
    'XML'   => 1,
    'JSON'  => 1,
    'ExtJS' => 1,
    'Tiny'  => 1,
);

sub log {
    my $self = shift;
    warn(@_);
}

sub handle_no_query {
    my ( $self, $request, $response ) = @_;
    $response->status(400);
    $response->content_type('text/plain');
    $response->body("'q' required");
    return $response;
}

sub do_search {
    my $self     = shift;
    my $request  = shift or croak "request required";
    my $response = shift or croak "response required";
    my %args     = ();
    my $params   = $request->parameters;

    # convert Plack style to Catalyst style
    if ( blessed($params) && $params->isa('Hash::MultiValue') ) {
        $params = $params->mixed;
    }

    my $query = $params->{q};
    if ( !defined $query ) {
        $self->handle_no_query( $request, $response );
    }
    else {
        for my $param (qw( b q s o p h c L f u t r x )) {
            next unless exists $params->{$param};
            $args{$param} = $params->{$param};
        }

        #dump \%args;

        # coerce some params to match Engine API
        if ( exists $args{x} ) {
            if ( ref $args{x} ) {

                # ok
            }
            elsif ( !defined $args{x} or !length $args{x} ) {

                # turn into empty array
                # this effectively limits fields to built-ins.
                $args{x} = [];
            }
            else {

                # force array
                $args{x} = [ $args{x} ];
            }
        }

        # map some Ext param names
        if ( defined $params->{start} ) {
            $args{'o'} = $params->{start};
        }
        if ( defined $params->{limit} ) {
            $args{'p'} = $params->{limit};
        }

        $args{t} ||= $params->{format} || 'JSON';
        if ( !exists $formats{ $args{t} } ) {
            $self->log("bad format $args{t} -- using JSON");
            $args{format} = 'JSON';
        }

        if ( !$self->engine ) {
            croak "engine() is undefined";
        }

        my $errmsg;
        my $search_response = try {
            my $resp = $self->engine->search(%args);

            if ( $self->stats_logger ) {
                $self->stats_logger->log( $request, $resp );
            }

            return $resp;
        }
        catch {
            $errmsg = $_;
            return undef;    # so $search_response is not set.
        };
        if ( $errmsg or ( $search_response and $search_response->error ) ) {
            if ( !$errmsg and $search_response and $search_response->error ) {
                $errmsg = $search_response->error;
            }
            elsif ( !$errmsg and $self->engine and $self->engine->error ) {
                $errmsg = $self->engine->error;
            }

            # log it
            $self->log( $errmsg, 'error' );

            # trim the return to hide file and linenum
            $errmsg =~ s/ at [\w\/\.]+ line \d+\.?.*$//s;

            # clear errors
            $self->engine->error(undef) if $self->engine;
            $search_response->error(undef) if $search_response;
        }

        if ( !$search_response or $errmsg ) {
            $errmsg ||= 'Internal error';
            $response->status(500);
            $response->content_type('application/json');
            $response->body(
                encode_json( { success => 0, error => $errmsg } ) );
        }
        else {
            $search_response->debug(1) if $params->{debug};
            $response->status(200);
            $response->content_type( $search_response->content_type );
            $response->body("$search_response");
        }

    }

    return $response;
}

# only supports JSON responses for now.
sub do_rest_api {
    my $self     = shift;
    my $request  = shift or croak "request required";
    my $response = shift or croak "response required";
    my $path     = shift || $request->path;

    my $start_time = time();
    my %args       = ();
    my $params     = $request->parameters;

    # convert Plack style to Catalyst style
    if ( blessed($params) && $params->isa('Hash::MultiValue') ) {
        $params = $params->mixed;
    }

    my $method = $request->method;
    my $engine = $self->engine;

    if ( !$engine ) {
        croak "engine() is undefined";
    }

    my @engine_allowed_methods = $engine->get_allowed_http_methods();
    my $server_allowed_methods = $self->http_allow()
        || [@engine_allowed_methods];

    # allowed HTTP methods is the intersection of
    # what the server allows and what the engine allows
    my @allowed_methods;
    my %intersection;
    for my $m ( @engine_allowed_methods, @$server_allowed_methods ) {
        $intersection{$m}++;
    }
    for my $m ( keys %intersection ) {
        if ( $intersection{$m} == 2 ) {
            push @allowed_methods, $m;
        }
    }

    if (   !$engine->can($method)
        or !grep { $_ eq $method } @allowed_methods )
    {
        $response->status(405);
        $response->header( 'Allow' => join( ', ', @allowed_methods ) );
        $response->body(
            Search::OpenSearch::Result->new(
                {   success => 0,
                    msg     => "Unsupported method: $method",
                    code    => 405,
                }
            )
        );
    }
    else {

        #warn "method==$method";
        my $body;
        if ( $request->can('content') ) {
            $body = $request->content;
        }
        elsif ( $request->can('body') ) {
            $body = $request->body;
        }
        else {
            croak "\$request does not implement a body() or content() method";
        }

        # defer to explicit headers over implicit values
        my $doc = {
            url => ( $request->header('X-SOS-Content-Location') || $path ),
            modtime =>
                ( $request->header('X-SOS-Last-Modified') || CORE::time() ),
            content => ( $body || '' ),
            type => (
                       $request->header('X-SOS-Content-Type')
                    || $request->content_type
                    || 'application/json'
            ),
            size => ( $request->content_length || 0 ),
            charset => (
                       $request->header('X-SOS-Encoding')
                    || $request->content_encoding
                    || 'UTF-8'
            ),
            parser => ( $request->header('X-SOS-Parser-Type') || undef ),
        };
        $doc->{url} =~ s,^/,,;    # strip leading /

        $self->log( dump $doc );

        #warn dump $doc;

        if (    ( $doc->{url} eq '/' or $doc->{url} eq "" )
            and $method ne "COMMIT"
            and $method ne "ROLLBACK" )
        {

            #warn "invalid url";
            $response->status(400);
            $response->body(
                Search::OpenSearch::Result->new(
                    {   success => 0,
                        msg     => "Invalid or missing document URI",
                        code    => 400,
                    }
                )
            );
        }
        else {
            my $arg = $doc;
            if ( $method eq 'GET' or $method eq 'DELETE' ) {
                $arg = $doc->{url};
            }

            # call the REST method
            my $rest = $engine->$method( $arg, $params );
            $rest->{build_time} = sprintf( "%0.5f", time() - $start_time );

            # set up the response
            if ( $rest->{code} =~ m/^2/ ) {
                $rest->{success} = 1;
            }
            else {
                $rest->{success} = 0;
            }

            my $rest_resp = Search::OpenSearch::Result->new(%$rest);

            if ( $self->stats_logger ) {
                $self->stats_logger->log( $request, $rest_resp );
            }

            $response->status( $rest_resp->code );
            $response->content_type(
                Search::OpenSearch::Response::JSON->content_type );
            $response->body("$rest_resp");

            #dump($response);
        }
    }

    return $response;
}

1;

__END__

=head1 NAME

Search::OpenSearch::Server - serve OpenSearch results

=head1 DESCRIPTION

Search::OpenSearch::Server is a Moose::Role. 

=head1 METHODS

The following methods are available to consumers.

=head2 engine

A L<Search::OpenSearch::Engine> instance created by B<init_engine>
or passed to new().

=head2 init_engine

Returns a L<Search::OpenSearch::Engine> instance, passing in the contents
of B<engine_config> with the C<logger> param set to $self.

=head2 engine_config

Defaults to an empty hashref.

=head2 init_engine_config

Returns empty hashref.

=head2 stats_logger

Expects an object of some kind.

=head2 http_allow

Expects an array ref of HTTP method names.

=head2 do_search( I<request>, I<response> )

Performs a search using a Search::OpenSearch::Engine set in engine().

=over

=item request

A Request object. Should act like a Plack::Request or a Catalyst::Request.

=item response

A Response object. Should act like a Plack::Response or a Catalyst::Response.

=back

Will return the I<response> object.

=head2 do_rest_api( I<request>, I<response>[, I<path>] )

Calls the appropriate REST method on the engine().

=over

=item request

A Request object. Should act like a Plack::Request or a Catalyst::Request.

=item response

A Response object. Should act like a Plack::Response or a Catalyst::Response.

=back

Will return the I<response> object.

The following HTTP headers are supported for explicitly setting
the indexer behavior:

=over

=item X-SOS-Content-Location

=item X-SOS-Last-Modified

=item X-SOS-Parser-Type

=item X-SOS-Content-Type

=item X-SOS-Encoding

=back

=head2 handle_no_query( I<request>, I<response> )

If no 'q' param is present in the Plack::Request, this method is called.
The default behavior is to set a 400 (bad request) with error message.
You can override it to behave more kindly.

=over

=item request

A Request object. Should act like a Plack::Request or a Catalyst::Request.

=item response

A Response object. Should act like a Plack::Response or a Catalyst::Response.

=back

Will return the I<response> object.

=head2 log( I<msg> [, <level ] )

Utility method. Default is to warn(I<msg>).

=head2 setup_engine

A no-op for backwards compatability for pre-Moose version of this class.
 
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
