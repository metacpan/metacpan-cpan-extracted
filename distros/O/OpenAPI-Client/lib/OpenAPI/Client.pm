package OpenAPI::Client;
use Mojo::EventEmitter -base;

use Carp ();
use JSON::Validator;
use Mojo::UserAgent;
use Mojo::Promise;
use Scalar::Util qw(blessed);

use constant DEBUG => $ENV{OPENAPI_CLIENT_DEBUG} || 0;

our $VERSION = '1.06';

has base_url => sub {
  my $self      = shift;
  my $validator = $self->validator;
  my $url       = $validator->can('base_url') ? $validator->base_url->clone : Mojo::URL->new;
  $url->scheme('http')    unless $url->scheme;
  $url->host('localhost') unless $url->host;
  return $url;
};

has ua => sub { Mojo::UserAgent->new };

sub call {
  my ($self, $op) = (shift, shift);
  my $code = $self->can($op) or Carp::croak('[OpenAPI::Client] No such operationId');
  return $self->$code(@_);
}

sub call_p {
  my ($self, $op) = (shift, shift);
  my $code = $self->can("${op}_p") or return Mojo::Promise->reject('[OpenAPI::Client] No such operationId');
  return $self->$code(@_);
}

sub new {
  my ($parent, $specification) = (shift, shift);
  my $attrs = @_ == 1 ? shift : {@_};

  my $class = $parent->_url_to_class($specification);
  $parent->_generate_class($class, $specification, $attrs) unless $class->isa($parent);

  my $self = $class->SUPER::new($attrs);
  $self->base_url(Mojo::URL->new($self->{base_url})) if $self->{base_url} and !blessed $self->{base_url};
  $self->ua->transactor->name('Mojo-OpenAPI (Perl)') unless $self->{ua};

  if (my $app = delete $self->{app}) {
    $self->base_url->host(undef)->scheme(undef)->port(undef);
    $self->ua->server->app($app);
  }

  return $self;
}

sub validator { Carp::confess("validator() is not defined for $_[0]") }

