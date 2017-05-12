use Test::More ;
use String::TieStack  ;

BEGIN { plan tests => 7 }

my $t = tie my @arr , 'String::TieStack';
my $ret;

@arr = ();
$t->max_entries(3) ;
$t->max_KBytes(undef) ;
ok  $t->queue( qw( two one )  );
is  $t->qelem            => 2 ;
ok  $t->queue( 'zero');
is  $t->qelem            =>  3 ;
is  $t->queue( '-one')   =>  undef ;
is  $t->qelem            =>  3 ;
@arr = ();
is  $t->total_bytes      =>  0 ;

#$t->pdumpq ;

