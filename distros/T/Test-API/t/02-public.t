# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;
use lib '.';

select STDERR;
$|++;
select STDOUT;
$|++;

use Test::More;
use Test::Builder::Tester 1.18;
use Test::API;

plan tests => 12;

require_ok('t::lib::NoSubs');
require_ok('t::lib::SubFoo');
require_ok('t::lib::UseCarp');
require_ok('t::lib::PvtFoo');

test_out("not ok 1 - public API for t::lib::NonExisting");
test_fail(+2);
test_diag("Module 't::lib::NonExisting' not loaded");
public_ok('t::lib::NonExisting');
test_test('public_ok - module not loaded');

test_out("ok 1 - public API for t::lib::NoSubs");
public_ok('t::lib::NoSubs');
test_test('public_ok - none provided, none expected');

test_out("not ok 1 - public API for t::lib::NoSubs");
test_fail(+2);
test_diag("missing: foo");
public_ok( 't::lib::NoSubs', 'foo' );
test_test('public_ok - none provided, one expected');

test_out("not ok 1 - public API for t::lib::SubFoo");
test_fail(+2);
test_diag("extra: foo");
public_ok('t::lib::SubFoo');
test_test('public_ok - one provided, none expected');

test_out("ok 1 - public API for t::lib::SubFoo");
public_ok( 't::lib::SubFoo', 'foo' );
test_test('public_ok - one provided, one expected');

test_out("not ok 1 - public API for t::lib::UseCarp");
test_fail(+2);
test_diag( "missing: foo", "extra: carp confess croak" );
public_ok( 't::lib::UseCarp', 'foo' );
test_test('public_ok - use Carp + missing sub');

test_out("ok 1 - public API for t::lib::PvtFoo");
public_ok('t::lib::PvtFoo');
test_test('public_ok - private provided, none expected');

{
    package PackWithConst;
    use constant foo => 1;
    $INC{"PackWithConst.pm"}++;
}

test_out("ok 1 - public API for PackWithConst");
public_ok("PackWithConst", "foo");
test_test('public_ok - works with packages containing constants');
