#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Passwords;
use Test::More;

plan tests => 1;

my %info = password_get_info('$2y$07$YEfmYEfmYEfmYEfmYEfmY.Iyc8r2EAVVZauJ9yIJXepp02av/0mCS');

is_deeply(\%info, {
    'algoName' => 'bcrypt',
    'algo' => 1,
    'options' => {
        'cost' => 7,
    }
});