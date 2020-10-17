#!/usr/bin/perl
#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2009
# Update    : 20/07/2009
# AIM       : Test quantile type 7 calcul
#==================================================================
use strict;
use warnings;
use Carp;

use Test::More tests => 15;
use Statistics::Descriptive;

my @data1 = ( 1 .. 10 );
my @data2 = (
    601, 449, 424, 568, 569, 447, 425, 621, 616, 573, 584, 635, 480, 437,
    724, 711, 717, 576, 724, 585, 458, 752, 753, 709, 584, 748, 628, 483,
    739, 747, 694, 601, 758, 653, 487, 720, 750, 660, 588, 719, 631, 492,
    584, 647, 548, 585, 649, 532, 492, 598, 653, 524, 567, 570, 506, 475,
    640, 725, 688, 567, 634, 520, 488, 718, 769, 739, 576, 718, 527, 497,
    698, 736, 785, 581, 733, 540, 537, 683, 691, 785, 588, 733, 531, 564,
    581, 554, 765, 580, 626, 510, 533, 495, 470, 713, 571, 573, 476, 526,
    441, 431, 686, 563, 496, 447, 518
);
my @data3 = qw/-9  2  3  44  -10  6  7/;

my %DataTest = (
    'First sample test' => {
        'Data' => \@data1,
        'Test' => {
            '0' => '1',
            '1' => '3.25',
            '2' => '5.5',
            '3' => '7.75',
            '4' => '10',
        },
    },
    'Second sample test' => {
        'Data' => \@data2,
        'Test' => {
            '0' => '424',
            '1' => '526',
            '2' => '584',
            '3' => '698',
            '4' => '785',
        },
    },
    'Third sample test' => {
        'Data' => \@data3,
        'Test' => {
            '0' => '-10',
            '1' => '-3.5',
            '2' => '3',
            '3' => '6.5',
            '4' => '44',
        },
    }
);

# Test Quantile,
foreach my $MessageTest ( sort keys %DataTest )
{
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data( @{ $DataTest{$MessageTest}->{Data} } );

    # TEST*3*5
    for ( 0 .. 4 )
    {
        is(
            $stat->quantile($_),
            $DataTest{$MessageTest}->{Test}{$_},
            $MessageTest . ", Q$_"
        );
    }
}
