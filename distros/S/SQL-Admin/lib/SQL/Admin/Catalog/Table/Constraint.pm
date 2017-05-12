
package SQL::Admin::Catalog::Table::Constraint;
use base qw( SQL::Admin::Catalog::Table::Object );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################
######################################################################
sub column_list {                        # ;
    my $self = shift;
    $self->{column_list} = shift if @_;
    $self->{column_list};
}


######################################################################
######################################################################
sub fullname {                           # ;
    my $self = shift;

    join '.', (
        $self->table->fullname,
        $self->_constraint_type,
        (map join ('-', ref $_ ? @$_ : $_), @{ $self->column_list || [] }),
    );
}


######################################################################
######################################################################

package SQL::Admin::Catalog::Table::Constraint;

1;

