########Search open doors in a target########
use P50Tools;

my $p = P50Tools::RandonDoors->new();
$p->target('my.target.lan');
$p->ini(78); 
$p->end(82);
# To use defaults doors don't declare 'ini' and 'end' methods, will be search all doors
# $p->timeout(20); this method can be used optionally
$p->scan;
