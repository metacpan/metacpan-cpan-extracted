[![Build Status](https://travis-ci.org/binary-com/perl-pubnub-pubsub.svg?branch=master)](https://travis-ci.org/binary-com/perl-pubnub-pubsub)
[![Coverage Status](https://coveralls.io/repos/binary-com/perl-pubnub-pubsub/badge.png?branch=master)](https://coveralls.io/r/binary-com/perl-pubnub-pubsub?branch=master)
[![Gitter chat](https://badges.gitter.im/binary-com/perl-pubnub-pubsub.png)](https://gitter.im/binary-com/perl-pubnub-pubsub)

# NAME

PubNub::PubSub - Perl library for rapid publishing of messages on PubNub.com

# SYNOPSIS

    use PubNub::PubSub;

    my $pubnub = PubNub::PubSub->new(
        pub_key => 'demo', # only required for publish
        sub_key => 'demo',
        channel => 'sandbox',
    );

    # publish
    $pubnub->publish({
        messages => ['message1', 'message2'],
        callback => sub {
            my ($res) = @_;

            # $res is a L<Mojo::Message::Response>
            say $res->code; # 200
            say Dumper(\$res->json); # [1,"Sent","14108733777591385"]
        }
    });
    $pubnub->publish({
        channel  => 'sandbox2', # optional, if not applied, the one in ->new will be used.
        messages => ['message3', 'message4']
    });

    # subscribe
    $pubnub->subscribe({
        callback => sub {
            my (@messages) = @_;
            foreach my $msg (@messages) {
                print "# Got message: $msg\n";
            }
            return 1; # 1 to continue, 0 to stop
        }
    });

# DESCRIPTION

PubNub::PubSub is Perl library for rapid publishing of messages on PubNub.com based on [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent)

perl clone of [https://gist.github.com/stephenlb/9496723#pubnub-http-pipelining](https://gist.github.com/stephenlb/9496723#pubnub-http-pipelining)

For a rough test:

- run perl examples/subscribe.pl in one terminal (or luanch may terminals with subscribe.pl)
- run perl examples/publish.pl in another terminal (you'll see all subscribe terminals will get messages.)

# METHOD

## new

- pub\_key

    optional, default pub\_key for publish

- sub\_key

    optional, default sub\_key for all methods

- channel

    optional, default channel for all methods

- publish\_callback

    optional. default callback for publish

- debug

    set ENV MOJO\_USERAGENT\_DEBUG to debug

## subscribe

subscribe channel to listen for the messages.

    $pubnub->subscribe({
        callback => sub {
            my (@messages) = @_;
            foreach my $msg (@messages) {
                print "# Got message: $msg\n";
            }
            return 1; # 1 to continue, 0 to stop
        }
    });

return 0 to stop

## publish

publish messages to channel

    $pubnub->publish({
        messages => ['message1', 'message2'],
        callback => sub {
            my ($res) = @_;

            # $res is a L<Mojo::Message::Response>
            say $res->code; # 200
            say Dumper(\$res->json); # [1,"Sent","14108733777591385"]
        }
    });
    $pubnub->publish({
        channel  => 'sandbox2', # optional, if not applied, the one in ->new will be used.
        messages => ['message3', 'message4']
    });

Note if you need shared callback, please pass it when do ->new with **publish\_callback**.

new Parameters specifically for **Publish V2 ONLY**

- ortt - Origination TimeToken where "r" = DOMAIN and "t" = TIMETOKEN
- meta - any JSON payload - intended as a safe and unencrypted payload
- ear - Eat At Read (read once)
- seqn - Sequence Number - for Guaranteed Delivery/Ordering

We'll first try to read from **messages**, if not specified, fall back to the same level as messages. eg:

    $pubnub->publish({
        messages => [
            {
                message => 'test message.',
                ortt => {
                    "r" => 13,
                    "t" => "13978641831137500"
                },
                meta => {
                    "stuff" => []
                },
                ear  => 'True',
                seqn => 12345,
            },
            {
                ...
            }
        ]
    });

    ## if you have common part, you can specified as the same level as messages
    $pubnub->publish({
        messages => [
            {
                message => 'test message.',
                ortt => {
                    "r" => 13,
                    "t" => "13978641831137500"
                },
                seqn => 12345,
            },
            {
                ...
            }
        ],
        meta => {
            "stuff" => []
        },
        ear  => 'True',
    });

## history

fetches historical messages of a channel

- sub\_key

    optional, default will use the one passed to ->new

- channel

    optional, default will use the one passed to ->new

- count

    Specifies the number of historical messages to return. The Default is 100.

- reverse

    Setting to true will traverse the time line in reverse starting with the newest message first. Default is false. If both start and end arguments are provided, reverse is ignored and messages are returned starting with the newest message.

- start

    Time token delimiting the start of time slice (exclusive) to pull messages from.

- end

    Time token delimiting the end of time slice (inclusive) to pull messages from.

Sample code:

    my $history = $pubnub->history({
        count => 20,
        reverse => "false"
    });
    # $history is [["message1", "message2", ... ],"Start Time Token","End Time Token"]

for example, to fetch all the rows in history

    my $history = $pubnub->history({
        reverse => "true",
    });
    while (1) {
        print Dumper(\$history);
        last unless @{$history->[0]}; # no messages
        sleep 1;
        $history = $pubnub->history({
            reverse => "true",
            start => $history->[2]
        });
    }

# GITHUB

[https://github.com/binary-com/perl-pubnub-pubsub](https://github.com/binary-com/perl-pubnub-pubsub)

# AUTHOR

Binary.com <fayland@gmail.com>

# LICENSE AND COPYRIGHT

Copyright 2014- binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
