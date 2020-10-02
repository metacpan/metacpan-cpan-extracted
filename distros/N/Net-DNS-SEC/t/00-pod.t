#!/usr/bin/perl
# $Id: 00-pod.t 1808 2020-09-28 22:08:11Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

my %prerequisite = ( 'Test::Pod' => 1.45 );

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep {$_} $prerequisite{$package};
	next if eval "use $package @revision; 1;";		## no critic
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}


my @poddirs = qw( blib demo );
my @allpods = all_pod_files(@poddirs);
all_pod_files_ok(@allpods);

exit;

__END__

