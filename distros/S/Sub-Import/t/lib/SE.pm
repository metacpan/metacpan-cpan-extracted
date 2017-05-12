use strict;
use warnings;

package SE;

use Sub::Exporter -setup => {
  exports => [ qw(foo) ],
};

sub foo { return 'FOO' }

1;
