#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OTRS::OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'ForeignKeyCreate.json' );
my $sopm = File::Spec->catfile( $dir, 'ForeignKeyCreate.sopm' );

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

OTRS::OPM::Maker::Command::sopm::execute( undef, { config => $json }, [ $dir ] );

ok -e $sopm;

my $version = $OTRS::OPM::Maker::Command::sopm::VERSION;

my $content = do{ local (@ARGV, $/) = $sopm; <> };
my $check   = qq~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package version="1.0">
    <!-- GENERATED WITH OTRS::OPM::Maker::Command::sopm ($version) -->
    <Name>ForeignKeyCreate</Name>
    <Version>0.0.3</Version>
    <Framework>3.2.x</Framework>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de</URL>
    <Description Lang="en">Test sopm command</Description>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Filelist>
        <File Permission="644" Location="01_simple_json.t" />
        <File Permission="644" Location="02_intro.t" />
        <File Permission="644" Location="03_database.t" />
        <File Permission="644" Location="04_cvs.t" />
        <File Permission="644" Location="05_foreign_key_create.t" />
        <File Permission="644" Location="06_type_exception.t" />
        <File Permission="644" Location="Database.json" />
        <File Permission="644" Location="ForeignKeyCreate.json" />
        <File Permission="644" Location="Intro.json" />
        <File Permission="644" Location="Test.json" />
    </Filelist>
    <DatabaseInstall Type="post">
        <TableCreate Name="opar_test">
            <Column Name="id" Required="true" Type="INTEGER" AutoIncrement="true" PrimaryKey="true" />
            <Column Name="object_id" Required="true" Type="INTEGER" />
            <Column Name="object_type" Required="true" Type="VARCHAR" Size="55" />
        </TableCreate>
    </DatabaseInstall>
    <DatabaseUpgrade Type="post">
        <TableAlter Name="opar_test" Version="0.0.2">
            <ForeignKeyCreate ForeignTable="ticket">
                <Reference Local="id" Foreign="id" />
            </ForeignKeyCreate>
            <ForeignKeyCreate ForeignTable="config_item">
                <Reference Local="object_id" Foreign="id" />
            </ForeignKeyCreate>
        </TableAlter>
    </DatabaseUpgrade>
    <DatabaseUninstall Type="pre">
        <TableDrop Name="opar_test" />
    </DatabaseUninstall>
</otrs_package>
~;

is_string $content, $check;

done_testing();
