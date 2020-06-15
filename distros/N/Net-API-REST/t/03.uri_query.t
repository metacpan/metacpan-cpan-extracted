#!/usr/bin/perl
BEGIN
{
	use strict;
	use Test::More qw( no_plan );
    use_ok( 'Net::API::REST::Query' );
};

my $qs = 'lang=ja_JP&name=%E3%83%AA%E3%83%BC%E3%82%AC%E3%83%AB%E3%83%86%E3%83%83%E3%82%AF%E3%83%97%E3%83%AC%E3%83%9F%E3%82%A2%E3%83%A0';

use utf8;
my $test_string = 'リーガルテックプレミアム';
my $q = Net::API::REST::Query->new( $qs );
isa_ok( $q, 'Net::API::REST::Query' );
my $h = $q->hash;
is( $h->{name}, $test_string );



