package Shell::Run;

use strict;
use warnings;

use Exporter::Tiny;
use IPC::Open2;
use IO::Select;
use IO::String;
use File::Which;
use Carp;

use constant BLKSIZE => 1024;

our
	$VERSION = '0.08';

our @ISA = qw(Exporter::Tiny);

sub new {
	my $class = shift;
	my @cmd;
	
	my $shell = _get_shell(@_);
	return bless $shell, $class;
}

sub _exporter_expand_sub {
	my $class = shift;
	my ($name, $args, $globals) = @_;
	my $as = $args->{as} || $name;
	croak "$as: not a valid subroutine name" unless $as =~ /^[a-z][\w]*$/;
	my $shell = $class->new(name => $name, %$args);
	return ($as => sub {return $shell->run(@_);});
}

sub _get_shell {
	my %args = @_;
	my @cmd;
	
	if ($args{exe}) {
		croak "$args{exe}: not an excutable file" unless -x $args{exe};
		$cmd[0] = $args{exe};
	} else {
		my $name = $args{name} || 'sh';
		$cmd[0] = which $name;
		croak "$name: not found in PATH" unless $cmd[0];
	}	

	if (defined $args{args}) {
		push @cmd, @{$args{args}};
	} else {
		push @cmd, '-c';
	}

	my $shell;
	$shell->{shell} = \@cmd;
	$shell->{debug} = $args{debug};
	return $shell;
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

	return ($status, !$status);
}

1;

# vi:ts=4:
__END__

=encoding utf8

=head1 NAME

Shell::Run - Execute shell commands using specific shell

=head1 SYNOPSIS

=head2 Procedural Interface

	use Shell::Run 'sh';
	my ($input, $output, $rc, $sc);

	# no input
	sh 'echo -n hello', $output;
	print "output is '$output'\n";
	# gives "output is 'hello'"

	# input and output, status check
	$input = 'fed to cmd';
	sh 'cat', $output, $input or warn 'sh failed';
	print "output is '$output'\n";
	# gives "output is 'fed to cmd'"
	
	# insert shell variable
	sh 'echo -n $foo', $output, undef, foo => 'var from env';
	print "output is '$output'\n";
	# gives "output is 'var from env'"

	# special bash feature
	use Shell::Run 'bash';
	bash 'cat <(echo -n $foo)', $output, undef, foo => 'var from file';
	print "output is '$output'\n";
	# gives "output is 'var from file'"

	# change export name
	use Shell::Run 'sea-shell.v3' => {as => 'seash3'};
	seash3 'echo hello', $output;

	# specify program not in PATH
	use Shell::Run sgsh => {exe => '/opt/shotgun/shell'};
	sgsh 'fire', $output;

	# not a shell
	use Shell::Run sed => {args => ['-e']};
	sed 's/fed to/eaten by/', $output, $input;
	print "output is '$output'\n";
	# gives "output is 'eaten by cmd'"

	# look behind the scenes
	use Shell::Run sh => {debug => 1, as => 'sh_d'};
	sh_d 'echo -n', $output;
	# gives:
	## using shell: /bin/sh -c
	## executing cmd:
	## echo -n
	##
	## closing output from cmd
	## cmd exited with rc=0

	# remove export
	no Shell::Run qw(seash3 sgsh);
	# from here on seash3 and sgsh are no longer known
	# use aliased name (seash3) if provided!

	# capture command status code
	($sc, $rc) = sh 'exit 2';
	# status code $sc is 2, return code $rc is false


=head2 OO Interface

	use Shell::Run;

	my $bash = Shell::Run->new(name => 'bash');

	my ($input, $output);

	# input and output, status check
	$input = 'fed to cmd';
	$bash->run('cat', $output, $input) or warn('bash failed');
	print "output is '$output'\n";
	
	# everything else analogous to the procedural interface
	
=head1 DESCIPTION

The Shell::Run module provides an alternative interface for executing
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
L<IPC::Run>

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
While this last item is perfectly solved by L<IPC::Run>,
the latter is rather complex and even requires some special setup to
execute code by a specific shell.

The module Shell::Run tries to merge the possibilities of the
above named alternatives into one. I.e.:

=over

=item *
use a specific command interpreter e.g. C<bash>.

=item *
provide the command to execute as a single string, like in C<system()>

=item *
give access to the full syntax of the command interpreter

=item *
enable feeding of standard input and capturing standard output
of the called command 

=item *
enable access to perl variables within the called command

=item *
easy but flexible usage

=back

