package Proc::Topus;

use strict;
use warnings;

use Exporter;
use Socket;


our $VERSION = '0.02';

our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( spawn );


sub _CONDUIT () { 'socketpair' }
sub _PARENT  () { 0 }
sub _WORKER  () { 1 }
sub _READER  () { 0 }
sub _WRITER  () { 1 }


sub spawn {
  my $args = _args( @_ );

  my $workers = $args->{workers};
  die 'No workers defined'
    unless defined $workers && keys %$workers > 0;

  my $pairs = _alloc_pairs( $workers, $args->{conduit}, $args->{autoflush} );

  my %pids;
  for my $name ( keys %$workers ) {
    my $config = $workers->{$name};

    my $pid = fork;
    defined $pid
      or die 'fork: ', $!;

    $pids{$pid} = $name;
    next
      if $pid != 0;

    my @pairs = map { $_->[_WORKER] } @{ delete $pairs->{$name} };
    delete $pairs->{$_}
      for keys %$pairs;

    if( $config->{setsid} ) {
      require POSIX;
      POSIX::setsid()
        or die 'setsid: ', $!;
    }

    my $loader = $config->{loader};
    $loader->( @pairs )
      if ref $loader eq 'CODE';

    while( @pairs ) {
      my $pair = shift @pairs;

      my $pid = fork;
      defined $pid
        or die 'fork: ', $!;

      next
        if $pid != 0;

      splice @pairs;

      my $main = $config->{main};
      $main = sub { $pair }
        unless ref $main eq 'CODE';

      return $main->( @$pair[_READER, _WRITER] );
    }

    exit 0;
  }

  for my $name ( keys %$pairs ) {
    $pairs->{$name} = [
      map { { reader => $_->[_READER], writer => $_->[_WRITER] } }
        map { $_->[_PARENT] }
          @{ $pairs->{$name} }
    ];
  }

  _wait( \%pids );

  my $main = $args->{main};
  $main = sub { $pairs }
    unless ref $main eq 'CODE';

  $main->( $pairs )
}

sub _args {
  if( scalar @_ == 1 ) {
    unless( defined $_[0] && ref $_[0] eq 'HASH' ) {
      die "Single arguments must be a HASH ref";
    }

    return $_[0]
  }
  elsif( @_ % 2 ) {
    die "Odd number of arguments";
  }
  else {
    return { @_ };
  }
}

sub _alloc_pairs {
  my ( $workers, $_conduit, $_autoflush ) = @_;

  $_conduit = _CONDUIT
    unless defined $_conduit;

  $_autoflush = 1
    unless defined $_autoflush;

  my %pairs;
  for my $name ( keys %$workers ) {
    my $config = $workers->{$name};

    my $count = $config->{count};
    die "Invalid worker count ($name)"
      unless defined $count && $count > 0;

    my $conduit = $config->{conduit};
    $conduit = $_conduit
      unless defined $conduit;

    my $autoflush = $config->{autoflush};
    $autoflush = $_autoflush
      unless defined $autoflush;

    $pairs{$name} =
      [ map { _alloc_pair( $name, $conduit, $autoflush ) } 1 .. $count ];
  }

  \%pairs
}

sub _alloc_pair {
  my ( $name, $conduit, $autoflush ) = @_;

  if( $conduit eq 'socketpair' ) {
    socketpair my $ps, my $ws, AF_UNIX, SOCK_STREAM, PF_UNSPEC
      or die 'socketpair: ', $!;

    _autoflush( $autoflush, $ps, $ws );

    return _pair( $ps, $ps, $ws, $ws );
  }
  elsif( $conduit eq 'pipe' ) {
    pipe my $pr, my $ww
      or die 'pipe: ', $!;
    pipe my $wr, my $pw
      or die 'pipe: ', $!;

    _autoflush( $autoflush, $pr, $pw, $wr, $ww );

    return _pair( $pr, $pw, $wr, $ww );
  }

  die "Invalid worker conduit '$conduit' for worker '$name'";
}

sub _autoflush {
  return
    unless shift;

  my $fh = select;
  do { select $_; $| = 1 }
    for @_;
  select $fh
}

sub _pair {
  my ( $pr, $pw, $wr, $ww ) = @_;

  my $pp; @$pp[_READER, _WRITER] = ( $pr, $pw );
  my $wp; @$wp[_READER, _WRITER] = ( $wr, $ww );

  my $pair; @$pair[_PARENT, _WORKER] = ( $pp, $wp );
  $pair
}

sub _wait {
  my ( $pids ) = @_;

  my $errors = 0;

  until( keys %$pids == 0 ) {
    my $pid = waitpid -1, 0;
    die 'waitpid: ', $!
      if $pid == -1;

    my $name = delete $pids->{$pid};
    next
      unless defined $name;

    my $rc = $? >> 8;
    $errors++
      unless $rc == 0;
  }

  die "One or more loaders failed"
    if $errors;
}


1
__END__

=pod

=head1 NAME

