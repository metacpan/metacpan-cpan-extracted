package Myriad::RPC::Message;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Object::Pad;
class Myriad::RPC::Message;

use utf8;

=encoding utf8

=head1 NAME

Myriad::RPC::Message - RPC message implementation

=head1 SYNOPSIS

 Myriad::RPC::Message->new();

=head1 DESCRIPTION

This class is to handle the decoding/encoding and verification of the RPC messages received
from the transport layer. It will throw an exception when the message is invalid or doesn't
match the structure.

=cut

use Scalar::Util qw(blessed);
use Syntax::Keyword::Try;
use JSON::MaybeUTF8 qw(:v1);

has $rpc;
has $message_id;
has $transport_id;
has $who;
has $deadline;

has $args;
has $stash;
has $response;
has $trace;

=head2 message_id

The ID of the message given by the requester.

=cut

method message_id { $message_id }

=head2 transport_id

The ID of the message given by Redis, to be used in xack later.

=cut

method transport_id { $transport_id };

=head2 rpc

The name of the procedure we are going to execute.

=cut

method rpc { $rpc }

=head2 who

A string that should identify the sender of the message for the transport.

=cut

method who { $who }

=head2 deadline

An epoch that represents when the timeout of the message.

=cut

method deadline { $deadline }

=head2 args

A JSON encoded string contains the argument of the procedure.

=cut

method args { $args }

=head2 resposne

The response to this message.

=cut

method response :lvalue { $response }

=head2 stash

information related to the request should be returned back to the requester.

=cut

method stash { $stash }

=head2 trace

Tracing information.

=cut

method trace { $trace }

=head2 BUILD

Build a new message.

=cut

BUILD(%message) {
    $rpc          = $message{rpc};
    $who          = $message{who};
    $message_id   = $message{message_id};
    $transport_id = $message{transport_id};
    $deadline     = $message{deadline} || time + 30;
    $args         = $message{args} || {};
    $response     = $message{response} || {};
    $stash        = $message{stash} || {};
    $trace        = $message{trace} || {};
}


=head2 as_hash

Return a simple hash with the message data, it mustn't return nested hashes
so it will convert them to JSON encoded strings.

=cut

method as_hash () {
    my $data =  {
        rpc => $rpc,
        who => $who,
        message_id => $message_id,
        deadline => $deadline,
    };

    $self->apply_encoding($data, 'utf8');

    return $data;

}

=head2 from_hash

a static method (can't be done with Object::Pad currently) that tries to
parse a hash and return a L<Myriad::RPC::Message>.

the hash should comply with the format returned by C<as_hash>.

=cut

sub from_hash (%hash) {
    is_valid(\%hash);
    apply_decoding(\%hash, 'utf8');

    return Myriad::RPC::Message->new(%hash);
}

=head2 as_json

returns the message data as a JSON string.

=cut

method as_json () {
        my $data = {
            rpc        => $rpc,
            message_id => $message_id,
            who        => $who,
            deadline   => $deadline,
        };

        # This step is not necessary but I'm too lazy to repeat the keys names.
        $self->apply_encoding($data, 'text');
        return encode_json_utf8($data);
}

=head2 from_json

a static method that tries to parse a JSON string
and return a L<Myriad::RPC::Message>.

=cut

sub from_json ($json) {
    my $raw_message = decode_json_utf8($json);
    is_valid($raw_message);
    apply_decoding($raw_message, 'text');

    return Myriad::RPC::Message->new($raw_message->%*);
}

=head2 is_valid

A static method used in the C<from_*> methods family to make
sure that we have the needed information.

=cut

sub is_valid ($message) {
    for my $field (qw(rpc message_id who deadline args)) {
        Myriad::Exception::RPC::InvalidRequest->throw(reason => "$field is requried") unless exists $message->{$field};
    }
}

=head2 apply_encoding

A helper method to enode the hash fields into JSON string.

=cut

method apply_encoding ($data, $encoding) {
    my $encode = $encoding eq 'text' ? \&encode_json_text : \&encode_json_utf8;
    try {
        for my $field (qw(args response stash trace)) {
            $data->{$field} = $encode->($self->$field);
        }
    } catch($e) {
        Myriad::Exception::RPC::BadEncoding->throw(reason => $e);
    }
}

=head2 apply_decoding

A helper sub to decode some field from JSON string into Perl hashes.

=cut

sub apply_decoding ($data, $encoding) {
    my $decode = $encoding eq 'text' ? \&decode_json_text : \&decode_json_utf8;
    try {
        for my $field (qw(args response stash trace)) {
            $data->{$field} = $decode->($data->{$field}) if $data->{$field};
        }
    } catch ($e) {
        Myriad::Exception::RPC::BadEncoding->throw(reason => $e);
    }
}

1;

