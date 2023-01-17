package Neovim::Ext::Plugin::Host;
$Neovim::Ext::Plugin::Host::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use Scalar::Util qw/weaken/;
__PACKAGE__->mk_accessors (qw/nvim _loaded _load_errors _specs notification_handlers request_handlers/);


our $lastPackage;

sub register
{
	my ($this, $package) = @_;
	$lastPackage = $package;
}



sub new
{
	my ($this, $nvim) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		nvim => $nvim,
		_loaded => {},
		_load_errors => {},
		_specs => {},
	};

	my $obj = bless $self, $class;

	my $host = $obj;
	weaken ($host);

	$obj->notification_handlers
	({
		nvim_error_event => sub
		{
			$host->_on_error_event (@_);
		},
	});
	$obj->request_handlers
	({
		poll     => sub { return 'ok' },
		specs    => sub { $host->_on_specs_request (@_) },
	});

	return $obj;
}



sub start
{
	my ($this, @plugins) = @_;

	my $host = $this;
	weaken ($host);

	$this->nvim->run_loop
	(
		sub { $host->_on_request (@_) },
		sub { $host->_on_notification (@_) },
		sub { $host->_load (@plugins) }
	);
}



sub shutdown
{
	my ($this) = @_;

	$this->_unload();
	$this->nvim->stop_loop();
}



sub _make_rpc_method
{
	my ($path, $handler) = @_;

	if ($handler->{type} eq 'rpc_export')
	{
		return $handler->{name};
	}

	my $method = join (':', $path, $handler->{type}, $handler->{name});
	if ($handler->{options}{pattern})
	{
		$method .= ":$handler->{options}{pattern}";
	}

	return $method;
}



sub _load
{
	my ($this, @plugins) = @_;

	foreach my $path (@plugins)
	{
		next if (exists ($this->_loaded->{$path}));

		eval
		{
			require $path;
			my $module = $lastPackage;
			my $plugin = $module->new ($this->nvim, $this);

			$this->_specs->{$path} = $module->get_specs();

			my @handlers =
			(
				$module->get_commands(),
				$module->get_functions(),
				$module->get_autocmds(),
				$module->get_rpc_exports(),
			);

			# Module may not export any handlers
			next if (scalar (@handlers) == 0);

			foreach my $handler (@handlers)
			{
				my $method = _make_rpc_method ($path, $handler);

				my $sub = sub
				{
					$handler->{symbol}->($plugin, @_);
				};

				if ($handler->{options}{sync})
				{
					$this->request_handlers->{$method} = $sub;
				}
				else
				{
					$this->notification_handlers->{$method} = $sub;
				}
			}

			$this->_loaded->{$path} =
			{
				handlers => \@handlers,
				package  => $module,
			};
		};

		if ($@)
		{
			$this->_load_errors->{$path} = "Could not load plugin '$path': $@";
		}
	}

	$this->nvim->api->set_client_info
	(
		'perl-rplugin-host', {}, 'host',
		{
			poll => {},
			specs => { nargs => 1 },
		},
		{
			license => 'perl5',
			website => 'https://github.com/jacquesg/p5-Neovim',
		},
		async_ => 1
	);
}



sub _unload
{
	my ($this) = @_;

	foreach my $path (keys %{$this->_loaded})
	{
		my $plugin = $this->_loaded->{$path};

		foreach my $hook ($plugin->{package}->get_shutdown_hooks())
		{
			$hook->();
		}

		foreach my $handler (@{$plugin->{handlers}})
		{
			my $method = _make_rpc_method ($path, $handler);

			if ($handler->{options}{sync})
			{
				delete $this->request_handlers->{$method};
			}
			else
			{
				delete $this->notification_handlers->{$method};
			}
		}
	}

	$this->_specs ({});
	$this->_loaded ({});
}



sub _on_error_event
{
	my ($this, $kind, $msg) = @_;

	$this->nvim->err_write ("Async request cause and error: $msg\n",
		async_ => 1);
}



sub _on_async_err
{
	my ($this, $msg) = @_;

	$this->nvim->err_write ($msg, async_ => 1);
}



sub _on_specs_request
{
	my ($this, $path) = @_;
	return $this->_specs->{$path};
}



sub _on_request
{
	my ($this, $name, $args) = @_;

	if (!exists ($this->request_handlers->{$name}))
	{
		my $msg = $this->_missing_handler_error ($name, 'request');
		return;
	}

	my $handler = $this->request_handlers->{$name};
	return $handler->(@$args);
}



sub _on_notification
{
	my ($this, $name, $args) = @_;

	if (!exists ($this->notification_handlers->{$name}))
	{
		my $msg = $this->_missing_handler_error ($name, 'notification');
		$this->_on_async_err ($msg."\n");
		return;
	}

	my $handler = $this->notification_handlers->{$name};
	return $handler->(@$args);
}



sub _missing_handler_error
{
	my ($this, $name, $kind) = @_;
	return "no $kind handler registered for $name\n";
}


=head1 NAME

Neovim::Ext::Plugin::Host - Neovim Plugin::Host class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

	my $host = Neovim::Ext::Plugin::Host->new ($nvim);
	$host->start ('/path/to/Plugin1.pm', '/path/to/Plugin2.pm');

=head1 METHODS

=head2 register( $package )

Register C<$package> as a plugin. This should be called by a plugin on load.

=head2 start( @plugins )

Start listening for msgpack-rpc requests and notifications.

=head2 shutdown( )

Shutdown the host.

=cut

1;
