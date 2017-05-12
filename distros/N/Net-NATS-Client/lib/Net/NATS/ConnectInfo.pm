package Net::NATS::ConnectInfo;

use Class::XSAccessor {
    constructors => [ '_new' ],
    accessors => [
        'verbose',
        'pedantic',
        'ssl_required',
        'auth_token',
        'user',
        'pass',
        'name',
        'lang',
        'version',
    ],
};

sub new {
    my $class = shift;
    my $self = $class->_new(@_);

    $self->verbose(0) unless $self->verbose;
    $self->pedantic(0) unless $self->pedantic;
    $self->ssl_required(0) unless $self->ssl_required;

    return $self;
}

sub TO_JSON {
    my $self = shift;
    my $hash = { %{ $self } };
    $hash->{verbose} = $self->verbose ? \1 : \0;
    $hash->{pedantic} = $self->pedantic ? \1 : \0;
    $hash->{ssl_required} = $self->ssl_required ? \1 : \0;
    return $hash;
}

1;
