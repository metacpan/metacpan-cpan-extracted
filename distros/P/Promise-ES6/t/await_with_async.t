use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use Eventer;
use PromiseTest;

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

my $pid = fork or do {
    Time::HiRes::sleep(0.1);
    $eventer->happen('waited');
    exit;
};

isa_ok $promise, 'Promise::ES6';
is PromiseTest::await($promise, \@checkers), 123, 'get resolved value';

waitpid $pid, 0;

done_testing();
