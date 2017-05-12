=pod

=encoding utf-8

=head1 PURPOSE

Test that RDF::Generator::HTTP generates RDF.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use HTTP::Response;
use Test::RDF;
use RDF::Trine qw(statement variable iri literal);

use_ok('RDF::Generator::HTTP');


my $h = HTTP::Headers->new(
									Date => 'Thu, 14 Feb 2014 20:48:33 GMT',
									Content_Type => 'text/turtle;charset=UTF-8',
									Expires =>  'Thu, 14 Feb 2014 21:48:33 GMT',
									'Last-Modified' =>  'Thu, 07 Feb 2014 20:48:33 GMT',
									Server => 'Dahutomatic/4.2'
								  );

my $rdf = RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
my $http = RDF::Trine::Namespace->new('http://www.w3.org/2007/ont/http#');
my $httph = RDF::Trine::Namespace->new('http://www.w3.org/2007/ont/httph#');

# Setting up the response
my $r = HTTP::Response->new(200, "OK", $h, "<> a <http://example.org/Dahut> .");
my $requestURI = 'http://www.example.invalid/';
$r->request(HTTP::Request->new(GET => $requestURI, [Accept => 'application/rdf+xml']));

{
	my $g = RDF::Generator::HTTP->new(message => $r);
	isa_ok($g, 'RDF::Generator::HTTP');
	isa_ok($g->response_subject, 'RDF::Trine::Node::Blank');
	my $model = $g->generate;
	isa_ok($g->request_subject, 'RDF::Trine::Node::Blank');
	isa_ok($model, 'RDF::Trine::Model');
	has_predicate($httph->date->uri_value, $model, 'Date Predicate URI is found');
	has_predicate($httph->content_type->uri_value, $model, 'Content-Type Predicate URI is found');
	pattern_target($model);
	my $pattern = RDF::Trine::Pattern->new(
														statement(variable('req'), $rdf->type, $http->RequestMessage),
														statement(variable('req'), $http->method, literal('GET')),
														statement(variable('req'), $httph->accept, literal('application/rdf+xml')),
														statement(variable('req'), $http->requestURI, iri($requestURI)),
														statement(variable('req'), $http->hasResponse, variable('res')),
														statement(variable('res'), $rdf->type, $http->ResponseMessage),
														statement(variable('res'), $http->status, literal('200')),
														statement(variable('res'), $httph->date, literal('Thu, 14 Feb 2014 20:48:33 GMT')),
														statement(variable('res'), $httph->content_type, literal('text/turtle;charset=UTF-8')),
														statement(variable('res'), $httph->expires, literal('Thu, 14 Feb 2014 21:48:33 GMT')),
														statement(variable('res'), $httph->last_modified, literal('Thu, 07 Feb 2014 20:48:33 GMT')),
														statement(variable('res'), $httph->server, literal('Dahutomatic/4.2'))
													  );

	pattern_ok($pattern, 'Full pattern found');
}


{
	my $reqs = iri('http://example.org/request');
	my $ress = iri('http://example.org/response');
	my $g = RDF::Generator::HTTP->new(message => $r, 
												 blacklist => ['Last-Modified', 'Accept'],
												 request_subject => $reqs,
												 response_subject => $ress
												);
	isa_ok($g, 'RDF::Generator::HTTP');
	isa_ok($g->response_subject, 'RDF::Trine::Node::Resource');
	my $model = $g->generate;
	isa_ok($g->request_subject, 'RDF::Trine::Node::Resource');
	ok($g->request_subject->equal($reqs), 'We get the request subject URI back');
	isa_ok($model, 'RDF::Trine::Model');
	has_subject('http://example.org/request', $model, 'Request subject URI is found');
	has_subject('http://example.org/response', $model, 'Response subject URI is found');
	has_predicate($httph->date->uri_value, $model, 'Date Predicate URI is found');
	has_predicate($httph->content_type->uri_value, $model, 'Content-Type Predicate URI is found');
	hasnt_uri($httph->accept->uri_value, $model, 'Accept Predicate URI is not found');
	hasnt_uri($httph->last_modified->uri_value, $model, 'Last-Modified Predicate URI is not found');
	hasnt_literal('Thu, 07 Feb 2014 20:48:33 GMT', undef, undef, $model, 'Last-Modified literal string is not found');

	pattern_target($model);
	my $pattern = RDF::Trine::Pattern->new(
														statement(variable('req'), $rdf->type, $http->RequestMessage),
														statement(variable('req'), $http->method, literal('GET')),
														statement(variable('req'), $http->requestURI, iri($requestURI)),
														statement(variable('req'), $http->hasResponse, variable('res')),
														statement(variable('res'), $rdf->type, $http->ResponseMessage),
														statement(variable('res'), $http->status, literal('200')),
														statement(variable('res'), $httph->date, literal('Thu, 14 Feb 2014 20:48:33 GMT')),
														statement(variable('res'), $httph->content_type, literal('text/turtle;charset=UTF-8')),
														statement(variable('res'), $httph->expires, literal('Thu, 14 Feb 2014 21:48:33 GMT')),
														statement(variable('res'), $httph->server, literal('Dahutomatic/4.2'))
													  );
	pattern_ok($pattern, 'Rest of pattern found');
}


