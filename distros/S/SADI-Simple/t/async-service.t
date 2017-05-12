#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use lib 'lib';

use Test::Simple tests => 2;
use CGITest qw(simulate_cgi_request);
use Log::Log4perl qw(:easy);
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use File::Spec::Functions;

#----------------------------------------------------------------------
# General test setup
#----------------------------------------------------------------------

Log::Log4perl->easy_init($WARN);

my $greeting_property = RDF::Trine::Node::Resource->new('http://sadiframework.org/examples/hello.owl#greeting');
my $is_defined_by_property = RDF::Trine::Node::Resource->new('http://www.w3.org/2000/01/rdf-schema#isDefinedBy');

#----------------------------------------------------------------------
# TEST: Service invocation where input is RDF/XML and 
# output is RDF/XML
#----------------------------------------------------------------------

my $output_rdfxml = invoke_async_service(
                            cgi_script => catfile('t', 'HelloWorldAsync.pl'),
                            input_file => catfile('t', 'hello-input.rdf'),
                            rdf_format => 'rdfxml'
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

my $output_n3 = invoke_async_service(
                        cgi_script => catfile('t', 'HelloWorldAsync.pl'),
                        input_file => catfile('t', 'hello-input.n3'),
                        rdf_format => 'turtle'
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

#------------------------------------------------------------
# helper subroutines
#------------------------------------------------------------

sub invoke_async_service
{
    my %args = @_;

    foreach my $required_arg ('cgi_script', 'input_file', 'rdf_format') {
        die "missing required arg $required_arg" unless $args{$required_arg};
    }

    my $media_type = $args{rdf_format} eq 'turtle' ? 'text/rdf+n3' : 'application/rdf+xml';

    my ($output, $headers) = simulate_cgi_request(
        request_method => 'POST',
        cgi_script => $args{cgi_script},
        input_file => $args{input_file},
        content_type => $media_type,
        http_accept => $media_type,
    );

    my $parser = RDF::Trine::Parser->new($args{rdf_format});

    while ($headers->{Status} && $headers->{Status} =~ /202|302/) {

        # get poll ID

        my $model = RDF::Trine::Model->temporary_model;
        $parser->parse_into_model(undef, $output, $model);

        my ($polling_url) = $model->objects(undef, $is_defined_by_property);
        $polling_url->uri =~ /poll=(.*?)$/;
        my $poll_id = $1;

        ($output, $headers) = 

                simulate_cgi_request(
                    request_method => 'GET',
                    cgi_script => $args{cgi_script},
                    http_accept => $media_type,
                    params => { poll => $poll_id },
                );

    }

    return wantarray ? ($output, $headers) : $output;
}

#----------------------------------------------------------------------
# TEST: Service invocation where input is RDF/XML is malformed. 
# Expected response is HTTP 500.
#----------------------------------------------------------------------

# TODO: This test works, but displays an XML parser ERROR that looks worrisome 
# to CPAN users

#my ($output, $headers) = simulate_cgi_request(
#                        request_method => 'POST',
#                        cgi_script => catfile('t', 'HelloWorldAsync.pl'),
#                        input_file => catfile('t', 'hello-input.rdf.malformed'),
#                        content_type => 'application/rdf+xml',
#                        http_accept => 'application/rdf+xml',
#                    );
#
#ok($headers->{Status} eq 500, 'test service response on malformed input RDF/XML');
