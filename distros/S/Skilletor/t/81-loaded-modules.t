#!/usr/bin/env perl
# scripts/loaded-modules.pl makes its fixture below the first of TMPDIR, TEMP and TMP that is a
# directory, else /tmp, and removes it again, a die included (k242). The bundle's Windows build
# leg sets no TMPDIR, and Strawberry perl cannot see Git Bash's /tmp; TEMP and TMP are set there.
# A git on PATH that records its arguments and fails stops the script at its first git call,
# right after the fixture dir is made, so the base it chose can be read off that call.
use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd ();
use Path::Tiny qw( path tempdir );

my $dist   = path( $FindBin::Bin, '..' )->realpath;
my $script = $dist->child( 'scripts', 'loaded-modules.pl' );
plan skip_all => 'needs scripts/loaded-modules.pl and package.json (a skilletor checkout)'
  unless $script->is_file && $dist->child('package.json')->is_file;
plan skip_all => 'a Unix test (the Windows leg runs the script in the workflow)' if $^O eq 'MSWin32';
my @path = split /:/, $ENV{PATH} // '';
plan skip_all => 'needs git and sh' unless grep( { -x "$_/git" } @path ) && grep( { -x "$_/sh" } @path );

sub sq { my $s = shift; $s =~ s/'/'\\''/g; "'$s'" }
my $tmp = tempdir;
my $log = $tmp->child('git-args');
my $fakebin = $tmp->child('fakebin');
$fakebin->mkpath;
$fakebin->child('git')->spew_raw( "#!/bin/sh\nprintf '%s\\n' \"\$@\" >".sq($log)."\nexit 1\n" );
$fakebin->child('git')->chmod(0755);

# run_script(\%env, $fake_git): the script from the dist root, every name in %env set to its value
# or, for undef, removed; with $fake_git the recording git first on PATH. Returns exit code,
# stdout, stderr.
sub run_script {
  my ( $env, $fake_git ) = @_;
  local @ENV{ keys %$env } = values %$env;
  delete $ENV{$_} for grep { !defined $env->{$_} } keys %$env;
  local $ENV{PATH} = $fake_git ? "$fakebin:$ENV{PATH}" : $ENV{PATH};
  $log->remove;
  my ( $out, $err ) = ( $tmp->child('out'), $tmp->child('err') );
  my $cwd = Cwd::getcwd();
  chdir $dist or die "chdir $dist: $!";
  system( 'sh', '-c', 'exec "$0" -Ilib scripts/loaded-modules.pl >"$1" 2>"$2"', $^X, "$out", "$err" );
  my $rc = $? >> 8;
  chdir $cwd or die "chdir $cwd: $!";
  return ( $rc, $out->slurp_raw, $err->slurp_raw );
}

my %dir = map { $_ => $tmp->child("base-$_") } qw( tmpdir temp tmp );
$_->mkpath for values %dir;
my $missing = $tmp->child('no-such-dir');

# [ name, env, the base that must be chosen ]
my @cases = (
  [ 'TMPDIR unset: TEMP',                  { TMPDIR => undef,          TEMP => "$dir{temp}", TMP => "$dir{tmp}" }, 'temp' ],
  [ 'TMPDIR and TEMP unset: TMP',          { TMPDIR => undef,          TEMP => undef,        TMP => "$dir{tmp}" }, 'tmp' ],
  [ 'TMPDIR first',                        { TMPDIR => "$dir{tmpdir}", TEMP => "$dir{temp}", TMP => "$dir{tmp}" }, 'tmpdir' ],
  [ 'a TMPDIR that is no directory: TEMP', { TMPDIR => "$missing",     TEMP => "$dir{temp}", TMP => undef },       'temp' ],
);
for my $case (@cases) {
  my ( $name, $env, $want ) = @$case;
  subtest $name => sub {
    my ( $rc, undef, $err ) = run_script( $env, 1 );
    isnt( $rc, 0, 'the failing git stops the script' );
    like( $err, qr/^loaded-modules: git init -q -b main failed$/m, 'at its first git call' ) or diag $err;
    my @args = $log->is_file ? $log->lines_raw( { chomp => 1 } ) : ();
    is( $args[0], '-C', 'git ran with -C' );
    like( $args[1] // '', qr{\A\Q$dir{$want}\E/skilletor-loaded-modules\.\d+\.\d+/git/remote\z},
      "the fixture is below the $want dir" );
    is_deeply( [ map { [ $_, [ $dir{$_}->children ] ] } sort keys %dir ], [ map { [ $_, [] ] } sort keys %dir ],
      'the fixture dir is removed after the die' );
  };
}

# The whole run with TEMP alone, as on the Windows leg: the module list, and nothing left behind.
my ( $rc, $out, $err ) = run_script( { TMPDIR => undef, TEMP => "$dir{temp}", TMP => undef }, 0 );
is( $rc, 0, 'loaded-modules.pl passes with TEMP alone' ) or diag $err;
my @mods = split /\n/, $out;
cmp_ok( scalar @mods, '>', 100, 'it prints the loaded set' );
for my $m (qw( Skilletor::CLI Skilletor::Source::Git Skilletor::Render Text::Nunjucks HTTP::Tiny )) {
  ok( ( grep { $_ eq $m } @mods ), "the loaded set has $m" );
}
is_deeply( [ $dir{temp}->children ], [], 'the TEMP dir is left empty' );

done_testing;
