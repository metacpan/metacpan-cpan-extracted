#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OTRS::OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'TestInstall.json' );
my $sopm = File::Spec->catfile( $dir, 'TestInstall.sopm' );

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

OTRS::OPM::Maker::Command::sopm::execute( undef, { config => $json }, [ $dir ] );

ok -e $sopm;

my $version = $OTRS::OPM::Maker::Command::sopm::VERSION;
#diag $version;

my $content = do{ local (@ARGV, $/) = $sopm; <> };
my $check   = qq~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package version="1.0">
    <!-- GENERATED WITH OTRS::OPM::Maker::Command::sopm ($version) -->
    <Name>TestInstall</Name>
    <Version>0.0.3</Version>
    <Framework>4.0.x</Framework>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de</URL>
    <Description Lang="en">Test sopm command</Description>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Filelist>
        <File Permission="644" Location="01_code_uninstall.t" />
        <File Permission="644" Location="02_code_uninstall_pre.t" />
        <File Permission="644" Location="03_code_uninstall_pre_3.t" />
        <File Permission="644" Location="04_code_install_package.t" />
        <File Permission="644" Location="Test.json" />
        <File Permission="644" Location="TestInstall.json" />
        <File Permission="644" Location="TestPre.json" />
        <File Permission="644" Location="TestPre3.json" />
    </Filelist>
    <CodeInstall Type="post"><![CDATA[
        \$Kernel::OM->Get('var::packagesetup::' . 'OtherPackage' )->CodeInstall();
    ]]></CodeInstall>
    <CodeUninstall Type="post"><![CDATA[
        \$Kernel::OM->Get('var::packagesetup::' . 'OtherPackage' )->CodeUninstall();
    ]]></CodeUninstall>
</otrs_package>
~;

is_string $content, $check;

done_testing();
