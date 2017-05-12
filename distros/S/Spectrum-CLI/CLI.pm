#  Spectrum::CLI - a perl module for use with Spectrum's Command Line Interface
#  Copyright (C) 1999-2003  Dave Plonka
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

# $Id: CLI.pm,v 1.16 2003/12/16 15:50:04 dplonka Exp $
# Dave Plonka <plonka@doit.wisc.edu>

package Spectrum::CLI;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use IO::File;
use IO::Socket;
use IPC::Open2;
use File::Basename;
use POSIX qw(setsid);
use Sys::Hostname;

require Exporter;
require AutoLoader;

@Spectrum::CLI::ISA = qw(Exporter AutoLoader);
# convert the RCS revision to a reasonable Exporter VERSION:
'$Revision: 1.16 $' =~ m/(\d+)\.(\d+)/ && (( $Spectrum::CLI::VERSION ) = sprintf("%d.%03d", $1, $2));

sub new {
   my $class = shift;
   my $self = {};
   $self->{verbose} = 0;
   $ENV{CLISESSID} = $$; # default
   $ENV{CLIMNAMEWIDTH} = 1024; # default
   my $daemon; # absolute path to VnmShd
   while (@_) {
      if ('HASH' eq ref($_[0])) { # a hashref
	 $self->{verbose} = $_[0]->{verbose} || $_[0]->{Verbose};
	 $self->{Verbose} = $_[0]->{Verbose};
	 if (defined $_[0]->{CLISESSID}) {
            $ENV{CLISESSID} = $_[0]->{CLISESSID}
	 }
	 if ($_[0]->{CLIMNAMEWIDTH}) {
            $ENV{CLIMNAMEWIDTH} = $_[0]->{CLIMNAMEWIDTH}
	 }
	 if ($_[0]->{VNMSHRCPATH}) {
            $ENV{VNMSHRCPATH} = $_[0]->{VNMSHRCPATH}
	 }
	 if ($_[0]->{localhostname}) {
	    $self->{localhostname} = $_[0]->{localhostname}
	 }
	 if ($_[0]->{timeout}) {
	    $self->{timeout} = $_[0]->{timeout}
	 }
	 shift
      } else { # scalar
	 if (m|^/|) { # it's an absolute path
            $self->{dir} = shift
	 } else { # it's the VNM name
            $self->{vnm} = shift
	 }
      }
   }
   if ('' eq $self->{dir}) {
      if ($ENV{SPEC_ROOT}) {
         $self->{dir} = "$ENV{SPEC_ROOT}/vnmsh"
      } elsif ($ENV{SPECROOT}) {
         $self->{dir} = "$ENV{SPECROOT}/vnmsh"
      }
   }

   if ('' eq $self->{dir}) {
      warn "must set SPEC_ROOT/SPECROOT environment variable or pass full path to vnmsh directory to \"new\" method!\n" if $self->{verbose};
      return undef
   }

   if ('' eq $ENV{VNMSHRCPATH} && -f "$self->{dir}/.vnmshrc") {
      $ENV{VNMSHRCPATH} = "$self->{dir}/.vnmshrc"
   }

   # discover which vnmsh commands are available:
   my $entry;
   my $dir = $self->{dir}; # kludge since perl doesn't like this in a glob
   foreach $entry (<$dir/*>) {
      my $cmd =  basename $entry; 
      $cmd    =~ s/.exe$//;
      if ($cmd =~ m;VnmShd$;) {
	 $daemon = $entry;
      }
      next if $cmd =~ m;(Vnm|stop)Shd$;; # skip these executables
      push(@{$self->{command}}, $cmd) if (-f $entry && -x _)

   }
   warn "valid vnmsh commands: @{$self->{command}}\n" if $self->{Verbose};

   # We don't want the vnmsh/connect command to launch VnmShd for us...
   # This is because (as of this writing - Spectrum 5.0r1) the vnmsh/connect
   # command not setting the close-on-exec flag before fork(2)ing/exec(2)ing
   # a VnmShd process.  This causes our perl read from pipe to hang (since
   # the other end of the pipe is still open for writing until VnmShd
   # terminates - ugh.)
   #
   # Unfortunately we now have a race condition here: If VnmShd shuts down
   # (e.g. is stopped intentionally) between when we start it and when we
   # run vnmsh/connect (which will restart VnmShd), we could hang
   # indefinitely in the read on the pipe from vnmsh/connect.
   # Then, when this new VnmShd terminates (e.g. is stopped intentionally)
   # read(2) will return with EOF, and we'll think we have a successful
   # connection - even though VnmShd is no longer running.
   # Ugh.
   #
   # All is not lost though - that would be an unlikely chain of events.
   # It should be able to be avoided by starting VnmShd "manually" before
   # any Spectrum::CLI scripts are run, and then shutting VnmShd down until
   # you know that no Spectrum::CLI scripts are running.
   #
   # This could all be fixed by fcntl(fd, F_GETFD, 0) followed by
   # fcntl(fd, F_SETFD, FD_CLOEXEC | flags) in vnmsh/connect.
   #
   # In hindsight it probably wasn't such a good idea for Spectrum to have
   # vnmsh/connect launch VnmShd when its not already running.  This runs
   # counter to the Unix permissions mechanism since any old Spectrum user
   # could be running VnmShd and doing SSAPI I/O on behalf of other users.
   # (IMHO, VnmShd should be run by the Spectrum install user.)

   # { Check to see if VnmShd is running (and start it if it's not):

   # determine which port VnmShd is to use (by parsing the config file):
   {
      my $fh = new IO::File "<$ENV{VNMSHRCPATH}";
      if (!ref($fh)) {
         warn "open \"$ENV{VNMSHRCPATH}\", \"r\": $!\n" if $self->{verbose}
      } else {
         while (<$fh>) {
            next if (m/^\s*#/); # skip comments
            if (m/\s*vsh_tcp_port\s*=\s*(0x([0-9a-f]+)|(\d+))/i) {
	       $self->{port} = $2? hex($2) : $3
            }
         }
      }
      undef $fh;
   }

   my $s = new IO::Socket::INET (Proto => 'tcp',
				 PeerAddr =>
				    ($self->{localhostname}?
				       $self->{localhostname} : hostname),
				 PeerPort =>
				    ($self->{port}? $self->{port}: 7777));
   if (!ref($s)) {
      warn "no VnmShd (yet)...\n" if $self->{Verbose};
      # start VnmShd
      if ('' eq $daemon) {
         warn("$self->{dir}/VnmShd not found!\n") if $self->{verbose};
         return undef
      }
      my @command = ($daemon);
      # FIXME stat(2)/access(2) VnmShd
      warn "fork, exec @command...\n" if $self->{Verbose};
      my $pid = fork();
      die "fork: $!\n" if (-1 == $pid);
      if (0 == $pid) { # child
	 # dissociate child from parent
	 setsid() or die "setsid: $!\n";
	 # Hmm... perhaps I should daemonize properly by chdir(2)ing,
	 # and association STDIN, STDOUT, and STDERR with "/dev/null".
	 # For the time being I'd like to see error messages (if any), so 
	 # we'll leave it alone.  Besides this is no sloppier than how
	 # vnmsh/connect leaves things (when it launches VnmShd).
	 exec @command;
	 die "exec \"@command\": $!\n"
      } else { # parent
         warn "waiting a bit...\n" if $self->{Verbose};
	 sleep($self->{timeout}? $self->{timeout} : 5)
      }
   }
   undef $s;

   # }

   my @command = ('connect');
   push(@command, $self->{vnm}) if $self->{vnm};

   warn("dir: $self->{dir}\n" .
	"CLISESSID=$ENV{CLISESSID}\n" .
	"CLIMNAMEWIDTH=$ENV{CLIMNAMEWIDTH}\n" .
	"VNMSHRCPATH=$ENV{VNMSHRCPATH}\n") if $self->{Verbose};

   warn "@command...\n" if $self->{Verbose};
   my $fh = new IO::File "$self->{dir}/@command 2>&1 |";
   if (!ref($fh)) {
      warn("failed to pipe from \"@command\": $!\n") if $self->{verbose};
      return undef
   }
   @{$self->{results}} = <$fh>;
   $fh->close;
   $self->{status} = int($?/256);
   if (0 != $self->{status}) {
      warn("\"@command\" failed - exit status: ", $self->{status}, "\n") if $self->{verbose};
      return undef
   }

   bless($self, $class)
}

sub dir {
   my $self = shift;
   die unless ref($self);
   if (@_) {
      $self->{dir} = shift
   }
   $self->{dir}
}

sub verbose {
   my $self = shift;
   die unless ref($self);
   if (@_) {
      $self->{verbose} = shift
   } else {
      $self->{verbose}
   }
}

sub Verbose {
   my $self = shift;
   die unless ref($self);
   if (@_) {
      $self->{Verbose} = shift
   } else {
      $self->{Verbose}
   }
}

sub results {
   my $self = shift;
   die unless ref($self);
   @{$self->{results}}
}

sub status {
   my $self = shift;
   die unless ref($self);
   $self->{status}
}

sub AUTOLOAD {
   my $self = shift;
   my $call = $Spectrum::CLI::AUTOLOAD;
   $call =~ s/^.*:://;

   # There seems to be some problems with buffered I/O, let's flush it here
   # before we fork(2) any processes, just to be safe.
   flush STDOUT;
   flush STDERR;

   # There seems to be an intermittent problem with SIGPIPE being delivered.
   # Let's try to avoid that issue:
   my $saved_pipe_handler = $SIG{PIPE};
   $SIG{PIPE} = 'IGNORE';

   # { save the hashref, if one was passed, and remove it from the argument list
   my $hashref;
   my $n;
   for ($n=0; $n <= @_; $n++) {
      if ('HASH' eq ref($_[$n])) {
	 $hashref = splice(@_, $n, 1)
      }
   }
   # }

   my @command = (split(m/_/, $call), @_);

   if (!grep { $command[0] eq $_ } @{$self->{command}}) {
      die "Can't locate object method \"$call\""
   }

   warn "@command...\n" if $self->{Verbose};

   my $display = 1; # default to "display" commands such as "show" and "seek"
   if ('fetchall_arrayref' eq $command[0]) {
      $command[0] = 'show'
   } elsif ('show' ne $command[0] && 'seek' ne $command[0]) {
      $display = 0
   }

   my $fhin = new IO::File;
   die "IO::File->new failed: $!\n" unless ref($fhin);
   my $fh = new IO::File;
   die "IO::File->new failed: $!\n" unless ref($fh);
   my $pid = open2($fh, $fhin, $self->dir . "/@command 2>&1");
   print $fhin "y\n"; # answer 'y'es to "destroy model: are you sure ?", etc.

   if (!$display) {
      @{$self->{results}} = <$fh>;
      waitpid($pid, 0);
      $self->{status} = int($?/256);
      if (0 != $self->{status} && $self->{verbose}) {
	 warn @{$self->{results}}
      }
      $fh->close;
      $fhin->close;
      $SIG{PIPE} = $saved_pipe_handler;
      return wantarray? ($self->{status}, @{$self->{results}}) : !$self->{status}
   }

   # { parse the output of display commands:
   my @results;
   my $headings = <$fh>;
   @{$self->{results}} = ($headings);
   chomp $headings;
   my(@headings, @lengths);
   while ($headings) {
      $headings =~ s/^\s*(\S+)\s*//;
      push(@headings, $1);
      push(@lengths, length($&))
   }
   while (<$fh>) {
      push(@{$self->{results}}, $_);
      chomp;
      my $index = 1+$#results;
      my $start = 0; # position where this column starts
      my $lcv;
      for ($lcv = 0; $headings[$lcv]; $lcv++) {
	 my $val;
	 if ($lcv < $#headings) {
            $val = substr($_, $start, $lengths[$lcv]);
	    $start += $lengths[$lcv]
	 } else {
            $val = substr($_, $start)
	 }
	 if ($hashref) {
	    # skip columns that the caller didn't request...
	    next unless $hashref->{$headings[$lcv]}
	 }
	 $val =~ s/\s+$//;
         $results[$index]{$headings[$lcv]} = $val
      }
   }
   # }
   waitpid($pid, 0);
   $self->{status} = int($?/256);
   $fh->close;
   $fhin->close;
   if (0 != $self->{status} && $self->{verbose}) {
      warn @{$self->{results}}
   }

   $SIG{PIPE} = $saved_pipe_handler;
   wantarray? @results : \@results
}

