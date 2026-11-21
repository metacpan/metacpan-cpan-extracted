package SkilletorTest::ParityCLI;
# ABSTRACT: Both CLIs on one machine – the reference's bundle and bin/skilletor – for t/54-parity-cli.t

# A machine is a temp dir ${TMP}: home/, project/ (when there is one), cwd/, the git sources
# under git/ and the git configs that reach them. It is saved once and restored before each CLI's
# run, so both CLIs run in the very same paths and their bytes compare as they are – no path
# placeholder, the render-inputs hash, which covers the project dir, included. Each CLI runs as a
# user's would: a process of its own, an environment built from nothing as
# conformance/README.md (`cli`) says, this machine's real host, user and git.

use strict;
use warnings;

use Cwd ();
use Exporter qw( import );
use POSIX ();
use Path::Tiny qw( path tempdir );
use Time::HiRes ();
use Skilletor::FSUtil qw( encode_text );
use Skilletor::JSON qw( js_ordered js_stringify js_type );

our @EXPORT_OK = qw( skip_reason clis start_cli finish_cli run_cli save_machine restore_machine snapshot drive wait_for );

use constant CHECKOUT => path(__FILE__)->absolute->parent(4)->realpath;    # t/lib/SkilletorTest/ -> the checkout

my $BUNDLE = CHECKOUT->child( 'dist', 'skilletor.js' );

# A step's CLI that runs longer than this fails it (README: cli).
my $TIMEOUT_MS = 30_000;

sub now_ms { int( Time::HiRes::time() * 1000 ) }

# The first `node` on PATH, as an absolute path: a step may run with a PATH of its own.
sub _node {
  for my $dir ( split /:/, $ENV{PATH} // '' ) {
    next unless length $dir;
    my $node = "$dir/node";
    return Cwd::abs_path($node) if -f $node && -x _;
  }
  return undef;
}

# Why the two CLIs cannot run here, or undef.
sub skip_reason {
  return 'drives the CLIs through fork, exec and sh, which Windows does not have' if $^O eq 'MSWin32';
  return 'needs node on PATH: the reference CLI runs on it' unless defined _node();
  return "needs the reference CLI bundle $BUNDLE (a skilletor checkout; npm run build)" unless -f $BUNDLE;
  return undef;
}

# The two CLIs as argv prefixes, the reference first: [ name, prefix ]. The Perl CLI runs from
# this checkout's lib/, its dependencies from PERL5LIB (cli_env passes it on).
sub clis {
  return (
    [ ts   => [ _node(), "$BUNDLE" ] ],
    [ perl => [ $^X, '-I'.CHECKOUT->child('lib'), CHECKOUT->child( 'script', 'skilletor' )."" ] ],
  );
}

# The input placeholders of a conformance step (README: placeholders) replaced by the machine's
# paths.
sub concrete {
  my ( $text, $m ) = @_;
  my %p = ( HOME => $m->{home}, TMP => $m->{tmp}, ( $m->{project} ? ( PROJECT => $m->{project} ) : () ) );
  $text =~ s/\$\{(HOME|PROJECT|TMP)\}/$p{$1} \/\/ "\${$1}"/ge;
  return $text;
}

sub _concrete_deep {
  my ( $v, $m ) = @_;
  my $type = js_type($v);
  return concrete( $v, $m ) if $type eq 'string';
  return [ map { _concrete_deep( $_, $m ) } @$v ] if $type eq 'array';
  return js_ordered( map { ( $_ => _concrete_deep( $v->{$_}, $m ) ) } keys %$v ) if $type eq 'object';
  return $v;
}

