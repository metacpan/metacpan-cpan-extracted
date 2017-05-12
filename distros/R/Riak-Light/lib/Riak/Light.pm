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
    $Riak::Light::VERSION = '0.12';
}
## use critic

use 5.010;
use Riak::Light::PBC;
use Riak::Light::Driver;
use MIME::Base64 qw(encode_base64);
use Type::Params qw(compile);
use Types::Standard -types;
use English qw(-no_match_vars );
use Scalar::Util qw(blessed);
use IO::Socket;
use Socket qw(TCP_NODELAY IPPROTO_TCP);
use Const::Fast;
use JSON;
use Carp;
use Module::Runtime qw(use_module);
use Moo;

# ABSTRACT: Fast and lightweight Perl client for Riak

has pid => ( is => 'lazy', isa => Int, clearer => 1, predicate => 1 );
has port => ( is => 'ro', isa => Int, required => 1 );
has host => ( is => 'ro', isa => Str, required => 1 );
has r    => ( is => 'ro', isa => Int, default  => sub {2} );
has w    => ( is => 'ro', isa => Int, default  => sub {2} );
has dw   => ( is => 'ro', isa => Int, default  => sub {2} );

has pr => ( is => 'ro', isa => Int, predicate => 1 );
has pw => ( is => 'ro', isa => Int, predicate => 1 );
has rw => ( is => 'ro', isa => Int, predicate => 1 );

has autodie => ( is => 'ro', isa => Bool, default => sub {1}, trigger => 1 );
has timeout     => ( is => 'ro', isa => Num,  default => sub {0.5} );
has tcp_nodelay => ( is => 'ro', isa => Bool, default => sub {1} );
has in_timeout  => ( is => 'lazy', trigger => 1 );
has out_timeout => ( is => 'lazy', trigger => 1 );
has client_id   => ( is => 'lazy', isa     => Str );

sub _build_pid {
    $$;
}

sub _build_client_id {
    "perl_riak_light" . encode_base64( int( rand(10737411824) ), '' );
}

sub _trigger_autodie {
    my ( $self, $value ) = @_;
    carp "autodie will be disable in the next version" unless $value;
}

sub _trigger_in_timeout {
    carp
      "this feature will be disabled in the next version, you should use just timeout instead";
}

sub _trigger_out_timeout {
    carp
      "this feature will be disabled in the next version, you should use just timeout instead";
}

sub _build_in_timeout {
    $_[0]->timeout;
}

sub _build_out_timeout {
    $_[0]->timeout;
}

has timeout_provider => (
    is      => 'ro',
    isa     => Maybe [Str],
    default => sub {'Riak::Light::Timeout::Select'}
);

has driver => ( is => 'lazy', clearer => 1 );

sub _build_driver {
    Riak::Light::Driver->new( socket => $_[0]->_build_socket() );
}

sub _build_socket {
    my ($self) = @_;

    $self->pid;    # force associate the pid with the current socket

    my $host = $self->host;
    my $port = $self->port;

    my $socket = IO::Socket::INET->new(
        PeerHost => $host,
        PeerPort => $port,
        Timeout  => $self->timeout,
    );

    croak "Error ($!), can't connect to $host:$port"
      unless defined $socket;

    if ( $self->tcp_nodelay ) {
        $socket->setsockopt( IPPROTO_TCP, TCP_NODELAY, 1 )
          or croak "Cannot set tcp nodelay $! ($^E)";
    }

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
    $_[0]->driver;
}

const my $PING          => 'ping';
const my $GET           => 'get';
const my $PUT           => 'put';
const my $DEL           => 'del';
const my $GET_KEYS      => 'get_keys';
const my $QUERY_INDEX   => 'query_index';
const my $MAP_REDUCE    => 'map_reduce';
const my $SET_CLIENT_ID => 'set_client_id';
const my $GET_CLIENT_ID => 'get_client_id';

const my $ERROR_RESPONSE_CODE         => 0;
const my $GET_RESPONSE_CODE           => 10;
const my $GET_KEYS_RESPONSE_CODE      => 18;
const my $MAP_REDUCE_RESPONSE_CODE    => 24;
const my $QUERY_INDEX_RESPONSE_CODE   => 26;
const my $GET_CLIENT_ID_RESPONSE_CODE => 4;

