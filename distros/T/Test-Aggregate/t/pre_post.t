#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;

my ( $startup, $shutdown ) = ( 0, 0 );
my ( $setup,   $teardown ) = ( 0, 0 );

$SIG{__WARN__} = sub {
    my $warning = shift;
    if ( $warning =~ m{Can't locate Data/Dump/Streamer\.pm in \@INC} ) {  #'
        return;
    }
    CORE::warn($warning);
};

my $dump = 'dump.t';

my $found_it;
my $tests = Test::Aggregate->new(
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
#        dump     => $dump,
    }
);
$tests->run;

my $num_tests = 9;

is $startup,  1, 'Startup should be called once';
is $shutdown, 1, '... as should shutdown';
is $setup,    $num_tests, 'Setup should be called once for each test program';
is $teardown, $num_tests, '... as should teardown';
#unlink $dump or warn "Cannot unlink ($dump): $!";
ok $found_it, '... and file names should be passed to setup';
done_testing();
