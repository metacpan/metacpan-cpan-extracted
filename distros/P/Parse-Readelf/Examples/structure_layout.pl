#!/usr/bin/perl
#
# This script extracts the layout of structures matching a given
# pattern from the debug information embedded in one or more object
# files.  (To ease debugging it also allows for pre-extracted object
# information in files ending with ".lst").
#
# Author: Thomas Dorner
# Copyright: (C) 2007-2013 by Thomas Dorner (Artistic License)

use strict;
use warnings;

use File::Spec;

BEGIN {
    # allow for usage in directory where archive got unpacked:
    my @split_path = File::Spec->splitpath($0);
    my $libpath = File::Spec->catpath(@split_path[0..1]);
    $libpath = File::Spec->catdir($libpath, '..', 'lib');
    $libpath = File::Spec->rel2abs($libpath);
    if (-d $libpath)
    {
	print 'adding ', $libpath, ' to @INC', "\n";
	unshift @INC, $libpath;
    }
    require Parse::Readelf;
};

die "usage: structure-layout.pl <regexp-for-identifier> <object-file>...\n"
    unless 2 <= @ARGV;

my $re_identifier = shift @ARGV;
$re_identifier = join('', <STDIN>) if $re_identifier eq '-';

# save commands to reset them if changed later:
my $prdl_cmd = $Parse::Readelf::Debug::Line::command;
my $prdi_cmd = $Parse::Readelf::Debug::Info::command;

{
    no warnings 'once';
    $Parse::Readelf::Debug::Info::re_substructure_filter =
	join('|',
	     # don't expand some of our special structures as substructures:
	     '^CVarArea$',
	     '^CVarString$',
	     '^TArea<',
	     '^TArray<',
	     '^TBit<',
	     '^TBitMatrix<',
	     '^TFixString<',
	     # ignore some standard structures when expanding substructures:
	     '^basic_string',
	     '^shared_ptr<std::',
	     '^string$');
}

# loop over objects:
foreach my $object (@ARGV)
{
    my $tmpfile = undef;
    # handle preextracted lists:
    if ($object eq '-'  or  $object =~ m/\.lst$/)
    {
	$Parse::Readelf::Debug::Line::command = 'cat';
	$Parse::Readelf::Debug::Info::command = 'cat';
	if ($object eq '-')
	{
	    require File::Temp;
	    $tmpfile = File::Temp->new(SUFFIX => '.lst');
	    $object = $tmpfile->filename;
	    print $tmpfile $_ while <STDIN>;
	}
    }
    else
    {
	$Parse::Readelf::Debug::Line::command = $prdl_cmd;
	$Parse::Readelf::Debug::Info::command = $prdi_cmd;
    }

    # parse object and print structure layout for matching identifiers:
    my $readelf_data = new Parse::Readelf($object);
$Parse::Readelf::Debug::Info::display_nested_items = 1;
    $readelf_data->print_structure_layout($re_identifier, 1);
}
