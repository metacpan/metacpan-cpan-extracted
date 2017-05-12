#!/usr/bin/perl

# Testing PITA::Guest::Storage::Simple

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use PITA                         ();
use PITA::Guest::Storage::Simple ();
use File::Remove                 'remove';
use File::Spec::Functions        ':ALL';
use Params::Util                 '_SET';

# Set up an existing directory
my $storage_dir = catdir( 't', 'storage_simple' );
File::Remove::clear($storage_dir);
ok( ! -d $storage_dir, 'storage_simple does not exists' );
ok( mkdir($storage_dir), 'storage_simple created' );
ok( -d $storage_dir, 'storage_simple exists' );

# Find the test guest file
my $image_test = catfile( 't', 'guests', 'image_test.pita' );
ok( -f $image_test, 'Found image_test.pita test file' );





#####################################################################
# Test a basic existing object

# Create a basic storage object
my $storage = PITA::Guest::Storage::Simple->new(
	storage_dir => $storage_dir,
);
isa_ok( $storage, 'PITA::Guest::Storage::Simple' );
isa_ok( $storage, 'PITA::Guest::Storage' );
SKIP: {
	skip( "No locking on Win32", 2 ) if $^O eq 'MSWin32';
	is( $storage->storage_dir, $storage_dir, '->storage_dir returns as expected' );
	isa_ok( $storage->storage_lock, 'File::Flock' );
}

# Create a simple guest and add it
my $guest = PITA::XML::Guest->read( $image_test );
isa_ok( $guest, 'PITA::XML::Guest' );
my $id = $guest->id;
ok( ! $guest->id, 'Guest has no identifier' );
ok( $storage->add_guest($guest), '->add_guest ok' );
ok(   $guest->id, 'Guest has an identifier' );

# Refetch the guest
my $guest2 = $storage->guest($guest->id);
isa_ok( $guest2, 'PITA::XML::Guest' );
is( $guest->id, $guest2->id, 'Guest refetched matches original' );

# Get the set of platforms
#my @platforms = $storage->platforms;
#ok( !! _SET0(\@platforms, 'PITA::XML::Platform'), '->platforms ok' );
