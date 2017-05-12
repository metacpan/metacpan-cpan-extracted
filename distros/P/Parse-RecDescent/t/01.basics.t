# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..32\n"; }
END {print "not ok 1\n" unless $loaded;}
use Parse::RecDescent;
$loaded = 1;
print "ok 1\n";

sub debug { $D || $D || 0 }

my $count = 2;
sub ok($;$)
{
	my $ok = ((@_==2) ? ($_[0] eq $_[1]) : $_[0]);
	print "\texp=[$_[1]]\n\tres=[$_[0]]\n" if debug && @_==2;
	print "not " unless $ok;
	print "ok $count\n";
	$count++;
	return $ok;
}

######################### End of black magic.

do { $RD_TRACE = 1; $RD_HINT = 1; } if debug > 1;

$data1    = '(the 1st   teeeeeest are easy easy easyeasy';
$expect1  = '[1st|teeeeeest|are|easy:easy:easy:easy]';

$data2    = '(the 2nd   test is';
$expect2  = '[2nd|test|is|]';

$data3    = 'the cat';
$expect3a = 'fluffy';
$expect3b = 'not fluffy';

$data4    = 'a dog';
$expect4  = 'rover';

$data5    = 'type a is int; type b is a; var x holds b; type c is d;';
$expect5  = 'typedef=>a, typedef=>b, defn=>x, baddef, baddef';

require './t/util.pl';

##################################################################

$parser_A = new Parse::RecDescent q
{
	test1:	"(" 'the' "$::first" /te+st/ is ('easy')(s?)
			{ "[$item[3]|$item[4]|$item[5]|" .
				join(':', @{$item[6]})   .
				']' }

	is:	'is' | 'are'

#================================================================#

	test2:	<matchrule:$arg{article}>
		<matchrule:$arg[3]>[$arg{sound}]

	the:	'the'
	a:	'a'

	cat:	<reject: $arg[0] ne 'meows'> 'cat'
			{ "fluffy" }
	   |    { "not fluffy" }

	dog:	'dog'
			{ "rover" }

#================================================================#

	test3:	 (defn | typedef | fail)(5..10)
			{ join ', ', @{$item[1]}; }

	typedef: 'type' id 'is' typename ';'
			{ $return = "$item[0]=>$item[2]";
			  $thisparser->Extend("typename: '$item[2]'"); }

	fail:	 { 'baddef' }

	defn:	 'var' id 'holds' typename ';'
			{ "$item[0]=>$item[2]" }

	id:	 /[a-z]		# LEADING ALPHABETIC
		  \w*		# FOLLOWED BY ALPHAS, DIGITS, OR UNDERSCORES
		 /ix		# CASE INSENSITIVE

	typename: 'int'

#================================================================#

	test4:	'a' b /c/
			{ "$itempos[1]{offset}{from}:$itempos[2]{offset}{from}:$itempos[3]{offset}{from}" }

	b:	"b"

#================================================================#

	test5: ...!name notname | name

	notname: /[a-z]\w*/i { 'notname' }

	name: 'fred' { 'name' }

#================================================================#

	test6: <rulevar: $test6 = 1>
	test6: 'a' <commit> 'b' <uncommit> 'c' <reject: $test6 && $text>
			{ 'prod 1' }
	     | 'a'
			{ 'prod 2' }
	     | <uncommit>
			{ 'prod 3' }

#================================================================#

	test7: 'x' <resync> /y+/
			{ $return = $item[3] }

#================================================================#

	test8:	'a' b /c+/ 'dddd' e 'f'
	        { &::make_itempos_text(\@item, \@itempos); }

	e: /ee/

#================================================================#

	test9:	'a' d(s) /c/
	        { &::make_itempos_text(\@item, \@itempos); }

    d: 'd' 'd' 'd'

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
$res = $parser_A->test2($data3,undef,
			article=>'the', animal=>'cat', sound=>'meows');
ok($res,$expect3a);

##################################################################
$res = $parser_A->test2($data3,undef,
			article=>'the', animal=>'cat', sound=>'purrs');
ok ($res,$expect3b);

##################################################################
$res = $parser_A->test2($data4,undef,
			article=>'a', animal=>'dog', sound=>'barks');
ok($res,$expect4);

##################################################################
$res = $parser_A->test3($data5);
ok($res,$expect5);

##################################################################
$res = $parser_A->test4("a  b   c");
ok($res, "0:3:7");

##################################################################
$res = $parser_A->test5("fred");
ok($res, "name");

$res = $parser_A->test5("fled");
ok($res, "notname");

##################################################################
$res = $parser_A->test6("a b d");
ok($res, "prod 2");

$res = $parser_A->test6("a c d");
ok($res, "prod 3");

$res = $parser_A->test6("a b c");
ok($res, "prod 1");

$res = $parser_A->test6("a b c d");
ok($res, "prod 2");

##################################################################
$res = $parser_A->test7("x yyy \n y");
ok($res, "y");

##################################################################

$res = $parser_A->test8("a\n b\n  cccccccccc\ndddd    ee\n   f");
ok($res,'
a          offset.from=  0 offset.to=  0 line.from=  1 line.to=  1 column.from=  1 column.to=  1
b          offset.from=  3 offset.to=  3 line.from=  2 line.to=  2 column.from=  2 column.to=  2
cccccccccc offset.from=  7 offset.to= 16 line.from=  3 line.to=  3 column.from=  3 column.to= 12
dddd       offset.from= 18 offset.to= 21 line.from=  4 line.to=  4 column.from=  1 column.to=  4
ee         offset.from= 26 offset.to= 27 line.from=  4 line.to=  4 column.from=  9 column.to= 10
f          offset.from= 32 offset.to= 32 line.from=  5 line.to=  5 column.from=  4 column.to=  4
');

##################################################################
$res = $parser_A->test9("a\n d d \n d d d d \n d d d\nc\n");
ok($res,'
a          offset.from=  0 offset.to=  0 line.from=  1 line.to=  1 column.from=  1 column.to=  1
_REF_      offset.from=  3 offset.to= 23 line.from=  2 line.to=  4 column.from=  2 column.to=  6
c          offset.from= 25 offset.to= 25 line.from=  5 line.to=  5 column.from=  1 column.to=  1
');

##################################################################


package Derived;

@ISA = qw { Parse::RecDescent };
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
$res = $parser_A->Extend("extended : 'some extension'");
ok(@{"$parser_A->{namespace}::ISA"} == 1);

#################################################################
package main;

# Ensure that regex modifiers (like /x below) get interpreted
$parser = new Parse::RecDescent q
{
test : /\.               # a literal period
        (Test)?
       /x
};
ok($parser) or exit;
ok($parser->test("."));
ok($parser->test(".Test"));
ok($parser->test(".Test"));


#################################################################
$parser = new Parse::RecDescent q
{
   whatever : /\\\\/ | /whatever/
};
ok ($parser) or exit;

ok($parser->whatever(" \\ "));
ok($parser->whatever(" whatever "));


#################################################################
# Check that changing some Data::Dumper variables don't break the
# parsers
foreach my $terse (0..1) {
	local $Data::Dumper::Terse = $terse;
	$parser = new Parse::RecDescent q{
   startrule : string
   string : "hello"
};

	ok ($parser) or exit;
	ok($parser->startrule("hello"));
}
