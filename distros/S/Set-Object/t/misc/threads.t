use strict;
use Test::More;
BEGIN {
    eval 'use threads';
    if ($@) {
      plan skip_all => 'threads missing';
      exit(0);
    }
}
plan tests => 2;
use threads::shared;
use Set::Object;

my $sh = new Set::Object();
my $warnings;
share($sh);
#share($warnings);

$SIG{__WARN__} = sub { $warnings = 1; warn @_ };

my $t1 = threads->new(\&f1);
my $t2 = threads->new(\&f2);

main();

$t1->join;
$t2->join;
threads->yield;

is $warnings, undef;

while ($t1->is_running && $t2->is_running) {
  sleep(0.1);
}

TODO: {
  local $TODO = "Set::Object has still refcount issues with threads RT#22760";
  is (scalar($sh->members), 5);
}

sub f1{
  foreach my $i (1..100){
    my $d = $i % 10;
    $sh->remove($d) if $sh->element($d);
  }
}

sub f2{
  foreach my $i (1..100){
    my $d = $i % 10;
    $sh->remove($d);
    #$sh->element($d);
  }
}

sub main{
  my $d;
  foreach my $i (1..100){
    my $d = $i % 10;
    $sh->insert($d);
  }
}

