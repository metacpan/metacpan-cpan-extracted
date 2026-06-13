use v5.40.0;
use common::sense;
use feature 'signatures';

use Cwd qw(abs_path);
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use FindBin    qw($Bin);

use lib 'lib';
use lib 't';
use TestCapture qw( run_cmd );
use Mojo::PrettyTidy;

my $root   = abs_path( File::Spec->catdir( $Bin, '..' ) );
my $lib    = File::Spec->catdir( $root, 'lib' );
my $tlib   = File::Spec->catdir( $root, 't', 'lib' );
my $script = File::Spec->catfile( $root, qw(bin mojo-prettytidy) );

my $untidy = '<div><span>alpha</span></div>' . "\n";
my $tidied = expected_tidy( $untidy );

ok -e $script, 'CLI script exists';
ok -x $script, 'CLI script is executable';

sub slurp ( $path ) {
  open my $fh, '<', $path or die "Cannot open '$path' for reading: $!";
  local $/;
  my $content = <$fh>;
  close $fh;
  return $content;
}

sub spurt ( $path, $content ) {
  open my $fh, '>', $path or die "Cannot open '$path' for writing: $!";
  print {$fh} $content;
  close $fh;
}

sub run_isolated ( %args ) {
  my $tmpdir = $args{tmpdir};
  my %env = (
              HOME => $tmpdir,
              PATH => $ENV{PATH} // '', );

  return
      run_cmd(
               argv => $args{argv},
               ( defined $args{stdin} ? ( stdin => $args{stdin} )        : () ),
               ( defined $tmpdir      ? ( cwd => $tmpdir, env => \%env ) : () ),
      );
}

sub cli_argv ( @args ) {
  return [ $^X, '-I' . $lib, '-I' . $tlib, $script, @args ];
}

sub expected_tidy ( $input, %args ) {
  my $pt = Mojo::PrettyTidy->new( %args );
  return $pt->tidy( $input );
}

subtest 'default mode writes tidied content to stdout' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $untidy );

  my $r = run_isolated( tmpdir => $tmpdir, argv => cli_argv( $path ) );

  is $r->{exit},     0,       'exit status is 0';
  is $r->{stdout},   $tidied, 'stdout contains tidied content';
  is $r->{stderr},   '',      'stderr is empty';
  is slurp( $path ), $untidy, 'input file was not modified';
};

subtest '--check returns 0 for tidy input' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $tidied );

  my $r =
      run_isolated( tmpdir => $tmpdir, argv => cli_argv( '--check', $path ) );

  is $r->{exit},   0,  '--check exits 0 when no changes would occur';
  is $r->{stdout}, '', 'stdout is empty';
  is $r->{stderr}, '', 'stderr is empty';
};

subtest '--check returns 1 for untidy input' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $untidy );

  my $r =
      run_isolated( tmpdir => $tmpdir, argv => cli_argv( '--check', $path ) );

  is $r->{exit},   1,  '--check exits 1 when changes would occur';
  is $r->{stdout}, '', 'stdout is empty';
  is $r->{stderr}, '', 'stderr is empty';
};

subtest '--diff returns 0 when no changes would occur' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $tidied );

  my $r =
      run_isolated( tmpdir => $tmpdir, argv => cli_argv( '--diff', $path ) );

  is $r->{exit},   0,  '--diff exits 0 when no changes would occur';
  is $r->{stdout}, '', 'stdout is empty when no diff is needed';
  is $r->{stderr}, '', 'stderr is empty';
};

subtest '--diff returns 1 and prints diff when changes would occur' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $untidy );

  my $r =
      run_isolated( tmpdir => $tmpdir, argv => cli_argv( '--diff', $path ) );

  is $r->{exit}, 1, '--diff exits 1 when changes are found';
  like $r->{stdout}, qr/^--- \Q$path\E \(original\)$/m,
      'diff includes original header';
  like $r->{stdout}, qr/^\+\+\+ \Q$path\E \(tidied\)$/m,
      'diff includes tidied header';
  like $r->{stdout}, qr/^@@ /m, 'diff includes hunk header';
  is $r->{stderr}, '', 'stderr is empty';
};

subtest '--help reports command-line options' => sub {
  my $r = run_cmd( argv => [ $^X, '-I', $lib, $script, '--help' ], );

  is $r->{exit}, 0, '--help exits 0';
  like $r->{stdout}, qr/COMMAND-LINE OPTIONS/,
      '--help shows command-line options';
  like $r->{stdout}, qr/--version/, '--help includes option details';
  is $r->{stderr}, '', '--help has no stderr';
};

