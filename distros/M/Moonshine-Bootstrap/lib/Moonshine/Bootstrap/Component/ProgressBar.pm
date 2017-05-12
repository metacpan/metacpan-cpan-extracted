package Moonshine::Bootstrap::Component::ProgressBar;

use Moonshine::Magic;

use Moonshine::Util;

lazy_components qw/span/;

extends 'Moonshine::Bootstrap::Component';

has(
    progress_bar_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'progress-bar' },
            role       => { default => 'progressbar' },
            aria_valuenow => 1,
            aria_valuemin => { default => "0" },
            aria_valuemax => { default => 100 },
            style   => { default => ["min-width:3em;"] },
            switch_base => { default => 'progress-bar-' },
            striped => 0,
            show => 0,
            animated => 0,
        };
    }
);

sub progress_bar {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->progress_bar_spec,
        }
    );

    if ( $build_args->{striped} ) {
       $base_args->{class} = prepend_str('progress-bar-striped', $base_args->{class}); 
    }


    my $percent = $base_args->{aria_valuenow} . "%";

    push @{ $base_args->{style} }, sprintf 'width:%s;', $percent;

    my $base_element = Moonshine::Element->new($base_args);

    if ( $build_args->{show} ) {
        $base_element->data($percent);
    }
    else {
        $base_element->add_child(
            $self->span( { class => 'sr-only', data => $percent } ) 
		);
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ProgressBar

=head1 SYNOPSIS

    $self->progress_bar({ });

returns a Moonshine::Element that renders too..
 
    <div class="progress-bar" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width: 60%;">
        60%
    </div>

=cut

