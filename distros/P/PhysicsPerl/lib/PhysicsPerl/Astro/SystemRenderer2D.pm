# [[[ HEADER ]]]
package PhysicsPerl::Astro::SystemRenderer2D;
use strict;
use warnings;
use RPerl::AfterSubclass;
our $VERSION = 0.003_000;

# [[[ OO INHERITANCE ]]]
use parent qw(RPerl::CompileUnit::Module::Class);    # no non-system inheritance, only inherit from base class
use RPerl::CompileUnit::Module::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls) # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use PhysicsPerl::Astro::System;
use PhysicsPerl::Astro::Body;
use PhysicsPerl::Astro::BodyRenderer2D;
use Time::HiRes qw(time);
use SDL;
use SDL::Event;
use SDL::Video;
use SDLx::App;
#use SDLx::Sprite;
use SDLx::Text;

# [[[ OO PROPERTIES ]]]
our hashref $properties = { 
    system => my PhysicsPerl::Astro::System $TYPED_system = undef,
    delta_time => my number $TYPED_delta_time = undef,
    time_step_max => my integer $TYPED_time_step_max = undef,
    time_step_current => my integer $TYPED_time_step_current = undef,
    time_steps_per_frame => my integer $TYPED_time_steps_per_frame = undef,
    time_start => my number $TYPED_time_start = undef,
    window_title => my string $TYPED_window_title = undef,
    window_width => my integer $TYPED_window_width = undef,
    window_height => my integer $TYPED_window_height = undef,
    zoom => my number $TYPED_zoom = undef,
    body_renderer2d => my PhysicsPerl::Astro::BodyRenderer2D $TYPED_body_renderer2d = undef,
    app => my SDLx::App $TYPED_app = undef
};

# [[[ OO METHODS & SUBROUTINES ]]]

our void::method $init = sub {
    ( my PhysicsPerl::Astro::SystemRenderer2D $self, my PhysicsPerl::Astro::System $system, my number $delta_time, my integer $time_step_max, my integer $time_steps_per_frame, my number $time_start ) = @_;

    $self->{system} = $system;
    $self->{delta_time} = $delta_time;
    $self->{time_step_max} = $time_step_max;
    $self->{time_step_current} = 0;
    $self->{time_steps_per_frame} = $time_steps_per_frame;
    $self->{time_start} = $time_start;

    # NEED FIX: remove hard-coded window size
    $self->{window_title} = 'N-Body Solar System Simulator';
    $self->{window_width} = 640;
    $self->{window_height} = 480;
    $self->{zoom} = 6;
#    $self->{window_width} = 1440;
#    $self->{window_height} = 900;
#    $self->{zoom} = 12;
    $self->{body_renderer2d} = PhysicsPerl::Astro::BodyRenderer2D->new();  # one body renderer used for all bodies in system
    $self->{body_renderer2d}->{x_offset} = $self->{window_width} / 2;  # offset coordinates so (0,0) maps to center of window, not upper-left corner
    $self->{body_renderer2d}->{y_offset} = $self->{window_height} / 2;
    $self->{body_renderer2d}->{zoom} = $self->{zoom};

    SDL::init(SDL_INIT_VIDEO);

    $self->{app} = SDLx::App->new(
        title => $self->{window_title},
        width => $self->{window_width},
        height => $self->{window_height},
        delay => 15
    );
};

our void::method $events = sub {
    ( my PhysicsPerl::Astro::SystemRenderer2D $self, my SDL::Event $event, my SDLx::App $app ) = @_;
    if ($event->type() == SDL_QUIT) { $app->stop(); }
};

