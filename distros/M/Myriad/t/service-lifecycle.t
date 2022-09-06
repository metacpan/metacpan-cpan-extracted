use strict;
use warnings;

use Test::More;
use Test::Fatal qw(lives_ok exception);

use IO::Async::Loop;
use IO::Async::Test;

use Log::Any::Test;
use Log::Any qw($log);
use Log::Any::Adapter qw(TAP);

use Myriad;

my $loop = IO::Async::Loop->new();
testing_loop($loop);

sub get_myriad  {
    $ENV{MYRIAD_TRANSPORT} = 'memory';
    return Myriad->new();
}

subtest 'It should throw if it failed to find required config' => sub {

    package Should::Fail {
        use Myriad::Service;

        config 'required_config';

        async method startup {
           die 'startup should not be reachable';
        }
    };

    my $myriad = get_myriad;
    $myriad->configure_from_argv(service => 'Should::Fail')->get();
    like( exception { $myriad->run->get },
        qr/A required configuration key was not set/,
        'exception has been thrown'
    );

};

subtest 'API should be available on startup' => sub {
    package Dummy::Service {
        use Myriad::Service;
        use Test::More;

        async method startup {
            isa_ok($api, 'Myriad::API', 'API is defined at startup');
            die 'testing done';
        }
    };

    my $myriad = get_myriad;
    $myriad->configure_from_argv(service => 'Dummy::Service')->get;
    lives_ok { $myriad->run->get };
};

subtest 'diagnostics should be called after startup' => sub {
     package Diag::Test {
        use Myriad::Service;
        use Test::More;

        has $called = 0;

        async method startup {
            $called++;
        }

        async method diagnostics ($level) {
            is($called, 1, 'diagnostics has been called after startup');
            die 'testing done';
        }
    };

    my $myriad = get_myriad;
    $myriad->configure_from_argv(service => 'Diag::Test')->get;
    lives_ok { $myriad->run->get };
};

done_testing;
