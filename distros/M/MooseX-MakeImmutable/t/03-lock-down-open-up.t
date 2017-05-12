use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use MooseX::MakeImmutable;
use t::Test::Alpha;
use t::Test::Charlie;

MooseX::MakeImmutable->lock_down(qw/package t::Test::Bravo/);

ok($_->meta->is_immutable) for qw/t::Test::Bravo t::Test::Bravo::Moose/;
ok(! $_->meta->is_immutable) for qw/t::Test::Alpha t::Test::Charlie/;

MooseX::MakeImmutable->open_up(qw/package t::Test::Bravo/);
MooseX::MakeImmutable->open_up(qw/package t::Test::Alpha/);
ok(! $_->meta->is_immutable) for qw/t::Test::Alpha t::Test::Bravo t::Test::Bravo::Moose t::Test::Charlie/;

package t::Test::MyPackage;

use Moose;

MooseX::MakeImmutable->lock_down;

package main;

ok($_->meta->is_immutable) for qw/t::Test::MyPackage/;

throws_ok {
    MooseX::MakeImmutable->lock_down;
} qr/MooseX::MakeImmutable::lock_down\(\): Can't lock down main::/;
