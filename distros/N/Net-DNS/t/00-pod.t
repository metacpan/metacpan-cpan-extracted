#!/usr/bin/perl
# $Id: 00-pod.t 2007 2025-02-08 16:45:23Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

my %prerequisite = ( 'Test::Pod' => 1.45 );

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep {$_} $prerequisite{$package};
	next if eval "use $package @revision; 1;";	## no critic
	plan skip_all => "$package @revision not installed";
	exit;
}


my @poddirs = qw( . );
my @allpods = grep !m#^[/.]*(blib/|[A-Z]+[-])#i, all_pod_files(@poddirs);
all_pod_files_ok( sort @allpods );


exit;

__END__

