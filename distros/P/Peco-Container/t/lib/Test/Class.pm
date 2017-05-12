package Test::Class;

sub new {
    my ( $class, $foo, $bar ) = @_;
    return bless {
        foo => $foo,
        bar => $bar,
    }, $class;
}

sub bar {
    my ( $self, $bar ) = @_;
    if ( @_ == 2 ) {
        $self->{bar} = $bar;
    }
    $self->{bar};
}

1;
