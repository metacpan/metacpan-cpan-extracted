# $Id: 2-parser.t,v 1.4 2004/12/23 10:24:12 mike Exp $

use strict;
use warnings;

BEGIN {
    use vars qw(@tests);
    @tests = (
	      [ 'brian',
		"term: brian" ],
	      [ '"brian"',
		"term: brian" ],
	      [ '"brian kernighan"',
		"term: brian kernighan" ],
	      [ '{brian kernighan}',
		"term: brian kernighan" ],
	      [ '@attr 1=1003 brian',
		"term: brian\n\tattr: bib-1 1=1003" ],
	      [ '@attr 1=1003 "brian"',
		"term: brian\n\tattr: bib-1 1=1003" ],
	      [ '@attr 1=1003 @attr 2=3 brian',
		"term: brian\n\tattr: bib-1 1=1003\n\tattr: bib-1 2=3" ],
	      [ '@and brian dennis',
		"and\n\tterm: brian\n\tterm: dennis" ],
	      [ '@set foo123',
		"rset: foo123" ],
	      [ '@attr 1=1003 @set foo123',
		"rset: foo123\n\tattr: bib-1 1=1003" ],
	      [ '@or brian dennis',
		"or\n\tterm: brian\n\tterm: dennis" ],
	      [ '@or ken @and brian dennis',
		"or\n\tterm: ken\n\tand\n\t\tterm: brian\n\t\tterm: dennis" ],
	      [ '@attr zthes 1=3 dennis',
		"term: dennis\n\tattr: zthes 1=3" ],
	      [ '@attrset zthes @attr 1=3 dennis',
		"term: dennis\n\tattr: zthes 1=3" ],
	      [ '@attrset zthes @attr bib-1 1=3 dennis',
		"term: dennis\n\tattr: bib-1 1=3" ],
	      [ '@or @attr 1=1003 dennis unix',
		"or\n\tterm: dennis\n\t\tattr: bib-1 1=1003\n" .
		    "\tterm: unix" ],
	      [ '@or dennis @attr 1=4 unix',
		"or\n\tterm: dennis\n" .
		    "\tterm: unix\n\t\tattr: bib-1 1=4" ],
	      [ '@attr bib-1 1=1003 @or dennis @attr 1=4 unix',
		"or\n\tterm: dennis\n\t\tattr: bib-1 1=1003\n" .
		    "\tterm: unix\n\t\tattr: bib-1 1=4" ],
	      [ '@attr 1=1003 @or dennis ken',
		"or\n\tterm: dennis\n\t\tattr: bib-1 1=1003\n" .
		    "\tterm: ken\n\t\tattr: bib-1 1=1003" ],
	      [ '@attr 1=1003 @attr 2=3 @and @or ken @attr 5=3 den ' .
		'@attr 1=4 unix',
		"and\n\tor\n" .
		"\t\tterm: ken\n\t\t\tattr: bib-1 1=1003\n" .
		"\t\t\tattr: bib-1 2=3\n" .
		"\t\tterm: den\n\t\t\tattr: bib-1 1=1003\n" .
		"\t\t\tattr: bib-1 2=3\n" .
		"\t\t\tattr: bib-1 5=3\n" .
		"\tterm: unix\n\t\tattr: bib-1 1=4\n\t\tattr: bib-1 2=3" ]
	      );
}
use Test::More tests => 2*scalar(@tests) + 2;
BEGIN { use_ok('Net::Z3950::PQF') };

my $parser = new Net::Z3950::PQF();
ok(defined $parser, "created parser");

foreach my $test (@tests) {
    my($query, $text) = @$test;
    my $top = $parser->parse($query);
    ok(defined $top, "parsed: $query");
    my $rendered = $top->render(0);
    my $ok = $rendered eq "$text\n";
    ok($ok, $ok ? "rendered" : "wanted: '$text\n', got '$rendered'");
    exit if !$ok;
}
