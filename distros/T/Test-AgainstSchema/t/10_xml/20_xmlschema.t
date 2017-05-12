#!/usr/bin/env perl

# Exercise the XML Schema tests

use 5.008;
use strict;
use warnings;
use vars qw($vol $dir);

use File::Spec;
use Test::More;
use Test::Builder::Tester tests => 12;

# Testing this:
use Test::AgainstSchema::XML;

($vol, $dir, undef) = File::Spec->splitpath(File::Spec->rel2abs($0));
$dir = File::Spec->catpath($vol, $dir, '');
require File::Spec->catfile($dir, '..', 'util.pl');
require File::Spec->catfile($dir, 'basic_tests.pl');

our $VERSION = '1.000';
my ($schemafile, $badschemafile);

$schemafile = File::Spec->catfile($dir, 'simple.xsd');
$badschemafile = File::Spec->catfile($dir, 'simple-bad.xsd');

basic_tests(
    type          => 'XSD',
    class         => 'XML::LibXML::Schema',
    basecall      => \&is_valid_against_xmlschema,
    alias1        => \&is_valid_against_xsd,
    alias2        => \&xmlschema_ok,
    schemafile    => $schemafile,
    badschemafile => $badschemafile
);

exit 0;
