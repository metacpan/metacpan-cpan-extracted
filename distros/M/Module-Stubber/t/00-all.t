#!/usr/bin/perl
use strict;
use warnings;
use Dir::Self;
use lib __DIR__;
use Test::More;
use blib;
use Data::Dumper;


my $status_hash = {};

use Module::Stubber NonExist => [ qw(bad_foo bad_bar bad_baz) ],
    silent => 1,
    status_hash => $status_hash;

ok((bad_foo() || 1), "Got symbols");
ok(!$Module::Stubber::Status{NonExist}, "status hash for NonExist is false");

use Module::Stubber goodmodule => [qw(goodmodule_true)],
    status_hash => $status_hash;

ok($Module::Stubber::Status{goodmodule}, "Status hash for goodmodule is true");
ok(goodmodule_true() eq 'goodmodule', "doesn't interrupt normal functionality");

my $dummy_object = NonExist->new();
ok($dummy_object, "Can create new dummy object");
ok($dummy_object->dummy_method, "Can call dummy methods");

sub defprint {
    print '# ';
    printf(@_);
    printf("\n");
    1;
}

use Module::Stubber 'Fake::Log::Fu' => [],
    will_use => {
        map { $_,\&defprint,$_."f", \&defprint }
        map { "log_" . $_ } qw(warn debug info crit err) },
    silent => 1;

diag "Will have some output here..";
ok(log_warn("Hi") && log_warn("Bye") && log_info("Foo") && log_errf("Meh"),
    "Default coderefs");

diag "Will check to see whether normal subsequent 'use' work";
use_ok('NonExist');

{
    package Blargh;
    use Test::More;
    diag "Checking from different calling package";
    use_ok('Fake::Log::Fu');
}

diag "Checking for import()-less package";
use_ok('Module::Stubber', 'noimport' => []);
done_testing();
