package Plack::Client;
BEGIN {
  $Plack::Client::VERSION = '0.06';
}
use strict;
use warnings;
# ABSTRACT: abstract interface to remote web servers and local PSGI apps

use Carp;
use Class::Load;
use HTTP::Message::PSGI;
use HTTP::Request;
use Plack::Request;
use Plack::Response;
use Scalar::Util qw(blessed reftype);



sub new {
    my $class = shift;
    my %params = @_;

    my %backends;
    for my $scheme (keys %params) {
        my $backend = $params{$scheme};
        if (blessed($backend) && $backend->isa('Plack::Client::Backend')) {
            $backends{$scheme} = $backend->as_code;
        }
        elsif (reftype($backend) eq 'CODE') {
            $backends{$scheme} = $backend;
        }
        elsif (ref($backend)) {
            (my $normal_scheme = $scheme) =~ s/-/_/g;
            my $backend_class = "Plack::Client::Backend::$normal_scheme";
            Class::Load::load_class($backend_class);
            croak "Backend classes must inherit from Plack::Client::Backend"
                unless $backend_class->isa('Plack::Client::Backend');
            $backends{$scheme} = $backend_class->new(
                reftype($backend) eq 'HASH'  ? %$backend
              : reftype($backend) eq 'ARRAY' ? @$backend
              :                                $$backend
            )->as_code;
        }
        else {
            croak "Backends must be a coderef or a Plack::Client::Backend instance";
        }
    }

    bless {
        backends => \%backends,
    }, $class;
}


sub backend {
    my $self = shift;
    my ($scheme) = @_;
    $scheme = $scheme->scheme if blessed($scheme);
    my $backend = $self->_backend($scheme);
    return $backend if defined $backend;
    $scheme = 'http' if $scheme eq 'https';
    $scheme =~ s/-ssl$//;
    return $self->_backend($scheme);
}

sub _backend {
    my $self = shift;
    my ($scheme) = @_;
    return $self->{backends}->{$scheme};
}


sub request {
    my $self = shift;

    my ($app, $env) = $self->_parse_request_args(@_);

    my $psgi_res = $self->_resolve_response($app->($env));
    # is there a better place to do this? Plack::App::Proxy already takes care
    # of this (since it's making a real http request)
    $psgi_res->[2] = [] if $env->{REQUEST_METHOD} eq 'HEAD';

    # XXX: or just return the arrayref?
    return Plack::Response->new(@$psgi_res);
}

sub _parse_request_args {
    my $self = shift;

    if (blessed($_[0])) {
        if ($_[0]->isa('HTTP::Request')) {
            return $self->_request_from_http_request(@_);
        }
        elsif ($_[0]->isa('Plack::Request')) {
            return $self->_request_from_plack_request(@_);
        }
        else {
            croak 'Request object must be either an HTTP::Request or a Plack::Request';
        }
    }
    elsif ((reftype($_[0]) || '') eq 'HASH') {
        return $self->_request_from_env(@_);
    }
    else {
        return $self->_request_from_http_request_args(@_);
    }
}

sub _request_from_http_request {
    my $self = shift;
    my ($http_request) = @_;
    my $env = $self->_http_request_to_env($http_request);
    return $self->_request_from_env($env);
}

sub _request_from_plack_request {
    my $self = shift;
    my ($req) = @_;

    return ($self->_app_from_request($req), $req->env);
}

sub _request_from_env {
    my $self = shift;
    return $self->_request_from_plack_request(Plack::Request->new(@_));
}

sub _request_from_http_request_args {
    my $self = shift;
    return $self->_request_from_http_request(HTTP::Request->new(@_));
}

sub _http_request_to_env {
    my $self = shift;
    my ($req) = @_;

    my $scheme       = $req->uri->scheme;
    my $original_uri = $req->uri->clone;

    # hack around with this - psgi requires a host and port to exist, and
    # for the scheme to be either http or https
    if ($scheme ne 'http' && $scheme ne 'https') {
        if ($scheme =~ /-ssl$/) {
            $req->uri->scheme('https');
        }
        else {
            $req->uri->scheme('http');
        }
        $req->uri->host('Plack::Client');
        $req->uri->port(-1);
    }

    my $env = $req->to_psgi;

    $env->{'plack.client.original_uri'} = $original_uri;

    return $env;
}

sub _app_from_request {
    my $self = shift;
    my ($req) = @_;

    my $uri = $req->env->{'plack.client.original_uri'} || $req->uri;

    my $backend = $self->backend($uri);
    my $app = $backend->($req);

    croak "Couldn't find app" unless $app;

    return $app;
}

