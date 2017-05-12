package Protocol::PerlDebugCLI;
# ABSTRACT: Interact with the Perl debugging interface using events
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);
use Protocol::PerlDebugCLI::Request;

our $VERSION = '0.002';

=head1 NAME

Protocol::PerlDebugCLI - generate and process events for interacting with the Perl debug interface

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Protocol::PerlDebugCLI;
 my $deb = Protocol::PerlDebugCLI->new;

 # Attach handlers for the events that we're interested in,
 # anything else will be quietly ignored
 $deb->add_handler_for_event(
   breakpoint => sub {
     warn "Breakpoint reached\n";
   },
 );

 # Set a breakpoint and continue execution
 $deb->request_breakpoint(
   file => 'script.pl',
   line => 17,
 );
 $deb->request_continue;

=head1 DESCRIPTION

This is an abstract implementation for interacting with the perl debugger.
It parses the debugger output (provided via the L</on_read> method) and
and generates events, similar in concept to SAX.

It also provides abstract methods for generating commands to drive the
debugger; by hooking the C<write> event a companion class or subclass
can drive the debugger without knowing the details of the protocol.

This class is not intended to be used directly - it deals with the abstract
protocol and requires additional code to deal with the transport layer
(this could be through sockets, via the RemotePort= PERLDBOPTS flag, or on
STDIN/STDOUT/TTY for a forked C<perl -d> process).

See L<Net::Async::PerlDebugCLI> for an implementation of a transport
layer using RemotePort, and L<Tickit::Debugger::Async> for a L<Tickit>-based
terminal debugging application.

Other similar classes for interacting with the debugger are listed in the
L</SEE ALSO> section.

=head1 METHODS

=cut

=head2 new

Instantiate a new object.

=cut

sub new {
	my $class = shift;
	my $self = bless { }, $class;

# Start with no queued requests, and until we get a prompt we're not ready to send requests yet
	$self->{queued_requests} = [];
	$self->{ready_for_request} = 0;

# Auto-send next request on prompt
	$self->add_handler_for_event(
		prompt => sub {
			my ($self, $depth) = @_;
			$self->send_next_request if $self->have_queued_requests;
			$self;
		}
	);
	return $self;
}

=head2 send_next_request

Attempt to send the next queued request to the debugger.

Expects the caller to have checked whether there are any requests pending,
and will raise an exception if this is not the case.

=cut

sub send_next_request {
	my $self = shift;
	die "No requests queued" unless my $req = shift @{$self->{queued_requests}};

	$self->write($req->command . "\n");
	return $self;
}

=head2 have_queued_requests

Returns true if there are queued requests.

=cut

sub have_queued_requests {
	my $self = shift;
	return @{$self->{queued_requests}} ? 1 : 0
}

=head2 current_state

Accessor for the current state.

Will raise an exception if attempting to set the state to the same value as it had previously.

=cut

sub current_state {
	my $self = shift;
	if(@_) {
		my $state = shift;
		die "Attempting to change state to the previous value: $state" if $state eq $self->{state};
		$self->{state} = shift;
		$self->invoke_event(state_changed => $self->{state});
		return $self;
	}
	return $self->{state};
}

=head2 parse_variable_dump_line

Parse variable dump output, typically from v or x commands.

=cut

sub parse_variable_dump_line {
	my $self = shift;
	my $line = shift;
	# FIXME Only handles simple scalar values at the moment
	if($line =~ s/^(\$|\%|\*|\@)(\w+)\s*=\s*//) {
		my $type = {
			'$'	=> 'scalar',
			'@'	=> 'array',
			'%'	=> 'hash',
			'*'	=> 'glob',
		}->{$1} || 'unknown';
		$self->invoke_event(have_variable =>
			type	=> $type,
			name	=> $2,
			data	=> $line
		);
	}
	return $self;
}

=head2 parse_code_context_line

Parse code context, which consists of the current active line and a few surrounding
lines.

=cut

sub parse_code_context_line {
	my $self = shift;
	my $line = shift;

	if($line =~ s/^(\d+)((?:==>)|(?::))?//) {
		my $line_number = $1;
		my $method = {
			'==>'	=> 'execution_line',
			':'	=> 'breakable',
			'none'	=> 'filler'
		}->{$2 || 'none'};
		$self->invoke_event(code_context =>
			method => $method,
			line => $line_number
		);
	}
	return $self;
}

=head2 parse_at_breakpoint

At a breakpoint we start with the spec, then get line(s) of code

=cut

sub parse_at_breakpoint {
	my $self = shift;
	my $line = shift;

	# Current file position
	if($line =~ s/^([\w:]+)\(([^:]+):(\d+)\)://) {
		my ($func, $file, $line) = ($1, $2, $3);
		$self->invoke_event(current_position =>
			function	=> $func,
			file		=> $file,
			line		=> $line
		);
	} elsif($line =~ s/^(\d+)((?:==>)|(?::))?//) {
		# Current file position
		my $line_number = $1;
		my $type = {
			'==>'	=> 'execution_line',
			':'	=> 'breakable',
			'none'	=> 'filler'
		}->{$2 || 'none'};
		$self->invoke_event(surrounding_code =>
			type => $type,
			line => $line_number,
			text => $line
		);
	} else {
		die "Unknown data: [$line]";
	}
	return $self;
}

