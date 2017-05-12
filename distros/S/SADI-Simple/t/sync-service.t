#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use lib 'lib';

use Test::Simple tests => 2;
use CGITest qw(simulate_cgi_request);
use Log::Log4perl qw(:easy);
use RDF::Trine::Model;
use RDF::Trine::Parser;
use File::Spec::Functions;

#----------------------------------------------------------------------
# General test setup
#----------------------------------------------------------------------

Log::Log4perl->easy_init($WARN);

my $greeting_property = RDF::Trine::Node::Resource->new('http://sadiframework.org/examples/hello.owl#greeting');

#----------------------------------------------------------------------
# TEST: Service invocation where input is RDF/XML and 
# output is RDF/XML
#----------------------------------------------------------------------

my $output_rdfxml = simulate_cgi_request(
                        request_method => 'POST',
                        cgi_script => catfile('t', 'HelloWorldSync.pl'),
                        input_file => catfile('t', 'hello-input.rdf'),
                        content_type => 'application/rdf+xml',
                        http_accept => 'application/rdf+xml',
                    );

my $model = RDF::Trine::Model->temporary_model;
my $parser = RDF::Trine::Parser->new('rdfxml');
$parser->parse_into_model(undef, $output_rdfxml, $model);

my $rdf_input = RDF::Trine::Node::Resource->new('http://sadiframework.org/examples/t/hello-input.rdf#1');
my @greetings = $model->objects($rdf_input, $greeting_property);

ok( 
    (@greetings == 1) && 
    $greetings[0]->is_literal && 
    $greetings[0]->value eq 'Hello, \'Guy Incognito\'!',

    'service invocation using RDF/XML for input and output'
);

#----------------------------------------------------------------------
# TEST: Service invocation where input is N3 and output is N3.
# Also tests the service with multiple inputs/outputs.
#----------------------------------------------------------------------

my $output_n3 = simulate_cgi_request(
                        request_method => 'POST',
                        cgi_script => catfile('t', 'HelloWorldSync.pl'),
                        input_file => catfile('t', 'hello-input.n3'),
                        content_type => 'text/rdf+n3',
                        http_accept => 'text/rdf+n3',
                    );

$model = RDF::Trine::Model->temporary_model;
$parser = RDF::Trine::Parser->new('turtle');
$parser->parse_into_model(undef, $output_n3, $model);

my $n3_input1 = RDF::Trine::Node::Resource->new('http://sadiframework.org/examples/t/hello-input.n3#1');
my $n3_input2 = RDF::Trine::Node::Resource->new('http://sadiframework.org/examples/t/hello-input.n3#2');

@greetings = $model->objects(undef, $greeting_property);
my ($greeting1) = $model->objects($n3_input1, $greeting_property);
my ($greeting2) = $model->objects($n3_input2, $greeting_property);

ok( 
    (@greetings == 2) && 
    $greeting1->is_literal && 
    ($greeting1->value eq 'Hello, \'Guy Incognito\'!') &&
    $greeting2->is_literal && 
    ($greeting2->value eq 'Hello, \'Homer Simpson\'!'),

    'service invocation using N3 for input and output'
);


#----------------------------------------------------------------------
# TEST: Service invocation where input is RDF/XML is malformed. 
# Expected response is HTTP 500.
#----------------------------------------------------------------------

# TODO: This test works, but displays an XML parser ERROR that looks worrisome 
# to CPAN users

#my ($output, $headers) = simulate_cgi_request(
#                        request_method => 'POST',
#                        cgi_script => catfile('t', 'HelloWorldSync.pl'),
#                        input_file => catfile('t', 'hello-input.rdf.malformed'),
#                        content_type => 'application/rdf+xml',
#                        http_accept => 'application/rdf+xml',
#                    );
#
#ok($headers->{Status} eq 500, 'test service response on malformed input RDF/XML');

