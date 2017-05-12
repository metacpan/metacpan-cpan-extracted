#!perl -T

use strict;
use warnings;
use Test::Simple tests => (1+1+1+1+1+1+(19+1)+1+1+1);

use Regexp::Keywords qw(keywords_regexp);

my @data = <DATA>;

my $kw = Regexp::Keywords->new(ignore_case => 1, texted_ops => 1);
ok( defined($kw) && $kw->{texted_ops} == 1, 'new() works' );

$kw->set(texted_ops => 0);
ok( $kw->{texted_ops} == 0, 'set() works' );

ok( $kw->get('ignore_case') == 1, 'get() works' );

$kw->prepare("any_keyword");
ok( $kw->{ok}, 'prepare() works' );

$kw->reparse();
ok( $kw->{ok} == 0, 'reparse() works' );

$kw->rebuild();
ok( $kw->{ok}, 'rebuild() works' );

my @results = (1, 4, 1, 2, 1, 1, 1, 1, 4, 1, 1, 11, 1, 3, 2, 2, 5, 8, 2);
my @tests = (
  "OLIVE&(POPEYE|BLUTO)", # case in-sensitive
  "(tom&jerry)|(sylvester&tweety)",
  "moe&(shemp|curly|joe)&larry",
  "moe&!curly&larry", # curly not present
  "moe curly larry", # "&" is optional
  "moe ( shemp | curly | joe ) larry", # "&" is optional
  "jerry -tom", # standard way of "AND" and "AND NOT"...
  "(moe)((shemp)|(curly)|(joe))(larry)", # also this
  "tom&jerry|sylvester&tweety", # use re's default precedence
  "olive - (bluto | brutus)", # only words can be excluded
  "olive - bluto - brutus", # Ok, spaces ignored.
  "(curly|!larry)&!moe", # valid, but senseless OR
  "moe&!(!curly)&larry", # curly present? yes...
  "tom -!jerry", # not not
  "curly&!(moe&larry)",
  "curly&(!larry|!moe)",
  "jerry|sylvester&tweety", # use re's default precedence
  "..rry", # wildcard
  '"shemp curly"', # multi words
  );

my $i = 0;
my $n = 0;
for my $test (@tests) {
  $i++;
  $kw->prepare($test);
  my $res = $kw->grep(@data);
  my $t = ($res == $results[$i-1]);
  $n++ if $t;
  ok( $t , 'test() #'.$i.' pass' );
}
ok( $n == @tests , 'test() works' );

$kw->prepare('"tom jerry"');
ok( $kw->grep(@data) == 2, 'grep() works' );

my $index = 0;
my %hash = map { $index++ => $_ } @data;
$kw->prepare("brutus olive");
my @keyfound = $kw->grep_keys(%hash);
ok( @keyfound == 1 && $keyfound[0] == 7 , 'grep_keys() works' );

my $rexp = keywords_regexp("TOM and JERRY", 1, 0, 0, 1);
ok( grep(/$rexp/, @data) == 3 , 'keywords_regexp() works' );


__DATA__
tom,jerry
jerry,tom
jerry,tomas
sylvester,tweety
tweeter,sylvester
tom,sylvester
popeye,olive
olive,brutus
moe,larry
shemp,curly,joe
larry,moe
larry,curly,moe
larry,shemp,curly
tom,jerry,tweety
