#!/usr/bin/perl

use Test::More tests => 7;
use Test::RDF;
use File::Util;
use RDF::Trine;
use File::Temp qw/tempfile cleanup/;

use_ok('RDF::Trine::Store::File');

my $stmt = RDF::Trine::Statement->new(
				      RDF::Trine::Node::Resource->new('http://example.org/a'),
				      RDF::Trine::Node::Resource->new('http://example.org/b'),
				      RDF::Trine::Node::Resource->new('http://example.org/c')
				     );

{
  note "Testing temporary_store";
  my $store = RDF::Trine::Store::File->temporary_store;
  isa_ok($store, 'RDF::Trine::Store::File');
  $store->add_statement($stmt);
  is($store->size, 1, 'Store has one statement according to size');
  $store->nuke;
}

{
  note "Testing new_with_string";
  my ($fh, $filename) = tempfile(EXLOCK => 0);
  my $store = RDF::Trine::Store::File->new_with_string('File;'.$filename);
  isa_ok($store, 'RDF::Trine::Store::File');
  $store->add_statement($stmt);
  is($store->size, 1, 'Store has one statement according to size');
  $store->nuke;
}

{
  note "Testing new_with_config";
  my ($fh, $filename) = tempfile(EXLOCK => 0);
  my $store = RDF::Trine::Store::File->new_with_config({ storetype => 'File', file => $filename});
  isa_ok($store, 'RDF::Trine::Store::File');
  $store->add_statement($stmt);
  is($store->size, 1, 'Store has one statement according to size');
  $store->nuke;
}


done_testing;
