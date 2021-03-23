package Spreadsheet::Compare::Record;

use Mojo::Base -base, -signatures;
use B qw();

# own attributes
has [qw(h2i reader rec sln)];

has limit_mask => sub { [] };

has diff_info => sub { {} };

has id => sub {
    my $identity = $_[0]->reader->identity;
    my @parts    = map { $_[0]->val($_) } @$identity;
    return join( '_', @parts );
};

has hash => sub {
    B::hash( join( '', grep { defined } @{ $_[0]->rec } ) );
};

has side => sub { $_[0]->reader->side };

has side_name => sub { $_[0]->reader->side_name };

sub val { return $_[0]->{rec}[ $_[0]->{h2i}->{ $_[1] } ] // '' }

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{h2i} //= $self->reader->h2i;
    return $self;
}


1;


=head1 NAME

Spreadsheet::Compare::Record - Class Representing a Single Record

=head1 SYNOPSIS

    use Spreadsheet::Compare::Record;
    my $rec = Spreadsheet::Compare::Record->new(
        rec    => \@record,
        reader => $reader_object;
    );

=head1 DESCRIPTION

Spreadsheet::Compare::Record represents a single record read by one of the reader classes.
It will normally be of little interest unless you are developing a new Reader class.

=head1 ATTRIBUTES

=head2 diff_info

A reference to a hash with summary information from the comparison with the corresponding
record on the opposite side. Modification (don't do that) will also modify the corresponding
record, the reference is shallow. It has the following structure:

    {
        ABS_FIELD => <name of the column with highest absolute deviation>,
        ABS_VALUE => <highest absolute deviation>,
        REL_FIELD => <name of the column with highest relative deviation>,
        REL_VALUE => <highest relative deviation>,
        limit     => <true if all deviations are below their configured limits>,
        equal     => <true if the records are considered equal>,
    };

=head2 h2i

=head2 hash

A hash value set by the reader. If the hash values for two record match, they are
considered equal and no detailed comparisons will take place. This enhances
performance significantly.

=head2 id

The id of the record constructed from the configuration value of
L<Spreadsheet::Compare::Reader/identity>

=head2 limit_mask

A reference to a hash with information from the comparison with the corresponding
record on the opposite side. Modification (don't do that) will also modify the corresponding
record, the reference is shallow. It has the following structure:

    {
        <columnindex> => [-1|0|1],
        ...
    }

with 0 means the values are equal, 1 means the values differ and -1 means they differ
but the deviation is below the configured limits.

=head2 reader

The L<Spreadsheet::Compare::Reader> object the record belongs to.

=head2 rec

A reference to an array with the record values.

=head2 side

A shortcut for $self->reader->side

=head2 side_name

A shortcut for $self->reader->side_name

=head2 sln

Source line number for the record, if the reader provides it (eg. file based readers).

=head1 METHODS

=head2 val($index)

Return the value at column index $index.

=cut
