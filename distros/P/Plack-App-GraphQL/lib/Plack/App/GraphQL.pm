package Plack::App::GraphQL;

use Plack::Util;
use Plack::Request;
use GraphQL::Execution;
use Safe::Isa;
use Moo;

extends 'Plack::Component';

our $VERSION = '0.002';

has convert => (
  is => 'ro',
  isa => sub { ref($_[0]) ? 1:0 },
  predicate => 'has_convert',
  coerce => sub {
    if(ref($_[0]) eq 'ARRAY') {
      my ($class_proto, @args) = @{$_[0]};
      return normalize_convert_class($class_proto)->to_graphql(@args);
    } else {
      return $_[0]; # assume its a hashref already.
    }
  },
);

  sub normalize_convert_class {
    my $class_proto = shift;
    my $class = $class_proto =~m/^\+(.+)$/ ?
      $1 : "GraphQL::Plugin::Convert::$class_proto";
    return Plack::Util::load_class($class);
  }

has schema => (
  is => 'ro',
  lazy => 1,
  required => 1,
  builder => '_build_schema',
  coerce => sub {
    my $schema_proto = shift;
    return (  ref($schema_proto) =~m/GraphQL::Schema/) ?
      $schema_proto :
      coerce_schema($schema_proto);
  }
);

  sub coerce_schema {
    my $source = Plack::Util::is_real_fh($_[0]) ?
      do { local $/ = undef; <$_[0]> } : 
        $_[0];
    return Plack::Util::load_class("GraphQL::Schema")
      ->from_doc($source);
  }

  sub _build_schema {
    my $self = shift;
    return $self->has_convert ? 
      $self->convert->{schema} :
      undef;
  }

has root_value => (
  is => 'ro',
  required => 1,
  lazy => 1,
  builder => '_build_root_value',
);

  sub _build_root_value {
    my $self = shift;
    return $self->has_convert ? 
      $self->convert->{root_value} :
      undef;
  }

has resolver => (
  is => 'ro',
  required => 0,
  lazy => 1,
  builder => '_build_resolver',
);

  sub _build_resolver {
    my $self = shift;
    return $self->has_convert ? 
      $self->convert->{resolver} :
      undef;
  }

has promise_code => (
  is => 'ro',
  required => 0,
  lazy => 1,
); # TODO waiting on GraphQL

has endpoint => (
  is => 'ro',
  required => 1,
  builder => 'DEFAULT_ENDPOINT',
);

  sub DEFAULT_ENDPOINT { our $DEFAULT_ENDPOINT ||= '/' }

has context_class => (
  is => 'ro',
  required => 1,
  builder => 'DEFAULT_CONTEXT_CLASS',
  coerce => sub { Plack::Util::load_class($_[0]) },
);

  sub DEFAULT_CONTEXT_CLASS { our $DEFAULT_CONTEXT_CLASS ||= 'Plack::App::GraphQL::Context' }

has ui_template_class => (
  is => 'ro',
  required => 1,
  init_arg => undef,
  builder => 'DEFAULT_UI_TEMPLATE_CLASS',
  coerce => sub { Plack::Util::load_class(shift) },
);

  sub DEFAULT_UI_TEMPLATE_CLASS { our $DEFAULT_UI_TEMPLATE_CLASS ||= 'Plack::App::GraphQL::UITemplate' }

has ui_template => (
  is => 'ro',
  required => 1,
  init_arg => undef,
  builder => '_build_ui_template',
  lazy => 1,
);

  sub _build_ui_template {
    my $self = shift;
    $self->ui_template_class->new(json_encoder => $self->json_encoder);
  }

has graphiql => (
  is => 'ro',
  required => 1,
  builder => 'DEFAULT_GRAPHIQL',
);

  sub DEFAULT_GRAPHIQL { our $DEFAULT_GRAPHIQL ||= 0 }

has json_encoder => (
  is => 'ro',
  required => 1,
  handles => {
    json_encode => 'encode',
    json_decode => 'decode',
  },
  builder => '_build_json_encoder',
);

  our $DEFAULT_JSON_CLASS = 'JSON::MaybeXS';
  sub _build_json_encoder {
    return our $JSON_ENCODER ||= Plack::Util::load_class($DEFAULT_JSON_CLASS)
      ->new
      ->utf8
      ->allow_nonref;
  }

has exceptions_class => (
  is => 'ro',
  required => 1,
  builder => 'DEFAULT_EXCEPTIONS_CLASS',
  coerce => sub { Plack::Util::load_class(shift) },
);

  our $DEFAULT_EXCEPTIONS_CLASS = 'Plack::App::GraphQL::Exceptions';
  sub DEFAULT_EXCEPTIONS_CLASS { $DEFAULT_EXCEPTIONS_CLASS }

