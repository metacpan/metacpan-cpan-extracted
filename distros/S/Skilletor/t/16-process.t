#!/usr/bin/env perl
# Skilletor::Process: run_command and spawn_detached, on the POSIX path and on the Windows path –
# the latter driven here with its spawn done the POSIX way (SkilletorTest::Win32), so everything
# but the Windows system calls themselves runs on any system. On Windows the same cases run on
# the real Windows path instead (the row "native"); what needs fork is skipped there.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );
use SkilletorTest::Win32 qw( win32_os parse_cmdline );

use Cwd ();
use Errno ();
use File::Spec ();
use POSIX ();
use Path::Tiny qw( path tempdir );
use Time::HiRes ();
use Skilletor::Process qw( run_command spawn_detached );

my $NATIVE_WIN32 = $^O eq 'MSWin32';
my $tmp = tempdir;
my $bin = $tmp->child('bin');
$bin->mkpath;
# A Windows program has its extension; this perl gets one.
symlink $^X, "$bin/perl.exe" or die "symlink: $!" unless $NATIVE_WIN32;

my %PATH = $NATIVE_WIN32
  ? ( native => { perl => $^X, args => sub { () } } )
  : (
  posix => { perl => $^X,             args => sub { () } },
  win32 => { perl => "$bin/perl.exe", args => sub { ( win32 => win32_os() ) } },
  );

sub perl_e {
  my ( $p, $script, @args ) = @_;
  return [ $p->{perl}, '-e', $script, @args ];
}

for my $name ( sort keys %PATH ) {
  my $p = $PATH{$name};
  my $run = sub { run_command( $p->{args}->(), @_ ) };

  subtest "$name: exit code, stdout and stderr as bytes" => sub {
    my $r = $run->( cmd => perl_e( $p, 'binmode STDOUT; print "out\x00\xff"; print STDERR "err"; exit 3' ) );
    is_deeply( $r, { code => 3, signal => 0, stdout => "out\x00\xff", stderr => 'err', timed_out => 0 }, 'the result' );
  };

  subtest "$name: every argument arrives as it was given" => sub {
    my @args = ( '', 'a b', "tab\there", 'quote"inside', 'back\\slash', 'trail\\', 'trail space\\', '\\"', '"', '""',
      "new\nline", "caf\xc3\xa9", '%PATH%', '&|<>^()', '  lead', 'a\\\\"b c', '\\\\server\\share x\\' );
    my $r = $run->( cmd => perl_e( $p, 'binmode STDOUT; print join "\0", @ARGV', @args ) );
    is( $r->{code}, 0, 'ran' );
    is_deeply( [ split /\0/, $r->{stdout}, -1 ], \@args, 'the arguments' );
  };

  subtest "$name: stdin gets the bytes, then end of file" => sub {
    my $bytes = join '', map { chr( $_ % 256 ) } 1 .. 1_000_000;
    my $r = $run->( cmd => perl_e( $p, 'binmode STDIN; binmode STDOUT; local $/; print <STDIN>' ), stdin => $bytes );
    ok( $r->{stdout} eq $bytes, 'echoed byte for byte (1 MB)' );
    # A child that fills its stdout before it reads stdin.
    $r = $run->( cmd => perl_e( $p, 'binmode STDOUT; print "x" x 1_000_000; local $/; my $in = <STDIN>; print length $in' ), stdin => 'y' x 300_000 );
    is( substr( $r->{stdout}, 1_000_000 ), '300000', 'no deadlock between a full stdout and stdin' );
    like( error_of( sub { $run->( cmd => perl_e( $p, '1' ), stdin => "\x{263a}" ) } ), qr/stdin must be bytes/, 'characters are refused' );
  };

  subtest "$name: no stdin is the null device" => sub {
    my $r = $run->( cmd => perl_e( $p, 'print defined( scalar <STDIN> ) ? "data" : "eof"' ) );
    is( $r->{stdout}, 'eof', 'end of file at once' );
  };

  subtest "$name: cwd and the whole environment" => sub {
    my $dir = $tmp->child("cwd-$name");
    $dir->mkpath;
    my $before = Cwd::getcwd();
    my %env_before = %ENV;
    my $r = $run->(
      cmd => perl_e( $p, 'use Cwd; print getcwd(), "\n", join( ",", sort keys %ENV ), "\n", $ENV{ONLY}' ),
      cwd => "$dir",
      env => { ONLY => 'this' },
    );
    my ( $cwd, $rest ) = split /\n/, $r->{stdout}, 2;
    is( path($cwd)->realpath->stringify, $dir->realpath->stringify, 'its cwd' );
    is( $rest, "ONLY\nthis", 'nothing but the given environment' );
    is( Cwd::getcwd(), $before, 'our cwd unchanged' );
    is_deeply( \%ENV, \%env_before, 'our environment unchanged' );
  };

  subtest "$name: a spawn error says which stage failed" => sub {
    my $enoent = do { local $! = Errno::ENOENT(); "$!" };
    my $r = $run->( cmd => perl_e( $p, '1' ), cwd => "$tmp/no-such-dir" );
    is_deeply( $r->{spawn_error}, { stage => 'chdir', errno => Errno::ENOENT(), message => $enoent }, 'no such directory: chdir' );
    is( $r->{code}, 127, 'and exit code 127, as the POSIX child' );
    $r = $run->( cmd => ["$tmp/no-such-program"] );
    is_deeply( $r->{spawn_error}, { stage => 'exec', errno => Errno::ENOENT(), message => $enoent }, 'no such program: exec' );
  };

  subtest "$name: the timeout ends the child, reported as SIGTERM" => sub {
    my $t0 = Time::HiRes::time();
    my $r = $run->( cmd => perl_e( $p, '$| = 1; print "early"; sleep 30' ), timeout_ms => 500 );
    cmp_ok( Time::HiRes::time() - $t0, '<', 10, 'returns after the timeout, not the child' );
    is_deeply( [ @{$r}{qw( timed_out code signal stdout )} ], [ 1, undef, 15, 'early' ], 'timed out, no code, signal 15, what it wrote kept' );
  };

  subtest "$name: our STDOUT keeps what it had and where it goes" => sub {
    my $file = $tmp->child("stdout-$name");
    open my $saved, '>&', \*STDOUT or die;
    open STDOUT, '>', "$file" or die;
    binmode STDOUT, ':raw:encoding(UTF-8)';
    STDOUT->autoflush(0);    # Test::Builder turned it on
    my @layers = PerlIO::get_layers(*STDOUT);
    print "before\x{263a}";    # still in the buffer
    my $r = $run->( cmd => perl_e( $p, 'print "child"' ) );
    print "after";
    my @after = PerlIO::get_layers(*STDOUT);
    close STDOUT;
    open STDOUT, '>&', $saved or die;
    STDOUT->autoflush(1);
    is( $r->{stdout}, 'child', 'the child\'s output is its own' );
    is( $file->slurp_raw, "before\xe2\x98\xbaafter", 'ours went where it went, in order' );
    is_deeply( \@after, \@layers, 'and kept its layers' );
  };

  subtest "$name: ON_WAIT" => sub {
    my $ticks = 0;
    local $Skilletor::Process::ON_WAIT = sub { $ticks++ };
    $run->( cmd => perl_e( $p, 'select undef, undef, undef, 0.3' ) );
    if   ( $name ne 'posix' ) { cmp_ok( $ticks, '>', 3, 'called while the Windows path waits' ) }
    else                      { is( $ticks, 0, 'never on the POSIX path' ) }
  };
}

