package Proc::Hevy;

use strict;
use warnings;

use Carp;
use Errno qw( EWOULDBLOCK );
use IO::Pipe;
use IO::Select;
use Proc::Hevy::Reader;
use Proc::Hevy::Writer;


sub exec {
  my ( $class, @args ) = @_;

  confess 'Odd number of parameters'
    unless @args % 2 == 0;
  my %args = @args;

  confess 'command: Required parameter not defined'
    unless defined $args{command};

  if( ref( $args{command} ) =~ /^(?:CODE)?\z/ ) {
    $args{command} = [ $args{command} ];
  }
  elsif( ref( $args{command} ) ne 'ARRAY' ) {
    confess 'command: Must be an ARRAY reference';
  }

  ref( $args{stdin} ) =~ /^(?:ARRAY|CODE|GLOB)\z/
    or confess 'stdin: Must be one of ARRAY, CODE or GLOB reference'
      if exists $args{stdin} and ref $args{stdin};

  ref( $args{stdout} ) =~ /^(?:ARRAY|CODE|GLOB|SCALAR)\z/
    or confess 'stdout: Must be one of ARRAY, CODE, GLOB or SCALAR reference'
      if exists $args{stdout};

  ref( $args{stderr} ) =~ /^(?:ARRAY|CODE|GLOB|SCALAR)\z/
    or confess 'stderr: Must be one of ARRAY, CODE, GLOB or SCALAR reference'
      if exists $args{stderr};

  ref( $args{parent} ) eq 'CODE'
    or confess 'parent: Must be a CODE reference'
      if defined $args{parent};

  ref( $args{child} ) eq 'CODE'
    or confess 'child: Must be a CODE reference'
      if defined $args{child};

  $args{priority} = 0
    unless defined $args{priority};

  my $std_i = Proc::Hevy::Writer->new( stdin  => $args{stdin}  );
  my $std_o = Proc::Hevy::Reader->new( stdout => $args{stdout} );
  my $std_e = Proc::Hevy::Reader->new( stderr => $args{stderr} );

  # fork
  my $pid = fork;
  confess "fork: $!\n"
    unless defined $pid;

  if( $pid == 0 ) {
    # child

    # run callback, if needed
    $args{child}->( getppid )
      if defined $args{child};

    # set filehandles
    $std_i->child( \*STDIN,  0 );
    $std_o->child( \*STDOUT, 1 );
    $std_e->child( \*STDERR, 2 );

    # set process priority, if needed
    if( $args{priority} ) {
      my $priority = getpriority( 0, $$ );
      defined $priority
        or die "getpriority(): $$: $!\n";

      $priority += $args{priority};

      setpriority( 0, $$, $priority )
        or die "setpriority(): $$: $!\n";
    }

    # exec
    if( ref( $args{command}->[0] ) eq 'CODE' ) {
      my $sub = shift @{ $args{command} };
      $sub->( @{ $args{command} } );
      exit 0;
    }

    exec @{ $args{command} };
    warn "exec: $args{command}->[0]: $!\n";
    exit 1;
  }

  # parent

  # run callback, if needed
  $args{parent}->( $pid )
    if defined $args{parent};

  # set filehandles
  my ( $select_w, $select_r ) = ( IO::Select->new, IO::Select->new );

  my %handles = (
    $std_i->parent( $select_w ),
    $std_o->parent( $select_r ),
    $std_e->parent( $select_r ),
  );

  # loop
  while( $select_r->count or $select_w->count ) {
    my ( $readers, $writers ) = IO::Select->select( $select_r, $select_w );

    $handles{$_}->read
      for @$readers;

    $handles{$_}->write
      for @$writers;
  }

  # use waitpid() to avoid signal handlers
  my $rc = waitpid $pid, 0;
  confess "waitpid: $!"
    if $rc == -1;

  return $?;
}


1
__END__

=pod

=head1 NAME

Proc::Hevy - A heavyweight module for running processes synchronously

