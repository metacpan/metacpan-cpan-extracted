#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'Database.json' );
my $sopm = File::Spec->catfile( $dir, 'Database.sopm' );

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

OPM::Maker::Command::sopm::execute( undef, { config => $json }, [ $dir ] );

ok -e $sopm;

my $version = $OPM::Maker::Command::sopm::VERSION;

my $content = do{ local (@ARGV, $/) = $sopm; <> };
my $check   = qq~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package version="1.0">
    <!-- GENERATED WITH OPM::Maker::Command::sopm ($version) -->
    <Name>Database</Name>
    <Version>0.0.3</Version>
    <Framework>3.0.x</Framework>
    <Framework>3.1.x</Framework>
    <Framework>3.2.x</Framework>
    <PackageRequired Version="3.2.1">TicketOverviewHooked</PackageRequired>
    <ModuleRequired Version="0.01">Digest::MD5</ModuleRequired>
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
            <Unique Name="id_object_id">
                <UniqueColumn Name="id" />
                <UniqueColumn Name="object_id" />
            </Unique>
            <ForeignKey ForeignTable="system_user">
                <Reference Local="object_id" Foreign="id" />
            </ForeignKey>
        </TableCreate>
        <TableCreate Name="opar_test_2">
            <Column Name="id" Required="true" Type="INTEGER" AutoIncrement="true" PrimaryKey="true" />
            <Column Name="object_id" Required="true" Type="INTEGER" />
            <Column Name="object_type" Required="true" Type="VARCHAR" Size="55" />
            <Unique Name="my_unique">
                <UniqueColumn Name="id" />
                <UniqueColumn Name="object_id" />
            </Unique>
            <ForeignKey ForeignTable="system_user">
                <Reference Local="object_id" Foreign="id" />
            </ForeignKey>
        </TableCreate>
        <Insert Table="ticket_history_type">
            <Data Key="name" Type="Quote"><![CDATA[teest]]></Data>
            <Data Key="comments" Type="Quote"><![CDATA[test]]></Data>
            <Data Key="valid_id">1</Data>
            <Data Key="create_time" Type="Quote"><![CDATA[2012-10-18 00:00:00]]></Data>
            <Data Key="create_by">1</Data>
            <Data Key="change_time" Type="Quote"><![CDATA[2012-10-18 00:00:00]]></Data>
            <Data Key="change_by">1</Data>
        </Insert>
        <Insert Table="ticket_history_type">
            <Data Key="name" Type="Quote"><![CDATA[test1
test2]]></Data>
            <Data Key="comments" Type="Quote"><![CDATA[test]]></Data>
            <Data Key="valid_id">1</Data>
            <Data Key="create_time" Type="Quote"><![CDATA[2012-10-18 00:00:00]]></Data>
            <Data Key="create_by">1</Data>
            <Data Key="change_time" Type="Quote"><![CDATA[2012-10-18 00:00:00]]></Data>
            <Data Key="change_by">1</Data>
        </Insert>
    </DatabaseInstall>
    <DatabaseUpgrade Type="post">
        <Insert Table="ticket_history_type" Version="0.0.2">
            <Data Key="name" Type="Quote"><![CDATA[teest]]></Data>
            <Data Key="comments" Type="Quote"><![CDATA[test]]></Data>
            <Data Key="valid_id">1</Data>
            <Data Key="create_time" Type="Quote"><![CDATA[2012-10-18 00:00:00]]></Data>
            <Data Key="create_by">1</Data>
            <Data Key="change_time" Type="Quote"><![CDATA[2012-10-18 00:00:00]]></Data>
            <Data Key="change_by">1</Data>
        </Insert>
        <Insert Table="ticket_history_type" Version="0.0.2">
            <Data Key="name" Type="Quote"><![CDATA[test1
test2]]></Data>
            <Data Key="comments" Type="Quote"><![CDATA[test]]></Data>
            <Data Key="valid_id">1</Data>
            <Data Key="create_time" Type="Quote"><![CDATA[2012-10-18 00:00:00]]></Data>
            <Data Key="create_by">1</Data>
            <Data Key="change_time" Type="Quote"><![CDATA[2012-10-18 00:00:00]]></Data>
            <Data Key="change_by">1</Data>
        </Insert>
    </DatabaseUpgrade>
    <DatabaseUninstall Type="pre">
        <TableDrop Name="opar_test_2" />
        <TableDrop Name="opar_test" />
    </DatabaseUninstall>
</otrs_package>
~;

is_string $content, $check;

done_testing();
