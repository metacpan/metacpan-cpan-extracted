
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all ignore_env);

plan tests => 35;

my  $v = new Statistics::Basic::Vector([1 .. 3]);
ok( $v->query_size, 3 );

$v->set_size( 4 ); # fix_size() fills in with 0s
ok( $v->query_size, 4 ); 
ok( $v->query_filled );

{ local $Statistics::Basic::NOFILL = 1;
    $v->set_size( 6 ); # waits for you to insert()
    ok( $v->query_size, 4 );
    ok( !$v->query_filled );

    $v->insert( 9 ); # waits for you to insert()
    ok( $v->query_size, 5 );
    ok( !$v->query_filled );
}

$v->insert(5); # auto fills
ok( $v->query_size, 6 );

$v->insert( [10..13], 14..15 );
ok( $v->query_size, 6 );

my $j = new Statistics::Basic::Vector;
ok( $j->query_size, 0 );

$j->set_vector([7,9,21]);
ok( $j->query_size, 3 );
ok( $j, "[7, 9, 21]");

$j->set_size(0);
ok( $j, "[]" );
ok( $j->query_size, 0 );

my $k = $j->copy;
   $k->ginsert(7);
   $j->ginsert(9);

ok( $j->query_size, 1 );
ok( $k->query_size, 1 );

$j->ginsert(7);

ok( $j->query_size, 2 );
ok( $k->query_size, 1 );

ok( $j, "[9, 7]" );
ok( $k, "[7]" );

$k->set_vector($j);
$j->ginsert(33);

ok( $j, "[9, 7, 33]" );
ok( $k, "[9, 7]" );

my $w = $j->copy;
ok( $w->query_size, $j->query_size );
ok( $w, $j );

$w->ginsert(6);
ok( $w->query_size-1, $j->query_size );
my $str = "$w";
ok($str =~ s/, 6//, 1);
ok( $str, $j );

my $S  = vector([1,2,3]);
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

$S->set_vector($w);

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
