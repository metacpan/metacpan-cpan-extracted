# The smallest debug interface. Run as: % perl -d -Ilib debug.pl
use Pod::HtmlEasy ;
$podhtml = Pod::HtmlEasy->new();
$podhtml->pod2html('t.pod', 'output', 't.html');
