#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use Data::Dumper;
use File::Temp qw(tempfile);
use Getopt::Long;
use Parse::CPAN::Packages::Fast;
use Test::More 'no_plan';

use TestUtil;

my $do_all;
GetOptions("a|all" => \$do_all)
    or die "usage: $0 [-a]";

my($tmpfh, $cache_file) = tempfile(UNLINK => 1)
    or die $!;
close $tmpfh;
utime 0, 0, $cache_file; # so the modtime check of _get_plain_packages_fh works
my $orig_packages_file = my_default_packages_file;
SKIP: {
    skip "Cannot get default CPAN packages index file", 1
	if !$orig_packages_file;

    my $pcpf = Parse::CPAN::Packages::Fast->new($orig_packages_file);
    my $i = 0;
    for my $package ($pcpf->packages) {
	my $ret = Parse::CPAN::Packages::Fast->_module_lookup($package, $orig_packages_file, $cache_file);
	is $ret->{package}, $package
	    or diag Dumper($ret);
	last if $i++>10 && !$do_all;
    }

    {
	my $ret = Parse::CPAN::Packages::Fast->_module_lookup("This module does not exist", $orig_packages_file, $cache_file);
	is $ret, undef;
    }
}
