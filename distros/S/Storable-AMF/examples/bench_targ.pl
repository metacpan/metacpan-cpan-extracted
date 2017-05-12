#!/usr/bin/perl -I/home/sites/combats.ru/slib
#===============================================================================
#
#         FILE:  bench_targ.pl
#
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#       AUTHOR:  Grishayev Anatoliy (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/05/2011 12:59:56 PM
#     REVISION:  ---
#===============================================================================

use strict;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze parse_serializator_option);
use Storable::AMF qw(freeze3);
use Benchmark qw(cmpthese);


my $obj = [ 1 .. 10, { a=> "Hello", b=> "Word", c=> "Mother" }, "Litrebol" ];
my $opt_targ = parse_serializator_option( "+targ" );
my $opt_def  = parse_serializator_option( "-targ" );


printf "%d<=>%d\n", $opt_targ, $opt_def, "\n";

cmpthese( -1,{
        def__0  => sub { my $s = freeze( $obj, $opt_def )},
        targ_0  => sub { my $s = freeze( $obj, $opt_targ )},
        def__3  => sub { my $s = freeze3( $obj, $opt_def )},
        targ_3  => sub { my $s = freeze3( $obj, $opt_targ )},
        noarg_0 => sub { my $s = freeze( $obj )},
        }
        );








