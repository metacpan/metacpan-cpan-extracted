# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Parse-Tinymush.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 10 };
use Parse::Tinymush;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $variables = {
  b => " ",
  B => " ",
  r => "\n",
  R => "\n",
  t => "\t",
  T => "\t",
  c => sub { "test code" },
};

my $functions = {
  add => [sub { $_[0] + $_[1] }, 2],
  print => [sub { "@_" }, Parse::Tinymush::FN_VARARG],
  func_name => [sub { $_[0] }, 0, Parse::Tinymush::FNC_PASS_NAME],
};

my $parser = Parse::Tinymush->new(
  variables => $variables, functions => $functions);
ok($parser);

ok($parser->parse("test"), 'test', "Basic parsing");
ok($parser->parse("%t%b%r"), "\t \n", "Basic variable substitution");
ok($parser->parse("%c"), "test code", "Advanced variable substitution");
ok($parser->parse("add(1,2)"), 3, "Basic function calls");
ok($parser->parse("print(%c)"), "test code", "Advanced function calls");
ok($parser->parse("print(%c,1,add(2,3))"), "test code 1 5", 
  "Advanced function calls");
ok($parser->parse("print({1,2,3,4,5})"), "1,2,3,4,5", 
  "Advanced braces");
ok($parser->parse("func_name()"), "func_name", "Function name passing");
