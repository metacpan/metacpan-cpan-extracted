########Search Remote File Inclusion fail########
use P50Tools;

my $p = P50Tools::RFIScan->new();
$p->target('my.target.lan');
# $p->string_list('MyStringList.txt'); this method can be used optionally if you had other list of strings
# $p->php_shell('My.SiteWith.file/php_name.txt'); this method can be used optionally if you had other file with php shell code
# $p->response('response'); this method needs to be configured according to the php shell used
$p->scan;
