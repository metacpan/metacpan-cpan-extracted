package RackTables::Types;

use strict;
use Exporter "import";


our @EXPORT = qw< RT_INTEGER RT_UNSIGNED RT_STRING >;

use constant RT_INTEGER => (
    data_type   => "integer",
    is_numeric  => 1,
    is_nullable => 0,
);

use constant RT_UNSIGNED => (
    RT_INTEGER,
    extra       => { unsigned => 1 },
);

use constant RT_STRING => (
    data_type   => "char",
    size        => 255,
);


__PACKAGE__

__END__

=head1 NAME

RackTables::Types - Common RackTables types

=head1 SYNOPSIS

    # in a DBIx::Class view definition
    use RackTables::Types;

    __PACKAGE__->add_columns(
        id        => { RT_UNSIGNED },
        name      => { RT_STRING, is_nullable => 0 },
        ...
    }

=head1 DESCRIPTION

This modules defines common RackTables types, in order to ease writing
DBIx::Class view definitions.

=head1 TYPES

The following types are defined and exported:

=over

=item * RT_INTEGER

integer, non-nullable

=item * RT_UNSIGNED

unsigned integer, non-nullable

=item * RT_STRING

string, default size of 255 characters (override with a C<size> attribute)

=back


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

