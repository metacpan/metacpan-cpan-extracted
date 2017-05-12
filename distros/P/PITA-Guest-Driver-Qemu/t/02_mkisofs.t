#!/usr/bin/perl

# Check that making an iso works like we expect

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 47;
use File::Spec::Functions ':ALL';
use File::Temp   'tempfile';
use File::Remove 'remove';
use Filesys::MakeISO;

# The source content dir
my $iso_dir  = catdir(  't', 'mkisofsdir'  );
ok( -d $iso_dir, 'iso_dir exists' );

# An unused file
my $iso_file = catfile( 't', 'mkisofs.iso' );
      if ( -f $iso_file ) { remove $iso_file; }
END { if ( -f $iso_file ) { remove $iso_file; } }
ok( ! -f $iso_file, 'ISO file does not exist' );

# Repeat with an existing zero-byte file
my $iso_file2 = catfile( 't', 'mkisofs2.iso' );
      if ( -f $iso_file2 ) { remove $iso_file2; }
END { if ( -f $iso_file2 ) { remove $iso_file2; } }
ok( ! -f $iso_file2, 'ISO file does not exist' );
ok( open( ISO2, '>', $iso_file2 ), 'Opened 0-byte test file' );
ok( print ISO2 '' );
ok( close( ISO2 ), 'Closed 0-byte test file' );
ok( -f $iso_file2, 'Confirmed 0-byte file created' );
my @f = stat( $iso_file2 );
is( $f[7], 0, 'Confirmed 0-byte file is actually zero bytes' );

# Confirm a tempfile can be created, and it has zero bytes
my $tempfile;
SCOPE: {
	my ($tmpfh, $tmpfile) = tempfile( SUFFIX => '.iso' );
	$tempfile = $tmpfile;
}
ok( $tempfile, 'Got a tempfile name' );
ok( $tempfile =~ /\.iso$/, 'Temp file is named .iso' );
ok( -f $tempfile, 'Temp file exists' );
@f = stat( $tempfile );
is( $f[7], 0, 'Confirmed 0-byte file is actually zero bytes' );
END { if ( $tempfile and -f $tempfile ) { remove $tempfile; } }





#####################################################################
# Main Tests

# Create the object
SCOPE: {
	my $iso = Filesys::MakeISO->new;
	isa_ok( $iso, 'Filesys::MakeISO' );
	ok( $iso->image($iso_file), '->image set ok'          );
	is( $iso->image, $iso_file, 'Validate it is set ok'   );
	ok( $iso->dir($iso_dir),    '->dir set ok'            );
	is( $iso->dir, $iso_dir,    'Validate it is set ok'   );
	ok( $iso->make_iso,         '->make_iso returns true' );
	ok( -f $iso_file,           'ISO file created'        );

	# Is the file the right size?
	my @f = stat($iso_file);
	ok( $f[7] > 100000, 'ISO file is larger than 400k'  );
	ok( $f[7] < 1000000, 'ISO file is smaller than 500k' );
	ok( remove($iso_file), 'Removed iso_file' );
}

# Repeat using the rock ridge and joliet extensions
SCOPE: {
	my $iso = Filesys::MakeISO->new;
	isa_ok( $iso, 'Filesys::MakeISO' );
	ok( $iso->image($iso_file), '->image set ok'          );
	ok( $iso->dir($iso_dir),    '->dir set ok'            );
	ok( $iso->joliet(1),        '->joliet set ok'         );
	is( $iso->joliet, 1,        'Validate it is set ok'   );
	ok( $iso->rock_ridge(1),    '->rock_ridge set ok'     );
	is( $iso->rock_ridge, 1,    'Validate it is set ok'   );
	ok( $iso->make_iso,         '->make_iso returns true' );
	ok( -f $iso_file,           'ISO file created'        );

	# Is the file the right size?
	my @f = stat($iso_file);
	ok( $f[7] > 100000, 'ISO file (with joliet+rockridge) is larger than 500k'  );
	ok( $f[7] < 1000000, 'ISO file (with joliet+rockridge) is smaller than 600k' );
}

# Repeat the above using the file we already know exists
SCOPE: {
	my $iso = Filesys::MakeISO->new;
	isa_ok( $iso, 'Filesys::MakeISO' );
	ok( $iso->image($iso_file2), '->image set ok'         );
	ok( $iso->dir($iso_dir),    '->dir set ok'            );
	ok( $iso->make_iso,         '->make_iso returns true' );
	ok( -f $iso_file2,           'ISO file created'       );

	# Is the file the right size?
	my @f = stat($iso_file2);
	ok( $f[7] > 100000, 'ISO file is larger than 400k'  );
	ok( $f[7] < 1000000, 'ISO file is smaller than 500k' );	
}

# Repeat the above again with the tempfile
SCOPE: {
	my $iso = Filesys::MakeISO->new;
	isa_ok( $iso, 'Filesys::MakeISO' );
	ok( $iso->image($tempfile), '->image set ok'          );
	ok( $iso->dir($iso_dir),    '->dir set ok'            );
	ok( $iso->make_iso,         '->make_iso returns true' );
	ok( -f $tempfile,           'ISO file created'        );

	# Is the file the right size?
	my @f = stat($tempfile);
	ok( $f[7] > 100000, 'ISO file is larger than 400k'  );
	ok( $f[7] < 1000000, 'ISO file is smaller than 500k' );	
}

exit(0);
