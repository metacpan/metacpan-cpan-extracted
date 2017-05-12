# ubuntu: libtest-pod-perl
# http://search.cpan.org/~dwheeler/Test-Pod-1.44/lib/Test/Pod.pm
use Test::More ; # tests => 4
use lib ('..');
use Data::Dumper;
$Data::Dumper::Indent = 1;
# no double-eval needed
#eval{
   eval("use Test::Pod;");
#};
if ($@) {
   SKIP: {
   	   plan(skip_all => "No Test::Pod in this system");
   	   exit(0);
   };
}
# Go forward
# NOT Needed. POD Testing plans by itself
#plan('tests' => 11, );
#my @podfiles = ('','','','','',);
# get files ?
#pod_file_ok('');
my @poddirs = ( 'blib', 'script', ); # '../blib'
# Extra may be given
my @podfiles = all_pod_files( @poddirs );
#DEBUG:print(Dumper(\@podfiles));
all_pod_files_ok(@podfiles);
