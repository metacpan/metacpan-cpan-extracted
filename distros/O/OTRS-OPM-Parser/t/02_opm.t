#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OTRS::OPM::Parser;

use File::Basename;
use File::Spec;

my $opm_file = File::Spec->catfile( dirname(__FILE__), 'data', 'QuickMerge-3.3.2.opm' );
my $opm      = OTRS::OPM::Parser->new( opm_file => $opm_file );

isa_ok $opm, 'OTRS::OPM::Parser';

$opm->parse;

ok $opm->tree, 'tree exists';
isa_ok $opm->tree, 'XML::LibXML::Document';

is $opm->name, 'QuickMerge', 'name';
is $opm->version, '3.3.2', 'version';
is $opm->vendor, 'Perl-Services.de', 'vendor';
is $opm->url, 'http://www.perl-services.de/', 'url';
is $opm->license, 'GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007', 'license';
is $opm->description, 'A module to merge tickets more quickly.', 'description';

is $opm->opm_file, $opm_file, 'opm_file';

is_deeply [ map{ $_->{filename} }@{ $opm->files } ], [qw!
  Kernel/Config/Files/QuickMerge.xml
  Kernel/Output/HTML/OutputFilterMergeOverview.pm
  doc/en/QuickMerge.pod
!], 'files';

my ($doc) = map{ $_->{filename} }$opm->documentation;
is $doc, 'doc/en/QuickMerge.pod', 'documentation';

is_deeply $opm->framework, [qw/
    3.0.x
    3.1.x
    3.2.x
    3.3.x
/], 'framework';

is_deeply $opm->dependencies, [
    { type => 'OTRS', version => '0.0.1', name => 'TestPackage' },
    { type => 'OTRS', version => '1.2.4', name => 'LocalPackage' },
    { type => 'CPAN', version => '4.32', name => 'Mojolicious' },
], 'dependencies';

my $sopm = do { local $/; <DATA> };
is $opm->as_sopm, $sopm, 'as_sopm';

done_testing();

__DATA__
<?xml version="1.0" encoding="utf-8"?>
<otrs_package version="1.0">
    <CVS>$Id: QuickMerge.sopm,v 1.1.1.1 2011/04/15 07:49:58 rb Exp $</CVS>
    <Name>QuickMerge</Name>
    <Version>3.3.2</Version>
    <Framework>3.0.x</Framework>
    <Framework>3.1.x</Framework>
    <Framework>3.2.x</Framework>
    <Framework>3.3.x</Framework>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de/</URL>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Description Lang="en">A module to merge tickets more quickly.</Description>
    <Description Lang="de">Ein Modul, mit dem Tickets schneller/einfacher zusammengefasst werden können.</Description>
    <PackageRequired Version="0.0.1">TestPackage</PackageRequired>
    <PackageRequired Version="1.2.4">LocalPackage</PackageRequired>
    <ModuleRequired Version="4.32">Mojolicious</ModuleRequired>
    <Filelist>
        <File Permission="644" Location="Kernel/Config/Files/QuickMerge.xml"/>
        <File Permission="644" Location="Kernel/Output/HTML/OutputFilterMergeOverview.pm"/>
        <File Permission="644" Location="doc/en/QuickMerge.pod"/>
    </Filelist>
</otrs_package>
