package t::await;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use Eventer;
use PromiseTest;

# use parent qw(Test::Class);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

my $eventer = Eventer->new();

my $resolve;

my @checkers;

my $promise = Promise::ES6->new(sub {
    ($resolve) = @_;

    push @checkers, sub {
        if ($eventer->has_happened('waited') && !$eventer->has_happened('resolved')) {
            $eventer->happen('resolved');
            $resolve->(123);
        }
    };
});

my $promise2 = $promise->then( sub {
    push @checkers, sub {
        if ($eventer->has_happened('waited2') && !$eventer->has_happened('resolved2')) {
            $eventer->happen('resolved2');
        }
    };

    return Promise::ES6->new( sub {
        my ($res) = @_;

        push @checkers, sub {
            if ($eventer->has_happened('waited3') && !$eventer->has_happened('resolved3')) {
                $eventer->happen('resolved3');
                $res->(456);
            }
        };
    } );
} );

my $pid = fork or do {
    Time::HiRes::sleep(0.1);
    $eventer->happen('waited');

    $eventer->wait_until('resolved');

    $eventer->happen('waited2');

    $eventer->wait_until('resolved2');

    $eventer->happen('waited3');

    exit;
};

isa_ok $promise, 'Promise::ES6';
is PromiseTest::await($promise, \@checkers), 123, 'get resolved value';
is PromiseTest::await($promise2, \@checkers), 456, 'get resolved value from returned sub-promise';

# To avoid a leak in Devel::Cover:
@checkers = ();

waitpid $pid, 0;

done_testing();

1;
