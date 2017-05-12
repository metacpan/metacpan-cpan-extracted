#!/usr/local/bin/perl5 -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)


BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok (can't load)\n" unless $loaded;}
use Net::Hesiod qw( :resolve hesiod_to_bind );

$loaded = 1;

######################### End of black magic.

# Tests hesiod_resolve, hesiod_to_bind, and ->query
require 't/helpers.pl';


#Some site specific data for the testing module
require "t/testdata.pl";
my @nullarry = ();
my $bindname="$bindsuff"; #Get rid of warning re bindsuff only being used once
$bindname="$name.$type.$bindsuff";

#Test the raw interface functions
my $context;
hesiod_init($context) &&  die "Unable to hesiod_init: $!\n";

#1 check hesiod_to_bind
my $res = hesiod_to_bind($context,$name,$type);
if ($res eq $bindname ) { print "ok 1\n" } else { print "not ok 1\n";}

#2 check hesiod_resolve
my @res = hesiod_resolve($context,$name,$type);
print &are_arrays_equal(\@res,\@resolve_answer)? "ok 2\n" : "not ok 2\n";

#3 check hesiod_resolve with bad name
@res = hesiod_resolve($context,$bogusname,$type);
print &are_arrays_equal(\@res,\@nullarry)? "ok 3\n" : "not ok 3\n";

#4 check hesiod_resolve with bad type
@res = hesiod_resolve($context,$name,$bogustype);
print &are_arrays_equal(\@res,\@nullarry)? "ok 4\n" : "not ok 4\n";

#5 check hesiod_resolve with bad name and type
@res = hesiod_resolve($context,$bogusname,$bogustype);
print &are_arrays_equal(\@res,\@nullarry)? "ok 5\n" : "not ok 5\n";

#done with non-OO interface
hesiod_end($context);

#Now test the OO interface
my $hesobj= new Net::Hesiod;
if (! defined $hesobj) { die "cannot create Net::Hesiod object"; }

#These should be redundant, as basically just wrappers to the "raw" routines
#6 test to_bind
$res = $hesobj->to_bind($name,$type);
if ($res eq $bindname ) { print "ok 6\n" } else { print "not ok 6\n";}

#7 test resolve
@res = $hesobj->resolve($name,$type);
print &are_arrays_equal(\@res,\@resolve_answer)? "ok 7\n" : "not ok 7\n";

#8 test resolve, bad name
@res = $hesobj->resolve($bogusname,$type);
print &are_arrays_equal(\@res,\@nullarry)? "ok 8\n" : "not ok 8\n";

#9 test resolve, bad type
@res = $hesobj->resolve($name,$bogustype);
print &are_arrays_equal(\@res,\@nullarry)? "ok 9\n" : "not ok 9\n";

#10 test resolve, bad type
@res = $hesobj->resolve($bogusname,$bogustype);
print &are_arrays_equal(@res,@nullarry)? "ok 10\n" : "not ok 10\n";

#Now some real tests again

#11 test query, scalar context
$res = $hesobj->query($name,$type);
if ($res eq $query_answer ) { print "ok 11\n" } else { print "not ok 11\n";}

#12 test  query, scalar context, bad name
$res = $hesobj->query($bogusname,$type);
if ($res) { print "not ok 12\n" } else { print "ok 12\n";}

#13 test  query, scalar context, bad type
$res = $hesobj->query($name,$bogustype);
if ($res) { print "not ok 13\n" } else { print "ok 13\n";}

#14 test  query, scalar context, bad name and type
$res = $hesobj->query($bogusname,$bogustype);
if ($res) { print "not ok 14\n" } else { print "ok 14\n";}

#15 test query, list context
@res = $hesobj->query($name,$type);
print &are_arrays_equal(\@res,\@query_answer)? "ok 15\n" : "not ok 15\n";

#16 test query, list context, bad name
@res = $hesobj->query($bogusname,$type);
print &are_arrays_equal(\@res,\@nullarry)? "ok 16\n" : "not ok 16\n";

#17 test query, list context, bad type
@res = $hesobj->query($name,$bogustype);
print &are_arrays_equal(\@res,\@nullarry)? "ok 17\n" : "not ok 17\n";

#18 test query, list context, bad name and type
@res = $hesobj->query($bogusname,$bogustype);
print &are_arrays_equal(\@res,\@nullarry)? "ok 18\n" : "not ok 18\n";
