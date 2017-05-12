package Storm::SQL::Fragment::OrderBy;
{
  $Storm::SQL::Fragment::OrderBy::VERSION = '0.240';
}
use Moose;

has '_column' => (
    is       => 'ro' ,
    required => 1    ,
);

has '_order'  => (
    is       => 'ro' ,
    default  => 'ASC',
);


sub BUILDARGS
{
    my $class             = shift;
    my $column = shift;
    my $order  = shift;
    
    # throw exception on bad arguments
    confess q[Usage: Storm::SQL::Fragment::OrderBy($self, $column, ['ASC' | 'DESC'])]
        if ! defined $column;  
    
    #
    return {
        _column  => $column,
        $order ?
          (_order => $order ) :
          ()
    };
    
}

sub sql {
    my $self = shift;
    my $sql = '';
    $sql = $self->_column->sql . ' ' . $self->_order;
    return $sql;
}


no Moose;
__PACKAGE__->meta()->make_immutable();

1;
