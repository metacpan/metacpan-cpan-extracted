# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Symbol-Name.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Symbol::Name', ':test') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $letter1 = 'h';
my $letter1Name = 'hache';
is(inSpanish($letter1), $letter1Name, "Test get letter name");

my $notSupportedSymbol2 = '(';
my $notSupportedSymbol2Name = undef;
is(inSpanish($notSupportedSymbol2), 
   $notSupportedSymbol2Name, 
   "Test get not supported symbol name");

my $letter3 = 'Á';
my $letter3Name = 'a con acento';
is(inSpanish($letter1), $letter1Name, "Test get upper case letter name");

my $symbol4 = '€';
my $symbol4Name = "euros";
is(inSpanish($symbol4), $symbol4Name, "Test euro symbol name");

ok(@{supportedSpanishSymbols()} > 1, "Test get supported symbols");