package PubNub::PubSub::Message;

use Carp;
use Mojo::JSON qw(encode_json decode_json);

use strict;
use warnings;

=head1 NAME

PubNub::PubSub::Message - Message object for PubNub::PubSub

=head1 SYNOPSIS

This module is primarily used behind the scenes in PubNub::PubSub.  It is
not intended to be used directly for users.  This being said, one can use it
if you want to do your own URL management or otherwise interface with PubNub in 
ways this distribution does not yet support.

 my $message = PubNub::PubSub::Message->new(payload=> $datastructure);
 my $json = $message->json;
 my $payload = $message->payload;
 my $queryhash = $message->query_params;

=head1 METHODS

=head2 new

THis is the basic constructor.  Requires message or payload argument.  Message 
is effectively an alias for payload.  Other arguments include ortt, meta, ear,
and seqn, supported per the PubNub API.  These other arguments are converted
to JSON in the query_params method below.

If a simple scalar is passed (not a reference), it is assumed that this will
be passed to PubNub as a string literal and handled appropriately.

=cut

sub new {
    my $pkg  = shift;
    unshift @_, 'payload' if scalar @_ == 1 and !ref $_[0];
    my %args = scalar @_ % 2 ? %{$_[0]} : @_;
    $args{payload} ||= $args{message}; # backwards compatibility
    croak 'Must provide payload' unless $args{payload};
    my $self = \%args;
    return bless $self, $pkg;
}

=head2 payload

Returns the message payload

=cut

sub payload {
    my $self = shift;
    return $self->{payload};
}

=head2 from_msg($json_string)

Returns a message object with a payload from a json string.

=cut

sub from_msg {
    my ($self, $json) = @_;
    my $arrayref = decode_json($json);
    return "$self"->new(payload => $arrayref->[0], timestamp => $arrayref->[1]);
}

=head2 json

Returns the payload encoded in json via Mojo::JSON

=cut

sub json {
    my $self = shift;
    return encode_json($self->{payload});
}

=head2 query_params($mergehash)

Returns a hash of query param properties (ortt, meta, ear, seqn), json-encoded,
for use in constructing URI's for PubNub requests.

=cut

sub query_params {
    my $self = shift;
    my $merge = shift;
    return { map {
        my $var = $self->{$_};
        $var = $merge->{$_} unless defined $var;
        defined $var ?
            ($_ => encode_json($var)) :
            ();
    } qw(ortt meta ear seqn) };
}

=head2 LICENSE

The copyright and license terms of this module are the same as those of the 
PubNub::PubSub module with which it is distributed.

=cut

1;
