package Shell::Run;

use strict;
use warnings;

use IPC::Open2;
use IO::Select;
use IO::String;
use File::Which;
use Carp;

use constant BLKSIZE => 1024;

our
	$VERSION = '0.04';

sub new {
	my $class = shift;
	my %args = @_;
	my @cmd;
	
	if ($args{exe}) {
		$cmd[0] = $args{exe};
	} else {
		my $name = $args{name} || 'sh';
		$cmd[0] = which $name;
	}	
	if (defined $args{args}) {
		push @cmd, @{$args{args}};
	} else {
		push @cmd, '-c';
	}
	my $shell;
	$shell->{shell} = \@cmd;
	$shell->{debug} = $args{debug};
	return bless $shell, $class;
}

sub run {
	my $self = shift;
	# command to execute
	my $cmd = shift;
	print STDERR "using shell: @{$self->{shell}}\n" if $self->{debug};
	print STDERR "executing cmd:\n$cmd\n" if $self->{debug};

	# cmd output, make $output an alias to the second argument
	our $output;
	local *output = \$_[0];
	$output = '';
	shift;

	# cmd input
	my $input = shift;
	my $inh = IO::String->new;
	$inh->open($input);
	print STDERR "have input data\n" if $self->{debug} && $input;

	# additional environment entries for use as shell variables
	my %env = @_;
	local %ENV = %ENV;
	$ENV{$_} = $env{$_} foreach keys %env;
	if ($self->{debug} && %env) {
		print STDERR "setting env variables:\n";
		print STDERR "$_=$env{$_}\n" foreach keys %env;
	}

	# start cmd
	my ($c_in, $c_out);
	$c_in = '' unless $input;
	my $pid = open2($c_out, $c_in, @{$self->{shell}}, $cmd);

	# ensure filehandles are blocking
	$c_in->blocking(1);
	$c_out->blocking(1);

	# create selectors for read and write filehandles
	my $sin = IO::Select->new;
	$sin->add($c_out);
	my $sout = IO::Select->new;
	$sout->add($c_in) if $input;

	# catch SIGPIPE on input pipe to cmd
	my $pipe_closed;
	local $SIG{PIPE} = sub {
		$pipe_closed = 1;
		print STDERR "got SIGPIPE\n" if $self->{debug};
	};

	print STDERR "\n" if $self->{debug};
	loop:
	while (1) {
		# get filehandles ready to read or write
		my ($read, $write) = IO::Select->select($sin, $sout, undef);
		
		# read from cmd
		foreach my $rh (@$read) {
			my $data;
			my $bytes =	sysread $rh, $data, BLKSIZE;
			unless (defined $bytes) {
				print STDERR "read from cmd failed\n" if $self->{debug};
				carp "read from cmd failed";
				return 1;
			}
			print STDERR "read $bytes bytes from cmd\n"
				if $self->{debug} && $bytes;
			$output .= $data;

			# finish on eof from cmd
			if (! $bytes) {
				print STDERR "closing output from cmd\n" if $self->{debug};
				close($rh);
				$sin->remove($rh);
				last loop;
			}
		}

		# write to cmd
		foreach my $wh (@$write) {
			# stop writing to input on write error / SIGPIPE
			if ($pipe_closed) {
				print STDERR "closing input to cmd as pipe is closed\n"
					if $self->{debug};
				close $wh;
				$sout->remove($wh);
				next loop;
			}

			# save position in case of partial writes
			my $pos = $inh->getpos;

			# try to write chunk of data
			my $data = $inh->getline;
			my $to_be_written = length($data) < BLKSIZE ?
				length($data) : BLKSIZE;
			print STDERR "writing $to_be_written bytes to cmd\n"
				if $self->{debug} && $data;
			my $bytes = syswrite $wh, $data, BLKSIZE;

			# write failure mostly because of broken pipe
			unless (defined $bytes) {
				print STDERR "write to cmd failed\n" if $self->{debug};
				carp "write to cmd failed";
				$pipe_closed = 1;
				next loop;
			}

			# log partial write
			print STDERR "wrote $bytes bytes to cmd\n"
				if $self->{debug} && $bytes < $to_be_written;
				
			# adjust input data position
			if ($bytes < length($data)) {
				$inh->setpos($pos + $bytes);
			}

			# close cmd input when data is exhausted
			if (eof($inh)) {
				print STDERR "closing input to cmd on end of data\n"
					if $self->{debug};
				close $wh;
				$sout->remove($wh);
			}
		}

	}

	# avoid zombies and get return status
	waitpid $pid, 0;
	my $status = $? >> 8;
	print STDERR "cmd exited with rc=$status\n\n" if $self->{debug};

	return !$status;
}

1;

# vi:ts=4:
__END__

=encoding utf8

=head1 NAME

Shell::Run - Execute shell commands using specific shell

