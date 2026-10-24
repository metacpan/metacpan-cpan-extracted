package Skilletor::Process;
# ABSTRACT: Run a program without a shell – cwd, environment, timeout, captured output

use strict;
use warnings;

use Carp qw( croak );
use Errno ();
use Exporter qw( import );
use IO::Select;
use POSIX ();
use Time::HiRes ();

our $VERSION = '0.001';

our @EXPORT_OK = qw( run_command );

sub run_command {
  my ( %args ) = @_;
  my $cmd = $args{cmd} or croak __PACKAGE__.'->run_command needs cmd';
  my ( $file, @argv ) = @$cmd;

  pipe( my $out_r, my $out_w ) or croak 'pipe: '.$!;
  pipe( my $err_r, my $err_w ) or croak 'pipe: '.$!;
  pipe( my $exec_r, my $exec_w ) or croak 'pipe: '.$!;    # the child's exec errno, if any
  my $pid = fork;
  croak 'fork: '.$! unless defined $pid;
  if ( !$pid ) {
    close $_ for $out_r, $err_r, $exec_r;
    open( STDIN, '<', '/dev/null' );
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
    my @ready = $sel->can_read($wait);
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
  close $_ for $out_r, $err_r;
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Process - Run a program without a shell – cwd, environment, timeout, captured output

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Process qw( run_command );

  my $r = run_command(
    cmd        => [ 'git', 'rev-parse', 'HEAD' ],
    cwd        => $dir,
    env        => \%env,          # the whole environment of the child
    timeout_ms => 60_000,
  );
  print $r->{stdout} if defined $r->{code} && $r->{code} == 0;

=head1 DESCRIPTION

What the reference gets from Node's C<execFile>: a program and its arguments
as a list (never a shell), a working directory, a complete environment, a
timeout after which the child gets C<SIGTERM>, and stdout and stderr captured
as bytes. Nothing of the parent's state changes.

=head2 run_command

  run_command( cmd => [...], cwd => $dir, env => \%env, timeout_ms => $ms );

Returns C<< { code, signal, stdout, stderr, timed_out, spawn_error? } >>.
C<code> is C<undef> when a signal ended the child. C<spawn_error>
(C<< { stage => 'chdir' | 'exec', errno, message } >>) says the program never
ran: no such directory, no such program.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
