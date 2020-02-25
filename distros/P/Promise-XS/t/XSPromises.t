use strict;
use warnings;

use Test::More;

eval { require AnyEvent; 1 } or plan skip_all => $@;

use Promise::XS;

Promise::XS::use_event('AnyEvent');

my $cv= AnyEvent->condvar;

my $deferred= Promise::XS::deferred();
my $promise= $deferred->promise;
is($deferred->is_pending, !!1);
$deferred->resolve([1, 2, 3]);
is($deferred->is_pending, !!0);

my ($next_ok, $any, $finally_called, $reached_end);
for (1..1) {
    my $final= $promise->then(
        sub {
            ok(1, 'start');
            $any= 1;
            return (123, 456);
        },
        sub {
            fail;
        }
    )->finally(sub {
        $finally_called= 1;
        654;
    })->then(sub {
        is($_[0], 123);
        is($_[1], 456);
        is(0 + @_, 2);
        die "Does this work?";
    })->then(
        sub {
            fail;
        },
        sub {
            ok(($_[0] =~ /Does this/) ? 1 : 0);
            # next;     # Removed this protection
        }
#    )->then(
#        sub {
#            fail;
#        },
#        sub {
#            ok(($_[0] =~ /outside a loop block/) ? 1 : 0);
#            $next_ok= 1;
#        }
    )->catch(sub {
        fail;
    })->then(sub {
        Fakepromise->new
    })->then(
        sub {
            is($_[0], 500, 'foreign promise class');
            $_= 5;
        }, sub {
            fail($_[0]);
        }
    )->then(sub {
        is($_, undef, '$_ is cleared between callbacks');
        die "test catch";
    })->then(sub {
        fail;
    })->catch(sub {
        like( $_[0], qr<test catch> );
#        collect(resolved(1), resolved(2));
#    })->then(sub {
#        is_deeply(\@_, [ [1], [2] ]);
#        collect(resolved(2), rejected(5));
#    })->then(sub {
#        fail;
#    }, sub {
#        is($_[0], 5);
#    })->then(sub {
        $reached_end= 1;
    })->then($cv, sub {
        diag $_[0]; fail;
        $cv->();
    })
}
$cv->recv;
ok($any);
TODO: {
    local $TODO = 'test disabled';
    ok($next_ok, 'erroneous exit-via-next is caught and treated as a rejection');
}
ok($reached_end);
ok($finally_called);

done_testing;

package Fakepromise;
sub new { bless {}, 'Fakepromise' }
sub then {
    my ($self, $resolve)= @_;
    $resolve->(500);
}
