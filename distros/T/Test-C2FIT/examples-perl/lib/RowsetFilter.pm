#
#   Martin Busik <martin.busik@busik.de>
#
#
#

package RowsetFilter;
use base qw(Test::C2FIT::Fixture);

use vars qw($filteredRows);

sub new {
    my $pkg   = shift;
    my $types = {
        findByManagerId => 'NullFkWrapper',
        findById        => 'NullFkWrapper'
    };

    $filteredRows = [] unless defined($filteredRows);

    return $pkg->SUPER::new( @_, methodSetterTypeMap => $types );
}

sub clear {

    # no data in output
    $filteredRows = [];
}

sub allRows {
    $filteredRows = $NullValueTest::ourData;
}

sub rowCount {
    my $self = shift;
    return scalar(@$filteredRows);
}

sub findById {
    my ( $self, $id ) = @_;
    $self->doFilter( filterByFieldname( 'id', $id ) );
}

sub findByManagerId {
    my ( $self, $managerId ) = @_;
    $self->doFilter( filterByFieldname( 'manager_id', $managerId ) );
}

sub filterByFieldname {
    my ( $fieldname, $value ) = @_;

    return ( defined($value) )
      ? sub { $_[0]->{$fieldname} == $value }
      : sub { !defined( $_[0]->{$fieldname} ) };
}

sub doFilter {
    my ( $filter, $filterCode ) = @_;

    my @newRows = grep { $filterCode->($_) } @$NullValueTest::ourData;
    $filteredRows = \@newRows;
}

1;
