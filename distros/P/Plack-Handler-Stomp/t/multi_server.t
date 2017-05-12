#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Test::Plack::Handler::Stomp;
with 'TestApp';

has t => (
    is => 'rw',
    lazy_build => 1,
);
sub _build_t { Test::Plack::Handler::Stomp->new() }

before run_test => sub {
    my ($self) = @_;

    $self->clear_t;
    my $t = $self->t;

    $t->clear_calls_and_queues;
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
        },
        body => 'foo',
    }));
    $t->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
                path_info => '/my/path',
            },
        ],
        servers => [
            { hostname => 'first', port => 61613 },
            { hostname => 'second', port => 61613 },
        ],
        connect_retry_delay => 1,
    );
};

test 'two servers, first one dies on connection' => sub {
    my ($self) = @_;

    my $t = $self->t;

    $t->handler->connection->{__fakestomp__callbacks}{connect} = sub {
        my $args = shift;
        $t->queue_connection_call($args);
        die "Can't connect\n"
            if $t->handler->current_server->{hostname} eq 'first';
    };

    my @warns;
    {
        local $SIG{__WARN__} = sub { push @warns,@_ };
        $t->handler->run($self->psgi_test_app);
    }
    is($t->connection_calls_count,2,
       'connected twice');
    is($t->subscription_calls_count,1,
       'subscribed once');
    is($t->frames_left_to_receive,0,
       'message consumed');
    is($t->sent_frames_count,1,
       'message ACKed');
    is(scalar(@warns),1,'one warning');
    like($warns[0],qr{\Aconnection problems\b.*?\bCan't connect\b},
         'correct warning');
};

test 'two servers, first one dies on subscribe' => sub {
    my ($self) = @_;

    my $t = $self->t;

    $t->handler->connection->{__fakestomp__callbacks}{subscribe} = sub {
        my $args = shift;
        $t->queue_subscription_call($args);
        die "Can't subscribe\n"
            if $t->handler->current_server->{hostname} eq 'first';
    };

    my @warns;
    {
        local $SIG{__WARN__} = sub { push @warns,@_ };
        $t->handler->run($self->psgi_test_app);
    }

    is($t->connection_calls_count,2,
       'connected twice');
    is($t->subscription_calls_count,2,
       'subscribed twice');
    is($t->frames_left_to_receive,0,
       'message consumed');
    is($t->sent_frames_count,1,
       'message ACKed');
    is(scalar(@warns),1,'one warning');
    like($warns[0],qr{\Aconnection problems\b.*?\bCan't subscribe\b},
         'correct warning');
};

run_me;
done_testing;
