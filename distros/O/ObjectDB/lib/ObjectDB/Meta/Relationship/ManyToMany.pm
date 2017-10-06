package ObjectDB::Meta::Relationship::ManyToMany;

use strict;
use warnings;

use base 'ObjectDB::Meta::Relationship';

our $VERSION = '3.24';

use ObjectDB::Util qw(load_class);

sub new {
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;

    $self->{map_class} = $params{map_class};
    $self->{map_from}  = $params{map_from};
    $self->{map_to}    = $params{map_to};

    return $self;
}

sub type     { 'many to many' }
sub is_multi { 1 }

sub map_to   { $_[0]->{map_to} }
sub map_from { $_[0]->{map_from} }

sub map_class {
    my $self = shift;

    my $map_class = $self->{map_class};

    load_class $map_class;

    return $map_class;
}

sub class {
    my $self = shift;

    return $self->{class} if $self->{class};

    $self->{class} =
      $self->map_class->meta->get_relationship($self->{map_to})->class;

    return $self->{class};
}

sub to_source {
    my $self = shift;
    my (%options) = @_;

    my ($map_from, $map_to) =
      %{ $self->map_class->meta->get_relationship($self->{map_from})->map };
    my ($rel_from, $rel_to) =
      %{ $self->map_class->meta->get_relationship($self->{map_to})->map };

    my $orig_table = $self->orig_class->meta->table;
    my $map_table  = $self->map_class->meta->table;
    my $rel_table  = $self->class->meta->table;

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

    my $name = $self->name;

    return {
        table      => $map_table,
        as         => $map_table,
        join       => 'left',
        constraint => [ "$orig_table.$map_to" => { -col => "$map_table.$map_from" } ]
      },
      {
        table      => $rel_table,
        as         => $name,
        join       => 'left',
        constraint => [ "$map_table.$rel_from" => { -col => "$name.$rel_to" } ],
        columns    => [@columns]
      };
}

1;
