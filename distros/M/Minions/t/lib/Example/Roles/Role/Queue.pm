package Example::Roles::Role::Queue;

use Minions::Role
    has  => {
        q => { default => sub { [ ] } },
    }, 
    semiprivate => ['after_push'],
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$Q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$Q} }, $val;

    $self->{$__}->after_push($self);
}

sub pop {
    my ($self) = @_;
    shift @{ $self->{$Q} };
}

sub after_push { }

1;
