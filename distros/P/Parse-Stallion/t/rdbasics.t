#This file is copied from the test cases for Parse::RecDescent, modified
#because not all has been implemented.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}

#eval "use Parse::RecDescent";
#my $skip = $@;
my $skip;
eval "use Text::Balanced";
$skip .= $@;
eval "use Parse::Stallion::RD";
$skip .= $@;

$skip = 1;
if ($skip) {
print "ok 1\n";
print "ok 2\n";
print "ok 3\n";
print "ok 4\n";
print "ok 5\n";
print "ok 6\n";
print "ok 7\n";
print "ok 8\n";
$loaded = 1;
$skip = 8;
}
else {
$loaded = 1;
print "ok 1\n";

#sub debug { $D || 0 }

my $count = 2;
sub ok($;$)
{
	my $ok = ((@_==2) ? ($_[0] eq $_[1]) : $_[0]);
	#print "\texp=[$_[1]]\n\tres=[$_[0]]\n" if debug && @_==2;
	print "not " unless $ok;
	print "ok $count\n";
	$count++;
	return $ok;
}

######################### End of black magic.

#do { $RD_TRACE = 1; $RD_HINT = 1; } if debug > 1;

$data1    = '(the 1st   teeeeeest are easy easy easyeasy';
$expect1  = '[1st|teeeeeest|are|easy:easy:easy:easy]';

$data2    = '(the 2nd   test is';
$expect2  = '[2nd|test|is|]';

##################################################################

$parser_A = new Parse::Stallion::RD q
{
	test1:	"(" 'the' "$::first" /te+st/ is ('easy')(s?)
			{ "[$item[3]|$item[4]|$item[5]|" .
				join(':', @{$item[6]})   .
				']' }

	is:	'is' | 'are'

#================================================================#

	test3:	 (defn | fail)(5..10)
			{ join ', ', @{$item[1]}; }

	fail:	 { 'baddef' }

	defn:	 'var' id 'holds' typename ';'
			{ "$item[0]=>$item[2]" }

	id:	 /[a-z]		# LEADING ALPHABETIC
		  \w*		# FOLLOWED BY ALPHAS, DIGITS, OR UNDERSCORES
		 /ix

	typename: 'int'

#================================================================#

	test5: ...!name notname | name

	notname: /[a-z]\w*/i { 'notname' }

	name: 'fred' { 'name' }

#================================================================#

};

ok ($parser_A) or exit;



##################################################################
$first = "1st";
$res = $parser_A->test1($data1);
ok($res,$expect1);

##################################################################
$first = "2nd";
$res = $parser_A->test1($data2);
ok($res,$expect2);

##################################################################
$res = $parser_A->test5("fred");
ok($res, "name");

$res = $parser_A->test5("fled");
ok($res, "notname");

##################################################################

##################################################################

package Derived;

@ISA = qw { Parse::Stallion::RD };
sub method($$) { reverse $_[1] }

package main;

$parser_B = new Derived q
{
	test1:	/[a-z]+/i
		{ reverse $item[1] }
		{ $thisparser->method($item[2]) }
};

ok ($parser_B) or exit;
##################################################################
$res = $parser_B->test1("literal string");
ok($res, "literal");

#################################################################
}
