package SMS::Send::BAD3;

use strict;
use SMS::Send::Driver ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'SMS::Send::Driver';
}

sub new {
	die "new dies as expected";
}

1;
