package Moonshine::Bootstrap::Component::Progress;

use Moonshine::Magic;

use Params::Validate qw/HASHREF ARRAYREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::ProgressBar',
);

has(
    progress_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'progress' },
            bar        => { type => HASHREF, optional => 1},
            stacked    => { type => ARRAYREF, default => [ ]},
        };
    }
);

sub progress {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->progress_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);
    
    if ( my $bar = $build_args->{bar} ) {
        $base_element->add_child( $self->progress_bar($bar) );
    }

    for ( @{ $build_args->{stacked} } ) {
        $base_element->add_child( $self->progress_bar($_) );
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Progress

=head1 SYNOPSIS

    $self->progress({ class => 'search' });

returns a Moonshine::Element that renders too..

    <div class="progress"></div>

=cut

