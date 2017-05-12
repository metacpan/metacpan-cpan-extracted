# [[[ HEADER ]]]
package PhysicsPerl::Astro::BodyRenderer2D;
use strict;
use warnings;
use RPerl::AfterSubclass;
our $VERSION = 0.002_000;

# [[[ OO INHERITANCE ]]]
use parent qw(RPerl::CompileUnit::Module::Class);    # no non-system inheritance, only inherit from base class
use RPerl::CompileUnit::Module::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls) # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use PhysicsPerl::Astro::Body;
use SDLx::App;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    body     => my PhysicsPerl::Astro::Body $TYPED_body = undef,
    x_offset => my integer $TYPED_x_offset              = undef,
    y_offset => my integer $TYPED_y_offset              = undef,
    zoom     => my number $TYPED_zoom                   = undef
};

# [[[ OO METHODS & SUBROUTINES ]]]

our void::method $draw = sub {
    ( my PhysicsPerl::Astro::BodyRenderer2D $self, my SDLx::App $app ) = @_;

    # NEED FIX: remove hard-coded radius scaling factor
    $app->draw_circle_filled(
        [ ( ( $self->{body}->get_x() * $self->{zoom} ) + $self->{x_offset} ), ( ( $self->{body}->get_y() * $self->{zoom} ) + $self->{y_offset} ) ],
        $self->{body}->get_radius() * 20,
        [ @{ $self->{body}->get_color() }, 255 ]
    );

    # don't label the sun
    if ( $self->{body}->get_name() !~ /Sun/ ) {
        SDLx::Text->new(
            size  => 15,
            color => [ 255, 255, 255 ],
            text  => $self->{body}->get_name(),
            x => ( ( $self->{body}->get_x() * $self->{zoom} ) + $self->{x_offset} ) + 2,
            y => ( ( $self->{body}->get_y() * $self->{zoom} ) + $self->{y_offset} ),
        )->write_to($app);
    }
};

1;    # end of class
