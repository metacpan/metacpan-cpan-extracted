package TestPlugin;

use strict;
use warnings;
use base 'Neovim::Ext::Plugin';

__PACKAGE__->register;


sub test_command :nvim_command('TestCommand')
{
	my ($this) = @_;

	foreach my $name (keys %{$this->host->notification_handlers})
	{
		if ($name =~ /ToBeDeleted/)
		{
			delete $this->host->notification_handlers->{$name};
			last;
		}
	}
}




sub test_command_tobedeleted :nvim_command('TestCommandToBeDeleted')
{
}



sub test_function :nvim_function('TestFunction', sync => 1)
{
	my ($this) = @_;

	foreach my $name (keys %{$this->host->request_handlers})
	{
		if ($name =~ /ToBeDeleted/)
		{
			delete $this->host->request_handlers->{$name};
			last;
		}
	}

	return 'hello!';
}



sub test_function_tobedeleted :nvim_function('TestFunctionToBeDeleted', sync => 1)
{
	return 'hello';
}



sub shutdown_hook :nvim_shutdown_hook
{
}



sub simple_autocmd :nvim_autocmd('BufEnter', pattern => '*.pl', eval => 'expand("<afile>")', sync => 1)
{
	my ($this, $filename) = @_;

	$this->nvim->command ("let g:simple_autocmd = '$filename'", async_ => 1);
}

1;

