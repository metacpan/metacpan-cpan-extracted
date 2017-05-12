#!/usr/bin/env perl

# Copyright (C) 2009, Pascal Gaudette.

use strict;
use warnings;

use Test::More;
use Mojo::URL;
use Mojo::Cookie::Response;
use MojoX::UserAgent::CookieJar;

plan tests => 30;

my $jar = MojoX::UserAgent::CookieJar->new;
my $cookie1 = Mojo::Cookie::Response->new;

$cookie1->name('foo');
$cookie1->value('1');
$cookie1->path('/foo');
$cookie1->domain('acajou.ca');
$cookie1->max_age(6000);

my $cookie2 = Mojo::Cookie::Response->new;

$cookie2->name('bar');
$cookie2->value('2');
$cookie2->path('/bar');
$cookie2->domain('acajou.ca');
$cookie2->max_age(6000);

my $cookie3 = Mojo::Cookie::Response->new;

$cookie3->name('host');
$cookie3->value('www');
$cookie3->path('/');
$cookie3->domain('www.acajou.ca');
$cookie3->max_age(6000);

$jar->store($cookie1, $cookie2, $cookie3);

is($jar->size, 3, "Stored 3 cookies");

my $returned;

$returned = $jar->cookies_for_url('http://boo.acajou.ca/foo/');

is(scalar @{$returned}, 1, 'Jar returned right number of cookies.');
is(${returned}->[0], $cookie1, 'Jar returned right cookie.');

$returned = $jar->cookies_for_url('http://bon.acajou.ca/bar/baz/');

is(scalar @{$returned}, 1, 'Jar returned right number of cookies.');
is($returned->[0], $cookie2, 'Jar returned right cookie.');

$returned = $jar->cookies_for_url('http://www.acajou.ca/');

is(scalar @{$returned}, 1, 'Jar returned right number of cookies.');
is($returned->[0], $cookie3, 'Jar returned right cookie.');

$returned = $jar->cookies_for_url('http://www.acajou.ca/foo/test#zop');

is(scalar @{$returned}, 2, 'Jar returned right number of cookies.');
isnt($returned->[0], $cookie2, 'Should not return $cookie2 (1/2)');
isnt($returned->[1], $cookie2, 'Should not return $cookie2 (2/2)');


# Delete cookie
my $cookie_unset = Mojo::Cookie::Response->new;

$cookie_unset->name('host');
$cookie_unset->value('www');
$cookie_unset->path('/');
$cookie_unset->domain('www.acajou.ca');
$cookie_unset->max_age(0);

$jar->store($cookie_unset);

$returned = $jar->cookies_for_url('http://www.acajou.ca/foo/test#zop');

is($jar->size, 2, "One cookie removed");
is(scalar @{$returned}, 1, 'Jar returned right number of cookies.');
is($returned->[0], $cookie1, 'Jar returned right cookie(s).');

$returned = $jar->cookies_for_url('http://www.not.ca/foo/test#zop');
is(scalar @{$returned}, 0, 'Jar returned right number of cookies.');


# Replace cookie

my $cookie4 = Mojo::Cookie::Response->new;

$cookie4->name('bar');
$cookie4->value('23456');
$cookie4->path('/bar');
$cookie4->domain('acajou.ca');
$cookie4->max_age(6000);

$jar->store($cookie4); # replaces old

is($jar->size, 2, "One cookie replaced");

$returned = $jar->cookies_for_url('http://www.zop.acajou.ca/bar/test#zop');

is(scalar @{$returned}, 1, "Returned right number of cookies");
is($returned->[0]->name, 'bar', "Returned right cookie");
is($returned->[0]->value, '23456', "Cookie value good");


# Delete cookie through expires

my $cookie5 = Mojo::Cookie::Response->new;

$cookie5->name('bar');
$cookie5->value('dontmatter');
$cookie5->path('/bar');
$cookie5->domain('acajou.ca');
$cookie5->expires("Mon, 07 Nov 1994 03:03:03 GMT");

$jar->store($cookie5);


is($jar->size, 1, "One cookie deleted");

$returned = $jar->cookies_for_url('http://www.zop.acajou.ca/bar/test#zop');

is(scalar @{$returned}, 0, "Cookie confirmed gone");


# expire a cookie with expires

my $cookie6 = Mojo::Cookie::Response->new;

$cookie6->name('baz');
$cookie6->value('e0e0e0');
$cookie6->path('/baz');
$cookie6->domain('acajou.ca');
$cookie6->expires(time+2);

$jar->store($cookie6);


is($jar->size, 2, "Cookie stored");

$returned = $jar->cookies_for_url('http://www.zop.acajou.ca/baz/test#zop');

is(scalar @{$returned}, 1, "Cookie returned");
is($returned->[0]->value, 'e0e0e0', "Cookie value good");

sleep(3);

$returned = $jar->cookies_for_url('http://www.zop.acajou.ca/baz/test#zop');

is(scalar @{$returned}, 0, "Cookie expired");
is($jar->size, 1, "Size of jar good");


# expire a cookie with max-age

my $cookie7 = Mojo::Cookie::Response->new;

$cookie7->name('bop');
$cookie7->value('1b1b1b');
$cookie7->path('/bop');
$cookie7->domain('acajou.ca');
$cookie7->max_age(2);

$jar->store($cookie7);

is($jar->size, 2, "Cookie stored");

$returned = $jar->cookies_for_url('http://www.zop.acajou.ca/bop/test#zop');

is(scalar @{$returned}, 1, "Cookie returned");
is($returned->[0]->value, '1b1b1b', "Cookie value good");

sleep(3);

$returned = $jar->cookies_for_url('http://www.zop.acajou.ca/bop/test#zop');

is(scalar @{$returned}, 0, "Cookie expired");
is($jar->size, 1, "Size of jar good");
