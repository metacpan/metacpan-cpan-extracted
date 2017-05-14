#!/usr/local/bin/perl

unshift(@INC, '.', '..');
use Tester;
use Term::Query qw(query_table_set_defaults query_table);

$Class = 'Tables';

@qtbl = ( 'Integer 1',	'rVidh', 
		[ 'int1', 4, 'Asking for integer 1', ] ,
	  'Integer 2',	'Vid',   
		[ 'int2', 5, ],
	  'Number 3',	'Vndh', 
		[ 'num3', 3.1415, 'Asking for a number', ],
	  'Yes or No 4','VYh',
		[ 'yn4',  "Asking yes or no", ],
	  'No or Yes 5','VNh',
		[ 'yn5',  "Asking no or yes", ],
	  'Keyword 6',	'rVkdh', 
		[ 'key6', \@keywords, 'IBM', 'Asking for a keyword', ],
	  'Nonkey 7',	'VrKh', 
		[ 'nonkey7', \@fields, 'Asking for a new keyword', ],
	  );

sub show_vars {
  foreach $var ( qw( int1 int2 num3 yn4 yn5 key6 nonkey7 ) ) {
      $val = $$var;
      print "  \$$var = \"$val\"\n";
  }
}

print "1..2\n";

Tester::run_test_with_input $Class, 1, '', sub {
    query_table_set_defaults \@qtbl;
    show_vars; };

Tester::run_test_with_input $Class, 2, "\n\n\n\n\n\n\n", sub {
    $ok = query_table \@qtbl;
    print "query_table returned $ok\n";
    show_vars; };

