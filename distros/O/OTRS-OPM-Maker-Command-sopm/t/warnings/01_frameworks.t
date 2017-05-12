#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use Capture::Tiny qw(:all);

use_ok 'OTRS::OPM::Maker::Command::sopm';

my $dir          = File::Spec->rel2abs( dirname __FILE__ );
my $warn_json    = File::Spec->catfile( $dir, 'Test.json' );
my $no_warn_json = File::Spec->catfile( $dir, 'TestOneMajor.json' );
my $source_dir   = File::Spec->catdir( $dir, '01' );

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

{
    my ($stdout, $stderr, @result) = capture {
        OTRS::OPM::Maker::Command::sopm::execute( undef, { config => $warn_json }, [ $source_dir ] );
    };

    like $stderr,
        qr/Two major versions declared in framework settings. Those might be incompatible./,
        'incompatibilities warning';
}

{
    my ($stdout, $stderr, @result) = capture {
        OTRS::OPM::Maker::Command::sopm::execute( undef, { config => $no_warn_json }, [ $source_dir ] );
    };

    unlike $stderr,
        qr/Two major versions declared in framework settings. Those might be incompatible./,
        'no imcompatibilities';
}

@files = <$dir/*.sopm>;
unlink @files;

@files_check = <$dir/*.sopm>;
ok !@files_check;

done_testing();
