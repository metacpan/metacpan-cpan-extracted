#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'ForeignKeyDrop.json' );
my $sopm = File::Spec->catfile( $dir, 'ForeignKeyDrop.sopm' );

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
    <Name>ForeignKeyDrop</Name>
    <Version>0.0.3</Version>
    <Framework>3.2.x</Framework>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de</URL>
    <Description Lang="en">Test sopm command</Description>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Filelist>
        <File Permission="644" Location="01_foreign_key_drop.t" />
        <File Permission="644" Location="ForeignKeyDrop.json" />
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
            <ForeignKeyDrop ForeignTable="ticket">
                <Reference Local="id" Foreign="id" />
            </ForeignKeyDrop>
            <ForeignKeyDrop ForeignTable="config_item">
                <Reference Local="object_id" Foreign="id" />
            </ForeignKeyDrop>
        </TableAlter>
    </DatabaseUpgrade>
    <DatabaseUninstall Type="pre">
        <TableDrop Name="opar_test" />
    </DatabaseUninstall>
</otrs_package>
~;

is_string $content, $check;

done_testing();
