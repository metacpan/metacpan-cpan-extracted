use strict;
use warnings;

use Test::More tests => 6;
use Mock::Quick;

use_ok('RabbitMQ::Consumer::Batcher');

my $batch_size = 2;

my $batcher = new_ok(
    'RabbitMQ::Consumer::Batcher',
    [
        batch_size        => $batch_size,
        on_batch_complete => sub {
            my ($batcher, $batch) = @_;

            is(scalar @$batch, $batch_size, 'count of items in batch');
            is(join('', map {$_->value()} @$batch), '12', 'value of items');
        },
        on_add_catch      => sub {
            my ($batcher, $msg, $exception) = @_;

            fail($exception);
        },
        on_batch_complete_catch => sub {
            my ($batcher, $batch, $exception) = @_;

            fail($exception);
        },
    ]
);

my $consume_code = $batcher->consume_code();

my $consumer_mock = qstrict(
    ack                  => qmeth {
        my (undef, $msg) = @_;

        pass("ack $msg->{deliver}{method_frame}{delivery_tag}")
    },
    reject               => qmeth {
        my (undef, $msg) = @_;

        fail("reject $msg->{deliver}{method_frame}{delivery_tag}")
    },
    reject_and_republish => qmeth {
        my (undef, $msg) = @_;

        fail("reject_and_republish $msg->{deliver}{method_frame}{delivery_tag}")
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
