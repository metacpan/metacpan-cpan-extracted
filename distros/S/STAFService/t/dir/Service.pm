package dir::Service;

sub new {
    my ($class, $params) = @_;
    print "Params: ", join(", ", map $_."=>".$params->{$_}, keys %$params), "\n";
    return bless {}, $class;
}

sub AcceptRequest {
    my ($self, $params) = @_;
    if ($params->{request} eq "Ping") {
        return (0, "Xong");
    }
    return (1, "ERROR");
}

1;