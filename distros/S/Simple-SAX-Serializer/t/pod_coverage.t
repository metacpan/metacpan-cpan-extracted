use strict;
use warnings;

use Test::Pod::Coverage tests => 4;

pod_coverage_ok('Simple::SAX::Serializer', "should have value Simple::SAX::Serializer POD file" );
pod_coverage_ok('Simple::SAX::Serializer::Parser', "should have value Simple::SAX::Serializer::Parser POD file");
pod_coverage_ok('Simple::SAX::Serializer::Element', "should have value Simple::SAX::Serializer::Element file");
pod_coverage_ok('Simple::SAX::Serializer::Handler', "should have value Simple::SAX::Serializer::Handler file");

