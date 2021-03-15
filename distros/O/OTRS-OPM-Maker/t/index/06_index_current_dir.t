#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Copy qw(copy);
use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OTRS::OPM::Maker::Command::index';

my $dir     = File::Spec->rel2abs( dirname __FILE__ );
my $opm_dir = File::Spec->catdir( $dir, '..', 'repo' );

mkdir './local_index';

my $opm_file   = File::Spec->catfile( $opm_dir, 'SecondSMTP-0.0.1.opm' );
my $local_file = File::Spec->catfile( './local_index', 'SecondSMTP-0.0.1.opm');
copy $opm_file, $local_file;

ok -f $local_file;

chdir './local_index';

my $index = q~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package_list version="1.0">
<Package>
  <Name>SecondSMTP</Name>
  <Version>0.0.1</Version>
  <Vendor>Renee Baecker, Perl-Services.de</Vendor>
  <URL>http://perl-services.de/</URL>
  <License>GNU AFFERO GENERAL PUBLIC LICENSE Version 3, November 2007</License>
  <Description Lang="en">A module that restricts email addresses.</Description>
  <Description Lang="de">Ein Modul, das den Emailversand auf Testsystemen einschränkt.</Description>
  <Framework>3.0.x</Framework>
  <Filelist>
    <FileDoc Permission="644" Location="doc/en/Test.pdf"/>
  </Filelist>
  <File>/SecondSMTP-0.0.1.opm</File>
</Package>

</otrs_package_list>
~;

{
    my $exec_output = capture_stdout {
        OTRS::OPM::Maker::Command::index::execute( undef, {}, [ '.' ] );
    };

    chdir '..';
    unlink $local_file; 
    ok !-f $local_file;

    #diag $exec_output;

    is_string $exec_output, $index, $opm_dir;
}

done_testing();
