use PDL::IO::HDF5;

use Test::More tests => 3;

# New File Check:
my $filename = "newFile.hdf5";
# get rid of filename if it already exists
unlink $filename if( -e $filename);
ok(new PDL::IO::HDF5($filename));

#Existing File for Writing Check
ok(new PDL::IO::HDF5(">".$filename));

#Existing File for Reading Check
ok(new PDL::IO::HDF5($filename));

# clean up file
unlink $filename if( -e $filename);
