#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light;
{
    $Riak::Light::VERSION = '0.052';
}
## use critic

use 5.012000;
use Riak::Light::PBC;
use Riak::Light::Driver;
use Params::Validate qw(validate_pos SCALAR CODEREF);
use English qw(-no_match_vars );
use Scalar::Util qw(blessed);
use IO::Socket;
use Const::Fast;
use JSON;
use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Maybe>;
use namespace::autoclean;

# ABSTRACT: Fast and lightweight Perl client for Riak

has port    => ( is => 'ro', isa => Int,  required => 1 );
has host    => ( is => 'ro', isa => Str,  required => 1 );
has r       => ( is => 'ro', isa => Int,  default  => sub {2} );
has w       => ( is => 'ro', isa => Int,  default  => sub {2} );
has dw      => ( is => 'ro', isa => Int,  default  => sub {2} );
has autodie => ( is => 'ro', isa => Bool, default  => sub {1} );
has timeout => ( is => 'ro', isa => Num,  default  => sub {0.5} );
has in_timeout  => ( is => 'lazy' );
has out_timeout => ( is => 'lazy' );

sub _build_in_timeout {
    (shift)->timeout;
}

sub _build_out_timeout {
    (shift)->timeout;
}

has timeout_provider => (
    is => 'ro', isa => Maybe [Str],
    default => sub {'Riak::Light::Timeout::Select'}
);

has driver => ( is => 'lazy' );

sub _build_driver {
    my $self = shift;

    Riak::Light::Driver->new( socket => $self->_build_socket() );
}

sub _build_socket {
    my $self = shift;

    my $host = $self->host;
    my $port = $self->port;

    my $socket = IO::Socket::INET->new(
        PeerHost => $host,
        PeerPort => $port,
        Timeout  => $self->timeout,
    );

    croak "Error ($!), can't connect to $host:$port"
      unless defined $socket;

    return $socket unless defined $self->timeout_provider;

    use Module::Load qw(load);
    load $self->timeout_provider;

    # TODO: add a easy way to inject this proxy
    $self->timeout_provider->new(
        socket      => $socket,
        in_timeout  => $self->in_timeout,
        out_timeout => $self->out_timeout,
    );
}

sub BUILD {
    (shift)->driver;
}

const my $PING     => 'ping';
const my $GET      => 'get';
const my $PUT      => 'put';
const my $DEL      => 'del';
const my $GET_KEYS => 'get_keys';

const my $ERROR_RESPONSE_CODE    => 0;
const my $GET_RESPONSE_CODE      => 10;
const my $GET_KEYS_RESPONSE_CODE => 18;

sub _CODES {
    my $operation = shift;

    return {
        $PING     => { request_code => 1,  response_code => 2 },
        $GET      => { request_code => 9,  response_code => 10 },
        $PUT      => { request_code => 11, response_code => 12 },
        $DEL      => { request_code => 13, response_code => 14 },
        $GET_KEYS => { request_code => 17, response_code => 18 },
    }->{$operation};
}

before [qw(ping get put del)] => sub {
    undef $@    ## no critic (RequireLocalizedPunctuationVars)
};

sub ping {
    my $self = shift;
    $self->_parse_response(
        operation => $PING,
        body      => q(),
    );
}

sub is_alive {
    my $self = shift;

    eval { $self->ping };
}

sub get_keys {
    my ( $self, $bucket, $callback ) =
      validate_pos( @_, 1, 1, { type => CODEREF } );

    my $body = RpbListKeysReq->encode( { bucket => $bucket } );
    $self->_parse_response(
        key       => "*",
        bucket    => $bucket,
        operation => $GET_KEYS,
        body      => $body,
        extra     => { callback => $callback },
    );
}

sub get_raw {
    my ( $self, $bucket, $key ) = validate_pos( @_, 1, 1, 1 );
    $self->_fetch( $bucket, $key, decode => 0 );
}

sub get {
    my ( $self, $bucket, $key ) = validate_pos( @_, 1, 1, 1 );
    $self->_fetch( $bucket, $key, decode => 1 );
}

sub exists {
    my ( $self, $bucket, $key ) = validate_pos( @_, 1, 1, 1 );
    defined $self->_fetch( $bucket, $key, decode => 0, head => 1 );
}

sub _fetch {
    my ( $self, $bucket, $key, %extra ) = @_;

    my $head = $extra{head};

    my $body = RpbGetReq->encode(
        {   r      => $self->r,
            key    => $key,
            bucket => $bucket,
            head   => $head
        }
    );

    $self->_parse_response(
        key       => $key,
        bucket    => $bucket,
        operation => $GET,
        body      => $body,
        extra     => {%extra}
    );
}

sub put_raw {
    my ( $self, $bucket, $key, $value, $content_type ) = validate_pos(
        @_, 1, 1, 1, { type => SCALAR },
        { default => 'plain/text' }
    );

    $self->_store( $bucket, $key, $value, $content_type );
}