# ---- the Windows path only -------------------------------------------------------------------

subtest 'win32: the program, found as Node finds it on PATH – never in the cwd first' => sub {
  my $find = \&Skilletor::Process::_win32_program;
  my $root = $tmp->child('find');
  path( $root, $_ )->touchpath for qw( a/tool.exe b/tool.com b/tool.exe c/run.ps1 c/run.ps1.exe d/x e/script.cmd cwd/tool.exe );
  path( $root, 'q', 'tool.exe' )->touchpath;
  my $f = sub { my $r = $find->(@_); defined $r ? path($r)->relative($root)->stringify : undef };
  is( $f->( 'tool', "$root/a;$root/b" ), 'a/tool.exe', 'the first PATH entry that has it' );
  is( $f->( 'tool', "$root/b;$root/a" ), 'b/tool.com', '.com before .exe' );
  is( $f->( 'run.ps1', "$root/c" ), 'c/run.ps1', 'a name with an extension as it is first' );
  is( $f->( 'x', "$root/d" ), undef, 'a name without one only with .com or .exe' );
  is( $f->( 'tool', qq(;"$root/q";) ), 'q/tool.exe', 'empty entries skipped, quotes around one dropped' );
  is( $f->( "$root/b/tool" ), 'b/tool.com', 'a directory part: there, not on PATH' );
  is( $f->( 'tool.exe', '' ), undef, 'nothing on PATH, nothing found' );
  {
    my $back = Cwd::getcwd();
    chdir "$root/cwd" or die;
    is( $f->( 'tool', "$root/b" ), 'b/tool.com', 'a tool.exe in the cwd is not taken' );
    is( $f->( 'tool', 'rel' ), undef, 'nor through a relative PATH entry that is not there' );
    is( $f->( './tool', '' ), 'cwd/tool.exe', 'unless named with a directory part' );
    chdir $back or die;
  }
  is( Skilletor::Process::_env_value( { Path => 'x', other => 'y' }, 'PATH' ), 'x', 'PATH in any case' );

  return if $NATIVE_WIN32;    # the rest spawns the POSIX way
  my $os = win32_os();
  my %env = ( ( map { $_ => $ENV{$_} } grep { uc ne 'PATH' } keys %ENV ), Path => "$bin" );    # one PATH, as Windows has
  my $r = run_command( win32 => $os, cmd => [ 'perl', '-e', 'print "found"' ], env => \%env );
  is( $r->{stdout}, 'found', 'perl on PATH: perl.exe' );
  is( $os->{calls}[0][1], "$bin/perl.exe", 'spawned by its full path' );
  like( $os->{calls}[0][2], qr/\Aperl -e "print \\"found\\""\z/, 'argv[0] as given' );
  $r = run_command( win32 => $os, cmd => ["$root/e/script.cmd"] );
  is( $r->{spawn_error}{errno}, Errno::EINVAL(), 'a .cmd is never run (cmd.exe would parse its arguments)' );
  is( scalar @{ $os->{calls} }, 1, 'nothing spawned for it' );
};

