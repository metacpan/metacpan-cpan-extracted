#
#   Martin Busik <martin.busik@busik.de>
#

package FilteredData;
use base qw(Test::C2FIT::RowFixture);

#
# All Columns which ends on "id" or "ref" are field which need to be wrapped
#

sub suggestFieldType {
    my ( $self, $name ) = @_;

    return 'NullFkWrapper' if $name =~ /id$/i || $name =~ /ref$/i;
    return $self->SUPER::suggestFieldType;
}

sub query {
    my $self = shift;
    return $RowsetFilter::filteredRows;
}

1;
