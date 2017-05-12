package DelayedService;

sub new {
    my ($class, $params) = @_;
    return bless { max => 20, list => [] }, $class;
}

sub AcceptRequest {
    my ($self, $params) = @_;
    my $requestNumber = $params->{requestNumber};
    push @{ $self->{list} }, $requestNumber;
    #print STDERR "Got request: $requestNumber\n";
    if ( $self->{max} <= @{ $self->{list} } ) {
        foreach my $req (@{ $self->{list} }) {
            #print STDERR "Replying to $req\n";
            STAF::DelayedAnswer($req, 0, "OK");
        }
        @{ $self->{list} } = ();
    }
    return $STAF::DelayedAnswer;
}

1;