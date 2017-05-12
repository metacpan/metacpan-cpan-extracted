#!/usr/bin/perl

use lib 't/lib';

use Baz ();
use strict;
use Test::More tests => 16;
use warnings;

# execution plan dump
{
    my @log;

    my $t = Baz->new;
    $t->meta->meta->add_before_method_modifier(
        'log', sub { push( @log, @_[ 1 .. $#_ ], ); }
    );
    $t->meta->dry_run( 1 );
    $t->meta->current_test_object( $t );
    $t->meta->run_tests;

    my $startup_count  = grep { /\(startup/;  } @log;
    my $setup_count    = grep { /\(setup/;    } @log;
    my $test_count     = grep { /\(test/;     } @log;
    my $teardown_count = grep { /\(teardown/; } @log;
    my $shutdown_count = grep { /\(shutdown/; } @log;
    my $total_count = $startup_count + $setup_count + $test_count
      + $teardown_count + $shutdown_count;

    is( $total_count, scalar @log, 'correct number of methods'    );
    is( $startup_count,  6,  'correct number of startup methods'  );
    is( $setup_count,    30, 'correct number of setup methods'    );
    is( $test_count,     6,  'correct number of test methods'     );
    is( $teardown_count, 36, 'correct number of teardown methods' );
    is( $shutdown_count, 5,  'correct number of shutdown methods' );
}

# filter startup methods by name and dump all test methods
{
    my @log;

    eval q[
        package Baz;

        no warnings 'redefine';
        sub BUILD {
            my ( $self, ) = @_;

            $self->meta->startup_methods( [ grep {
                $_->name !~ /bar/;
            } @{ $self->meta->startup_methods } ] );
            $self->meta->test_methods( [] );

            $self->meta->meta->add_before_method_modifier(
                'log', sub { push( @log, @_[ 1 .. $#_ ], ); }
            );

            return;
        }
    ];

    my $t = Baz->new;

    $t->meta->dry_run( 1 );
    $t->run_tests;

    my $startup_count  = grep { /\(startup/;  } @log;
    my $shutdown_count = grep { /\(shutdown/; } @log;

    is(
        $startup_count + $shutdown_count, scalar @log,
        'correct number of methods'
    );
    is( $startup_count,  3, 'correct number of startup methods'  );
    is( $shutdown_count, 5, 'correct number of shutdown methods' );
}

# test methods from subclass and setup methods from superclasses
{
    my @log;

    Baz->meta->add_method( 'BUILD', sub {
        my ( $self, ) = @_;

        my @test_methods = grep {
            $_->package_name eq 'Baz';
        } @{ $self->meta->test_methods };
        $self->meta->test_methods( \@test_methods );

        my @setup_methods = grep {
            $_->package_name ne 'Baz';
        } @{ $self->meta->setup_methods };
        $self->meta->setup_methods( \@setup_methods );

        $self->meta->meta->add_before_method_modifier(
            'log', sub { push( @log, @_[ 1 .. $#_ ], ); }
        );

        return;
    } );

    Baz->meta->clear_all_methods;
    my $t = Baz->new;

    $t->meta->dry_run( 1 );
    $t->run_tests;

    my $startup_count  = grep { /\(startup/;  } @log;
    my $setup_count    = grep { /\(setup/;    } @log;
    my $test_count     = grep { /\(test/;     } @log;
    my $teardown_count = grep { /\(teardown/; } @log;
    my $shutdown_count = grep { /\(shutdown/; } @log;
    my $total_count = $startup_count + $setup_count + $test_count
      + $teardown_count + $shutdown_count;

    is( $total_count, scalar @log, 'correct number of methods'   );
    is( $startup_count,  6, 'correct number of startup methods'  );
    is( $setup_count,    4, 'correct number of setup methods'    );
    is( $test_count,     1, 'correct number of test methods'     );
    is( $teardown_count, 6, 'correct number of teardown methods' );
    is( $shutdown_count, 5, 'correct number of shutdown methods' );
}

# explicit method ordering
{
    my @methods = (
        [ 'teardown_foo1',   -10000, ],
        [ 'teardown_2',      -1,     ],
        [ 'teardown_6_bar3', 0,      ],
        [ 'teardown_bar1',           ],
        [ 'teardown_bar2',   1,      ],
        [ 'teardown_0',      5000,   ],
    );
    for ( @methods ) {
        Baz->meta->find_method_by_name( $_->[ 0 ] )->order( $_->[ 1 ] )
          if defined $_->[ 1 ];
    }

    Baz->meta->clear_all_methods;
    my $t = Baz->new;

    is_deeply(
        [ map { $_->name; } @{ $t->meta->teardown_methods } ],
        [ map { $_->[ 0 ]; } @methods ],
        'correct ordering'
    );
}
