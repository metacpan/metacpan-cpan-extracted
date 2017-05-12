BEGIN { push @INC, "./t" ; print "1..1\n" }

package main;

use Qt;
use My::SubCodec;
use Foo::SubCodec;

$tc1 = My::SubCodec();
$tc2 = Foo::SubCodec();

$tc1->bar();
$tc2->foo();

$tc2->deleteAllCodecs;

#  all imports OK

print "ok 1\n";
