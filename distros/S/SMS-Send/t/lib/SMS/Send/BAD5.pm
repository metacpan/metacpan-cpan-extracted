package SMS::Send::BAD5;

use strict;
use SMS::Send::Driver ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.07';
	@ISA     = 'SMS::Send::Driver';
}

# Return something other than a driver object
sub new { bless {}, 'Foo' }

1;
