package # hide from PAUSE
    Local::Node::Hash2;

sub new {
    my $class = shift;
    my %attrs = @_;
    $attrs{parent} //= undef;
    $attrs{children} //= [];
    bless \%attrs, $class;
}

sub get_parent {
    my $self = shift;
    $self->{parent};
}

sub set_parent {
    my $self = shift;
    $self->{parent} = $_[0];
}

sub get_children {
    my $self = shift;

    # we deliberately do this for testing, to make sure that the node methods
    # can work with both children returning arrayref or list
    if (rand() < 0.5) {
        return $self->{children};
    } else {
        return @{ $self->{children} };
    }
}

sub set_children {
    my $self = shift;
    $self->{children};
}

sub get_id {
    my $self = shift;
    $self->{id};
}

sub set_id {
    my $self = shift;
    $self->{id} = $_[0];
}

1;
