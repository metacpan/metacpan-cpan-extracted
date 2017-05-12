# $Id: 00-pod.t 1381 2015-08-25 07:36:09Z willem $
#

use strict;
use Test::More;

my %prerequisite = qw(
		Test::Pod 1.45
		);

while ( my ( $package, $rev ) = each %prerequisite ) {
	eval "use $package $rev";
	next unless $@;
	plan skip_all => "$package $rev required for testing POD";
	exit;
}


my @poddirs = qw( blib demo );
my @allpods = all_pod_files(@poddirs);
all_pod_files_ok(@allpods);