subtest 'win32: arguments quoted as libuv quotes them, parsed back as they were' => sub {
  my $q = \&Skilletor::Process::_win32_quote;
  # libuv's quote_cmd_arg examples (src/win/process.c)
  my @table = (
    [ 'hello"world',    '"hello\\"world"' ],
    [ 'hello""world',   '"hello\\"\\"world"' ],
    [ 'hello\\world',   'hello\\world' ],
    [ 'hello\\\\world', 'hello\\\\world' ],
    [ 'hello\\"world',  '"hello\\\\\\"world"' ],
    [ 'hello\\\\"world', '"hello\\\\\\\\\\"world"' ],
    [ 'hello world\\',  '"hello world\\\\"' ],
    [ '',               '""' ],
    [ 'plain',          'plain' ],
    [ 'two words',      '"two words"' ],
  );
  is( $q->( $_->[0] ), $_->[1], "quote $_->[0]" ) for @table;
  my @args = map { $_->[0] } @table;
  push @args, "a\tb", "a\nb", '\\', '\\\\', '"\\', ' ', '\\ "', "x\x0By";
  is_deeply( [ parse_cmdline( join ' ', 'prog', map { $q->($_) } @args ) ], [ 'prog', @args ], 'every one parses back' );
};

subtest 'win32: fds 0 to 2 not open (a process started without them) get the null device' => sub {
  plan skip_all => 'spawns the POSIX way' if $NATIVE_WIN32;
  my $lib = path( $INC{'Skilletor/Process.pm'} )->parent(2)->stringify;
  my $script = <<'END';
use strict; use warnings; use POSIX ();
use Skilletor::Process qw( run_command ); use SkilletorTest::Win32 qw( win32_os );
my ( $perl, $report ) = @ARGV;
POSIX::close($_) for 0 .. 2;
my $r = run_command( win32 => win32_os(), cmd => [ $perl, '-e', 'print "ok"' ] );
my $open = join ',', map { my $d = POSIX::dup($_); defined $d ? 'open' : 'closed' } 0 .. 2;
my $fd = POSIX::open( $report, POSIX::O_WRONLY() | POSIX::O_CREAT() | POSIX::O_TRUNC() ) // die;
my $text = "$r->{stdout} $open $fd";
POSIX::write( $fd, $text, length $text );
END
  my $report = $tmp->child('fds-report');
  my $r = run_command( cmd => [ $^X, "-I$lib", "-I$FindBin::Bin/lib", '-e', $script, "$bin/perl.exe", "$report" ] );
  is( $r->{stderr}, '', 'no complaint' );
  my ( $out, $open, $fd ) = split ' ', $report->slurp_raw;
  is( $out, 'ok', 'the child ran and its output was captured' );
  is( $open, 'open,open,open', 'fds 0 to 2 open afterwards' );
  cmp_ok( $fd, '>', 2, 'so a later open takes none of their numbers' );
};

subtest 'win32: spawn_detached' => sub {
  plan skip_all => 'records the start instead of starting' if $NATIVE_WIN32;
  my $os = win32_os();
  my %before = %ENV;
  ok( spawn_detached( win32 => $os, cmd => [ 'perl', 'a b', 'c' ], env => { Path => "$bin", ONLY => 'x' } ), 'started' );
  my ( $what, $program, $line, $env ) = @{ $os->{calls}[0] };
  is( $what, 'detach', 'by the detach primitive' );
  is( $program, "$bin/perl.exe", 'the program found on PATH' );
  is( $line, 'perl "a b" c', 'its command line' );
  is_deeply( $env, { Path => "$bin", ONLY => 'x' }, 'the given environment, while it starts' );
  is_deeply( \%ENV, \%before, 'ours afterwards' );
  ok( !spawn_detached( win32 => $os, cmd => ["$tmp/no-such-program"] ), 'no such program: false' );
  is( scalar @{ $os->{calls} }, 1, 'and nothing started' );
  my $failing = { detach => sub { 0 } };
  ok( !spawn_detached( win32 => $failing, cmd => ["$bin/perl.exe"] ), 'a start that fails: false' );
};

done_testing;
