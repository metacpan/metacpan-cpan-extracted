#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OTRS::OPM::Maker::Command::sopm';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $json = File::Spec->catfile( $dir, 'Changelog.json' );
my $sopm = File::Spec->catfile( $dir, '01/Test.sopm' );
my $tdir = File::Spec->catdir( $dir, '01' );

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

OTRS::OPM::Maker::Command::sopm::execute( undef, { config => $json }, [ $tdir ] );

ok -e $sopm;

my $version = $OTRS::OPM::Maker::Command::sopm::VERSION;

my $content = do{ local (@ARGV, $/) = $sopm; <> };
my $check   = qq~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package version="1.0">
    <!-- GENERATED WITH OTRS::OPM::Maker::Command::sopm ($version) -->
    <Name>Test</Name>
    <Version>0.0.3</Version>
    <Framework>3.0.x</Framework>
    <PackageRequired Version="3.2.1">TicketOverviewHooked</PackageRequired>
    <ModuleRequired Version="0.01">Digest::MD5</ModuleRequired>
    <Vendor>Perl-Services.de</Vendor>
    <URL>http://www.perl-services.de</URL>
    <Description Lang="en">Test sopm command</Description>
    <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
    <Filelist>
        <File Permission="644" Location="Test.txt" />
    </Filelist>
    <ChangeLog Version="5.0.1" Date="2015-11-30 12:32:00"><![CDATA[ Das ist ein Test ]]></ChangeLog>
    <ChangeLog Version="4.0.2" Date="2015-10-29 13:44:55"><![CDATA[ Noch eiin Test ]]></ChangeLog>
    <CodeInstall Type="post"><![CDATA[
        # define function name
        my \$FunctionName = 'CodeInstall';

        # create the package name
        my \$CodeModule = 'var::packagesetup::' . \$Param{Structure}->{Name}->{Content};

        # load the module
        if ( \$Self->{MainObject}->Require(\$CodeModule) ) {

            # create new instance
            my \$CodeObject = \$CodeModule->new( %{\$Self} );

            if (\$CodeObject) {

                # start methode
                if ( !\$CodeObject->\$FunctionName(%{\$Self}) ) {
                    \$Self->{LogObject}->Log(
                        Priority => 'error',
                        Message  => "Could not call method \$FunctionName() on \$CodeModule.pm."
                    );
                }
            }

            # error handling
            else {
                \$Self->{LogObject}->Log(
                    Priority => 'error',
                    Message  => "Could not call method new() on \$CodeModule.pm."
                );
            }
        }

    ]]></CodeInstall>
</otrs_package>
~;

is_string $content, $check;

done_testing();
