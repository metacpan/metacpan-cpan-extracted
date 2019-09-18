package t::reject;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use parent qw(Test::Class);
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub reject : Tests(1) {
    Promise::ES6->reject('oh my god')->then(sub {
        die;
    }, sub {
        my ($reason) = @_;
        is $reason, 'oh my god';
    });
}

__PACKAGE__->runtests;
