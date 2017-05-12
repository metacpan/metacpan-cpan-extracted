#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Output;

use Cwd;

my $class = 'Module::Release';
my $file  = ".releaserc";

use_ok( $class );
can_ok( $class, 'new' );

BEGIN {
	use File::Spec;
	my $file = File::Spec->catfile( qw(t lib setup_common.pl) );
	require $file;
	}


my @subs = qw(touch touch_all_in_manifest);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create test object
my $release = $class->new;
isa_ok( $release, $class );
can_ok( $release, @subs );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# make some files
my @files = qw(one two three);
END { unlink @files }

my $past   = time - 200_000;
my $future = time + 200_000;

foreach my $name ( @files )
	{
	open my($fh), ">", $name; close $fh;
	ok( -e $name, "test file $name exists" );
	
	utime $past, $past, $name;
	cmp_ok( -M $name, ">", 2, "File is older than two days" );
	}
	
utime $future, $future, $files[-1];
cmp_ok( -M $files[-1], "<", 2, "File is newer than two days (in the future)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test that it works
{
my $start = time;
my $count = $release->touch( @files );
my $end = time;

foreach my $file ( @files )
	{
	foreach my $time ( (stat $file)[8,9] )
		{
		cmp_ok( $time, ">=", $start, "Time for $file is greater than start time" );
		cmp_ok( $time, "<=", $end,   "Time for $file is less than end time" );
		}
	}

is( $count, scalar @files, "All files touched" );

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test that it fails with non-existent file
{
$release->turn_quiet_off;

my $count = 0;

stderr_like
	{ $release->touch( 'not_there' ) }
	qr/not a plain file/,
	"touch fails for non-existent file";

is( $count, 0, "No files touched (good)" );
}

