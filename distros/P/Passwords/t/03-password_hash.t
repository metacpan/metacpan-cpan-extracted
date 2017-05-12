#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Passwords;
use Test::More;

plan tests => 1;

is password_hash('perlhipster', PASSWORD_BCRYPT, ('cost' => 7, 'salt' => 'hhhhhhhhhhhhhhhh')), '$2y$07$YEfmYEfmYEfmYEfmYEfmY.Iyc8r2EAVVZauJ9yIJXepp02av/0mCS';