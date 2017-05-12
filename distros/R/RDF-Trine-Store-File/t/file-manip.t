#!/usr/bin/perl

use Test::More;
use Test::RDF;
use File::Util;
use RDF::Trine;
use File::Temp qw/tempfile cleanup/;

use_ok('RDF::Trine::Store::File');

my ($fh, $filename) = tempfile(EXLOCK => 0);

my $store = RDF::Trine::Store::File->new($filename);

ok($store, 'Store object OK');

$store->add_statement(RDF::Trine::Statement->new(
						 RDF::Trine::Node::Resource->new('http://example.org/a'),
						 RDF::Trine::Node::Resource->new('http://example.org/b'),
						 RDF::Trine::Node::Resource->new('http://example.org/c')
						));

is($store->size, 1, 'Store has one statement according to size');

is($store->count_statements(undef, undef, undef), 1, 'Store has one statement according to count');

my $first_etag = $store->etag;

like($first_etag, qr/\w{32}/, 'Etag is 32 chars long, only hex');

note "Sleep one second to ensure new etag";
sleep 1;

my($f) = File::Util->new();

{
  my($content) = $f->load_file($filename);

  is_valid_rdf($content, 'ntriples', 'Content is valid N-Triples');

  is_rdf($content, 'ntriples', '<http://example.org/a> <http://example.org/b> <http://example.org/c> .', 'turtle', 'Content is correct');
}

$store->add_statement(RDF::Trine::Statement->new(
						 RDF::Trine::Node::Resource->new('http://example.org/a'),
						 RDF::Trine::Node::Resource->new('http://example.org/d'),
						 RDF::Trine::Node::Resource->new('http://example.org/e')
						));

$store->add_statement(RDF::Trine::Statement->new(
						 RDF::Trine::Node::Resource->new('http://example.org/a'),
						 RDF::Trine::Node::Resource->new('http://example.org/d'),
						 RDF::Trine::Node::Literal->new('Dahut')
						));
$store->add_statement(RDF::Trine::Statement->new(
						 RDF::Trine::Node::Resource->new('http://example.org/a'),
						 RDF::Trine::Node::Resource->new('http://example.org/d'),
						 RDF::Trine::Node::Literal->new('Dahut', 'en')
						));

is($store->size, 4, 'Store has four statements');

is($store->count_statements(
			    RDF::Trine::Node::Resource->new('http://example.org/a'),
			    RDF::Trine::Node::Resource->new('http://example.org/d'),
			    undef), 3, 'Three statements with object unbound');

is($store->count_statements(
			    undef,
			    RDF::Trine::Node::Resource->new('http://example.org/d'),
			    RDF::Trine::Node::Literal->new('Dahut', 'en')),
   1, '1 statement with object bound to lang literal');

my $second_etag = $store->etag;

like($second_etag, qr/\w{32}/, 'Etag is 32 chars long, only hex');

isnt($first_etag, $second_etag, 'Etags differ');

{
  my($content) = $f->load_file($filename);
  is_valid_rdf($content, 'ntriples', 'Content is valid N-Triples');

#  is_rdf($content, 'ntriples', '<http://example.org/a> <http://example.org/b> <http://example.org/c> .', 'ntriples', 'Content is correct');
}

$store->remove_statement(RDF::Trine::Statement->new(
						 RDF::Trine::Node::Resource->new('http://example.org/a'),
						 RDF::Trine::Node::Resource->new('http://example.org/d'),
						 RDF::Trine::Node::Resource->new('http://example.org/e')
						));

is($store->size, 3, 'Store has 3 statements after single remove');

is($store->size, $store->count_statements(undef, undef, undef), 'count and size are equal');

$store->remove_statements(
			  RDF::Trine::Node::Resource->new('http://example.org/a'),
			  RDF::Trine::Node::Resource->new('http://example.org/d'),
			  undef);

is($store->size, 1, 'Store has one statement after match-remove');

$store->nuke;

ok(! -e $filename, 'File is gone');

{
  my $store2 = RDF::Trine::Store::File->new_with_string('File;' . $filename);

  ok($store2, 'Store with string config object OK');

  $store2->add_statement(RDF::Trine::Statement->new(
						    RDF::Trine::Node::Resource->new('http://example.org/a'),
						    RDF::Trine::Node::Resource->new('http://example.org/b'),
						    RDF::Trine::Node::Resource->new('http://example.org/c')
						   ));

  is($store2->size, 1, 'Store with string config has one statement according to size');

  $store2->nuke;

  ok(! -e $filename, 'File with string config is gone');
}

done_testing;
