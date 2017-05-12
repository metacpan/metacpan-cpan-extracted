########Stress test########
use P50Tools;

my $p = P50Tools::Packs->new();
$p->target('my.target.lan');
$p->door(80);
$p->send;
