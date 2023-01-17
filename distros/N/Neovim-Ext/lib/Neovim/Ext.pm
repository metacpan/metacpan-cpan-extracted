package Neovim::Ext;
$Neovim::Ext::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use Carp;
use Exporter qw/import/;
use Scalar::Util qw/blessed/;
use Neovim::Ext::MsgPack::RPC;
use Neovim::Ext::Common qw/walk/;
use Neovim::Ext::Buffer;
use Neovim::Ext::Buffers;
use Neovim::Ext::Current;
use Neovim::Ext::Funcs;
use Neovim::Ext::LuaFuncs;
use Neovim::Ext::RemoteApi;
use Neovim::Ext::RemoteMap;
use Neovim::Ext::RemoteSequence;
use Neovim::Ext::Tabpage;
use Neovim::Ext::Window;
use Neovim::Ext::Plugin::Host;
use Neovim::Ext::Tie::Stream;

__PACKAGE__->mk_accessors (qw/session channel_id metadata types api
	vars vvars options buffers windows tabpages current funcs lua err_cb/);

our @EXPORT = (qw(start_host));

sub from_session
{
	my ($session) = @_;

	my $result = $session->request ('nvim_get_api_info');
	my ($channel_id, $metadata) = ($result->[0], $result->[1]);

	my $types =
	{
		$metadata->{types}{Buffer}{id}  => 'Neovim::Ext::Buffer',
		$metadata->{types}{Window}{id}  => 'Neovim::Ext::Window',
		$metadata->{types}{Tabpage}{id} => 'Neovim::Ext::Tabpage',
	};

	return __PACKAGE__->new ($session, $channel_id, $metadata, $types);
}



sub _setup_logging
{
	my ($name, $nvim) = @_;

	if ($name eq 'script')
	{
		my $stderr;
		if ($ENV{NVIM_PERL_LOG_FILE})
		{
			open $stderr, '>', $ENV{NVIM_PERL_LOG_FILE};
		}

		# Redirect STDERR
		tie (*STDERR => 'Neovim::Ext::Tie::Stream', sub
			{
				my ($data) = @_;

				if ($stderr)
				{
					print $stderr $data if ($stderr);
				}
				else
				{
					$data .= "\n" if (substr ($data, -1) ne "\n");
					$nvim->err_write ($data, async_ => 1);
				}
			}
		);

		# Redirect STDOUT
		my $buffer;
		open NEWSTDOUT, '>', \$buffer;
		select NEWSTDOUT;
		tie (*NEWSTDOUT => 'Neovim::Ext::Tie::Stream', sub
			{
				my ($data) = @_;
				$data .= "\n" if (substr ($data, -1) ne "\n");
				$nvim->out_write ($data, async_ => 1);
			}
		);
	}
	else
	{
		if ($ENV{NVIM_PERL_LOG_FILE})
		{
			open *STDERR, '>', $ENV{NVIM_PERL_LOG_FILE};
		}
	}
}



sub start_host
{
	my ($session) = @_;

	my @plugins;
	while (my $plugin = shift @ARGV)
	{
		next if ($plugin !~ /\.pm$/);
		push @plugins, $plugin;
	}

	$session //= Neovim::Ext::MsgPack::RPC::stdio_session();
	my $nvim = from_session ($session);

	if (scalar (@plugins) == 1 && $plugins[0] eq 'ScriptHost.pm')
	{
		# Special case: the legacy host
		my $legacyHostPlugin = $INC{'Neovim/Ext/Plugin/Host.pm'};
		$legacyHostPlugin =~ s/Host/ScriptHost/g;
		@plugins = ($legacyHostPlugin);

		_setup_logging ('script', $nvim);
	}
	else
	{
		_setup_logging ('rplugin', $nvim);
	}

	my $host = Neovim::Ext::Plugin::Host->new ($nvim);
	$host->start (keys (%{{ map { $_ => 1 } @plugins }}))
}



sub new
{
	my ($this, $session, $channel_id, $metadata, $types, %options) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		session => $session,
		channel_id => $channel_id,
		metadata => $metadata,
		types => $types,
		err_cb => $options{err_cb},
	};

	my $obj = bless $self, $class;
	$obj->api (Neovim::Ext::RemoteApi->new ($obj, 'nvim_'));
	$obj->vars (Neovim::Ext::RemoteMap->new ($obj, 'nvim_get_var', 'nvim_set_var', 'nvim_del_var'));
	$obj->vvars (Neovim::Ext::RemoteMap->new ($obj, 'nvim_get_vvar'));
	$obj->options (Neovim::Ext::RemoteMap->new ($obj, 'nvim_get_option', 'nvim_set_option'));
	$obj->buffers (Neovim::Ext::Buffers->new ($obj));
	$obj->windows (Neovim::Ext::RemoteSequence->new ($obj, 'nvim_list_wins'));
	$obj->tabpages (Neovim::Ext::RemoteSequence->new ($obj, 'nvim_list_tabpages'));
	$obj->current (Neovim::Ext::Current->new ($obj));
	$obj->funcs (Neovim::Ext::Funcs->new ($obj));
	$obj->lua (Neovim::Ext::LuaFuncs->new ($obj));
	return $obj;
}



