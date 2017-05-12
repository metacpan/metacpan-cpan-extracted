#!/usr/bin/env perl

# Test the parsing-only tests of Test::Formats::XML

use 5.008;
use strict;
use warnings;
use vars qw($vol $dir $file $fh $parser $doc);

use File::Spec;
use Test::Builder::Tester tests => 6;

# Testing this:
use Test::AgainstSchema::XML;

our $VERSION = '1.000';

($vol, $dir, undef) = File::Spec->splitpath(File::Spec->rel2abs($0));
$dir = File::Spec->catpath($vol, $dir, '');

test_out('ok 1 - string');
test_out('not ok 2 - string fail');
test_out('ok 3 - string, no PI');
is_well_formed_xml(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, 'string');
is_well_formed_xml(q{<?xml version="1.0"?>
<container><data>foo<data></container>
}, 'string fail');
is_well_formed_xml(q{<container><data>foo</data></container>}, 'string, no PI');
test_test(name => 'basic string argument', skip_err => 1);

# Test the alias
test_out('ok 1 - string alias');
xml_parses_ok(q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, 'string alias');
test_test(name => 'string argument, xml_parses_ok alias', skip_err => 1);

# Test the reading of XML from filehandles
test_out('ok 1 - filehandle');
test_out('not ok 2 - filehandle fail');
$file = File::Spec->catfile($dir, 'xml-simple.xml');
if (! (open $fh, '<', $file))
{
    die "Error opening $file: $!";
}
is_well_formed_xml($fh, 'filehandle');
close $fh;
$file = File::Spec->catfile($dir, 'xml-simple-bad.xml');
if (! (open $fh, '<', $file))
{
    die "Error opening $file: $!";
}
is_well_formed_xml($fh, 'filehandle fail');
close $fh;
test_test(name => 'filehandle argument', skip_err => 1);

# Test scalar refs with the same tests we used for strings
test_out('ok 1 - stringref');
test_out('not ok 2 - stringref fail');
test_out('ok 3 - stringref, no PI');
is_well_formed_xml(\q{<?xml version="1.0"?>
<container><data>foo</data></container>
}, 'stringref');
is_well_formed_xml(\q{<?xml version="1.0"?>
<container><data>foo<data></container>
}, 'stringref fail');
is_well_formed_xml(\q{<container><data>foo</data></container>},
                   'stringref, no PI');
test_test(name => 'basic string argument', skip_err => 1);

# Test a pre-parsed document as a XML::LibXML::Document
$file = File::Spec->catfile($dir, 'xml-simple.xml');
$parser = XML::LibXML->new();
$doc = $parser->parse_file($file);
test_out('ok 1 - parsed dom');
is_well_formed_xml($doc, 'parsed dom');
test_test(name => 'parsed document argument', skip_err => 1);

# Test filenames as arguments
test_out('ok 1 - filename');
test_out('not ok 2 - filename parse fail');
test_out('not ok 3 - filename open fail');
$file = File::Spec->catfile($dir, 'xml-simple.xml');
is_well_formed_xml($file, 'filename');
$file = File::Spec->catfile($dir, 'xml-simple-bad.xml');
is_well_formed_xml($file, 'filename parse fail');
$file = File::Spec->catfile($dir, 'xml-simple-nofile.xml');
is_well_formed_xml($file, 'filename open fail');
test_test(name => 'filename argument', skip_err => 1);

exit 0;
