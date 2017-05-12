package Plack::Test::AnyEvent::Test;

use strict;
use warnings;
use parent 'Test::Class';

use AnyEvent;
use HTTP::Request::Common;
use Test::Exception;
use Test::More;
use Plack::Test;

sub startup :Test(startup) {
    my ( $self ) = @_;

    $Plack::Test::Impl = $self->impl_name;

    my $timer = AnyEvent->timer(
        after => 1,
        cb    => sub {},
    ); # just get the ball rolling

    diag "Running on $AnyEvent::MODEL";

    do {
        no warnings 'once'; ## no critic (TestingAndDebugging::ProhibitNoWarnings)
        $EV::DIED = sub {
            unless($@ =~ /bad apple/) {
                warn $@;
            }
        };
        $Event::DIED = sub {
            my ( undef, $error ) = @_;

            unless($error =~ /bad apple/ || $error eq '?') {
                warn $error;
            }
        };

        eval { Glib->install_exception_handler(sub {
            my ( $error ) = @_;

            unless($error =~ /bad apple/) {
                warn $error;
            }
            return 1;
        })};
    };
}

sub test_simple_app :Test(3) {
    my $app = sub {
        return [
            200,
            ['Content-Type' => 'text/plain'],
            ['OK'],
        ];
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
        is $res->content_type, 'text/plain';
        is $res->content, 'OK';
    };
}

