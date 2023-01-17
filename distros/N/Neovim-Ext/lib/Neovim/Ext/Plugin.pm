package Neovim::Ext::Plugin;
$Neovim::Ext::Plugin::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;
use Attribute::Handlers;
Neovim::Ext::Plugin->mk_accessors (qw/nvim host/);

sub register
{
	require Neovim::Ext::Plugin::Host;
	Neovim::Ext::Plugin::Host->register (shift);
}


# attributes (decorators)
sub nvim_command :ATTR(CODE,BEGIN)
{
	my ($package, $symbol, $sub, $attr, $data) = @_;
	$package->_add_command ($sub, @$data);
}

sub nvim_autocmd :ATTR(CODE,BEGIN)
{
	my ($package, $symbol, $sub, $attr, $data) = @_;
	$package->_add_autocmd ($sub, @$data);
}

sub nvim_function :ATTR(CODE,BEGIN)
{
	my ($package, $symbol, $sub, $attr, $data) = @_;
	$package->_add_function ($sub, @$data);
}

sub nvim_shutdown_hook :ATTR(CODE,BEGIN)
{
	my ($package, $symbol, $sub, $attr, $data) = @_;
	$package->_add_shutdown_hook ($sub, @$data);
}

sub nvim_rpc_export :ATTR(CODE,BEGIN)
{
	my ($package, $symbol, $sub, $attr, $data) = @_;
	$package->_add_rpc_export ($sub, @$data);
}


sub get_specs
{
	my ($package) = @_;
	no strict 'refs';
	return \@{$package.'::specs'};
}



sub _add_spec
{
	my ($package, $spec) = @_;
	no strict 'refs';
	push @{$package.'::specs'}, $spec;
}



sub _add_command
{
	my ($package, $symbol, $name, %options) = @_;

	no strict 'refs';
	push @{$package.'::commands'},
	{
		type => 'command',
		name => $name,
		symbol => $symbol,
		options => \%options,
	};

	if (!$options{sync} && delete $options{allow_nested})
	{
		$options{sync} = 'urgent';
	}

	$package->_add_spec
	(
		{
			type => 'command',
			name => $name,
			sync => !!$options{sync},
			opts => \%options,
		}
	);
}



sub get_commands
{
	my ($package) = @_;
	no strict 'refs';
	return @{$package.'::commands'};
}



sub _add_autocmd
{
	my ($package, $symbol, $name, %options) = @_;

	$options{pattern} //= '*';

	no strict 'refs';
	push @{$package.'::autocmds'},
	{
		type => 'autocmd',
		name => $name,
		symbol => $symbol,
		options => \%options,
	};

	if (!$options{sync} && delete $options{allow_nested})
	{
		$options{sync} = 'urgent';
	}

	$package->_add_spec
	(
		{
			type => 'autocmd',
			name => $name,
			sync => !!$options{sync},
			opts => \%options,
		}
	);
}



sub get_autocmds
{
	my ($package) = @_;
	no strict 'refs';
	return @{$package.'::autocmds'};
}



sub _add_function
{
	my ($package, $symbol, $name, %options) = @_;

	no strict 'refs';
	push @{$package.'::functions'},
	{
		type => 'function',
		name => $name,
		symbol => $symbol,
		options => \%options,
	};

	if (!$options{sync} && delete $options{allow_nested})
	{
		$options{sync} = 'urgent';
	}

	$package->_add_spec
	(
		{
			type => 'function',
			name => $name,
			sync => !!$options{sync},
			opts => \%options,
		}
	);
}



sub get_functions
{
	my ($package) = @_;
	no strict 'refs';
	return @{$package.'::functions'};
}



sub _add_shutdown_hook
{
	my ($package, $symbol) = @_;

	no strict 'refs';
	push @{$package.'::shutdown_hooks'}, $symbol;
}



sub get_shutdown_hooks
{
	my ($package) = @_;
	no strict 'refs';
	return @{$package.'::shutdown_hooks'};
}



sub _add_rpc_export
{
	my ($package, $symbol, $name, %options) = @_;

	$options{sync} //= 0;

	no strict 'refs';
	push @{$package.'::rpc_exports'},
	{
		type => 'rpc_export',
		name => $name,
		symbol => $symbol,
		options => \%options,
	};
}



sub get_rpc_exports
{
	my ($package) = @_;
	no strict 'refs';
	return @{$package.'::rpc_exports'};
}



sub new
{
	my ($this, $nvim, $host) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		nvim => $nvim,
		host => $host,
	};

	return bless $self, $class;
}

=head1 NAME

Neovim::Ext::Plugin - Neovim Plugin class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 new( $nvim )

Create a new plugin instance.

=head2 register( )

Register the plugin. This should be called as soon as possible.

=head2 nvim_command( )

Subroutine attribute to export a subroutine as a Vim command.

=head2 nvim_autocmd( )

Subroutine attribute to export a subroutine as a Vim autocmd.

=head2 nvim_function( )

Subroutine attribute to export a subroutine as a Vim function.

=head2 nvim_rpc_export( )

Subroutine attribute to export a subroutine as an RPC export.

=head2 nvim_shutdown_hook( )

Subroutine attribute to export a subroutine as a shutdown hook.

=head2 get_commands( )

Get all exported commands for the plugin.

=head2 get_functions( )

Get all exported functions for the plugin.

=head2 get_autocmds( )

Get all exported autocmds for the plugin.

=head2 get_shutdown_hooks( )

Get all shutdown hooks for the plugin.

=head2 get_rpc_exports( )

Get all the RPC exports for the plugin.

=head2 get_specs( )

Get all specs for the plugin.

=cut

1;
