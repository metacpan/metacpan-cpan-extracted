#!/usr/bin/perl

use Test::More;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init( { level   =>  $TRACE} ) if $ENV{TEST_VERBOSE};

use_ok('RDF::Trine::Store::File');

my $store = RDF::Trine::Store::File->temporary_store;

isa_ok($store, 'RDF::Trine::Store::File');

{
  my $regex = $store->_search_regexp(undef,
				     RDF::Trine::Node::Resource->new('http://example.org/b'),
				     RDF::Trine::Node::Resource->new('http://example.org/c')
				    );
  is($regex, '(<.*?> <http://example.org/b> <http://example.org/c> \.\n)', 'Subject variable matches');
}

{
  my $regex = $store->_search_regexp(RDF::Trine::Node::Resource->new('http://example.org/a'),
				     RDF::Trine::Node::Resource->new('http://example.org/d'),
				     undef
				    );
  is($regex, '(<http://example.org/a> <http://example.org/d> .* \.\n)', 'object variable matches');
}

{
  my $regex = $store->_search_regexp(RDF::Trine::Node::Resource->new('http://example.org/a'),
				     undef,
				     undef
				    );
  is($regex, '(<http://example.org/a> <.*?> .* \.\n)', 'predicate and object variable matches');
}

$store->nuke;

done_testing;
