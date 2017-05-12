#!/usr/bin/perl

# Check that making an iso works like we expect

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Spec::Functions ':ALL';
use File::Remove 'remove';

# Set the name of the test image (and remove redundant files)
my $pitafile = catfile( 't', 'ping.pita' );
remove( $pitafile ) if -f $pitafile;
END { 
	remove( $pitafile ) if -f $pitafile;
}

# Can we load the test data package
eval {
	require PITA::Test::Image::Qemu;
};
if ( $@ ) {
	plan( 'skip_all' );
	exit(0);
}

plan( tests => 15 );
use_ok( 'PITA::XML'   );
use_ok( 'PITA::Guest' );






#####################################################################
# Preparation

# Locate the test image
my $filename = PITA::Test::Image::Qemu->filename;
ok(      $filename, 'Got test image name'        );
ok(   -f $filename, 'Test image exists'          );
ok(   -r $filename, 'Test image is readable'     );
ok( ! -w $filename, 'Test image is not writable' );

# Create an xml element for the file
my $filexml = PITA::XML::File->new(
	filename => $filename,
	);
isa_ok( $filexml, 'PITA::XML::File' );

# Create a Qemu guest and save it, since we can only
# create live guest objects with on-disk files.
my $guestxml = PITA::XML::Guest->new(
	driver   => 'Qemu',
	memory   => 128,
	snapshot => 1,
	);
isa_ok( $guestxml, 'PITA::XML::Guest' );
ok( $guestxml->add_file( $filexml ), 'Added file to the guest config' );
ok( $guestxml->write( $pitafile ), "Saved guest pita file to $pitafile" );
ok( -f $pitafile, 'Wrote guest file ok' );





#####################################################################
# Main Testing

# Create the guest
my $guest = PITA::Guest->new( $pitafile );
isa_ok( $guest, 'PITA::Guest' );
ok( -f $guest->file, 'File exists' );
ok( -f ($guest->driver->guest->files)[0]->filename, 'File exists' );

# Ping the guest
ok( $guest->ping, 'Guest pings ok' );

1;
