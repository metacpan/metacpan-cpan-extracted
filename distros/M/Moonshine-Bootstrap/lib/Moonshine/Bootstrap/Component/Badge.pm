package Moonshine::Bootstrap::Component::Badge;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';
use Params::Validate qw/HASHREF/;

has(
    badge_spec => sub {
        {
            tag        => { default => 'span' },
            wrapper    => { type    => HASHREF, optional => 1 },
            class_base => { default => 'badge' },
        };
    }
);

sub badge {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->badge_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    #---------.....----....---..--....
    if ( defined $build_args->{wrapper} ) {
        my $wrapper = Moonshine::Element->new( $build_args->{wrapper} );
        $wrapper->add_child($base_element);
        return $wrapper;
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Badge

=head1 SYNOPSIS

    $self->badge({ data => '42', wrapper => { tag => 'button' });

returns a Moonshine::Element that renders too..

    <button ...<span class="badge">42</span></button>

=cut