sub test_delayed_app :Test(3) {
    my $app = sub {
        return sub {
            my ( $respond ) = @_;

            my $timer;
            $timer = AnyEvent->timer(
                after => 1,
                cb    => sub {
                    undef $timer;
                    $respond->([
                        200,
                        ['Content-Type' => 'text/plain'],
                        ['OK'],
                    ]);
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
        is $res->content_type, 'text/plain';
        is $res->content, 'OK';
    };

}

sub test_streaming_app :Test(6) {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            my $writer = $respond->([
                200,
                ['Content-Type' => 'text/plain'],
            ]);
            my $timer;
            my $i  = 0;

            $timer = AnyEvent->timer(
                interval => 1,
                cb       => sub {
                    $writer->write($i++);
                    if($i > 2) {
                        $writer->close;
                        undef $timer;
                    }
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
        is $res->content_type, 'text/plain';
        is $res->content, '';

        my $i = 0;
        $res->on_content_received(sub {
            my ( $chunk ) = @_;
            is $chunk, $i++;
        });
        $res->recv;
    };
}

sub test_infinite_app :Test(6) {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            my $writer = $respond->([
                200,
                ['Content-Type' => 'text/plain'],
            ]);
            my $timer;
            my $i  = 0;
            $timer = AnyEvent->timer(
                interval => 1,
                cb       => sub {
                    local $SIG{__WARN__} = sub {}; # $writer complains if its
                                                   # been closed, and
                                                   # rightfully so.  We just
                                                   # don't want trouble during
                                                   # testing.
                    $writer->write($i++);
                    ( undef ) = $timer; # keep a reference to $timer
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
        is $res->content_type, 'text/plain';
        is $res->content, '';

        my $i = 0;
        $res->on_content_received(sub {
            my ( $chunk ) = @_;
            is $chunk, $i++;
            if($i > 2) {
                $res->send;
            }
        });
        $res->recv;
    };
}

sub test_bad_app :Test(1) {
    my $app = sub {
        die "bad apple";
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        throws_ok {
            $cb->(GET '/');
        } qr/bad apple/;
    };
}

sub test_responsible_app :Test {
    my $app = sub {
        eval {
            die "good apple";
        };
        return [
            200,
            ['Content-Type' => 'text/plain'],
            ['All Alright'],
        ];
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
    };
}

sub test_bad_delayed_app :Test {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            my $timer;
            $timer = AnyEvent->timer(
                after => 0.5,
                cb    => sub {
                    undef $timer;
                    die "bad apple";
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        throws_ok {
            my $res = $cb->(GET '/');
        } qr/bad apple/;
    };
}

sub test_responsible_delayed_app :Test {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            my $timer;
            $timer = AnyEvent->timer(
                after => 0.5,
                cb    => sub {
                    undef $timer;
                    eval {
                        die "bad apple";
                    };
                    $respond->([
                        200,
                        ['Content-Type' => 'text/plain'],
                        ['All Alright'],
                    ]);
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
    };
}

sub test_bad_app_die_post_response :Test(2) {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            my $timer;
            $timer = AnyEvent->timer(
                after => 0.5,
                cb    => sub {
                    undef $timer;
                    $respond->([
                        200,
                        ['Content-Type' => 'text/plain'],
                        'Hey!',
                    ]);
                    die "bad apple";
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        throws_ok {
            $cb->(GET '/');
        } qr/bad apple/;
    };
}

sub test_responsible_app_die_post_response :Test(2) {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            my $timer;
            $timer = AnyEvent->timer(
                after => 0.5,
                cb    => sub {
                    undef $timer;
                    $respond->([
                        200,
                        ['Content-Type' => 'text/plain'],
                        ['Hey!'],
                    ]);
                    eval {
                        die "bad apple";
                    };
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
        like $res->content, qr/Hey!/;
    };
}

sub test_bad_app_die_in_response :Test(2) {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            die "bad apple";
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        throws_ok {
            $cb->(GET '/');
        } qr/bad apple/;
    };
}

sub test_responsible_app_die_in_response :Test(2) {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            eval {
                die "bad apple";
            };
            $respond->([
                200,
                ['Content-Type' => 'text/plain'],
                ['All Alright'],
            ]);
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
        like $res->content, qr/All Alright/;
    };
}

sub test_bad_app_streaming :Test(2) {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            my $timer;
            $timer = AnyEvent->timer(
                after => 0.5,
                cb    => sub {
                    my $writer = $respond->([
                        200,
                        ['Content-Type' => 'text/plain'],
                    ]);

                    $timer = AnyEvent->timer(
                        after => 0.5,
                        cb    => sub {
                            undef $timer;
                            die "bad apple";
                        },
                    );
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        my $timer = AnyEvent->timer(
            after => 5,
            cb    => sub {
                $res->send; # self-inflicted timeout
            },
        );
        is $res->code, 200;
        $res->on_content_received(sub {
            # no-op
        });
        throws_ok {
            $res->recv;
        } qr/bad apple/;
    };
}

sub test_responsible_app_streaming :Test(2) {
    my $app = sub {
        my ( $env ) = @_;

        return sub {
            my ( $respond ) = @_;

            my $timer;
            $timer = AnyEvent->timer(
                after => 0.5,
                cb    => sub {
                    my $writer = $respond->([
                        200,
                        ['Content-Type' => 'text/plain'],
                    ]);

                    $timer = AnyEvent->timer(
                        after => 0.5,
                        cb    => sub {
                            eval {
                                die "bad apple";
                            };
                            $writer->write('All Alright');
                            $writer->close;
                            undef $timer;
                        },
                    );
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200;
        $res->on_content_received(sub {
            # no-op
        });
        lives_ok {
            $res->recv;
        };
    };
}

sub test_infinite_request_shutdown :Test {
    my $app = sub {
        return sub {
            my ( $respond ) = @_;

            my $writer = $respond->([
                200,
                ['Content-Type' => 'text/plain'],
            ]);

            my $timer;
            my $count = 0;
            $timer = AnyEvent->timer(
                interval => 0.1,
                cb       => sub {
                    $writer->write($count++);
                    ( undef ) = ( $timer ); ## keep a reference to $timer around
                },
            );
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');

        my $expecting_call = 1;
        my $seen_bad_call;

        $res->on_content_received(sub {
            my ( $chunk ) = @_;

            unless($expecting_call) {
                $seen_bad_call = 1;
            }

            if($chunk >= 5) {
                $res->send;
            }
        });

        $res->recv;

        $expecting_call = 0;

        my $res2 = $cb->(GET '/');

        $res2->on_content_received(sub {
            my ( $chunk ) = @_;

            if($chunk >= 5) {
                $res2->send;
            }
        });

        $res2->recv;

        ok !$seen_bad_call, "Don't want to see a callback after I've finished testing it";
    };
}

sub test_three_element_delayed_response :Test(3) {
    my $app = sub {
        return sub {
            my ( $respond ) = @_;

            $respond->([
                200,
                [ 'Content-Type' => 'text/plain' ],
                ['OK']
            ]);
        };
    };

    test_psgi $app, sub {
        my ( $cb ) = @_;

        my $res = $cb->(GET '/');
        $res->on_content_received(sub{
            is $res->code, 200, 'Status code should match';
            is $res->content_type, 'text/plain', 'Content-Type header should match';
            is $res->content, 'OK', 'Content should match';
        });
        $res->recv;
    };
}

1;
