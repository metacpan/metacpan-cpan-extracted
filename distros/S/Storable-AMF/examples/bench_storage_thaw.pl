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
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze parse_serializator_option thaw);
use Storable::AMF qw(freeze3 thaw3 dclone freeze0 thaw0);
use Benchmark qw(cmpthese);
use Data::Dumper;


my $obj = [ 1 .. 10, { a=> "Hello", b=> "Word", c=> "Mother" }, "Litrebol" ];
my $bobj = [ map dclone( $obj ), 1..10 ];
my $sobj = { a =>1, b=>1, c=>1 } ;
my $opt_targ = parse_serializator_option( "+targ" );
my $opt_def  = parse_serializator_option( "-targ" );
my $option   = parse_serializator_option( "+prefer_number" );

my $storage = Storable::AMF0::amf_tmp_storage( $option );
my $ff_obj    = freeze0( $obj ); 
my $ff_sobj   = freeze0( $sobj ); 
my $ff_bobj   = freeze0( $bobj ); 

my $ff_obj3    = freeze3( $obj ); 
my $ff_sobj3   = freeze3( $sobj ); 
my $ff_bobj3   = freeze3( $bobj ); 
print "AMF0 benchmark\n";
cmpthese( -1,{
        bobj_1   =>  sub { 
            my $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
                
        },
        bobj_st   => sub { 
            my $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
        },
});
cmpthese( -1,{
        obj_1   =>  sub { 
            my $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
                
        },
        obj_st   => sub { 
            my $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
        },
});


cmpthese( -1,{
        sobj_1   =>  sub { 
            my $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
        },
        
        sobj_st   => sub { 
            my $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
        },
        }
        );

print "AMF3 benchmark\n";
cmpthese( -1,{
        bobj3_1   =>  sub { 
            my $s = thaw3( $ff_bobj3, $option);
            $s = thaw3( $ff_bobj3, $option);
            $s = thaw3( $ff_bobj3, $option);
            $s = thaw3( $ff_bobj3, $option);
            $s = thaw3( $ff_bobj3, $option);
            $s = thaw3( $ff_bobj3, $option);
            $s = thaw3( $ff_bobj3, $option);
                
        },
        bobj3_st   => sub { 
            my $s = thaw3( $ff_bobj3, $storage) ;
            $s = thaw3( $ff_bobj3, $storage) ;
            $s = thaw3( $ff_bobj3, $storage) ;
            $s = thaw3( $ff_bobj3, $storage) ;
            $s = thaw3( $ff_bobj3, $storage) ;
            $s = thaw3( $ff_bobj3, $storage) ;
            $s = thaw3( $ff_bobj3, $storage) ;
        },
});
cmpthese( -1,{
        obj3_1   =>  sub { 
            my $s = thaw3( $ff_obj3, $option);
            $s = thaw3( $ff_obj3, $option);
            $s = thaw3( $ff_obj3, $option);
            $s = thaw3( $ff_obj3, $option);
            $s = thaw3( $ff_obj3, $option);
            $s = thaw3( $ff_obj3, $option);
            $s = thaw3( $ff_obj3, $option);
                
        },
        obj3_st   => sub { 
            my $s = thaw3( $ff_obj3, $storage) ;
            $s = thaw3( $ff_obj3, $storage) ;
            $s = thaw3( $ff_obj3, $storage) ;
            $s = thaw3( $ff_obj3, $storage) ;
            $s = thaw3( $ff_obj3, $storage) ;
            $s = thaw3( $ff_obj3, $storage) ;
            $s = thaw3( $ff_obj3, $storage) ;
        },
});


cmpthese( -1,{
        sobj3_1   =>  sub { 
            my $s = thaw3( $ff_sobj3, $option) ;
            $s = thaw3( $ff_sobj3, $option) ;
            $s = thaw3( $ff_sobj3, $option) ;
            $s = thaw3( $ff_sobj3, $option) ;
            $s = thaw3( $ff_sobj3, $option) ;
            $s = thaw3( $ff_sobj3, $option) ;
            $s = thaw3( $ff_sobj3, $option) ;
        },
        
        sobj3_st   => sub { 
            my $s = thaw3( $ff_sobj3, $storage) ;
            $s = thaw3( $ff_sobj3, $storage) ;
            $s = thaw3( $ff_sobj3, $storage) ;
            $s = thaw3( $ff_sobj3, $storage) ;
            $s = thaw3( $ff_sobj3, $storage) ;
            $s = thaw3( $ff_sobj3, $storage) ;
            $s = thaw3( $ff_sobj3, $storage) ;
        },
        }
        );