sub put {
    my ( $self, $bucket, $key, $value, $content_type ) =
      validate_pos( @_, 1, 1, 1, 1, { default => 'application/json' } );

    my $encoded_value =
      ( $content_type eq 'application/json' )
      ? encode_json($value)
      : $value;

    $self->_store( $bucket, $key, $encoded_value, $content_type );
}

sub _store {
    my ( $self, $bucket, $key, $encoded_value, $content_type ) =
      validate_pos( @_, 1, 1, 1, { type => SCALAR }, 1 );

    my $body = RpbPutReq->encode(
        {   key     => $key,
            bucket  => $bucket,
            content => {
                value        => $encoded_value,
                content_type => $content_type,
            },
        }
    );

    $self->_parse_response(
        key       => $key,
        bucket    => $bucket,
        operation => $PUT,
        body      => $body,
    );
}

sub del {
    my ( $self, $bucket, $key ) = validate_pos( @_, 1, 1, 1 );

    my $body = RpbDelReq->encode(
        {   key    => $key,
            bucket => $bucket,
            rw     => $self->dw
        }
    );

    $self->_parse_response(
        key       => $key,
        bucket    => $bucket,
        operation => $DEL,
        body      => $body,
    );
}

sub _parse_response {
    my ( $self, %args ) = @_;

    my $operation = $args{operation};

    my $request_code  = _CODES($operation)->{request_code};
    my $expected_code = _CODES($operation)->{response_code};

    my $request_body = $args{body};
    my $extra        = $args{extra};
    my $bucket       = $args{bucket};
    my $key          = $args{key};
    my $callback     = $extra->{callback};

    $self->driver->perform_request(
        code => $request_code,
        body => $request_body
      )
      or return $self->_process_generic_error(
        $ERRNO, $operation, $bucket,
        $key
      );

    my $done = $expected_code != $GET_KEYS_RESPONSE_CODE;
    my $response;
    do {
        $response = $self->driver->read_response();

        if ( !defined $response ) {
            $response = { code => -1, body => undef, error => $ERRNO };
            $done = 1;
        }
        elsif ( !$done
            && $response->{code} == $GET_KEYS_RESPONSE_CODE )
        {
            my $obj = RpbListKeysResp->decode( $response->{body} );

            my $keys = $obj->keys;

            if ($keys) {
                $callback->($_) foreach ( @{$keys} );
            }

            $done = $obj->done;
        }
        elsif ( !$done ) {
            $done = 1;
        }
    } while ( !$done );

    my $response_code  = $response->{code};
    my $response_body  = $response->{body};
    my $response_error = $response->{error};

    # return internal error message
    return $self->_process_generic_error(
        $response_error, $operation, $bucket,
        $key
    ) if defined $response_error;

    # return default message
    return $self->_process_generic_error(
        "Unexpected Response Code in (got: $response_code, expected: $expected_code)",
        $operation, $bucket, $key
      )
      if $response_code != $expected_code
          and $response_code != $ERROR_RESPONSE_CODE;

    # return the error msg
    return $self->_process_riak_error(
        $response_body, $operation, $bucket,
        $key
    ) if $response_code == $ERROR_RESPONSE_CODE;

    # return the result from fetch
    return $self->_process_riak_fetch( $response_body, $bucket, $key, $extra )
      if $response_code == $GET_RESPONSE_CODE;

    1    # return true value, in case of a successful put/del
}

sub _process_riak_fetch {
    my ( $self, $encoded_message, $bucket, $key, $extra ) = @_;

    $self->_process_generic_error( "Undefined Message", 'get', $bucket, $key )
      unless ( defined $encoded_message );

    my $should_decode   = $extra->{decode};
    my $decoded_message = RpbGetResp->decode($encoded_message);

    my $content = $decoded_message->content;
    if ( ref($content) eq 'ARRAY' ) {
        my $value        = $content->[0]->value;
        my $content_type = $content->[0]->content_type;

        return ( $content_type eq 'application/json' and $should_decode )
          ? decode_json($value)
          : $value;
    }

    undef;
}

sub _process_riak_error {
    my ( $self, $encoded_message, $operation, $bucket, $key ) = @_;

    my $decoded_message = RpbErrorResp->decode($encoded_message);

    my $errmsg  = $decoded_message->errmsg;
    my $errcode = $decoded_message->errcode;

    $self->_process_generic_error(
        "Riak Error (code: $errcode) '$errmsg'",
        $operation, $bucket, $key
    );
}

sub _process_generic_error {
    my ( $self, $error, $operation, $bucket, $key ) = @_;

    my $extra =
      ( $operation ne 'ping' )
      ? "(bucket: $bucket, key: $key)"
      : q();

    my $error_message = "Error in '$operation' $extra: $error";
    croak $error_message if $self->autodie;

    $@ = $error_message;    ## no critic (RequireLocalizedPunctuationVars)

    undef;
}


sub show_status {
    my $self = shift;

    print
      "bytes in (@{[ $self->driver->connector->socket->bytes_in ]}), bytes out (@{[ $self->driver->connector->socket->bytes_out ]})\n";
}

1;


=pod

=head1 NAME

Riak::Light - Fast and lightweight Perl client for Riak