# A step's environment, built from nothing (README: cli): the fixed variables, PERL5LIB when this
# run has one (the Perl CLI's dependencies), the machine's, then the step's – null unsets one.
sub cli_env {
  my ( $m, $step ) = @_;
  my %env = (
    PATH                => $ENV{PATH} // '',
    HOME                => $m->{home},
    CODEX_HOME          => "$m->{home}/.codex",
    GIT_CONFIG_GLOBAL   => "$m->{tmp}/gitconfig",
    GIT_CONFIG_NOSYSTEM => '1',
    LC_ALL              => 'C',
    ( defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : () ),
    %{ $m->{env} // {} },
  );
  for my $k ( keys %{ $step->{env} // {} } ) {
    my $v = $step->{env}{$k};
    if   ( defined $v ) { $env{$k} = encode_text( concrete( $v, $m ) ) }
    else                { delete $env{$k} }
  }
  return \%env;
}

# Start a step's CLI: argv after the prefix, cwd (default the project, else ${TMP}/cwd), env,
# stdin through a pipe (a string as its UTF-8 bytes, any other value as compact JSON), then end
# of file; with group, in a process group of its own, as Claude Code starts a hook (k251). Its own
# fork and exec, not Skilletor::Process: the port's process layer is under test.
sub start_cli {
  my ( $prefix, $m, $step ) = @_;
  my @cmd = ( @$prefix, map { encode_text( concrete( $_, $m ) ) } @{ $step->{argv} } );
  my $cwd = encode_text( defined $step->{cwd} ? concrete( $step->{cwd}, $m ) : $m->{project} // "$m->{tmp}/cwd" );
  my $env = cli_env( $m, $step );
  my $stdin =
      !exists $step->{stdin}                  ? ''
    : js_type( $step->{stdin} ) eq 'string' ? concrete( $step->{stdin}, $m )
    :                                         js_stringify( _concrete_deep( $step->{stdin}, $m ) );
  my $dir = tempdir;
  pipe( my $reader, my $writer ) or die "pipe: $!";
  my $t0  = now_ms();
  my $pid = fork // die "fork: $!";
  if ( !$pid ) {
    close $writer;
    setpgrp( 0, 0 ) if $step->{group};
    open STDIN,  '<&', $reader       or POSIX::_exit(126);
    open STDOUT, '>',  "$dir/stdout" or POSIX::_exit(126);
    open STDERR, '>',  "$dir/stderr" or POSIX::_exit(126);
    chdir $cwd or do { print STDERR "chdir $cwd: $!"; POSIX::_exit(126) };
    %ENV = %$env;
    exec { $cmd[0] } @cmd or print STDERR "exec $cmd[0]: $!";
    POSIX::_exit(127);
  }
  close $reader;
  {
    local $SIG{PIPE} = 'IGNORE';    # a CLI that reads no stdin may be gone already
    binmode $writer;
    print {$writer} encode_text($stdin);
    close $writer;
  }
  return { pid => $pid, dir => $dir, t0 => $t0, what => join( ' ', @cmd ) };
}

# Wait for a started CLI: { exit, stdout, stderr, t0, t1 } (bytes; t0, t1 epoch ms around the
# run), or { failed => why } for one that outlives the timeout or dies of a signal.
sub finish_cli {
  my ( $run, $timeout_ms ) = @_;
  my $deadline = now_ms() + ( $timeout_ms // $TIMEOUT_MS );
  my $done;
  while ( !( $done = waitpid( $run->{pid}, POSIX::WNOHANG() ) ) ) {
    if ( now_ms() > $deadline ) {
      kill 'KILL', $run->{pid};
      waitpid $run->{pid}, 0;
      return { failed => "$run->{what} outlived its timeout" };
    }
    Time::HiRes::sleep(0.01);
  }
  my $status = $?;
  my $t1 = now_ms();
  my %r = (
    t0     => $run->{t0},
    t1     => $t1,
    stdout => path( $run->{dir}, 'stdout' )->slurp_raw,
    stderr => path( $run->{dir}, 'stderr' )->slurp_raw,
  );
  return { %r, failed => "$run->{what} was killed by signal ".( $status & 127 ) } if $status & 127;
  return { %r, exit => $status >> 8 };
}

sub run_cli { finish_cli( start_cli(@_) ) }

# Wait until $test is true, at most $ms; true when it came.
sub wait_for {
  my ( $test, $ms ) = @_;
  my $deadline = now_ms() + $ms;
  until ( $test->() ) {
    return 0 if now_ms() > $deadline;
    Time::HiRes::sleep(0.005);
  }
  return 1;
}

# What a machine's run may change: everything under ${TMP} but the git sources (git/), which the
# CLIs only fetch from.
sub _entries { grep { $_->basename ne 'git' } path( $_[0]{tmp} )->children }

sub _copy {
  my ( $from, $to ) = @_;
  if ( -l $from ) { symlink( readlink($from), "$to" ) or die "symlink $to: $!"; return }
  if ( -d $from ) {
    path($to)->mkpath;
    _copy( $_, path( $to, $_->basename ) ) for path($from)->children;
    return;
  }
  path($from)->copy($to);
  chmod( ( stat $from )[2] & 07777, "$to" );
}

# Keep the machine as it is now, to start each CLI's run from.
sub save_machine {
  my ( $m ) = @_;
  my $saved = tempdir;
  _copy( $_, path( $saved, $_->basename ) ) for _entries($m);
  return $saved;
}

sub restore_machine {
  my ( $m, $saved ) = @_;
  for my $p ( _entries($m) ) { -d $p && !-l $p ? $p->remove_tree( { safe => 0 } ) : $p->remove }
  _copy( $_, path( $m->{tmp}, $_->basename ) ) for path($saved)->children;
}

# Everything a run may change, relative to ${TMP}: { files => { rel => bytes }, dirs => [ rel ],
# executables => [ rel ] }, the files' owner executable bits and every directory (an emptied one
# left behind shows). Left out, each because it must differ from one run to the next:
# - every `.git` directory – a cache's and a work tree's – git's own bytes: index stat data,
#   FETCH_HEAD and reflogs carry the run's times; a cache's checkout and its name are compared;
# - `sync.lock/` and what it leaves beside it (`sync.lock.*`): the owner record holds pid, host
#   and a random token (the lock itself is compared in the scenarios that hold it).
# Normalised: in last-check.json and session-cwd.json – the in-session check's marks and a
# session's cwd record, Date.now() when written – each epoch-ms number that lies in one of
# $windows ([ t0, t1, label ], first match wins) becomes the string "<label>", so a mark compares
# by the step that wrote it; any other number, one a case seeded, stays as it is.
sub snapshot {
  my ( $m, $windows ) = @_;
  my %snap = ( files => {}, dirs => [], executables => [] );
  my $walk;
  $walk = sub {
    my ( $dir, $rel ) = @_;
    for my $p ( sort { $a->basename cmp $b->basename } path($dir)->children ) {
      my $name = $p->basename;
      next if !length $rel && $name eq 'git';
      next if $name eq '.git';
      next if ( $name eq 'sync.lock' || index( $name, 'sync.lock.' ) == 0 ) && path($dir)->basename eq 'skilletor';
      my $r = length $rel ? "$rel/$name" : $name;
      if ( -d $p && !-l $p ) {
        push @{ $snap{dirs} }, $r;
        $walk->( $p, $r );
        next;
      }
      my $bytes = -l $p ? 'symlink -> '.readlink($p) : $p->slurp_raw;
      $bytes = _stamp( $bytes, $windows // [] ) if $name eq 'last-check.json' || $name eq 'session-cwd.json';
      $snap{files}{$r} = $bytes;
      push @{ $snap{executables} }, $r if !-l $p && ( stat $p )[2] & 0100;
    }
  };
  $walk->( $m->{tmp}, '' );
  return \%snap;
}

sub _stamp {
  my ( $bytes, $windows ) = @_;
  $bytes =~ s{(?<![\d.])(\d{12,14})(?![\d.])}{
    my $t = $1;
    my ($w) = grep { $t >= $_->[0] && $t <= $_->[1] } @$windows;
    $w ? qq("<$w->[2]>") : $t
  }ge;
  return $bytes;
}

# Run the steps in order with one CLI on the machine as it is: per step { id, result, snap } –
# the snapshot after it, each time stamp named by the step that wrote it.
sub drive {
  my ( $m, $prefix, $steps ) = @_;
  my ( @out, @windows );
  for my $step (@$steps) {
    my $result = run_cli( $prefix, $m, $step );
    push @windows, [ $result->{t0}, $result->{t1} // now_ms(), "step $step->{id}" ];
    push @out, { id => $step->{id}, result => $result, snap => snapshot( $m, \@windows ) };
  }
  return \@out;
}

1;