sub DESTROY {
   my $self = shift;
   die unless ref $self;
   if ( $^O =~ /^(ms)?(dos|win(32|nt)?)/i ) {
      system($self->dir . "/disconnect >null 2>&1");
   } else {
      system($self->dir . "/disconnect >/dev/null 2>&1");
   }
}

1;
__END__

=head1 NAME

Spectrum::CLI - wrapper class for the Spectrum Command Line Interface

=head1 SYNOPSIS

  use Spectrum::CLI;

  see METHODS section below

=head1 DESCRIPTION

C<Spectrum::CLI> is class which intends to provide a convenient way to
invoke the various CLI commands of Spectrum Enterprise Manager from
within perl scripts.

In the author's estimation, the two primary benefits of
C<Spectrum::CLI> are:

=over 4

=item * the parsing of "show" command results

C<Spectrum::CLI> intelligently parses of the output of CLI "show"
commands.  That is, it will split apart the columnar values for you,
and return them as an array of hashes, each element representing one
line of output.

=item * the elimination of "SpecHex" numbers in scripts

Because of the aforementioned results parsing, it is now easy to
mention spectrum data objects by name rather than by their hexadecimal
Handle or Id.  For instance, the following one=liner will create a hash
of models by model name:

    map { $Model{$_->{MName}} = $_ } Spectrum::CLI->new->show_models;

