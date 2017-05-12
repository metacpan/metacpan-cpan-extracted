use strict;
use warnings;

package Ex;
use base 'Exporter';

our @EXPORT_OK = qw(&foo);

sub foo { return 'FOO' }

1;
