#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Passwords;
use Test::More;

plan tests => 3;

is password_verify('rasmuslerdorf', '$2y$07$usesomesillystringfore2uDLvp1Ii2e./U9C8sBjqp8I90dH6hi'), 1;
is password_verify('perlhipster', '$2y$10$hoMzKUY2O7kcnNp/RBcxBuo0IR2HplzOj9BZ.yz9Fh56iJ1peKsKu'), 1;
isnt password_verify('perlhipster', '$2y$10$hoMzKUY2O7kcnNp/RBcxBuo0IR2HplzOj9BZ.yz8Fh56iJ1peKsKu'), 1;
