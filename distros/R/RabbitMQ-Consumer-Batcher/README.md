[![Build Status](https://travis-ci.org/avast/RabbitMQ-Consumer-Batcher.svg?branch=master)](https://travis-ci.org/avast/RabbitMQ-Consumer-Batcher)
# NAME

RabbitMQ::Consumer::Batcher - batch consumer of RMQ messages

# SYNOPSIS

    use AnyEvent;
    use AnyEvent::RabbitMQ::PubSub;
    use AnyEvent::RabbitMQ::PubSub::Consumer;
    use RabbitMQ::Consumer::Batcher;

    my ($rmq_connection, $channel) = AnyEvent::RabbitMQ::PubSub::connect(
        host  => 'localhost',
        port  => 5672,
        user  => 'guest',
        pass  => 'guest',
        vhost => '/',
    );

    my $exchange = {
        exchange    => 'my_test_exchange',
        type        => 'topic',
        durable     => 0,
        auto_delete => 1,
    };

    my $queue = {
        queue       => 'my_test_queue';
        auto_delete => 1,
    };

    my $routing_key = 'my_rk';

    my $consumer = AnyEvent::RabbitMQ::PubSub::Consumer->new(
        channel        => $channel,
        exchange       => $exchange,
        queue          => $queue,
        routing_key    => $routing_key,
    );
    $consumer->init(); #declares channel, queue and binding

    my $batcher = RabbitMQ::Consumer::Batcher->new(
        batch_size              => $consumer->prefetch_count,
        on_add                  => sub {
            my ($batcher, $msg) = @_;

            my $decode_payload = decode_payload($msg->{header}, $msg->{body}->payload());
            return $decode_payload;
        },
        on_add_catch            => sub {
            my ($batcher, $msg, $exception) = @_;

            if ($exception->$_isa('failure') && $exception->{payload}{stats_key}) {
                $stats->increment($exception->{payload}{stats_key});
            }

            if ($exception->$_isa('failure') && $exception->{payload}{reject}) {
                $batcher->reject($msg);
                $log->error("consume failed - reject: $exception\n".$msg->{body}->payload());
            }
            else {
                $batcher->reject_and_republish($msg);
                $log->error("consume failed - republish: $exception");
            }
        },
        on_batch_complete       => sub {
            my ($batcher, $batch) = @_;

            path(...)->spew(join "\t", map { $_->value() } @$batch);
        },
        on_batch_complete_catch => sub {
            my ($batcher, $batch, $exception) = @_;

            $log->error("save messages to file failed: $exception");
        }
    );

    my $cv = AnyEvent->condvar();
    $consumer->consume($cv, $batcher->consume_code())->then(sub {
        say 'Consumer was started...';
    });

# DESCRIPTION

If you need batch of messages from RabbitMQ - this module is for you.

This module work well with [AnyEvent::RabbitMQ::PubSub::Consumer](https://metacpan.org/pod/AnyEvent::RabbitMQ::PubSub::Consumer)

Idea of this module is - in _on\_add_ phase is message validate and if is corrupted, can be reject.
In _on\_batch\_complete_ phase we manipulated with message which we don't miss.
If is some problem in this phase, messages are republished..

# METHODS

## new(%attributes)

### attributes

#### batch\_size

Max batch size (trigger for `on_batch_complete`)

`batch_size` must be `prefetch_count` or bigger!

this is required attribute

#### on\_add

this callback are called after consume one single message. Is usefully for decoding for example.

return value of callback are used as value in batch item ([RabbitMQ::Consumer::Batcher::Item](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Item))

default behaviour is payload of message is used as item in batch

    return sub {
        my($batcher, $msg) = @_;
        return $msg->{body}->payload()
    }

parameters which are give to callback:

- `$batcher`

    self instance of [RabbitMQ::Consumer::Batcher](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher)

- `$msg`

    consumed message ["on\_consume" in AnyEvent::RabbitMQ::Channel](https://metacpan.org/pod/AnyEvent::RabbitMQ::Channel#on_consume)

#### on\_add\_catch

this callback are called if `on_add` callback throws

default behaviour do reject message

    return sub {
        my ($batcher, $msg, $exception) = @_;

        $batcher->reject($msg);
    }

parameters which are give to callback:

- `$batcher`

    self instance of [RabbitMQ::Consumer::Batcher](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher)

- `$msg`

    consumed message ["on\_consume" in AnyEvent::RabbitMQ::Channel](https://metacpan.org/pod/AnyEvent::RabbitMQ::Channel#on_consume)

- `$exception`

    exception string

#### on\_batch\_complete

this callback is triggered if batch is complete (count of items is `batch_size`)

this is required attribute

parameters which are give to callback:

- `$batcher`

    self instance of [RabbitMQ::Consumer::Batcher](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher)

- `$batch`

    batch is _ArrayRef_ of [RabbitMQ::Consumer::Batcher::Item](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Item)

example `on_batch_complete` _CodeRef_ (item _value_ are _string_s)

    return sub {
        my($batcher, $batch) = @_;

        print join "\n", map { $_->value() } @$batch;
        $batcher->ack($batch);
    }

#### on\_batch\_complete\_catch

this callback are called if `on_batch_complete` callback throws

after this callback is batch _reject\_and\_republish_

If you need change _reject\_and\_republish_ of batch to (for example) _reject_, you can do:

    return sub {
        my ($batcher, $batch, $exception) = @_;

        $batcher->reject($batch);
        #batch_clean must be called,
        #because reject_and_republish after this exception handler will be called to...
        $batcher->batch_clean();
    }

parameters which are give to callback:

- `$batcher`

    self instance of [RabbitMQ::Consumer::Batcher](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher)

- `$batch`

    _ArrayRef_ of [RabbitMQ::Consumer::Batcher::Item](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Item)s

- `$exception`

    exception string

## consume\_code()

return `sub{}` for handling messages in `consume` method of [AnyEvent::RabbitMQ::PubSub::Consumer](https://metacpan.org/pod/AnyEvent::RabbitMQ::PubSub::Consumer)

    $consumer->consume($cv, $batcher->consume_code());

## ack(@items)

ack all `@items` (instances of [RabbitMQ::Consumer::Batcher::Item](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Item) or [RabbitMQ::Consumer::Batcher::Message](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Message))

## reject(@items)

reject all `@items` (instances of [RabbitMQ::Consumer::Batcher::Item](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Item) or [RabbitMQ::Consumer::Batcher::Message](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Message))

## reject\_and\_republish(@items)

reject and republish all `@items` (instances of [RabbitMQ::Consumer::Batcher::Item](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Item) or [RabbitMQ::Consumer::Batcher::Message](https://metacpan.org/pod/RabbitMQ::Consumer::Batcher::Message))

# contributing

for dependency use [cpanfile](https://metacpan.org/pod/cpanfile)...

for resolve dependency use [Carton](https://metacpan.org/pod/Carton) (or [Carmel](https://metacpan.org/pod/Carmel) - is more experimental)

    carton install

for run test use `minil test`

    carton exec minil test

if you don't have perl environment, is best way use docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton install
    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton exec minil test

## warning

docker run default as root, all files which will be make in docker will be have root rights

one solution is change rights in docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended bash -c "carton install; chmod -R 0777 ."

or after docker command (but you must have root rights)

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
