package SMS::Send::BAD4;

use strict;
use SMS::Send::Driver ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'SMS::Send::Driver';
}

1;
