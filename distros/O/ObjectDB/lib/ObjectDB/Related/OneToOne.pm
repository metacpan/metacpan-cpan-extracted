package ObjectDB::Related::OneToOne;

use strict;
use warnings;

use base 'ObjectDB::Related::ManyToOne';

our $VERSION = '3.28';

use Scalar::Util ();
use Storable qw(dclone);
use ObjectDB::Util qw(to_array);

sub create_related {
    my $self = shift;
    my ($row, $related) = @_;

    if (@$related > 1) {
        Carp::croak('cannot create multiple related objects in one to one');
    }

    my $meta = $self->meta;
    my ($from, $to) = %{ $meta->map };

    my @where = ($to => $row->column($from));

    if ($meta->class->find(first => 1, where => \@where)) {
        Carp::croak('Related object is already created');
    }

    $related = $related->[0];
    if (!Scalar::Util::blessed($related)) {
        $related = $meta->class->new(%$related);
    }
    $related->set_columns(@where);
    return $related->save;
}

sub update_related {
    my $self = shift;
    my ($row) = shift;

    return $self->_related_table->update($self->_build_params($row, @_));
}

sub delete_related {
    my $self = shift;
    my ($row) = shift;

    return $self->_related_table->delete($self->_build_params($row, @_));
}

sub _related_table { shift->meta->class->table }

sub _build_params {
    my $self     = shift;
    my ($row)    = shift;
    my (%params) = @_;

    my $meta = $self->meta;
    my ($from, $to) = %{ $meta->map };

    my $merged = dclone(\%params);
    $merged->{where} = [ $to => $row->column($from), to_array $merged->{where} ];

    return %$merged;
}

1;
