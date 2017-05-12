package FBTest;

use strict;
use warnings;

my %CONFIG = (
    test_email   => $ENV{FRESHBOOKS_EMAIL}        || 'olaf@raybec.com',
    account_name => $ENV{FRESHBOOKS_ACCOUNT_NAME} || 'netfreshbooksapi',
    auth_token   => $ENV{FRESHBOOKS_AUTH_TOKEN}
        || 'd2d6c5a50b023d95e1c804416d1ec15d',
);

sub get {
    my $class = shift;
    my $key   = shift;
    return $CONFIG{$key};
}

1;
