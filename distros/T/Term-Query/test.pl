#!/usr/local/bin/perl
#
# Test driver for Term::Query.pm
#
use Term::Query qw( query query_table query_table_set_defaults );

use Tester;
require "Query_Test.pl";

@ARGV = ('all') unless @ARGV;

$Term::Query::Force_Interactive = 1;	# force interactive behaviour

while ($_ = shift) {
  if    (!index('-debug', $_))		{ $Debug++; }
  elsif (!index('-details', $_))	{ $Details++; }
  elsif (!index('-keep', $_))		{ $KeepGoing++; }
  elsif (!index('-output', $_))		{ $ShowOutput++; }
  elsif (!index('-help',$_))		{ &usage; }
  else {
    $a = $_;
    run_class_test 'General'	if grep(/^-?$a/i, qw( general all));
    run_class_test 'Refs'	if grep(/^-?$a/i, qw( refs references all));
    run_class_test 'Defaults'	if grep(/^-?$a/i, qw( defaults all ));
    run_class_test 'Tables'	if grep(/^-?$a/i, qw( tables all ));
    run_class_test 'Subs'	if grep(/^-?$a/i, qw( subs all ));
  }
}
exit;

sub usage {
    print STDERR <<EOF;
usage: tq [-options] [class ..]
options:
  -debug	Do lots of debugging
  -details	Show details of the tests (give twice for more details)
  -keep		Keep going past errors
  -output	Show output of failed tests (in "t/$TEST.out")
  -help		This help

"class" is a general class of tests, which are:
  all		Do all the classes (below)
  general	Do general query tests
  references	Do tests on using referenced variables
  defaults	Do tests on assignment of default values to named variables
  tables	Do tests of query_table
  subs		Do tests on "before" and "after" sub references

tq works by running the tests named by \$CLASS (which are just files
named as "t/\$CLASS.pl").  These classes of tests generate sequences of
"ok" or "not ok", indexed by an individual test number.  The output
from each particular indexed test is kept in the file "t/\$TEST.out"
which is compared against the "reference" output kept in
"t/\$TEST.ref".  If a comparison fails, then a test is "not ok".  With
-detail set, the output is shown after the failure.

If you've just installed the Term::Query.pm module, and haven't made
any changes, then all tests should be "ok".  If you've "enhanced" or
"fixed" a problem with Term::Query.pm, be sure to run "tq -detail all"
to perform a regression test.

EOF
    exit;
}
