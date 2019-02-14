use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Eventer;
use PromiseTest;

use Promise::ES6;

my $eventer = Eventer->new();

my ($resolve1, $resolve2);

my $p1 = Promise::ES6->new(sub {
    ($resolve1) = @_;
});

my $p2 = Promise::ES6->new(sub {
    ($resolve2) = @_;
});

my ($happen1, $happen2);

my @checks = (
    sub {
        if ( $eventer->has_happened('one') && !$eventer->has_happened('resolved1') ) {
            $resolve1->(1);

            $eventer->happen('resolved1');

            return 1;
        }
    },
    sub {
        if ( $eventer->has_happened('two') && !$eventer->has_happened('resolved2') ) {
            $resolve2->(2);

            $eventer->happen('resolved2');

            return 1;
        }
    },
);

my $pid = fork or do {
    $eventer->happen('two');
    $eventer->wait_until('resolved2');

    $eventer->happen('one');
    $eventer->wait_until('resolved1');

    exit;
};

my $all = Promise::ES6->all([$p1, $p2, 3]);

is_deeply( PromiseTest::await($all, \@checks), [1,2,3] );

waitpid $pid, 0;

done_testing;