has exceptions => (
  is => 'ro',
  required => 1,
  init_arg => undef,
  lazy => 1,
  handles => [qw(respond_415 respond_404 respond_400)],
  builder => '_build_exceptions',
);

  sub _build_exceptions {
    my $self = shift;
    return $self->exceptions_class->new(psgi_app=>$self);
  } 

sub call {
  my ($self, $env) = @_;
  my $req = Plack::Request->new($env);
  return $self->respond($req) if $self->matches_endpoint($req);
  return $self->respond_404($req);
}

sub matches_endpoint {
  my ($self, $req) = @_;
  return $req->env->{PATH_INFO} eq $self->endpoint ? 1:0;
}

sub respond {
  my ($self, $req) = @_;
  return sub { $self->respond_graphiql($req, @_) } if $self->accepts_graphiql($req);
  return sub { $self->respond_graphql($req, @_) } if $self->accepts_graphql($req);
  return $self->respond_415($req);
}

sub accepts_graphiql {
  my ($self, $req) = @_;
  return 1  if $self->graphiql
            and (($req->env->{HTTP_ACCEPT}||'') =~ /^text\/html\b/)
            and (!defined($req->body_parameters->{'raw'}));
  return 0;
}

sub accepts_graphql {
  my ($self, $req) = @_;
  return (($req->env->{HTTP_ACCEPT}||'') =~ /^application\/json\b/) ? 1:0;
}

sub respond_graphiql {
  my ($self, $req, $responder) = @_;
  my $body = $self->ui_template->process($req);
  return $responder->(
    [
      200,
      [
        'Content-Type'   => 'text/html',
        'Content-Length' => Plack::Util::content_length([$body]),
      ],
      [$body],
    ]
  );
}

sub respond_graphql {
  my ($self, $req, $responder) = @_;
  my ($results, $context) = $self->prepare_results($req);
  my $writer = $self->prepare_writer($context, $responder);

  # This is ugly; its just a placeholder until GraphQL allows Futures.
  if(ref($results)=~m/Future/) {
    $results->on_done(sub {
      return $self->write_results($context, shift, $writer);
    }); # needs on_fail...
  } else {
    return $self->write_results($context, $results, $writer)
  }
}

sub prepare_writer {
  my ($self, $context, $responder) = @_;
  my @headers = $self->prepare_headers($context);
  return my $writer = $responder->([200, \@headers]);
}

sub prepare_headers {
  my ($self, $context) = @_;
  return my @headers = ('Content-Type' => 'application/json');
}

sub write_results {
  my ($self, $context, $results, $writer) = @_;
  my $body = $self->json_encode($results);
  $writer->write($body);
  $writer->close;
}

sub prepare_results {
  my ($self, $req) = @_;
  my $data = $self->prepare_body($req);
  my $context = $self->prepare_context($req, $data);
  my $root_value = $self->prepare_root_value($context);
  my $results = $self->execute(
    $self->schema,
    $data,
    $root_value,
    $context,
    $self->resolver,
    $self->promise_code,
  );
  return ($results, $context);
}

sub prepare_body {
  my ($self, $req) = @_;
  my $json_body = eval {
    $self->json_decode($req->raw_body());
  } || do {
    $self->respond_400($req);
  };
  return $json_body;
}

sub prepare_context {
  my ($self, $req) = @_;
  return my $context = $req->env->{'plack.graphql.context'} ||= $self->build_context($req);
}

sub build_context {
  my ($self, $req, $data) = @_;
  my $context_class = $self->context_class;
  return $context_class->new(
    request => $req, 
    data => $data,
    app => $self,
    log => $req->env->{'psgix.logger'},
  );
}

sub prepare_root_value {
  my ($self, $context) = @_;
  return my $root_value = $context->req->env->{'plack.graphql.root_value'} ||= $self->root_value;
}

sub execute {
  my ($self, $schema, $data, $root_value, $context, $resolver, $promise_code) = @_;
  return my $results = GraphQL::Execution::execute(
    $schema,
    $data->{query},
    $root_value,
    $context,
    $data->{variables},
    $data->{operationName},
    $resolver,
    $promise_code,
  );
}

1;

=head1 NAME
 
Plack::App::GraphQL - Serve GraphQL from Plack / PSGI

=begin markdown


https://travis-ci.org/jjn1056/Plack-App-GraphQL

# PROJECT STATUS

