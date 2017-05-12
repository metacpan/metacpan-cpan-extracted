#!/usr/bin/perl -w
use strict;

use Test::CPAN::Meta;
use Test::Builder::Tester tests => 7;

my $testfile = 't/samples/00-META.yml';

test_out('ok 1 - t/samples/00-META.yml contains valid YAML');
test_out('ok 2 - t/samples/00-META.yml meets the designated specification (1.3)');
meta_spec_ok($testfile,'1.3');
test_test("$testfile with version 1.3");

test_out('ok 1 - t/samples/00-META.yml contains valid YAML');
test_out('not ok 2 - t/samples/00-META.yml meets the designated specification (1.2)');
test_fail(2);
test_err('#   ERR: META.yml specification URL does not match version (meta-spec -> url) [Validation: 1.2]');
meta_spec_ok($testfile,'1.2');
test_test("$testfile with version 1.2");

test_out('ok 1 - t/samples/00-META.yml contains valid YAML');
test_out('ok 2 - t/samples/00-META.yml meets the designated specification (1.1)');
meta_spec_ok($testfile,'1.1');
test_test("$testfile with version 1.1");

test_out('ok 1 - t/samples/00-META.yml contains valid YAML');
test_out('ok 2 - t/samples/00-META.yml meets the designated specification (1.0)');
meta_spec_ok($testfile,'1.0');
test_test("$testfile with version 1.0");

test_out('ok 1 - t/samples/00-META.yml contains valid YAML');
test_out('ok 2 - t/samples/00-META.yml meets the designated specification');
meta_spec_ok($testfile);
test_test("$testfile with assumed (1.3) version");

test_out('ok 1 - t/samples/00-META.yml contains valid YAML');
test_out('ok 2 - my own test');
meta_spec_ok($testfile,undef,'my own test');
test_test("$testfile with assumed (1.3) version");

test_out('ok 1 - t/samples/00-META.yml contains valid YAML');
test_out('not ok 2 - bad spec version');
test_fail(2);
test_err('#   ERR: Unknown META.yml specification, cannot validate. [Validation: 0.99]');
meta_spec_ok($testfile,'0.99','bad spec version');
test_test("$testfile with bad spec version 0.99");
