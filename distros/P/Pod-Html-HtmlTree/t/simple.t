#!/usr/bin/perl

unshift @INC , qw ( blib/arch blib/lib );
use FindBin;
use lib "$FindBin::Bin/../lib";
use Pod::Html::HtmlTree;	
use Test::More qw/no_plan/;
use File::Path;
use File::stat;
use strict;

 
&test_my_pod;
&test_extention;
&test_args;

if( !is_ms_win() ){
    &test_mask();
}

sub is_ms_win {
 $^O =~ m/MSWin/ ? 1 : 0;
}

sub test_my_pod{
    my $p = Pod::Html::HtmlTree->new;
    $p->indir ( 'lib/' );
    $p->outdir( 't/test_pod/' );
    my $outfiles = $p->create;
    # ** check outfile count
    ok (  scalar @{$outfiles} );
    # ** check html file
    ok ( -f $outfiles->[0]{outfile} );
    rmtree ( 't/test_pod/' );
}
sub test_extention{
    # * no such extentions
    my $p = Pod::Html::HtmlTree->new( { indir=>'lib/' , outdir=>'t/test_pod/' } );
    my @exts = ( 'foo', 'garrr' );
    $p->pod_exts( \@exts );
    my $outfiles = $p->create();
    ok ( !scalar @{ $outfiles } );
    
    # * ok extention
    $p = Pod::Html::HtmlTree->new( { indir=>'lib/' , outdir=>'t/test_pod/' } );
    @exts = ( 'pm' );
    $p->pod_exts( \@exts );
    $outfiles = $p->create;
    ok ( scalar @{$outfiles} );
    rmtree ( 't/test_pod' );
}

sub test_args{
    # * No error at Pod::Html means succeess for this test.
     my $p = Pod::Html::HtmlTree->new( { indir=>'lib/' , outdir=>'t/test_pod/' } );
     $p->args({
	 backlink  => 'top',
	 #cachedir  => 't/test_pod',
	 css       => 'pod.css',
	 flush     => 0,
	 header    => 0,
	 #help      => 0,
	 htmldir   => 't/test_pod',
	 htmlroot  => 'http://localhost/pod',
	 noindex   => 0,
	 libpods   => 'perlfunc:perlmod',
	 podpath   => './../lib/Pod',
	 podroot   => 'lib',
	 quiet     => 0,
	 recurse   => 0,
	 title     => 'test title',
	 noverbose => 0, 
     });
     my $outfiles = $p->create;
     ok( scalar @{$outfiles} );
     rmtree ( 't/test_pod' );
}

sub test_mask{
    my $p = Pod::Html::HtmlTree->new();
    $p->indir ( 'lib/' );
    $p->outdir( 't/test_pod/' );
    $p->mask_dir( 0776 );
    $p->mask_html( 0777 );
    my $outfiles = $p->create();

    # ** Dir mask check.
    my $st = stat( 't/test_pod/' );
    ok ( sprintf( "%04o" , $st->mode & 0777) eq '0776' );
    $st = stat ( 't/test_pod/Pod/' );
    ok ( sprintf( "%04o" , $st->mode & 0777) eq '0776');

    # ** Html file mask check.
    $st = stat( $outfiles->[0]{outfile} );
    ok ( sprintf( "%04o" , $st->mode & 0777)  eq '0777' );

    rmtree ( 't/test_pod' );
}
1;
