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

sub reject_promise : Tests(2) {
    my $p2 = Promise::ES6->resolve(123);

    Promise::ES6->reject($p2)->catch( sub {
        my $reason = shift;
        is( $reason, $p2, 'reject() - promise as rejection is literal rejection value' );
    } );

    Promise::ES6->new( sub { $_[1]->($p2) } )->catch( sub {
        my $reason = shift;
        is( $reason, $p2, 'callback - promise as rejection is literal rejection value' );
    } );
}

__PACKAGE__->runtests;
