package Example::Roles::Role::Pushable;

use Minions::Role
    has  => {
        items => { default => sub { [ ] } },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$ITEMS} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$ITEMS} }, $val;
}

1;
