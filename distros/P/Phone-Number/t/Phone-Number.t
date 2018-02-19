# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Phone-Number.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Phone::Number') };

my $number = new Phone::Number('02002221666');

is($number->formatted, '020 0222 1666', 'Formatted');
is($number->packed,    '02002221666',   'Packed');
is($number->number,    '+442002221666', 'Number');
is($number->plain,     '442002221666',  'Plain');
is("$number",	       '020 0222 1666',   'Stringify');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

