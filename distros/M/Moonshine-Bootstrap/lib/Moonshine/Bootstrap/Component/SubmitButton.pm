package Moonshine::Bootstrap::Component::SubmitButton;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Button',
);

has(
    submit_button_spec => sub {
        {
            type   => { default => 'submit' },
            switch => { default => 'default', base => 1 }, 
            data   => { default => 'Submit' }
        };
    }
);

sub submit_button {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->submit_button_spec,
        }
    );

    return $self->button($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::SubmitButton

=head1 SYNOPSIS

    $self->submit_button({ class => 'search' });

returns a Moonshine::Element that renders too..

    <button type="submit" class="btn btn-default">Submit</button>

=cut

