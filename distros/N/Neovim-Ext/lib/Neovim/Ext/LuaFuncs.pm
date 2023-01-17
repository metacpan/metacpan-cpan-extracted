package Neovim::Ext::LuaFuncs;
$Neovim::Ext::LuaFuncs::VERSION = '0.06';
use strict;
use warnings;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors (qw/nvim name/);


sub new
{
	my ($this, $nvim, $name) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		nvim => $nvim,
		name => $name,
	};

	return bless $self, $class;
}



sub call
{
	my ($this, @args) = @_;

	my $async = 0;

	my @filtered;
	while (my $value = shift @args)
	{
		push @filtered, $value;

		if ($value eq 'async_')
		{
			my $tmp = shift @args;
			$async = !!$tmp;
			push @filtered, $tmp;
		}
	}

	@args = @filtered;

	my $code = $this->name."(...)";
	if (!$async)
	{
		$code = "return $code";
	}

	$this->nvim->exec_lua ($code, @args);
}



sub DESTROY
{
}


our $AUTOLOAD;

sub AUTOLOAD
{
	my $methodName;
	($methodName = $AUTOLOAD) =~ s/.*:://;

	my $this = shift;
	my $prefix = '';
	$prefix = $this->name.'.' if ($this->name);

	my $name = $prefix.$methodName;
	return __PACKAGE__->new ($this->nvim, $name);
}

=head1 NAME

Neovim::Ext::LuaFuncs - Neovim LuaFuncs class

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

	my $result = $lua->lua_function->call (123);

=head1 DESCRIPTION

Helper pacakge to allow lua functions to be called like perl methods.

=head1 METHODS

=head2 call( @args )

Call a lua function.

=cut

1;
