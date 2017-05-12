package Initialize;

use Simple::Accessor qw{foo bar};

sub initialize {
    my ( $self, %opts ) = @_;

    $self->foo(51);

    $self->bar( $opts{rab} ) if $opts{rab};

    return \%opts;
}

sub _initialize_bar {
    1031;
}

1;
