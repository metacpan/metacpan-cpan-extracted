package Proc::Lite;

use strict;
use warnings;

use Carp;
use Proc::Hevy;

our $VERSION = '0.10';


sub new {
  my ( $class, @args ) = @_;

  confess 'Odd number of parameters'
    unless @args % 2 == 0;
  my %args = @args;

  confess 'command: Required parameter'
    unless defined $args{command};

  bless {
    command  => $args{command},
    stdin    => $args{stdin},
    stdout   => [ ],
    stderr   => [ ],
    status   => undef,
    parent   => $args{parent},
    child    => $args{child},
    priority => $args{priority},
  }, $class
}

sub exec {
  my ( $class, @command ) = @_;
  $class->new( command => \@command )->run;
}

sub run {
  my ( $self ) = @_;

  my $status = Proc::Hevy->exec(
    command  => $self->{command},
    stdin    => $self->{stdin},
    stdout   => $self->{stdout},
    stderr   => $self->{stderr},
    parent   => $self->{parent},
    child    => $self->{child},
    priority => $self->{priority},
  );

  $self->{status} = $status >> 8;

  $self
}

sub status  { my ( $self ) = @_; $self->{status} }

sub stdout  { my ( $self ) = @_; wantarray ? @{ $self->{stdout} } : $self->{stdout} }

sub stderr  { my ( $self ) = @_; wantarray ? @{ $self->{stderr} } : $self->{stderr} }

sub success { my ( $self ) = @_; $self->status == 0 }


1
__END__

=pod

=head1 NAME

Proc::Lite - A lightweight module for running processes synchronously

=head1 SYNOPSIS

  use Proc::Lite;

  {
    my $proc = Proc::Lite->new(
      command => 'cat -',
      stdin   => "Useless use of cat\n",
    );

    $proc->run;
  }

  {
    my $proc = Proc::Lite->new(
      command => [qw( cat - )],
      stdin   => [ 'Another useless use of cat' ],
    )->run;
  }

  {
    my @stdin = qw( foo bar baz );
    my $proc = Proc::Lite->new(
      command => sub { while( <STDIN> ) { print } },
      stdin   => sub { pop @stdin },
    )->run;
  }

  {
    my $proc = Proc::Lite->new(
      command => [ sub {
        my ( $ppid ) = @_;
        while( <STDIN> ) {
          print "$ppid: $_"
        }
      }, $$ ],
      stdin => \*STDIN,
    )->run;
  }

  {
    # really useless use of cat
    my $proc = Proc::Lite->exec(
      'cat </dev/null 1>/dev/null 2>/dev/null' );
  }

  {
    my $proc = Proc::Lite->exec( qw( ls -l ), @ARGV );
    if( $proc->success ) {
      print "success\n";
      print " => $_\n"
        for $proc->stdout;
    }
    else {
      print "failed: ", $proc->status, "\n";
      print " => $_\n"
        for $proc->stderr;
    }
  }

  {
    sub echo { print "$_\n" for @_ }

    my $proc = Proc::Lite->exec( \&echo, @ARGV );
  }

  {
    my $proc = Proc::Lite->new(
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
    )->run;
  }

=head1 DESCRIPTION

Proc::Lite is a lightweight, easy-to-use wrapper around
L<Proc::Hevy>.  It is meant to provide a simple interface
for common use cases.

=head1 CLASS METHODS

=head2 new( %args )

Creates a L<Proc::Lite> object.  The command given is
not executed at this time.  See the C<run()> method for actually
running the command.  C<%args> may contain the following options:

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

Specifies data that may be sent to the child process's C<STDIN>.
The first form simply sends the given string of bytes to the
child process.  The second form will write individual array
elements to the child process.  The third form will run the
given C<CODE> reference and write the return value to the child.
A value of C<undef> signals that no more input should be sent
to the child process.  The fourth form simply re-opens the
child's C<STDIN> handle to the given filehandle allowing a
pass-through effect.  If this option is not given, the
child's C<STDIN> will be reopened to C<'/dev/null'>.

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

=head2 exec( $command )

=head2 exec( @command )

=head2 exec( \&code, @args )

This is a simple wrapper method for calling C<new()> and
C<run()> in a single step.  The three forms correspond to
the ways C<new()>'s C<command> argument may be specified.

=head1 OBJECT METHODS

=head2 run

Runs the command specified in C<new()>.  It returns the
C<Proc::Lite> object so that it can be called in
conjunction with C<new()> (C<Proc::Lite-E<gt>new( ... )-E<gt>run>).

=head2 status

Returns the exit status from the process.

=head2 stdout

Returns the C<STDOUT> output from the child process.  In
list context, the output is returned as a list.  In scalar
context, an C<ARRAY> reference is returned.

=head2 stderr

Similar to C<stdout> except that the C<STDERR> output is returned.

=head2 success

Returns true if the process exited with a status of 0.  Otherwise
returns false.

=head1 BUGS

None are known at this time, but if you find one, please feel free
to submit a report to the author.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Proc::Hevy>

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
