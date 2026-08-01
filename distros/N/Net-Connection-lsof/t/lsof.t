#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Connection::lsof') || print "Bail out!\n";
}

my $output_raw = `lsof -i UDP -i TCP -n -l -P 2> /dev/null`;
if (
	( $? == 0 )
	|| (   ( $^O eq 'linux' )
		&& ( $? == 256 ) )
	)
{
	my @nc_objects;
	my $worked = eval {

		# skip resolving so the test does not stall on slow DNS,
		# but leave proc_info on so that path gets a live test
		@nc_objects = lsof_to_nc_objects( { ports => 0, ptrs => 0, uid_resolve => 0 } );
		1;
	};

	ok( $worked, 'lsof_to_nc_objects' ) or diag( 'lsof_to_nc_objects died with ' . $@ );

	if ($worked) {
		my $all_nc_objects = 1;
		foreach my $nc_object (@nc_objects) {
			if ( !ref($nc_object) || !$nc_object->isa('Net::Connection') ) {
				$all_nc_objects = 0;
			}
		}
		ok( $all_nc_objects, 'everything returned is a Net::Connection object' );
	}
} ## end if ( ( $? == 0 ) || ( ( $^O eq 'linux' ) &&...))

done_testing();
