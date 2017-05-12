#use Data::Dumper;
use Test::More qw(no_plan);
use PerlIO::via::Skip;
BEGIN { eval q(use Test::Exception) };

my $data ;

sub work ($) {
        my ($mode) = @_ ;
 	no warnings;
	die unless open my $i , "${mode}:via(Skip)",  \$data ;
}


SKIP: {
 skip 'because no Test::Exception', 5  unless $INC{ 'Test/Exception.pm'}; 
	lives_ok { work  '<'   } ;
	lives_ok { work  '>'   } ;
	lives_ok { work  '>>'  } ;
	dies_ok  { work   '+>' } ;
	dies_ok  { work   '+<' } ;
}