=head2 on_read

Should be called by the transport layer when data is available for parsing.

Expects the following parameters:

=over 4

=item * $buffref - a scalar reference to the current read buffer. Any parseable
data will be extract from this buffer, modifying in-place. If there is insufficient
data to parse a full line then there may be some data left in this buffer on return,
and the transport layer should call us again after reading more data (and not before).

=item * $eof - a flag indicating that no further data is forthcoming. When this is set
we attempt to parse any trailing data and then go through any required cleanup before
returning.

=back

=cut

sub on_read {
	my ($self, $buffref, $eof) = @_;
	$self->{ready_for_request} = 0;

# First, parse any full lines we may have already
	while($$buffref =~ s/^(.*?)\n//) {
		my $line = $1;
		next unless $line =~ /\w/;
		if($line =~ /^Use /) {
			$self->invoke_event(execution_complete =>);
#		} elsif(@parser) {
#			$parser[0]->($line);
		} elsif($line =~ /^Loading DB routines/ || $line =~ /^Editor support/ || $line =~ /^Enter h/) {
			
			$self->invoke_event(unparsed_data => $line);
		} else {
			$self->parse_at_breakpoint($line);
		}
	}

# Check for prompt
	if($$buffref =~ s/^  DB<(\d+)> //) {
		$self->{ready_for_request} = 1;
		$self->invoke_event(prompt => $1);
	}
	return $self;
}

=head2 is_ready_for_request

Returns true if we're ready to send the next request (i.e. we're at a prompt).

=cut

sub is_ready_for_request {shift->{ready_for_request} }

=head2 request_stack_trace

Request a full stack trace.

=cut

sub request_stack_trace {
	my $self = shift;
	$self->queue_command(
		command	=> 'T',
	);

	return $self;
}

=head2 request_vars_in_scope

Request a dump of all vars in the current scope.

=cut

sub request_vars_in_scope {
	my $self = shift;
	$self->queue_command(
		command	=> 'y',
		on_start => sub {
			$self->{scope_vars} = [];
		},
		parser => 'parse_var_info',
	);
	return $self;
}

=head2 request_current_line

Request information about the current line (i.e. next line to be executed).

=cut

sub request_current_line {
	my $self = shift;
	$self->queue_command(
		command	=> 'y',
	);
	return $self;
}

=head2 request_step_into

Step into the current line.

=cut

sub request_step_into {
	my $self = shift;
	$self->queue_command(
		command	=> 's',
	);
	return $self;
}

=head2 request_step_over

Step over the current line.

=cut

sub request_step_over {
	my $self = shift;
	$self->queue_command(
		command	=> 'n',
	);
	return $self;
}

=head2 request_continue

Continue execution.

=cut

sub request_continue {
	my $self = shift;
	$self->queue_command(
		command	=> 'c',
	);
	return $self;
}

=head2 request_breakpoint

Set a breakpoint on the requested line.

=cut

sub request_breakpoint {
	my $self = shift;
	my %args = @_;
	$self->queue_command(
		command	=> 'b' . (exists $args{line} ? ' ' . $args{line} : ''),
	);
	return $self;
}

=head2 request_clear_breakpoint

Clear the given breakpoint.

Expects the following named parameters:

=over 4

=item * line - (optional) line number to clear breakpoints from

=back

If no line is provided, will clear all existing breakpoints.

=cut

sub request_clear_breakpoint {
	my $self = shift;
	my %args = @_;
	$self->queue_command(
		command	=> 'B ' . (exists $args{line} ? $args{line} : '*'),
	);
	return $self;
}

=head2 request_restart

Restart the current program.

=cut

sub request_restart {
	my $self = shift;
	$self->queue_command(
		command	=> 'R',
	);
	return $self;
}

=head2 request_watch

Request a watch on the given variable.

=cut

sub request_watch {
	my $self = shift;
	my %args = @_;
	$self->queue_command(
		command	=> 'w ' . $args{variable},
	);
	return $self;
}

=head2 queue_command

Queue the given command.

=cut

sub queue_command {
	my $self = shift;
	my $req = Protocol::PerlDebugCLI::Request->new(@_);
	push @{$self->{queued_requests}}, $req;
	$self->send_next_request if $self->is_ready_for_request;
	return $self;
}

=head2 write

Invokes a C<write> event, requesting the given data be written to the
underlying transport.

=cut

sub write {
	my $self = shift;
	$self->invoke_event(write => shift);
	return $self;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Debug::Client> - provides a similar interface to the perl debugger, including code
to handle the listening socket. Probably a good alternative if you want a synchronous rather
than event-driven interface.

=item * C<Pro Perl Debugging>, by Andy Lester and Richard Foley (L<http://www.apress.com/9781590594544>),
provides a remoteport.pl script which again offers a synchronous interface to the remote
debugger port.

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2012. Licensed under the same terms as Perl itself.
