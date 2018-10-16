package ObjectDB::Related::ManyToMany;

use strict;
use warnings;

use base 'ObjectDB::Related';

our $VERSION = '3.28';

use Storable qw(dclone);
use ObjectDB::Util qw(to_array);

sub create_related {
    my $self = shift;
    my ($row, $related) = @_;

    my @row_objects;
    foreach my $related (@$related) {
        my $meta = $self->meta;

        if (!Scalar::Util::blessed($related)) {
            $related = $meta->class->new(%$related);
        }

        my $row_object;
        $row_object = $related if $related->is_in_db;
        $row_object ||= $related->load_or_create;

        my $map_from = $meta->map_from;
        my $map_to   = $meta->map_to;

        my ($from_foreign_pk, $from_pk) =
          %{ $meta->map_class->meta->get_relationship($map_from)->map };

        my ($to_foreign_pk, $to_pk) =
          %{ $meta->map_class->meta->get_relationship($map_to)->map };

        my $map_object = $meta->map_class->new(
            $from_foreign_pk => $row->get_column($from_pk),
            $to_foreign_pk   => $row_object->get_column($to_pk)
        );
        $map_object->create unless $map_object->load;

        push @row_objects, $row_object;
    }

    return @row_objects;
}

sub find_related {
    my $self = shift;
    my ($row) = shift;

    return $self->_related_table->find($self->_build_params($row, @_));
}

sub count_related {
    my $self = shift;
    my ($row) = shift;

    return $self->_related_table->count($self->_build_params($row, @_));
}

sub delete_related {
    my $self = shift;
    my ($row) = shift;

    return $self->_related_map_table->delete($self->_build_params($row, @_));
}

sub _related_table     { shift->meta->class->table }
sub _related_map_table { shift->meta->map_class->table }

sub _build_params {
    my $self     = shift;
    my ($row)    = shift;
    my (%params) = @_;

    my $meta = $self->meta;

    my $map_from = $meta->map_from;
    my $map_to   = $meta->map_to;

    my ($map_table_to, $map_table_from) =
      %{ $meta->map_class->meta->get_relationship($map_from)->map };

    my $table     = $meta->class->meta->table;
    my $map_table = $meta->map_class->meta->table;

    my $merged = dclone(\%params);
    $merged->{where} = [ "$map_table.$map_table_to" => $row->column($map_table_from), to_array $merged->{where} ];

    return %$merged;
}

1;
