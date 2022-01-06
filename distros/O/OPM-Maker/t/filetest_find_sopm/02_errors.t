#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::filetest';

my $dir  = File::Spec->catdir( dirname( __FILE__ ), qw/ .. invalid / );
chdir $dir;

my $args = [];


{

    my $error;
    eval {
        OPM::Maker::Command::filetest::execute( undef, {}, $args );
    } or $error = $@;

    like_string $error, qr/Found more than one .sopm file/;
}

done_testing();
