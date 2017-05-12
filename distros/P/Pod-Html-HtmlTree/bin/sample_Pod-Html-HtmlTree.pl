#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Data::Dumper;
use Pod::Html::HtmlTree;

my $p =  Pod::Html::HtmlTree->new;
 $p->indir ( '/usr/lib/perl5/5.8.5'     );
 $p->outdir( '/tmp/pod' );
 $p->args({
    css =>'http://localhost/pod.css',
    quiet=> 0 ,
 });
 $p->mask_dir ( 0777 ); # default is 0775
 $p->mask_html( 0777 ); # default is 0664
 $p->pod_exts ( [ 'pm' ] );

 my $outfiles = $p->create;
 print Dumper $outfiles;
 exit( 0 );
