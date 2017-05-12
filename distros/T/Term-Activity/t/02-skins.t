use Term::Activity;
use Test::Simple tests => 4;
use strict;

# Wave

my $t = new Term::Activity;

for ( 0 .. 999 ) {
  $t->tick;
}

$t = undef;	

ok(1);

# Wave (my own chars)

$t = new Term::Activity ({ skin => 'wave', chars => [['|','='],['|','-']] });

for ( 0 .. 999 ) {
  $t->tick;
}

$t = undef;	
	
ok(1);

# Flat 

$t = new Term::Activity ({ skin => 'flat' });

for ( 0 .. 999 ) {
  $t->tick;
}

$t = undef;	
	
ok(1);

# Flat (my own chars)

$t = new Term::Activity ({ skin => 'flat', chars => [qw/X Y Z/] });

for ( 0 .. 999 ) {
  $t->tick;
}

$t = undef;	
	
ok(1);
