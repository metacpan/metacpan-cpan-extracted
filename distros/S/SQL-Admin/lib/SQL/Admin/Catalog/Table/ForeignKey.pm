
package SQL::Admin::Catalog::Table::ForeignKey;
use base qw( SQL::Admin::Catalog::Table::Constraint );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################
######################################################################
sub _constraint_type {                   # ;
    'foreign_key';
}


######################################################################
######################################################################
sub fullname {                           # ;
    my $self = shift;

    $self->SUPER::fullname
      . '{'
      . join ('.', grep $_, (
        $self->referenced_table->fullname,
        (map join ('-', ref $_ ? @$_ : $_), @{ $self->referenced_column_list || [] }),
    )) . '}';
}


######################################################################
######################################################################
sub referencing_column_list {            # ;
    shift->column_list (@_);
}


######################################################################
######################################################################
sub referenced_table {                  # ;
    my $self = shift;
    $self->{referenced_table} = shift if @_;
    $self->{referenced_table};
}


######################################################################
######################################################################
sub referenced_column_list {            # ;
    my $self = shift;
    $self->{referenced_column_list} = shift if @_;
    $self->{referenced_column_list};
}


######################################################################
######################################################################
sub update_rule {                        # ;
    my $self = shift;
    $self->{update_rule} = shift if @_;
    $self->{update_rule};
}


######################################################################
######################################################################

sub delete_rule {                        # ;
    my $self = shift;
    $self->{delete_rule} = shift if @_;
    $self->{delete_rule};
}


######################################################################
######################################################################


package SQL::Admin::Catalog::Table::ForeignKey;

1;
