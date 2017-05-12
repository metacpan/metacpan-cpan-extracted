package MySerializer;

sub new {
    bless {
	serialize => $_[1],
	deserialize => $_[2],
    }, $_[0]
}

sub serialize {
    my $self = shift;
    $self->{serialize}(@_);
}

sub deserialize {
    my $self = shift;
    $self->{deserialize}(@_);
}

1;
