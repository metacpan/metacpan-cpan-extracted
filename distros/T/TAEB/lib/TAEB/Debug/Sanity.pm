package TAEB::Debug::Sanity;
use TAEB::OO;
with 'TAEB::Role::Config';

has enabled => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub {
        my $self = shift;
        return 0 if !$self->config;
        return $self->config->{enabled}
    },
    lazy    => 1,
);

sub msg_step {
    my $self = shift;

    TAEB->enqueue_message('sanity') if $self->enabled;
}

sub msg_key {
    my $self = shift;
    my $key  = shift;

    return if $key ne 'S';

    $self->enabled(!$self->enabled);

    TAEB->notify("Global per-turn sanity checks now " .
        ($self->enabled ? "en" : "dis") . "abled.");
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;
