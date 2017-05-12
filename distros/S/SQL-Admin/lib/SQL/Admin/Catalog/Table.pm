
package SQL::Admin::Catalog::Table;
use base qw( SQL::Admin::Catalog::Object );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################
######################################################################
sub add {                                # ;
    my ($self, $what, @params) = @_;

    return unless $self->catalog;

    return $self->table_row (@params)
      if $what eq 'table_row';

    ##################################################################

    my $obj = $self->catalog->add ($what, table => $self, @params);

    ##################################################################

    return $self->column ($obj->name, $obj)
      if $what eq 'column';

    return $self->primary_key ($obj)
      if $what eq 'primary_key';

    return $self->unique ($obj->fullname, $obj)
      if $what eq 'unique';

    return $self->foreign_key ($obj->fullname, $obj)
      if $what eq 'foreign_key';

}


######################################################################
######################################################################
sub column {                             # ;
    my $self = shift;
    my $map = $self->{column_map} ||= {};

    return $map unless @_;

    my $name = shift;
    return unless defined $name;

    return $map->{$name} unless @_;

    my $col = shift;
    my $list = $self->{column_list} ||= [];

    push @$list, $col->name
      unless exists $map->{$name};

    $map->{$name} = $col;
}


######################################################################
######################################################################
sub columns {                            # ;
    my $retval = shift->{column_list} ||= [];

    return $retval unless wantarray;
    return @$retval;
}


######################################################################
######################################################################
sub option {                             # ;
    my $self = shift;
    return $self->{option} ||= {} unless @_;

    my $key = shift;
    return $self->{option}{ $key } unless @_;

    $self->{option}{$key} = shift;
}


######################################################################
######################################################################
sub primary_key {                        # ;
    my $self = shift;

    $self->{primary_key} = shift if @_;
    $self->{primary_key};
}


######################################################################
######################################################################
sub unique {                             # ;
    my $self = shift;

    my $map = $self->{unique} ||= {};
    return $map unless @_;

    my $key = shift;
    return $map->{$key} unless @_;

    $map->{$key} = shift;
}


######################################################################
######################################################################
sub foreign_key {                        # ;
    my $self = shift;

    my $map = $self->{foreign_key} ||= {};
    return $map unless @_;

    my $key = shift;
    return $map->{$key} unless @_;

    $map->{$key} = shift;
}


######################################################################
######################################################################
sub table_row {                          # ;
    my $self = shift;

    my $list = $self->{table_row} ||= [];
    return $list unless @_;

    push @$list, @_;
}


######################################################################
######################################################################
sub set_row_search {                     # ;
    my $self= shift;
    $self->{row_search} = shift;
}


######################################################################
######################################################################
sub row_search {                         # ;
    # simple query, just key-value pair
    my ($self, $query) = @_;

    return $self->{row_search}->($self, $query)
      if $self->{row_search};

}


######################################################################
######################################################################

package SQL::Admin::Catalog::Table;

1;