subtest '--output writes tidied content to a separate file' => sub {
  my $tmpdir   = tempdir( CLEANUP => 1 );
  my $in_path  = File::Spec->catfile( $tmpdir, 'one.html.ep' );
  my $out_path = File::Spec->catfile( $tmpdir, 'out.html.ep' );

  spurt( $in_path, $untidy );

  my $r = run_isolated( tmpdir => $tmpdir,
                        argv   => cli_argv( '--output', $out_path, $in_path ) );

  is $r->{exit},         0,       '--output exits 0';
  is $r->{stdout},       '',      'stdout is empty';
  is $r->{stderr},       '',      'stderr is empty';
  is slurp( $in_path ),  $untidy, 'input file was not modified';
  is slurp( $out_path ), $tidied, 'output file received tidied content';
};

subtest '--stdin writes tidied content to stdout' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );

  my $r = run_isolated(
                        tmpdir => $tmpdir,
                        argv   => cli_argv( '--stdin' ),
                        stdin  => $untidy );

  is $r->{exit},   0,       '--stdin exits 0';
  is $r->{stdout}, $tidied, 'stdout contains tidied stdin';
  is $r->{stderr}, '',      'stderr is empty';
};

subtest '--stdin with --output writes tidied content to a file' => sub {
  my $tmpdir   = tempdir( CLEANUP => 1 );
  my $out_path = File::Spec->catfile( $tmpdir, 'out.html.ep' );

  my $r = run_isolated(
                        tmpdir => $tmpdir,
                        argv   => cli_argv( '--stdin', '--output', $out_path ),
                        stdin  => $untidy, );

  is $r->{exit},         0,       '--stdin with --output exits 0';
  is $r->{stdout},       '',      'stdout is empty';
  is $r->{stderr},       '',      'stderr is empty';
  is slurp( $out_path ), $tidied, 'output file received tidied stdin content';
};

subtest '--write rewrites the file in place' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $untidy );

  my $r =
      run_isolated( tmpdir => $tmpdir, argv => cli_argv( '--write', $path ) );

  is $r->{exit},     0,       '--write exits 0';
  is $r->{stdout},   '',      'stdout is empty';
  is $r->{stderr},   '',      'stderr is empty';
  is slurp( $path ), $tidied, 'file was rewritten in place';
};

subtest '--write --backup creates backup and rewrites file' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $untidy );

  my $r = run_isolated( tmpdir => $tmpdir,
                        argv   => cli_argv( '--write', '--backup', $path ) );

  is $r->{exit},   0,  '--write --backup exits 0';
  is $r->{stdout}, '', 'stdout is empty';
  is $r->{stderr}, '', 'stderr is empty';
  ok -e $path . '.bak', 'backup file exists';
  is slurp( $path . '.bak' ), $untidy, 'backup contains original content';
  is slurp( $path ),          $tidied, 'original file was rewritten';
};

subtest '--write --backup-ext uses custom suffix' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $untidy );

  my $r = run_isolated(
         tmpdir => $tmpdir,
         argv => cli_argv( '--write', '--backup', '--backup-ext=.orig', $path ),
  );

  is $r->{exit}, 0, 'custom backup suffix exits 0';
  ok -e $path . '.orig', 'custom backup file exists';
  is slurp( $path . '.orig' ), $untidy,
      'custom backup contains original content';
  is slurp( $path ), $tidied, 'original file was rewritten';
};

subtest
    'directory input with --prefix and --outdir writes matching html.ep files'
    => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $indir  = File::Spec->catdir( $tmpdir, 'templates' );
  my $outdir = File::Spec->catdir( $tmpdir, 'parsed' );

  make_path( $indir, $outdir );

  my $ep1 = File::Spec->catfile( $indir, 'one.html.ep' );
  my $ep2 = File::Spec->catfile( $indir, 'two.html.ep' );
  my $txt = File::Spec->catfile( $indir, 'ignore.txt' );
  my $oth = File::Spec->catfile( $indir, 'three.js.ep' );

  spurt( $ep1, $untidy );
  spurt( $ep2, '<div><span>beta</span></div>' . "\n" );
  spurt( $txt, "leave me alone\n" );
  spurt( $oth, "also ignored\n" );

  my $r = run_isolated(
             tmpdir => $tmpdir,
             argv => cli_argv( $indir, '--prefix', 'pt.', '--outdir', $outdir ),
  );

  is $r->{exit},   0,  'directory input exits 0';
  is $r->{stdout}, '', 'stdout is empty';
  is $r->{stderr}, '', 'stderr is empty';

  ok -e File::Spec->catfile( $outdir, 'pt.one.html.ep' ),
      'first html.ep output exists';
  ok -e File::Spec->catfile( $outdir, 'pt.two.html.ep' ),
      'second html.ep output exists';
  ok !-e File::Spec->catfile( $outdir, 'pt.ignore.txt' ),
      'non-template file was ignored';
  ok !-e File::Spec->catfile( $outdir, 'pt.three.js.ep' ),
      'non-html.ep ep-like file was ignored';
    };

