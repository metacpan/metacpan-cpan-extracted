use Test::More tests=>3;
BEGIN {  eval 'use Test::Pod'; }

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';
my @files = ( <${dir}lib/String/*.pm>, 
              <${dir}lib/String/*pod>,
	      <${dir}lib/String/RexxStack/*pm> ,
	    );



SKIP: {
	skip  'no Test::Pod', 3       unless $INC{'Test/Pod.pm'} ;
	pod_file_ok $_ , "$_ ok"      for @files;
} ;
