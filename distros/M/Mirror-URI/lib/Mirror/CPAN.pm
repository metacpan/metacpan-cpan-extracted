package Mirror::CPAN;

use 5.006;
use strict;
use Mirror::JSON;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.90';
	@ISA     = 'Mirror::JSON';
}

sub filename {
	return 'modules/07mirror.json';
}

1;

# Copyright 2007 - 2009 Adam Kennedy.
#
# This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.
#
# The full text of the license can be found in the
# LICENSE file included with this module.