Proc::Topus - Spawn worker processes with IPC built-in

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Proc::Topus qw( spawn );

  my $type = spawn({
    main    => sub {
      my ( $pairs ) = @_;

      for my $key ( keys %$pairs ) {
        for my $pair (@{ $pairs->{$key} }) {
          my $fh = $pair->{reader};

          my $in = <$fh>;
          chomp $in;

          print "Received '$in' from worker '$key'\n";
        }
      }

      for my $key ( keys %$pairs ) {
        for my $pair (@{ $pairs->{$key} }) {
          my $fh = $pair->{writer};

          print {$fh} "Hello, worker ($key)\n";
        }
      }

      return 'master';
    },

    conduit => 'pipe',

    workers => {
      foo => {
        count   => 2,
        conduit => 'socketpair',
        loader  => sub { print "In loader (foo)\n" },
        main    => sub { work( foo => @_ ) },
      },

      bar => {
        count   => 2,
        conduit => 'socketpair',
        loader  => sub { print "In loader (bar)\n" },
        main    => sub { work( bar => @_ ) },
      },
    },
  });

  print "Exiting from $type\n";


  sub work {
    my ( $type, $reader, $writer ) = @_;

    print {$writer} "Hello, master\n";

    my $in = <$reader>;
    chomp $in;

    print "Received '$in' from master\n";

    return "worker ($type)";
  }

=head1 DESCRIPTION

Proc::Topus spawns one or more worker processes from one or more
worker groups.  Each worker process is pre-allocated a pair of
filehandles for communicating with the initial master process.  An
intermediate loader process is also created in order to take
advantage of copy-on-write mechanisms, if present.

Workers are arranged in groups so that multiple different types of
worker processes may be spawned at the same time.  Each group of
workers can be configured independently of the others to allow for
maximum flexibility.  This includes configuring the number of workers,
the method in which the IPC filehandles are created and whether
or not autoflush is enabled.  These options may also be set globally
for all groups.

A double-fork method is used to spawn individual worker processes.
Initially a process is forked from the master process for each worker
group.  This intermediate process is used for loading worker-specific
modules or performing other tasks specific to the worker group.  Once
the loading operations have completed, a configured number of worker
processes are forked and the loader process exits.

=head1 EXPORTS

=head2 spawn( %args )

=head2 spawn( \%args )

The C<spawn()> function is the only thing exported from this module. It
is responsible for performing all of the forking operations.  C<%args>
may contain the following options:

=head3 main =E<gt> sub { ... }

This option specifies a sub-routine that will be run in the master
process once all loaders have completed.  It is passed a single
C<HASH> reference containing all of the IPC filehandles.  The
structure is similar to the following:

  {
    $name => [
      { reader => $rh, writer => $wh },
      ...
    ],
    ...
  }

The return value from this sub-routine is used as the return from
C<spawn()> in the master process.  This is intended to allow for
returning an application-specific data structure.

If this option is not present the same structure that would normally
be passed to the call-back is returned from C<spawn()>.

=head3 conduit =E<gt> $conduit

This option specifices the default way the IPC filehandles are created
for all worker groups.  This can either be C<'socketpair'> or C<'pipe'>.
If not present it defaults to C<'socketpair'>.

=head3 autoflush =E<gt> $autoflush

This options is a boolean value for controlling the default autoflush
behavior for the IPC filehandles for all worker groups.  When true,
autoflush is turned on.  When false, autoflush is turned off.  If not
present it defaults to true.

=head3 workers =E<gt> { $name =E<gt> \%config, ... }

This option specifies the configuration for the worker processes.  This
option is required.  Workers are grouped by C<$name> and each have their
own configuration.  C<%config> may contain the following options:

=head4 count =E<gt> $count

This option specifies the number of worker processes that will be
spawned.  It is required.

=head4 loader =E<gt> sub { ... }

This option specifies a sub-routine that is used as a call-back during
the loading phase.  This allows resources to be loaded before individual
worker processes are forked.  This can be used to take advantage of
copy-on-write features or to allocate resources that should be shared
amongst each worker process.

=head4 setsid =E<gt> $setsid

This option is a boolean value for controlling whether or not
C<POSIX::setsid()> is called during the loading phase.  If not
specified, C<setsid()> will not be called.

=head4 conduit =E<gt> $conduit

This option specifies the way the IPC filehandles are created for the
worker group.  This can either be C<'socketpair'> or C<'pipe'>.  If not
present, the global value will be used.  If no global value is specified
it defaults to C<'socketpair'>.

=head4 autoflush =E<gt> $autoflush

This option is a boolean value for controlling the autoflush behavior
for the IPC filehandles for the worker group.  When true, autoflush is
turned on.  When false, autoflush is turned off.  If not present, the
global value will be used.  If no global value is specified it defaults
to true.

=head4 main =E<gt> sub { ... }

This option specifies a sub-routine that will be run in the worker
process once it has been forked.  It is passed two parameters: the
read filehandle and the write filehandle.  The return value from
this sub-routine is used as the return from C<spawn()> in the worker
process.

If this option is not present the same filehandles are returned from
C<spawn()> as an C<ARRAY> reference with the read filehandle located
at index 0 and the write filehandle located at index 1.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2012-2014, jason hord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
