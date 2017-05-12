#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More;

plan +Test::More->can('subtest')
  ? ( tests => 6 )
  : ( skip_all => 'Need Test::More::subtest() for this test' );
use Test::Aggregate::Nested;

my ( $startup, $shutdown ) = ( 0, 0 );
my ( $setup,   $teardown ) = ( 0, 0 );

$SIG{__WARN__} = sub {
    my $warning = shift;
    if ( $warning =~ m{Can't locate Data/Dump/Streamer\.pm in \@INC} ) {    #'
        return;
    }
    CORE::warn($warning);
};

my $found_it;
subtest 'nested tests' => sub {
    my $tests = Test::Aggregate::Nested->new(
        {
            dirs     => 'aggtests',
            findbin  => 1,
            startup  => sub { $startup++ },
            shutdown => sub { $shutdown++ },
            setup    => sub {
                my $file = shift;
                if ( $file =~ /slow_load\.t$/ ) {
                    $found_it = 1;
                }
                $setup++;
            },
            teardown => sub { $teardown++ },
            shuffle  => 1,
        }
    );
    $tests->run;
};

my $num_tests = 9;

is $startup,  1, 'Startup should be called once';
is $shutdown, 1, '... as should shutdown';
is $setup,    $num_tests, 'Setup should be called once for each test program';
is $teardown, $num_tests, '... as should teardown';
ok $found_it, '... and file names should be passed to setup';
