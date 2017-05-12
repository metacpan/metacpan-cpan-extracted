#!perl

use warnings;
use strict;
use 5.010;

use Net::Dropbox;
use YAML qw(Dump);

my $nd = Net::Dropbox->new();

my $res = $nd->_send_and_fetch(
	"get_folder_tag",
	{ path => '/home/sungo/Dropbox/Backups' }
);


say Dump $res;