{
	my $reqs = iri('http://example.org/request');
	my $ress = iri('http://example.org/response');
	my $g = RDF::Generator::HTTP->new(message => $r, 
												 whitelist => ['Date', 'Content-Type', 'Expires'],
												 request_subject => $reqs,
												 response_subject => $ress
												);
	isa_ok($g, 'RDF::Generator::HTTP');
	my $model = $g->generate;
	isa_ok($model, 'RDF::Trine::Model');
	isa_ok($g->request_subject, 'RDF::Trine::Node::Resource');
	has_subject('http://example.org/request', $model, 'Request subject URI is found');
	has_subject('http://example.org/response', $model, 'Response subject URI is found');
	has_object_uri('http://example.org/response', $model, 'Response object URI is found');
	has_predicate($httph->date->uri_value, $model, 'Date Predicate URI is found');
	has_predicate($httph->content_type->uri_value, $model, 'Content-Type Predicate URI is found');
	has_literal('text/turtle;charset=UTF-8', undef, undef, $model, 'Content-Type literal is found');
	hasnt_literal('Thu, 07 Feb 2014 20:48:33 GMT', undef, undef, $model, 'Last-Modified literal string is not found');
	pattern_target($model);
	my $pattern = RDF::Trine::Pattern->new(
														statement($reqs, $rdf->type, $http->RequestMessage),
														statement($reqs, $http->method, literal('GET')),
														statement($reqs, $http->requestURI, iri($requestURI)),
														statement($reqs, $http->hasResponse, $ress),
														statement($ress, $rdf->type, $http->ResponseMessage),
														statement($ress, $http->status, literal('200')),
														statement($ress, $httph->date, literal('Thu, 14 Feb 2014 20:48:33 GMT')),
														statement($ress, $httph->content_type, literal('text/turtle;charset=UTF-8')),
														statement($ress, $httph->expires, literal('Thu, 14 Feb 2014 21:48:33 GMT'))
													  );

	pattern_ok($pattern, 'Rest of whitelist pattern found');

	pattern_fail(
					 statement(variable('req'), $httph->accept, literal('application/rdf+xml')),
					 statement(variable('res'), $httph->last_modified, literal('Thu, 07 Feb 2014 20:48:33 GMT')),
					 statement(variable('res'), $httph->server, literal('Dahutomatic/4.2')),
					 'Banned not found');


}

{
	my $g = RDF::Generator::HTTP->new(message => $r, graph => iri('http://example.org/graphname'));
	isa_ok($g, 'RDF::Generator::HTTP');
	my $model = $g->generate;
	isa_ok($model, 'RDF::Trine::Model');
	has_predicate($httph->date->uri_value, $model, 'Date Predicate URI is found');
	has_predicate($httph->content_type->uri_value, $model, 'Content-Type Predicate URI is found');
	has_literal('text/turtle;charset=UTF-8', undef, undef, $model, 'Content-Type literal is found');
	is($model->size, 12, 'Model has the correct number of triples');
	is($model->count_statements(undef, undef, undef, iri('http://example.org/graphname')), 
		12, 'Model has the correct number of triples given graph');
	my @graphs = $model->get_contexts->get_all;
	is(scalar @graphs, 1, 'Just one graph');
	is($graphs[0]->uri_value, 'http://example.org/graphname', 'Correct graph name');
}



done_testing;

