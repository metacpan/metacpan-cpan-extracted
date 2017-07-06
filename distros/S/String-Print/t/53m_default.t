#!/usr/bin/env perl
# Test the 'undef default' modifier

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

### these are all examples from the manual page

is $f->sprinti("visitors: {count //0}", count => 1), "visitors: 1", 'count';
is $f->sprinti("visitors: {count //0}", count => undef), "visitors: 0";
is $f->sprinti("visitors: {count//0}",  count => undef), "visitors: 0";

is $f->sprinti("published: {date DT//'not yet'}", date => undef),
   "published: not yet", 'date';
is $f->sprinti('published: {date DT//"not yet"}', date => undef),
   "published: not yet";
is $f->sprinti("published: {date DT//'not yet'}", date =>"2017-06-25 12:35:00"),
   "published: 2017-06-25 12:35:00";

is $f->sprinti("copyright: {year//2017 YEAR}", year => " 2018 "),
   'copyright: 2018', 'year';
is $f->sprinti("copyright: {year//2017 YEAR}", year => undef),
   'copyright: 2017';

$f->addModifiers(qw/EUR\b/ => sub {
    my ($sp, $format, $value, $args) = @_;
    defined $value ? "$value€" : undef;
});

is $f->sprinti("price: {price//5 EUR}", price => 3), 'price: 3€', 'price';
is $f->sprinti("price: {price//5 EUR}", price => undef), 'price: 5€';
is $f->sprinti("price: {price EUR//unknown}", price => 3), 'price: 3€';
is $f->sprinti("price: {price EUR//unknown}", price => undef), 'price: unknown';

done_testing;
