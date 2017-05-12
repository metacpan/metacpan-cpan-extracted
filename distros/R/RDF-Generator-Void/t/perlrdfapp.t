use strict;
use warnings;
use Test::More;

BEGIN {
	eval { require App::perlrdf };
	plan skip_all => "App::perlrdf needed for these tests" if ($@);
	eval { require App::Cmd::Tester };
	plan skip_all => " App::Cmd::Tester needed for these tests" if ($@);
}

use Test::RDF;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use App::Cmd::Tester;

my $base_uri = 'http://localhost';

my $testdata = $Bin . '/data/basic.ttl';
my $expected = $Bin . '/data/basic-expected.ttl';

note 'First load the data into a SQLite DB';
my ($fh, $filename) = tempfile( UNLINK => 1, SUFFIX => '.sqlite', EXLOCK => 0);

my $make = test_app('App::perlrdf' => [ 'make_store', '-Q', $filename ]);

is($make->error, undef, 'Init store threw no exceptions');

my $load = test_app('App::perlrdf' => [ 'store_load', '-Q', $filename, $testdata ]);

like($load->stderr, qr|^Loading file:///\S+data/basic.ttl$|, 'Loading statement STDERR');
is($load->error, undef, 'Loading threw no exceptions');
is($load->exit_code, 0, 'Loading has exit code 0');

note 'Now test the VoID generation';

my $parser     = RDF::Trine::Parser->new( 'turtle' );
my $expected_void_model = RDF::Trine::Model->temporary_model;
$parser->parse_file_into_model( $base_uri, $expected, $expected_void_model );

{
  my $model = void_tests('void', '-Q', $filename, '-l', '1', $base_uri . '/dataset#foo' );
  hasnt_uri('http://purl.org/dc/terms/title', $model, 'Has no title');
  hasnt_uri('http://rdfs.org/ns/void#uriSpace', $model, 'Has no urispace predicate');
}
{
  my $model = void_tests('void', '-Q', $filename, '-l', '1',
								 '--license_uris', 'http://example.org/open-data-license',
								 $base_uri . '/dataset#foo' );
  has_predicate('http://purl.org/dc/terms/license', $model, 'Has license predicate');
}
{
  my $model = void_tests('void', '-Q', $filename, '-l', '1',
								 '--license_uris', 'http://example.org/open-data-license', 
								 '--void_urispace', $base_uri,
								 $base_uri . '/dataset#foo' );
  has_predicate('http://purl.org/dc/terms/license', $model, 'Has license predicate');
  has_literal($base_uri, undef, undef, $model, 'Has urispace object');
}
{
  my $model = void_tests('void', '-Q', $filename, '-l', '1',
								 '--license_uris', 'http://example.org/open-data-license', 
								 '--void_title', "This is a title",
								 $base_uri . '/dataset#foo' );
  has_predicate('http://purl.org/dc/terms/license', $model, 'Has license predicate');
  has_literal("This is a title", 'en', undef, $model, 'Has urispace object');
}
{
  my $model = void_tests('void', '-Q', $filename, '-l', '1',
								 '--endpoint_urls', $base_uri . '/sparql',
								 $base_uri . '/dataset#foo' );
  has_predicate('http://rdfs.org/ns/void#sparqlEndpoint', $model, 'Has sparqlEndpoint predicate');
  has_object_uri($base_uri . '/sparql', $model, 'Has sparqlEndpoint object');
}


sub void_tests {
  my @args = @_;
  note 'Run tests for ' . join(" ", @args);
  my $result = test_app('App::perlrdf' => \@args);

  is($result->error, undef, 'VoID threw no exceptions');
  is($result->exit_code, 0, 'VoID exit code 0');
  ok($result->stdout, 'VoID sends result to STDOUT');

  my $data_model = RDF::Trine::Model->temporary_model;
  $parser->parse_into_model( $base_uri, $result->stdout, $data_model );

  are_subgraphs($data_model, $expected_void_model, 'Got the expected VoID description with generated data');
  return $data_model;
}

done_testing();
