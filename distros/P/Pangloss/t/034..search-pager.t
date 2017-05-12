#!/usr/bin/perl

##
## Tests for Pangloss::Search::Pager
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;

use Pangloss::Term;
use Pangloss::Search::Results;
BEGIN { use_ok("Pangloss::Search::Results::Pager") }
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
	       Pangloss::Concept->new->name('d'),
	      )
	    )
  ->terms( Pangloss::Terms->new->add
	   (
	    # lots of duplicates so we end up with results split over pages...
	    Pangloss::Term->new->name('test1')->concept('a')->language('l1'),
	    Pangloss::Term->new->name('test3')->concept('b')->language('l1'),
	    Pangloss::Term->new->name('test4')->concept('c')->language('l3'),
	    Pangloss::Term->new->name('test7')->concept('d')->language('l3'),
	    Pangloss::Term->new->name('test2')->concept('a')->language('l2'),
	    Pangloss::Term->new->name('test5')->concept('a')->language('l1'),
	    Pangloss::Term->new->name('test6')->concept('a')->language('l1'),
	    Pangloss::Term->new->name('test8')->concept('a')->language('l1'),
	    Pangloss::Term->new->name('test9')->concept('a')->language('l1'),
	    Pangloss::Term->new->name('testA')->concept('a')->language('l1'),
	   )
	 );

my $results = Pangloss::Search::Results->new
  ->parent($search)
  ->add(  $search->terms->list );

my $pager = new Pangloss::Search::Results::Pager();
ok( $pager, 'new' ) || die "cannot proceed\n";

is( $pager->page(1), $pager,             'pager->page(set)' );
is( $pager->page_size(2), $pager,        'pager->page_size(set)' );
is( $pager->results( $results ), $pager, 'pager->results(set)' );
#is( $pager->counter, 0,                  'pager->counter(get)' );

is( $pager->order_by('concept','language'), $pager, 'pager->order_by(set)' );

is( $pager->pages, 5, 'pager->pages expected size' );

is( $pager->size, $pager->page_size,    'pager->size (expect current page size)' );
is( $pager->total_size, $results->size, 'pager->total_size (expect results->size)' );
is( @{ $pager->pages_list }, $pager->pages, 'pager->pages_list' );
is( $pager->start_number, 1, 'pager->start_number' );
is( $pager->end_number, 2, 'pager->end_number' );

ok( $pager->not_empty, 'pager->not_empty' );
ok(!$pager->is_empty,  '!pager->is_empty' );

is( $pager->concepts->size, 4,  'expected pager->concepts' );
is( $pager->languages->size, 3, 'expected pager->languages' );

is( $pager->page_concepts->size, 1,  'expected pager->concepts' );
is( $pager->page_languages->size, 1, 'expected pager->languages' );

{
    my @terms = $pager->list;
    is( scalar @terms, 2, 'pager->list expected page size' )
      || diag( Dumper( \@terms  ) );
}

{
    # switch current page
    $pager->page(4);
    my @terms = $pager->list_by( 'b', 'l1' );
    is( scalar @terms, 1, 'pager->list_by' )
      || diag( Dumper( \@terms  ) );
}