This would subsequently enable one to refer to a model's handle
like this:

    my $handle = $Model{Universe}{MHandle};

In this way, scripts can be written which discover all SpecHex magic
numbers, and are, therefore, more readable and potentially more
portable/reusable amongst Spectrum installations.

=back

=head1 METHODS

=over 4

=item B<new> - create a new Spectrum::CLI object

   $obj = Spectrum::CLI->new([VNM_Name,]
                             [SPECROOT,]
                             [ {
                                [verbose => 1,]
                                [Verbose => 1,]
                                [CLISESSID => $sessid,]
                                [CLIMNAMEWIDTH => $width,]
                                [VNMSHRCPATH => $path,]
                                [localhostname => $localname,]
                                [timeout => $seconds,]
                             } ]);

  my $cli = new Spectrum::CLI;

This is the class' constructor - it returns a C<Spectrum::CLI> object
upon success or undef on failure.  Its arguments are optional, and may
occur in any order.  In general, it can be called with no arguments
unless the SPECROOT environment variable is not set, or one wishes to
connect to a SpectroSERVER on another host (i.e. the script is not
running on the VNM host).

The optional constructor arguments are:

=over 4

=item I<VNM name>

You may pass a string specifying the name of the VNM machine where the
SpectroSERVER to which you'd like to connect resides.  (This is passed
to the as the first argument to the "connect" command.)

