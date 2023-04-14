#!/usr/bin/perl -T

use lib 'lib';

use Test::More;
plan tests => 6;

use Net::validMX qw(check_email_validity);

is( check_email_validity('kevin.mcgrail@peregrinehw.com'), 1, 'Test for valid email format');
is( check_email_validity('kevin.mcgrail@aol'), 0, 'Test for invalid email format without sanitize');
is( check_email_validity('kevin.mcgrail @ peregrine hw .com'), 0, 'Test for invalid email with spaces');
is( check_email_validity('kevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrai@peregrinehw.com'), 1, 'Test for email address with local-part that is exactly 64 characters');
is( check_email_validity('kevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrail@peregrinehw.com'), 0, 'Test for invalid email address with local-part that is too long');
is( check_email_validity('kevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrailkevin.mcgrail@peregrinehw.com'), 0, 'Test for invalid email address that is too long');
