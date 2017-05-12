########Search SQL injection fail########
use P50Tools;

my $p = P50Tools::SQLiScan->new();
$p->target_list('my_list_with_target.txt');
$p->output('my_results.txt');
$p->scan;