=item I<SPECROOT value>

You may pass a string specifying the absolute path to the "vnmsh"
directory.  It should point to a directory which contains the "vnmsh"
sub-directory.  (It is not necessary to pass this argument if either
the SPECROOT or SPEC_ROOT environment variables are set.)

=item I<options hashref>

A hash reference may also be passed as an argument.  The hash can be
used to specify a number of options.  These include:

=over 4

=item I<verbose>

Passing { verbose => 1 } will cause the package to report errors from
the CLI commands to STDERR.  This feature can also be enabled by
calling the "verbose" object method with a non-zero argument after the
constructor returns successfully with that object.

=item I<Verbose>

Primarily for use while debugging, passing { Verbose => 1 } will cause
the package to report what it is doing, such as which CLI command it is
about to execute.  This feature can also be enabled by calling the
"Verbose" object method with a non-zero argument after the constructor
returns successfully with that object.

=item I<CLISESSID>

Passing { CLISESSID => value } will cause C<Spectrum::CLI> to use that
value as the session id.  Normally, in the absence of this option, the
perl script's process id is used.  Use of this option is discouraged
unless the default value is somehow problematic.

=item I<CLIMNAMEWIDTH>

Passing { CLIMNAMEWIDTH => value } will cause C<Spectrum::CLI> to use
that value as the model name width for CLI "show" commands. Normally,
in the absence of this option, the value 1024 is used.  Use of this
option is discouraged unless the default value is somehow
problematic.

=item I<VNMSHRCPATH>

Passing { VNMSHRCPATH => value } will cause C<Spectrum::CLI> to use
that value as the full path to the configuration file for the CLI.
Normally, in the absence of this option, the value "$SPECROOT/vnmsh/.vnmshrc"
is used.  Use of this option is discouraged unless the default value is
somehow problematic.

=item I<localhostname>

