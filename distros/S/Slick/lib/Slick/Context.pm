package Slick::Context;

use 5.036;

use Moo;
use Slick::Util;
use Types::Standard qw(Str HashRef);
use Module::Runtime qw(require_module);
use URI::Query;
use URL::Encode;
use JSON::Tiny qw(encode_json decode_json);
use YAML::Tiny;

# STATIC
sub REDIRECT { return 'R'; }
sub STANDARD { return 'S'; }

has id => (
    is      => 'ro',
    isa     => Str,
    default => sub { return Slick::Util->four_digit_number; }
);

has stash => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { return { 'slick.errors' => [] }; }
);

has request => (
    is       => 'ro',
    required => 1
);

has response => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        return {
            status  => 200,
            body    => [''],
            headers => []
        };
    }
);

has queries => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { return {}; }
);

has params => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { return {}; }
);

has _initiated_time => (
    is      => 'ro',
    default => sub { require_module('Time::HiRes'); return time; }
);

sub _decode_content {
    my $self = shift;

    state $known_types = {
        'application/json'                => sub { return decode_json(shift); },
        'text/json'                       => sub { return decode_json(shift); },
        'application/json; encoding=utf8' => sub { return decode_json(shift); },
        'application/yaml'   => sub { return YAML::Tiny->read_string(shift); },
        'text/yaml'          => sub { return YAML::Tiny->read_string(shift); },
        'application/x-yaml' => sub { return YAML::Tiny->read_string(shift); },
        'application/x-www-form-urlencoded' =>
          sub { return url_decode_utf8(shift); }
    };

    return $known_types->{ $self->request->content_type }
      ->( $self->request->content )
      if exists $known_types->{ $self->request->content_type };

    if ( rindex( $self->request->content_type, 'application/json', 0 ) == 0 ) {
        return decode_json( $self->request->content );
    }
    elsif (
        rindex( $self->request->content_type,
            'application/x-www-form-urlencoded' ) == 0
      )
    {
        return url_decode_utf8( $self->request->content );
    }
    elsif (rindex( $self->request->content_type, 'application/yaml', 0 ) == 0
        || rindex( $self->request->content_type, 'application/x-yaml', 0 ) ==
        0 )
    {
        return YAML::Tiny->read_string( $self->request->content );
    }
    else {
        return $self->request->content;
    }
}

sub BUILD {
    my $self = shift;

    $self->{queries} = URI::Query->new( $self->request->query_string )->hash;

    return $self;
}

sub param {
    return shift->params->{ shift() };
}

sub query {
    return shift->queries->{ shift() };
}

sub to_psgi {
    my $self     = shift;
    my $response = $self->response;

    $response->{status} = 500
      if $self->stash->{'slick.errors'}->@*;

    return [ $response->{status}, $response->{headers}, $response->{body} ];
}

sub from_psgi {
    my $self     = shift;
    my $response = shift;

    $self->response->{status}  = $response->[0];
    $self->response->{headers} = $response->[1];
    $self->response->{body}    = $response->[2];

    return $self;
}

