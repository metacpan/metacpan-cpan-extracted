
package SQL::Admin::Catalog::Table::Unique;
use base qw( SQL::Admin::Catalog::Table::Constraint );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################
######################################################################
sub _constraint_type {                   # ;
    'unique';
}


######################################################################
######################################################################

package SQL::Admin::Catalog::Table::Unique;

1;
