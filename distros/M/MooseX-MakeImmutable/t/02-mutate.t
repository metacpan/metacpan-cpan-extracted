use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use MooseX::MakeImmutable

MooseX::MakeImmutable->make_immutable(<<_END_);
t::Test::Alpha
t::Test::Bravo
t::Test::Charlie
_END_

ok($_->meta->is_immutable) for qw/t::Test::Alpha t::Test::Bravo t::Test::Bravo::Moose t::Test::Charlie/;

MooseX::MakeImmutable->make_mutable(<<_END_);
t::Test::*
_END_

ok(! $_->meta->is_immutable) for qw/t::Test::Alpha t::Test::Bravo t::Test::Bravo::Moose t::Test::Charlie/;
