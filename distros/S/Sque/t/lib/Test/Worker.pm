package Test::Worker;

sub perform {
    my ( $job ) = @_;
    return $job->args;
}

1;
