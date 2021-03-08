#!perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Pinto::Remote::SelfContained::Util qw(mask_uri_passwords);

is( mask_uri_passwords('http://www.example.com/'),
    'http://www.example.com/',
    'mask_uri_passwords: nothing to mask' );

is( mask_uri_passwords('http://fred:sekr1t@www.example.com/'),
    'http://fred:*password*@www.example.com/',
    'mask_uri_passwords: password' );

had_no_warnings();
done_testing();
