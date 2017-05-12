package FailToCompile;
use XXXXXXXXXXXXXX;

sub new {
    my ($class, $params) = @_;
    print "Params: ", join(", ", map $_."=>".$params->{$_}, keys %$params), "\n";
    return bless {}, $class;
}

sub AcceptRequest {
    my ($self, $params) = @_;
    if ($params->{request} eq "Ping") {
        return (0, "Pong");
    } elsif ($params->{request} eq "Error") {
        return (1, "There was an error");
    } elsif ($params->{request} eq "Die") {
        die "Committing suicide";
    }
}

1;