[![Build Status](https://travis-ci.org/jjn1056/Plack-App-GraphQL.svg?branch=master)](https://travis-ci.org/jjn1056/Plack-App-GraphQL)
[![CPAN version](https://badge.fury.io/pl/Plack-App-GraphQL.svg)](https://metacpan.org/pod/Plack-App-GraphQL) 

=end markdown
 
=head1 SYNOPSIS
 
    use Plack::App::GraphQL;

    my $schema = q|
      type Query {
        hello: String
      }
    |;

    my %root_value = (
      hello => 'Hello World!',
    );

    my $app = Plack::App::GraphQL
      ->new(schema => $schema, root_value => \%root_value)
      ->to_app;

Or mount under a given URL:

    use Plack::Builder;
    use Plack::App::GraphQL;

    # $schema and %root_value as above

    my $app = Plack::App::GraphQL
      ->new(schema => $schema, root_value => \%root_value)
      ->to_app;

    builder {
      mount "/graphql" => $app;
    };

You can also use the 'endpoint' configuration option to set a root path to match.
This is the most simple option if you application is not serving other endpoints
or applications (See documentation below).

=head1 DESCRIPTION
 
Serve L<GraphQL> with L<Plack>.

Please note this is an early access / minimal documentation release.  You should already
be familiar with L<GraphQL>.  There's some examples in C</examples> but few real test
cases.  If you are not comfortable using this based on reading the source code and
can't accept the possibility that the underlying code might change (although I expect
the configuration options are pretty set now) then you shouldn't use this. I recommend
looking at official plugins for Dancer and Mojolicious: L<Dancer2::Plugin::GraphQL>,
L<Mojolicious::Plugin::GraphQL> instead (or you can send me patches :) ).

This currently doesn't support an asychronous responses until updates are made in 
core L<GraphQL>.

=head1 CONFIGURATION
 
This L<Plack> applications supports the following configuration arguments:

=head2 schema

The L<GraphQL::Schema>.  Canonically this should be an instance of L<GraphQL::Schema>
but if you pass a string or a filehandle, we will assume that it is a parse-able 
graphql SDL document that we can build a schema object from.  Makes for easy demos.

=head2 root_value

An object, hashref or coderef that field resolvers can use to look up requests.  Generally
the method or hash keys will match the query or mutation keys.  See the examples for
more.

You can override this at runtime (with for example a bit of middleware) by using the
'plack.graphql.root_value' key in the PSGI $env.  This may or my not be considered a
good practice :)  Some examples suggest always using the $context for stuff like this
while other examples seem to think its a good idea.  I choose to rather enable this
ability and let you decide what is right for your application.

=head2 resolver

Used to change how field resolvers work.  See L<GraphQL> (or ignore this since its likely
something you really don't need for normal work.

=head2 convert

This takes a sub class of L<GraphQL::Plugin::Convert>, such as L<GraphQL::Plugin::Convert::DBIC>.
Providing this will automatically provide L</schema>, L</root_value> and L</resolver>.

You can shortcut the value of this with a '+' and we will assume the default namespace.  For
example '+DBIC' is the same as 'GraphQL::Plugin::Convert::DBIC'.

=head2 endpoint

The URI path part that is associated with the graphql API endpoint.  Often this is set to
'graphql'.  The default is '/'.  You might prefer to use a custom or alternative router
(for example L<Plack::Builder>).

=head2 context_class

Default is L<Plack::App::GraphQL::Context>.  This is an object that is passed as the 'context'
argument to your field resolvers.  You might wish to subclass this to add additional useful
methods such as simple access to a user object (if you you authentication for example).

=head2 graphiql

Boolean that defaults to FALSE.  Turn this on to enable the HTML Interactive GraphQL query
screen.  Useful for leaning and debugging but you probably want it off in production.

B<NOTE> If you want to use this you should also install L<Template::Tiny> which is needed.  We
don't make L<Template::Tiny> a dependency here so that you are not forced to install it where
you don't want the interactive screens (such as production).

=head2 json_encoder

Lets you specify the instance of the class used for JSON encoding / decoding.  The default is an
instance of L<JSON::MaybeXS> so you will want to be sure install a fast JSON de/encoder in production,
such as L<Cpanel::JSON::XS> (it will default to a pure Perl one which might not need your speed 
requirements).

=head2 exceptions_class

Class that provides the exception responses.  Override the default (L<Plack::App::GraphQL::Exceptions>)
if you want complete control over how your errors look.

=head1 METHODS

    TBD
 
=head1 AUTHOR
 
John Napiorkowski <jnapiork@cpan.org>

=head1 SEE ALSO
 
L<GraphQL>, L<Plack>

=head1 COPYRIGHT

Copyright (c) 2019 by "AUTHOR" as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.
 
=cut
