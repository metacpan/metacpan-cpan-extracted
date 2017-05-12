#
# Martin Busik <martin.busik@busik.de>
#
package NullValueTest;
use base qw(Test::C2FIT::ColumnFixture);

use vars qw($ourData);    # static

#
# All Columns which ends on "id" or "ref" are field which need to be wrapped
#

sub suggestFieldType {
    my ( $self, $name ) = @_;

    return 'NullFkWrapper' if $name =~ /id$/i || $name =~ /ref$/i;
    return $self->SUPER::suggestFieldType;
}

sub reset {
    my $self = shift;
    $self->{id} = $self->{manager_id} = $self->{cname} = undef;
}

sub execute {
    my $self = shift;

    my $record = {
        id         => undef,
        manager_id => undef,
        cname      => undef
    };
    map { $record->{$_} = $self->{$_} } keys %$record;
    $ourData = [] unless ref($ourData);
    push( @$ourData, $record );
}

1;