sub _generate_class {
  my ($parent, $class, $specification, $attrs) = @_;

  my $jv = JSON::Validator->new;
  $jv->coerce($attrs->{coerce} // 'booleans,numbers,strings');
  $jv->store->ua->server->app($attrs->{app}) if $attrs->{app};

  my $schema = $jv->schema($specification)->schema;
  die "Invalid schema: $specification has the following errors:\n", join "\n", @{$schema->errors} if @{$schema->errors};

  eval <<"HERE" or Carp::confess("package $class: $@");
package $class;
use Mojo::Base '$parent';
1;
HERE

  Mojo::Util::monkey_patch($class => validator => sub {$schema});
  return unless $schema->can('routes');    # In case it is not an OpenAPI spec

  for my $route ($schema->routes->each) {
    next unless $route->{operation_id};
    warn "[$class] Add method $route->{operation_id}() for $route->{method} $route->{path}\n" if DEBUG;
    $class->_generate_method_bnb($route->{operation_id} => $route);
    $class->_generate_method_p("$route->{operation_id}_p" => $route);
  }
}

sub _generate_method_bnb {
  my ($class, $method_name, $route) = @_;

  Mojo::Util::monkey_patch $class => $method_name => sub {
    my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
    my $self = shift;
    my $tx   = $self->_build_tx($route, @_);

    if ($tx->error) {
      return $tx unless $cb;
      Mojo::IOLoop->next_tick(sub { $self->$cb($tx) });
      return $self;
    }

    return $self->ua->start($tx) unless $cb;
    $self->ua->start($tx, sub { $self->$cb($_[1]) });
    return $self;
  };
}

sub _generate_method_p {
  my ($class, $method_name, $route) = @_;

  Mojo::Util::monkey_patch $class => $method_name => sub {
    my $self = shift;
    my $tx   = $self->_build_tx($route, @_);

    return $self->ua->start_p($tx) unless my $err = $tx->error;
    return Mojo::Promise->new->reject($err->{message}) unless $err->{code};
    return Mojo::Promise->new->reject('WebSocket handshake failed') if $tx->req->is_handshake && !$tx->is_websocket;
    return Mojo::Promise->new->resolve($tx);
  };
}

sub _build_tx {
  my ($self, $route, $params, %content) = @_;
  my $v   = $self->validator;
  my $url = $self->base_url->clone;
  my ($tx, %headers);

  push @{$url->path}, map { local $_ = $_; s,\{([-\w]+)\},{$params->{$1}//''},ge; $_ } grep {length} split '/',
    $route->{path};

  my @errors = $self->validator->validate_request(
    [@$route{qw(method path)}],
    {
      body => sub {
        my ($name, $param) = @_;

        if (exists $params->{$name}) {
          $content{json} = $params->{$name};
        }
        else {
          for ('body', sort keys %{$self->ua->transactor->generators}) {
            next unless exists $content{$_};
            $params->{$name} = $content{$_};
            last;
          }
        }

        return {exists => $params->{$name}, value => $params->{$name}};
      },
      formData => sub {
        my ($name, $param) = @_;
        my $value = _param_as_array($name => $params);
        $content{form}{$name} = $params->{$name};
        return {exists => !!@$value, value => $value};
      },
      header => sub {
        my ($name, $param) = @_;
        my $value = _param_as_array($name => $params);
        $headers{$name} = $value;
        return {exists => !!@$value, value => $value};
      },
      path => sub {
        my ($name, $param) = @_;
        return {exists => exists $params->{$name}, value => $params->{$name}};
      },
      query => sub {
        my ($name, $param) = @_;
        my $value = _param_as_array($name => $params);
        $url->query->param($name => _coerce_collection_format($value, $param));
        return {exists => !!@$value, value => $value};
      },
    }
  );

  if (@errors) {
    warn "[@{[ref $self]}] Validation for $route->{method} $url failed: @errors\n" if DEBUG;
    $tx = Mojo::Transaction::HTTP->new;
    $tx->req->method(uc $route->{method});
    $tx->req->url($url);
    $tx->res->headers->content_type('application/json');
    $tx->res->body(Mojo::JSON::encode_json({errors => \@errors}));
    $tx->res->code(400)->message($tx->res->default_message);
    $tx->res->error({message => 'Invalid input', code => 400});
  }
  else {
    warn "[@{[ref $self]}] Validation for $route->{method} $url was successful\n" if DEBUG;
    $tx = $self->ua->build_tx($route->{method}, $url, \%headers, defined $content{body} ? $content{body} : %content);
  }

  $tx->req->env->{operationId} = $route->{operation_id};
  $self->emit(after_build_tx => $tx);

  return $tx;
}

sub _coerce_collection_format {
  my ($value, $param) = @_;
  my $format = $param->{collectionFormat} || (+($param->{type} // '') eq 'array' ? 'csv' : '');
  return $value if !$format or $format eq 'multi';
  return join "|",  @$value if $format eq 'pipes';
  return join " ",  @$value if $format eq 'ssv';
  return join "\t", @$value if $format eq 'tsv';
  return join ",",  @$value;
}

sub _param_as_array {
  my ($name, $params) = @_;
  return !exists $params->{$name} ? [] : ref $params->{$name} eq 'ARRAY' ? $params->{$name} : [$params->{$name}];
}

sub _url_to_class {
  my ($self, $package) = @_;

  $package =~ s!^\w+?://!!;
  $package =~ s!\W!_!g;
  $package = Mojo::Util::md5_sum($package) if length $package > 110;    # 110 is a bit random, but it cannot be too long

  return "$self\::$package";
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

The specification given to L</new> need to point to a valid OpenAPI document.
This document can be OpenAPI v2.x or v3.x, and it can be in either JSON or YAML
format. Example:

  openapi: 3.0.1
  info:
    title: Swagger Petstore
    version: 1.0.0
  servers:
  - url: http://petstore.swagger.io/v1
  paths:
    /pets:
      get:
        operationId: listPets
        ...

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

  # Promises
  $promise = $client->listPets_p->then(sub { my $tx = shift });

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

=head1 CUSTOMIZATION

=head2 Custom server URL

If you want to request a different server than what is specified in the Open
API document, you can change the L</base_url>:

  # Pass on a Mojo::URL object to the constructor
  $base_url = Mojo::URL->new("http://example.com");
  $client1 = OpenAPI::Client->new("file:///path/to/api.json", base_url => $base_url);

  # A plain string will be converted to a Mojo::URL object
  $client2 = OpenAPI::Client->new("file:///path/to/api.json", base_url => "http://example.com");

  # Change the base_url after the client has been created
  $client3 = OpenAPI::Client->new("file:///path/to/api.json");
  $client3->base_url->host("other.example.com");

=head2 Custom content

You can send XML or any format you like, but this require you to add a new
"generator":

  use Your::XML::Library "to_xml";
  $client->ua->transactor->add_generator(xml => sub {
    my ($t, $tx, $data) = @_;
    $tx->req->body(to_xml $data);
    return $tx;
  });

  $client->addHero({}, xml => {name => "Supergirl"});

See L<Mojo::UserAgent::Transactor> for more details.

=head1 EVENTS

=head2 after_build_tx

  $client->on(after_build_tx => sub { my ($client, $tx) = @_ })

This event is emitted after a L<Mojo::UserAgent::Transactor> object has been
built, just before it is passed on to the L</ua>. Note that all validation has
already been run, so alternating the C<$tx> too much, might cause an invalid
request on the server side.

A special L<Mojo::Message::Request/env> variable will be set, to reference the
operationId:

  $tx->req->env->{operationId};

Note that this usage of C<env()> is currently EXPERIMENTAL:

=head1 ATTRIBUTES

=head2 base_url

  $base_url = $client->base_url;

Returns a L<Mojo::URL> object with the base URL to the API. The default value
comes from C<schemes>, C<basePath> and C<host> in the OpenAPI v2 specification
or from C<servers> in the OpenAPI v3 specification.

=head2 ua

  $ua = $client->ua;

Returns a L<Mojo::UserAgent> object which is used to execute requests.

=head1 METHODS

=head2 call

  $tx = $client->call($operationId => \%params, %content);
  $client = $client->call($operationId => \%params, %content, sub { my ($client, $tx) = @_; });

Used to either call an C<$operationId> that has an "invalid name", such as
"list pets" instead of "listPets" or to call an C<$operationId> that you are
unsure is supported yet. If it is not, an exception will be thrown,
matching text "No such operationId".

C<$operationId> is the name of the resource defined in the
L<OpenAPI specification|https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#operation-object>.

C<$params> is optional, but must be a hash ref, where the keys should match a
named parameter in the L<OpenAPI specification|https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#parameter-object>.

C<%content> is used for the body of the request, where the key need to be
either "body" or a matching L<Mojo::UserAgent::Transactor/generators>. Example:

  $client->addHero({}, body => "Some data");
  $client->addHero({}, json => {name => "Supergirl"});

C<$tx> is a L<Mojo::Transaction> object.

=head2 call_p

  $promise = $client->call_p($operationId => $params, %content);
  $promise->then(sub { my $tx = shift });

As L</call> above, but returns a L<Mojo::Promise> object.

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

See L<JSON::Validator/coerce>. Default to "booleans,numbers,strings".

=back

=head2 validator

  $validator = $client->validator;
  $validator = $class->validator;

Returns a L<JSON::Validator::Schema::OpenAPIv2> object for a generated class.
Note that this is a global variable, so changing the object will affect all
instances returned by L</new>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2021, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHORS

=head2 Project Founder

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=head2 Contributors

=over 2


=item * Clive Holloway <clhollow@estee.com>

=item * Ed J <mohawk2@users.noreply.github.com>

=item * Jan Henning Thorsen <jan.henning@thorsen.pm>

=item * Jan Henning Thorsen <jhthorsen@cpan.org>

=item * Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item * Reneeb <info@perl-services.de>

=item * Roy Storey <kiwiroy@users.noreply.github.com>

=item * Veesh Goldman <rabbiveesh@gmail.com>

=back

=cut
