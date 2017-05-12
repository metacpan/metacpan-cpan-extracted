#!perl
use strict;
use warnings;

use lib qw(../lib/ );

use Test::More;

my $class = 'SimString::Wrapper';

use_ok($class);

my $object = new_ok($class);
ok($object->new());
ok($object->new(1,2));
ok($object->new({}));
ok($object->new({a => 1}));


my @result = $object->simstring('helmut','../sample/names.2',0.7);
print 'result: ',"\n",join("\n",@result),"\n";




#   -b, --build           build a database for strings read from STDIN
is($object->_options({b=>1}),' --build','b is build');
is($object->_options({build=>1}),' --build','build is build');

#   -d, --database=DB     specify a database file
is($object->_options({d=>'foo'}),' --database','d is database=foo');
is($object->_options({database=>'foo'}),' --database','database is database=foo');

#   -u, --unicode         use Unicode (wchar_t) for representing character
is($object->_options({u=>1}),' --unicode','u is unicode');
is($object->_options({unicode=>1}),' --unicode','unicode is unicode');

#   -n, --ngram=N         specify the unit of n-grams (DEFAULT=3)
is($object->_options({n=>2}),' --ngram=2','n=2 is ngram=2');
is($object->_options({u=>1,n=>2}),' --ngram=2 --unicode',' --ngram=2 --unicode');

#   -m, --mark            include marks for begins and ends of strings
is($object->_options({'m'=>1}),' --mark','m is mark');
is($object->_options({mark=>1}),' --mark','mark is mark');


#  -s, --similarity=SIM  specify a similarity measure (DEFAULT='cosine'):
#      exact                 exact match
#      dice                  dice coefficient
#      cosine                cosine coefficient
#      jaccard               jaccard coefficient
#      overlap               overlap coefficient

is($object->_options({'s'=>'exact'}),' --similarity=exact','s=exact is --similarity=exact');
is($object->_options({similarity=>'exact'}),' --similarity=exact',' --similarity=exact');

is($object->_options({similarity=>'dice'}),' --similarity=dice',' --similarity=dice');
is($object->_options({similarity=>'cosine'}),' --similarity=cosine',' --similarity=cosine');
is($object->_options({similarity=>'jaccard'}),' --similarity=jaccard',' --similarity=jaccard');
is($object->_options({similarity=>'overlap'}),' --similarity=overlap',' --similarity=overlap');


#  -t, --threshold=TH    specify the threshold (DEFAULT=0.7)
is($object->_options({t=>1}),' --threshold=1','t=1 is threshold=1');
is($object->_options({threshold=>1}),' --threshold=1','threshold=1 is threshold=1');
is($object->_options({t=>0.123}),' --threshold=0.123','threshold=0.123');

#  -e, --echo-back       echo back query strings to the output
is($object->_options({e=>1}),' --echo-back','e is echo-back');
is($object->_options({'echo-back'=>1}),' --echo-back','echo-back is echo-back');


#  -q, --quiet           suppress supplemental information from the output
is($object->_options({'q'=>1}),' --quiet','q is quiet');
is($object->_options({quiet=>1}),' --quiet','quiet is quiet');

#  -p, --benchmark       show benchmark result (retrieved strings are suppressed)
is($object->_options({'p'=>1}),' --benchmark','p is benchmark');
is($object->_options({benchmark=>1}),' --benchmark','benchmark is benchmark');

#  -v, --version         show this version information and exit
is($object->_options({'v'=>1}),' --version','v is version');
is($object->_options({version=>1}),' --version','version is version');

#  -h, --help            show this help message and exit
is($object->_options({'h'=>1}),' --help','h is help');
is($object->_options({help=>1}),' --help','help is help');


done_testing;
