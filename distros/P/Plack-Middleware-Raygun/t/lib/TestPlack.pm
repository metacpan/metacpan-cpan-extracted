package TestPlack;

use strict;
use warnings;
use parent qw(Test::Class);

use Test::More;
use Test::Deep;    # (); # uncomment to stop prototype errors
use Test::Exception;
use Test::MockModule;
use Plack::Test;

use HTTP::Request;

#use Smart::Comments;

sub t0005_use_middleware : Test(1) {
    my $self = shift;
    use_ok('Plack::Middleware::Raygun')
        or $self->FAIL_ALL('Could not load middleware');
}

sub t0010_response_ok : Test(2) {
    my $self = shift;

    my $app = sub {
        return [ 200, [ 'Content-Type', 'text/plain' ], ['Hello'] ];
    };
    lives_ok {
        $app = Plack::Middleware::Raygun->wrap($app);
    }
    'Wrapped middleware around app';

    test_psgi $app, sub {
        my $cb  = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        is($res->code, 200);
        }
}

sub t0020_response_error : Test(4) {
    my $self = shift;

    my $app = sub {
        die "Some error";
        return [ 200, [ 'Content-Type', 'text/plain' ], ['Hello'] ];
    };
    lives_ok {
        $app = Plack::Middleware::Raygun->wrap($app);
    }
    'Wrapped middleware around app';

    test_psgi $app, sub {

        my $module = Test::MockModule->new('WebService::Raygun::Messenger');
        $module->mock(
            'fire_raygun',
            sub {
                my $self    = shift;
                my $message = $self->message->prepare_raygun;
                ### message : $message
                cmp_deeply(
                    $message,
                    superhashof({
                            occurredOn => ignore(),
                            details    => superhashof({
                                    error => superhashof({
                                            message => re(qr{Some\serror})
                                        }) }) }
                    ),
                    'Message has the same text as die above.'
                );

                pass('Called the fire_raygun method as expected.');
            });

        my $cb  = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        ### response : $res
        is($res->code, 500);
        $module->unmock_all();
        }
}

sub t0030_argument_in_builder : Test(3) {
    my $self = shift;
    my $app  = sub {
        die "Some error";
        return [ 200, [ 'Content-type', 'text/html' ], ['Hello'] ];
    };

    lives_ok {
        $app = Plack::Middleware::Raygun->wrap($app, api_key => 'whatever');
    }
    'Wrapped middleware around app';

    test_psgi $app, sub {
        my $module = Test::MockModule->new('WebService::Raygun::Messenger');
        $module->mock(
            'fire_raygun',
            sub {
                my $self    = shift;
                my $api_key = $self->api_key;
                ### called sub : $api_key
                if ( $api_key and $api_key eq 'whatever' ) {
                    pass('Found api key');
                }
                else {
                    fail('API key not passed through!');
                }
            }
        );
        my $cb  = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        ### response : $res
        is($res->code, 500);
        $module->unmock_all();
      }
}


1;

__END__
