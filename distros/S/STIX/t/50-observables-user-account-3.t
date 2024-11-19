#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';


my $object = user_account(
    user_id            => '1001',
    account_login      => 'jdoe',
    account_type       => 'unix',
    display_name       => 'John Doe',
    is_service_account => !!0,
    is_privileged      => !!0,
    can_escalate_privs => !!1,
    extensions => [unix_account_ext(gid => 1001, groups => ['wheel'], home_dir => '/home/jdoe', shell => '/bin/shell')],
);

my @errors = $object->validate;

diag 'Basic UNIX Account', "\n", "$object";

isnt "$object", '';

is $object->type, 'user-account';

is @errors, 0;

done_testing();
