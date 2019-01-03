#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use OTRS::OPM::Maker;
use OTRS::OPM::Maker::Command::dependencies;

my $dependencies = OTRS::OPM::Maker::Command::dependencies->new({
    app => OTRS::OPM::Maker->new
});

{
    my $error;
    eval { $dependencies->validate_args(); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $dependencies->validate_args( undef, undef ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $dependencies->validate_args( undef, {} ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $dependencies->validate_args( undef, [] ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $dependencies->validate_args( undef, [undef] ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $dependencies->validate_args( undef, ['test.txt'] ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $error;
    eval { $dependencies->validate_args( undef, ['o_o_m_c_b_does_not_exist.sopm'] ); 1;} or $error = $@;
    like $error, qr/Error: need path to .sopm/;
}

{
    my $file   = File::Spec->catfile( dirname(__FILE__), '..', 'valid', 'TestSMTP', 'TestSMTP.sopm' );
    my $error;
    eval { $dependencies->validate_args( undef, [$file] ); 1;} or $error = $@;;
    is $error, undef;
}

{
    my $file   = File::Spec->catfile( dirname(__FILE__), '..', 'repo', 'TestSMTP-0.0.1.opm' );
    my $error;
    eval { $dependencies->validate_args( undef, [$file] ); 1;} or $error = $@;;
    is $error, undef;
}

done_testing;
