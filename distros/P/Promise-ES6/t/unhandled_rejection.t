#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Promise::ES6;

{
    my @warnings;
    local $SIG{'__WARN__'} = sub { push @warnings, @_ };

    #----------------------------------------------------------------------

    my @tests = (
        sub {
            Promise::ES6->new( sub { die 123 } );

            cmp_deeply(
                \@warnings,
                [ re( qr<123> ) ],
                'warn() as expected when constructor callback die()s',
            );
        },
        sub {
            {
                my ($res, $rej);
                my $p = Promise::ES6->new( sub { ($res, $rej) = @_ } );

                $rej->(123);
            }

            cmp_deeply(
                \@warnings,
                [ re( qr<123> ) ],
                'warn() as expected when rejection after constructor',
            );
        },
        sub {
            my ($res, $rej);
            my $p = Promise::ES6->new( sub { ($res, $rej) = @_ } )->catch( sub {  } );

            $rej->(123);

            cmp_deeply(
                \@warnings,
                [],
                'don’t warn() if there is a rejection handler',
            ) or diag explain \@warnings;
        },
        sub {
            Promise::ES6->new( sub { my ($res, $rej) = @_; $rej->(123) } );

            cmp_deeply(
                \@warnings,
                [ re( qr<123> ) ],
                'warn() when rejected promise is destroyed right after callback',
            );
        },
        sub {
            my $p = Promise::ES6->new( sub { my ($res, $rej) = @_; $rej->(123) } );

            cmp_deeply(
                \@warnings,
                [],
                'don’t warn() when constructor callback rejects “peacefully”',
            );

            $p->catch( sub {} );
        },
        sub {
            Promise::ES6->new( sub { die 123 } )->then( sub { 234 } );

            cmp_deeply(
                \@warnings,
                [ re( qr<123> ) ],
                'warn() only once',
            );
        },

        sub {
            my $p = Promise::ES6->new( sub { die 123 } );

            $p->catch( sub { 234 } )->then( sub { die 345 } );

            cmp_deeply(
                \@warnings,
                [ re( qr<345> ) ],
                'warn() again when a promise is caught after initial failure but then rejects later (uncaught)',
            ) or diag explain \@warnings;
        },

        sub {
            {
                my $r = Promise::ES6->reject('nono');

                $r->catch( sub { } );
            }

            is_deeply(
                \@warnings,
                [],
                'caught exception',
            ) or diag explain \@warnings;
        },

        sub {
            my ($finally_args, $p2str);

            my $finally_wantarray;

            {
                my $p = Promise::ES6->reject('nono');

                my $p2 = $p->finally( sub {
                    $finally_args = \@_;
                    $finally_wantarray = wantarray;
                } );

                $p2str = "$p2";
            }

            is_deeply(
                $finally_args,
                [],
                'finally() receives no arguments',
            );

            is(
                $finally_wantarray,
                q<>,
                'finally() callback runs in scalar context',
            );

            cmp_deeply(
                \@warnings,
                [
                    all(
                        re( qr<\Qnono\E> ),
                    ),
                ],
                '… and the expected warning happens',
            );
        },

        # var p = Promise.reject(789); var p2 = p.catch(e => console.debug(e)); p.finally(() => {});
        sub {
            {
                my $p = Promise::ES6->reject(789);

                my $p2 = $p->catch( sub {} );

                my $f = $p->finally( sub {} );
            }

            cmp_deeply(
                \@warnings,
                [ re( qr<789> ) ],
                'finally() shoots out a warning',
            );
        },

        # var p = Promise.reject(789); p.finally(() => {}); var p2 = p.catch(e => console.debug(e));
        sub {
            {
                my $rej;

                my $p = Promise::ES6->new( sub { (undef, $rej) = @_ } );

                $p->finally( sub { } );

                $p->catch( sub { } );

                $rej->(1234);
            }

            cmp_deeply(
                \@warnings,
                [ re( qr<1234> ) ],
                'finally() shoots out a warning',
            ) or diag explain \@warnings;
        },

        sub {
            {
                my $p = Promise::ES6->resolve(1)->then( sub { Promise::ES6->reject(789) } );
            }

            cmp_deeply(
                \@warnings,
                [ re( qr<789> ) ],
                'then() shoots out a warning from a returned rejection',
            );
        },

        sub {
            {
                my $p = Promise::ES6->resolve(1)->finally( sub { Promise::ES6->reject(789) } );
            }

            cmp_deeply(
                \@warnings,
                [ re( qr<789> ) ],
                'finally() shoots out a warning from a returned rejection',
            );
        },
    );

    for my $t (@tests) {
        $t->();
        @warnings = ();
    }
}

done_testing();
