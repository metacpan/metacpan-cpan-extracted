#!/usr/bin/perl

use Module::ScanDeps;
use strict;
use warnings;

use Test::More qw(no_plan); # no_plan because the number of objects in the dependency tree (and hence the number of tests) can change
use Test::Requires qw( Module::Pluggable );

use lib qw(t t/data/pluggable);
use Utils;

my $rv = scan_deps(
  files   => ['t/data/pluggable/Foo.pm'],
  recurse => 1,
);

my @deps = qw(Module/Pluggable.pm Foo/Plugin/Bar.pm Foo/Plugin/Baz.pm);
generic_scandeps_rv_test($rv, ['t/data/pluggable/Foo.pm'], \@deps);

__END__