const my $CODES => {
    $PING          => { request_code => 1,  response_code => 2 },
    $GET           => { request_code => 9,  response_code => 10 },
    $PUT           => { request_code => 11, response_code => 12 },
    $DEL           => { request_code => 13, response_code => 14 },
    $GET_KEYS      => { request_code => 17, response_code => 18 },
    $MAP_REDUCE    => { request_code => 23, response_code => 24 },
    $QUERY_INDEX   => { request_code => 25, response_code => 26 },
    $GET_CLIENT_ID => { request_code => 3,  response_code => 4 },
    $SET_CLIENT_ID => { request_code => 5,  response_code => 6 },
};

const my $DEFAULT_MAX_RESULTS => 100;

sub ping {
    $_[0]->_parse_response(
        operation => $PING,
        body      => q(),
    );
}

sub is_alive {
    eval { $_[0]->ping };
}

sub get_keys {
    state $check = compile( Any, Str, Optional [CodeRef] );
    my ( $self, $bucket, $callback ) = $check->(@_);

    my $body = RpbListKeysReq->encode( { bucket => $bucket } );
    $self->_parse_response(
        key       => "*",
        bucket    => $bucket,
        operation => $GET_KEYS,
        body      => $body,
        callback  => $callback,
    );
}

sub get_raw {
    state $check = compile( Any, Str, Str, Optional [Bool] );
    my ( $self, $bucket, $key, $return_all ) = $check->(@_);
    my $response = $self->_fetch( $bucket, $key, 0 );

    my $result;
    if ( defined $response ) {
        $result = ($return_all) ? $response : $response->{value};
    }
    $result;
}

sub get_full_raw {
    state $check = compile( Any, Str, Str );
    my ( $self, $bucket, $key ) = $check->(@_);

    $self->get_raw( $bucket, $key, 1 );
}

sub get {
    state $check = compile( Any, Str, Str, Optional [Bool] );
    my ( $self, $bucket, $key, $return_all ) = $check->(@_);
    my $response = $self->_fetch( $bucket, $key, 1 );
    my $result;
    if ( defined $response ) {
        $result = ($return_all) ? $response : $response->{value};
    }
    $result;
}

sub get_full {
    state $check = compile( Any, Str, Str );
    my ( $self, $bucket, $key ) = $check->(@_);

    $self->get( $bucket, $key, 1 );
}