sub next_message
{
	my ($this) = @_;

	my $msg = $this->session->next_message();
	if ($msg)
	{
		return walk (sub { $this->_from_nvim (@_) }, $msg);
	}

	return undef;
}



sub run_loop
{
	my ($this, $request_cb, $notification_cb, $setup_cb, $err_cb) = @_;

	$err_cb //= sub
	{
		my ($exception) = @_;

		if (ref ($exception) && ref ($exception) eq 'Neovim::Ext::ErrorResponse')
		{
			print STDERR $exception->{msg};
		}
		else
		{
			print STDERR $exception;
		}
	};

	$this->err_cb ($err_cb);

	my $filter_request_cb = sub
	{
		my ($name, $args) = @_;

		$args = walk (sub { $this->_from_nvim (@_) }, $args);

		my $result;
		eval
		{
			$result = $request_cb->($name, $args);
		};

		if ($@)
		{
			$this->err_cb->($@);
			die;
		}

		return walk (sub { $this->_to_nvim (@_) }, $result);
	};

	my $filter_notification_cb = sub
	{
		my ($name, $args) = @_;

		$args = walk (sub { $this->_from_nvim (@_) }, $args);

		eval
		{
			$notification_cb->($name, $args);
		};

		if ($@)
		{
			$this->err_cb->($@);
			die;
		}
	};

	$this->session->run ($filter_request_cb, $filter_notification_cb, $setup_cb);
}



sub stop_loop
{
	my ($this) = @_;
	$this->session->stop();
}



sub close
{
	my ($this) = @_;
	$this->session->close();
}



sub request
{
	my ($this, $name, @args) = @_;

	@args = @{walk (sub { $this->_to_nvim (@_) }, \@args)};
	my $result = $this->session->request ($name, @args);
	return walk (sub { $this->_from_nvim (@_) }, $result);
}



sub subscribe
{
	my ($this, $event) = @_;
	return $this->request ('nvim_subscribe', $event);
}



sub unsubscribe
{
	my ($this, $event) = @_;
	return $this->request ('nvim_unsubscribe', $event);
}



sub command
{
	my ($this, $string, @args) = @_;
	return $this->request ('nvim_command', $string, @args);
}



sub command_output
{
	my ($this, $string) = @_;
	return $this->request ('nvim_command_output', $string)
}



sub eval
{
	my ($this, $string, @args) = @_;
	return $this->request ('nvim_eval', $string, @args);
}



sub call
{
	my ($this, $name, @args) = @_;
	return $this->request ('nvim_call_function', $name, [@args]);
}



sub exec_lua
{
	my ($this, $code, @args) = @_;
	return $this->request ('nvim_execute_lua', $code, [@args]);
}



sub strwidth
{
	my ($this, $string) = @_;
	return $this->request ('nvim_strwidth', $string);
}



sub list_runtime_paths
{
	my ($this) = @_;
	return $this->request ('nvim_list_runtime_paths');
}




sub list_uis
{
	my ($this) = @_;
	return $this->request ('nvim_list_uis');
}



sub foreach_rtp
{
	my ($this, $cb) = @_;

	foreach my $path (@{$this->list_runtime_paths})
	{
		eval
		{
			last if (!$cb->($path));
		};

		if ($@)
		{
			last;
		}
	}
}



sub chdir
{
	my ($this, $dir_path) = @_;
	chdir ($dir_path);
	return $this->request ('nvim_set_current_dir', $dir_path);
}



sub feedkeys
{
	my ($this, $keys, $options, $escape_csi) = @_;

	$options //= '';
	$escape_csi //= 1;
	return $this->request ('nvim_feedkeys', $keys, $options, $escape_csi);
}



sub input
{
	my ($this, $bytes) = @_;
	return $this->request ('nvim_input', $bytes);
}



sub replace_termcodes
{
	my ($this, $string, $from_part, $do_lt, $special) = @_;

	$from_part //= 0;
	$do_lt //= 1;
	$special //= 1;
	return $this->request ('nvim_replace_termcodes', $string,
		$from_part, $do_lt, $special);
}



sub out_write
{
	my ($self, $msg, @args) = @_;
	return $self->request ('nvim_out_write', $msg, @args);
}



sub err_write
{
	my ($self, $msg, @args) = @_;
	return $self->request ('nvim_err_write', $msg, @args);
}




sub err_writeln
{
	my ($self, $msg, @args) = @_;
	return $self->request ('nvim_err_writeln', $msg, @args);
}



