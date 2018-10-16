package ObjectDB::Quoter;

use strict;
use warnings;

our $VERSION = '3.28';

use base 'SQL::Composer::Quoter';

use List::Util qw(first);

sub new {
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;

    $self->{meta} = $params{meta};
    $self->{with} = [];

    return $self;
}

sub quote {
    my $self = shift;
    my ($column, $prefix) = @_;

    my @parts = split /[.]/xsm, $column;
    $column = pop @parts;

    my $meta = $self->{meta};
    my $rel_table;
    my $name;
    foreach my $part (@parts) {
        my $relationship = $meta->get_relationship($part);

        $name      = $name ? $name . '_' . $relationship->name : $relationship->name;
        $rel_table = $relationship->class->meta->table;
        $meta      = $relationship->class->meta;
    }

    if ($rel_table) {
        $column = $name . q{.} . $column;

        my $with = join q{.}, @parts;
        push @{ $self->{with} }, $with
          unless first { $_ eq $with } @{ $self->{with} };
    }

    return $self->SUPER::quote($column, $prefix);
}

sub with {
    my $self = shift;

    return @{ $self->{with} || [] };
}

1;
