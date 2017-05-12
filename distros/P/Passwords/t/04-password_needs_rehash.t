#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Passwords;
use Test::More;

plan tests => 3;

is password_needs_rehash('$2y$07$YEfmYEfmYEfmYEfmYEfmY.Iyc8r2EAVVZauJ9yIJXepp02av/0mCS', PASSWORD_BCRYPT), 1;
is password_needs_rehash('$2y$07$YEfmYEfmYEfmYEfmYEfmY.Iyc8r2EAVVZauJ9yIJXepp02av/0mCS', PASSWORD_BCRYPT, 'cost' => 5), 1;
isnt password_needs_rehash('$2y$07$YEfmYEfmYEfmYEfmYEfmY.Iyc8r2EAVVZauJ9yIJXepp02av/0mCS', PASSWORD_BCRYPT, 'cost' => 7), 1;