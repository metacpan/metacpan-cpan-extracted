package Moonshine::Bootstrap::Component::Pager;

use Moonshine::Magic;
use Moonshine::Util;
use Params::Validate qw/ARRAYREF HASHREF/;

use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Pagination',
);

has(
    pager_spec => sub {
        {
            tag        => { default => 'ul' },
            class_base => { default => 'pager', base => 1 },
            items      => { type => ARRAYREF, optional => 1, base => 1 },
           	previous => {
                default => {
                    span => { data => 'Previous' },
                    link => { href => '#' },
                },
                type => HASHREF,
                base => 1,
            },
            next => {
                default => {
                    span => { data => 'Next' },
                    link => { href => "#" }
                },
                type => HASHREF,
                base => 1,
            },
            aligned => 0,
            disable => { build => 1, optional => 1 },
            nav      => { optional => 1, base => 1 },
            nav_args => { optional => 1, base => 1 }, 
        };
    },
);

sub pager {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->pager_spec,
        }
    );

    if ( $build_args->{aligned} ) {
        $base_args->{previous}->{class} .= 'previous';
        $base_args->{next}->{class}     .= 'next';
    }

    given ( $build_args->{disable} ) {
        my $dis = 'disabled';
        when ('previous') {
            $base_args->{previous}->{class} =
              prepend_str( $dis, $base_args->{previous}->{class} );
        }
        when ('next') {
            $base_args->{next}->{class} =
              prepend_str( $dis, $base_args->{next}->{class} );
        }
        when ('both') {
            $base_args->{next}->{class} =
              prepend_str( $dis, $base_args->{next}->{class} );
            $base_args->{previous}->{class} =
              prepend_str( $dis, $base_args->{previous}->{class} );
        }
	}

    return $self->pagination($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Pager

=head1 SYNOPSIS

    $self->pager({ class => 'search' });

returns a Moonshine::Element that renders too..

    <ul class="pager">
        <li><a href="#">Previous</a></li>
        <li><a href="#">Next</a></li>
    </ul>

=cut

