
use ExtUtils::testlib;
use Test::More no_plan;
BEGIN { use_ok('Net::Address::Ethernet', qw( get_address ), ) };

# Make sure the get_address() function was imported:
eval { my $s = &get_address };
is($@, '');
# Make sure the method() function was NOT imported:
eval { my $s = &method };
isnt($@, '');
