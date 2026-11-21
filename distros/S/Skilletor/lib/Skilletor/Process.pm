package Skilletor::Process;
# ABSTRACT: Run a program without a shell – cwd, environment, timeout, captured output

use strict;
use warnings;

use Carp qw( croak );
use Cwd ();
use Errno ();
use Exporter qw( import );
use File::Spec ();
use IO::Handle ();
use IO::Select;
use POSIX ();
use Time::HiRes ();

our $VERSION = '0.008000';

our @EXPORT_OK = qw( run_command spawn_detached );

use constant WIN32 => $^O eq 'MSWin32';

# The creation flags of the detached spawn on Windows (WinBase.h).
use constant CREATE_NEW_PROCESS_GROUP => 0x0000_0200;
use constant CREATE_NO_WINDOW         => 0x0800_0000;

# Called, without arguments, each time the Windows path looks whether its child has ended
# (Skilletor::State's lock refreshes ride on it there).
our $ON_WAIT;

sub run_command {
  my ( %args ) = @_;
  my $cmd = $args{cmd} or croak __PACKAGE__.'->run_command needs cmd';
  my ( $file, @argv ) = @$cmd;

  my ( $stdin, $in_r, $in_w ) = ( $args{stdin} );
  if ( defined $stdin ) {
    $stdin = "$stdin";
    utf8::downgrade( $stdin, 1 ) or croak __PACKAGE__.'->run_command: stdin must be bytes';
  }
  if ( my $os = $args{win32} // ( WIN32 ? {} : undef ) ) {
    return _run_win32( $os, $file, \@argv, $stdin, %args );
  }
  if ( defined $stdin ) {
    pipe( $in_r, $in_w ) or croak 'pipe: '.$!;
  }
  pipe( my $out_r, my $out_w ) or croak 'pipe: '.$!;
  pipe( my $err_r, my $err_w ) or croak 'pipe: '.$!;
  pipe( my $exec_r, my $exec_w ) or croak 'pipe: '.$!;    # the child's exec errno, if any
  my $pid = fork;
  croak 'fork: '.$! unless defined $pid;
  if ( !$pid ) {
    close $_ for $out_r, $err_r, $exec_r;
    if ($in_r) {
      close $in_w;
      open( STDIN, '<&', $in_r ) or POSIX::_exit(127);
    }
    else {
      open( STDIN, '<', '/dev/null' );
    }
    open( STDOUT, '>&', $out_w ) or POSIX::_exit(127);
    open( STDERR, '>&', $err_w ) or POSIX::_exit(127);
    if ( defined $args{cwd} && length $args{cwd} ) {
      unless ( chdir $args{cwd} ) {
        syswrite $exec_w, 'chdir:'.( 0 + $! );
        POSIX::_exit(127);
      }
    }
    %ENV = %{ $args{env} } if $args{env};
    { no warnings 'exec'; exec {$file} $file, @argv; }
    syswrite $exec_w, 'exec:'.( 0 + $! );
    POSIX::_exit(127);
  }
  close $_ for $out_w, $err_w, $exec_w;

  # stdin goes in as the child takes it, between the reads: a child that writes a full pipe
  # before it reads stdin would otherwise wait on us while we wait on it.
  local $SIG{PIPE} = 'IGNORE';    # a child that exits without reading all of stdin
  my $pending = $stdin // '';
  my $wsel = IO::Select->new;
  if ($in_w) {
    close $in_r;
    if   ( length $pending ) { $in_w->blocking(0); $wsel->add($in_w) }
    else                     { close $in_w }
  }

  my %buf = ( out => '', err => '' );
  my $sel = IO::Select->new( $out_r, $err_r );
  my $deadline = defined $args{timeout_ms} ? Time::HiRes::time() + $args{timeout_ms} / 1000 : undef;
  my $timed_out = 0;
  while ( $sel->count ) {
    my $wait = defined $deadline ? $deadline - Time::HiRes::time() : undef;
    if ( defined $wait && $wait <= 0 ) {
      $timed_out = 1;
      kill 'TERM', $pid;
      last;
    }
    my ( $readable, $writable ) = IO::Select->select( $sel, ( $wsel->count ? $wsel : undef ), undef, $wait );
    for my $fh ( @{ $writable // [] } ) {
      my $n = syswrite $fh, $pending, 65536;
      next if !defined $n && ( $!{EINTR} || $!{EAGAIN} );
      substr( $pending, 0, $n, '' ) if defined $n;
      if ( !defined $n || !length $pending ) {    # all written, or the child closed its stdin
        $wsel->remove($fh);
        close $fh;
      }
    }
    my @ready = @{ $readable // [] };
    for my $fh (@ready) {
      my $n = sysread $fh, my $chunk, 65536;
      if ( !defined $n ) {
        next if $!{EINTR} || $!{EAGAIN};
        $n = 0;
      }
      if ( $n == 0 ) {
        $sel->remove($fh);
        next;
      }
      $buf{ $fh == $out_r ? 'out' : 'err' } .= $chunk;
    }
  }
  if ($timed_out) {
    # drain what is left without waiting on a child that ignores TERM for long
    my $grace = Time::HiRes::time() + 2;
    while ( $sel->count && Time::HiRes::time() < $grace ) {
      for my $fh ( $sel->can_read(0.1) ) {
        my $n = sysread $fh, my $chunk, 65536;
        if ( !$n ) { $sel->remove($fh); next }
        $buf{ $fh == $out_r ? 'out' : 'err' } .= $chunk;
      }
    }
    kill 'KILL', $pid if $sel->count;
  }
  close $_ for $out_r, $err_r, $wsel->handles;
  waitpid $pid, 0;
  my $status = $?;
  my $spawn_error;
  {
    local $/;
    my $msg = <$exec_r>;
    close $exec_r;
    if ( defined $msg && $msg =~ /\A(chdir|exec):(\d+)\z/ ) {
      local $! = $2;
      $spawn_error = { stage => $1, errno => 0 + $2, message => "$!" };
    }
  }
  return {
    code      => ( $status & 127 ) ? undef : $status >> 8,
    signal    => $status & 127,
    stdout    => $buf{out},
    stderr    => $buf{err},
    timed_out => $timed_out,
    ( $spawn_error ? ( spawn_error => $spawn_error ) : () ),
  };
}

# Start a program and leave it running on its own: a session of its own (setsid, so a kill of the
# caller's process group spares it), stdio on /dev/null, never waited for – the intermediate child
# that starts it exits at once, so no zombie is left behind. Node's spawn with `detached` and
# `stdio: "ignore"`, `unref()`ed. True when the program was started (its exec is not awaited).
sub spawn_detached {
  my ( %args ) = @_;
  my $cmd = $args{cmd} or croak __PACKAGE__.'->spawn_detached needs cmd';
  my ( $file, @argv ) = @$cmd;
  if ( my $os = $args{win32} // ( WIN32 ? {} : undef ) ) {
    my $detach  = $os->{detach} // \&_win32_detach;
    my $program = _win32_program( $file, _env_value( $args{env} // \%ENV, 'PATH' ) );
    return 0 if !defined $program || $program =~ /\.(?:bat|cmd)\z/i;
    my $line = join ' ', map { _win32_quote($_) } $file, @argv;
    return _with_env( $args{env}, sub { $detach->( $program, $line ) } ) ? 1 : 0;
  }
  my $pid = fork;
  return 0 unless defined $pid;
  if ( !$pid ) {
    POSIX::setsid();
    my $grandchild = fork;
    POSIX::_exit(1) unless defined $grandchild;    # no second fork: nothing started
    POSIX::_exit(0) if $grandchild;                # the intermediate goes, the program runs on
    open( STDIN,  '<', '/dev/null' );
    open( STDOUT, '>', '/dev/null' );
    open( STDERR, '>', '/dev/null' );
    %ENV = %{ $args{env} } if $args{env};
    { no warnings 'exec'; exec {$file} $file, @argv; }
    POSIX::_exit(127);
  }
  waitpid $pid, 0;
  return $? == 0 ? 1 : 0;
}

#### Windows ###########################################################
#
# No fork, no select() on pipes, no signals: the child's stdin, stdout and stderr are anonymous
# temp files (on Windows deleted once their last handle closes), put on fds 0 to 2 for the moment
# of a P_NOWAIT spawn; this process looks every few ms whether the child has ended, terminates it
# at the deadline, then reads what it wrote. What touches the system is in the primitives a test
# replaces ($args{win32}): spawn and detach; the rest runs on any system.

sub _run_win32 {
  my ( $os, $file, $argv, $stdin, %args ) = @_;
  my $spawn = $os->{spawn} // \&_win32_spawn;
  _std_fds();
  my $in;
  if ( defined $stdin ) {
    $in = _tmpfile();
    for ( my $off = 0; $off < length $stdin; ) {
      my $n = syswrite $in, $stdin, 65536, $off;
      croak 'write: '.$! unless defined $n;
      $off += $n;
    }
    sysseek( $in, 0, 0 ) or croak 'seek: '.$!;
  }
  else {
    open( $in, '<', File::Spec->devnull ) or croak 'open '.File::Spec->devnull.': '.$!;
  }
  my ( $out, $err ) = ( _tmpfile(), _tmpfile() );

  # The stages of the POSIX child, in its order: chdir, then the program – looked up with the
  # child's PATH, from the child's cwd.
  my $back;
  if ( defined $args{cwd} && length $args{cwd} ) {
    defined( $back = Cwd::getcwd() ) or croak 'getcwd: '.$!;
    chdir $args{cwd} or return _spawn_failed( chdir => 0 + $! );
  }
  my ( $pid, $errno );
  my $program = _win32_program( $file, _env_value( $args{env} // \%ENV, 'PATH' ) );
  if    ( !defined $program )              { $errno = Errno::ENOENT() }
  elsif ( $program =~ /\.(?:bat|cmd)\z/i ) { $errno = Errno::EINVAL() }    # never through cmd.exe, as Node
  else {
    my @line = map { _win32_quote($_) } $file, @$argv;
    ( $pid, $errno ) = _with_env( $args{env}, sub { _with_stdio( [ $in, $out, $err ], sub { $spawn->( $program, @line ) } ) } );
  }
  chdir $back if defined $back;
  return _spawn_failed( exec => $errno // 0 ) unless $pid;

  my $deadline = defined $args{timeout_ms} ? Time::HiRes::time() + $args{timeout_ms} / 1000 : undef;
  my ( $timed_out, $nap ) = ( 0, 0.001 );
  until ( waitpid $pid, POSIX::WNOHANG() ) {    # 0 while it runs
    $ON_WAIT->() if $ON_WAIT;
    my $left = defined $deadline ? $deadline - Time::HiRes::time() : undef;
    if ( defined $left && $left <= 0 ) {
      $timed_out = 1;
      kill 'KILL', $pid;    # TerminateProcess, what Node's timeout does there
      waitpid $pid, 0;
      last;
    }
    Time::HiRes::sleep( defined $left && $left < $nap ? $left : $nap );
    $nap *= 2 if $nap < 0.016;
  }
  my $status = $?;
  close $in;
  return {
    code      => ( $timed_out || ( $status & 127 ) ) ? undef : $status >> 8,
    signal    => $timed_out ? 15 : $status & 127,    # a timeout as Node reports it there: SIGTERM
    stdout    => _drain($out),
    stderr    => _drain($err),
    timed_out => $timed_out,
  };
}

# What the POSIX path returns for a child whose chdir or exec failed.
sub _spawn_failed {
  my ( $stage, $errno ) = @_;
  local $! = $errno;
  return { code => 127, signal => 0, stdout => '', stderr => '', timed_out => 0, spawn_error => { stage => $stage, errno => 0 + $errno, message => "$!" } };
}

sub _tmpfile {
  open( my $fh, '+>', undef ) or croak 'tmpfile: '.$!;
  binmode $fh;
  return $fh;
}

sub _drain {
  my ( $fh ) = @_;
  sysseek( $fh, 0, 0 ) or croak 'seek: '.$!;
  my $buf = '';
  1 while sysread $fh, $buf, 65536, length $buf;
  close $fh;
  return $buf;
}

# Run $code with %$env as the whole environment, when one is given.
sub _with_env {
  my ( $env, $code ) = @_;
  return $code->() unless $env;
  local %ENV = %$env;
  return $code->();
}

# fds 0 to 2 open – on the null device where one is not (a process started without standard
# handles, as the detached one on Windows) – so no temp file takes the number of one.
sub _std_fds {
  for my $fd ( 0 .. 2 ) {
    my $dup = POSIX::dup($fd);
    if ( defined $dup ) { POSIX::close($dup); next }
    my $null = POSIX::open( File::Spec->devnull, POSIX::O_RDWR() ) // next;
    next if $null == $fd;
    POSIX::dup2( $null, $fd );
    POSIX::close($null);
  }
}

# Run $code with fds 0, 1 and 2 on the given handles – what a child spawned meanwhile gets as its
# stdin, stdout and stderr (on Windows a dup2 onto them sets the standard handles) – then put back
# what they were. At the fd level, so STDIN, STDOUT and STDERR keep their PerlIO layers; flushed
# first, so nothing this process printed lands in the child's output.
sub _with_stdio {
  my ( $handles, $code ) = @_;
  $_->flush for \*STDOUT, \*STDERR;
  my @saved = map { POSIX::dup($_) } 0 .. 2;
  my @r;
  my $ok = eval {
    for my $fd ( 0 .. 2 ) {
      defined POSIX::dup2( fileno( $handles->[$fd] ), $fd ) or die 'dup2: '.$!."\n";
    }
    @r = $code->();
    1;
  };
  my $err = $@;
  for my $fd ( reverse 0 .. 2 ) {
    my $back = $saved[$fd] // POSIX::open( File::Spec->devnull, POSIX::O_RDWR() ) // next;
    POSIX::dup2( $back, $fd );
    POSIX::close($back);
  }
  die $err unless $ok;
  return @r;
}

# A variable of %$env as Windows looks it up: its name in any case.
sub _env_value {
  my ( $env, $name ) = @_;
  my ($key) = sort grep { uc($_) eq uc($name) } keys %$env;
  return defined $key ? $env->{$key} : undef;
}

# The program a Windows spawn starts, found as libuv finds it for Node's spawn, but never in the
# working directory first: a name with a directory part there (relative to the cwd), a bare name
# in each PATH entry; in each place the name as it is when it has an extension, then with .com,
# then with .exe appended. undef when there is none.
sub _win32_program {
  my ( $file, $path ) = @_;
  return undef unless defined $file && length $file;
  my ($name) = $file =~ m{([^/\\:]*)\z};
  my $has_ext = $name =~ /\.(?=.)/s;
  my @bases = $name ne $file
    ? ($file)
    : map { File::Spec->catfile( $_, $file ) } grep { length } map { s/\A"(.*)"\z/$1/sr } split /;/, $path // '';
  for my $base (@bases) {
    for my $try ( ( $has_ext ? $base : () ), "$base.com", "$base.exe" ) {
      return $try if -f $try;
    }
  }
  return undef;
}

# One argument of a Windows command line, so that the C runtime's parser (CommandLineToArgvW)
# reads it back as it is: libuv's quote_cmd_arg. As it is unless empty or holding whitespace or a
# quote; else in quotes, a quote escaped, the backslashes before a quote or the end doubled. Any
# whitespace quotes, not only space and tab: Perl's spawn would quote it otherwise.
sub _win32_quote {
  my ( $arg ) = @_;
  return '""' unless length $arg;
  return $arg unless $arg =~ /[ \t\n\x0B\f\r"]/;
  ( my $q = $arg ) =~ s/(\\*)"/$1$1\\"/g;
  $q =~ s/(\\+)\z/$1$1/;
  return qq{"$q"};
}

# The spawn: Perl's own P_NOWAIT spawn of the program found (passing fds 0 to 2 as the standard
# handles); the arguments come quoted, so Perl's command line keeps them as they are. A console
# of its own – when this process has none to share – stays hidden. The pid, else undef and errno.
sub _win32_spawn {
  my ( $program, @line ) = @_;
  my $shown = defined &Win32::SetChildShowWindow ? Win32::SetChildShowWindow(0) : undef;
  my $pid   = do { no warnings 'exec'; system { $program } 1, @line };
  my $errno = 0 + $!;
  if ( defined &Win32::SetChildShowWindow ) {
    defined $shown ? Win32::SetChildShowWindow($shown) : Win32::SetChildShowWindow();
  }
  return $pid > 0 ? $pid : ( undef, $errno );
}

# The detached spawn: no handle inherited – the hook's stdout must not stay open in a child that
# outlives it – in a process group of its own, with a console of its own that has no window, so
# neither it nor the programs it runs flash one. True when it was started.
sub _win32_detach {
  my ( $program, $line ) = @_;
  require Win32::Process;
  my $process;
  return Win32::Process::Create( $process, $program, $line, 0, CREATE_NEW_PROCESS_GROUP | CREATE_NO_WINDOW, '.' ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Process - Run a program without a shell – cwd, environment, timeout, captured output

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Process qw( run_command );

  my $r = run_command(
    cmd        => [ 'git', 'rev-parse', 'HEAD' ],
    cwd        => $dir,
    env        => \%env,          # the whole environment of the child
    timeout_ms => 60_000,
    stdin      => $bytes,         # optional; else stdin is /dev/null
  );
  print $r->{stdout} if defined $r->{code} && $r->{code} == 0;

=head1 DESCRIPTION

What the reference gets from Node's C<execFile>: a program and its arguments
as a list (never a shell), a working directory, a complete environment, a
timeout after which the child gets C<SIGTERM>, and stdout and stderr captured
as bytes. Nothing of the parent's state changes. Stdin is F</dev/null>, or a
pipe that gets C<stdin>'s bytes and then end of file, as C<execFileSync>'s
C<input> gives it.

On Windows (C<$^O> C<MSWin32>), which has no C<fork>, no C<select> on pipes
and no signals, the same calls take a path of their own, with the same
results: stdin, stdout and stderr are anonymous temp files, put on the
standard handles for the moment of a C<P_NOWAIT> spawn (C<system 1>) of the
program as Node would find it on C<PATH> (C<.com>, C<.exe>; never in the
working directory first, never a C<.bat> or C<.cmd>), with its arguments
quoted for the C runtime's command-line parser; the process is waited for
until the timeout, then terminated (C<TerminateProcess>) and reported as Node
reports it there, signal 15. A child that ends leaves its output read even if
a program it started still holds the handles.

=head2 run_command

  run_command( cmd => [...], cwd => $dir, env => \%env, timeout_ms => $ms, stdin => $bytes );

Returns C<< { code, signal, stdout, stderr, timed_out, spawn_error? } >>.
C<code> is C<undef> when a signal ended the child. C<spawn_error>
(C<< { stage => 'chdir' | 'exec', errno, message } >>) says the program never
ran: no such directory, no such program.

C<< win32 => { spawn => $code } >> takes the Windows path on any system, with
C<$code> in place of the spawn – C<< $code->( $program, @quoted_args ) >>
returns the pid, else C<undef> and errno – for a test. While the Windows path
waits it calls C<$Skilletor::Process::ON_WAIT>, when set, every few ms.

=head2 spawn_detached

  spawn_detached( cmd => [ $program, @args ], env => \%env );

Starts the program and returns without waiting for it: in a session of its
own, stdin, stdout and stderr on F</dev/null>, the given environment (default:
this process's). The background sync of the hooks runs this way. True when the
program was started; whether its C<exec> succeeded is not known.

On Windows it is C<Win32::Process::Create>, inheriting no handle (a hook's
stdout does not stay open in it), in a process group of its own and with a
console of its own that has no window, so neither it nor what it runs flashes
one. False there when there is no such program. C<< win32 => { detach =>
$code } >> takes this path on any system, C<< $code->( $program, $command_line ) >>
in place of the start, for a test.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
