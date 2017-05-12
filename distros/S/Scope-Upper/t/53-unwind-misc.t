#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

use Scope::Upper qw<unwind UP SUB>;

{
 my @destroyed;

 {
  package Scope::Upper::TestTimelyDestruction;

  sub new {
   my ($class, $label) = @_;
   bless { label => $label }, $class;
  }

  sub label { $_[0]->{label} }

  sub DESTROY {
   push @destroyed, $_[0]->label;
  }
 }

 sub SU_TTD () { 'Scope::Upper::TestTimelyDestruction' }

 sub foo {
  my $r = SU_TTD->new('a');
  my @x = (SU_TTD->new('c'), SU_TTD->new('d'));
  unwind 123, $r, SU_TTD->new('b'), @x, sub { SU_TTD->new('e') }->() => UP SUB;
 }

 sub bar {
  foo();
  die 'not reached';
 }

 {
  my $desc = sub { "unwinding @_ across a sub" };
  my @res = bar();
  is $res[0],        123, $desc->('a constant literal');
  is $res[1]->label, 'a', $desc->('a lexical');
  is $res[2]->label, 'b', $desc->('a temporary object');
  is $res[3]->label, 'c', $desc->('the contents of a lexical array (1)');
  is $res[4]->label, 'd', $desc->('the contents of a lexical array (2)');
  is $res[5]->label, 'e', $desc->('a temporary object returned by a sub');
 }

 is_deeply \@destroyed, [ qw<e d c b a> ],
                                    'all these objects were properly destroyed';
}
