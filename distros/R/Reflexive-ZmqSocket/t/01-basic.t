use warnings;
use strict;

use Test::More;

{
    package App::Test;
    use Moose;
    extends 'Reflex::Base';
    use Reflex::Trait::Watched qw/ watches /;
    use Reflexive::ZmqSocket::ReplySocket;
    use Reflexive::ZmqSocket::RequestSocket;
    use ZeroMQ::Constants(':all');

    watches request => (
        isa => 'Reflexive::ZmqSocket::RequestSocket',
        clearer => 'clear_request',
        predicate => 'has_request',
    );

    watches reply => (
        isa => 'Reflexive::ZmqSocket::ReplySocket',
        clearer => 'clear_reply',
        predicate => 'has_reply',
    );
    
    for(qw/ping pong pang pung/)
    {
        has "$_"  => (
            is => 'ro',
            isa => 'Bool',
            traits => ['Bool'],
            default => 0,
            handles => { "toggle_$_" => 'toggle' },
        );
    }

    sub init {
        my ($self) = @_;

        my $rep = Reflexive::ZmqSocket::ReplySocket->new(
            endpoints => [ 'tcp://127.0.0.1:54321' ],
            endpoint_action => 'connect',
            socket_options => {
                +ZMQ_LINGER ,=> 1,
            },
        );

        my $req = Reflexive::ZmqSocket::RequestSocket->new(
            endpoints => [ 'tcp://127.0.0.1:54321' ],
            endpoint_action => 'bind',
            socket_options => {
                +ZMQ_LINGER ,=> 1,
            },
        );

        $self->request($req);
        $self->reply($rep);
    }

    sub clear {
        my ($self) = @_;
        $self->ignore($self->request) if $self->has_request;
        $self->ignore($self->reply) if $self->has_reply;
        $self->clear_request;
        $self->clear_reply;
    }

    sub BUILD {
        my ($self) = @_;
        
        $self->clear();
        $self->init();
    }

    sub on_reply_message {
        my ($self, $msg) = @_;
        return if $self->ping;
        $self->toggle_ping;
        $self->reply->send($msg->data + 1);
    }

    sub on_reply_multipart_message {
        my ($self, $msg) = @_;
        if($msg->count_parts == 3)
        {
            my @parts = map { $_->data } $msg->all_parts;
            Test::More::is_deeply(\@parts, [1,2,3], 'Multipart request is in order');
            $self->toggle_pang;
            $self->reply->send([3,2,1]);
        }
    }

    sub on_request_message {
        my ($self, $msg) = @_;
        $self->toggle_pong;
        $self->request->send([1, 2, 3]);
    }

    sub on_request_multipart_message {
        my ($self, $msg) = @_;
        if($msg->count_parts == 3)
        {
            my @parts = map { $_->data } $msg->all_parts;
            Test::More::is_deeply(\@parts, [3,2,1], 'Multipart response is in order');
            $self->toggle_pung;
            $self->request->send(2);
        }
    }

    sub on_request_socket_flushed {
        my ($self) = @_;
        if($self->pung)
        {
            $self->clear();
        }
    }
    
    sub on_reply_socket_flushed {
        my ($self) = @_;
        if($self->pung)
        {
            $self->clear();
        }
    }

    sub on_reply_socket_error {
        my ($self, $msg) = @_;
        Test::More::BAIL_OUT("There should never be a reply socket error: \n" . $msg->dump);
    }

    sub on_request_socket_error {
        my ($self, $msg) = @_;
        Test::More::BAIL_OUT("There should never be a request socket error: \n" . $msg->dump);
    }

    sub on_reply_bind_error {
        my ($self, $msg) = @_;
        Test::More::BAIL_OUT("There should never be a reply bind socket error: \n" . $msg->dump);
    }

    sub on_reply_connect_error {
        my ($self, $msg) = @_;
        Test::More::BAIL_OUT("There should never be a reply connect socket error: \n" . $msg->dump);
    }

    sub on_request_connect_error {
        my ($self, $msg) = @_;
        Test::More::BAIL_OUT("There should never be a request connect socket error: \n" . $msg->dump);
    }

    sub on_request_bind_error {
        my ($self, $msg) = @_;
        Test::More::BAIL_OUT("There should never be a request bind socket error: \n" . $msg->dump);
    }

    __PACKAGE__->meta->make_immutable();
}

my $app = App::Test->new();
$app->request->send(1);
$app->run_all();

ok($app->ping, 'Successfully set ping');
ok($app->pong, 'Successfully set pong');
ok($app->pang, 'Successfully set pang');
ok($app->pung, 'Successfully set pung');

done_testing();

