use v5.40.0;
use common::sense;
use feature 'signatures';

use Test::More;
use File::Basename;
use File::Temp qw(tempdir);
use File::Spec qw(dirname);
use File::Path qw(make_path);

use lib 't';
use TestCapture qw(run_cmd);

my $root =
    File::Spec->rel2abs( File::Spec->catdir( dirname( __FILE__ ), '..' ) );
my $lib    = File::Spec->catdir( $root, 'lib' );
my $tlib   = File::Spec->catdir( $root, 't' );
my $script = File::Spec->catfile( $root, qw(bin mojo-prettytidy) );

ok -e $script, 'CLI script exists';
ok -x $script, 'CLI script is executable';

sub all_stale_artifacts_exist ( $tmpdir ) {
  for my $path ( stale_artifact_paths( $tmpdir ) ) {
    return 0 if !-e $path;
  }

  return 1;
}

sub cli_argv ( @args ) {
  return [ $^X, '-I' . $lib, '-I' . $lib, $script, @args ];
}

sub create_stale_artifacts ( $tmpdir ) {
  for my $dir ( stale_artifact_dirs( $tmpdir ) ) {
    make_path( $dir );
    spurt( File::Spec->catfile( $dir, 'stale.txt' ), "stale\n" );
  }

  for my $path ( legacy_stale_artifact_paths( $tmpdir ) ) {
    my ( undef, $dir ) = File::Spec->splitpath( $path );
    make_path( $dir ) if length $dir;
    spurt( $path, "legacy stale\n" );
  }

  return;
}

sub legacy_stale_artifact_paths ( $tmpdir ) {
  return ( File::Spec->catfile( $tmpdir, qw(tmp pt.raw-perltidy.out) ), );
}

sub run_isolated ( %args ) {
  my $tmpdir = $args{tmpdir};

  my %env = (
              HOME => $tmpdir,
              PATH => $ENV{PATH} // '', );

  return
      run_cmd(
               argv => $args{argv},
               cwd  => $tmpdir,
               env  => \%env, );
}

sub spurt ( $path, $content ) {
  open my $fh, '>', $path or die "Cannot open '$path' for writing: $!";
  print {$fh} $content;
  close $fh;
}

sub stale_artifact_dirs ( $tmpdir ) {
  return (
           File::Spec->catdir( $tmpdir, qw(tmp perltidy) ),
           File::Spec->catdir( $tmpdir, qw(tmp debug) ),
           File::Spec->catdir( $tmpdir, qw(tmp error) ),
           File::Spec->catdir( $tmpdir, qw(tmp javascript) ),
           File::Spec->catdir( $tmpdir, qw(tmp prettytidy) ), );
}

sub stale_artifact_paths ( $tmpdir ) {
  my @files = legacy_stale_artifact_paths( $tmpdir );

  for my $dir ( stale_artifact_dirs( $tmpdir ) ) {
    push @files, File::Spec->catfile( $dir, 'stale.txt' );
  }

  return @files;
}

sub slurp ( $path ) {
  open my $fh, '<', $path or die "Cannot open '$path' for reading: $!";
  local $/;
  my $content = <$fh>;
  close $fh;
  return $content;
}

subtest 'cleanup removes stale PrettyTidy artifacts before a run' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );

  ok( File::Spec->rel2abs( $tmpdir ) ne File::Spec->rel2abs( '.' ),
      'cleanup test uses isolated tempdir, not repo root', );

  my $input = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $input, "<div><span>alpha</span></div>\n" );
  create_stale_artifacts( $tmpdir );

  ok all_stale_artifacts_exist( $tmpdir ), 'stale artifacts exist before a run';

  my $r = run_isolated( tmpdir => $tmpdir, argv => cli_argv( $input ) );

  is $r->{exit}, 0, 'formatter exits 0'
      or diag "stdout:\n$r->{stdout}\nstderr:\n$r->{stderr}";
  for my $dir ( stale_artifact_dirs( $tmpdir ) ) {
    ok !-e $dir, "removed stale artifact directory $dir"
        or diag "still exists: $dir";
  }

  for my $path ( legacy_stale_artifact_paths( $tmpdir ) ) {
    ok !-e $path, "removed legacy stale artifact $path"
        or diag "still exists: $path";
  }
};

done_testing;

1;

#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
