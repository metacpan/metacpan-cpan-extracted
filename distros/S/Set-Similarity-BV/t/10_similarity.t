#!perl
use strict;
use warnings;

use lib qw(../lib/ );

use Test::More;
use Test::Exception;

my $class = 'Set::Similarity::BV';

our $width = int 0.999+log(~0)/log(2);

use_ok($class);

my $object = new_ok($class);



dies_ok { $object->from_integers() } ;

ok($object->new());
ok($object->new(1,2));
ok($object->new({}));
ok($object->new({a => 1}));
ok($class->new());

is($object->min(0,0),0,'0,0 -> 0');
is($object->min(0,1),0,'0,1 -> 0');
is($object->min(1,0),0,'1,0 -> 0');

is($object->_integers("0")->[0],0,'_integers("0")');
is($object->_integers("1")->[0],1,'_integers("1")');
is($object->_integers("f")->[0],15,'_integers("f")');
is($object->_integers("ab")->[0],171,'_integers("ab")');
is($object->_integers("1ff")->[0],256+255,'_integers("1ff")');
is(scalar @{$object->_integers("f"x16)},int(16/($width/4)),'_integers("f"x16)');
is(scalar @{$object->_integers("f"x17)},int(17/($width/4))+1,'_integers("f"x17)');

is($object->bits([0]),0,'bits([0])');
is($object->bits([1]),1,'bits([1])');
is($object->bits([1,1]),2,'bits([1,1])');
is($object->bits($object->_integers("ff"x4)),32,'bits "ff"x4');
is($object->bits($object->_integers("ff"x8)),64,'bits "ff"x8');
is($object->bits($object->_integers("ff"x9)),72,'bits "ff"x9');

is($object->intersection([0],[0]),0,'intersection([0],[0])');
is($object->intersection([1],[1]),1,'intersection([1],[1])');
is($object->intersection([15],[1]),1,'intersection([15],[1])');
is($object->intersection([15],[15]),4,'intersection([15],[15])');
is($object->intersection($object->_integers("ab"),$object->_integers("ab")),5,'intersection("ab","ab")');
is($object->intersection($object->_integers("ff"x8),$object->_integers("ff"x9)),64,'intersection("ff"x8,"ff"x9)');


done_testing;
