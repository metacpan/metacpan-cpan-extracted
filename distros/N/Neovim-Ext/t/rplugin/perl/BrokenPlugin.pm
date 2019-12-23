package BrokenPlugin;

use strict;
use warnings;
use base 'Neovim::Ext::Plugin';

__PACKAGE__->register;


sub test
{
	broken
}

1;

