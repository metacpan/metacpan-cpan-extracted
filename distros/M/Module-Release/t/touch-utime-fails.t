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

BEGIN {
*CORE::GLOBAL::utime = sub { '' };
}

my @subs = qw(touch);

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
	
	CORE::utime $past, $past, $name;
	cmp_ok( -M $name, ">", 2, "File is older than two days" );
	}
	
CORE::utime $future, $future, $files[-1];
cmp_ok( -M $files[-1], "<", 2, "File is newer than two days (in the future)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test that it fails if utime doesn't work
{
foreach my $file ( @files )
	{
	CORE::utime( $past, $past, $file );
	is( (stat $file)[9], $past, "Set $file to past time" );
	}
	
stderr_like
	{ $release->touch( @files ) }
	qr/did not set utime/,
	"utime for $file failed (good)"
}