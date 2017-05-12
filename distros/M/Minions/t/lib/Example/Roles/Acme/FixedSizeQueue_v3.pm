package Example::Roles::Acme::FixedSizeQueue_v3;

use Minions::Implementation
    has  => {
        max_size => { 
            init_arg => 'max_size',
        },
    }, 
    semiprivate => ['after_push'],
    roles => [qw/
        Example::Roles::Role::Queue
        Example::Roles::Role::LogSize
    /]
;

sub after_push {
    my (undef, $self) = @_;

    if ($self->size > $self->{$__max_size}) {
        $self->pop;        
    }
    $self->{$__}->log_info($self);
}

1;
