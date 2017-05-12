#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib qw( t/lib );

BEGIN {
    use_ok('TestExtenderSingleNS');
};

my $obj = TestExtenderSingleNS->new();

ok( $obj, 'New TestExtenderSingleNS instance');

my $xslt_proc = $obj->xslt_processor;

ok( $xslt_proc, 'Got an extended XSLT processor.');

my $xsl_file = 't/data/stylesheets/single_ns.xsl';
my $xml_file = 't/data/documents/single_ns.xml';

ok( -f $xsl_file, 'Stylesheet exists.');
ok( -f $xml_file, 'Input XML exists.');

my $style_dom = XML::LibXML->load_xml( location=> $xsl_file );
my $input_dom = XML::LibXML->load_xml( location=> $xml_file );

ok( $style_dom, 'XSL DOM exists.');
ok( $input_dom, 'Input DOM exists.');

my $stylesheet = $obj->parse_stylesheet($style_dom);

my $transd_dom = $stylesheet->transform( $input_dom );

ok ( $transd_dom, 'Got a transformed DOM');

my $root = $transd_dom->getDocumentElement();

ok( $root, 'Transformed XML has a root element');

cmp_ok( $root->findvalue('/result/foo'), 'eq', 'DEFAULT::TESTFOO::FOO');

cmp_ok( $root->findvalue('/result/bar'), 'eq', 'SETBYFOO::TESTBAR::BAR');

cmp_ok( $root->exists('/result/quux/setbybar'), '==', 1);

# warn "DEBUG " . $stylesheet->output_as_bytes($transd_dom);

done_testing();