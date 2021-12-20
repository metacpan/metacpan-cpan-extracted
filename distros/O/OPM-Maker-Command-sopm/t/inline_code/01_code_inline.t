#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'Test.json' );
my $sopm = File::Spec->catfile( $dir, 'Test.sopm' );

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

OPM::Maker::Command::sopm::execute( undef, { config => $json }, [ $dir ] );

ok -e $sopm;

my $version = $OPM::Maker::Command::sopm::VERSION;

my $content = do{ local (@ARGV, $/) = $sopm; <> };
my $check   = sprintf q~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package version="1.0">
    <!-- GENERATED WITH OPM::Maker::Command::sopm (%s) -->
    <Name>Test</Name>
    <Version>0.0.3</Version>
    <Framework>4.0.x</Framework>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de</URL>
    <Description Lang="en">Test sopm command</Description>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Filelist>
        <File Permission="644" Location="01_code_inline.t" />
        <File Permission="644" Location="Test.json" />
        <File Permission="644" Location="Test.pm" />
    </Filelist>
    <CodeInstall Type="post"><![CDATA[
        my ($Self, %%Params) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request';
    my $Test = $ParamObject->GetParam('Test');

    if ( $Test ) {
        for ( 0 .. 10 ) {
            warn $_;
        }
    }

    for ( 0 .. 10 ) {
        warn $_;
    }

    return 1;

    ]]></CodeInstall>
</otrs_package>
~, $version;

is_string $content, $check;

done_testing();
