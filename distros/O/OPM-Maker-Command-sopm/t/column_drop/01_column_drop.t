#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'ColumnDrop.json' );
my $sopm = File::Spec->catfile( $dir, 'ColumnDrop.sopm' );

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
    <Name>ColumnDrop</Name>
    <Version>0.0.3</Version>
    <Framework>3.2.x</Framework>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de</URL>
    <Description Lang="en">Test sopm command</Description>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Filelist>
        <File Permission="644" Location="01_column_drop.t" />
        <File Permission="644" Location="ColumnDrop.json" />
    </Filelist>
    <DatabaseUninstall Type="pre">
        <TableAlter Name="opar_test">
            <ColumnDrop Name="col1" />
        </TableAlter>
    </DatabaseUninstall>
</otrs_package>
~;

is_string $content, $check;

done_testing();
