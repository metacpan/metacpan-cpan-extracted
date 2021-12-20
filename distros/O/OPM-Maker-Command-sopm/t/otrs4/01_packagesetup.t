#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'Packagesetup.json' );
my $sopm = File::Spec->catfile( $dir, '01/Test.sopm' );
my $tdir = File::Spec->catdir( $dir, '01' );

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

OPM::Maker::Command::sopm::execute( undef, { config => $json }, [ $tdir ] );

ok -e $sopm;

my $version = $OPM::Maker::Command::sopm::VERSION;

my $content = do{ local (@ARGV, $/) = $sopm; <> };
my $check   = qq~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package version="1.0">
    <!-- GENERATED WITH OPM::Maker::Command::sopm ($version) -->
    <Name>Test</Name>
    <Version>0.0.3</Version>
    <Framework>4.0.x</Framework>
    <PackageRequired Version="3.2.1">TicketOverviewHooked</PackageRequired>
    <ModuleRequired Version="0.01">Digest::MD5</ModuleRequired>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de</URL>
    <Description Lang="en">Test sopm command</Description>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Filelist>
        <File Permission="644" Location="Test.txt" />
    </Filelist>
    <CodeInstall Type="post"><![CDATA[
        \$Kernel::OM->Get('var::packagesetup::' . \$Param{Structure}->{Name}->{Content} )->CodeInstall();
    ]]></CodeInstall>
    <CodeUpgrade Type="post"><![CDATA[
        \$Kernel::OM->Get('var::packagesetup::' . \$Param{Structure}->{Name}->{Content} )->CodeUpgrade();
    ]]></CodeUpgrade>
    <CodeUpgrade Type="post" Version="3"><![CDATA[
        \$Kernel::OM->Get('var::packagesetup::' . \$Param{Structure}->{Name}->{Content} )->UpgradeTo3();
    ]]></CodeUpgrade>
</otrs_package>
~;

is_string $content, $check;

done_testing();
