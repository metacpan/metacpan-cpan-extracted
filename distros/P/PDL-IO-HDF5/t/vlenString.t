
# Test case for reading variable-length string arrays.
#   These are converted to fixed-length PDL::Char types when read

use PDL;
use PDL::Char;
use PDL::IO::HDF5;

use Test::More tests => 6;

# New File Check:
my $filename = "varlen.hdf5";

my $h5obj;
ok($h5obj = new PDL::IO::HDF5(">".$filename));

my $dataset = $h5obj->dataset("Dataset");

my $pdl = $dataset->get();

my @dims = $pdl->dims;

#print "dims = ".join(", ", @dims)."\n";
ok(  join(", ", @dims) eq "93, 4");

#print $pdl->atstr(2)."\n";
ok(    $pdl->atstr(2) eq "Now we are engaged in a great civil war,");

# print "PDL::Char = $pdl\n";


###### Now check variable-length string attribute array ###
($pdl) = $dataset->attrGet('Attr1');

@dims = $pdl->dims;

#print "dims = ".join(", ", @dims)."\n";
ok(  join(", ", @dims) eq "14, 4");

#print $pdl->atstr(2)."\n";
ok(    $pdl->atstr(2) eq "Attr String 3");

###### Now check variable-length string attribute scalar ###
($pdl) = $dataset->attrGet('attr2');
ok(  $pdl eq "dude");
