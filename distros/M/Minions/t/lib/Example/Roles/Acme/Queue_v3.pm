package Example::Roles::Acme::Queue_v3;

use Minions::Implementation
    roles => [qw/
        Example::Roles::Role::Pushable
        Example::Roles::Role::LogSize
    /],

    requires => {
        attributes => [qw/items/]
    },
    attr_style => 'uc'
;

sub pop {
    my ($self) = @_;

    $self->log_info;
    shift @{ $self->{$ITEMS} };
}

1;
