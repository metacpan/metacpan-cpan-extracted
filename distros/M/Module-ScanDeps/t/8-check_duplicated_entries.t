#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;
use lib qw(t t/data/duplicated_entries);
use Utils;


##############################################################
# Tests compilation of Module::ScanDeps
##############################################################
BEGIN { use_ok( 'Module::ScanDeps' ); }

my @roots = qw(t/data/duplicated_entries/use_scoped_package.pl t/data/duplicated_entries/Scoped/Package.pm);
my $expected_rv =
{
  "use_scoped_package.pl" => {
                               file => generic_abs_path("t/data/duplicated_entries/use_scoped_package.pl"),
                               key  => "use_scoped_package.pl",
                               type => "data",
                               uses => ["Scoped/Package.pm"],
                             },
  "Scoped/Package.pm"     => {
                               file    => generic_abs_path("t/data/duplicated_entries/Scoped/Package.pm"),
                               key     => "Scoped/Package.pm",
                               type    => "module",
                               used_by => ["use_scoped_package.pl"],
                             },
};

# Functional i/f
my $rv = scan_deps(@roots);
compare_scandeps_rvs($rv, $expected_rv, \@roots);

__END__
