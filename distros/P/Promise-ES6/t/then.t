package t::then;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent qw(Test::Class);

use Time::HiRes;

use Test::More;

use Promise::ES6;

sub already_resolved : Tests {
    my $called = 0;
    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->('executed');
    })->then(sub {
        my ($value) = @_;
        $called = 'called';
    });
    is $called, 'called', 'call fulfilled callback if promise already reasolved';
}

__PACKAGE__->runtests;