sub redirect {
    my ( $self, $location, $status ) = @_;

    $self->status( $status // 303 );
    $self->header( Location => $location );

    return $self;
}

sub header {
    my ( $self, $key, $value ) = @_;

    my %headers = @{ $self->response->{headers} };
    $headers{$key} = $value;
    $self->response->{headers} = [%headers];

    return $self;
}

sub status {
    my $self   = shift;
    my $status = shift;

    $self->response->{status} = $status;

    return $self;
}

sub json {
    my $self = shift;
    my $body = shift;

    require_module('JSON::Tiny');

    $self->header( 'Content-Type', 'application/json; encoding=utf8' );
    $self->body( encode_json $body);

    return $self;
}

sub yaml {
    my $self = shift;
    my $body = shift;

    require_module('YAML::Tiny');

    $self->header( 'Content-Type', 'application/yaml; encoding=utf8' );
    $self->body( YAML::Tiny->new($body)->write_string );

    return $self;
}

sub text {
    my $self = shift;
    my $body = shift;

    $self->body($body);
    $self->header( 'Content-Type', 'text/plain; encoding=utf8' );

    return $self;
}

sub html {
    my $self = shift;
    my $body = shift;

    $self->body($body);
    $self->header( 'Content-Type', 'text/html; encoding=utf8' );

    return $self;
}

sub body {
    my $self = shift;
    my $body = shift;

    $self->response->{body} = [$body];

    return $self;
}

sub content {
    my $self = shift;

    state $val = $self->_decode_content;

    return $val;
}

1;

=encoding utf8

=head1 NAME

Slick::Context

=head1 SYNOPSIS

L<Slick::Context> is an L<Moo> wrapper around the HTTP lifecycle. It encompases a L<Plack::Request>
and a bunch of other helpers to make it easy to handle HTTP in L<Slick>.

=head1 API

=head2 content

    $s->post('/foo', sub {
        my ($app, $context) = @_;
        my $data = $context->content;
    });

Decodes the body of the L<Plack::Request> via the following:

=over 2

=item * C<JSON> => L<JSON::Tiny>

=item * C<YAML> => L<YAML::Tiny>

=item * C<URL ENCODED> => L<URL::Encode>

=item * C<OTHER> => returns as text/bytes

=back

=head2 body

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->body('Foo!');
    });

Sets the body of the response to whatever is provided. Note:
You'll probably want to use L<"html">, L<"json">, L<"text"> or L<"yaml"> instead of this.

=head2 html

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->body('<h1>Foo!</h1>');
    });

Sets the body of the response and sets the C<Content-Type> header to C<text/html>.
Returns the context.

Note, you should have C<use utf8;> enabled.

=head2 json

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->json({ hello => 'world' });
    });

Sets the body of the response and sets the C<Content-Type> header to C<application/json>.
Returns the context.

Note, you should have C<use utf8;> enabled.

=head2 yaml

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->yaml([ { hello => 'world' });
    });

Sets the body of the response and sets the C<Content-Type> header to C<application/yaml>.
Returns the context.

Note, you should have C<use utf8;> enabled.

=head2 text

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->text("Hello World!");
    });

Sets the body of the response and sets the C<Content-Type> header to C<text/plain>.
Returns the context.

Note, you should have C<use utf8;> enabled.

=head2 to_psgi

Converts the L<Slick::Context> to L<Plack> response. In the format:

    [$status, [ @headers ], [ @body ]]

=head2 status

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->status(201);
    });

Sets the status code of the response, returns the context.

=head2 redirect

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->redirect("/foo");
    });

Sets the response to redirect to a given location, optionally provide another status code as a second argument if you don't want C<303>.
Returns the context object.

=head2 header

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->header(Foo => 'bar');
    });

Sets a header on the underlying response C<HashRef>. Returns the context.

=head2 response

Returns the response C<HashRef> that will be used to create the PSGI response via L<"to_psgi">.

=head2 query

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->query('bar');
    });

Returns the value of a specified query parameter key, returns undef if there is no such key.

See L<"queries"> for the raw query parameter C<HashRef>.

=head2 queries

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->queries->{'bar'};
    });

Returns the query parameters as a C<HashRef>.

=head2 param

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        $context->param('bar');
    });

Returns the value of a specified path parameter key, returns undef if there is no such key.

See L<"params"> for the raw path parameter C<HashRef>.

=head2 params

    $s->get('/foo/{bar}', sub {
        my ($app, $context) = @_;
        $context->params->{'bar'};
    });

Returns the path parameters as a C<HashRef>.

=head2 stash

Returns a transient C<HashRef> that is persistent per request, this is for inter-layer communication.

=head2 id

Returns an arbitrary tracing ID in the form of a 4-digit number.

=head1 See also

=over2

=item * L<Slick>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
