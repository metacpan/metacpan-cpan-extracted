#!perl

use strict;
use warnings FATAL => 'all';

use URI;
use RDF::Trine qw(iri blank literal);

use Test::More tests => 2;

use_ok('RDF::KV::Patch');

my $patch = RDF::KV::Patch->new;

isa_ok($patch, 'RDF::KV::Patch');

my $ret = $patch->add_this
    ('_:wat', 'http://purl.org/dc/terms/title', literal('derps', undef, 'xsd:string'));

diag($ret->sse);
