package RabbitMQ::Consumer::Batcher;
use Moose;

use namespace::autoclean;

use Try::Tiny;
use RabbitMQ::Consumer::Batcher::Item;
use RabbitMQ::Consumer::Batcher::Message;

our $VERSION = '0.1.1';

=head1 NAME

RabbitMQ::Consumer::Batcher - batch consumer of RMQ messages

=head1 SYNOPSIS

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

=head1 DESCRIPTION

If you need batch of messages from RabbitMQ - this module is for you.

This module work well with L<AnyEvent::RabbitMQ::PubSub::Consumer>

Idea of this module is - in I<on_add> phase is message validate and if is corrupted, can be reject.
In I<on_batch_complete> phase we manipulated with message which we don't miss.
If is some problem in this phase, messages are republished..

=head1 METHODS

=head2 new(%attributes)

=head3 attributes

=head4 batch_size

Max batch size (trigger for C<on_batch_complete>)

C<batch_size> must be C<prefetch_count> or bigger!

this is required attribute

=cut

has 'batch_size' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=head4 on_add

this callback are called after consume one single message. Is usefully for decoding for example.

return value of callback are used as value in batch item (L<RabbitMQ::Consumer::Batcher::Item>)

default behaviour is payload of message is used as item in batch

    return sub {
        my($batcher, $msg) = @_;
        return $msg->{body}->payload()
    }

parameters which are give to callback:

=over

=item C<$batcher>

self instance of L<RabbitMQ::Consumer::Batcher>

=item C<$msg>

consumed message L<AnyEvent::RabbitMQ::Channel/on_consume>

=back

=cut

has 'on_add' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        return sub {
            my ($batcher, $msg) = @_;
            return $msg->{body}->payload();
          }
    }
);

=head4 on_add_catch

this callback are called if C<on_add> callback throws

default behaviour do reject message

    return sub {
        my ($batcher, $msg, $exception) = @_;

        $batcher->reject($msg);
    }

parameters which are give to callback:

=over

=item C<$batcher>

self instance of L<RabbitMQ::Consumer::Batcher>

=item C<$msg>

consumed message L<AnyEvent::RabbitMQ::Channel/on_consume>

=item C<$exception>

exception string

=back

=cut

has 'on_add_catch' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        return sub {
            my ($batcher, $msg, $exception) = @_;

            $batcher->reject($msg);
        }
    }
);

=head4 on_batch_complete

this callback is triggered if batch is complete (count of items is C<batch_size>)

this is required attribute

parameters which are give to callback:


=over

=item C<$batcher>

self instance of L<RabbitMQ::Consumer::Batcher>

=item C<$batch>

batch is I<ArrayRef> of L<RabbitMQ::Consumer::Batcher::Item>

=back

example C<on_batch_complete> I<CodeRef> (item I<value> are I<string>s)

    return sub {
        my($batcher, $batch) = @_;

        print join "\n", map { $_->value() } @$batch;
        $batcher->ack($batch);
    }

=cut

has 'on_batch_complete' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

=head4 on_batch_complete_catch

this callback are called if C<on_batch_complete> callback throws

after this callback is batch I<reject_and_republish>

If you need change I<reject_and_republish> of batch to (for example) I<reject>, you can do:

    return sub {
        my ($batcher, $batch, $exception) = @_;

        $batcher->reject($batch);
        #batch_clean must be called,
        #because reject_and_republish after this exception handler will be called to...
        $batcher->batch_clean();
    }

parameters which are give to callback:

=over

=item C<$batcher>

self instance of L<RabbitMQ::Consumer::Batcher>

=item C<$batch>

I<ArrayRef> of L<RabbitMQ::Consumer::Batcher::Item>s

=item C<$exception>

exception string

=back

=cut

has 'on_batch_complete_catch' => (
    is => 'ro',
    isa => 'Maybe[CodeRef]',
);

has 'batch' => (
    is      => 'ro',
    isa     => 'ArrayRef[RabbitMQ::Consumer::Batcher::Item]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        add_to_batch         => 'push',
        clean_batch          => 'clear',
        count_of_batch_items => 'count',
        batch_as_array       => 'elements',
    }
);

=head2 consume_code()

return C<sub{}> for handling messages in C<consume> method of L<AnyEvent::RabbitMQ::PubSub::Consumer>

    $consumer->consume($cv, $batcher->consume_code());

=cut

sub consume_code {
    my ($self) = @_;

    return sub {
        my ($consumer, $msg) = @_;

        my $message = RabbitMQ::Consumer::Batcher::Message->new(
            %$msg,
            consumer => $consumer,
        );

        try {

            my $value = $self->on_add->($self, $message);

            $self->add_to_batch(
                RabbitMQ::Consumer::Batcher::Item->new(
                    value    => $value,
                    msg      => $message,
                )
            );
        }
        catch {
            $self->on_add_catch->($self, $message, $_);
        };

        if ($self->count_of_batch_items() >= $self->batch_size) {
            try {
                $self->on_batch_complete->($self, $self->batch);
                $self->ack($self->batch_as_array());
            }
            catch {
                my $exception = $_;
                if (defined $self->on_batch_complete_catch) {
                    $self->on_batch_complete_catch->($self, $self->batch, $exception);
                }
                $self->reject_and_republish($self->batch_as_array());
            }
            finally {
                $self->clean_batch();
            };
        }
    }
}

=head2 ack(@items)

ack all C<@items> (instances of L<RabbitMQ::Consumer::Batcher::Item> or L<RabbitMQ::Consumer::Batcher::Message>)

=cut

sub ack {
    my ($self, @items) = @_;

    _consumer('ack', @items);
}

=head2 reject(@items)

reject all C<@items> (instances of L<RabbitMQ::Consumer::Batcher::Item> or L<RabbitMQ::Consumer::Batcher::Message>)

=cut

sub reject {
    my ($self, @items) = @_;

    _consumer('reject', @items);
}

=head2 reject_and_republish(@items)

reject and republish all C<@items> (instances of L<RabbitMQ::Consumer::Batcher::Item> or L<RabbitMQ::Consumer::Batcher::Message>)

=cut

sub reject_and_republish {
    my ($self, @items) = @_;

    _consumer('reject_and_republish', @items);
}

sub _consumer {
    my ($action, @items) = @_;

    foreach my $item (@items) {
        if ($item->isa('RabbitMQ::Consumer::Batcher::Item')) {
            $item->msg->consumer->$action($item->msg);
        }
        elsif ($item->isa('RabbitMQ::Consumer::Batcher::Message')) {
            $item->consumer->$action($item);
        }
        else {
            die 'Unknown object (without consumer)';
        }
    }

}

=head1 contributing

for dependency use L<cpanfile>...

for resolve dependency use L<Carton> (or L<Carmel> - is more experimental)

    carton install

for run test use C<minil test>

    carton exec minil test


if you don't have perl environment, is best way use docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton install
    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton exec minil test

=head2 warning

docker run default as root, all files which will be make in docker will be have root rights

one solution is change rights in docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended bash -c "carton install; chmod -R 0777 ."

or after docker command (but you must have root rights)

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

__PACKAGE__->meta->make_immutable();

1;
