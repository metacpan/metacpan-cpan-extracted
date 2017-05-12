#!/usr/local/bin/nperl -w

use Tcl::pTk;
use Data::Dumper;
use Test;


$mw = MainWindow->new;
$|=1;

# This will skip if Tix not present
my $retVal = $mw->interp->pkg_require('Tix');

unless( $retVal){
	plan tests => 1;
        skip("Tix Tcl package not available", 1);
        exit;
}

plan tests => 5;

my $hl = $mw->Scrolled('HList', -separator => '.', -width => 25,
#my $hl = $mw->HList( -separator => '.', -width => 25,
                        -drawbranch => 1,
                        -selectmode => 'extended', -columns => 2,
                        -indent => 10);

$hl->configure( -command => [ sub
                               {
                                my $hl = shift;
                                my $ent = shift;
                                my $data = $hl->info('data',$ent);
                                print "Data = ".Data::Dumper::Dumper($data)."\n";
                                foreach ($hl,$ent,$data)
                                 {
                                  print ref($_) ? "ref $_\n" : "string $_\n";
                                 }
                                print "\n";
                               }, $hl
                             ]
               );

$hl->pack(-expand => 1, -fill => 'both');

@list = qw(one two three);

my $i = 0;
foreach my $item (@list)
 {
  $hl->add($item, -itemtype => 'text', -text => $item, -data => {});
  my $subitem;
  foreach $subitem (@list)
   {
    $hl->addchild($item, -itemtype => 'text', -text => $subitem, -data => []);
   }
 }
 
 
 # Add an item that will be deleted
 $hl->add("deleteItem", -itemtype => 'text', -text => 'deleteItem');
 $hl->delete("entry", "deleteItem");
 
 # Check that we can store and retreive data
 $hl->add("dataItem", -itemtype => 'text', -text => 'dataItem', -data => [ 1..20 ]); 
 my $data = $hl->entrycget("dataItem",'-data');  #get the data ref for this entry
 ok(scalar(@$data), 20, "Hlist data storage");

ok(1, 1, "HList Widget Creation");
 
# Make a selection and check return value
my $ent = 'two';
$hl->anchorSet($ent);
$hl->selectionClear;
$hl->selectionSet($ent, 'three');

my @selections = $hl->info('selection');
#print "selection = '".join("', '", @selections)."'\n";
ok(join(", ", @selections), "two, two.0, two.1, two.2, three");

# Try the same call using infoSelection
@selections = $hl->infoSelection;
#print "selection = '".join("', '", @selections)."'\n";
ok(join(", ", @selections), "two, two.0, two.1, two.2, three");

$mw->update;
 # check that infoBbox method returns an array
 my @coords = $hl->infoBbox('one');
 ok(scalar(@coords), 4, "infoBbox method returns array");


$mw->after(1000,sub{$mw->destroy}) unless(@ARGV);

MainLoop;
