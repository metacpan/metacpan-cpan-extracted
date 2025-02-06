#!/usr/bin/perl
# $Id: 00-pod.t 1856 2021-12-02 14:36:25Z willem $	-*-perl-*-
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

