#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use Capture::Tiny qw(:all);

use_ok 'OTRS::OPM::Maker::Command::sopm';

my $dir        = File::Spec->rel2abs( dirname __FILE__ );
my $warn_json  = File::Spec->catfile( $dir, 'Test.json' );
my $source_dir = File::Spec->catdir( $dir, '02' );

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

{
    my ($stdout, $stderr, @result) = capture {
        OTRS::OPM::Maker::Command::sopm::execute( undef, { config => $warn_json }, [ $source_dir ] );
    };

    like $stderr,
        qr/The old template engine was replaced with Template::Toolkit. Please use bin\/otrs.MigrateDTLToTT.pl./,
        'incompatibilities warning';
}

@files = <$dir/*.sopm>;
unlink @files;

@files_check = <$dir/*.sopm>;
ok !@files_check;

done_testing();