=head1 SYNOPSIS

	use Shell::Run;
	
	my $bash = Shell::Run->new(name => 'bash');

	my ($input, $output);

	# input and output, status check
	$input = 'fed to cmd';
	$bash->run('cat', $output, $input) or warn('bash failed');
	print "output is '$output'\n";
	
	# no input
	$bash->run('echo hello', $output);
	print "output is '$output'\n";
	
	# use shell variable
	$bash->run('echo $foo', $output, undef, foo => 'var from env');
	print "output is '$output'\n";

	# use bash feature
	$bash->run('cat <(echo $foo)', $output, undef, foo => 'var from file');
	print "output is '$output'\n";

=head1 DESCIPTION
The C<Shell::Run> class provides an alternative interface for executing
shell commands in addition to 

=over

=item *
C<qx{cmd}>

=item *
C<system('cmd')>

=item *
C<open CMD, '|-', 'cmd'>

=item *
C<open CMD, '-|', 'cmd'>

=item *
C<IPC::Run>

=back

While these are convenient for simple commands, at the same
time they lack support for some advanced shell features.

Here is an example for something rather simple within bash that cannot
be done straightforward with perl:

	export passwd=secret
	key="$(openssl pkcs12 -nocerts -nodes -in somecert.pfx \
		-passin env:passwd)"
	signdata='some data to be signed'
	signature="$(echo -n "$signdata" | \
		openssl dgst -sha256 -sign <(echo "$key") -hex"
	echo "$signature"

As there are much more openssl commands available on shell level
than via perl modules, this is not so simple to adopt.
One had to write the private key into a temporary file and feed
this to openssl within perl.
Same with input and output from/to the script: one has to be
on file while the other may be written/read to/from a pipe.

Other things to consider:

=over

=item *
There is no way to specify by which interpreter C<qx{cmd}> is executed.

=item *
The default shell might not understand constructs like C<<(cmd)>.

=item *
perl variables are not accessible from the shell.

=back

Another challenge consists in feeding the called command
with input from the perl script and capturing the output at
the same time.
While this last item is perfectly solved by C<IPC::Run>,
the latter is rather complex and even requires some special setup to
execute code by a specific shell.

The class C<Shell::Run> tries to merge the possibilities of the
above named alternatives into one. I.e.:

=over

=item *
use a specific command interpreter e.g. C<bash> (or C<sh> as default
which does not make too much sense).

=item *
provide the command to execute as a single string, like in C<system()>

=item *
give access to the full syntax of the command interpreter

=item *
enable feeding of standard input and capturing standard output
of the called command 

=item *
enable access to perl variables within the called command

=back

Using the C<Shell::Run> class, the above given shell script example
might be implemented this way in perl:

	my $bash = Shell::Run->new(name => 'bash');

	my $passwd = 'secret';
	my $key;
	$bash->run('openssl pkcs12 -nocerts -nodes -in demo.pfx \
		-passin env:passwd', $key, undef, passwd => $passwd);
	my $signdata = 'some data to be signed';
	my $signature;
	$bash->run('openssl dgst -sha256 -sign <(echo "$key") -hex',
		 $signature, $signdata, key => $key);
	print $signature;

Quite similar, isn't it?

Actually, the a call to C<openssl dgst> as above was the very reason
to create this class.

Commands run by C<$sh->run> are by default executed via the C<-c> option
of the specified shell.
This behaviour can be modified by providing other arguments in the
constructor C<Shell::Run->new>.

Debugging output can be enabled in a similar way.

=head1 METHODS

=head2 Constructor


=head3 Shell::Run->new([name => I<shell>,] [exe => I<path>,] [args => I<arguments>,] [debug => I<debug>])

=over

=item I<shell>

The name of the shell interpreter to be used by the
created instance.
The executable is searched for in the C<PATH> variable.

This value is ignored if I<path> is given and defaults to C<sh>.

=item I<path>

The fully specified path to an executable to be used by
the created instance.

=item I<arguments>

If I<arguments> is provided, it shall be a reference to an array
specifying arguments that are passed to the specified shell.

The default is C<-c>.
Use a reference to an empty array to avoid this.

=item I<debug>

When I<debug> is set to true, calls to the C<run> method will print
debugging output to STDERR.

=back

=head2 Methods

=head3 $sh->run(I<cmd>, I<output>, [I<input>, [I<key> => I<value>, ...]])

=over

=item I<cmd>

The code that is to be executed by this shell.

=item I<output>

A scalar that will receive STDOUT from I<cmd>.
The content of this variable will be overwritten by C<$sh->run> calls.

=item I<input>

An optional scalar holding data that is fed to STDIN of I<cmd>

=item I<key> => I<value>, ...

A list of key-value pairs that are set in the environment of the
called shell.

=back

=head1 BUGS AND LIMITATIONS

There seems to be some race condition when the called script
closes its input file prior to passing all provided input
data to it.
Sometimes a SIGPIPE is caught and sometimes C<syswrite>
returns an error.
It is not clear if all situations are handled correctly.

Best efford has been made to avoid blocking situations
where neither reading output from the script
nor writing input to it is possible.
However, under some circumstance such blocking might occur.

=head1 SEE ALSO

For more advanced interaction with background processes see L<IPC::Run>.

=head1 AUTHOR

Jörg Sommrey

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, Jörg Sommrey. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
