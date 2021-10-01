#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::index';

my $dir     = File::Spec->rel2abs( dirname __FILE__ );
my $opm_dir = File::Spec->catdir( $dir, '..', 'otobo-repo' );

my $index = q~<?xml version="1.0" encoding="utf-8" ?>
<otobo_package_list version="1.0">
<Package>
  <Name>SecondSMTP</Name>
  <Version>0.0.1</Version>
  <Vendor>Renee Baecker, Perl-Services.de</Vendor>
  <URL>http://perl-services.de/</URL>
  <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
  <Description Lang="en">A module that restricts email addresses.</Description>
  <Description Lang="de">Ein Modul, das den Emailversand auf Testsystemen einschränkt.</Description>
  <Framework>10.0.x</Framework>
  <Filelist>
    <FileDoc Permission="644" Location="doc/en/Test.pdf"/>
  </Filelist>
  <File>/SecondSMTP-0.0.1.opm</File>
</Package>
<Package>
  <Name>TestSMTP</Name>
  <Version>0.0.1</Version>
  <Vendor>Renee Baecker, Perl-Services.de</Vendor>
  <URL>http://perl-services.de/</URL>
  <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
  <Description Lang="en">A module that restricts email addresses.</Description>
  <Description Lang="de">Ein Modul, das den Emailversand auf Testsystemen einschränkt.</Description>
  <Framework>3.0.x</Framework>
  <Filelist/>
  <File>/TestSMTP-0.0.1.opm</File>
</Package>

</otobo_package_list>
~;

{
    my $exec_output = capture_stdout {
        OPM::Maker::Command::index::execute( undef, {}, [ $opm_dir ] );
    };

    #diag $exec_output;

    is_string $exec_output, $index, $opm_dir;
}

done_testing();
