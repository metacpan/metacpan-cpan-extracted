package Moonshine::Bootstrap::Component::Jumbotron;

use Moonshine::Magic;

lazy_components qw/div h1 p span/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Button',
);

has(
    jumbotron_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'jumbotron' },
            full_width => 0,
        };
    }
);

sub jumbotron {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->jumbotron_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    if ( defined $build_args->{full_width} ) {
        $base_element->add_child( $self->div( { class => 'container' } ) );
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Jumbotron

=head1 SYNOPSIS

    $self->jumbotron({ class => 'search' });

returns a Moonshine::Element that renders too..


    <div class="jumbotron">
        ...
    </div>

=cut

