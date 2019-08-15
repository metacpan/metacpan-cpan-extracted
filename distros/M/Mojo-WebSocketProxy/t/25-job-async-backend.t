use strict;
use warnings;

use t::TestWSP qw/test_wsp/;
use curry;
use Test::More;
use Test::Fatal;
use Test::Mojo;
use JSON::MaybeUTF8 ':v1';
use Mojo::IOLoop;
use IO::Async::Loop::Mojo;

our @PENDING_JOBS;

my $loop = IO::Async::Loop::Mojo->new;
our $LAST_ID = 999;

package t::SampleClient {
    use parent qw(Job::Async::Client);

    sub loop { shift->{loop} //= $loop }
    sub start { Future->done }

    sub submit {
        my ($self, %args) = @_;
        push @::PENDING_JOBS,
            my $job = Job::Async::Job->new(
            data   => \%args,
            id     => ++$LAST_ID,
            future => $self->loop->new_future,
            );
        $job->future;
    }
};

package t::SampleWorker {
    use parent qw(Job::Async::Worker);
    use Future::Utils qw(repeat);

    sub loop { shift->{loop} //= $loop }

    sub start { Future->done }

    sub trigger {
        my ($self) = @_;
        $self->{active} ||= (
            repeat {
                if (my $job = shift(@::PENDING_JOBS)) {
                    $self->process($job);
                }
                return Future->done;
            }
            while => sub { 0 + @::PENDING_JOBS }
            )->on_ready(
            sub {
                delete $self->{active};
            });
    }

    sub process {
        my ($self, $job) = @_;
        $self->jobs->emit($job);
    }
};

package t::FrontEnd {
    use base 'Mojolicious';

    use Mojo::WebSocketProxy::Backend::JobAsync;

    sub startup {
        my $self = shift;

        my $url = $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined");
        (my $url2 = $url) =~ s{/rpc/}{/rpc2/};

        my $client = t::SampleClient->new;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [['success'], ['faraway', {backend => "via_job_async"}],],
                backends => {
                    via_job_async => {
                        type   => 'job_async',
                        client => $client
                    },
                },
                base_path => '/api',
                url       => $url,
            });
    }
};

test_wsp {
    my ($t) = @_;
    $t->websocket_ok('/api' => {});
    $t->send_ok({json => {success => 1}})->message_ok;
    is(decode_json_utf8($t->message->[1])->{success}, 'success-reply');

    is(
        exception {
            my $worker        = t::SampleWorker->new;
            my @job_callbacks = (
                sub {
                    my ($job) = @_;
                    is($job->id,           1000,      'have correct ID');
                    is($job->data('name'), 'faraway', 'method name was correct');
                    $job->done(encode_json_utf8({result => 'everything worked'}));
                },
                sub {
                    my ($job) = @_;
                    is($job->id,           1001,      'have correct ID');
                    is($job->data('name'), 'faraway', 'method name was correct');
                    $job->fail(encode_json_utf8({error => {code => 'WrongResponse'}}));
                });
            my $handler = $worker->jobs->each(
                sub {
                    my ($job) = @_;
                    is(
                        exception {
                            ok(0 + @job_callbacks, 'had some callbacks waiting');
                            shift(@job_callbacks)->($job);
                        },
                        undef,
                        'job handling was quite happy'
                    );
                });
            note 'Trigger worker once before we send the message';
            $worker->trigger;

            $t->send_ok({json => {faraway => 1}});
            Mojo::IOLoop->one_tick until @PENDING_JOBS;
            $worker->trigger;
            $t->message_ok;
            is(decode_json_utf8($t->message->[1])->{faraway}, 'everything worked');

            $t->send_ok({json => {faraway => 1}});
            Mojo::IOLoop->one_tick until @PENDING_JOBS;
            $worker->trigger;
            $t->message_ok;
            is(decode_json_utf8($t->message->[1])->{error}{code}, 'WrongResponse');
        },
        undef,
        'no exceptions when decoding the Job::Async response'
    ) or note explain $t->message->[1];
}
't::FrontEnd';

done_testing;

1;