sub quit
{
	my ($self, $quit_command) = @_;

	$quit_command //= 'qa!';
	eval { $self->command ($quit_command) };
}



sub _to_nvim
{
	my ($this, $obj) = @_;

	if (ref ($obj) && blessed ($obj) && $obj->isa ('Neovim::Ext::Remote'))
	{
		return $obj->code_data;
	}

	return $obj;
}



sub _from_nvim
{
	my ($this, $obj) = @_;

	if (ref ($obj) eq 'MsgPack::Raw::Ext')
	{
		my $class = $this->types->{$obj->{type}};
		return $class->new ($this, $obj);
	}

	return $obj;
}

1;

__END__

=for HTML
<a href="https://dev.azure.com/jacquesgermishuys/p5-Neovim-Ext/_build">
	<img src="https://dev.azure.com/jacquesgermishuys/p5-Neovim-Ext/_apis/build/status/jacquesg.p5-Neovim-Ext?branchName=master" alt="Build Status: Azure Pipeline" align="right" />
</a>
<a href="https://ci.appveyor.com/project/jacquesg/p5-neovim-ext">
	<img src="https://ci.appveyor.com/api/projects/status/gn8y20nno0aj79l4?svg=true" alt="Build Status: AppVeyor" align="right" />
</a>
<a href="https://coveralls.io/r/jacquesg/p5-Neovim-Ext">
	<img src="https://coveralls.io/repos/jacquesg/p5-Neovim-Ext/badge.png?branch=master" alt="coveralls" align="right" />
</a>
=cut

=head1 NAME

Neovim::Ext - Perl bindings for neovim

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Perl interface to Neovim

=head1 FUNCTIONS

=head2 from_session( $session )

Create a new Nvim instance for C<$session>.

=head2 start_host( $session )

Promote the current process into a perl plugin host for Nvim. It starts the event
loop for C<$session>, listening for Nvim requests and notifications, and also
registers Nvim commands for loading/unloading perl plugins.

=head1 METHODS

=head2 call( $name, @args )

Call a vimscript function.

=head2 chdir( $path )

Set the Nvim current directory.

=head2 close( )

Close the Nvim session.

=head2 command( $string, @args)

Execute a single ex command.

=head2 command_output( )

Execute a single ex command and return the output.

=head2 err_write( $msg )

Print C<$msg> as an error message. Does not append a newline and won't be displayed
if a linefeed is not sent.

=head2 err_writeln( $msg )

Print C<$msg> as an error message. Appends a newline so the buffer is flushed
and displayed.

=head2 eval( $string, @args )

Evaluate a vimscript expression

=head2 exec_lua( $code, @args )

Execute lua code.

=head2 feedkeys ($keys, [$options, $escape_csi])

Push C<$keys>< to Nvim user input buffer. Options can be a string with the following
character flags:

=over 4

=item * "m"

Remap keys. This is the default.

=item * "n"

Do not remap keys.

=item * "t"
Handle keys as if typed; otherwise they are handled as if coming from a mapping. This
matters for undo, opening folds, etc.

=back

=head2 foreach_rtp( \&cb )

Invoke C<\&cb> for each path in 'runtimepath'.

=head2 input( $bytes )

Push C<$bytes> to Nvim's low level input buffer. Unliked C<feedkeys()> this uses the
lowest level input buffer and the call is not deferred.

=head2 list_runtime_paths( )

Return a list reference of paths contained in the 'runtimepath' option.

=head2 list_uis( )

Gets a list of attached UIs.

=head2 next_message( )

Block until a message (request or notification) is available. If any messages were
previously enqueued, return the first in the queue. If not, the event loop is run
until one is received.

=head2 out_write( $msg, @args )

Print C<$msg> as a normal message. The message is buffered and wont display
until a linefeed is sent.

=head2 quit( [$quit_command])

Send a quit command to Nvim. By default, the quit command is C<qa!> which will make
Nvim quit without saving anything.

=head2 replace_termcodes( $string, [$from_part, $do_lt, $special] )

Replace any terminal code strings by byte sequences. The returned sequences are Nvim's
internal representation of keys. The returned sequences can be used as input to
C<feekeys()>.

=head2 request( $name, @args)

Send an API request or notification to Nvim.

=head2 run_loop($request_cb, $notification_cb, [$setup_cb, $err_cb] )

Run the event loop to receive requests and notifications from Nvim. This should not
be called from a plugin running in the host, which already runs the loop and dispatches
events to plugins.

=head2 stop_loop( )

Stop the event loop.

=head2 strwidth( $string )

Return the number of display cells C<$string> occupies.

=head2 subscribe( $event )

Subscribe to an Nvim event.

=head2 unsubscribe( $event )

Unsubscribe from an Nvim event.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
