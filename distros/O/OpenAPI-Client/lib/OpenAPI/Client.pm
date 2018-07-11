package OpenAPI::Client;
use Mojo::Base -base;

use Carp ();
use JSON::Validator::OpenAPI::Mojolicious;
use Mojo::UserAgent;
use Mojo::Util;
use Mojo::Promise;

use constant DEBUG => $ENV{OPENAPI_CLIENT_DEBUG} || 0;

our $VERSION = '0.16';

my $BASE = __PACKAGE__;
my $X_RE = qr{^x-};

has base_url => sub {
  my $self    = shift;
  my $schema  = $self->validator->schema;
  my $schemes = $schema->get('/schemes') || [];

  return Mojo::URL->new->host_port($schema->get('/host') || 'localhost')->path($schema->get('/basePath') || '/')
    ->scheme($schemes->[0] || 'http');
};

has pre_processor => sub {
  return sub {
    my ($headers, $req) = @_;
    return $headers, json => delete $req->{body} if ref $req->{body};
    return $headers, form => $req->{form}        if defined $req->{form};
    return $headers, $req->{body} if defined $req->{body};
    return $headers;
  };
};

has ua => sub { Mojo::UserAgent->new };

sub call {
  my ($self, $op) = (shift, shift);
  my $code = $self->can($op);
  return $self->$code(@_) if $code;
  Carp::croak('[OpenAPI::Client] No such operationId');
}

sub call_p {
  my $self    = shift;
  my $promise = Mojo::Promise->new;
  $self->call(
    @_,
    sub {
      my ($self, $tx) = @_;
      my $err = $tx->error;
      return $promise->reject($err->{message}) if $err && !$err->{code};
      return $promise->reject('WebSocket handshake failed') if $tx->req->is_handshake && !$tx->is_websocket;
      $promise->resolve($tx);
    }
  );
  $promise;
}

