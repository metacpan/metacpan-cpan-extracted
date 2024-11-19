#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use STIX ':sco';


my $object = user_account(
    user_id       => 'thegrugq_ebooks',
    account_login => 'thegrugq_ebooks',
    account_type  => 'twitter',
    display_name  => 'the grugq',
);

my @errors = $object->validate;

diag 'Basic Twitter Account', "\n", "$object";

isnt "$object", '';

is $object->type, 'user-account';

is @errors, 0;

done_testing();
