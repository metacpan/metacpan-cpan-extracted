package TestModuleC;
use threads;
use threads::shared;

sub new {
    my $class = shift;
    my $self = &share({});
    return bless $self, $class;
}

sub call : locked method {
    my ($self) = @_;
    $self->{context} = wantarray;
}

sub get_context : locked method {
    my ($self) = @_;
    return $self->{context};
}

sub call_to_exit {
    exit 0;
}

sub call_to_die {
    die "DIED";
}

1;
