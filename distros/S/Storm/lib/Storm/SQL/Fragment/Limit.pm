package Storm::SQL::Fragment::Limit;
{
  $Storm::SQL::Fragment::Limit::VERSION = '0.240';
}
use Moose;

has '_limit'  => (
    is => 'rw' ,
    isa => 'Maybe[Int]',
);


sub BUILDARGS
{
    my $class  = shift;
    my $limit  = shift;
    
    # throw exception on bad arguments
    confess q[Usage: Storm::SQL::Fragment::Limit($self, $column)]
        if ! defined $limit;  
    
    #
    return {
        _limit  => $limit,
    };
}

sub sql {
    my $self = shift;
    
    my $sql = 'LIMIT ' . $self->_limit;
    return $sql;
}


no Moose;
__PACKAGE__->meta()->make_immutable();

1;