=head1 VERSION

version 0.052

=head1 SYNOPSIS

  use Riak::Light;

  # create a new instance - using pbc only
  my $client = Riak::Light->new(
    host => '127.0.0.1',
    port => 8087
  );

  $client->is_alive() or die "ops, riak is not alive";

  # store hashref into bucket 'foo', key 'bar'
  # will serializer as 'application/json'
  $client->put( foo => bar => { baz => 1024 });

  # store text into bucket 'foo', key 'bar'
  $client->put( foo => baz => "sometext", 'text/plain');

  # fetch hashref from bucket 'foo', key 'bar'
  my $hash = $client->get( foo => 'bar');

  # delete hashref from bucket 'foo', key 'bar'
  $client->del(foo => 'bar');

  # list keys in stream
  $client->get_keys(foo => sub{
     my $key = $_[0];

     # you should use another client inside this callback!
     $another_client->del(foo => $key);
  });

=head1 DESCRIPTION

Riak::Light is a very light (and fast) perl client for Riak using PBC interface. Support only basic operations like ping, get, put and del. Is flexible to change the timeout backend for I/O operations and can suppress 'die' in case of error (autodie) using the configuration. There is no auto-reconnect option.

=head2 ATTRIBUTES

=head3 host

Riak ip or hostname. There is no default.

=head3 port

Port of the PBC interface. There is no default.

=head3 r

R value setting for this client. Default 2.

=head3 w

W value setting for this client. Default 2.

=head3 dw

DW value setting for this client. Default 2.

=head3 autodie

Boolean, if false each operation will return undef in case of error (stored in $@). Default is true.

=head3 timeout

Timeout for connection, write and read operations. Default is 0.5 seconds.

=head3 in_timeout

Timeout for read operations. Default is timeout value.

=head3 out_timeout

Timeout for write operations. Default is timeout value.

=head3 timeout_provider

Can change the backend for timeout. The default value is IO::Socket::INET and there is only support to connection timeout.
IMPORTANT: in case of any timeout error, the socket between this client and the Riak server will be closed.
To support I/O timeout you can choose 5 options (or you can set undef to avoid IO Timeout):

=over

=item * Riak::Light::Timeout::Alarm

uses alarm and Time::HiRes to control the I/O timeout. Does not work on Win32. (Not Safe)

=item * Riak::Light::Timeout::Time::Out

uses Time::Out and Time::HiRes to control the I/O timeout. Does not work on Win32. (Not Safe)

=item *  Riak::Light::Timeout::Select

uses IO::Select to control the I/O timeout

=item *  Riak::Light::Timeout::SelectOnWrite

uses IO::Select to control only Output Operations. Can block in Write Operations. Be Careful.

=item *  Riak::Light::Timeout::SetSockOpt

uses setsockopt to set SO_RCVTIMEO and SO_SNDTIMEO socket properties. Does not Work on NetBSD 6.0.

=back

=head3 driver

This is a Riak::Light::Driver instance, to be able to connect and perform requests to Riak over PBC interface.

=head2 METHODS

=head3 is_alive

  $client->is_alive() or warn "ops... something is wrong: $@";

Perform a ping operation. Will return false in case of error (will store in $@).

=head3 is_alive

  try { $client->ping() } catch { "ops... something is wrong: $_" };

Perform a ping operation. Will die in case of error.

=head3 get

  my $value_or_reference = $client->get(bucket => 'key');

Perform a fetch operation. Expects bucket and key names. Decode the json into a Perl structure. if the content_type is 'application/json'. If you need the raw data you can use L<get_raw>.

=head3 get_raw

  my $scalar_value = $client->get_raw(bucket => 'key');

Perform a fetch operation. Expects bucket and key names. Return the raw data. If you need decode the json, you should use L<get> instead.

=head3 exists

  $client->exists(bucket => 'key') or warn "key not found";

Perform a fetch operation but with head => 0, and the if there is something stored in the bucket/key.

=head3 put

  $client->put(bucket => key => { some_values => [1,2,3] });
  $client->put(bucket => key => 'text', 'plain/text');

Perform a store operation. Expects bucket and key names, the value and the content type (optional, default is 'application/json'). Will encode the structure in json string if necessary. If you need only store the raw data you can use L<put_raw> instead.

=head3 put_raw

  $client->put_raw(bucket => key => encode_json({ some_values => [1,2,3] }), 'application/json');
  $client->put_raw(bucket => key => 'text');

Perform a store operation. Expects bucket and key names, the value and the content type (optional, default is 'plain/text'). Will encode the raw data. If you need encode the structure you can use L<put> instead.

=head3 del

  $client->del(bucket => key);

Perform a delete operation. Expects bucket and key names.

=head3 get_keys

  $client->get_keys(foo => sub{
     my $key = $_[0];

     # you should use another client inside this callback!
     $another_client->del(foo => $key);
  });

Perform a list keys operation. Receive a callback and will call it for each key. You can't use this callback to perform other operations!

=head1 SEE ALSO

L<Net::Riak>

L<Data::Riak>

L<Data::Riak::Fast>

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