sub _resolve_response {
    my $self = shift;
    my ($psgi_res) = @_;

    if (ref($psgi_res) eq 'CODE') {
        my $body = [];
        $psgi_res->(sub {
            $psgi_res = shift;
            return Plack::Util::inline_object(
                write => sub { push @$body, $_[0] },
                close => sub { push @$psgi_res, $body },
            );
        });
    }

    if (ref($psgi_res) ne 'ARRAY') {
        require Data::Dumper;
        croak "Unable to understand app response:\n"
            . Data::Dumper::Dumper($psgi_res);
    }

    return $psgi_res;
}


sub get    { shift->request('GET',    @_) }
sub head   { shift->request('HEAD',   @_) }
sub post   { shift->request('POST',   @_) }
sub put    { shift->request('PUT',    @_) }
sub delete { shift->request('DELETE', @_) }


1;

__END__
=pod

=head1 NAME

Plack::Client - abstract interface to remote web servers and local PSGI apps

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Plack::Client;
  my $client = Plack::Client->new(
      'psgi-local' => { myapp => sub { ... } },
      'http'       => {},
  );
  my $res1 = $client->get('http://google.com/');
  my $res2 = $client->post(
      'psgi-local://myapp/foo.html',
      ['Content-Type' => 'text/plain'],
      "foo"
  );

=head1 DESCRIPTION

A common task required in more complicated web applications is communicating
with various web services for different tasks. These web services may be spread
among a number of different servers, but some of them may be on the local
server, and for those, there's no reason to require accessing them through the
network; assuming the app is written using Plack, the app coderef for the
service already exists in the current process, so a lot of time could be saved
by just calling it directly.

The key issue here then becomes providing an interface that allows accessing
both local and remote services through a common api, so that services can be
moved between servers with only a small change in configuration, rather than
having to change the actual code involved in accessing it. This module solves
this issue by providing an API similar to L<LWP::UserAgent>, but using an
underlying implementation consisting entirely of Plack apps. The app to use for
a given request is determined based on the URL schema; for instance,
C<< $client->get('http://example.com/foo') >> would call a L<Plack::App::Proxy>
app to retrieve a remote resource, while
C<< $client->get('psgi-local://myapp/foo') >> would directly call the C<myapp>
app coderef that was passed into the constructor for the
L<psgi-local|Plack::Client::Backend::psgi_local> backend. This API allows a
simple config file change to be all that's necessary to migrate your service to
a different server. The list of available URL schemas is determined by the
arguments passed to the constructor, which map schemas to backends which return
appropriate apps based on the request.

=head1 METHODS

=head2 new

  my $client = Plack::Client->new(
      'psgi-local => {
          apps => {
              foo => sub { ... },
              bar => MyApp->new->to_app,
          }
      },
      'http' => Plack::Client::Backend::http->new,
  )

Constructor. Takes a hash of arguments, where keys are URL schemas, and values
are backends which handle those schemas. Backends are really just coderefs
which receive a L<Plack::Request> and return a PSGI application coderef, but
see L<Plack::Client::Backend> for a more structured way to define these.
Hashref and arrayref values are also valid, and will be dereferenced and passed
to the constructor of the default backend for that scheme (the class
C<Plack::Client::Backend::$scheme>, where C<$scheme> has dashes replaced by
underscores).

=head2 backend

  $client->backend('http');
  $client->backend($req->uri);

Returns the backend object used to generate apps for the given URL scheme or
URI object. By default, the SSL variant of a scheme will be handled by the same
backend as the non-SSL variant, although this can be overridden by explicitly
specifying a backend for the SSL variant. SSL variants are indicated by
appending C<-ssl> to the scheme (or by being equal to C<https>).

=head2 request

  $client->request(
      'POST',
      'http://example.com/',
      ['Content-Type' => 'text/plain'],
      "content",
  );
  $client->request(HTTP::Request->new(...));
  $client->request($env);
  $client->request(Plack::Request->new(...));

This method performs most of the work for this module. It takes a request in
any of several forms, makes the request, and returns the response as a
L<Plack::Response> object. The request can be in the form of an
L<HTTP::Request> or L<Plack::Request> object directly, or it can take arguments
to pass to the constructor of either of those two modules (so see those two
modules for a description of exactly what is valid).

=head2 get

=head2 head

=head2 post

=head2 put

=head2 delete

  $client->get('http://example.com/foo');
  $client->head('psgi-local://bar/admin');
  $client->post('https://example.com/submit', [], "my submission");
  $client->put('psgi-local-ssl://foo/new-item', [], "something new");
  $client->delete('http://example.com/item/2');

These methods are just shorthand for C<request>. They only allow the "URL,
headers, body" API; for anything more complicated, C<request> should be used
directly.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-plack-client at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Client>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Plack>

=item *

L<HTTP::Request>

=back

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Plack::Client

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Client>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Client>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

