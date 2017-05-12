package Example::Roles::Acme::FixedSizeQueue_v2;

use Minions::Implementation
    has  => {
        max_size => { 
            init_arg => 'max_size',
        },
    }, 
    semiprivate => ['after_push'],
    roles => ['Example::Roles::Role::Queue']
;

sub after_push {
    my (undef, $self) = @_;

    if ($self->size > $self->{$MAX_SIZE}) {
        $self->pop;        
    }
}

1;
