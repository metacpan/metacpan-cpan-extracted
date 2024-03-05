use 5.010;
use strict;
use warnings;

package URI::neo4j;
$URI::neo4j::VERSION = '0.46';

use parent 'URI::_server';

sub default_port { 7687 }

1;
