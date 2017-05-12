#!/usr/bin/perl

use strict;
use warnings;
no warnings 'redefine';
use Test::Exception;
use Scalar::Util qw(refaddr);
use Test::More;

use_ok( 'RDF::EARL' );

dies_ok(sub {
	my $earl	= RDF::EARL->new();
}, 'empty constructor call fails');

{
	my $earl	= RDF::EARL->new( 'http://example.org/testing' );
	isa_ok($earl, 'RDF::EARL');
	isa_ok($earl->assertor, 'RDF::Trine::Node::Resource');
	like($earl->assertor->uri_value, qr{^http://purl.org/NET/cpan-uri/dist/RDF-EARL/v_([-0-9_.]+)$}, 'default assertor IRI');
}

{
	my $earl	= RDF::EARL->new( subject => 'http://example.org/testing' );
	isa_ok($earl, 'RDF::EARL');
	isa_ok($earl->assertor, 'RDF::Trine::Node::Resource');
	like($earl->assertor->uri_value, qr{^http://purl.org/NET/cpan-uri/dist/RDF-EARL/v_([-0-9_.]+)$}, 'default assertor IRI');
}

{
	my $earl	= RDF::EARL->new( subject => 'http://example.org/testing', assertor => 'http://example.org/harness' );
	isa_ok($earl, 'RDF::EARL');
	isa_ok($earl->assertor, 'RDF::Trine::Node::Resource');
	is($earl->assertor->uri_value, 'http://example.org/harness', 'default assertor IRI');
}

{
	my $earl	= RDF::EARL->new( subject => 'http://example.org/testing', assertor => 'http://example.org/harness' );
	$earl->pass('http://example.org/tests/test1', 'comment');
	my $graph	= RDF::Trine::Graph->new( $earl->model );
	my $expect	= _graph_from_ttl(<<"END");
[]
	a <http://www.w3.org/ns/earl#Assertion> ;
	<http://www.w3.org/ns/earl#assertedBy> <http://example.org/harness> ;
	<http://www.w3.org/ns/earl#result> [
		<http://www.w3.org/ns/earl#outcome> <http://www.w3.org/ns/earl#passed> ;
		<http://www.w3.org/ns/earl#info> "comment" ;
		a <http://www.w3.org/ns/earl#TestResult> ;
	] ;
	<http://www.w3.org/ns/earl#subject> <http://example.org/testing> ;
	<http://www.w3.org/ns/earl#test> <http://example.org/tests/test1> .
END
	ok( $graph->equals( $expect ), 'expected model after single pass result' );
}

{
	my $earl	= RDF::EARL->new( subject => 'http://example.org/testing', assertor => 'http://example.org/harness' );
	$earl->pass('http://example.org/tests/test2', 'passed!');
	$earl->fail('http://example.org/tests/test3', 'failed!');
	my $graph	= RDF::Trine::Graph->new( $earl->model );
	my $expect	= _graph_from_ttl(<<"END");
[]
	a <http://www.w3.org/ns/earl#Assertion> ;
	<http://www.w3.org/ns/earl#assertedBy> <http://example.org/harness> ;
	<http://www.w3.org/ns/earl#result> [
		<http://www.w3.org/ns/earl#outcome> <http://www.w3.org/ns/earl#passed> ;
		<http://www.w3.org/ns/earl#info> "passed!" ;
		a <http://www.w3.org/ns/earl#TestResult> ;
	] ;
	<http://www.w3.org/ns/earl#subject> <http://example.org/testing> ;
	<http://www.w3.org/ns/earl#test> <http://example.org/tests/test2> .

[]
	a <http://www.w3.org/ns/earl#Assertion> ;
	<http://www.w3.org/ns/earl#assertedBy> <http://example.org/harness> ;
	<http://www.w3.org/ns/earl#result> [
		<http://www.w3.org/ns/earl#outcome> <http://www.w3.org/ns/earl#failed> ;
		<http://www.w3.org/ns/earl#info> "failed!" ;
		a <http://www.w3.org/ns/earl#TestResult> ;
	] ;
	<http://www.w3.org/ns/earl#subject> <http://example.org/testing> ;
	<http://www.w3.org/ns/earl#test> <http://example.org/tests/test3> .
END
	ok( $graph->equals( $expect ), 'expected model after single pass and fail results' );
}


done_testing();



sub _graph_from_ttl {
	my $ttl	= shift;
	my $p	= RDF::Trine::Parser->new('turtle');
	my $m	= RDF::Trine::Model->temporary_model;
	$p->parse_into_model( 'http://example.org/base/', $ttl, $m );
	return RDF::Trine::Graph->new( $m );
}
