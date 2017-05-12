
package SQL::Admin::Catalog::Table::Object;
use base qw( SQL::Admin::Catalog::Object );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################
######################################################################
sub table {                              # ;
    my $self = shift;
    if (@_) {
        $self->{table} = shift;
        delete $self->{fullname};
    }
    $self->{table};
}


######################################################################
######################################################################

package SQL::Admin::Catalog::Table::Object;

1;
