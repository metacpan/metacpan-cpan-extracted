#!/usr/bin/env perl
# scripts/binary-pp-args.sh hands pp the -M and -X sets in an option file (k242): some 2000
# options are past the 32767 characters of a Windows command line, where the Windows build leg
# failed with "Argument list too long". The script prints one line, @binary-pp-args.txt, and
# that file in the dist root expands, the way pp reads it there (Getopt::ArgvFile with
# resolveEnvVars), to exactly the options the two sets make; a name that this expansion would
# change stops the build instead.
# The script runs in a temp dist: lib/ and script/ of this checkout, and stand-ins for
# scripts/loaded-modules.pl and scripts/left-out-modules.pl that print fixed lists.
use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd ();
use Path::Tiny qw( path tempdir );

my $dist   = path( $FindBin::Bin, '..' )->realpath;
my $script = $dist->child( 'scripts', 'binary-pp-args.sh' );
plan skip_all => 'needs scripts/binary-pp-args.sh and package.json (a skilletor checkout)'
  unless $script->is_file && $dist->child('package.json')->is_file;
plan skip_all => 'a Unix shell test (the Windows leg runs the script in the workflow)' if $^O eq 'MSWin32';
plan skip_all => 'needs bash' unless grep { -x "$_/bash" } split /:/, $ENV{PATH} // '';
plan skip_all => 'needs Getopt::ArgvFile, which pp reads its option files with (PAR::Packer)'
  unless eval { require Getopt::ArgvFile; 1 };
plan skip_all => 'needs what the script checks first: Text::Nunjucks, IO::Socket::SSL 2.009, Mozilla::CA'
  unless eval { require Text::Nunjucks; require IO::Socket::SSL; IO::Socket::SSL->VERSION(2.009); require Mozilla::CA; 1 };

my $tmp = tempdir;
my $d   = $tmp->child('dist');
$d->child('scripts')->mkpath;
for my $part (qw( lib script )) {
  symlink( $dist->child($part), $d->child($part) ) or die "symlink $part: $!";
}
$script->copy( $d->child( 'scripts', 'binary-pp-args.sh' ) );
my $file = $d->child('binary-pp-args.txt');

# run_with(\@loaded, \@left_out): the script from the temp dist, the stand-ins printing the two
# lists, this perl first on PATH. Returns exit code, stdout, stderr.
sub run_with {
  my ( $loaded, $left_out ) = @_;
  for ( [ 'loaded-modules.pl', $loaded ], [ 'left-out-modules.pl', $left_out ] ) {
    my ( $name, $lines ) = @$_;
    $d->child( 'scripts', $name )->spew_raw( "print <<'EOF';\n" . join( '', map { "$_\n" } @$lines ) . "EOF\n" );
  }
  my ( $out, $err ) = ( $tmp->child('out'), $tmp->child('err') );
  local $ENV{PATH} = path($^X)->absolute->parent . ":$ENV{PATH}";
  my $cwd = Cwd::getcwd();
  chdir $d or die "chdir $d: $!";
  system( 'bash', '-c', 'exec bash scripts/binary-pp-args.sh >"$0" 2>"$1"', "$out", "$err" );
  my $rc = $? >> 8;
  chdir $cwd or die "chdir $cwd: $!";
  return ( $rc, $out->slurp_raw, $err->slurp_raw );
}

# The pp command line of the bundle with ARGS in the place of the script's lines, expanded as pp
# expands it, in the dist root (where the bundle runs pp).
sub as_pp_reads {
  my @argv = ( '-o', 'OUT', '-I', 'lib', @_, 'script/skilletor' );
  my $cwd = Cwd::getcwd();
  chdir $d or die "chdir $d: $!";
  Getopt::ArgvFile::argvFile( array => \@argv, resolveEnvVars => 1 );
  chdir $cwd or die "chdir $cwd: $!";
  return \@argv;
}
sub options { my ( $loaded, $left_out ) = @_; [ '-o', 'OUT', '-I', 'lib', ( map { ( '-M', $_ ) } @$loaded ), ( map { ( '-X', $_ ) } @$left_out ), 'script/skilletor' ] }

local $ENV{SKILLETOR_T_VAR} = 'expanded';
my @loaded   = map { sprintf 'Fake::Loaded::M%03d', $_ } 1 .. 260;
my @left_out = ( 'Pod::Usage', 'unicore/lib/Perl/Word.pl', 'unicore/To/Lb.pl', map { sprintf 'Fake::Left::Out::Member%04d', $_ } 1 .. 1800 );

subtest 'the sets go to pp as one @FILE' => sub {
  my ( $rc, $out, $err ) = run_with( \@loaded, \@left_out );
  is( $rc, 0, 'the script passes' ) or diag $err;
  is( $out, "\@binary-pp-args.txt\n", 'it prints one line: @ and the option file' );
  ok( $file->is_file, 'which it wrote in the dist root' );
  is_deeply( as_pp_reads( $out =~ s/\n\z//r ), options( \@loaded, \@left_out ), 'pp reads the file as -M per loaded module, then -X per left-out one' );
  like( $err, qr/^binary-pp-args: 260 modules \(-M\), 1803 left out \(-X\) in binary-pp-args\.txt;/m, 'STDERR names the counts and the file' );
};

subtest 'the next run overwrites the file' => sub {
  my @fewer = @loaded[ 0 .. 150 ];
  my ( $rc, $out, $err ) = run_with( \@fewer, ['Pod::Usage'] );
  is( $rc, 0, 'the script passes' ) or diag $err;
  is_deeply( as_pp_reads( $out =~ s/\n\z//r ), options( \@fewer, ['Pod::Usage'] ), 'only this run\'s sets' );
};

# refused(\@loaded, \@left_out, $bad): the run fails on $bad before it writes the file.
sub refused {
  my ( $loaded, $left_out, $bad ) = @_;
  $file->remove;
  my ( $rc, $out, $err ) = run_with( $loaded, $left_out );
  is( $rc, 1, 'the script fails' );
  is( $out, '', 'it prints no argument' );
  like( $err, qr/^ERROR: '\Q$bad\E' cannot go into pp's option file/m, 'it names the entry' ) or diag $err;
  ok( !$file->exists, 'it writes no option file' );
}

# Each would come out of the file changed: split, expanded, unquoted, or read as a file itself.
for my $bad ( 'Two Words', 'Env::$SKILLETOR_T_VAR', 'Env::${SKILLETOR_T_VAR}', "Quo'te", 'Back\\slash', '@nested' ) {
  subtest "a left-out name pp's option file would change stops the build: $bad" => sub {
    my $probe = $tmp->child('probe');
    $probe->spew_raw("-X $bad\n");
    isnt( join( "\0", @{ as_pp_reads("\@$probe") } ), join( "\0", @{ options( [], [$bad] ) } ), 'pp would read it otherwise' );
    refused( \@loaded, [ 'Pod::Usage', $bad ], $bad );
  };
}
subtest 'so does a loaded one' => sub { refused( [ @loaded, 'Two Words' ], ['Pod::Usage'], 'Two Words' ) };

done_testing;
