package VCP::Logger;

=head1 NAME

VCP::Logger - Update message, bug, and Log file management

=head1 SYNOPSIS

   use VCP::Logger qw( shell_quote );

=head1 DESCRIPTION

Does not throw exceptions or use the debug module, so this is safe to
use with both.  Load this as the very first module in your program.

The log file name defaults to "vcp.log", set the environment
variable VCPLOGFILE to change it.  Here's how to do this in your
program:

   BEGIN {
      $ENV{VCPLOGFILE} = "foo.bar"
         unless defined $ENV{VCPLOGFILE} || length $ENV{VCPLOGFILE};
   }

=cut

@EXPORT_OK = qw(
   BUG
   lg
   lg_fh
   log_file_name
   pr
   program_name
   start_time
);

@ISA = qw( Exporter );
use Exporter;

use strict ;
use Carp;
use File::Basename qw( basename );

use constant program_name => basename $0;
use constant log_file_name => 
   defined $ENV{VCPLOGFILE} && length $ENV{VCPLOGFILE}
      ? $ENV{VCPLOGFILE}
      : "vcp.log";

my $quiet_mode = 0;

=head1 FUNCTIONS

=over

=item lg

Prints a timestamped message to the log.  Adds a trailing newline if
need be.  The first word of the message should not be capitalized
unless it's a name or acronym; this makes grepping a bit easier
(same for all error messages).

"lg" is "log" abbreviated so as not to conflict with Perl's builtin
log().

The timestamps are in integer seconds since this module was compiled
unless you have Time::HiRes install in which case they are in floating
point seconds.

Should not throw an exception or alter $@ in the normal course of events
(does not call any routines that should do so).

=cut

my $start_time;

## We "gracefully" degrade to 1 second resolution if no Time::HiRes.
BEGIN { eval "use Time::HiRes qw( time )" }

BEGIN {
   $start_time = time;
}

{
   my $s1;  BEGIN { $s1 = program_name . ": " }

   sub _msg {
      my $msg = join "", map defined $_ ? $_ : "(((UNDEF)))", @_;
      1 while chomp $msg;
      $msg =~ s/^$s1//o; ## TODO: go 'round and get rid of all the vcp: prefixes
      join $msg, $s1, "\n";
   }

   my $log_failure_warned;

   sub _lg {
      print LOG (
         sprintf( "%f ", time - $start_time ),
         @_
      ) or $log_failure_warned++
         or warn "$! writing ", program_name, " log file ", log_file_name, "\n";
   }

}


sub lg {
  _lg &_msg;
}

=item lg_fh

Returns a reference to the log filehandle (*LOG{IO}) so you can emit
to the log directly.  The log is flushed after every write, so this should
be quite safe.

=cut

sub lg_fh { *LOG{IO} }

=item pr

Emit a status notification to STDERR (unless in quiet mode) and log it.

=cut

sub pr {
   my $msg = &_msg;
   print STDERR $msg unless $quiet_mode;
   _lg $msg;
}


BEGIN {
   open LOG, ">>" . log_file_name or die "$!: " . log_file_name . "\n";

   ## Flush the LOG every print() so that we never miss data and
   ## so that we can pass the log to child processes to emit STDOUT
   ## and STDERR to.
   select LOG;
   $| = 1;
   select STDOUT;

   ## Print a header line guaranteed to start at the beginning of a
   ## line.
   print LOG "\n", "#" x 79, "\n";
   lg "started ",
      scalar localtime $start_time,
      " (",
      scalar gmtime $start_time,
      " GMT)";
}

END {
   lg "ended";
}

=item BUG

Reports a bug using Carp::confess and logging the information.

=cut

sub BUG {
   print STDERR "***BUG REPORT***\n", @_, "\n";
   print STDERR "Please see ", log_file_name, "\n";
   print LOG "***BUG REPORT***\n", @_, "\n";

   open STDOUT, ">&LOG" or warn "$! redirecting STDOUT to LOG\n";
   open STDERR, ">&LOG" or warn "$! redirecting STDOUT to LOG\n";
   system $^X, "-V" and warn "$! getting perl -V\n";
   require Carp;
   eval { Carp::confess "stack trace" };
   warn $@;

   exit 1;
}

=item start_time

Returns the time the application started.  This is a floating point
number if Time::HiRes was found.

=cut

sub start_time() { $start_time }

=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=cut

1 ;
