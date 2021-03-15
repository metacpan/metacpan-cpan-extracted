#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use OPM::Maker;
use OPM::Maker::Command::build;

my $build = OPM::Maker::Command::build->new({
    app => OPM::Maker->new
});

{
    my $error;
    eval { $build->validate_args(); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $build->validate_args( undef, undef ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $build->validate_args( undef, {} ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $build->validate_args( undef, [] ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $build->validate_args( undef, [undef] ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $build->validate_args( undef, ['test.txt'] ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $build->validate_args( undef, ['o_o_m_c_b_does_not_exist.sopm'] ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $file   = File::Spec->catfile( dirname(__FILE__), '..', 'valid', 'TestSMTP', 'TestSMTP.sopm' );
    my $error;
    eval { $build->validate_args( undef, [$file] ); 1;} or $error = $@;;
    is $error, undef;
}

done_testing;
