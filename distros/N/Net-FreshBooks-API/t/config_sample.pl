
# This is a sample of the config file required for testing actual API calls to
# the live FreshBooks site (at the moment there is no sandbox). Be aware that
# running the tests will interact with your account, so it is essential that
# you create a test account for testing.

# Copy this file to 't/config.pl' and enter the details needed.

package FBTest;

use strict;
use warnings;

my %CONFIG = (

    # DO NOT USE A REAL ACCOUNT HERE - CREATE A TEST ACCOUNT.
    # tests will delete clients from the account

    test_email => 'test@example.com',    # test email address
    account_name => 'yourname',   # from 'https://yourname.freshbooks.com/...'
    auth_token   => '123...def',  # provided when you enable API access
);

sub get {
    my $class = shift;
    my $key   = shift;
    return $CONFIG{$key};
}

1;