subtest 'multiple inputs without destination mode are rejected' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $in1    = File::Spec->catfile( $tmpdir, 'one.html.ep' );
  my $in2    = File::Spec->catfile( $tmpdir, 'two.html.ep' );

  spurt( $in1, $tidied );
  spurt( $in2, $tidied );

  my $r = run_isolated( tmpdir => $tmpdir, argv => cli_argv( $in1, $in2 ) );

  isnt $r->{exit}, 0, 'exit is non-zero';
  like $r->{stderr}, qr/multiple input/i,
      'stderr explains multiple inputs need an output mode';
};

subtest 'invalid option combinations are rejected' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );
  my $out    = File::Spec->catfile( $tmpdir, 'out.html.ep' );
  my $dir    = File::Spec->catdir( $tmpdir, 'templates' );

  spurt( $path, $tidied );
  make_path( $dir );

  my @cases = (
                [
                  [ '--backup', $path ],
                  qr/--backup requires --write/,
                  '--backup without --write'
                ],
                [
                  [ '--check', $dir ],
                  qr/--check.*single|directory.*not supported/i,
                  '--check with directory'
                ],
                [
                  [ '--diff', $dir ],
                  qr/--diff.*single|directory.*not supported/i,
                  '--diff with directory'
                ],
                [
                  [ '--diff', '--write', $path ],
                  qr/--diff cannot be combined with --write/,
                  '--diff with --write'
                ],
                [
                  [ '--diff', '--stdin' ],
                  qr/--diff cannot be combined with --stdin/,
                  '--diff with --stdin'
                ],
                [
                  [ '--check', '--output', $out, $path ],
                  qr/--output cannot be combined with --check/,
                  '--output with --check'
                ],
                [
                  [ '--diff', '--output', $out, $path ],
                  qr/--output cannot be combined with --diff/,
                  '--output with --diff'
                ],
                [
                  [ '--write', '--output', $out, $path ],
                  qr/--output cannot be combined with --write/,
                  '--output with --write'
                ],
                [
                  [ '--write', '--prefix', 'pt.', $path ],
                  qr/--write cannot be combined with --prefix/,
                  '--write with --prefix'
                ],
                [
                  [ '--write', '--outdir', $dir, $path ],
                  qr/--write cannot be combined with --outdir/,
                  '--write with --outdir'
                ],
                [
                  [ '--stdin', '--write' ],
                  qr/--stdin cannot be combined with --write/,
                  '--stdin with --write'
                ],
                [
                  [ '--stdin', '--backup' ],
                  qr/--backup requires --write/i,
                  '--stdin with --backup'
                ],
                [
                  [ '--stdin', $path ],
                  qr/--stdin cannot be combined with file or directory inputs/,
                  '--stdin with file input'
                ], );

  for my $case ( @cases ) {
    my ( $args, $re, $name ) = @$case;
    my $r = run_isolated( tmpdir => $tmpdir, argv => cli_argv( @$args ) );

    isnt $r->{exit}, 0, "$name exits non-zero";

    my $combined = ( $r->{stderr} // '' ) . ( $r->{stdout} // '' );

    like $combined, $re, "$name explains invalid usage"
        or diag join "\n",
        "case=[$name]",
        "args=[" . join( ' ', @$args ) . "]",
        "exit=[$r->{exit}]",
        "stdout=[$r->{stdout}]",
        "stderr=[$r->{stderr}]";
  }
};

subtest '--version prints version and exits 0' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );

  my $r = run_isolated( tmpdir => $tmpdir, argv => cli_argv( '--version' ) );

  is $r->{exit}, 0, '--version exits 0';
  like $r->{stdout}, qr/^mojo-prettytidy \Q$Mojo::PrettyTidy::VERSION\E\n\z/,
      '--version prints script version';
  is $r->{stderr}, '', 'stderr is empty';
};

subtest '--show-options reports active options and -VV reports defaults' =>
    sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $path   = File::Spec->catfile( $tmpdir, 'one.html.ep' );

  spurt( $path, $tidied );

  my $v = run_isolated(
                      tmpdir => $tmpdir,
                      argv => cli_argv( '-V', '--no-columns', '--diff', $path ),
  );

  my $v_text = ( $v->{stdout} // '' ) . ( $v->{stderr} // '' );

  is $v->{exit}, 0, '-V exits 0';
  like $v_text, qr/^mojo-prettytidy effective options:/m,
      '-V prints options header';
  like $v_text, qr/columns\s+=>\s+0\s+\[cli\]/, '-V shows explicit no-columns';
  like $v_text, qr/diff\s+=>\s+1\s+\[cli\]/,    '-V shows explicit diff';

  my $vv = run_isolated( tmpdir => $tmpdir,
                         argv   => cli_argv( '-VV', $path ), );

  my $vv_text = ( $vv->{stdout} // '' ) . ( $vv->{stderr} // '' );

  is $vv->{exit}, 0, '-VV exits 0';
  like $vv_text, qr/attributes\s+=>\s+1\s+\[default\]/,
      '-VV shows default attributes';
  like $vv_text, qr/columns\s+=>\s+80\s+\[default\]/,
      '-VV shows default columns';
    };

done_testing;
