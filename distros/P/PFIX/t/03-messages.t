#!/usr/bin/perl -I../lib

use Test::More tests => 12;
use Data::Dumper;
diag("Testing PFIX Message methods.");

use_ok('PFIX::Message') || print "Bail out!\n";

#ok( PFIX::Dictionary::load('FIX44'), "PFIX::Dictionary::load('FIX44')" );

my $m = PFIX::Message->new(undef,version=>'FIX44');

my ( $o,$s, $g, $r);

$s='8=FIX.4.4|9=81|35=D|78=2|79=Acct1|80=500|79=acct2|80=1500|55=EUR/CHF|64=20100817|15=EUR|38=2000|10=240|';
$g='8=FIX.4.4|9=81|35=D|78=2|79=Acct1|80=500|79=acct2|80=1500|64=20100817|55=EUR/CHF|38=2000|15=EUR|10=016|';
$s=~s/\|/\001/g;
$m->fromString($s);
$m->resetString();
$r=$m->toPrint();
ok( $r eq $g , 'Parsing of a multi alloc successful');



$s="8=FIX.4.4|9=81|35=D|55=EUR/CHF|64=20100817|15=EUR|38=2000|78=2|79=Acct1|80=500|79=Acct2|80=1500|10=240|";
$g='8=FIX.4.4|9=81|35=D|78=2|79=Acct1|80=500|79=Acct2|80=1500|64=20100817|55=EUR/CHF|38=2000|15=EUR|10=240|';
$s =~ s/\|/\001/g;
$m->fromString($s);
$m->resetString();
ok ( $m->toPrint() eq $g , "Parsing of a multi alloc successful (but alloc is just at the end of the message)." );

$s="8=FIX.4.4|9=245|35=D|52=20100831-11:34:18|34=2|56=TARGET|49=SENDER|11=BB:102145538|63=6|21=3|167=CS|78=2|79=Acct1|80=500|79=Acct2|80=1500|460=4|107=EUR/CHF|461=MRCXXX|100=OEUR|55=EUR/CHF|39=0|64=20100817|40=1|15=EUR|38=2000|59=1|60=20100813-14:07:27|150=0|54=1|10=105|";
#$g='8=FIX.4.4|9=259|35=D|34=2|49=SENDER|52=20100831-11:34:18|56=TARGET|11=BB:102145538|15=EUR|21=3|38=2000|39=0|40=1|54=1|55=EUR/CHF|59=1|60=20100813-14:07:27|63=6|64=20100817|78=2|79=Acct1|80=500|79=Acct2|80=1500|100=OEUR|107=EUR/CHF|150=0|167=CS|460=4|461=MRCXXX|10=116|';
$g='8=FIX.4.4|9=245|35=D|49=SENDER|56=TARGET|34=2|52=20100831-11:34:18|11=BB:102145538|78=2|79=Acct1|80=500|79=Acct2|80=1500|63=6|64=20100817|21=3|100=OEUR|55=EUR/CHF|460=4|461=MRCXXX|167=CS|107=EUR/CHF|54=1|60=20100813-14:07:27|38=2000|40=1|15=EUR|59=1|39=0|150=0|10=052|';
$s =~ s/\|/\001/g;
$m->fromString($s);
$m->resetString();
ok ( $m->toPrint() eq $g , "Parsing of a complete new simple order." );

$s='8=FIX.4.4|9=253|35=D|52=20100831-11:34:18|34=2|56=TARGET|49=SENDER|11=BB:102145538|63=6|21=3|167=CS|78=2|79=Acct1|80=500|79=Acct2|80=1500|460=4|107=EUR/CHF|461=MRCXXX|100=OEUR|55=EUR/CHF|39=0|64=20100817|40=1|15=EUR|38=2000|59=1|60=20100813-14:07:27|150=0|54=1|20000=3|10=105|';
$g='8=FIX.4.4|9=253|35=D|49=SENDER|56=TARGET|34=2|52=20100831-11:34:18|11=BB:102145538|78=2|79=Acct1|80=500|79=Acct2|80=1500|63=6|64=20100817|21=3|100=OEUR|55=EUR/CHF|460=4|461=MRCXXX|167=CS|107=EUR/CHF|54=1|60=20100813-14:07:27|38=2000|40=1|15=EUR|59=1|39=0|150=0|20000=3|10=150|';
$s =~ s/\|/\001/g;
$m->fromString($s);
$m->resetString();
$r=$m->toPrint();
ok ( $r eq $g , "Parsing of an order with an unknown field in it." );

