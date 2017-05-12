use String::TieStack;

use Test::More ;

BEGIN { plan tests => 7 }

my $t = tie my @arr , 'String::TieStack',  max_entries=>0, max_KBytes=>0;
is  $t->max_entries  =>  0 ;
is  $t->max_KBytes   =>  0 ;

push @arr , 'zero';
is  @arr             =>  1 ;

my @func = qw( PUSH   POP   UNSHIFT makebuf dropbuf 
               desbuf qelem queued  qbuf    import 
	       max_entries  max_KBytes
	     );

ok  can_ok  'String::TieStack' , @func;

use String::TieStack  max_entries => 4 , max_KBytes => 1;

$t = tie my @bar , 'String::TieStack';
is  $t->max_entries   =>  4 ;
is  $t->max_KBytes    =>  1 ;
