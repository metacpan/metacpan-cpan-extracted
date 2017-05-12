
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all ignore_env);

plan tests => 12;

my $i = Statistics::Basic::Vector->new([ 1 .. 30 ]);
my $j = Statistics::Basic::ComputedVector->new( $i );
   $j->set_filter(sub { grep {$_<= 3} @_ });

ok( $j->query_size, 3 );
ok( $j, "[1, 2, 3]" );

$i->insert( 2 );

ok( $j->query_size, 3 );
ok( $j, "[2, 3, 2]" );

my $S  = computed(1,2,3); $S->set_filter(sub {map {$_+1} @_ });
my $Sr = $S->query;

{ my $Sr2 = $S->query;
  my @Sr2 = $S->query;
  ok( "@Sr2", "@$Sr2" );
  ok( "@Sr2", "@$Sr" );
}

$S->insert(7);
$S->ginsert(9);

{ my $Sr2 = $S->query;
  my @Sr2 = $S->query;
  ok( "@Sr2", "@$Sr2" );
  ok( "@Sr2", "@$Sr" );
}

$S->set_vector($i);

{ my $Sr2 = $S->query;
  my @Sr2 = $S->query;
  ok( "@Sr2", "@$Sr2" );
  ok( "@Sr2", "@$Sr" );
}

$S->set_vector([1,2,3,5]);

{ my $Sr2 = $S->query;
  my @Sr2 = $S->query;
  ok( "@Sr2", "@$Sr2" );
  ok( "@Sr2", "@$Sr" );
}
