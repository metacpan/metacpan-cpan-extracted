#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Test::Modern;
no warnings 'redefine';
use Test::Exception;
use Encode qw(encode_utf8 decode_utf8);
use Scalar::Util qw(refaddr);

use RDF::EARL;

my $test		= Attean::BindingEqualityTest->new();

dies_ok(sub {
	my $earl	= RDF::EARL->new();
}, 'empty constructor call fails');

{
	my $earl	= RDF::EARL->new( 'http://example.org/testing' );
	isa_ok($earl, 'RDF::EARL');
	does_ok($earl->assertor, 'Attean::API::IRI');
	like($earl->assertor->value, qr{^http://purl.org/NET/cpan-uri/dist/RDF-EARL/v_([-0-9_.]+)$}, 'default assertor IRI');
}

{
	my $earl	= RDF::EARL->new( subject => 'http://example.org/testing' );
	isa_ok($earl, 'RDF::EARL');
	does_ok($earl->assertor, 'Attean::API::IRI');
	like($earl->assertor->value, qr{^http://purl.org/NET/cpan-uri/dist/RDF-EARL/v_([-0-9_.]+)$}, 'default assertor IRI');
}

{
	my $earl	= RDF::EARL->new( subject => 'http://example.org/testing', assertor => 'http://example.org/harness' );
	isa_ok($earl, 'RDF::EARL');
	does_ok($earl->assertor, 'Attean::API::IRI');
	is($earl->assertor->value, 'http://example.org/harness', 'default assertor IRI');
}

{
	my $earl	= RDF::EARL->new( subject => 'http://example.org/testing', assertor => 'http://example.org/harness' );
	$earl->pass('http://example.org/tests/test1', 'comment');
	my $earl_iter	= $earl->model->get_quads()->map(sub { Attean::Triple->new(($_->values)[0..2]) }, 'Attean::API::Triple');
	my $expect_ttl	= <<"END";
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
	my $expect	= _graph_from_ttl($expect_ttl);
	my $ok	= $test->equals($earl_iter, $expect);
	ok( $ok, 'expected model after single pass result' );
	unless ($ok) {
		warn $test->error();
		my $ser			= Attean->get_serializer('NTriples')->new();
		my $iter		= $earl->model->get_quads()->map(sub { Attean::Triple->new(($_->values)[0..2]) }, 'Attean::API::Triple');
		my $got			= decode_utf8($ser->serialize_iter_to_bytes($iter));
		my $expected	= decode_utf8($ser->serialize_iter_to_bytes(_graph_from_ttl($expect_ttl)));
		warn "Got data:\n$got\n";
		warn "Expected data:\n$expected\n";
	}
}

{
	my $earl	= RDF::EARL->new( subject => 'http://example.org/testing', assertor => 'http://example.org/harness' );
	$earl->pass('http://example.org/tests/test2', 'passed!');
	$earl->fail('http://example.org/tests/test3', 'failed!');
	my $earl_iter	= $earl->model->get_quads()->map(sub { Attean::Triple->new(($_->values)[0..2]) }, 'Attean::API::Triple');
	my $expect_ttl	= <<"END";
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
	my $expect	= _graph_from_ttl($expect_ttl);
	my $ok	= $test->equals($earl_iter, $expect);
	ok( $ok, 'expected model after single pass and fail results' );
	unless ($ok) {
		warn $test->error();
		my $ser			= Attean->get_serializer('NTriples')->new();
		my $iter		= $earl->model->get_quads()->map(sub { Attean::Triple->new(($_->values)[0..2]) }, 'Attean::API::Triple');
		my $got			= decode_utf8($ser->serialize_iter_to_bytes($iter));
		my $expected	= decode_utf8($ser->serialize_iter_to_bytes(_graph_from_ttl($expect_ttl)));
		warn "Got data:\n$got\n";
		warn "Expected data:\n$expected\n";
	}
}


done_testing();



sub _graph_from_ttl {
	my $ttl		= shift;
	my $parser	= Attean->get_parser('Turtle')->new();
	my $iter	= $parser->parse_iter_from_bytes(encode_utf8($ttl));
	return $iter;
}
