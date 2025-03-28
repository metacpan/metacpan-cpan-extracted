package POSIX::Run::Capture;

use 5.016001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use POSIX::Run::Capture ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	SD_STDOUT
        SD_STDERR
) ],
		     'std' => [ qw(
	SD_STDOUT
        SD_STDERR
) ]    );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw();

our $VERSION = '1.05';

require XSLoader;
XSLoader::load('POSIX::Run::Capture', $VERSION);

use constant {
    SD_STDOUT => 1,
    SD_STDERR => 2
};

# Preloaded methods go here.
sub get_lines {
    my ($self, $fd) = @_;
    my @lines;

    $self->rewind($fd);
    while (my $s = $self->next_line($fd)) {
	push @lines, $s;
    }
    return \@lines;
}

sub set_argv {
    my $self = shift;
    $self->set_argv_ref([@_]);
}

sub set_env {
    my $self = shift;
    $self->set_env_ref([@_]);
}

1;
__END__
=head1 NAME

POSIX::Run::Capture - run command and capture its output

=head1 SYNOPSIS

  use POSIX::Run::Capture;

  $obj = new POSIX::Run::Capture(argv => [ $command, @args ],
 			         program => $prog,
                                 env => [ @environment ],
			         stdin => $fh_or_string,
			         stdout => $ref_or_string,
			         stderr => $ref_or_string,
			         timeout => $n);
  $obj->run;

  $num = $obj->errno;
  $num = $obj->status;
  $num = $obj->length($chan);
  $num = $obj->nlines($chan);

  $str = $obj->next_line($chan);
  $aref = $obj->get_lines($chan);
  $obj->rewind($chan)

  $obj->set_argv(@argv);  
  $obj->set_program($prog);
  $obj->set_env(@argv);  
  $obj->set_timeout($n);
  $obj->set_input($fh_or_string);

  $aref = $obj->argv;
  $str = $obj->program
  $aref = $obj->env;
  $num = $obj->timeout;
    
=head1 DESCRIPTION

Runs an external command and captures its output. Both standard error and
output can be captured. Standard input can be supplied as either a
filehandle or a string. Upon exit, the captured streams can be accessed line
by line or in one chunk. Callback routines can be supplied that will be
called for each complete line of output read, providing a way for synchronous
processing. 

This module is for those who value performance and effectiveness over
portability. As its name suggests, it can be used only on POSIX systems.
    
=head2 new POSIX::Run::Capture

Creates a new capture object. There are three possible invocation modes.

  new POSIX::Run::Capture(argv => [ $command, @args ],
 			  program => $prog,
                          env => [ @environment ],
			  stdin => $fh_or_string,
			  stdout => $ref_or_string,
			  stderr => $ref_or_string,
			  timeout => $n)

When named arguments are used, the following keywords are allowed:

=over 4

=item B<argv>

Defines the command (B<C argv[0]>) and its arguments. In the absense of
B<program> argument, B<$argv[0]> will be run.

=item B<program>

Sets the pathname of binary file to run.	

=item B<env>

Defines execution environment.  By default, environment variables are
inherited from the calling process.    
    
=item B<stdin> or B<input>

Supplies standard input for the command. The argument can be a string or
a file handle.

=item B<stdout> =E<gt> I<$coderef>

Sets the I<line monitor> function for standard output. Line monitor is
invoked each time a complete line is read, or the EOF is hit on the standard
output. The acquired line is passed to the monitor as its argument. The
following example monitor function prints its argument to STDOUT:

    sub stdout_monitor {
        my $line = shift;
        print $line;
    }

Notice that the last line read can lack the teminating newline character.

=item B<stdout> =E<gt> I<FH>

Redirect standard output to file handle I<FH>.  Obviously, the handle should
be writable.
    
=item B<stdout> =E<gt> I<NAME>

Capture standard output and write it to the file I<NAME>.  If the file
exists, it will be truncated.  Otherwise, it will be created with permissions
of 0666 modified by the process' "umask" value.    

