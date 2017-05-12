package RepoTest;
use strict;
use warnings;

use File::Temp;
use File::Spec;
use Cwd ();
require Test::More;

use vars qw/$StartDir $Debug/;

BEGIN {$StartDir = Cwd::cwd();}

my ($datadir, $parrepo_cmd, @test_dists, $tempdir);

my @repofiles = qw(
  dbm_checksums.txt
  modules_dists.dbm.zip
  repository_info.yml
  scripts_dists.dbm.zip
  dependencies.dbm.zip
  symlinks.dbm.zip
);

setup();


sub setup {
  $datadir = File::Spec->rel2abs('data');
  Test::More::ok(-d $datadir, __PACKAGE__ . ': located data dir');

  $parrepo_cmd = File::Spec->rel2abs(
    File::Spec->catfile(
      File::Spec->updir(),
      'bin',
      'parrepo',
    )
  );
  Test::More::ok(-f $parrepo_cmd, __PACKAGE__ . ': located parrepo command');

  opendir my $dh, $datadir or die $!;
  while (defined(my $file = readdir($dh))) {
    my $full = File::Spec->catfile($datadir, $file);
    next if not -f $full;
    push @test_dists, $full if $full =~ /\.par$/i;
  }
  closedir $dh;
  Test::More::ok(scalar(@test_dists), __PACKAGE__ . ': located one or more test distributions');

}


sub RepoFiles { [@repofiles] }
sub DataDir { $datadir }
sub ParrepoCmd { $parrepo_cmd }
sub TestDists { [@test_dists] }


sub TempDir {
  return $tempdir if defined $tempdir;
  $tempdir = File::Temp::tempdir( CLEANUP => 1 );
  return $tempdir;
}


sub RunParrepo {
  my $class = shift;
  my @args = @_;
  my $cmd = RepoTest->ParrepoCmd;
  my $perl = $^X;
  my $inc = File::Spec->catdir($StartDir, File::Spec->updir(), 'blib', 'lib');
  my @full_cmd = (
    $perl,
    "-I$inc",
    $cmd,
    @args
  );

  warn __PACKAGE__ . ": Running '@full_cmd'" if $Debug;

  return system(@full_cmd);
}


sub TestRepoFilesExist {
  my $class = shift;
  my $path = shift;
  my $files = RepoTest->RepoFiles;
  
  my %repofiles = map {($_ => 1)} @$files;
  foreach my $file (@$files) {
    my $full = File::Spec->catfile($path, $file);
    Test::More::ok(-f $full, __PACKAGE__ . ": parrepo contains file '$file'");
  }

  opendir my $dh, $path or die "Could not open repository directory '$path': $!";
  my @badfiles;
  while (defined($_ = readdir($dh))) {
    next unless -f File::Spec->catfile($path, $_);
    push @badfiles, $_ if not exists $repofiles{$_};
  }
  closedir $dh;

  Test::More::ok(!@badfiles, 'No extra files in repository main directory')
    or Test::More::diag("Found the following extra files in the repository main directory: '"
            . join("', '", @badfiles) . "'");
  
}


sub CanOpenRepo {
  my $class = shift;
  require PAR::Repository;

  my $path = shift;
  my @args = @_;

  my $repo = PAR::Repository->new( path => $path, @args );
  Test::More::isa_ok($repo, 'PAR::Repository');
  Test::More::ok(-d $path, __PACKAGE__ . ': repo path exists after open');
  return $repo;
}


sub ConvertSymlinks {
  my $class = shift;
  my $path = shift;
  my $repo = $class->CanOpenRepo($path);
  
  $repo->_convert_symlinks();
  return();
}



END { chdir($StartDir); }

1;

