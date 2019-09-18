package t::then;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;
use parent qw(Test::Class);

use Time::HiRes;

use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub already_resolved : Tests {
    my $called = 0;
    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->('executed');
    });

    $p->then(sub {
        $called = 'called';
    });
    is $called, 'called', 'call fulfilled callback if promise already reasolved';
}

__PACKAGE__->runtests;
