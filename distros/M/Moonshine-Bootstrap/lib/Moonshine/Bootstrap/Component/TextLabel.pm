package Moonshine::Bootstrap::Component::TextLabel;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    text_label_spec => sub {
        {
            data        => 1,
            tag         => { default => 'span' },
            class_base  => { default => 'label' },
            switch      => { default => 'default' },
            switch_base => { default => 'label-' },
        };
    }
);

sub text_label {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->text_label_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::TextLabel

=head1 SYNOPSIS

    $self->text_label({ class => 'search' });

returns a Moonshine::Element that renders too..

    <span class="label label-default">Default</span>

=cut

