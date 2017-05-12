use strict;
use warnings;

use Test::More 0.90;

use Capture::Tiny qw/ capture_stderr /;
use HTTP::Request::Common;
use Plack::Test;

use_ok 'Plack::Middleware::LogHarakiri';

my $app = sub {
    my ($env) = @_;

    $env->{'psgix.harakiri.supported'} = 1; # legacy

    my $key = $env->{'psgix.harakiri.supported'} ?
        'psgix.harakiri' :
        'psgix.harakiri.commit';

    if ($env->{REQUEST_URI} eq '/die') {
        $env->{$key} = 1;
    }

    return [ 200,
             [ 'Content-Type' => 'text/plain' ],
             [ $env->{$key} ? 'killed' : 'not killed' ] ];

    };

ok $app = Plack::Middleware::LogHarakiri->wrap($app), 'wrap';

subtest 'log harakiri message' => sub {

    my $stderr = capture_stderr {
        test_psgi
            app    => $app,
            client => sub {
                my ($cb) = @_;
                my $req = GET 'http://localhost/die';
                my $res = $cb->($req);
                is $res->content, 'killed';
                };
        };

    like $stderr,
        qr/pid $$ committed harakiri \(size: \d+, shared: \d+, unshared: \d+\)/,
        'warning logged';

    };

subtest 'no harakiri message' => sub {

    my $stderr = capture_stderr {
        test_psgi
            app    => $app,
            client => sub {
                my ($cb) = @_;
                my $req = GET 'http://localhost/live';
                my $res = $cb->($req);
                is $res->content, 'not killed';
                };
        };

    is $stderr, '', 'no warning logged';

    };

done_testing;

