use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Eventer;
use PromiseTest;

use Promise::ES6;

my $eventer = Eventer->new();

my @checkers;

my $p = Promise::ES6->new(sub {
    (undef, my $reject) = @_;

    push @checkers, sub {
        if ($eventer->has_happened('thing')) {
            $reject->('oh my god!');
        }
    };
})->catch(sub {
    my ($reason) = @_;
    return $reason;
});

my $pid = fork or do {
    Time::HiRes::sleep(0.1);
    $eventer->happen('thing');
    exit;
};

is PromiseTest::await($p, \@checkers), 'oh my god!';

waitpid $pid, 0;

done_testing();
