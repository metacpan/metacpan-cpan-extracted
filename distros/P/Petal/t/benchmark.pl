#!/usr/bin/perl

##
## Benchmark some common functions
##

use warnings;
use lib 'lib';

use Test::More qw( no_plan );
use Benchmark;
use Petal;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 1;
$Petal::TAINT        = 1;
$Petal::INPUT        = 'HTML';

#$Petal::Hash::Var::ERROR_ON_UNDEF_VAR = 0;

my %vars = (
	    foo     => bless ({ bar => 1 }, 'Foo'),
	    list    => [ 1, 2, 3, 4 ],
	    session => { id   => '1234asdf',
			 user => { id => 'fred', name => 'fred fish' },
		    },
	   );

diag ("running benchmarks for 10s...");

my $b = timethis (-10, sub { run_test( %vars ) });

diag (timestr $b);

ok (1);

sub run_test {
    Petal->new( 'benchmark.html' )->process( @_ );
}

