package Hooks;

use Simple::Accessor qw{cherry kiwi apple invalid};

sub _before_kiwi {
    my ( $self, $v ) = @_;

    # invalidate false values
    return $v;
}

sub _validate_kiwi {
    my ( $self, $v ) = @_;

    # if $v ...
    1;
}

sub _after_kiwi {
    my ($self) = @_;

    $self->apple( $self->kiwi() );
}

# nothing is valid for cherry
sub _validate_invalid {
    0;
}

1;
