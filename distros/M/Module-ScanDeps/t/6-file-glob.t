#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Module::ScanDeps;
use lib qw(t/data);

my $map = scan_deps(
    files   => ['t/data/file-glob-no.pl'],
    recurse => 1,
);

ok(not exists $map->{'File/Glob.pm'});

$map = scan_deps(
    files => ['t/data/file-glob-yes.pl'],
    recurse => 1,
);

ok(exists $map->{'File/Glob.pm'});

__END__
