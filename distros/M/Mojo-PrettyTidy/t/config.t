use v5.40.0;
use common::sense;
use feature 'signatures';

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use lib 'lib';
use lib 't';
use Mojo::PrettyTidy;
use TestCapture qw(run_cmd);

my $script =
    File::Spec->rel2abs( File::Spec->catfile( qw(bin mojo-prettytidy) ) );

my $lib = File::Spec->rel2abs( 'lib' );

ok -e $script, 'CLI script exists';
ok -x $script, 'CLI script is executable';

sub spurt ( $path, $content ) {
  open my $fh, '>', $path or die "Cannot open '$path' for writing: $!";
  print {$fh} $content;
  close $fh;
}

sub run_config_test ( %args ) {
  my $tmpdir = $args{tmpdir};
  my $home   = $args{home} // $tmpdir;

  return
      run_cmd(
               argv => $args{argv},
               cwd  => $tmpdir,
               env  => {HOME => $home},
               ( defined $args{stdin} ? ( stdin => $args{stdin} ) : () ), );
}

sub write_input_file ( $dir, $name = 'one.html.ep' ) {
  my $path = File::Spec->catfile( $dir, $name );
  spurt( $path, "alpha  \n" );
  return $path;
}

sub write_config ( $path, $json ) {
  spurt( $path, $json );
  return $path;
}

subtest 'autoload prefers $HOME config over cwd config' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $home   = File::Spec->catdir( $tmpdir, 'home' );
  make_path( $home );

  my $input = write_input_file( $tmpdir );

  my $home_cfg = write_config(
                               File::Spec->catfile(
                                                  $home, '.mojo-prettytidy.json'
                               ),
qq[{"columns":0,"attributes":false,"indent_width":4}\n],
  );

  my $cwd_cfg = write_config(
                              File::Spec->catfile(
                                                $tmpdir, '.mojo-prettytidy.json'
                              ),
qq[{"columns":120,"attributes":true,"indent_width":8}\n],
  );

  my $r = run_config_test(
                           tmpdir => $tmpdir,
                           home   => $home,
                           argv => [ $^X, '-I' . $lib, $script, '-VV', $input ],
  );

  is $r->{exit}, 0, 'exit status is 0';
  like $r->{stdout}, qr/^\s*config\s+=>\s+\Q$home_cfg\E\s+\[auto\]/m,
      'autoload selected HOME config';
  unlike $r->{stdout}, qr/\Q$cwd_cfg\E\s+\[auto\]/,
      'cwd config was not selected when HOME config exists';
  like $r->{stdout}, qr/^\s*columns\s+=>\s+0\s+\[config\]/m,
      'columns came from HOME config';
  like $r->{stdout}, qr/^\s*attributes\s+=>\s+0\s+\[config\]/m,
      'attributes came from HOME config';
  like $r->{stdout}, qr/^\s*indent-width\s+=>\s+4\s+\[config\]/m,
      'indent_width came from HOME config';
};

subtest 'autoload falls back to cwd config when HOME config is absent' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $home   = File::Spec->catdir( $tmpdir, 'home' );
  make_path( $home );

  my $input = write_input_file( $tmpdir );

  write_config( File::Spec->catfile( $tmpdir, '.mojo-prettytidy.json' ),
                qq[{"columns":72,"tab_width":4}\n], );

  my $r = run_config_test(
                           tmpdir => $tmpdir,
                           home   => $home,
                           argv => [ $^X, '-I' . $lib, $script, '-VV', $input ],
  );

  is $r->{exit}, 0, 'exit status is 0';
  like $r->{stdout},
      qr/^\s*config\s+=>\s+\.\/\.mojo-prettytidy\.json\s+\[auto\]/m,
      'autoload selected cwd config';
  like $r->{stdout}, qr/^\s*columns\s+=>\s+72\s+\[config\]/m,
      'columns came from cwd config';
  like $r->{stdout}, qr/^\s*tab-width\s+=>\s+4\s+\[config\]/m,
      'tab_width came from cwd config';
};

subtest 'explicit --config overrides default config discovery' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $home   = File::Spec->catdir( $tmpdir, 'home' );
  make_path( $home );

  my $input = write_input_file( $tmpdir );

  write_config( File::Spec->catfile( $home, '.mojo-prettytidy.json' ),
                qq[{"columns":0}\n], );

  write_config( File::Spec->catfile( $tmpdir, '.mojo-prettytidy.json' ),
                qq[{"columns":72}\n], );

  my $explicit = write_config(
                               File::Spec->catfile(
                                                    $tmpdir, 'explicit.json'
                               ),
                               qq[{"columns":99,"javascript":false}\n], );

  my $r = run_config_test(
    tmpdir => $tmpdir,
    home   => $home,
    argv => [ $^X, '-I' . $lib, $script, '--config', $explicit, '-VV', $input ],
  );

  is $r->{exit}, 0, 'exit status is 0';
  like $r->{stdout}, qr/^\s*config\s+=>\s+\Q$explicit\E\s+\[cli\]/m,
      'explicit config path is shown as CLI-set';
  like $r->{stdout}, qr/^\s*columns\s+=>\s+99\s+\[config\]/m,
      'columns came from explicit config';
  like $r->{stdout}, qr/^\s*javascript\s+=>\s+0\s+\[config\]/m,
      'javascript came from explicit config';
};

subtest 'CLI options override config values' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $home   = File::Spec->catdir( $tmpdir, 'home' );
  make_path( $home );

  my $input = write_input_file( $tmpdir );

  write_config( File::Spec->catfile( $home, '.mojo-prettytidy.json' ),
                qq[{"columns":0,"attributes":false,"perl":false}\n], );

  my $r = run_config_test(
                           tmpdir => $tmpdir,
                           home   => $home,
                           argv   => [
                                     $^X,  '-I' . $lib, $script,  '--cols',
                                     '88', '--attrib',  '--perl', '-VV',
                                     $input,
                           ], );

  is $r->{exit}, 0, 'exit status is 0';
  like $r->{stdout}, qr/^\s*columns\s+=>\s+88\s+\[cli\]/m,
      'CLI columns override config';
  like $r->{stdout}, qr/^\s*attributes\s+=>\s+1\s+\[cli\]/m,
      'CLI attributes override config';
  like $r->{stdout}, qr/^\s*perl\s+=>\s+1\s+\[cli\]/m,
      'CLI perl override config';
};

subtest 'unknown config keys are rejected' => sub {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $home   = File::Spec->catdir( $tmpdir, 'home' );
  make_path( $home );

  my $input = write_input_file( $tmpdir );
  my $bad   = write_config( File::Spec->catfile( $tmpdir, 'bad.json' ),
                          qq[{"bogus":true}\n], );

  my $r = run_config_test(
                tmpdir => $tmpdir,
                home   => $home,
                argv => [ $^X, '-I' . $lib, $script, '--config', $bad, $input ],
  );

  isnt $r->{exit}, 0, 'exit is non-zero';
  like $r->{stderr}, qr/Unknown config key 'bogus'/,
      'stderr explains unknown config key';
};

done_testing;

