# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl NCBIToRDF.t'

#########################

BEGIN {
	unshift @INC, '/norstore/user/mironov/workspace/onto-perl/ONTO-PERL-1.37/lib';
    eval { require Test; };
    use Test;    
    plan tests => 2;
}

#########################

use OBO::APO::NCBIToRDF;
use Carp;
use strict;
use warnings;

my $ncbi2rdf = OBO::APO::NCBIToRDF->new();
ok(1);
my $names = './t/data/names_dummy.dmp';
my $nodes = './t/data/nodes_dummy.dmp';
open (FH, ">./t/data/test_ncbi.rdf") || die $!;
my $base = 'http://www.semantic-systems-biology.org/';
my $ns   = 'SSB';

my $file_handle = \*FH;
$file_handle = $ncbi2rdf->work ( $names, $nodes, $file_handle, $base, $ns );
close $file_handle;
ok(1);