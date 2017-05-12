package Moonshine::Bootstrap::Component::Alert;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;
use Moonshine::Util;

lazy_components qw/a/;
extends 'Moonshine::Bootstrap::Component';

has(
    alert_spec => sub {
        {
            tag         => { default => 'div' },
            class_base  => { default => 'alert' },
            switch      => { default => 'success' },
            switch_base => { default => 'alert-' },
            link        => { type => HASHREF, optional => 1 },
        };
    }
);

sub alert {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->alert_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    if ( my $link = $build_args->{link} ) {
        $link->{class} = append_str('alert-link', $link->{class});
        $base_element->add_child( $self->a($link) );
    }

    return $base_element;    
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Alert

=head1 SYNOPSIS


    $self->alert({ class => 'search' });

returns a Moonshine::Element that renders too..

    <span class="alert"></span>

=cut

