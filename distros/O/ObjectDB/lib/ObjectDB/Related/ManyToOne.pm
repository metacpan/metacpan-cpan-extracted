package ObjectDB::Related::ManyToOne;

use strict;
use warnings;

use base 'ObjectDB::Related';

our $VERSION = '3.20';

use ObjectDB::Util qw(merge);

sub find_related {
    my $self = shift;
    my ($row) = shift;

    my $meta = $self->meta;
    my ($from, $to) = %{$meta->map};

    return unless defined $row->column($from) && length $row->column($from);

    return $self->_related_table->find(
        $self->_build_params($row, @_, single => 1));
}

sub _related_table { shift->meta->class->table }

sub _build_params {
    my $self = shift;
    my ($row) = shift;

    my $meta = $self->meta;
    my ($from, $to) = %{$meta->map};

    my $params = merge { @_ }, {where => [$to => $row->column($from)]};
    return %$params;
}

1;
