#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use OTRS::OPM::Maker;
use OTRS::OPM::Maker::Command::index;

my $index = OTRS::OPM::Maker::Command::index->new({
    app => OTRS::OPM::Maker->new
});

{
    my $error;
    eval { $index->validate_args(); 1;} or $error = $@;
    like $error, qr/Error: need path to directory that contains opm files/;
}

{
    my $error;
    eval { $index->validate_args( undef, undef ); 1;} or $error = $@;
    like $error, qr/Error: need path to directory that contains opm files/;
}

{
    my $error;
    eval { $index->validate_args( undef, {} ); 1;} or $error = $@;
    like $error, qr/Error: need path to directory that contains opm files/;
}

{
    my $error;
    eval { $index->validate_args( undef, [] ); 1;} or $error = $@;
    like $error, qr/Error: need path to directory that contains opm files/;
}

{
    my $error;
    eval { $index->validate_args( undef, [undef] ); 1;} or $error = $@;
    like $error, qr/Error: need path to directory that contains opm files/;
}

{
    my $error;
    eval { $index->validate_args( undef, ['.'] ); 1;} or $error = $@;;
    is $error, undef;
}

done_testing;
