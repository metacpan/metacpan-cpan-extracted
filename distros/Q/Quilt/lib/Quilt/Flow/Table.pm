#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Table.pm,v 1.2 1997/10/25 00:00:33 ken Exp $
#

use Quilt;

use strict;

package Quilt::Flow::Table;

sub num_parts {
    my $self = shift;

    return $#{$self->contents} + 1;
}

sub parts {
    my $self = shift;

    return $self->contents;
}

sub num_rows {
    my $self = shift;
    my $rows = 0;
    my $part;

    if (!defined $self->{'num_rows'}) {
	foreach $part (@{$self->parts}) {
	    $rows += $part->num_rows;
	}
	$self->{'num_rows'} = $rows;
    }

    return $self->{'num_rows'};
}

sub num_columns {
    my $self = shift;

    if (!defined $self->{'num_columns'}) {
	my $max_columns = 0;
	my ($columns, $part);

	foreach $part (@{$self->parts}) {
	    $columns = $part->num_columns;
	    $max_columns = $columns
		if ($columns >$max_columns);
	}
	$self->{'num_columns'} = $max_columns;
    }

    return $self->{'num_columns'};
}

package Quilt::Flow::Table::Part;

# we are type compatible with a whole table
sub num_parts {
    return 1;
}

sub parts {
    my $self = shift;

    return [$self];
}

sub num_rows {
    my $self = shift;

    return $#{$self->contents} + 1;
}

sub num_columns {
    my $self = shift;

    if (!defined $self->{'num_columns'}) {
	my $max_columns = 0;
	my ($columns, $row);

	foreach $row (@{$self->rows}) {
	    $columns = $row->num_columns;
	    $max_columns = $columns
		if ($columns >$max_columns);
	}
	$self->{'num_columns'} = $max_columns;
    }

    return $self->{'num_columns'};
}

sub rows {
    my $self = shift;

    return $self->contents;
}

package Quilt::Flow::Table::Row;
sub num_columns {
    my $self = shift;

    return $#{$self->contents} + 1;
}

sub entries {
    my $self = shift;

    return $self->contents;
}

package Quilt::Flow::Table::Cell;

1;
