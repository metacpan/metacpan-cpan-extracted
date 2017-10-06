package ObjectDB::Meta::Relationship::OneToMany;

use strict;
use warnings;

use base 'ObjectDB::Meta::Relationship';

our $VERSION = '3.24';

require Carp;

sub type     { 'one to many' }
sub is_multi { 1 }

sub to_source {
    my $self = shift;
    my (%options) = @_;

    my $name      = $self->name || Carp::croak('Name is required');
    my $table     = $self->orig_class->meta->table;
    my $rel_table = $self->class->meta->table;

    my ($from, $to) = %{ $self->{map} };

    my $constraint =
      [ "$table.$from" => { -col => "$name.$to" }, @{ $self->{constraint} || [] } ];

    my @columns;
    if ($options{columns}) {
        $options{columns} = [ $options{columns} ]
          unless ref $options{columns} eq 'ARRAY';
        @columns = @{ $options{columns} };
        unshift @columns, $self->class->meta->get_primary_key;
    }
    else {
        @columns = $self->class->meta->get_columns;
    }

    return {
        table      => $rel_table,
        as         => $name,
        join       => $self->{join},
        constraint => $constraint,
        columns    => [@columns]
    };
}

1;
