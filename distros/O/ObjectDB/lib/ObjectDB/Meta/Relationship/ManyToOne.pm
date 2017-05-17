package ObjectDB::Meta::Relationship::ManyToOne;

use strict;
use warnings;

use base 'ObjectDB::Meta::Relationship';

our $VERSION = '3.20';

sub type     { 'many to one' }
sub is_multi { 0 }

sub to_source {
    my $self = shift;
    my (%options) = @_;

    my $name      = $self->name;
    my $name_prefix = $options{name_prefix} || '';
    my $table     = $options{table} || $self->orig_class->meta->table;
    my $rel_table = $self->class->meta->table;

    my ($from, $to) = %{$self->{map}};

    my $constraint = [
        "$table.$from" => {-col => "$name_prefix$name.$to"},
        @{$self->{constraint} || []}
    ];

    my @columns;
    if ($options{columns}) {
        $options{columns} = [$options{columns}]
          unless ref $options{columns} eq 'ARRAY';
        @columns = @{$options{columns}};
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
