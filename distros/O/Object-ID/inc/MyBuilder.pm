package MyBuilder;

use base qw(Module::Build);

sub get_metadata {
    my $self = shift;
    my $data = $self->SUPER::get_metadata(@_);

    delete $data->{provides}{UNIVERSAL};
    return $data;
}

1;
