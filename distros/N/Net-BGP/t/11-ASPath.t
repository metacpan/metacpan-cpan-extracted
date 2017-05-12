#!/usr/bin/perl -wT

use strict;

use Test::More tests => 163;

# Use
use_ok('Net::BGP::ASPath');

# Empty
my $empty = new Net::BGP::ASPath();
ok(ref $empty eq 'Net::BGP::ASPath','Simple construction');

# Length, Original, Prepend normal, Prepred confed, Cleanup, Striped
my $aseseq     = [0,'','42','(42)','','']; # Actully empty AS path
my $aseset     = [0,'{}','42','(42)','','{}'];
my $aseconfseq = [0,'()','42','(42)','',''];
my $aseconfset = [0,'({})','42','(42)','',''];
my $asseq      = [3,'1 2 3','42 1 2 3','(42) 1 2 3','1 2 3','1 2 3'];
my $asset      = [1,'{1,2,3,4}','42 {1,2,3,4}','(42) {1,2,3,4}',undef,undef];
my $asconfseq  = [0,'(1 2 3 4 5)','42','(42 1 2 3 4 5)',undef,''];
my $asconfset  = [0,'({1,2,3,4,5,6})','42','(42) ({1,2,3,4,5,6})',undef,''];
my $combi1     = [4,'1 2 3 {4,5,6}','42 1 2 3 {4,5,6}','(42) 1 2 3 {4,5,6}',undef,undef];
my $combi2     = [3,'(1 2 3) 4 5 6','42 4 5 6','(42 1 2 3) 4 5 6',undef,'4 5 6'];
my $combi3     = [4,'(1 2 3) 4 5 6 {7,8,9}','42 4 5 6 {7,8,9}',
                 '(42 1 2 3) 4 5 6 {7,8,9}',undef,'4 5 6 {7,8,9}'];
my $combi4     = [3,'(1 2 3) ({4,5,6}) 7 8 {9}','42 7 8 {9}',
                 '(42 1 2 3) ({4,5,6}) 7 8 {9}',undef,'7 8 {9}'];
my $as4        = [2,
                  '{100000,200000,300000} 400000',
                  '42 {100000,200000,300000} 400000',
                  '(42) {100000,200000,300000} 400000',
                  undef,
                  '{100000,200000,300000} 400000',
                 ];
my $longpath   = [301,
                  ('1 'x300). '2',
                  '42 '.('1 'x300).'2',
                  '(42) '.('1 'x300).'2',
                  undef,
                  ('1 'x300).'2',
                 ];
my %l;
my %s;

my $ss=0;

foreach my $pair (
	$aseseq,$aseset,$aseconfseq,$aseconfset,
	$asseq,$asset,$asconfseq,$asconfset,
	$combi1,$combi2,$combi3,$combi4,$as4,
        $longpath
	)
 {
  my ($len,$str,$prep,$prep_conf,$cup,$strip) = @{$pair};
  $cup = $str unless defined $cup;
  $strip = $str unless defined $strip;
  my $a = new Net::BGP::ASPath($str);
  $l{$len} = $a;
  $s{$pair} = $a;
  ok($a->length == $len, "'$str' has length $len");
  ok("$a" eq $str,"'$a' equals '$str'");
  my $prepend = $a->clone;
  $prepend->prepend(42);
  ok("$prepend" eq $prep,"Prepend '$prepend' should be '$prep'");
  my $prepend_confed = $a->clone;
  $prepend_confed->prepend_confed(42);
  ok("$prepend_confed" eq $prep_conf,"Prepend confederation '$prepend_confed' should be '$prep_conf'");

  my $prependadd = $a->clone;
  $prependadd += 42;
  ok("$prependadd" eq $prep,"Prepend overloaded '$prepend' should be '$prep'");

  my $prepend_confedadd = $a->clone;
  $prepend_confedadd += "(42)";
  ok("$prepend_confedadd" eq $prep_conf,"Prepend confederation overloaded '$prepend_confed' should be '$prep_conf'");

  my $cleanup = $a->clone;
  $cleanup->cleanup;
  ok("$cleanup" eq $cup,"Cleanup '$cleanup' should be '$cup'");
  my $strip1 = $a->clone;
  $strip1->strip;
  ok("$strip1" eq $strip,"Strip '$strip1' should be '$strip'");
  my $striped = $a->striped;
  ok("$striped" eq $strip,"Striped '$striped' should be '$strip'");

  my $trans = _new_from_msg Net::BGP::ASPath($a->_encode);
  ok($a eq $trans,"'$trans' should be decode(encode('$a'))");
 };

