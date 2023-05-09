#!perl

use Test::Needs qw( CPAN::Meta File::Find::Rule::Perl );

use Test::Builder::Tester tests => 2;
require Test::Dependencies;           # must not be 'use' to avoid import + plan set

chdir "t/data/empty";

test_out("not ok 1 - Missing META.{yml,json} file for dependency checking");
test_fail(+2);
test_diag("Use the non-legacy invocation to provide the info");
Test::Dependencies::ok_dependencies();
test_test("empty directory fails to find META.yml");

chdir "../../../t/data/mostly-empty";

test_out("ok 1 - META.yml is present and readable");
Test::Dependencies::ok_dependencies();
test_test("mostly empty directory works just fine");
