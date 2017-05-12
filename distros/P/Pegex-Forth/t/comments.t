use lib -e 't' ? 't' : 'test';
use TestPegexForth;

my $forth;

$forth = "
3 ( Put 3 on stack )
4 ( Put 4 on stack)
+ ( Add top 2 stack elems and put result on stack )
";
test_top $forth, 7, 'Comments work';
