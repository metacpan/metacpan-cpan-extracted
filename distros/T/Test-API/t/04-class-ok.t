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

plan tests => 5;

require_ok('t::lib::Parent');
require_ok('t::lib::Child');

#--------------------------------------------------------------------------#
# not loaded
#--------------------------------------------------------------------------#

test_out("not ok 1 - public API for class t::lib::Child");
test_fail(+2);
test_diag("extra: www");
class_api_ok( 't::lib::Child', qw(xxx yyy zzz) );
test_test('class_api_ok - missing method');

test_out("ok 1 - public API for class t::lib::Child");
class_api_ok( 't::lib::Child', qw(www xxx yyy zzz) );
test_test('class_api_ok - complete set of methods');

test_out("ok 1 - public API for class t::lib::Child");
class_api_ok( 't::lib::Child', qw(www xxx yyy) );
test_test('class_api_ok - missing inherited method');
