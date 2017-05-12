# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Perl6-Slurp-Eval.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Perl6::Slurp::Interpret') };
BEGIN { use_ok('Inline::Files') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
our $column = "name";
our $table = "customers";

ok( print &eval_slurp( \*SQL ) );
# ok( eval_slurp( \*SQL ) eq 'select name from customers', "Inline Test" );

__DATA__
__SQL__
$table.$columns;

