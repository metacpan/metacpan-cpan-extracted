#!perl -T

use Test::More tests => 3;

use Net::validMX qw(check_email_validity);

is( &check_email_validity('kevin.mcgrail@thoughtworthy.com'), 1, 'Test for valid email format');
is( &check_email_validity('kevin.mcgrail@aol'), 0, 'Test for invalid email format without sanitize');
is( &check_email_validity('kevin.mcgrail @ ThoughtWorthy .com'), 0, 'Test for invalid email with spaces');
