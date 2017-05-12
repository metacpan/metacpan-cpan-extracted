#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
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

my @subs = qw(
	manifest_name files_in_manifest touch_all_in_manifest check_manifest
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create test object
my $release = $class->new;
isa_ok( $release, $class );
can_ok( $release, @subs );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
{
my $filename = $release->manifest_name;
ok( defined $filename, "manifest_name returns something that is defined" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# check deprecation warning
{
stderr_like
	{ $release->manifest }
	qr/deprecated/,
	"Get deprecation warning from calling manifest";
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# test with no MANIFEST file. Should die.
{
ok( ! -e $release->manifest_name, "MANIFEST file is not there (good)" );
my @files = eval { $release->files_in_manifest };
my $at = $@;
ok( defined $at, "eval fails when MANIFEST is not present" );
like( $at, qr/could not open/, "Error message says it could not open file" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create MANIFEST file and some files for it.
my %files = map { $_, 1 } qw(README Changes Makefile.PL Foo.pm);
END { unlink keys %files }

{
open my($fh), ">", $release->manifest_name or warn "Could not create $file: $!";
print $fh "$_\n" for keys %files;
close $fh;

ok( -e $release->manifest_name, "MANIFEST file is there" );

my @files = eval { $release->files_in_manifest };
my $at = $@;
ok( ! length $at, "eval did not fail when MANIFEST exists" );
is( scalar @files, scalar keys %files,
	"files_in_manifest returns the right number of files" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# create the files in MANIFEST
{
foreach my $file ( keys %files )
	{
	open my($fh), ">", $file or warn "Could not create $file: $!";
	close $fh;
	ok( -e $file, "file [$file] exists" );
	}

my $past = time - 86400;

utime $past, $past, keys %files;

foreach my $file ( keys %files )
	{
	ok( -M $file > 0.9, "file [$file] is about one day old" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# now touch the files and check if they were updated
$release->touch_all_in_manifest;
foreach my $file ( keys %files )
	{
	my $mtime = -M $file;
	ok( -M $file < 0.01, "file [$file] is new [-M is $mtime]" );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Let's check the manifest file with a run() mock
{
# Replace run() with a mock. We don't want to actually do anything.
# Just return whatever is in $output
our $run_output = '';
{
no warnings;
no strict;
*{"${class}::run"} = sub { $run_output };
}

# With no output, should get the pass message
stdout_like
	{ $release->check_manifest }
	qr/up-to-date/,
	"with no run output, MANIFEST passes";
}

# With some output, it should die and give a message
{
our $run_output =<<'MANIFEST';
Removed from MANIFEST: Quux.pm
Added to MANIFEST: Bar.pm
Added to MANIFEST: t/test.t
MANIFEST

my $rc = eval { $release->check_manifest };
my $at = $@;
ok( defined $at, "eval did not fail when MANIFEST exists" );
like( $at, qr/not up-to-date/, "check_manifest fails and reports not up-to-date" );

}

done_testing();
