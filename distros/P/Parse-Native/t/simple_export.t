# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Parse-Native.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Parse::Native') };
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.



Grammar SimpleGrammar;	



Rule Salutation;		

$skip = '\s*';

sub Parse
{
	warn "parse";
	lit 'Hello';
	lit ',';
	rule 'identifier';
	regx '[!.?]';	
}

EndGrammar;			

package main;

use Data::Dumper;


is_deeply( 
	\@Parse::Native::Grammar::SimpleGrammar::Rules, 
	['Parse::Native::Grammar::SimpleGrammar::Rule::Salutation'], 
	"Testing that Rules are registered in grammar array"
);

#Parse::Native::Grammar::SimpleGrammar::Salutation::Parse;



