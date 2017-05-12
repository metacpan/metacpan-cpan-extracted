#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

use lib "t";

use Octothorpe;
use XML::LibXML;
use XMLTests;

my @eg_filenames = map {"t/$_"}
	sort {$a cmp $b} XMLTests::find_tests("xml/valid");

my $valid_foo = Octothorpe->parse_file( shift @eg_filenames );
ok($valid_foo, "parse_file('filename')");

open FH, "<", shift @eg_filenames;
$valid_foo = Octothorpe->parse_fh( \*FH );
ok($valid_foo, "parse_fh(\*FOO)");

{
    eval {Octothorpe->parse_fh( 'blah' )};
    my $error = $@;
    ok( ($error =~ qr{Parameter #1 \("blah"\) to PRANG::Graph::parse_fh did not pass the 'checking type constraint for GlobRef' callback})
    ||  ($error =~ qr{Parameter #1 does not pass the type constraint because: Validation failed for 'GlobRef' with value "blah"}) );
}

my $parser = XML::LibXML->new;
my $dom = $parser->parse_file( shift @eg_filenames );
$valid_foo = Octothorpe->from_dom( $dom );
ok($valid_foo, "from_dom(\$dom)");
