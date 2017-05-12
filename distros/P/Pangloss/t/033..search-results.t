#!/usr/bin/perl

##
## Tests for Pangloss::Search::Results
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Pangloss::Term;
BEGIN { use_ok("Pangloss::Search::Results") }
use Pangloss::Search;

my $search = Pangloss::Search->new
  ->languages( Pangloss::Languages->new->add
	       (
		Pangloss::Language->new->iso_code('l1'),
		Pangloss::Language->new->iso_code('l2'),
		Pangloss::Language->new->iso_code('l3'),
	       )
	     )
  ->concepts( Pangloss::Concepts->new->add
	      (
	       Pangloss::Concept->new->name('a'),
	       Pangloss::Concept->new->name('b'),
	       Pangloss::Concept->new->name('c'),
	      )
	    )
  ->terms( Pangloss::Terms->new->add
	   (
	    Pangloss::Term->new->name('test1')->concept('a')->language('l1'),
	    Pangloss::Term->new->name('test2')->concept('a')->language('l2'),
	    Pangloss::Term->new->name('test3')->concept('b')->language('l1'),
	    Pangloss::Term->new->name('test4')->concept('c')->language('l3'),
	   )
	 );


my $results = Pangloss::Search::Results->new->parent($search);
ok( $results, 'new' ) || die "cannot proceed\n";

is( $results->add( $search->terms->list ), $results, 'add' );

is( $results->size, 4, 'size' );
is( $results->concepts->size, 3, 'concepts size' );
is( $results->languages->size, 3, 'languages size' );

{
    my $r1 = $results->by_concept( 'a' );
    if (isa_ok( $r1, $results->class, 'by_concept' )) {
	is( $r1->size, 2, ' size as expected' );
	is( $r1->parent, $results, 'parent set' );
    }
}

{
    my $r1 = $results->by_language( 'l3' );
    if (isa_ok( $r1, $results->class, 'by_language' )) {
	is( $r1->size, 1, ' size as expected' );
    }
}


__END__

foreach $concept ($results->concepts) {
    my $results_by_concept = $results->by_concept( $concept );
    foreach my $lang ($results_by_concept->languages) {
	my $results_by_lang = $results->by_language( $lang );
	foreach my $term ($results_by_lang->list_by_name) {
	    # do stuff with $term
	}
    }
}
