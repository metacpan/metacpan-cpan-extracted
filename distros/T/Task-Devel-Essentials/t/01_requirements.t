# Copyright (c) 2014-2020 by Martin Becker, Blaubeuren.
# This script is free software; you can redistribute it and/or modify it
# under the terms of the Artistic License 2.0 (see the LICENSE file).
#
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01_requirements.t'

use strict;
use warnings;
use Test::More 0.82;

$ENV{'NYTPROF'} = 'start=no';

my $MAKEFILE_PL = 'Makefile.PL';

my @modules  = ();
my $versions = 0;

if (!open MF, '<', $MAKEFILE_PL) {
    plan skip_all => "cannot open $MAKEFILE_PL";
}
while (<MF>) {
    if (/^\s*requires\s*'([\w:]+)'\s*=>\s*'?([\d.]+)'?\s*;\s*\z/) {
        push @modules, [$1, $2];
        ++$versions if $2;
    }
}
close MF;
if (!@modules) {
    plan skip_all => "could not parse requirements in $MAKEFILE_PL";
}
plan tests => @modules + $versions;

foreach my $mv (@modules) {
    my ($module, $version) = @{$mv};
    require_ok $module;
    version_ok($module, $version) if $version;
}

sub version_ok {
    my ($module, $version) = @_;
    SKIP: {
        my $loaded = defined eval '$' . $module . '::VERSION';
        skip "$module not loaded", 1 if !$loaded;

        my $have = eval { $module->VERSION($version) };
        my $ok   = defined $have;
        ok $ok, "version_ok $module => $version";
        note("we have $module version $have") if $ok && $version ne $have;
        diag($@) if !$ok;
    }
}

__END__
