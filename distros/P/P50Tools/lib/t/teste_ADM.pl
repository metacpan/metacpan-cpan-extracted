########Search Adm Page########
use P50Tools;

my $p = P50Tools::AdminFinder->new();
$p->target('my.target.lan');
# $p->string_list('MyStringList.txt'); this method can be used optionally if you had other list of strings
$p->scan;
