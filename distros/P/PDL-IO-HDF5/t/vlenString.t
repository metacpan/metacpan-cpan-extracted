# Test case for reading variable-length string arrays.
#   These are converted to fixed-length PDL::Char types when read

use strict;
use warnings;
use PDL;
use PDL::Char;
use PDL::IO::HDF5;
use Test::More;

# New File Check:
my $filename = "varlen.hdf5";

ok(my $h5obj = new PDL::IO::HDF5(">".$filename));

my $dataset = $h5obj->dataset("Dataset");

my $pdl = $dataset->get();

my @dims = $pdl->dims;

is(join(", ", @dims), "93, 4");

is($pdl->atstr(2), "Now we are engaged in a great civil war,");

###### Now check variable-length string attribute array ###
($pdl) = $dataset->attrGet('Attr1');

@dims = $pdl->dims;

is(join(", ", @dims), "14, 4");

is($pdl->atstr(2), "Attr String 3");

###### Now check variable-length string attribute scalar ###
($pdl) = $dataset->attrGet('attr2');
is($pdl, "dude");

done_testing;
