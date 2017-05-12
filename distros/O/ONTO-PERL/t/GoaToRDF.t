# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GoaToRDF.t'

#########################

BEGIN {
	eval { require Test; };
	use Test;    
	plan tests => 2;
}
#########################

use Carp;
use strict;
use warnings;

use OBO::APO::GoaToRDF;

my $goa2rdf = OBO::APO::GoaToRDF->new();
ok(1);
my $file = './t/data/goa_assoc_filt.txt';
open (FH, '>./t/data/test_goa.rdf') || die $!;

my $file_handle = \*FH;
my $base        = 'http://www.semantic-systems-biology.org/';
my $ns          = 'SSB';
$file_handle    = $goa2rdf->work($file, $file_handle, $base, $ns);

ok(1);
close $file_handle;