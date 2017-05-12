package Request;

sub new {
    my ($class, $params) = @_;

    return bless $params, $class;
}

1;

