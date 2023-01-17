package Neovim::Ext::Plugin::ScriptHost;
$Neovim::Ext::Plugin::ScriptHost::VERSION = '0.06';
use strict;
use warnings;
use List::Util qw/min/;
use base 'Neovim::Ext::Plugin';
use Neovim::Ext::ErrorResponse;
use Neovim::Ext::VIMCompat::Buffer;
use Neovim::Ext::VIMCompat::Window;
use Eval::Safe;

__PACKAGE__->mk_accessors (qw/current env/);
__PACKAGE__->register;

BEGIN
{
	eval "package VIM;\n use Neovim::Ext::VIMCompat;\n;1;\n";
};

our $VIM;
our $curbuf;
our $curwin;
our $line;
our $linenr;
our $current;
our $vim;
our $nvim;


sub new
{
	my ($this, $nvim, $host) = @_;

	$VIM = $nvim;

	my $obj = $this->SUPER::new ($nvim, $host);
	$obj->env (Eval::Safe->new());
	$obj->env->share ('$curbuf');
	$obj->env->share ('$curwin');
	$obj->env->share ('$line');
	$obj->env->share ('$linenr');
	$obj->env->share ('$current');
	$obj->env->share ('$vim');
	$obj->env->share ('$nvim');

	return $obj;
}

sub perl_execute :nvim_rpc_export('perl_execute', sync => 1)
{
	my ($this, $script, $range_start, $range_stop) = @_;

	$this->_eval ($range_start, $range_stop, $script);
	if ($@)
	{
		die Neovim::Ext::ErrorResponse->new ($@);
	}

	return undef;
}

sub perl_execute_file :nvim_rpc_export('perl_execute_file', sync => 1)
{
	my ($this, $file_path, $range_start, $range_stop) = @_;

	my $script;
	{
		open my $fh, '<', $file_path or
			die Neovim::Ext::ErrorResponse->new ("Could not open '$file_path': $!");
		local $/ = undef;
		$script = <$fh>;
		close $fh;
	}

	$this->perl_execute ($script, $range_start, $range_stop);
	return undef;
}

sub perl_do_range :nvim_rpc_export('perl_do_range', sync => 1)
{
	my ($this, $start, $stop, $code) = @_;

	$start -= 1;

	my $buffer = tied (@{$this->nvim->current->buffer});
	while ($start < $stop)
	{
		my $lines = $buffer->api->get_lines ($start, $start+1, 1);

		$this->_setup_current ($start, $start, $lines->[0], $start+1);
		my $result = $this->env->eval ("local \$_ = \$line; $code; \$_") // '';

		$buffer->api->set_lines ($start, $start+1, 1, [$result]);

		++$start;

		# The number of lines in the buffer could have reduced and $stop
		# could now point past the end, readjust.
		my $count = scalar (@{$this->nvim->current->buffer});
		$stop = min ($count, $stop);
	}

	return undef;
}

sub perl_eval :nvim_rpc_export('perl_eval', sync => 1)
{
	my ($this, $expr) = @_;

	$this->_setup_current();
	return $this->env->eval ($expr) // 0;
}

sub perl_chdir :nvim_rpc_export('perl_chdir', sync => 0)
{
	my ($this, $cwd) = @_;
	chdir ($cwd);
}

sub _eval
{
	my ($this, $start, $stop, $code) = @_;

	$this->_setup_current ($start, $stop);
	$this->env->eval ($code);
}

sub _setup_current
{
	my ($this, $start, $stop, $line_, $linenr_) = @_;

	$vim = $this->nvim;
	$nvim = $this->nvim;

	$current = $this->nvim->current;
	$current->range (tied (@{$current->buffer})->range ($start, $stop)) if (defined ($start) && defined ($stop));
	$curbuf = Neovim::Ext::VIMCompat::Buffer->new ($current->buffer);
	$curwin = Neovim::Ext::VIMCompat::Window->new ($current->window);
	$main::curbuf = $curbuf;
	$main::curwin = $curwin;

	$line = $line_;
	$linenr = $linenr_;
}

=head1 NAME

Neovim::Ext::Plugin::ScriptHost - Neovim Legacy perl Plugin

=head1 VERSION

version 0.06

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 perl_execute( $script, $range_start, $range_stop )

=head2 perl_execute_file( $file_path, $range_start, $range_stop )

=head2 perl_do_range( $start, $stop, $code )

=head2 perl_eval( $expr )

=head2 perl_chdir( $cwd )

=cut

1;
