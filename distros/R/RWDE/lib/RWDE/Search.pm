# Object to handle Search, maps requests to rpc
# The only purpose for this class is to afford RWDE::Search namespace
# so that Gearman clients can issue requests in the form RWDE::Search->method

package RWDE::Search;

use strict;
use warnings;

use base qw(RWDE::Mapper);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

1;
