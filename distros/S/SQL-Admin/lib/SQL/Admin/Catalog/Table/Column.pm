
package SQL::Admin::Catalog::Table::Column;
use base qw( SQL::Admin::Catalog::Table::Object );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################
######################################################################
sub add {                                # ;
    my ($self, $what, @params) = @_;

    my $obj = $self->catalog->add ($what, column => $self, @params);

    ##################################################################

    return $self->not_null ($obj) if $what eq 'not_null';
    return $self->default ($obj)  if $what eq 'default';
}


######################################################################
######################################################################
sub type {                               # ;
    my $self = shift;
    $self->{type} = shift if @_;
    $self->{type};
}


######################################################################
######################################################################
sub fullname {                           # ;
    my $self = shift;

    $self->table->fullname . '.' . $self->name;
}


######################################################################
######################################################################
sub not_null {                           # ;
    my $self = shift;
    $self->{not_null} = shift if @_;
    $self->{not_null};
}


######################################################################
######################################################################
sub default {                            # ;
    my $self = shift;
    $self->{default} = shift if @_;
    $self->{default};
}


######################################################################
######################################################################
sub autoincrement {                      # ;
    my $self = shift;
    $self->{autoincrement} = shift if @_;
    $self->{autoincrement};
}


######################################################################
######################################################################
sub autoincrement_hint {                 # ;
    my $self = shift;

    my $map = $self->{autoincrement_hint} ||= {};
    return $map unless @_;

    my $key = shift;
    return $map->{$key} unless @_;

    $map->{$key} = shift;
}


######################################################################
######################################################################

package SQL::Admin::Catalog::Table::Column;

1;

