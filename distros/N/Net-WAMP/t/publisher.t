#!/usr/bin/env perl

use strict;
use warnings;

use Test::Deep;
use Test::More tests => 3;

local $SIG{'__WARN__'} = sub { die shift };

use Types::Serialiser ();

use Net::WAMP::Message::PUBLISHED ();
use Net::WAMP::Message::WELCOME ();
use Net::WAMP::Session ();

#----------------------------------------------------------------------
package MyClient;

#just picked one …
use parent qw( Net::WAMP::Role::Publisher );

our @PUBLISHED;

sub on_PUBLISHED {
    my ($self) = shift;
    push @PUBLISHED, \@_;
}

#----------------------------------------------------------------------

package main;

my @sent;

my $client = MyClient->new(
    serialization => 'json',
    on_send => sub { push @sent, $_[0] },
);

$client->send_HELLO( 'my-realm', { foo => 2 } );

#Use this just for serialization. This isn’t needed in actual code.
my $json_session = Net::WAMP::Session->new(
    serialization => 'json',
    on_send => sub { die 'NONO' },
);

my $hello_msg = $json_session->message_bytes_to_object( shift @sent );

cmp_deeply(
    $hello_msg,
    all(
        Isa('Net::WAMP::Message::HELLO'),
        methods(
            [ get => 'Realm' ] => 'my-realm',
            [ get => 'Auxiliary' ] => {
                foo => 2,
                agent => re( qr<MyClient> ),
                roles => {
                    publisher => {
                        features => {
                            publisher_exclusion => Types::Serialiser::true(),
                        },
                    },
                },
            },
        ),
    ),
    'HELLO messsage sent as expected',
) or diag explain $hello_msg;

#----------------------------------------------------------------------

my $welcome_msg = Net::WAMP::Message::WELCOME->new(
    123123123,
    {
        roles => {
            broker => {},
        },
    },
);

$client->handle_message(
    $json_session->message_object_to_bytes($welcome_msg),
);

#----------------------------------------------------------------------

$client->send_PUBLISH( { acknowledge => Types::Serialiser::true() }, 'some.topic', ['foo'], { bar => 'baz' } );

my $publish_msg = $json_session->message_bytes_to_object( shift @sent );

cmp_deeply(
    $publish_msg,
    all(
        Isa('Net::WAMP::Message::PUBLISH'),
        methods(
            [ get => 'Topic' ] => 'some.topic',
            [ get => 'Auxiliary' ] => { acknowledge => Types::Serialiser::true() },
            [ get => 'Arguments' ] => ['foo'],
            [ get => 'ArgumentsKw' ] => { bar => 'baz' },
            [ get => 'Request' ] => re( qr<\A[0-9]+\z> ),
        ),
    ),
    'PUBLISH messsage sent as expected',
) or diag explain $hello_msg;

#----------------------------------------------------------------------

my $published_msg = Net::WAMP::Message::PUBLISHED->new(
    $publish_msg->get('Request'),
    456456456,
);

$client->handle_message(
    $json_session->message_object_to_bytes($published_msg),
);

cmp_deeply(
    \@MyClient::PUBLISHED,
    [ [ $published_msg ] ],
    'on_PUBLISHED() callback',
) or diag explain \@MyClient::PUBLISHED;
