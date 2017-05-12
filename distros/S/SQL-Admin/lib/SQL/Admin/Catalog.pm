
package SQL::Admin::Catalog;

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

use SQL::Admin::Catalog::Schema;
use SQL::Admin::Catalog::Sequence;
use SQL::Admin::Catalog::Index;
use SQL::Admin::Catalog::Table;
use SQL::Admin::Catalog::Table::Column;
use SQL::Admin::Catalog::Table::PrimaryKey;
use SQL::Admin::Catalog::Table::Unique;
use SQL::Admin::Catalog::Table::ForeignKey;

######################################################################

use List::Util;

our $NAME_TRANSFORM = {
    NAME    => sub { $_[0] },
    NAME_lc => sub { lc $_[0] },
    NAME_uc => sub { uc $_[0] },
};

######################################################################

my $class_map = {
    schema      => 'SQL::Admin::Catalog::Schema',
    sequence    => 'SQL::Admin::Catalog::Sequence',
    table       => 'SQL::Admin::Catalog::Table',
    index       => 'SQL::Admin::Catalog::Index',
    column      => 'SQL::Admin::Catalog::Table::Column',
    primary_key => 'SQL::Admin::Catalog::Table::PrimaryKey',
    unique      => 'SQL::Admin::Catalog::Table::Unique',
    foreign_key => 'SQL::Admin::Catalog::Table::ForeignKey',
};

######################################################################
######################################################################
sub new {                                # ;
    my ($class, %param) = @_;

    $param{FetchHashKeyName} = 'NAME_uc'
      unless $param{FetchHashKeyName};

    $param{FetchHashKeyName} = 'NAME'
      unless exists $NAME_TRANSFORM->{ $param{FetchHashKeyName} };

    ##################################################################

    bless {
        name_transform => $NAME_TRANSFORM->{ $param{FetchHashKeyName} },
        allow_redeclare => 1,

        (map +($_ => {}), keys %$class_map),
    }, ref $class || $class;
}


######################################################################
######################################################################
sub catalog {                            # ;
    $_[0];
}


######################################################################
######################################################################
sub add {                                # ;
    my ($self, $type, %param) = @_;

    return unless exists $class_map->{$type};

    my $typemap = $self->{$type}  ||= {};

    ##################################################################

    $param{schema} = $self->{default_schema}
      if ! $param{schema} and $self->{default_schema};

    my $obj = $self->get ($type, %param, catalog => $self);

    ##################################################################

    if (my $schema = $obj->schema) {
        $self->{schema}{$schema} ||= $class_map->{schema}->new (name => $schema);
    }

    ##################################################################

    $typemap->{ $obj->fullname } ||= $obj;
}


######################################################################
######################################################################
sub get {                                # ;
    my ($self, $type, %param) = @_;

    return
      unless exists $class_map->{$type};

    ##################################################################

    # my $obj = $class_map->{$type}->new (%param, catalog => $self);
    my $obj = $class_map->{$type}->new (%param);
    my $key = $obj->fullname;

    $obj = $self->{$type}{ $key }
      if exists $self->{$type}{ $key };

    ##################################################################

    return $obj;
}


######################################################################
######################################################################
sub exists {                             # ;
    my ($self, $type, @list) = @_;

    return
      unless exists $class_map->{$type};

    my $key;
    $key = 1 == @list ? $list[0] : $class_map->{$type}->new (@list);
    $key = $key->fullname if ref $key;

    return exists $self->{$type}{ $key } && $key;
}


######################################################################
######################################################################
sub list {                               # ;
    my ($self, $type) = @_;

    +{ %{ $self->{$type} || {} } };
}


######################################################################
######################################################################
sub add_statement {                      # ;
    my $self = shift;
    my $list = $self->{statements} ||= [];

    push @$list, @_;
}


######################################################################
######################################################################
sub load {                               # ;
    my ($self, $driver, @params) = @_;

    $driver = SQL::Admin->get_driver ($driver, @{ shift @params || [] } )
      unless ref $driver;

    $driver->load ($self, @params);

    $self;
}


######################################################################
######################################################################
sub save {                               # ;
    my ($self, $driver, @params) = @_;

    $driver = SQL::Admin->get_driver ($driver, @{ shift @params || [] } )
      unless ref $driver;

    $driver->save ($self, @params);

    $self;
}


######################################################################
######################################################################

package SQL::Admin::Catalog;

1;

__END__

=pod

=head1 NAME

SQL::Admin::Catalog

=head1 DESCRIPTION

=head2 Commands

command is a pair (hashref) of command name and data.

=head3 create_sequence

Data is hashref with keys:

=over

=item sequence_name

schema qualified name (href with name and optional schema)

=item sequence_type

sequence datatype

=item sequence_options

=over

=item start_with integer

Sequence starting value

=item increment_by integer

Sequence step

=item minvalue integer

=item maxvalue integer

min/max values

=item cycle (flag)

if exists, sequence can cycle

=item order (flag)

if exists, sequence must generate values in request order

=item cache positive-integer

=back

=back