sub new {
  my ($class, $specification) = (shift, shift);
  my $attrs = @_ == 1 ? shift : {@_};
  my $validator = JSON::Validator::OpenAPI::Mojolicious->new;

  $validator->coerce($attrs->{coerce} // 1);
  $validator->ua->server->app($attrs->{app}) if $attrs->{app};
  $class = $class->_url_to_class($specification);
  _generate_class($class, $validator->load_and_validate_schema($specification, $attrs)) unless $class->isa($BASE);

  my $self = bless $attrs, $class;
  $self->ua->transactor->name('Mojo-OpenAPI (Perl)') unless $self->{ua};

  if (my $app = delete $self->{app}) {
    $self->base_url->host(undef)->scheme(undef)->port(undef);
    $self->ua->server->app($app);
  }

  return $self;
}

sub validator { Carp::confess('No JSON::Validator::OpenAPI::Mojolicious object available') }

sub _generate_class {
  my ($class, $validator) = @_;
  my $paths = $validator->get('/paths') || {};

  eval <<"HERE" or Carp::confess("package $class: $@");
package $class;
use Mojo::Base '$BASE';
1;
HERE

  Mojo::Util::monkey_patch($class => validator => sub {$validator});

  for my $path (keys %$paths) {
    next if $path =~ $X_RE;
    my $path_parameters = $validator->get([paths => $path => 'parameters']) || [];

    for my $http_method (keys %{$validator->get([paths => $path])}) {
      next if $http_method =~ $X_RE or $http_method eq 'parameters';
      my $op_spec = $validator->get([paths => $path => $http_method]);
      my $method = $op_spec->{operationId} or next;
      my @rules = (@$path_parameters, @{$op_spec->{parameters} || []});
      my $code = _generate_method(lc $http_method, $path, \@rules);
      warn "[$class] Add method $method() for $http_method $path\n" if DEBUG;
      Mojo::Util::monkey_patch($class => $method => $code);
    }
  }
}

sub _generate_method {
  my ($http_method, $path, $rules) = @_;
  my @path_spec = grep {length} split '/', $path;

  return sub {
    my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
    my $self = shift;
    my $tx   = $self->_generate_tx($http_method, \@path_spec, $rules, @_);

    if ($tx->error) {
      return $tx unless $cb;
      Mojo::IOLoop->next_tick(sub { $self->$cb($tx) });
      return $self;
    }

    return $self->ua->start($tx) unless $cb;
    return $self->tap(
      sub {
        $self->ua->start($tx, sub { $self->$cb($_[1]) });
      }
    );
  };
}

sub _generate_tx {
  my ($self, $http_method, $path_spec, $rules, $params, %args) = @_;
  my $v   = $self->validator;
  my $url = $self->base_url->clone;
  my (%headers, %req, @errors);

  push @{$url->path}, map { local $_ = $_; s,\{(\w+)\},{$params->{$1}//''},ge; $_ } @$path_spec;

  for my $p (@$rules) {
    my ($in, $name, $type) = @$p{qw(in name type)};
    my @e;

    if ($in eq 'body' and exists $args{body}) {
      $params->{$name} = $args{body};
    }

    if (exists $params->{$name} or $p->{required}) {
      @e = $v->validate($params,
        {type => 'object', required => $p->{required} ? [$name] : [], properties => {$name => $p->{schema} || $p}});
    }

    if (@e) {
      warn "[@{[ref $self]}] Validation for $url failed: @e\n" if DEBUG;
      push @errors, @e;
    }
    elsif (!exists $params->{$name} or $in eq 'path') {
      1;
    }
    elsif ($in eq 'query') {
      $url->query->param($name => $params->{$name}) if $in eq 'query';
    }
    elsif ($in eq 'header') {
      $headers{$name} = $params->{$name};
    }
    elsif ($in eq 'formData') {
      $req{form}{$name} = $params->{$name};
    }
    elsif ($in eq 'body') {
      $req{body} = $params->{$name};
    }
    else {
      warn "[@{[ref $self]}] Unknown 'in' '$in' for parameter '$name'";
    }
  }

  # Valid input
  unless (@errors) {
    warn "[@{[ref $self]}] Validation for $url was successful.\n" if DEBUG;
    return $self->ua->build_tx($http_method, $url, $self->pre_processor->(\%headers, \%req));
  }

  my $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url($url || Mojo::URL->new);
  $tx->res->headers->content_type('application/json');
  $tx->res->body(Mojo::JSON::encode_json({errors => \@errors}));
  $tx->res->code(400)->message($tx->res->default_message);
  $tx->res->error({message => 'Invalid input', code => 400});
  return $tx;
}

sub _url_to_class {
  my ($self, $package) = @_;

  $package =~ s!^\w+?://!!;
  $package =~ s!\W!_!g;
  $package = Mojo::Util::md5_sum($package) if length $package > 110;    # 110 is a bit random, but it cannot be too long

  return sprintf '%s::%s', __PACKAGE__, $package;
}

1;

=encoding utf8

=head1 NAME

OpenAPI::Client - A client for talking to an Open API powered server

=head1 DESCRIPTION

L<OpenAPI::Client> can generating classes that can talk to an Open API server.
This is done by generating a custom class, based on a Open API specification,
with methods that transform parameters into a HTTP request.

The generated class will perform input validation, so invalid data won't be
sent to the server.

Note that this implementation is currently EXPERIMENTAL, but unlikely to change!
Feedback is appreciated.

=head1 SYNOPSIS

=head2 Open API specification

The specification given to L</new> need to point to a valid OpenAPI document,
in either JSON or YAML format. Example:

  ---
  swagger: 2.0
  host: api.example.com
  basePath: /api
  schemes: [ "http" ]
  paths:
    /foo:
      get:
        operationId: listPets
        parameters:
        - name: limit
          in: query
          type: integer
        responses:
          200: { ... }

C<host>, C<basePath> and the first item in C<schemes> will be used to construct
L</base_url>. This can be altered at any time, if you need to send data to a
custom endpoint.

=head2 Client

The OpenAPI API specification will be used to generate a sub-class of
L<OpenAPI::Client> where the "operationId", inside of each path definition, is
used to generate methods:

  use OpenAPI::Client;
  $client = OpenAPI::Client->new("file:///path/to/api.json");

  # Blocking
  $tx = $client->listPets;

  # Non-blocking
  $client = $client->listPets(sub { my ($client, $tx) = @_; });

  # With parameters
  $tx = $client->listPets({limit => 10});

See L<Mojo::Transaction> for more information about what you can do with the
C<$tx> object, but you often just want something like this:

  # Check for errors
  die $tx->error->{message} if $tx->error;

  # Extract data from the JSON responses
  say $tx->res->json->{pets}[0]{name};

Check out L<Mojo::Transaction/error>, L<Mojo::Transaction/req> and
L<Mojo::Transaction/res> for some of the most used methods in that class.

=head2 Customization

If you want to request a different server than what is specified in
the Open API document:

  $client->base_url->host("other.server.com");

=head1 ATTRIBUTES

=head2 base_url

  $base_url = $self->base_url;

Returns a L<Mojo::URL> object with the base URL to the API. The default value
comes from C<schemes>, C<basePath> and C<host> in the Open API specification.

=head2 pre_processor

  $code = $self->pre_processor;
  $self = $self->pre_processor(sub { my ($headers, $req) = @_; ... });

Holds a code ref that can pre-process the request. The return values are passed
on to L<Mojo::UserAgent/build_tx>. Example:

  $self->pre_processor(sub {
    my ($headers, $req) = @_;
    return $headers, json => {whatever => 42};
  });

The code above will result in this:

  $self->ua->build_tx($http_method, $url, $headers, json => {whatever => 42});
                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

C<$headers> is a hash-ref containing the request headers and C<$req> is a
hash-ref that can contain either the key "body" or "form". Note that additional
parameters might be added to C<$req>, though it is unlikely.

=head2 ua

  $ua = $self->ua;

Returns a L<Mojo::UserAgent> object which is used to execute requests.

=head1 METHODS

=head2 call

  $tx = $self->call($operationId => @args);
  $self = $self->call($operationId => @args, sub { my ($self, $tx) = @_; });

Used to either call an C<$operationId> that has an "invalid name", such as
"list pets" instead of "listPets" or to call an C<$operationId> that you are
unsure is supported yet. If it is not, an exception will be thrown,
matching text "No such operationId".

C<$operationId> is the name of the resource defined in the
L<OpenAPI specification|https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#operation-object>.

The first element in C<@args> can be a hash ref, where a key should match a
named parameter in the L<OpenAPI specification|https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#parameter-object>.

C<$tx> is a L<Mojo::Transaction> object.

=head2 call_p

  $promise = $self->call_p($operationId => @args);
  $promise->then(sub { my ($self, $tx) = @_; });

As L</call> above, but instead of returning a C<$tx>, returns a
L<Mojo::Promise> of that C<$tx>. Obviously, you should not give a callback.

=head2 new

  $client = OpenAPI::Client->new($specification, \%attributes);
  $client = OpenAPI::Client->new($specification, %attributes);

Returns an object of a generated class, with methods generated from the Open
API specification located at C<$specification>. See L<JSON::Validator/schema>
for valid versions of C<$specification>.

Note that the class is cached by perl, so loading a new specification from the
same URL will not generate a new class.

Extra C<%attributes>:

=over 2

=item * app

Specifying an C<app> is useful when running against a local L<Mojolicious>
instance.

=item * coerce

See L<JSON::Validator/coerce>. Default to 1.

=back

=head2 validator

  $validator = $self->validator;
  $validator = $class->validator;

Returns a L<JSON::Validator::OpenAPI::Mojolicious> object for a generated
class. Not that this is a global variable, so changing the object will affect
all instances.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHORS

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Ed J - C<etj@cpan.org>

=cut
