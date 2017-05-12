#!/usr/bin/perl -T
#
# Create resource maps and check that one can get triples back as expected
#
# $Id: 10-create-rem.t,v 1.4 2010-12-06 14:44:02 simeon Exp $
use strict;
use warnings;

use lib qw(t/lib);
use English qw(-no_match_vars);
use Test::More;
use Slurp;

plan('tests'=>9);

use_ok( 'SemanticWeb::OAI::ORE::ReM' );

print "Creating blank ReM\n";
my $rem=SemanticWeb::OAI::ORE::ReM->new();
ok( $rem->isa('SemanticWeb::OAI::ORE::ReM'), "Check create empty ReM object" );

my $uri_r;

$uri_r='NOT_A_URI';
print "Set and get URI of ReM (URI-R=$uri_r)\n";
is( $rem->uri($uri_r), $uri_r, "Set URI-R" );
is( $rem->uri, $uri_r, "Check URI-R" );

$uri_r='http://example.org/r';
print "Set and get URI of ReM (URI-R=$uri_r)\n";
is( $rem->uri($uri_r), $uri_r, "Set URI-R" );
is( $rem->uri, $uri_r, "Check URI-R" );

print "Check model currently empty\n";
my $n3_header="# Dump of OAI-ORE Resource Map model as N3\n";
my $n3=$rem->model->as_n3;
is( $n3, $n3_header, "Check blank N3 (just header) with no model" );

##### Test real serialize N3 code #####

### No model
$n3=$rem->serialize('n3');
is( $n3, slurp('t/10-create-rem/out1.n3'), "Check blank N3 serialize with no model" );

### Now lets add some elements and check as we go
my $uri_a='http://example.org/a';
$rem->aggregation($uri_a);
my $uri_ar1='http://example.org/ar1';
my $uri_ar2='http://example.org/ar2';
$rem->aggregated_resources($uri_ar1,$uri_ar2);
$n3=$rem->serialize('n3');
is( $n3, slurp('t/10-create-rem/out2.n3'), "Check blank N3 serialize with simple model" );
