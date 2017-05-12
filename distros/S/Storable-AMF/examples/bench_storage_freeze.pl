#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  bench_shared.pl
#
#        USAGE:  ./bench_shared.pl  
#
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06/03/2011 02:56:06 PM
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
$bobj = [ map [], 1..50 ];
my $sobj = { a =>1, b=>1, c=>1 } ;#$sobj = {} ;
my $opt_targ = parse_serializator_option( "+targ" );
my $opt_def  = parse_serializator_option( "-targ" );
my $option   = parse_serializator_option( "+prefer_number" );

my $shared  = $opt_targ;
my $storage;
#my $shared  = 0 ;# Storable::AMF0::amf_tmp_storage( $opt_targ );
my $ff_obj    = freeze0( $obj ); 
my $ff_sobj   = freeze0( $sobj ); 
my $ff_bobj   = freeze0( $bobj ); 

my $ff_obj3    = freeze3( $obj ); 
my $ff_sobj3   = freeze3( $sobj ); 
my $ff_bobj3   = freeze3( $bobj ); 
print "AMF0 benchmark\n";
$storage = Storable::AMF0::amf_tmp_storage( $opt_targ );
cmpthese( -1,{
        bobj_1   =>  sub { 
            my $s = freeze0( $bobj, $shared);
            $s = freeze0( $bobj, $shared);
            $s = freeze0( $bobj, $shared);
            $s = freeze0( $bobj, $shared);
            $s = freeze0( $bobj, $shared);
            $s = freeze0( $bobj, $shared);
            $s = freeze0( $bobj, $shared);
                
        },
        bobj_st   => sub { 
            my $s = freeze0( $bobj, $storage) ;
            $s = freeze0( $bobj, $storage) ;
            $s = freeze0( $bobj, $storage) ;
            $s = freeze0( $bobj, $storage) ;
            $s = freeze0( $bobj, $storage) ;
            $s = freeze0( $bobj, $storage) ;
            $s = freeze0( $bobj, $storage) ;
        },
});
$storage = Storable::AMF0::amf_tmp_storage( $opt_targ );
cmpthese( -1,{
        obj_1   =>  sub { 
            my $s = freeze0( $obj, $shared);
            $s = freeze0( $obj, $shared);
            $s = freeze0( $obj, $shared);
            $s = freeze0( $obj, $shared);
            $s = freeze0( $obj, $shared);
            $s = freeze0( $obj, $shared);
            $s = freeze0( $obj, $shared);
                
        },
        obj_st   => sub { 
            my $s = freeze0( $obj, $storage) ;
            $s = freeze0( $obj, $storage) ;
            $s = freeze0( $obj, $storage) ;
            $s = freeze0( $obj, $storage) ;
            $s = freeze0( $obj, $storage) ;
            $s = freeze0( $obj, $storage) ;
            $s = freeze0( $obj, $storage) ;
        },
});
$storage = Storable::AMF0::amf_tmp_storage( $opt_targ );
cmpthese( -1,{
        sobj_1   =>  sub { 
            my $s = freeze0( $sobj, $shared);
            $s = freeze0( $sobj, $shared);
            $s = freeze0( $sobj, $shared);
            $s = freeze0( $sobj, $shared);
            $s = freeze0( $sobj, $shared);
            $s = freeze0( $sobj, $shared);
            $s = freeze0( $sobj, $shared);
                
        },
        sobj_st   => sub { 
            my $s = freeze0( $sobj, $storage) ;
            $s = freeze0( $sobj, $storage) ;
            $s = freeze0( $sobj, $storage) ;
            $s = freeze0( $sobj, $storage) ;
            $s = freeze0( $sobj, $storage) ;
            $s = freeze0( $sobj, $storage) ;
            $s = freeze0( $sobj, $storage) ;
        },
});
print "AMF3 benchmark\n";
$storage = Storable::AMF0::amf_tmp_storage( $opt_targ );
cmpthese( -1,{
        bobj_1   =>  sub { 
            my $s = freeze3( $bobj, $shared);
            $s = freeze3( $bobj, $shared);
            $s = freeze3( $bobj, $shared);
            $s = freeze3( $bobj, $shared);
            $s = freeze3( $bobj, $shared);
            $s = freeze3( $bobj, $shared);
            $s = freeze3( $bobj, $shared);
                
        },
        bobj_st   => sub { 
            my $s = freeze3( $bobj, $storage) ;
            $s = freeze3( $bobj, $storage) ;
            $s = freeze3( $bobj, $storage) ;
            $s = freeze3( $bobj, $storage) ;
            $s = freeze3( $bobj, $storage) ;
            $s = freeze3( $bobj, $storage) ;
            $s = freeze3( $bobj, $storage) ;
        },
});
$storage = Storable::AMF0::amf_tmp_storage( $opt_targ );
cmpthese( -1,{
        obj_1   =>  sub { 
            my $s = freeze3( $obj, $shared);
            $s = freeze3( $obj, $shared);
            $s = freeze3( $obj, $shared);
            $s = freeze3( $obj, $shared);
            $s = freeze3( $obj, $shared);
            $s = freeze3( $obj, $shared);
            $s = freeze3( $obj, $shared);
                
        },
        obj_st   => sub { 
            my $s = freeze3( $obj, $storage) ;
            $s = freeze3( $obj, $storage) ;
            $s = freeze3( $obj, $storage) ;
            $s = freeze3( $obj, $storage) ;
            $s = freeze3( $obj, $storage) ;
            $s = freeze3( $obj, $storage) ;
            $s = freeze3( $obj, $storage) ;
        },
});
$storage = Storable::AMF0::amf_tmp_storage( $opt_targ );
cmpthese( -1,{
        sobj_1   =>  sub { 
            my $s = freeze3( $sobj, $shared);
            $s = freeze3( $sobj, $shared);
            $s = freeze3( $sobj, $shared);
            $s = freeze3( $sobj, $shared);
            $s = freeze3( $sobj, $shared);
            $s = freeze3( $sobj, $shared);
            $s = freeze3( $sobj, $shared);
                
        },
        sobj_st   => sub { 
            my $s = freeze3( $sobj, $storage) ;
            $s = freeze3( $sobj, $storage) ;
            $s = freeze3( $sobj, $storage) ;
            $s = freeze3( $sobj, $storage) ;
            $s = freeze3( $sobj, $storage) ;
            $s = freeze3( $sobj, $storage) ;
            $s = freeze3( $sobj, $storage) ;
        },
});
exit;
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