Passing { localhostname => value } will cause C<Spectrum::CLI> to use
that value as the IP address or resolvable hostname to determine whether
or not the local VnmShd is running.  (If VnmShd is not running, the
constructor will attempt to launch it.)
Normally, in the absence of this option, the return value from
Sys::Hostname::hostname is used.  Use of this option is discouraged unless
the default value is somehow problematic.  (That should probably never
happen as currently VnmShd seems to bind(2) and listen(2) at the address
associated with the system's hostname.)

=item I<timeout>

Passing { timeout => value } will cause C<Spectrum::CLI> to use
that value as the number of seconds to sleep before attempting to connect
to the VnmShd that it just launched.  If the VnmShd is already running
(when the constructor is called) this timeout is not used.  Perhaps in
the future this timeout will be use for other things as well.
Normally, in the absence of this option, the value of 5 seconds will be
used.  Use of this option is discouraged unless the default value is
somehow problematic.

=back

=back

=item B<show_*>

   # show_types:
   map { $Type{$_->{Name}} = $_ } $cli->show_types;

   # show_attributes:
   map {
      $UserAttr{$_->{Name}} = $_
   } $cli->show_attributes("mth=$Type{User}{Handle}");

   # ...

These methods invoke the CLI "show" command.  They return an array of
hashes where the hash keys are the column headings from the first line
of output of the corresponding CLI command, and the values are the
corresponding value in that column for the given row.

=item B<seek>

   @results = $obj->seek("attr=attribute_id,val=value",
			 [lh=landscape_handle]);

This method invokes the CLI "seek" command.  It returns values in a
like the "show" methods.

=item B<create_*>, B<destroy_*>, B<etc.>

   # create_model:
   $cli->create_model("mth=$Type{User}{Handle}",
            "attr=$UserAttr{Model_Name}{Id},val=joe",
            "attr=$UserAttr{User_Full_Name}{Id},val='Joe User'");

ALL of the other CLI commands are available as methods.  The return
value(s) of these methods differs markedly from that of the
aforementioned show_* or seek methods.  This is because these methods
do not normally produce columnar output, but instead produce messages
which sometimes include some useful piece of information.  For
instance, "create model" produces a message upon success, which
indicates the model handle of the create model.  The caller will nearly
always want to obtain that handle, which can be done by parsing the
returned values.  (See the C<results> method for a hint at how to do
this.)

In an array context these methods return an array in which the first
element is the exit status (i.e. zero indication success) of the
underlying CLI command.  The subsequent elements of the returned array
are the standard output and standard error (if any) lines produced by
the underlying CLI command.

In a scalar context these methods return non-zero if the command
succeeds, zero otherwise.

Regardless of the context in which they are invoked, these methods
cause the objects internal status and results to be set.  If it is more
convenient, these values can be retrieved using the C<status> and
C<results> methods rather than having to collect them as return
values.

=item B<dir>

   print $obj->dir;

this method returns the absolute path to the directory containing the
vnmsh commands.

=item B<verbose>

   $obj->verbose(1);
   print $obj->verbose;

This method returns a boolean value indicating whether or not
verbose behavior is currently turned on.

If a zero or non-zero argument is passed it will either clear or set
this feature, respectively. 

=item B<Verbose>

   $obj->Verbose(1);
   print $obj->Verbose;

This method returns a boolean value indicating whether or not "very
verbose" behavior is currently turned on.

If a zero or non-zero argument is passed it will either clear or set
this feature, respectively.

=item B<results>


   @results = $obj->results;

This method returns an array containing the results (standard output
and standard error) of the last vnmsh command that was executed.

The B<results> method is I<extremely> useful to determine things such as
the model handle of the model that was created by a call to B<create_model>.
For instance:

   if ($obj->create_model("mth=$T{User}{Handle}",
                "attr=$A{Model_Name}{Id},val=joe",
                "attr=$A{User_Full_Name}{Id},val='Joe User'")) {
      printf "created model: %s\n", model_handle($obj->results)
   }

   sub model_handle {
      my $mh;
      grep { m/(0x[0-9A-Fa-f]+)$/ && ($mh = $&)} @_;
      return $mh
   }

=item B<status>

   if (0 != ($status = $obj->status)) {
      printf("the previous vnmsh command failed: %d\n", $status)
   }

This method returns the exit status of the last vnmsh command that was
executed.

=back

=head1 IMPLEMENTATION

Spectrum::CLI is a perl AutoLoader.  As such, there is no explicit
definition of each method that corresponds to a CLI command.
Instead, this module "discovers" which commands are available in the
vnmsh directory, and invokes them based on the called method name as
determined at run time.

Theoretically, this has at least two advantages:

=over 4

=item *

If new CLI commands or options are ever introduced, they will
magically appear as part of this API and perhaps even behave as
expected.  This is especially likely if the output and return values
are like those of the current commands.

=item *

This module is relatively terse.  It would have been much more work to
create and maintain if a seperate method needed to be written for each
and command and argument combination.

=back

=head1 AUTHOR

Dave Plonka <plonka@doit.wisc.edu>

Copyright (C) 1999-2003  Dave Plonka.
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

perl(1).

=cut
