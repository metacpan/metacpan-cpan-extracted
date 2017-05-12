use Test;
BEGIN {
	plan tests => 3
};

# Test 1 = Simple use statement Test
eval {
	require Net::MirapointAdmin;
	return 1;
};
ok($@, '');
croak() if $@;			# Fail Hard

use Net::MirapointAdmin;	# Bring it in permanently
	
# Test 2 = Check to see if ERRSTR is ""
ok($Net::MirapointAdmin::ERRSTR, '');

# Test 3 = Make sure our version is correct
ok($Net::MirapointAdmin::VERSION, "3.06");
# End-Of-Module
1;
