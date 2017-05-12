package #
  Module::CPANTS::TestAnalyse;

use strict;
use warnings;
use Carp;
use base 'Exporter';
use File::Temp qw/tempdir/;
use File::Path;
use File::Spec::Functions qw/splitpath catfile abs2rel/;
use File::Find;
use Cwd;
use Module::CPANTS::Analyse;
use CPAN::Meta::YAML;
use Test::More;

our @EXPORT = qw/
  test_distribution
  write_file
  write_pmfile
  write_metayml
  archive_and_analyse
/;

push @EXPORT, \$Test::More::TODO, grep {Test::More->can($_)} qw/
  ok use_ok require_ok
  is isnt like unlike is_deeply
  cmp_ok
  skip todo_skip
  pass fail
  eq_array eq_hash eq_set
  plan
  done_testing
  can_ok isa_ok new_ok
  diag note explain
  BAIL_OUT
  subtest
  nest
/;

sub test_distribution (&) {
  my $code = shift;

  my $cwd = cwd;

  my $dir = tempdir(CLEANUP => 1);

  my $mca = Module::CPANTS::Analyse->new({
    dist => $dir,
    distdir => $dir,
  });

  note "tests under $dir";
  eval { $code->($mca, $dir) };
  ok !$@, "no errors";

  chdir $cwd;
  rmtree $dir;
}

sub write_file {
  my ($path, $content) = @_;
  my ($vol, $dir, $file) = splitpath($path);
  $dir = "$vol$dir" if $vol;
  mkpath $dir unless -d $dir;
  open my $fh, '>:encoding(utf8)', $path or croak "Can't open $path: $!";
  print $fh $content;
  note "wrote to $path";
}

sub write_pmfile {
  my ($path, $content) = @_;
  my @lines = ('package '.'Module::CPANTS::Analyse::Test');
  push @lines, $content if defined $content;
  push @lines, '1';
  write_file($path, join ";\n", @lines, "");
}

sub write_metayml {
  my ($path, $args) = @_;
  my $meta = {
    name => 'Module::CPANTS::Analyse::Test',
    abstract => 'test',
    author => ['A.U.Thor'],
    generated_by => 'hand',
    license => 'perl',
    'meta-spec' => {version => '1.4', url => 'http://module-build.sourceforge.net/META-spec-v1.4.html'},
    version => '0.01',
    %{$args || {}},
  };
  write_file($path, CPAN::Meta::YAML->new($meta)->write_string);
}

sub archive_and_analyse {
  my ($dir, $name) = @_;
  my $archive_path = catfile($dir, $name);
  (my $basename = $name) =~ s/(?:\.tar\.(?:gz|bz)|\.zip)$//;
  require Archive::Tar;
  my $archive = Archive::Tar->new;
  find({
    wanted => sub {
      my $file = $File::Find::name;
      my $relpath = abs2rel($file, $dir);
      return if $relpath =~ /^\./;
      my $path = catfile($basename, $relpath);
      if (-l $file) {
        $archive->add_data($path, '', {
          type => Archive::Tar::SYMLINK,
          linkname => readlink $file,
        }) or die "failed to add symlink: $path";
      } elsif (-f $file) {
        my $content = do { local $/; open my $fh, '<', $file; <$fh> };
        $archive->add_data($path, $content);
      } elsif (-d $dir && $path ne '.') {
        $archive->add_data($path, '', Archive::Tar::DIR) or die "failed to add dir: $path";
      }
    },
    no_chdir => 1,
  }, $dir);
  $archive->write($archive_path, Archive::Tar::COMPRESS_GZIP);

  ok -f $archive_path, "archive exists";

  Module::CPANTS::Analyse->new({
    dist => $archive_path,
  })->run;
}

1;
