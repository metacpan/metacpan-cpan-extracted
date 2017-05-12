#!/usr/bin/perl -w                                         # -*- perl -*-
# $Id: 10-features.t 4114 2009-03-04 22:28:43Z andrew $

use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);

use lib ($Bin, "$Bin/../lib");
use Pod::POM;
use Pod::POM::View::DocBook;
use XML::LibXML;

# use Data::Dumper; # for debugging

use Test::More;
use Test::XML;

use TestUtils;


my @tests = get_tests();

plan tests => 2 * int @tests;

my $pod_parser = Pod::POM->new();
my $xml_parser = XML::LibXML->new();

# parser tests seem to hang on RHEL5 on looking up identifiers
# tried to sort it by explicitly loading a local catalog but that doesn't seem to work.
#my $rc = $xml_parser->load_catalog( "./catalog/4.5/catalog.xml" );


foreach my $test (@tests) {
    my $view = 'Pod::POM::View::DocBook';
    if (keys %{$test->viewoptions}) {
        $view = $view->new(%{$test->viewoptions});
    }

    my $pom    = $pod_parser->parse_text($test->input);
    my $result = $pom->present($view);


    is_xml(normalize($result), normalize($test->expect),
	       "matched output: " . $test->description);

    eval { 
        my $doc = $xml_parser->parse_string($result);
    };
    is($@, "", "parsed  output: " . $test->description);
}


