use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use Eventer;
use PromiseTest;

use Promise::ES6;

my $eventer = Eventer->new();

my $test_value = 'first';

my @todo;

my $p = Promise::ES6->new(sub {
    my ($resolve, $reject) = @_;

    push @todo, sub {
        if ($eventer->has_happened('ready1') && !$eventer->has_happened('resolved1')) {
            is $test_value, 'first';
            $test_value = 'second';
            $resolve->('first resolve');
            $eventer->happen('resolved1');
        }
    };
});

my $pid = fork or do {
    Time::HiRes::sleep(0.2);
    $eventer->happen('ready1');

    exit;
};

is( PromiseTest::await($p, \@todo), 'first resolve' );

waitpid $pid, 0;

done_testing;
