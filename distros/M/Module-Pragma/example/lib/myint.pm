package
	myint;

use strict;
use warnings;

use base qw(Module::Pragma);

__PACKAGE__->register_tags('ok');

sub default_import { 'ok' }


1;