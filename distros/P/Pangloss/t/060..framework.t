#!/usr/bin/perl

##
## Setup a test framework for Pangloss
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Benchmark;
use Test::More 'no_plan';
use File::Spec;
use Data::Dumper;

use TestStore;
use TestFramework;

$Pangloss::DEBUG{ALL} = grep /-d/, @ARGV;

my $terms_db = File::Spec->catfile(qw( t data terms.yml ));
my $pixie;

if (TestFramework->new->load) {
    ok( 1, 'framework already exists' );
} else {
    my $framework = TestFramework->new
      ->number({ languages    => 10,
		 users        => 30,
		 translators  => 10,
		 proofreaders => 10,
		 categories   => 10, });

    print( "generating a randomized test model based on $terms_db\n",
	  "(this may take a while)\n" );
    my $t0 = Benchmark->new;
    ok( $framework->create_random_model_from( $terms_db ),
	'generated test model' );
    my $t1 = Benchmark->new;
    print "took " . timestr( timediff($t1, $t0) ), "\n";

    print( "saving framework\n",
	  "(this may take a while)\n" );
    my $t2 = Benchmark->new;
    ok( $framework->save, 'saved test model' );
    my $t3 = Benchmark->new;
    print "took " . timestr( timediff($t3, $t2) ), "\n";
}


1;

