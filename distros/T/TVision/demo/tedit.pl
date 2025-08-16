use strict;
use TVision('tnew');

my $tedit = tnew(TEditor=>[1,1,110,16]); #,  $sb1, $sb2, $ind, 1000);
my $sb1 = tnew(TScrollBar=>[51,11,100,11]);
my $sb2 = tnew(TScrollBar=>[1,1,20,1]);
my $ind = tnew(TIndicator=>[1,21,10,21]);
my $tedit2 = tnew(TEditor=>[1,21,110,36], $sb1, $sb2, $ind, 100000);

my $tapp = tnew('TVApp');
my $desktop = $tapp->deskTop;
my $r = $desktop->getExtent;
print "e=[@$r]\n";

$desktop->insert($tedit);
$desktop->insert($tedit2);

$tapp->onCommand(my $sub = sub {
    my ($cmd, $arg) = @_;
    print "command[@_]\n";
    if ($cmd == 123) {
    }
    elsif ($cmd == 125) {
    }
});

$tapp->run;

