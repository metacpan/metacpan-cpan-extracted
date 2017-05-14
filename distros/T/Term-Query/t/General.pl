#!/usr/local/bin/perl

unshift(@INC, '.', '..');
require 'Query_Test.pl';

@keywords = qw( SGI HP Sun DEC IBM );
@fields = qw( Index Title Vendor );

print "1..14\n";

&query_test(  $Class, 1, 'foo bar', ['Enter anything:'] );

&query_test(  $Class, 2, 'snafu', ['Enter a required value:','r'] );

&query_test(  $Class, 3, "foo", ['Enter a yes or no:','Y'], "/y/" );

&query_test(  $Class, 4, "foo\nn", ['Enter a yes or no:','Y'], "/n/" );

&query_test(  $Class, 5, "bad\n88", 
	['Enter an integer:','ridh', 5,
	  'This is some help for an int query.'] );

&query_test(  $Class, 6, '', ['Enter a yes or no:','N'] );

&query_test(  $Class, 7, '', ['Enter a number:','nrd', 3.1415] );

&query_test(  $Class, 8, "bad\n99.9", ['Enter a number:','nrd', 3.1415] );

&query_test(  $Class, 9, "bad", ['Enter a number:','nrd', 3.1415], "/3\\.1415/" );

&query_test(  $Class, 10, '2.828', ['Enter a number:','nrd', 3.1415], "/2\\.828/" );

&query_test(  $Class, 11, 'input', ['Enter a matching keyword:','rmdh',
	  '^(SGI|HP|Sun|DEC)$',	# match pattern '
	  'SGI',			# default
	  'Answer one of SGI, HP, Sun, or DEC.'] ); # help string


&query_test(  $Class, 12, 'input', ['Enter a keyword:','rdkh',
	  'SGI',		# default
	  \@keywords,		# keyword table
	  'Enter a vendor keyword.'] ); # helpstring

    $Query::Case_sensitive = 1;
&query_test(  $Class, 13, 'input', ['Enter a keyword (case-sensitive):','rdkh',
	  'SGI',		# default
	  \@keywords,		# keyword table
	  'Enter a case-sensitive vendor keyword.'] ); # helpstring
    $Query::Case_sensitive = '';


&query_test(  $Class, 14, 'input', ['Enter a new keyword:','rKh',
	  \@fields,		# anti-keyword list
	  'Enter a new field name.'] );

1;
