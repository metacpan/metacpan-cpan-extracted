package Proc::Branch;

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %arg = (
        'branch' => 2,
        'sleep'  => 0,
        'debug'  => 0,
        'auto_merge' => 1,
        @_,
    );

    my $debug = $arg{debug};

    my @pid;
    if ( ( my $n = $arg{branch} - 1 ) > 0 ) {
        while ( $n >= 1 ) {
            my $pid = fork;
            if ( not defined $pid ) {
                carp "ERROR: cannot fork\n" if ( $debug );
                return;
            }
            elsif ( $pid == 0 ) {
                # child process
                print "INFO($class): Child process($$) launches.\n"
                    if ( $debug );
                $arg{proc} = int $n;
                return bless( \%arg, __PACKAGE__ );
            }
            else {
                # parent
                push @pid, $pid;
                $n--;
                sleep $arg{'sleep'};
            }
        }
    }

    print "INFO($class): Branching is completed.\n"
        if ( $debug );
    $arg{proc} = 0;
    $arg{pid} = \@pid;

    return bless( \%arg, $class );
}

sub proc {
    my $self = shift;
    return $self->{proc};
}

sub merge {
    my $self = shift;
    my $exit = shift || 0;

    $self->{auto_merge} = 0;

    my $debug = $self->{debug};

    if ( $self->{proc} ) {
        print "INFO(" . __PACKAGE__ . "): Child process($$) exits.\n"
            if ( $debug );
        exit($exit);
    }
    else {
        # waitpid
        for ( @{ $self->{pid} } ) {
            print "INFO(" . __PACKAGE__ . "): Waiting for child process($_).\n"
                if ( $debug );
            waitpid $_, 0;
        }
    }
}

sub pid {
    my $self = shift;
    my $proc = shift;

    return if ( !defined $proc or $proc < 1 );
    return $self->{pid}[$proc-1];
}

sub DESTROY {
    my $self = shift;
    if ( $self->{auto_merge} ) {
        $self->merge;
    }
}

1;
__END__

=head1 NAME

Proc::Branch - Creating Multiple Child Processes and Merging

=head1 SYNOPSIS

  use Proc::Branch;
  my $b = Proc::Branch->new( branch => 4 ); # 1 parent and 3 children
  my $procid = $b->proc;                    # serial number of the process
  print "I am processor $procid.\n";
  if ( $procid == 0 ) {
      print "I am the parent.\n";
      for ( 1 .. 3 ) {
          my $pid = $b->pid($_);            # PID of the children
          print "I have child $pid\n";
      }
  }
  $b->merge;                                # merging the branched processes
  $b = undef;                               # same as above

=head1 DESCRIPTION

This module branches the current process into multiple processes when
the object is created.  Internally, perl function "fork" is used.

=head1 METHODS

=over

=item new

C<new> is the constructor method. It has arguments shown below.

  $b = Proc::Branch(
      # default values
      'branch' => 2,     # number of branches including the parent process
      'sleep'  => 0,     # sleep time between forking
      'debug'  => 0,     # turn on to see detailed messages
      'auto_merge' => 1, # When the object is destroyed, it merges.
      # When auto_merge is turned off,
      # 'merge' should be called somewhere.
  );

=item proc

C<proc> returns serial number of the processes. Parent process is 0.

=item pid(I<serial_number>)

C<pid> returns process ID of the child with the I<serial_number>. When it
is called by a child process, C<undef> is returned.

=item merge

Branched processes are merged. If C<auto_merge> mode, you can simply
destroy the object to call this method.

=back

=head1 SEE ALSO

L<Proc::Fork>, L<Proc::Simple>

=head1 AUTHOR

In Suk Joung, E<lt>jmarch@hanmail.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by In Suk Joung

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
