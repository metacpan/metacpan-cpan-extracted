use strict;
use warnings;

use t::TestWSP qw/test_wsp/;
use Test::More;
use Test::Mojo;
use JSON::XS;
use Mojo::IOLoop;
use Future;

subtest "w/o before-forward" => sub {

    package t::FrontEnd1 {
        use base 'Mojolicious';

        sub startup {
            my $self = shift;
            $self->plugin(
                'web_socket_proxy' => {
                    actions   => [['success'],],
                    base_path => '/api',
                    url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
                });
        }
    };

    test_wsp {
        my ($t) = @_;
        $t->websocket_ok('/api' => {});
        $t->send_ok({json => {success => 1}})->message_ok;
        is decode_json($t->message->[1])->{success}, 'success-reply';
    }
    't::FrontEnd1';
};

subtest "simple before-forward (allows forward)" => sub {

    package t::FrontEnd2 {
        use base 'Mojolicious';

        sub startup {
            my $self = shift;
            $self->plugin(
                'web_socket_proxy' => {
                    before_forward => [sub { return }],
                    actions        => [['success'],],
                    base_path      => '/api',
                    url => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
                });
        }
    };

    test_wsp {
        my ($t) = @_;
        $t->websocket_ok('/api' => {});
        $t->send_ok({json => {success => 1}})->message_ok;
        is decode_json($t->message->[1])->{success}, 'success-reply';
    }
    't::FrontEnd2';
};

subtest "simple before-forward (prohibits forward)" => sub {

    package t::FrontEnd3 {
        use base 'Mojolicious';

        sub startup {
            my $self = shift;
            $self->plugin(
                'web_socket_proxy' => {
                    before_forward => [sub { return {"non-authorized" => 'by-some-reason'} }],
                    actions        => [['success'],],
                    base_path      => '/api',
                    url => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
                });
        }
    };

    test_wsp {
        my ($t) = @_;
        $t->websocket_ok('/api' => {});
        $t->send_ok({json => {success => 1}})->message_ok;
        is decode_json($t->message->[1])->{"non-authorized"}, 'by-some-reason';
    }
    't::FrontEnd3';
};

subtest "future-based before-forward (immediate success)" => sub {

    package t::FrontEnd4 {
        use base 'Mojolicious';

        sub startup {
            my $self = shift;
            $self->plugin(
                'web_socket_proxy' => {
                    before_forward => [sub { return Future->done }],
                    actions        => [['success'],],
                    base_path      => '/api',
                    url => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
                });
        }
    };

    test_wsp {
        my ($t) = @_;
        $t->websocket_ok('/api' => {});
        $t->send_ok({json => {success => 1}})->message_ok;
        is decode_json($t->message->[1])->{success}, 'success-reply';
    }
    't::FrontEnd4';
};

subtest "future-based before-forward (immediate error)" => sub {

    package t::FrontEnd5 {
        use base 'Mojolicious';

        sub startup {
            my $self = shift;
            $self->plugin(
                'web_socket_proxy' => {
                    before_forward => [sub { return Future->fail({"non-authorized" => 'by-some-reason'}) }],
                    actions        => [['success'],],
                    base_path      => '/api',
                    url => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
                });
        }
    };

    test_wsp {
        my ($t) = @_;
        $t->websocket_ok('/api' => {});
        $t->send_ok({json => {success => 1}})->message_ok;
        is decode_json($t->message->[1])->{"non-authorized"}, 'by-some-reason';
    }
    't::FrontEnd5';
};

subtest "future-based before-forward (delayed fail)" => sub {

    package t::FrontEnd6 {
        use base 'Mojolicious';

        sub startup {
            my $self = shift;
            $self->plugin(
                'web_socket_proxy' => {
                    before_forward => [
                        sub {
                            my $f  = Future->new;
                            my $id = Mojo::IOLoop->timer(
                                0.1,
                                sub {
                                    $f->fail({"non-authorized" => 'by-some-reason'});
                                });
                            return $f;
                        }
                    ],
                    actions   => [['success'],],
                    base_path => '/api',
                    url       => $ENV{T_TestWSP_RPC_URL} // die("T_TestWSP_RPC_URL is not defined"),
                });
        }
    };

    test_wsp {
        my ($t) = @_;
        $t->websocket_ok('/api' => {});
        $t->send_ok({json => {success => 1}})->message_ok;
        is decode_json($t->message->[1])->{"non-authorized"}, 'by-some-reason';
    }
    't::FrontEnd6';
};

done_testing;
