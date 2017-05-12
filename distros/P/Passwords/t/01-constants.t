#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Passwords;
use Test::More;

plan tests => 2;

is PASSWORD_DEFAULT, 1;
is PASSWORD_BCRYPT , 1;
