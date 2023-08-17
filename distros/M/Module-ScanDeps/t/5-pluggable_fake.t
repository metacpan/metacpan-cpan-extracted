#!/usr/bin/perl

use Module::ScanDeps;
use strict;
use warnings;

use Test::More tests => 1;

use Test::Requires qw( Module::Pluggable );

use lib qw(t t/data/pluggable);
use Utils;

my $rv = scan_deps(
  files   => ['t/data/pluggable/Foo.pm'],
  recurse => 1,
);

my @deps = qw(Module/Pluggable.pm Foo/Plugin/Bar.pm Foo/Plugin/Baz.pm);
check_rv($rv, ['t/data/pluggable/Foo.pm'], \@deps);

