
package SQL::Admin::Catalog::Table::PrimaryKey;
use base qw( SQL::Admin::Catalog::Table::Constraint );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################
######################################################################
sub _constraint_type {                   # ;
    'primary_key';
}


######################################################################
######################################################################

package SQL::Admin::Catalog::Table::PrimaryKey;

1;
