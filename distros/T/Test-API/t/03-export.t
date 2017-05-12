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

plan tests => 14;

require_ok('t::lib::NoSubs');
require_ok('t::lib::Export');
require_ok('t::lib::ExportComplex');

#--------------------------------------------------------------------------#
# not loaded
#--------------------------------------------------------------------------#

test_out("not ok 1 - importing from t::lib::NonExisting");
test_fail(+2);
test_diag("Module 't::lib::NonExisting' not loaded");
import_ok('t::lib::NonExisting');
test_test('import_ok - module not loaded');

#--------------------------------------------------------------------------#
# nothing exported
#--------------------------------------------------------------------------#

test_out("ok 1 - importing from t::lib::NoSubs");
import_ok('t::lib::NoSubs');
test_test('import_ok - export: none; expect: none');

test_out("not ok 1 - importing from t::lib::NoSubs");
test_fail(+2);
test_diag("not exported: foo");
import_ok( 't::lib::NoSubs', export => 'foo' );
test_test('import_ok - export: none; expect: foo');

#--------------------------------------------------------------------------#
# just one sub exported
#--------------------------------------------------------------------------#

test_out("ok 1 - importing from t::lib::Export");
import_ok( 't::lib::Export', export => [qw/foo/] );
test_test('import_ok - export: foo; expect: foo');

test_out("not ok 1 - importing from t::lib::Export");
test_fail(+2);
test_diag("unexpectedly exported: foo");
import_ok('t::lib::Export');
test_test('import_ok - export: foo; expect: none');

#--------------------------------------------------------------------------#
# multi-subs exported
#--------------------------------------------------------------------------#

test_out("ok 1 - importing from t::lib::ExportComplex");
import_ok(
    't::lib::ExportComplex',
    export    => [qw/foo bar/],
    export_ok => [qw/baz bam/]
);
test_test('import_ok - export: several; expect: several');

test_out("not ok 1 - importing from t::lib::ExportComplex");
test_fail(+2);
test_diag("unexpectedly exported: bar foo");
import_ok(
    't::lib::ExportComplex',
    export    => [],
    export_ok => [qw/baz bam/],
);
test_test('import_ok - export: several; expect: none');

test_out("not ok 1 - importing from t::lib::ExportComplex");
test_fail(+2);
test_diag("unexpectedly exported: bar");
import_ok(
    't::lib::ExportComplex',
    export    => ['foo'],
    export_ok => [qw/baz bam/]
);
test_test('import_ok - export: several; expect: one');

#--------------------------------------------------------------------------#
# export_ok
#--------------------------------------------------------------------------#

test_out("ok 1 - importing from t::lib::ExportComplex");
import_ok(
    't::lib::ExportComplex',
    export    => [qw/foo bar/],
    export_ok => [qw/baz bam/]
);
test_test('import_ok - export_ok several functions');

test_out("not ok 1 - importing from t::lib::ExportComplex");
test_fail(+2);
test_diag("not optionally exportable: wibble");
import_ok(
    't::lib::ExportComplex',
    export    => [qw/foo bar/],
    export_ok => [qw/wibble baz bam/]
);
test_test('import_ok - export_ok a missing function');

test_out("not ok 1 - importing from t::lib::ExportComplex");
test_fail(+2);
test_diag("extra optionally exportable: bam baz");
import_ok( 't::lib::ExportComplex', export => [qw/foo bar/], );
test_test('import_ok - export_ok excludes items in @EXPORT_OK');

