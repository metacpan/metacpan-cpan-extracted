#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'Phase.json' );
my $sopm = File::Spec->catfile( $dir, 'Phase.sopm' );

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
    <Name>Phase</Name>
    <Version>0.0.3</Version>
    <Framework>3.2.x</Framework>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de</URL>
    <Description Lang="en">Test sopm command</Description>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Filelist>
        <File Permission="644" Location="01_base.t" />
        <File Permission="644" Location="02_phase.t" />
        <File Permission="644" Location="Database.json" />
        <File Permission="644" Location="Phase.json" />
    </Filelist>
    <DatabaseInstall Type="pre">
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
    <DatabaseUpgrade Type="pre">
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
</otrs_package>
~;

is_string $content, $check;

done_testing();