=item B<stderr> =E<gt> I<$arg>

Sets the I<line monitor> function for standard error or redirects it to
the file handle or file, depending on the type of I<$arg> (CODE reference,
GLOB or scalar string).  For details, see the description of B<stdout> above.

=item B<timeout>

Sets execution timeout, in seconds. If the program takes longer than B<$n>
seconds to terminate, it will be forcibly terminated (by sending the B<SIGKILL>
signal).

=back
    
=head3 new POSIX::Run::Capture([ $command, @args ]);

A simplified way of creating the object, equivalent to

   new POSIX::Run::Capture(argv => [ $command, @args ]);

=head3 new POSIX::Run::Capture;

Crates an empty capture object.

Whatever constructor is used, the necessary parameters can be set
or changed later, using B<set_argv>, B<set_program>, B<set_env>, B<set_input>,
and B<set_timeout>.

Monitors and redirections can be defined only when creating the object.

=head2 Modifying the object.

The following methods modify the object:    

=head3 $obj->set_argv(@argv)

Set arguments array.    
    
=head3 $obj->set_program($prog)

Sets the pathname of the command to run.

=head3 $obj->set_env(@env)

Set environment variables.    
    
=head3 $obj->set_timeout($n)

Sets runtime timeout, in seconds.

=head3 $obj->set_input($fh_or_string)

Sets standard input for the program. Argument must be either a filehandle
open for reading or a string. The filehandle will be repositioned to its
beginning prior to use.

=head2 Accessors

The following accessors return parameters associated with the object:    
    
=head3 $obj->argv

Returns a reference to the B<argv> array associated with the object.

=head3 $obj->program

Returns the pathname of the executable program.

=head3 $obj->env

Returns a reference to the array of environment variables.    
    
=head3 $obj->timeout

Returns the runtime timeout or B<0> if no timeout is set.

=head2 Running the command
    
=head3 $obj->run

Runs the program. Returns B<1> on successful termination, B<0> otherwise.

=head3 $obj->errno

If the last call to B<run> returned false, this method returns the
value of the system error number (the C B<errno> variable).

Upon successful return from B<$obj-E<gt>run>, the following accessors can
be used:    
    
=head3 $obj->status

Returns the termination status of the program. Use the macros from
B<POSIX :sys_wait_h> to analyze it. E.g.:

    use POSIX qw(:sys_wait_h);
    if ($obj->run()) {
        if (WIFEXITED($obj->status)) {
            print "program "
                  . $obj->program
                  . " terminated with code "
                  . WEXITSTATUS($obj->status);
        } elsif (WIFSIGNALED($self->status)) {
            print "program "
                  . $obj->program
                  . " terminated on signal "
                  . WTERMSIG($obj->status);
        } else {
            print "program "
                  . $obj->program
                  . " terminated with unrecogized code "
                  . $obj->status;
        }
    }

=head3 $obj->nlines($chan)

Returns number of lines saved in output channel B<$chan> (1 for stdout or 2
for stderr). You can also use symbolic constants B<SD_STDOUT> and
B<SD_STDERR>, if you require the module as

    use POSIX::Run::Capture qw(:std);

=head3 $obj->length($chan)

Returns total length in bytes of data captured in output channel B<$chan>.

=head3 $obj->next_line($chan)

Returns next line from the captured channel B<$chan>.

=head3 $obj->get_lines($chan)

Returns a reference to an array of lines captured from channel B<$chan>.    
    
=head3 $obj->rewind($chan)

Rewinds the captured channel B<$chan> to its beginning.

=head1 EXPORT

None by default.  Use B<:std> or B<:all> to export the constants
B<SD_STDOUT> and B<SD_STDERR>, which correspond to the numbers of
standard output and error channels.

=head1 AUTHOR

Sergey Poznyakoff, E<lt>gray@gnu.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2024 by Sergey Poznyakoff

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

It is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this library. If not, see <http://www.gnu.org/licenses/>.    

=cut