our void::method $show = sub {
    ( my PhysicsPerl::Astro::SystemRenderer2D $self, my number $dt, my SDLx::App $app ) = @_;
    SDL::Video::fill_rect( $app, SDL::Rect->new(0, 0, $app->w(), $app->h()), 0 );

    my PhysicsPerl::Astro::Body $body_i;
 
    for my integer $i (0 .. ($self->{system}->get_bodies_size() - 1)) {
        $body_i = $self->{system}->get_bodies_element($i);
        
        # NEED FIX: create set_x() Perl shim to pass-by-reference to set_x_rawptr() C++ code
        # DEV NOTE: set_bodies_element() required for pass-by-value set_x() but not pass-by-reference set_color()
        # TMP DEBUG
#        $body_i->set_x($body_i->get_x() - 1);
#        $self->{system}->set_bodies_element($i, $body_i);
#        $body_i->set_color([200, 200, 200]);

        $self->{body_renderer2d}->{body} = $body_i;
        $self->{body_renderer2d}->draw($app);
    }
    
    my string $status = q{};
    my string $status_tmp;
    $status .= 'Time, Step: ' . ::number_to_string($self->{time_step_current}) . ' of ' . ::number_to_string($self->{time_step_max}) . "\n";
    $status_tmp = ::number_to_string($self->{delta_time} * $self->{time_step_current});
    $status_tmp =~ s/[.].*//xms;  # sim time, 0 characters after decimal
    $status .= 'Time, Sim:  ' . $status_tmp . ' of ' . ::number_to_string($self->{delta_time} * $self->{time_step_max}) . "\n";
    my number $time_elapsed = time() - $self->{time_start};
    $status_tmp = ::number_to_string($time_elapsed);
    $status_tmp =~ s/([.].{1}).*/$1/xms;  # real time elapsed, 1 character after decimal
    $status .= 'Time, Real: ' . $status_tmp;
    $status_tmp = ::number_to_string($time_elapsed * ($self->{time_step_max} / $self->{time_step_current}));
    $status_tmp =~ s/([.].{1}).*/$1/xms;  # real time total estimate, 1 character after decimal
    $status .= ' of ' . $status_tmp . "\n";
    $status_tmp =  ($self->{time_step_current} / $self->{time_step_max}) * 100;
    $status_tmp =~ s/[.].*//xms;  # sim time, 0 characters after decimal
    $status .= 'Completion: ' . $status_tmp . '%';
    $status_tmp = ::number_to_string($self->{time_step_current} / $time_elapsed);
    $status_tmp =~ s/[.].*//xms;  # steps per real time, 0 characters after decimal
    $status .= ' at ' . $status_tmp . ' Steps / Second' . "\n";
    $status_tmp = ::number_to_string($self->{system}->energy());
    $status_tmp =~ s/([.].{11}).*/$1/xms;  # energy, 11 characters after decimal
    $status .= 'Energy:     ' . $status_tmp . "\n";

    # NEED FIX: remove hard-coded font path
    SDLx::Text->new(
        font    => 'fonts/VeraMono.ttf',
        size    => 15,
        color   => [255, 255, 255],
        text    => $status,
        x       => 10,
        y       => 10,
    )->write_to($app);

    $app->update();
};

our void::method $move = sub {
    ( my PhysicsPerl::Astro::SystemRenderer2D $self, my number $dt, my SDLx::App $app, my number $t ) = @_;
    # don't overshoot your time_step_max
    if (($self->{time_step_current} + $self->{time_steps_per_frame}) > $self->{time_step_max}) {
        $self->{time_steps_per_frame} = $self->{time_step_max} - $self->{time_step_current};
    }
    $self->{system}->advance_loop($self->{delta_time}, $self->{time_steps_per_frame});
    $self->{time_step_current} += $self->{time_steps_per_frame};
    if ($self->{time_step_current} >= $self->{time_step_max}) { $app->stop(); }
};

our void::method $render2d_video = sub {
    ( my PhysicsPerl::Astro::SystemRenderer2D $self ) = @_;

    $self->{app}->add_event_handler( sub { $self->events(@_) } );
    $self->{app}->add_show_handler( sub { $self->show(@_) } );
    $self->{app}->add_move_handler( sub { $self->move(@_) } );

#    $self->{app}->fullscreen();
    $self->{app}->run();
};

1;    # end of class
