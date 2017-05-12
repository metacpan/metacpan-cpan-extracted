#!/usr/bin/env perl

use FindBin qw($Bin);

use strict;
use Test::More tests => 8;

#use Test::NoWarnings;

my $file = $Bin . '/data/basic.ttl';

BEGIN {
    use_ok('RDF::Helper::Properties');
    use_ok('RDF::Trine::Parser');
    use_ok('RDF::Trine::Model');
}

my $parser     = RDF::Trine::Parser->new( 'turtle' );
my $model = RDF::Trine::Model->temporary_model;
my $base_uri = 'http://localhost:3000';
$parser->parse_file_into_model( $base_uri, $file, $model );

ok($model, "We have a model");

my $preds = RDF::Helper::Properties->new(model => $model);

my $node = RDF::Trine::Node::Resource->new('http://localhost:3000/foo');
my $barnode = RDF::Trine::Node::Resource->new('http://localhost:3000/bar/baz/bing');

is($preds->title($node), 'This is a test', "Correct title");

my @list = $preds->title($node);
is_deeply(\@list, ['This is a test', 'en', undef], "Correct title (list context)");

is($preds->page($node), 'http://en.wikipedia.org/wiki/Foo', "/foo has a foaf:page at Wikipedia");

is($preds->page($barnode), 'http://localhost:3000/bar/baz/bing/page', "/bar/baz/bing has default page");

