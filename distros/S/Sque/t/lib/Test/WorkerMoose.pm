package Test::WorkerMoose;
use Moose;

has test => ( is => 'ro', default => 'test' );

sub perform {
    my ( $self, $job ) = @_;
    return $job->args;
}

1;
