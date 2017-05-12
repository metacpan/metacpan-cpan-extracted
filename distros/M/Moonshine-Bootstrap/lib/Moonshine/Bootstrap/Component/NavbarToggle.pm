package Moonshine::Bootstrap::Component::NavbarToggle;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

lazy_components('span');

has(
    navbar_toggle_spec => sub {
        {
            tag           => { default => 'button' },
            type          => { default => 'button' },
            class_base    => { default => 'navbar-toggle collapsed' },
            data_toggle   => { default => 'collapse' },
            aria_expanded => { default => 'false' },
            i             => { default => 'icon-bar' },
            sr_text       => { default => 'Toggle navigation' },
            data_target   => 1,
        };
    }
);

sub navbar_toggle {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_toggle_spec,
        }
    );

    $base_args->{data_target} = sprintf "#%s", $base_args->{data_target};

    my $toggle = Moonshine::Element->new($base_args);

    $toggle->add_child(
        $self->span( { class => 'sr-only', data => $build_args->{sr_text} } ) );

    for ( 1 .. 3 ) {
        $toggle->add_child( $self->span( { class => $build_args->{i} } ) );
    }

    return $toggle;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarToggle

=head1 SYNOPSIS

    $self->navbar_toggle({  });

returns a Moonshine::Element that renders too..

    <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
    </button>

=cut

