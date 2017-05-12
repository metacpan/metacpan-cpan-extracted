package Storm::Role::Query::IsExecutable;
{
  $Storm::Role::Query::IsExecutable::VERSION = '0.240';
}
use Moose::Role;

has '_sth' => (
    is  => 'ro'     ,
    isa => 'DBI::st',
    reader => '_sth',
    clearer => '_clear_sth',
    lazy_build => 1,
);

sub _build__sth {
    my $self = shift;
    return $self->dbh->prepare( $self->_sql );
}

no Moose::Role;
1;
