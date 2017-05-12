use Module::Build::Kwalitee;
use Test::More tests => 10;

use Data::Dumper;
use File::Temp qw( tempdir );
use File::Find::Rule;
use File::Spec::Functions qw(catfile);

my $dir = tempdir( CLEANUP => 1 );

chdir $dir;

ok ! -d "t", 'no directory yet';

ok (my $build = Module::Build::Kwalitee->new(
  license => 'perl',
  dist_name => 'Foo', 
  dist_version => '0.01',
  dist_author => 'Stig',
  dist_abstract => 'this is a module that...',
), 'get a build object');

ok -d "t", "there's a test directory now";

my @files = File::Find::Rule->file()->name('00*.t')->in('t');
is scalar @files, 4, 'four test files present' or diag Dumper \@files;

# check deps
my $requires = {
  'Test::More' => 0,
  'File::Find::Rule' => 0,
};
my $recommends = {
  'Test::Pod' => 0,
  'Pod::Coverage::CountParents' => 0,
  'IPC::Open3' => 0,
};
is_deeply $build->build_requires, $requires, 'expected requires';
is_deeply $build->recommends, $recommends, 'expected recommends';


# now check distdir target
my $distdir = 'Foo-0.01';
is $build->dist_dir, $distdir, 'expected dist dir';

ok ! -d $distdir, 'distdir does not exist';
$build->ACTION_manifest;
$build->ACTION_distdir;
ok -d $distdir, 'distdir exists now';

ok -f catfile($distdir, qw(mbk Module Build Kwalitee.pm));

END {
  rmdir $distdir;
}
