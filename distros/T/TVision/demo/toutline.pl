use strict;
use TVision;

my $node1 = tnew(TNode=>"нодв1");
my $node2 = tnew(TNode=>"нодв2");
my $node3 = tnew1(TNode=>"нодв2",$node1,$node2);
my $noder = tnew1(TNode=>"к",$node1,$node3);
my $sb1 = tnew(TScrollBar=>[51,11,100,11]);
my $sb2 = tnew(TScrollBar=>[1,1,20,1]);
my $to = tnew(TOutline=>[1,1,15,5],$sb1,$sb2,$noder);


my $tapp = tnew('TVApp');
my $desktop = $tapp->deskTop;
$desktop->insert($to);

$tapp->run;