ok($l{3} > $l{0},'length 3 greater then length 0');
ok($l{3} < $l{4},'length 3 less then length 4');
ok($l{3} == $l{3},'length 3 equals length 3');

my $sorted = join(',',map { $_->length; } (sort { $a <=> $b } values(%l)));
ok($sorted eq '0,1,2,3,4,301',"sort with <=> ($sorted)");

ok($s{$combi4}[0] == 1,'old fasioned array access 1');

my $arracc = join(' ',@{$s{$combi4}});
ok($arracc eq '1 2 3 4 5 6 7 8 9',"old fasion array access 2 ($arracc)");

ok($s{$combi4} eq $s{$combi4},'Equal');
ok($s{$combi4} ne $s{$combi3},'Not equal');

my $copy1 = new Net::BGP::ASPath($s{$combi4});
my $copy2 = $s{$combi4}->clone;

ok($s{$combi4} eq $copy1,'Constructor clone');
ok($s{$combi4} eq $copy2,'Clone method');

my $heada = '1 2 3 4';
my $headb = '(1 2 3) 4';
my $headc = '(1 2';
my $tailsa = [' {5,6,7,8,9,10,11,12}',
		'5 6 7','8 9','10 {11,12}'];
my $tailsb = [') ({3,6,9}) 4 5 {7,10,11}',
		'3) 4 5','3 6) 4 5 7','9) 4 5 {10,11}'];

my $correct;
my @paths;
foreach my $pair ([$heada,$tailsa],[$headb,$tailsa],[$headc,$tailsb])
 {
  my ($head,$tails) = @{$pair};
  my ($tailok,@tails) = @{$tails};
  @paths = ();
  foreach my $tail (@tails)
   {
    push(@paths, new Net::BGP::ASPath($head . ' ' . $tail));
   };
  my $aggregated = Net::BGP::ASPath->aggregate(@paths);
  $correct = $head . $tailok;
  ok("$aggregated" eq $correct,"Aggregation (class) '$aggregated' should be '$correct'");
 };

my $aggregated = shift(@paths)->aggregate(@paths);
ok("$aggregated" eq $correct,"Aggregation (object) '$aggregated' should be '$correct'");

my $n = 1;
my $prepend0 = $s{$asseq}->clone;
$prepend0->prepend('(4 5 6)');
ok("$prepend0" eq '(4 5 6) 1 2 3','Prepend ' . $n++);
foreach my $arg (['4 5 6 '],[[4,5,6]])
 {
  my $prepend1 = $s{$asseq}->clone;
  $prepend1->prepend(@{$arg});
  ok("$prepend1" eq '4 5 6 1 2 3','Prepend ' . $n++);
  my $prepend2 = $s{$asseq}->clone;
  $prepend2->prepend_confed(@{$arg});
  ok("$prepend2" eq '(4 5 6) 1 2 3','Prepend ' . $n++);
 };

# Test to make sure creating an ASPath by array reference works
 my $arraypath = Net::BGP::ASPath->new([65001,65002]); # Straight from docs
 ok (
     $arraypath->length == 2,
     'Constructing AS Path from Array proper length'
 );
 ok (
     $arraypath->as_string eq '65001 65002',
     'Constructing AS Path from Array proper content'
 );

__END__
