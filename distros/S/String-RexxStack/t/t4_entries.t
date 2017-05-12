use String::TieStack   max_entries=>3 ;


use Test::More ;

BEGIN { plan tests => 12 }

my $t = tie my @arr , 'String::TieStack';



is  $t->max_entries , 3;
is  $t->max_KBytes  , 0;

push @arr , 'one';
is  @arr     => 1;
push @arr , 'two';
is  @arr     => 2;
push @arr , 'three';
is  @arr     => 3;
push @arr , 'four';
is  @arr     => 3;

@arr = ();
push @arr , 'one', 'two', 'three' ;
is  @arr     => 3;
push @arr , 'four';
is  @arr     => 3;

@arr = ();
push @arr , 'one', 'two', 'three', 'four' ;
is  @arr => 0;

@arr = ();
push @arr , 'one';
push @arr , 'one', 'two', 'three', 'four' ;
is  @arr     => 1;

$t->max_entries(2);
push @arr, 'two';
is @arr     => 2;
push @arr, 'three';
is @arr     => 2;
