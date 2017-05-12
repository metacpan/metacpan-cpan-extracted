#!/usr/bin/perl
# $Id$

use strict;
use Test::More tests => 43;
use FindBin qw($Bin);
use RPM4;
use RPM4::Header::Dependencies;

my %_minfo = RPM4::moduleinfo;

isa_ok(
    RPM4::rpmlibdep(),
    'RPM4::Header::Dependencies',
    "Can get a dep for rpmlib"
);

my $htest = RPM4::Header->new("$Bin/test-rpm-1.0-1mdk.noarch.rpm");
my $hdep = RPM4::Header->new("$Bin/test-dep-1.0-1mdk.noarch.rpm");
isa_ok($htest, 'RPM4::Header', '$htest');
isa_ok($hdep, 'RPM4::Header' , '$hdep');

isa_ok(
    $hdep->dep("CONFLICTNAME"),
    'RPM4::Header::Dependencies',
    '$hdep->dep("CONFLICTNAME")'
);
isa_ok(
    $hdep->dep("REQUIRENAME"),
    'RPM4::Header::Dependencies',
    '$hdep->dep("REQUIRENAME")'
);
isa_ok(
    $hdep->dep("OBSOLETENAME"),
    'RPM4::Header::Dependencies',
    '$hdep->dep("OBSOLETENAME")'
);
isa_ok(
    $hdep->dep("PROVIDENAME"),
    'RPM4::Header::Dependencies',
    '$hdep->dep("PROVIDENAME")'
);
ok(
    ! defined($hdep->dep("TRIGGERNAME")),
    "fetching triggers returns undef"
);

ok($htest->compare($hdep) == 0, "Compare two header");
ok($hdep->compare($htest) == 0, "Compare two header");

ok(! defined($htest->hchkdep($hdep, "REQUIRENAME")),  "test-rpm requires test-dep,  no");
ok(  defined($hdep->hchkdep($htest, "REQUIRENAME")),  "test-dep requires test-rpm,  yes");
ok(! defined($htest->hchkdep($hdep, "OBSOLETENAME")), "test-rpm obsoletes test-dep, no");
ok(  defined($hdep->hchkdep($htest, "OBSOLETENAME")), "test-dep obsoletes test-rpm, yes");
ok(! defined($htest->hchkdep($hdep, "CONFLICTNAME")), "test-rpm conflics test-dep,  no");
ok(  defined($hdep->hchkdep($htest, "CONFLICTNAME")), "test-dep conflicts test-rpm, yes");
ok(! defined($htest->hchkdep($hdep, "TRIGGERNAME")),  "test-rpm trigger test-dep,   no");
ok(! defined($hdep->hchkdep($htest, "TRIGGERNAME")),  "test-dep trigger test-rpm,   no");
ok(! defined($htest->hchkdep($hdep, "PROVIDENAME")),  "test-rpm provide test-dep,   no");
ok(! defined($hdep->hchkdep($htest, "PROVIDENAME")),  "test-dep provide test-rpm,   no");

ok(  $hdep->is_better_than($htest), "test-dep better than test-rpm: yes");
ok(! $htest->is_better_than($hdep), "test-rpm better than test-dep: no");

my ($dep1, $dep2, $dep3);
isa_ok(
    RPM4::Header::Dependencies->new("REQUIRENAME",
        [ "test-rpm", [ qw(LESS EQUAL) ], "1.0-1mdk" ]
    ),
    'RPM4::Header::Dependencies',
    'New REQUIRENAME dependencies'
);

ok($dep1 = RPM4::newdep("REQUIRENAME", "test-rpm", [ qw(LESS EQUAL) ], "1.0-1mdk"), "Build a new dep");
ok($dep2 = RPM4::newdep("REQUIRENAME", "test-rpm", [ qw(GREATER EQUAL) ], "1.0-1mdk"), "Build a new dep");
ok($dep3 = RPM4::newdep("REQUIRENAME", "test-rpm", [ "GREATER" ], "1.0-1mdk"), "Build a new dep");

is($dep1->count, 1, "dependencies number");
ok(defined($dep1->move), "Can move into dep");
ok($dep1->next == -1, "no further dependency");

ok($dep1->add("test-dep", [ qw(LESS EQUAL) ], "1.0-1mdk"), "Add a dep entry into existing dep");

ok(scalar($dep1->info) eq "R test-rpm <= 1.0-1mdk", "Can get info from RPM4::Header::Dep");
ok(($dep1->info)[3] eq "1.0-1mdk", "Can get info from RPM4::Header::Dep");
ok($dep1->name eq 'test-rpm', "Get dep name from RPM4::Header::Dep");
ok($dep1->flags, "Get dep flags from RPM4::Header::Dep");
ok($dep1->evr eq '1.0-1mdk', "Get dep evr from RPM4::Header::Dep");

ok($dep1->overlap($dep2), "compare two dep");
ok($dep1->overlap($dep3) == 0, "compare two dep");

ok($htest->matchdep($dep1), "Test single dep PROVIDE");
ok($htest->matchdep($dep3) == 0, "Test single dep REQUIRE");

ok($hdep->matchdep($dep1) == 0, "Test single dep PROVIDE");
ok($htest->matchdep($dep2), "Test single dep REQUIRE");

ok(  $dep1->matchheadername($htest), "Dependancy match header name: yes");
ok(! $dep1->matchheadername($hdep),  "Dependancy match header name: no");
