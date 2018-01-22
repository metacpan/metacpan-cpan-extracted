#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::RDF;
use RDF::Trine qw[iri literal blank variable statement];
use Test::WWW::Mechanize::PSGI;
use Module::Load::Conditional qw[check_install];
use RDF::Trine::Namespace qw(rdf);
use HTTP::Request ();
use Config::ZOMG;
use Plack::App::RDF::LinkedData;


$ENV{'RDF_LINKEDDATA_CONFIG_LOCAL_SUFFIX'} = 'acl';

my $config = Config::ZOMG->open(name => "RDF::LinkedData");
my $linkeddata = Plack::App::RDF::LinkedData->new();

$linkeddata->configure($config);

my $tester = $linkeddata->to_app;

BAIL_OUT("The application is not running") unless ($tester);

use Log::Any::Adapter;

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};


my $exprefix = 'http://example.org/hypermedia#';

my $parser = RDF::Trine::Parser->new( 'turtle' );

my $rxparser = RDF::Trine::Parser->new( 'rdfxml' );
my $base_uri = 'http://localhost/';

my $head = [ 'Content-Type' => 'text/turtle' ];

subtest 'Write operations without authentication' => sub {
  my $body = '<' .$base_uri . 'bar/baz/bing> <http://example.org/error> "No merged triple"@en .';
  {
	 my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
	 $mech->request(HTTP::Request->new('POST', "/bar/baz/bing/data", $head, $body));
	 is($mech->status, 401, "Posting returns 401");
  }
  {
	 my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
	 $mech->request(HTTP::Request->new('PUT', "/bar/baz/bing/data", $head, $body));
	 is($mech->status, 401, "Putting returns 401");
  }
};

my $prevcount = 0;
subtest 'Check before we write' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  my $model = check_content($mech);
  $prevcount = $model->size;
};

subtest 'Merge operations with authentication wrong content type' => sub {
  my $body = '<' .$base_uri . 'bar/baz/bing> <http://example.org/success> "Merged triple"@en .';
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->request(HTTP::Request->new('POST', "/bar/baz/bing/data", [ 'Content-Type' => 'foo/bar' ], $body));
  is($mech->status, 415, "Posting returns 415");
};

subtest 'Merge operations with authentication' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  my $body = '<' .$base_uri . 'bar/baz/bing> <http://example.org/success> "Merged triple"@en .';
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->request(HTTP::Request->new('POST', "/bar/baz/bing/data", $head, $body));
  is($mech->status, 200, "Posting returns 200");
  $mech->content_lacks('discarded', 'No triples discarded');

  my $model = check_content($mech);
  is($model->size, $prevcount+1, 'Got another triple now');
  has_predicate('http://example.org/success', $model, 'Got the predicate');
  has_literal('Testing with longer URI.', 'en', undef, $model, "Test phrase in content");};

subtest 'Replace operations with authentication' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  my $body = '<' .$base_uri . 'bar/baz/bing> <http://example.org/success> "Replaced with triple"@en .';
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->request(HTTP::Request->new('PUT', "/bar/baz/bing/data", $head, $body));
  is($mech->status, 200, "Putting returns 200");
  $mech->content_lacks('discarded', 'No triples discarded');
  my $model = check_content($mech);
  is($model->size, 9, 'Only one triple now in addition to hypermedia'); # Even though we replaced them all, the resource will still respond with 8 hypermedia triples (i.e. vocabularies, where to edit, etc
  has_predicate('http://example.org/success', $model, 'Got the predicate');
  hasnt_literal('Testing with longer URI.', 'en', undef, $model, "Test phrase in content");
};


subtest 'Merge operations with authentication and wrong subject' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  my $body = '<' .$base_uri . 'bar/baz/bing> <http://example.org/success> "Merged triple"@en . <http://example.org/foo> a <http://example.org/Dahut> ; <http://example.org/notin> <' .$base_uri . 'bar/baz/bing> .';
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->request(HTTP::Request->new('POST', "/bar/baz/bing/data", $head, $body));
  is($mech->status, 200, "Posting returns 200");
  $mech->content_contains('2 triples', '2 triples were discarded');
  my $model = check_content($mech);
};

  
subtest 'Replace operations with authentication and wrong subject' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  my $body = '<' .$base_uri . 'bar/baz/bing> <http://example.org/success> "Replaced with triple"@en . <http://example.org/foo> a <http://example.org/Dahut> ; <http://example.org/notin> <' .$base_uri . 'bar/baz/bing> .';
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->request(HTTP::Request->new('PUT', "/bar/baz/bing/data", $head, $body));
  is($mech->status, 200, "Putting returns 200");
  $mech->content_contains('2 triples', '2 triples were discarded');
  my $model = check_content($mech);
};


subtest 'Merge operations with authentication and no subject' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  my $body = '<http://example.org/foo> a <http://example.org/Dahut> ; <http://example.org/notin> <' .$base_uri . 'bar/baz/bing> .';
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->request(HTTP::Request->new('POST', "/bar/baz/bing/data", $head, $body));
  is($mech->status, 403, "Posting returns 403");
  $mech->content_contains('No triples', 'No triples were found');
  my $model = check_content($mech);
};

  
subtest 'Replace operations with authentication and wrong subject' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  my $body = '<http://example.org/foo> a <http://example.org/Dahut> ; <http://example.org/notin> <' .$base_uri . 'bar/baz/bing> .';
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->request(HTTP::Request->new('PUT', "/bar/baz/bing/data", $head, $body));
  is($mech->status, 403, "Putting returns 403");
  $mech->content_contains('No triples', 'No triples were found');
  my $model = check_content($mech);
};

subtest 'Write operations without authentication again' => sub {
  my $body = '<' .$base_uri . 'bar/baz/bing> <http://example.org/error> "Credentials should be forgotten."@en .';
  {
	 my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
	 $mech->request(HTTP::Request->new('POST', "/bar/baz/bing/data", $head, $body));
	 is($mech->status, 401, "Posting returns 401");
  }
  {
	 my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
	 $mech->request(HTTP::Request->new('PUT', "/bar/baz/bing/data", $head, $body));
	 is($mech->status, 401, "Putting returns 401");
  }
};

subtest 'Delete operation with authentication' => sub {
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
  ok($mech->credentials('testuser', 'sikrit' ), 'Setting credentials (cannot really fail...)');
  $mech->request(HTTP::Request->new('DELETE', "/bar/baz/bing/data", $head, ""));
  is($mech->status, 204, "Deleting returns 204");
  $mech->get("/bar/baz/bing/data");
  is($mech->status, 404, "data returns 404");
  $mech->get("/bar/baz/bing");
  is($mech->status, 404, "resource returns 404");
  $mech->get("/bar/baz/bing/control");
  is($mech->status, 404, "control returns 404");
};



sub check_content {
  my $mech = shift;
  $mech->default_header('Accept' => 'application/rdf+xml');
  $mech->get_ok("/bar/baz/bing");
  is($mech->ct, 'application/rdf+xml', "Correct content-type");
  like($mech->uri, qr|/bar/baz/bing/data$|, "Location is OK");
  is_valid_rdf($mech->content, 'rdfxml', 'Returns valid RDF/XML');
  my $model = return_model($mech->content, $rxparser);
  has_subject($base_uri . 'bar/baz/bing', $model, "Subject URI in content");
  return $model;
}

sub return_model {
	my ($content, $parser) = @_;
	my $retmodel = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model( $base_uri, $content, $retmodel );
	return $retmodel;
}


done_testing();
