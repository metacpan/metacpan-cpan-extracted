$|=1;

print "1..7\n";

use No::Sort;

@ord = ("fulg", "fisk", "�", "�", "A", "�", "m�nerel�", "id�",
"ide", "�", "�", "�", "�l", "�lesund", "m�se", "�les�nd", "�", "�",
"o", "grus", "idf", "�", "�", "maskere", "4kl�ver");

@a = no_sort @ord;

# while testing, we want debug output on STDOUT
open(STDERR, ">&STDOUT");

$No::Sort::DEBUG=1;
@b = no_sort @ord;

print "not " unless "@a" eq "@b";
print "ok 1\n";

print "----\n";
print join("/", @a), "\n";

print "not " unless join("/",@a) eq "4kl�ver/A/fisk/fulg/grus/ide/id�/idf/maskere/m�nerel�/m�se/o/�/�/�/�/�/�/�/�/�/�/�l/�lesund/�les�nd";
print "ok 2\n";


sub my_xfrm {
    my $word = shift;
    $word =~ s/A[aA]/�/g;
    $word =~ s/aa/�/g;
    No::Sort::no_xfrm($word);
}

@names = ("Aas", "Asheim", "Andersen", "Haakon", "Hansen", "�sterud",
"�sheim", "Aanonsen", "�m�s");

@a = no_sort \&my_xfrm, @names;

print "not " unless join("/",@a) eq "Andersen/Asheim/Hansen/Haakon/�sterud/�m�s/Aanonsen/Aas/�sheim";
print "ok 3\n";

#-------
print "Case convertion tests...\n";
use No::Sort qw(latin1_uc latin1_lc latin1_ucfirst latin1_lcfirst);

print "not " unless latin1_uc(q( !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~������������������������������������������������������������������������������������������������)) eq
   q( !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~������������������������������������������������������������������������������������������������);
print "ok 4\n";

print "not " unless latin1_lc(q( !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~������������������������������������������������������������������������������������������������)) eq
   q( !"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\]^_`abcdefghijklmnopqrstuvwxyz{|}~������������������������������������������������������������������������������������������������);
print "ok 5\n";

print "not " unless latin1_ucfirst("�se") eq "�se";
print "ok 6\n";

print "not " unless latin1_lcfirst("�SE") eq "�SE";
print "ok 7\n";