sub get_all_indexes {
    state $check = compile( Any, Str, Str );
    my ( $self, $bucket, $key ) = $check->(@_);
    my $response = $self->_fetch( $bucket, $key, 0, 1 );

    return ( !defined $response )
      ? []
      : [ map { +{ value => $_->value, key => $_->key } }
          @{ $response->{indexes} // [] } ];
}

sub get_index_value {
    state $check = compile( Any, Str, Str, Str );
    my ( $self, $bucket, $key, $index_name ) = $check->(@_);

    $self->get_all_index_values( $bucket, $key )->{$index_name};
}

sub get_all_index_values {
    state $check = compile( Any, Str, Str );
    my ( $self, $bucket, $key ) = $check->(@_);

    my %values;
    foreach my $index ( @{ $self->get_all_indexes( $bucket, $key ) } ) {
        my $key = $index->{key};
        $values{$key} //= [];
        push @{ $values{$key} }, $index->{value};
    }

    \%values;
}

sub get_vclock {
    state $check = compile( Any, Str, Str );
    my ( $self, $bucket, $key ) = $check->(@_);
    my $response = $self->_fetch( $bucket, $key, 0, 1 );

    defined $response and $response->{vclock};
}

sub exists {
    state $check = compile( Any, Str, Str );
    my ( $self, $bucket, $key ) = $check->(@_);
    defined $self->_fetch( $bucket, $key, 0, 1 );
}

sub _fetch {
    my ( $self, $bucket, $key, $decode, $head ) = @_;

    my %extra_parameters;
    $extra_parameters{pr} = $self->pr if $self->has_pr;

    my $body = RpbGetReq->encode(
        {   r      => $self->r,
            key    => $key,
            bucket => $bucket,
            head   => $head,
            %extra_parameters
        }
    );

    $self->_parse_response(
        key       => $key,
        bucket    => $bucket,
        operation => $GET,
        body      => $body,
        decode    => $decode,
    );
}

sub put_raw {
    state $check =
      compile( Any, Str, Str, Any, Optional [Str],
        Optional [ HashRef [ Str | ArrayRef [Str] ] ], Optional [Str] );
    my ( $self, $bucket, $key, $value, $content_type, $indexes, $vclock ) =
      $check->(@_);
    $content_type ||= 'plain/text';
    $self->_store( $bucket, $key, $value, $content_type, $indexes, $vclock );
}

sub put {
    state $check =
      compile( Any, Str, Str, Any, Optional [Str],
        Optional [ HashRef [ Str | ArrayRef [Str] ] ], Optional [Str] );
    my ( $self, $bucket, $key, $value, $content_type, $indexes, $vclock ) =
      $check->(@_);

    ( $content_type ||= 'application/json' ) eq 'application/json'
      and $value = encode_json($value);

    $self->_store( $bucket, $key, $value, $content_type, $indexes, $vclock );
}

sub _store {
    my ( $self, $bucket, $key, $encoded_value, $content_type, $indexes,
        $vclock ) = @_;

    my %extra_parameters = ();

    $extra_parameters{vclock} = $vclock if $vclock;
    $extra_parameters{dw}     = $self->dw;
    $extra_parameters{pw}     = $self->pw if $self->has_pw;

    my $body = RpbPutReq->encode(
        {   key     => $key,
            bucket  => $bucket,
            content => {
                value        => $encoded_value,
                content_type => $content_type,
                (   $indexes
                    ? ( indexes => [
                            map {
                                my $k = $_;
                                my $v = $indexes->{$_};
                                ref $v eq 'ARRAY'
                                  ? map { { key => $k, value => $_ }; } @$v
                                  : { key => $k, value => $v };
                              } keys %$indexes
                        ]
                      )
                    : ()
                ),
            },
            w => $self->w,
            %extra_parameters,
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
    state $check = compile( Any, Str, Str );
    my ( $self, $bucket, $key ) = $check->(@_);

    my %extra_parameters;

    $extra_parameters{rw} = $self->rw if $self->has_rw;
    $extra_parameters{pr} = $self->pr if $self->has_pr;
    $extra_parameters{pw} = $self->pw if $self->has_pw;

    my $body = RpbDelReq->encode(
        {   key    => $key,
            bucket => $bucket,
            r      => $self->r,
            w      => $self->w,
            dw     => $self->dw,
            %extra_parameters
        }
    );

    $self->_parse_response(
        key       => $key,
        bucket    => $bucket,
        operation => $DEL,
        body      => $body,
    );
}

sub query_index_loop {
    state $check =
      compile( Any, Str, Str, Str | ArrayRef, Optional [HashRef] );
    my ( $self, $bucket, $index, $value_to_match, $extra_parameters ) =
      $check->(@_);

    $extra_parameters //= {};
    $extra_parameters->{max_results} //= $DEFAULT_MAX_RESULTS;

    my @keys;
    do {

        my ( $temp_keys, $continuation, undef ) =
          $self->query_index( $bucket, $index, $value_to_match,
            $extra_parameters );

        $extra_parameters->{continuation} = $continuation;

        push @keys, @{$temp_keys};

    } while ( defined $extra_parameters->{continuation} );

    return \@keys;
}

sub query_index {
    state $check =
      compile( Any, Str, Str, Str | ArrayRef, Optional [HashRef] );
    my ( $self, $bucket, $index, $value_to_match, $extra_parameters ) =
      $check->(@_);

    my $query_type = 0;    # eq
    ref $value_to_match
      and $query_type = 1;    # range

    croak "query index in stream mode not supported"
      if defined $extra_parameters && $extra_parameters->{stream};

    my $body = RpbIndexReq->encode(
        {   index  => $index,
            bucket => $bucket,
            qtype  => $query_type,
            $query_type
            ? ( range_min => $value_to_match->[0],
                range_max => $value_to_match->[1]
              )
            : ( key => $value_to_match ),
            %{ $extra_parameters // {} },
        }
    );

    $self->_parse_response(
        $query_type
        ? ( key => "2i query on index='$index' => "
              . $value_to_match->[0] . '...'
              . $value_to_match->[1] )
        : ( key => "2i query on index='$index' => " . $value_to_match ),
        bucket    => $bucket,
        operation => $QUERY_INDEX,
        body      => $body,
        paginate  => defined $extra_parameters
          && exists $extra_parameters->{max_results},
    );
}

sub map_reduce {
    state $check = compile( Any, Any, Optional [CodeRef] );
    my ( $self, $request, $callback ) = $check->(@_);

    my @args;

    push @args, ref($request) ? encode_json($request) : $request;
    push @args, 'application/json';
    push @args, $callback if $callback;

    $self->map_reduce_raw(@args);
}

sub map_reduce_raw {
    state $check = compile( Any, Str, Str, Optional [CodeRef] );
    my ( $self, $request, $content_type, $callback ) = $check->(@_);

    my $body = RpbMapRedReq->encode(
        {   request      => $request,
            content_type => $content_type,
        }
    );

    $self->_parse_response(
        key       => 'no-key',
        bucket    => 'no-bucket',
        operation => $MAP_REDUCE,
        body      => $body,
        callback  => $callback,
        decode    => ( $content_type eq 'application/json' ),
    );
}

sub get_client_id {
    my $self = shift;

    $self->_parse_response(
        operation => $GET_CLIENT_ID,
        body      => q(),
    );
}

sub set_client_id {
    state $check = compile( Any, Str );
    my ( $self, $client_id ) = $check->(@_);

    my $body = RpbSetClientIdReq->encode( { client_id => $client_id } );

    $self->_parse_response(
        operation => $SET_CLIENT_ID,
        body      => $body,
    );
}

sub _pid_change {
    $_[0]->pid != $$;
}

sub _parse_response {
    my ( $self, %args ) = @_;

    my $operation = $args{operation};

    my $request_code  = $CODES->{$operation}->{request_code};
    my $expected_code = $CODES->{$operation}->{response_code};

    my $request_body = $args{body};
    my $decode       = $args{decode};
    my $bucket       = $args{bucket};
    my $key          = $args{key};
    my $callback     = $args{callback};
    my $paginate     = $args{paginate};

    $self->autodie
      or undef $@;    ## no critic (RequireLocalizedPunctuationVars)

    if ( $self->_pid_change ) {
        $self->clear_pid;
        $self->clear_driver;
    }

    $self->driver->perform_request(
        code => $request_code,
        body => $request_body
      )
      or return $self->_process_generic_error(
        $ERRNO, $operation, $bucket,
        $key
      );

#    my $done = 0;
#$expected_code != $GET_KEYS_RESPONSE_CODE;

    my $response;
    my @results;
    while (1) {

        # get and check response
        $response = $self->driver->read_response()
          // { code => -1, body => undef, error => $ERRNO };

        my ( $response_code, $response_body, $response_error ) =
          @{$response}{qw(code body error)};

        # in case of internal error message
        defined $response_error
          and return $self->_process_generic_error(
            $response_error, $operation, $bucket,
            $key
          );

        # in case of error msg
        $response_code == $ERROR_RESPONSE_CODE
          and return $self->_process_riak_error(
            $response_body, $operation, $bucket,
            $key
          );

        # in case of default message
        $response_code != $expected_code
          and return $self->_process_generic_error(
            "Unexpected Response Code in (got: $response_code, expected: $expected_code)",
            $operation, $bucket, $key
          );

        $response_code == $GET_CLIENT_ID_RESPONSE_CODE
          and return $self->_process_get_client_id_response($response_body);

        # we have a 'get' response
        $response_code == $GET_RESPONSE_CODE
          and
          return $self->_process_get_response( $response_body, $bucket, $key,
            $decode );

# we have a 'get_keys' response
# TODO: support for 1.4 (which provides 'stream', 'return_terms', and 'stream')
        if ( $response_code == $GET_KEYS_RESPONSE_CODE ) {
            my $obj = RpbListKeysResp->decode($response_body);
            my @keys = @{ $obj->keys // [] };
            if ($callback) {
                $callback->($_) foreach @keys;
                $obj->done
                  and return;
            }
            else {
                push @results, @keys;
                $obj->done
                  and return \@results;
            }
            next;
        }    # in case of a 'query_index' response
        elsif ( $response_code == $QUERY_INDEX_RESPONSE_CODE ) {
            my $obj = RpbIndexResp->decode($response_body);

            my $keys = $obj->keys // [];

            if ( $paginate and wantarray ) {
                return ( $keys, $obj->continuation, $obj->done );
            }
            else {
                return $keys;
            }
        }
        elsif ( $response_code == $MAP_REDUCE_RESPONSE_CODE ) {
            my $obj = RpbMapRedResp->decode($response_body);

            my $phase = $obj->phase;
            my $response =
              ($decode)
              ? decode_json( $obj->response // '[]' )
              : $obj->response;

            if ($callback) {
                $obj->done
                  and return;
                $callback->( $response, $phase );
            }
            else {
                $obj->done
                  and return \@results;
                push @results, { phase => $phase, response => $response };
            }
            next;
        }

        # in case of no return value, signify success
        return 1;
    }

}

sub _process_get_client_id_response {
    my ( $self, $encoded_message ) = @_;

    $self->_process_generic_error( "Undefined Message", 'get client id', '-',
        '-' )
      unless ( defined $encoded_message );

    my $decoded_message = RpbGetClientIdResp->decode($encoded_message);
    $decoded_message->client_id;
}

sub _process_get_response {
    my ( $self, $encoded_message, $bucket, $key, $should_decode ) = @_;

    $self->_process_generic_error( "Undefined Message", 'get', $bucket, $key )
      unless ( defined $encoded_message );

    my $decoded_message = RpbGetResp->decode($encoded_message);

    my $contents = $decoded_message->content;
    if ( ref($contents) eq 'ARRAY' ) {
        my $content = $contents->[0];

        my $decode =
          $should_decode && ( $content->content_type eq 'application/json' );
        return {
            value => ($decode)
            ? decode_json( $content->value )
            : $content->value,
            indexes => $content->indexes,
            vclock  => $decoded_message->vclock,
        };
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

    my $extra = '';

    if ( $operation eq $PING ) {
        $extra = '';
    }
    elsif ( $operation eq $QUERY_INDEX ) {
        $extra = "(bucket: $bucket, $key)";
    }
    elsif ( $operation eq $MAP_REDUCE ) {
        $extra = '';    # maybe add the sha1 of the request?
    }
    else {
        $extra = "(bucket: $bucket, key: $key)";
    }

    my $error_message = "Error in '$operation' $extra: $error";

    croak $error_message if $self->autodie;

    $@ = $error_message;    ## no critic (RequireLocalizedPunctuationVars)

    undef;
}

1;


=pod

=head1 NAME

Riak::Light - Fast and lightweight Perl client for Riak

=head1 VERSION

version 0.12

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
  $client->put_raw( foo => baz => "sometext");  # does not encode !

  # fetch hashref from bucket 'foo', key 'bar'
  my $hash = $client->get( foo => 'bar');
  my $text = $client->get_raw( foo => 'baz');   # does not decode !

  # delete hashref from bucket 'foo', key 'bar'
  $client->del(foo => 'bar');

  # check if exists (like get but using less bytes in the response)
  $client->exists(foo => 'baz') or warn "ops, foo => bar does not exist";

  # list keys in stream (callback only)
  $client->get_keys(foo => sub{
     my $key = $_[0];

     # you should use another client inside this callback!
     $another_client->del(foo => $key);
  });
  
  # perform 2i queries
  my $keys    = $client->query_index( $bucket_name => 'index_test_field_bin', 'plop');
  
  # list all 2i indexes and values
  my $indexes = $client->get_all_indexes( $bucket_name => $key );
  
  # perform map / reduce operations
  my $response = $client->map_reduce('{
      "inputs":"training",
      "query":[{"map":{"language":"javascript",
      "source":"function(riakObject) {
        var val = riakObject.values[0].data.match(/pizza/g);
        return [[riakObject.key, (val ? val.length : 0 )]];
      }"}}]}');  

=head1 DESCRIPTION

Riak::Light is a very light (and fast) Perl client for Riak using PBC
interface. Support operations like ping, get, exists, put, del, and secondary
indexes (so-called 2i) setting and querying.

It is flexible to change the timeout backend for I/O operations and can
suppress 'die' in case of error (autodie) using the configuration. There is no
auto-reconnect option. It can be very easily wrapped up by modules like
L<Action::Retry> to manage flexible retry/reconnect strategies.

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

=head3 rw

RW value setting for this client. Default not set ( and omit in the request)

=head3 pr

PR value setting for this client. Default not set ( and omit in the request)

=head3 pw

PW value setting for this client. Default not set ( and omit in the request)    

=head3 autodie

Boolean, if false each operation will return undef in case of error (stored in $@). Default is true.

=head3 timeout

Timeout for connection, write and read operations. Default is 0.5 seconds.

=head3 in_timeout

Timeout for read operations. Default is timeout value.

=head3 out_timeout

Timeout for write operations. Default is timeout value.

=head3 tcp_nodelay

Boolean, enable or disable TCP_NODELAY. If True (default), disables Nagle's Algorithm.

See more in: L<http://docs.basho.com/riak/latest/dev/references/client-implementation/#Nagle-s-Algorithm>.

=head3 timeout_provider

Can change the backend for timeout. The default value is IO::Socket::INET and
there is only support to connection timeout.

B<IMPORTANT>: in case of any timeout error, the socket between this client and the
Riak server will be closed. To support I/O timeout you can choose 5 options (or
you can set undef to avoid IO Timeout):

=over

=item * Riak::Light::Timeout::Alarm

uses alarm and Time::HiRes to control the I/O timeout. Does not work on Win32.
(Not Safe)

=item * Riak::Light::Timeout::Time::Out

uses Time::Out and Time::HiRes to control the I/O timeout. Does not work on
Win32. (Not Safe)

=item *  Riak::Light::Timeout::Select

uses IO::Select to control the I/O timeout

=item *  Riak::Light::Timeout::SelectOnWrite

uses IO::Select to control only Output Operations. Can block in Write
Operations. Be Careful.

=item *  Riak::Light::Timeout::SetSockOpt

uses setsockopt to set SO_RCVTIMEO and SO_SNDTIMEO socket properties. Does not
Work on NetBSD 6.0.

=back

=head3 driver

This is a Riak::Light::Driver instance, to be able to connect and perform
requests to Riak over PBC interface.

=head2 METHODS

=head3 is_alive

  $client->is_alive() or warn "ops... something is wrong: $@";

Perform a ping operation. Will return false in case of error (will store in $@).

=head3 ping

  try { $client->ping() } catch { "oops... something is wrong: $_" };

Perform a ping operation. Will die in case of error.

=head3 set_client_id

  $client->set_client_id('foobar');

Set the client id.

=head3 get_client_id

  my $client_id = $client->get_client_id();

Get the client id.

=head3 get

  my $value_or_reference = $client->get(bucket => 'key');

Perform a fetch operation. Expects bucket and key names. Decode the json into a
Perl structure, if the content_type is 'application/json'. If you need the raw
data you can use L<get_raw>.

There is a third argument: return_all. Default is false. If true, we will return an hashref with 3 entries: 
value (the data decoded), indexes and vclock.

=head3 get_raw

  my $scalar_value = $client->get_raw(bucket => 'key');

Perform a fetch operation. Expects bucket and key names. Return the raw data.
If you need decode the json, you should use L<get> instead.

There is a third argument: return_all. Default is false. If true, we will return an hashref with 3 entries: 
value (the data decoded), indexes and vclock.

=head3 get_full

  my $value_or_reference = $client->get_full(bucket => 'key');

Perform a fetch operation. Expects bucket and key names. Will return an hashref with 3 entries: 
value (the data decoded), indexes and vclock. It is the equivalent to call get(bucket, key, 1)

=head3 get_full_raw

  my $scalar_value = $client->get_full_raw(bucket => 'key');

Perform a fetch operation. Expects bucket and key names. Will return an hashref with 3 entries: 
value (the raw data), indexes and vclock. It is the equivalent to call get_raw(bucket, key, 1)

=head3 exists

  $client->exists(bucket => 'key') or warn "key not found";

Perform a fetch operation but with head => 0, and the if there is something
stored in the bucket/key.

=head3 get_all_indexes

  $client->get_all_indexes(bucket => 'key');

Perform a fetch operation but instead return the content, return a hashref with a mapping between index name and an arrayref with all possible values (or empty arrayref if none). For example one possible return is:

  [
      { key => 'index_test_field_bin', value => 'plop' },
      { key => 'index_test_field2_bin', value => 'plop2' }, 
      { key => 'index_test_field2_bin', value => 'plop3' }, 
  ]

IMPORT: this arrayref is unsortered.

=head3 get_index_value

Perform a fetch operation, will return an arrayref with all values of the index or undef (if does not exists). There is no order for the array.

  my $value = $client->get_index_value(bucket => key => 'index_test_field_bin');

It is similar to do

  my $value = $client->get_all_index_values(bucket => 'key')->{index_test_field_bin};

=head3 get_all_index_values

Perform a fetch operation, will return an hashref with all 2i indexes names as keys, and arrayref of all values for values.

=head3 get_vclock

Perform a fetch operation, will return the value of the vclock

  my $vclock = $client->get_vclock(bucket => 'key');

=head3 put

  $client->put('bucket', 'key', { some_values => [1,2,3] });
  $client->put('bucket', 'key', { some_values => [1,2,3] }, 'application/json);
  $client->put('bucket', 'key', 'text', 'plain/text');

  # you can set secondary indexes (2i)
  $client->put( 'bucket', 'key', 'text', 'plain/text',
                { field1_bin => 'abc', field2_int => 42 }
              );
  $client->put( 'bucket', 'key', { some_values => [1,2,3] }, undef,
                { field1_bin => 'abc', field2_int => 42 }
              );
  # remember that a key can have more than one value in a given index. In this
  # case, use ArrayRef:
  $client->put( 'bucket', 'key', 'value', undef,
                { field1_bin => [ 'abc', 'def' ] } );

Perform a store operation. Expects bucket and key names, the value, the content
type (optional, default is 'application/json'), and the indexes to set for this
value (optional, default is none).

Will encode the structure in json string if necessary. If you need only store
the raw data you can use L<put_raw> instead.

B<IMPORTANT>: all the index field names should end by either C<_int> or
C<_bin>, depending if the index type is integer or binary.

To query secondary indexes, see L<query_index>.

=head3 put_raw

  $client->put_raw('bucket', 'key', encode_json({ some_values => [1,2,3] }), 'application/json');
  $client->put_raw('bucket', 'key', 'text');
  $client->put_raw('bucket', 'key', 'text', undef, {field_bin => 'foo'});

Perform a store operation. Expects bucket and key names, the value, the content
type (optional, default is 'plain/text'), and the indexes to set for this value
(optional, default is none).

Will encode the raw data. If you need encode the structure you can use L<put>
instead.

B<IMPORTANT>: all the index field names should end by either C<_int> or
C<_bin>, depending if the index type is integer or binary.

To query secondary indexes, see L<query_index>.

=head3 del

  $client->del(bucket => key);

Perform a delete operation. Expects bucket and key names.

=head3 get_keys

  $client->get_keys(foo => sub{
     my $key = $_[0];

     # you should use another client inside this callback!
     $another_client->del(foo => $key);
  });

Perform a list keys operation. Receive a callback and will call it for each
key. You can't use this callback to perform other operations!

The callback is optional, in which case an ArrayRef of all the keys are
returned. But you should always provide a callback, to avoid your RAM usage to
skyrocket...

=head3 query_index

Perform a secondary index query. Expects a bucket name, the index field name,
and the index value you're searching on. Returns and ArrayRef of matching keys.

The index value you're searching on can be of two types. If it's a scalar, an
B<exact match> query will be performed. if the value is an ArrayRef, then a
B<range> query will be performed, the first element in the array will be the
range_min, the second element the range_max. other elements will be ignored.

Based on the example in C<put>, here is how to query it:

  # exact match
  my $matching_keys = $client->query_index( 'bucket',  'field2_int', 42 );

  # range match
  my $matching_keys = $client->query_index( 'bucket',  'field2_int', [ 40, 50] );

  # with pagination
  my ($matching_keys, $continuation, $done) = $client->query_index( 'bucket',  'field2_int', 42, { max_results => 100 });

  to fetch the next 100 keys

  my ($matching_keys, $continuation, $done) = $client->query_index( 'bucket',  'field2_int', 42, { 
    max_results => 100,
    continuation => $continuation
   });

to fetch only the first 100 keys you can do this

  my $matching_keys = $client->query_index( 'bucket',  'field2_int', [ 40, 50], { max_results => 100 });

=head3 query_index_loop

Instead using a normal loop around query_index to query 2i with pagination, like this:

  do {
      ($matching_keys, $continuation) = $client->query_index( 'bucket',  'field2_int', 42, { 
      max_results => 100,
      continuation => $continuation
     });
     push @keys, @{$matching_keys};
  } while(defined $continuation);

you can simply use query_index_loop helper method

  my $matching_keys = $client->query_index_loop( 'bucket',  'field2_int', [ 40, 50], { max_results => 1024 });

if you omit the max_results, the default value is 100

=head3 map_reduce

This is an alias for map_reduce_raw with content-type 'application/json'

=head3 map_reduce_raw

Performa a map/reduce operation. You can use content-type 'application/json' or 'application/x-erlang-binary' Accept callback.

Example:

  my $map_reduce_json = '{
    "inputs":"training",
    "query":[{"map":{"language":"javascript",
    "source":"function(riakObject) {
      var val = riakObject.values[0].data.match(/pizza/g);
      return [[riakObject.key, (val ? val.length : 0 )]];
    }"}}]}';
    
  my $response = $client->map_reduce_raw($map_reduce_json, 'application/json');

will return something like

  [
    {'response' => [['foo',1]],'phase' => 0},
    {'response' => [['bam',3]],'phase' => 0},
    {'response' => [['bar',4]],'phase' => 0},
    {'response' => [['baz',0]],'phase' => 0}
  ]    

a hashref with response (decoded if json) and phase value. you can also pass a callback

  $client->map_reduce( $map_reduce_json , sub { 
      my ($response, $phase) = @_;
      
      # process the response
    });

this callback will be called 4 times, with this response (decoded from json)

 [['foo', 1]]
 [['bam', 3]]
 [['bar', 4]]
 [['baz', 0]]

using map_reduce method, you can also use a hashref as a map reduce query:

  my $json_hash = {
      inputs => "training",
      query => [{
        map => {
          language =>"javascript",
          source =>"function(riakObject) {
            var val = riakObject.values[0].data.match(/pizza/g);
            return [[riakObject.key, (val ? val.length : 0 )]];
          }"
        }
      }]
    };
  
  $client->map_reduce($json_hash, sub { ... });

map_reduce encode/decode to json format. If you need control with the format (like to use with erlang), you should use map_reduce_raw.  

you can use erlang functions but using the json format (see L<this example |http://docs.basho.com/riak/latest/dev/advanced/mapreduce/#Erlang-Functions>).

   {"inputs":"messages","query":[{"map":{"language":"erlang","module":"mr_example","function":"get_keys"}}]}

More information:

L<protocol buffers mapreduce api|http://docs.basho.com/riak/latest/dev/references/protocol-buffers/mapreduce/>

L<mapreduce basics|http://docs.basho.com/riak/latest/dev/using/mapreduce/>

L<advanced mapreduce|http://docs.basho.com/riak/latest/dev/advanced/mapreduce/>

=head1 SEE ALSO

L<Net::Riak>

L<Data::Riak>

L<Data::Riak::Fast>

L<Action::Retry>

=head1 AUTHORS

=over 4

=item *

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=item *

Damien Krotkine <dams@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
