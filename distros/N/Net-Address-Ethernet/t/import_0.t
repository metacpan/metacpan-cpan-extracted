
use ExtUtils::testlib;
use Test::More no_plan;
BEGIN { use_ok('Net::Address::Ethernet', ) };

# Make sure the get_address() function was NOT imported:
eval { my $s = &get_address };
isnt($@, '');
# Make sure the method() function was NOT imported:
eval { my $s = &method };
isnt($@, '');
