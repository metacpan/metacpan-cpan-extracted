#!/usr/bin/perl

use strict;
use warnings;

use Mojo::Snoo::Thing;
use Test::More tests => 6;
use Test::Exception;

lives_ok {
    Mojo::Snoo::Thing->new;
} 'creates Mojo::Snoo::Thing ok';

# test that data objects are created
my $comment = Mojo::Snoo::Thing->get_instance('t1_38t1hf');
isa_ok($comment, 'Mojo::Snoo::Comment', 'creates comment object');

my $link = Mojo::Snoo::Thing->get_instance('t3_15bfi0');
isa_ok($link, 'Mojo::Snoo::Link', 'creates link object');

my $subreddit = Mojo::Snoo::Thing->get_instance('t5_perl');
isa_ok($subreddit, 'Mojo::Snoo::Subreddit', 'creates subreddit object');

throws_ok {
    Mojo::Snoo::Thing->get_instance('_perl');
} qr/Missing type prefix/,
    'fails when given no type prefix';

throws_ok {
    Mojo::Snoo::Thing->get_instance('t10_perl');
} qr/Unsupported type prefix/,
    'fails when given fake type prefix';
