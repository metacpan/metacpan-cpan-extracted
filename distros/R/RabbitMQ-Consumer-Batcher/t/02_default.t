use strict;
use warnings;

use Test::More tests => 15;
use Mock::Quick;

use_ok('RabbitMQ::Consumer::Batcher');

my $batch_size = 10;

my $batcher = new_ok(
    'RabbitMQ::Consumer::Batcher',
    [
        batch_size        => $batch_size/2,
        on_add            => sub {
            my ($batcher, $msg) = @_;

            if ($msg->body->payload() % 2) {
                die 'add exception';
            }

            return $msg->body->payload();
        },
        #on_add_catch      => sub {
        #    my ($batcher, $msg, $exception) = @_;

        #    note($exception);
        #},
        on_batch_complete => sub {
            my ($batcher, $batch) = @_;

            is(scalar @$batch, $batch_size/2, 'count of items in batch');
            is(join('', map {$_->value()} @$batch), '246810', 'value of items');

            die 'batch exception';
        },
        on_batch_complete_catch => sub {
            my ($batcher, $batch, $exception) = @_;

            like($exception, qr/batch exception/, 'on_batch_complete_catch');
        }
    ]
);

my $consume_code = $batcher->consume_code();

my $consumer_mock = qstrict(
    ack                  => qmeth {
        my (undef, $msg) = @_;

        fail("ack $msg->{deliver}{method_frame}{delivery_tag}")
    },
    reject               => qmeth {
        my (undef, $msg) = @_;

        pass("reject $msg->{deliver}{method_frame}{delivery_tag}")
    },
    reject_and_republish => qmeth {
        my (undef, $msg) = @_;

        pass("reject_and_republish $msg->{deliver}{method_frame}{delivery_tag}")
    },
);

for my $i (1 .. $batch_size) {
    my $body_mock = qstrict(payload => $i,);

    my $deliver_mock = qstrict(
        method_frame => qstrict(
            delivery_tag => $i
        ),
    );

    my $header_mock = qstrict(
        content_type => '',
        priority => 1,
        timestamp => time,
        user_id => 'guest',
        delivery_mode => 1,
        headers => {}
    );

    $consume_code->($consumer_mock, { header => $header_mock, body => $body_mock, deliver => $deliver_mock });
}
