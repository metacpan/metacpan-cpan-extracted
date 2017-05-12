#!/usr/bin/env perl

use Test::Simple tests => 4;

use strict;
use lib '../lib';
use RNA::HairpinFigure qw/draw/;
my $name = 'hsa-mir-92a-1 MI0000093 Homo sapiens miR-92a-1 stem-loop';
my $seq
    = 'CUUUCUACACAGGUUGGGAUCGGUUGCAAUGCUGUGUUUCUGUAUGGUAUUGCACUUGUCCCGGCCUGUUGAGUUUGG';
my $struct
    = '..(((...((((((((((((.(((.(((((((((((......)))))))))))))).)))))))))))).))).....';

my $f
    = "---CU   UAC            C   U           UU \n"
    . "     UUC   ACAGGUUGGGAU GGU GCAAUGCUGUG  U\n"
    . "     |||   |||||||||||| ||| |||||||||||   \n"
    . "     GAG   UGUCCGGCCCUG UCA CGUUAUGGUAU  G\n"
    . "GGUUU   --U            U   -           GU ";

my $figure = draw( $seq, $struct );
ok( $figure eq $f );

ok( draw( $seq, '' ) =~ /Missing/ );

ok( draw( $seq, $struct."[" ) =~ /Missmatch/ );

ok( draw( $seq."A", $struct."[" ) =~ /Illegal/ );