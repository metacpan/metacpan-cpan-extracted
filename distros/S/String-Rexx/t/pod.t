use Test::More qw(no_plan);
BEGIN { eval 'use Test::Pod' };

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';
my $file = "${dir}lib/String/Rexx.pm" ;

SKIP: {
	skip  'no Test::Pod', 1  unless $INC{'Test/Pod.pm'} ;
	pod_file_ok $file , 'Pod ok' ;
} ;
