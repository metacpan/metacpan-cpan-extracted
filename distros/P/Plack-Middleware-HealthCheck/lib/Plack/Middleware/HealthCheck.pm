package Plack::Middleware::HealthCheck;

# ABSTRACT: A health check endpoint for your Plack app
use version;
our $VERSION = 'v0.2.1'; # VERSION

use 5.010;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Request;
use Plack::Util::Accessor qw(
    health_check
    health_check_paths
    allowed_params
);

use Carp;
use JSON         ();
use Scalar::Util ();

sub new {
    my ( $class, @args ) = @_;
    my %params = @args == 1
        && Scalar::Util::reftype $args[0] eq 'HASH' ? %{ $args[0] } : @args;

    if ( $params{health_check} ) {
        croak "health_check doesn't seem like a HealthCheck"
            unless do { local $@; eval { local $SIG{__DIE__};
                $params{health_check}->can('check') } };
    }
    else {
        croak "health_check parameter required";
    }

    # Adding default params if none specified
    $params{allowed_params} = [qw< runtime >]
        unless exists $params{allowed_params};

    # custom query param filter validation
    my $error = "HealthCheck allowed_params must be an arrayref of strings";
    my $ref   = Scalar::Util::reftype $params{allowed_params};

    if ( !$ref ) {    # someone sent a scalar; massage it
        $params{allowed_params} = [ $params{allowed_params} ];
    }
    elsif ( $ref ne 'ARRAY' ) {
        croak "$error; found $ref";
    }

    foreach my $param ( @{ $params{allowed_params} } ) {
        if ( my $ref = Scalar::Util::reftype $param ) {
            croak "$error; found $ref value";
        }
        elsif ( lc $param eq 'env' ) {
            croak "Cannot overload \%env params";
        }
    }

    return $class->SUPER::new(
        health_check_paths => ['/healthz'],
        %params,
    );
}

sub call {
    my ( $self, $env ) = @_;

    return $self->serve_health_check($env)
        if $self->should_serve_health_check($env);

    return $self->serve_tags_list($env)
        if $self->should_serve_tags_list($env);

    return $self->app->($env);
}

sub should_serve_health_check {
    my ( $self, $env ) = @_;

    my $path = $env->{'PATH_INFO'};
    foreach ( @{ $self->health_check_paths || [] } ) {
        return 1 if $path eq $_;
    }

    return 0;
}

sub should_serve_tags_list {
    my ( $self, $env ) = @_;

    my $path = $env->{'PATH_INFO'};
    foreach ( @{ $self->health_check_paths || [] } ) {
        return 1 if $path eq "$_/tags";
    }

    return 0;
}

sub serve_health_check {
    my ( $self, $env ) = @_;

    my $req            = Plack::Request->new($env);
    my $query_params   = $req->query_parameters;         # a Hash::MultiValue
    my $allowed_params = $self->allowed_params || [];    # an array

    my %check_params = ( env => $env );

    foreach my $param ( @{$allowed_params}, 'tags' ) {
        if( exists $query_params->{$param} ){
            $check_params{$param} = [ $query_params->get_all($param) ]
                if exists $query_params->{$param};
        }
    }

    # turn on runtime if pretty and make param value scalar not array
    if ( exists $check_params{runtime} ) {
        $check_params{runtime}
            = $check_params{runtime}[0] eq '' ? 1 : $check_params{runtime}[0];
    }
    elsif ( exists $req->query_parameters->{pretty} ) {
        $check_params{runtime} = 1;
    }

    local $SIG{__WARN__} = sub { $env->{'psgi.errors'}->print($_) for @_ };
    return $self->health_check_response(
        $self->health_check->check(%check_params), $req );
}

sub serve_tags_list {
    my ( $self, $env ) = @_;

    my $req = Plack::Request->new($env);

    return $self->health_check_response(
        [ $self->health_check->get_registered_tags ], $req );
}

