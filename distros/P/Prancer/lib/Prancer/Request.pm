package Prancer::Request;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

use Plack::Request;
use Hash::MultiValue;
use URI::Escape ();
use Carp;

use Prancer::Request::Upload;

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub new {
    my ($class, $env) = @_;
    my $self = bless({
        '_env' => $env,
        '_request' => Plack::Request->new($env),
    }, $class);

    # make instances of these and return those. these calls create new URI objects
    # with every invocation so this should avoid creating unnecessary objects later
    $self->{'_uri'} = $self->{'_request'}->uri();
    $self->{'_base'} = $self->{'_request'}->base();

    # other manipulation routines
    $self->{'_uploads'} = $self->_parse_uploads();
    $self->{'_cookies'} = $self->_parse_cookies();

    return $self;
}

sub _parse_uploads {
    my $self = shift;

    # turn all uploads into Prancer::Upload objects
    my $result = Hash::MultiValue->new();
    my $uploads = $self->{'_request'}->uploads();
    for my $key (keys %{$uploads}) {
        $result->add($key, map { Prancer::Request::Upload->new($_) } $uploads->get_all($key));
    }

    return $result;
}

sub _parse_cookies {
    my $self = shift;

    my $result = Hash::MultiValue->new();
    return $result unless defined($self->{'_env'}->{'HTTP_COOKIE'});

    # translate all cookies
    my @pairs = grep { m/=/x } split(/[;,]\s?/x, $self->{'_env'}->{'HTTP_COOKIE'});
    for my $pair (@pairs) {
        # trim leading and trailing whitespace
        $pair =~ s/^\s+|\s+$//xg;

        my ($key, $value) = map { URI::Escape::uri_unescape($_) } split(/=/x, $pair, 2);
        $result->add($key, $value);
    }

    return $result;
}

sub env {
    my $self = shift;
    return $self->{'_env'};
}

sub uri {
    my $self = shift;
    return $self->{'_uri'};
}

sub base {
    my $self = shift;
    return $self->{'_base'};
}

sub method {
    my $self = shift;
    return $self->{'_request'}->method();
}

sub protocol {
    my $self = shift;
    return $self->{'_request'}->protocol();
}

sub scheme {
    my $self = shift;
    return $self->{'_request'}->scheme();
}

sub port {
    my $self = shift;
    return $self->{'_request'}->port();
}

sub secure {
    my $self = shift;
    return ($self->{'_request'}->secure() ? 1 : 0);
}

sub path {
    my $self = shift;
    return $self->{'_request'}->path();
}

sub body {
    my $self = shift;
    return $self->{'_request'}->body();
}

sub content {
    my $self = shift;
    return $self->{'_request'}->raw_body();
}

sub address {
    my $self = shift;
    return $self->{'_request'}->address();
}

sub user {
    my $self = shift;
    return $self->{'_request'}->user();
}

sub headers {
    my $self = shift;
    return $self->{'_request'}->headers();
}

sub param {
    my $self = shift;

    # return the keys if nothing is asked for
    return keys %{$self->params()} unless @_;

    my $key = shift;
    return $self->params->get($key) unless wantarray;
    return $self->params->get_all($key);
}

sub params {
    my $self = shift;
    return $self->{'_request'}->parameters();
}

sub cookie {
    my $self = shift;

    # return the keys if nothing is asked for
    return keys %{$self->cookies()} unless @_;

    my $key = shift;
    return $self->cookies->get($key) unless wantarray;
    return $self->cookies->get_all($key);
}

sub cookies {
    my $self = shift;
    return $self->{'_cookies'};
}

sub upload {
    my $self = shift;

    # return the keys if nothing is asked for
    return keys %{$self->uploads()} unless @_;

    my $key = shift;
    return $self->uploads->get($key) unless wantarray;
    return $self->uploads->get_all($key);
}

sub uploads {
    my $self = shift;
    return $self->{'_uploads'};
}

sub uri_for {
    my ($self, $path, $args) = @_;
    my $uri = URI->new($self->base());

    # don't want multiple slashes clouding things up
    if ($uri->path() =~ /\/$/x && $path =~ /^\//x) {
        $path = substr($path, 1);
    }

    $uri->path($uri->path() . $path);
    $uri->query_form(@{$args}) if $args;
    return $uri;
}

1;

=head1 NAME

Prancer::Request

=head1 SYNOPSIS

    sub handler {
        my ($self, $env, $request, $response, $session) = @_;

        sub (GET) {
            my $path         = $request->path();
            my $cookie       = $request->cookie("foo");
            my $param        = $request->param("bar");
            my $cookie_names = $request->cookie();
            my $user_agent   = $request->headers->header("user-agent");

            ...

            return $response->finalize(200);
        }
    }

=head1 METHODS

=over

=item uri

Returns an URI object for the current request. The URI is constructed using
various environment values such as C<SCRIPT_NAME>, C<PATH_INFO>,
C<QUERY_STRING>, C<HTTP_HOST>, C<SERVER_NAME> and C<SERVER_PORT>.

=item base

Returns a URI object for the base path of current request. This is like C<uri>
but only contains up to C<SCRIPT_NAME> where your application is hosted at.

=item method

Contains the request method (C<GET>, C<POST>, C<HEAD>, etc).

=item protocol

Returns the protocol (C<HTTP/1.0> or C<HTTP/1.1>) used for the current request.

=item scheme

Returns the scheme (C<http> or C<https>) of the request.

=item secure

Returns true or false, indicating whether the connection is secure (C<https>).

=item path

Returns B<PATH_INFO> in the environment but returns / in case it is empty.

=item body

Returns a handle to the input stream.

=item address

Returns the IP address of the client (C<REMOTE_ADDR>).

=item user

Returns C<REMOTE_USER> if it's set.

=item headers

Returns an L<HTTP::Headers::Fast> object containing the headers for the current
request.

=item param

When called with no arguments this will return a list of all parameter names.
When called in scalar context this will return the last value for the given
key. When called in list context this will return all values for the given key
in a list.

=item params

Returns a L<Hash::MultiValue> hash reference containing the merged GET and POST
parameters.

=item cookie

When called with no arguments this will return a list of all cookie names.
When called in scalar context this will return the last cookie for the given
key. When called in list context this will return all cookies for the given
key in a list.

=item cookies

Returns an L<Hash::MultiValue> containing all cookies.

=item upload

When called with no arguments this will return a list of all upload names.
When called in scalar context this will return the last
L<Prancer::Request::Upload> object for the given key. When called in list
context this will return all L<Prancer::Request::Upload> objects for the given
key.

=item uploads

Returns an L<Hash::MultiValue> containing all uploads.

=item uri_for

Generates a URL to a new location in an easy to use manner. For example:

    my $link = $request->uri_for("/logout", [ signoff => 1 ]);

=back

=cut
