# NAME

Net::AMQP::RabbitMQ::PP - Pure perl AMQP client for RabbitMQ

<div>

    <a href='https://travis-ci.org/Humanstate/net-amqp-rabbitmq?branch=master'><img src='https://travis-ci.org/Humanstate/net-amqp-rabbitmq.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/Humanstate/net-amqp-rabbitmq?branch=master'><img src='https://coveralls.io/repos/Humanstate/net-amqp-rabbitmq/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    use Net::AMQP::RabbitMQ::PP;

    my $connection = Net::AMQP::RabbitMQ::PP->new();
    $connection->connect;
    $connection->basic_publish(
        payload => "Foo",
        routing_key => "foo.bar",
    );
    $connection->disconnect

# DESCRIPTION

Like [Net::RabbitMQ](https://metacpan.org/pod/Net::RabbitMQ) but pure perl rather than a wrapper around librabbitmq.

# VERSION

0.09

# SUBROUTINES/METHODS

A list of methods with their default arguments (undef = no default)

## new

Loads the AMQP protocol definition, primarily. Will not be an active
connection until ->connect is called.

        my $mq = Net::AMQP::RabbitMQ::PP->new;

## connect

Connect to the server. Default arguments are shown below:

        $mq->connect(
                host           => "localhost",
                port           => 5672,
                timeout        => undef,
                username       => 'guest',
                password       => 'guest',
                virtualhost    => '/',
                heartbeat      => undef,
                socket_timeout => 5,
        );

connect can also take a secure flag for SSL connections, this will only work if
[IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) is available. You can also pass SSL specific arguments through
in the connect method and these will be passed through

        $mq->connect(
                ...
                secure => 1,
                SSL_blah_blah => 1,
        );

## disconnect

Disconnects from the server

        $mq->disconnect;

## set\_keepalive

Set a keep alive poller. Note: requires [Socket::Linux](https://metacpan.org/pod/Socket::Linux)

        $mq->set_keepalive(
                idle     => $secs, # time between last meaningful packet and first keep alive
                count    => $n,    # number of failures to allow,
                interval => $secs, # time between keep alives
        );

## receive

Receive the nextframe

        my $rv = $mq->receive;

Content or $rv will look something like:

        {
                payload              => $str,
                content_header_frame => Net::AMQP::Frame::Header,
                delivery_frame       => Net::AMQP::Frame::Method,
        }

## channel\_open

Open the given channel:

        $mq->channel_open( channel => undef );

## exchange\_declare

Instantiate an exchange with a previously opened channel:

        $mq->exchange_declare(
                channel            => undef,
                exchange           => undef,
                exchange_type      => undef,
                passive            => undef,
                durable            => undef,
                auto_delete        => undef,
                internal           => undef,
                alternate_exchange => undef,
        );

## exchange\_delete

Delete a previously instantiated exchange

        $mq->exchange_delete(
                channel   => undef,
                exchange  => undef,
                if_unused => undef,
        );

## queue\_declare

        $mq->exchange_declare(
                channel     => undef,
                queue       => undef,
                exclusive   => undef,
                passive     => undef,
                durable     => undef,
                auto_delete => undef,
                expires     => undef,
                message_ttl => undef,
        );

## queue\_bind

        $mq->queue_bind(
                channel     => undef,
                queue       => undef,
                exchange    => undef,
                routing_key => undef,
                headers     => {},
                x_match     => undef,
        );

## queue\_delete

        $mq->queue_delete(
                channel   => undef,
                queue     => undef,
                if_empty  => undef,
                if_unused => undef,
        );

## queue\_unbind

        $mq->queue_bind(
                channel     => undef,
                queue       => undef,
                exchange    => undef,
                routing_key => undef,
                headers     => {},
                x_match     => undef,
        );

## queue\_purge

        $mq->queue_purge(
                channel => undef,
                queue   => undef,
        );

## basic\_ack

        $mq->basic_ack(
                channel      => undef,
                delivery_tag => undef,
                multiple     => undef,
        );

## basic\_cancel\_callback

        $mq->basic_cancel_callback(
                callback => undef,
        );

## basic\_cancel

        $mq->basic_cancel(
                channel      => undef,
                queue        => undef,
                consumer_tag => undef,
        );

## basic\_get

        $mq->basic_get(
                channel => undef,
                queue   => undef,
                no_ack  => undef,
        );

## basic\_publish

        $mq->basic_publish(
                channel     => undef,
                payload     => undef,
                exchange    => undef,
                routing_key => undef,
                mandatory   => undef,
                immediate   => undef,
                props       => {
                        content_type     => undef,
                        content_encoding => undef,
                        headers          => undef,
                        delivery_mode    => undef,
                        priority         => undef,
                        correlation_id   => undef,
                        reply_to         => undef,
                        expiration       => undef,
                        message_id       => undef,
                        timestamp        => undef,
                        type             => undef,
                        user_id          => undef,
                        app_id           => undef,
                        cluster_id       => undef,
                },
        );

## basic\_consume

        $mq->basic_consume(
                channel      => undef,
                queue        => undef,
                consumer_tag => undef,
                exclusive    => undef,
                no_ack       => undef,
        );

## basic\_reject

        $mq->basic_reject(
                channel      => undef,
                delivery_tag => undef,
                requeue      => undef,
        );

## basic\_qos

        $mq->basic_qos(
                channel        => undef,
                global         => undef,
                prefetch_count => undef,
                prefetch_size  => undef,
        );

## transaction\_select

## transaction\_commit

## transaction\_rollback

## confirm\_select

All take channel => $channel as args.

## heartbeat

TODO

# BUGS, LIMITATIONS, AND CAVEATS

Please report all bugs to the issue tracker on github.
https://github.com/Humanstate/net-amqp-rabbitmq/issues

One known limitation is that we cannot automatically send heartbeat frames in
a useful way.

A caveat is that I (LEEJO) didn't write this, I just volunteered to take
over maintenance and upload to CPAN since it is used in our stack. So I
apologize for the poor documentation. Have a look at the tests if any of the
documentation is not clear.

Another caveat is that the tests require MQHOST=a.rabbitmq.host to be of any
use, they used to default to dev.rabbitmq.com but that is currently MIA. If
MQHOST is not set they will be skipped.

# SUPPORT

Use the issue tracker on github to reach out for support.
https://github.com/Humanstate/net-amqp-rabbitmq/issues

# AUTHOR

Originally:

        Eugene Marcotte
        athenahealth
        emarcotte@athenahealth.com
        http://athenahealth.com

Current maintainer:

        leejo@cpan.org

Contributors:

        Ben Kaufman
        Jonathan Briggs

# LICENSE AND COPYRIGHT

Copyright 2013 Eugene Marcotte

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

# SEE ALSO

[Net::RabbitMQ](https://metacpan.org/pod/Net::RabbitMQ)

[Net::AMQP](https://metacpan.org/pod/Net::AMQP)
