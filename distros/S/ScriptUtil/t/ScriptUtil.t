# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ScriptUtil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan';
BEGIN { use_ok('ScriptUtil') };

#########################


my $object = ScriptUtil->new();
isa_ok( $object, 'ScriptUtil' );

my $expected = "foo";
my $got = $object->trim("\t\t   foo    \t");
ok ( $got eq $expected, 'trim' );

exit;
__END__