=head1 SYNOPSIS

  use Proc::Hevy;

  {
    my $status = Proc::Hevy->exec(
      command => 'cat',
      stdin   => "Useless use of cat\n",
      stdout  => \my $stdout,
      stderr  => \my $stderr,
    );
  }

  {
    my $status => Proc::Hevy->exec(
      command => [qw( cat - )],
      stdin   => [ 'Another useless use of cat' ],
      stdout  => my $stdout = [ ],
      stderr  => my $stderr = [ ],
    );
  }

  {
    my @stdin = qw( foo bar baz );
    my ( @stdout, @stderr );

    my $status => Proc::Hevy->exec(
      command => sub {
        while( <STDIN> ) {
          my ( $fh, $prefix )
            = $. % 2 == 0
            ? ( \*STDOUT, 'even' )
            : ( \*STDERR, 'odd'  )
          ;
          print {$fh} "$prefix :: $_";
        }
      },
      stdin   => sub { shift @stdin },
      stdout  => sub { push @stdout, $_[0] },
      stderr  => sub { push @stderr, $_[0] },
    );
  }

  {
    sub cat {
      my ( @files ) = @_;

      exec cat => '--', @files
    }

    my $status => Proc::Hevy->exec(
      command => [ \&cat, @ARGV ],
      stdin   => \*STDIN,
      stdout  => \*STDERR,
      stderr  => \*STDOUT,
    );
  }

  {
    # really useless use of cat
    my $status = Proc::Hevy->exec(
      command => 'cat </dev/null 1>/dev/null 2>/dev/null',
    );
  }

  {
    my $status = Proc::Hevy->exec(
      stdout => \*STDOUT,
      stderr => \*STDERR,

      priority => 10,

      command => sub {
        print "In child process ($$): command\n";
      },

      parent => sub {
        my ( $pid ) = @_;

        print "In parent process ($$): child=$pid\n";
      },

      child => sub {
        my ( $ppid ) = @_;

        print "In child process ($$): parent=$ppid\n";
      },
    );
  }

=head1 DESCRIPTION

Proc::Hevy is a simplistic module for spawning child
processes in a synchronous manner.  It provides a simple interface
for passing data to a process's C<STDIN> while also offering several
methods for buffering C<STDOUT> and C<STDERR> output.

=head1 METHODS

=head2 exec( %args )

C<exec()> starts a child process and buffers input and output
according to the given arguments.  Once the process exits, the
exit status (as in C<$?>) is returned.  C<%args> may contain
the following options:

=head3 command =E<gt> $command

=head3 command =E<gt> \@command

=head3 command =E<gt> \&code

=head3 command =E<gt> [ \&code, @args ]

Specifies the command to run.  The first form may expand shell
meta-characters while the second form will not.  Review the
documentation for C<exec()> for more information.  The third
form will run the given C<CODE> reference in the child process
and the fourth form does the same, but also passes in C<@args>
as arguments to the subroutine.  This option is required.

=head3 stdin =E<gt> $buffer

=head3 stdin =E<gt> \@buffer

=head3 stdin =E<gt> \&code

=head3 stdin =E<gt> \*GLOB

If specified, identifies a data source that will be used to
pipe data to the child process's C<STDIN> handle.  The first
form simply specifies a string of bytes to write.  The second
form will write each array element to the child one at a time
until the array is empty.  The third form will write whatever
string is returned by the given C<CODE> reference until C<undef>
is returned.  Both the second and third forms append the
current value of C<$\> if defined or C<"\n"> if not.  The
fourth form simply re-opens the child process's C<STDIN>
handle to the given filehandle allowing a pass-through effect.

If not specified, the child process's C<STDIN> handle is
re-opened to C<'/dev/null'> for reading.

=head3 stdout =E<gt> \$buffer

=head3 stdout =E<gt> \@buffer

=head3 stdout =E<gt> \&code

=head3 stdout =E<gt> \*GLOB

If specified, identifies a data destination that will be used
to pipe from the child process's C<STDOUT> handle.  The first
form will append all input into a single string.  The second
form will push C<$/>-delimited lines on the given array.  The
third form will call the given C<CODE> reference for each
C<$/>-delimited line passing the line in as a single argument.
The fourth form simply re-opens the child process's C<STDOUT>
handle to the given filehandle allowing a pass-through effect.

If not specified, the child process's C<STDOUT> handle is
re-opened to C<'/dev/null'> for reading.

=head3 stderr =E<gt> \$buffer

=head3 stderr =E<gt> \@buffer

=head3 stderr =E<gt> \&code

=head3 stderr =E<gt> \*GLOB

The options specified here are similar to the C<stdout>
options except that the child process's C<STDERR> handle
is affected.

=head3 parent =E<gt> \&code

If specified, the given C<CODE> reference is called in the
parent process after the C<fork()> is performed.  The child
process's PID is passed in as a single argument.

=head3 child =E<gt> \&code

If specified, the given C<CODE> reference is called in the
child process after the C<fork()> is performed.  The parent
process's PID is passed in as a single argument.

=head3 priority =E<gt> $delta

If specified, adjusts the child process's priority according
to the value specified.

=head1 BUGS

None are known at this time, but if you find one, please feel free
to submit a report to the author.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Proc::Lite>

=back

=head1 COPYRIGHT

Copyright (c) 2009-2014, jason hord

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
