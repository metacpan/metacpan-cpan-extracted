#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';


my $object = user_account(
    user_id                 => '1001',
    account_login           => 'jdoe',
    account_type            => 'unix',
    display_name            => 'John Doe',
    is_service_account      => !!0,
    is_privileged           => !!0,
    can_escalate_privs      => !!1,
    account_created         => '2016-01-20T12:31:12',
    credential_last_changed => '2016-01-20T14:27:43',
    account_first_login     => '2016-01-20T14:26:07',
    account_last_login      => '2016-07-22T16:08:28',
);

my @errors = $object->validate;

diag 'Basic UNIX Account', "\n", "$object";

isnt "$object", '';

is $object->type, 'user-account';

is @errors, 0;

done_testing();