$s="8=FIX.4.4|9=245|35=D|52=20100831-11:34:18|34=2|56=TARGET|49=SENDER|11=BB:102145538|63=6|21=3|167=CS|78=2|79=Acct1|80=500|79=Acct2|80=1500|460=4|107=EUR/CHF|461=MRCXXX|100=OEUR|55=EUR/CHF|39=0|64=20100817|40=1|15=EUR|38=2000|59=1|60=20100813-14:07:27|150=0|54=1|10=105|";
$g='8=FIX.4.4|9=245|35=D|49=SENDER|56=TARGET|34=2|52=20100831-11:34:18|11=BB:102145538|78=2|79=Acct1|80=500|79=Acct2|80=1500|63=6|64=20100817|21=3|100=OEUR|55=USD/JPY|460=4|461=MRCXXX|167=CS|107=EUR/CHF|54=1|60=20100813-14:07:27|38=2000|40=1|15=EUR|59=1|39=0|150=0|10=086|';
$s =~ s/\|/\001/g;
$m->fromString($s);
$m->setField(55,'USD/JPY');
ok ( $m->toPrint() eq $g , "Testing setField(55,'USD/JPY') on a new simple order." );

$s='8=FIX.4.4|9=245|35=D|52=20100831-11:34:18|34=2|56=TARGET|49=SENDER|11=BB:102145538|63=6|21=3|167=CS|78=2|79=Acct1|80=500|79=Acct2|80=1500|460=4|107=EUR/CHF|461=MRCXXX|100=OEUR|55=EUR/CHF|39=0|64=20100817|40=1|15=EUR|38=2000|59=1|60=20100813-14:07:27|150=0|54=1|10=105|';
$g='8=FIX.4.4|9=234|35=D|49=SENDER|56=TARGET|34=2|52=20100831-11:34:18|11=BB:102145538|78=2|79=Acct1|80=500|79=Acct2|80=1500|63=6|64=20100817|21=3|100=OEUR|460=4|461=MRCXXX|167=CS|107=EUR/CHF|54=1|60=20100813-14:07:27|38=2000|40=1|15=EUR|59=1|39=0|150=0|10=158|';
$s =~ s/\|/\001/g;
$m->fromString($s);
$m->delField(55);
#print $m->toPrint() . "\n";
ok ( $m->toPrint() eq $g , "Testing delField(55) on a new simple order." );


$s="8=FIX.4.4|9=253|35=D|52=20100831-11:34:18|34=2|56=TARGET|49=SENDER|11=BB:102145538|63=6|21=3|167=CS|78=2|79=Acct1|80=500|79=Acct2|80=1500|460=4|107=EUR/CHF|461=MRCXXX|100=OEUR|55=EUR/CHF|39=0|64=20100817|40=1|15=EUR|38=2000|59=1|60=20100813-14:07:27|150=0|54=1|20000=3|10=105|";
$g='8=FIX.4.4|9=245|35=D|49=SENDER|56=TARGET|34=2|52=20100831-11:34:18|11=BB:102145538|78=2|79=Acct1|80=500|79=Acct2|80=1500|63=6|64=20100817|21=3|100=OEUR|55=EUR/CHF|460=4|461=MRCXXX|167=CS|107=EUR/CHF|54=1|60=20100813-14:07:27|38=2000|40=1|15=EUR|59=1|39=0|150=0|10=052|';
$s =~ s/\|/\001/g;
$m->fromString($s);
$m->delField(20000);
$r=$m->toPrint();
ok ( $r eq $g , "Testing delField(20000) on an order with an unknown field in it." );


$s="8=FIX.4.4|9=253|35=D|52=20100831-11:34:18|34=2|56=TARGET|49=SENDER|11=BB:102145538|63=6|21=3|167=CS|78=2|79=Acct1|80=500|79=Acct2|80=1500|460=4|107=EUR/CHF|461=MRCXXX|100=OEUR|55=EUR/CHF|39=0|64=20100817|40=1|15=EUR|38=2000|59=1|60=20100813-14:07:27|150=0|54=1|20000=3|10=105|";
$g='8=FIX.4.4|9=263|35=D|49=SENDER|56=TARGET|34=2|52=20100831-11:34:18|11=BB:102145538|78=2|79=Acct1|80=500|79=Acct2|80=1500|63=6|64=20100817|21=3|100=OEUR|55=EUR/CHF|460=4|461=MRCXXX|167=CS|107=EUR/CHF|54=1|60=20100813-14:07:27|38=2000|40=1|15=EUR|59=1|39=0|150=0|20000=3|20010=new|10=018|';
$s =~ s/\|/\001/g;
$m->fromString($s);
$m->setField(20010,'new');
$r=$m->toPrint();
ok ( $r eq $g , "Testing setField(20010,new) on an order with just unknown field 20000 in it." );

$s="8=FIX.4.4|9=81|35=D|78=2|79=Acct1|80=500|79=Acct2|80=1500|55=EUR/CHF|64=20100817|15=EUR|38=2000|10=240|";
$s =~ s/\|/\001/g;
$m->fromString($s);

ok ( $m->getField('NoAllocs') == 2 , "No allocs is indeed correct at 2" );
ok ( $m->getFieldInGroup('NoAllocs',0,'AllocQty') == 500 ,  "1st alloc qty is 500!" );
ok ( $m->getFieldInGroup('NoAllocs',1,'AllocQty') == 1500 , "2nd alloc qty is 1500!" );


print "End of tests\n";