Using the Shell::Run module, the above given shell script example
might be implemented this way in perl:

	use Shell::Run 'bash';

	my $passwd = 'secret';
	my $key;
	bash 'openssl pkcs12 -nocerts -nodes -in demo.pfx \
		-passin env:passwd', $key, undef, passwd => $passwd;
	my $signdata = 'some data to be signed';
	my $signature;
	bash 'openssl dgst -sha256 -sign <(echo "$key") -hex',
		 $signature, $signdata, key => $key;
	print $signature;

Quite similar, isn't it?

Actually, the call to C<openssl dgst> as above was the very reason
to create this module.

Commands run by Shell::Run are by default executed via the C<-c> option
of the specified shell.
This behaviour can be modified by providing other arguments in the
C<use> statement or the constructor C<< Shell::Run->new >>.

Debugging output can be enabled in a similar way.

=head2 Procedural vs OO interface

The procedural interface acts as a wrapper for the OO interface
with a hidden object instance.
Despite syntax, there is no difference in funtionallity between

C<< $sh->run('something', ...) >>

and

C<sh 'something', ...>

The only difference is I<when> the instance of Shell::Run is created.
With C<use Shell::Run 'shell'> it happens in a C<BEGIN> block
and with C<< $shell = Shell::Run->new(name => 'shell') >> at runtime.

So use the OO interface

=over

=item *
if you like it more

=item *
if need a reference to the C<run> subroutine

=item *
if you want to catch errors from the C<new> constructor at runtime

=back

and use the procedural interface

=over

=item *
if you like it more

=item *
if you prefer a terse syntax

=back

=head1 USAGE

The procedural interface's behaviour can be configured by arguments given
to the C<use> statement.
Providing arguments to the C<use Shell::Run> statement is mandatory
for the procedural interfaces as nothing will be exported by default.

=over

=item use Shell::Run qw(I<name>...)

Searches every given I<name> in C<PATH> and exports a subroutine of the
same name for each given argument into the caller for accessing the
specified external programs.

=item use Shell::Run I<name> => I<options>, ...

Export a subroutine into the caller for accessing an external program.
Unless otherwise specified in I<options>, search for an executable
named I<name> in C<PATH> and export a subroutine named I<name>

I<options> must be a hash reference as follows:

=over

=item exe => I<executable>

Use I<executable> as the path to an external program.
Disables a C<PATH> search.

=item args => I<arguments>

Call the specified external program with these arguments.
Must be a reference to an array.

Default: C<['-c']>.

=item as => I<export>

Use I<export> as the name of the exported subroutine.

=item debug => I<debug>

Provide debugging output to C<STDERR> if I<debug> has a true value.

=back

=back

=head1 FUNCTIONS

=head3 I<name> I<cmd>, I<output>, [I<input>, [I<key> => I<value>,...]]

Call external program configured as I<name>.

=over

=item I<cmd>

The code that is to be executed by this shell.

=item I<output>

A scalar that will receive STDOUT from I<cmd>.
The content of this variable will be overwritten.

=item I<input>

An optional scalar holding data that is fed to STDIN of I<cmd>

=item I<key> => I<value>, ...

A list of key-value pairs that are set in the environment of the
called shell.

=back

In scalar context, returns true or false according
to the exit status of the called command.
In list context, returns two values: the completion code
of the executed command and the exit status as the
logical negation of the completion code from a perl view.

=head1 METHODS

=head2 Constructor

=head3 Shell::Run->new([I<options>])

I<options> (if provided) must be a hash as follows:

=over

=item name => I<name>

Searches I<name> in C<PATH> for an external program to be used.

This value is ignored if I<executable> is given and defaults to C<sh>.

=item exe => I<executable>

Use I<executable> as the path to an external program.
Disables a C<PATH> search.

=item args => I<arguments>

Call the specified external program with these arguments.
Must be a reference to an array.

Default: C<['-c']>.

=item debug => I<debug>

Provide debugging output to C<STDERR> if I<debug> has a true value.

=back

=head2 Methods

=head3 $sh->run(I<cmd>, I<output>, [I<input>, [I<key> => I<value>, ...]])

=over

=item I<cmd>

The code that is to be executed by this shell.

=item I<output>

A scalar that will receive STDOUT from I<cmd>.
The content of this variable will be overwritten.

=item I<input>

An optional scalar holding data that is fed to STDIN of I<cmd>

=item I<key> => I<value>, ...

A list of key-value pairs that are set in the environment of the
called shell.

=back

In scalar context, returns true or false according
to the exit status of the called command.
In list context, returns two values: the completion code
of the executed command and the exit status as the
logical negation of the completion code from a perl view.

=head1 BUGS AND LIMITATIONS

There seems to be some race condition when the called script
closes its input file prior to passing all provided input
data to it.
Sometimes a SIGPIPE is caught and sometimes C<syswrite>
returns an error.
It is not clear if all situations are handled correctly.

Best effort has been made to avoid blocking situations
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