sub health_check_response {
    my ( $self, $result, $req ) = @_;
    my $json = JSON->new->allow_blessed->convert_blessed->utf8;
    $json->canonical->pretty
        if $req and exists $req->query_parameters->{pretty};
    return [
        ref $result eq 'ARRAY' || ( $result->{status} || '' ) eq 'OK'
            ? 200 : 503,
        [ 'Content-Type' => 'application/json; charset=utf-8' ],
        [ $json->encode($result) ] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::HealthCheck - A health check endpoint for your Plack app

=head1 VERSION

version v0.2.1

=head1 SYNOPSIS

    $psgi_app = Plack::Middleware::HealthCheck->wrap( $psgi_app,
        health_check => HealthCheck->new(...),
    )

This automatically serves the results as JSON at C</healthz>.

You can serve the results from different L</health_check_paths> than the default,
and you can specify which query parameters,
other than the always allowed C<tags>,
are passed to the check with L</allowed_params>.
Runtime support is enabled by default,
but can be overridden by specifying an L</allowed_params> configuration,
like the one below, that does not include C<runtime>.

    $psgi_app = HealthCheck::Diagnostic::LoadAverage->wrap( $psgi_app,
        health_check       => HealthCheck->new(...),
        health_check_paths => ['/_healthcheck'],
        allowed_params     => [ 'foo', 'bar' ],
    );

Since you don't want to serve this HealthCheck everywhere on the internet, you
should limit its access,
for example using L<Plack::Middleware::Conditional> to limit by IP address.

    # Using enable_if
    use Plack::Builder;

    builder {
        enable_if { $_[0]->{REMOTE_ADDR} =~ /^10\./ } 'HealthCheck',
            health_check => HealthCheck->new(...),
        ;
        $psgi_app;
    };

    # OO interface
    $app = Plack::Middleware::Conditional->wrap(
        $psgi_app,
        condition  => sub { $_[0]->{REMOTE_ADDR} =~ /^10\./ },
        builder => sub {
            Plack::Middleware::HealthCheck->wrap( $psgi_app,
                health_check => HealthCheck->new(...),
            )
        },
    );

=head1 DESCRIPTION

Does a basic health check for your app, by default responding on
L</health_check_paths> with L</serve_health_check>.

You must provide your own L</health_check> object that the checks will
be run against.

=head1 NAME

Plack::Middleware::HealthCheck - Health checks for your plack app

=head1 ATTRIBUTES

=head2 health_check

A L<HealthCheck> object that should have checks with the C<ecv_test> tag.

The default object registers C<LoadAverage> and C<HideFile> checks
with the values from L</load_limit> and L</hide_files>.

=head2 health_check_paths

A list of URLs to L</serve_health_check> from.

Defaults to C<['/healthz']>.

If you don't want any health check paths,
set this to an empty arrayref (C<[]>).

=head2 allowed_params

A list of C<query_params> to pass through to C<check>.
Parameters are passed with the values in arrayrefs.

Defaults to C<runtime>,
and C<tags> are always passed by L</serve_health_check>.

The C<runtime> parameter defaults to true if C<pretty> is specified,
or it is in the query string without a value.

=head1 METHODS

=head2 serve_health_check

Called with the Plack C<$env> hash as an argument
if L</should_serve_health_check> returns true.

Reads the query parameters for any C<tags> or other L</allowed_params>
and then calls
the L</health_check> check method with those parameters as well as passing
C<$env> under the "env" key.

Returns the result of passing the health check C<$result>
to L</health_check_response>.

=head2 serve_tags_list

Called with the Plack C<$env> hash as an argument
if L</should_serve_health_check> returns true.

Calls L<get_registered_tags|HealthCheck/get_registered_tags> on the
L<health_check> and returns the result of passing the list of tags to
L</health_check_response>.

=head2 should_serve_health_check

Receives the Plack C<$env> as an argument and returns a truthy value
if C<< $env->{PATH_INFO} >> matches any of the L</health_check_paths>.

=head2 should_serve_tags_list

Receives the Plack C<$env> as an argument and returns a truthy value if C<<
$env->{PATH_INFO} >> matches any of the L</health_check_paths> followed by
C</tags>.

=head2 health_check_response

Takes a health check C<$result> and returns a Plack response arrayref.

Returns a 200 response if the C<< $result->{status} >> is "OK" or if the result
is an array ref (for L</serve_tags_list>), otherwise returns a 503.

The body of the response is the C<$result> JSON encoded.

Also takes an optional L<Plack::Request> object as a second argument
which it will check for the existence of a C<pretty> query parameter
in which case it will make the JSON response both C<pretty> and C<canonical>.

=head1 DEPENDENCIES

L<Plack::Middleware>,
L<HealthCheck>

=head1 SEE ALSO

The GSG L<Health Check Standard|https://grantstreetgroup.github.io/HealthCheck.html>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 - 2024 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
