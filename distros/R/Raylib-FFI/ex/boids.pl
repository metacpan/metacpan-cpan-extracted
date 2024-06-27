#!/usr/bin/env perl
use 5.40.0;
use lib qw(lib);
use experimental 'class';

use Raylib::App;

class ECS {
    use Carp qw(confess);
    field $systems : param;

    field @entities   = ();
    field @empty_slots = ();
    field %components = ();

    method entity_count {
        return scalar grep defined, @entities;
    }

    method add_entity() {
        if (@empty_slots) {
            return shift @empty_slots;
        }
        return push @entities, {};
    }

    method destroy_entity ($entity) {
        $entities[$entity] = undef;
        push @empty_slots => $entity;
    }

    method add_component ( $entity, $component ) {
        $entities[$entity]{ ref $component } = $component;
        push $components{ ref $component }->@*, $entity;
    }

    method entities_with (@components) {
        return grep defined,
          @entities[ map { $_->@* } @components{@components} ];
    }

    method update () {
        for my $system ( $systems->@* ) {
            $system->update($self);
        }
    }
}

class System {
    method update ($ecs) { ... }
}

class Position {
    field $x : param;
    field $y : param;
    field $vx = rand();
    field $vy = rand();

    method location { return ( $x,  $y ) }
    method velocity { return ( $vx, $vy ) }

    method vx ($dvx) { $vx = $dvx }
    method vy ($dvy) { $vy = $dvy }

    method update_location() {
        $x += $vx;
        $y += $vy;
    }

}

class Vision {
    field $range : param : reader = 30;

}

class Proximity {
    field $distance : param : reader = 5;
}

class Avoidance : isa(System) {
    field $avoidance_factor : param = 1.5;

    method update ($ecs) {
        my @others =
          map { entity => $_, location => [ $_->{'Position'}->location ] },
          $ecs->entities_with('Position');
        my @entities = $ecs->entities_with( 'Position', 'Proximity' );

        for my $entity (@entities) {
            my $cdx = 0;
            my $cdy = 0;
            my ( $pos, $prox ) = $entity->@{ 'Position', 'Proximity' };
            my ( $x, $y )      = $pos->location();
            my ( $vx, $vy )    = $pos->velocity();
            my $sq_distance = $prox->distance**2;

            for my $other ( grep $entity != $_->{entity}, @others ) {
                my ( $other_x, $other_y ) = $other->{location}->@*;
                my $dx = $x - $other_x;
                my $dy = $y - $other_y;

                unless ( $dx**2 + $dy**2 > $sq_distance ) {
                    $cdx += $dx;
                    $cdy += $dy;
                }
            }
            $pos->vx( $vx + $cdx / $avoidance_factor );
            $pos->vy( $vy + $cdy / $avoidance_factor );
        }
    }
}

class Alignment : isa(System) {
    field $matching_factor : param = 0.08;

    method update ($ecs) {
        my @others =
          map {
            entity     => $_,
              location => [ $_->{'Position'}->location ],
              velocity => [ $_->{'Position'}->velocity ],
          }, $ecs->entities_with('Position');

        for my $entity ( $ecs->entities_with( 'Position', 'Vision' ) ) {
            my $xpos_avg          = 0;
            my $ypos_avg          = 0;
            my $xvel_avg          = 0;
            my $yvel_avg          = 0;
            my $neighboring_boids = 0;

            my ( $pos, $vis ) = $entity->@{ 'Position', 'Vision' };
            my ( $x,   $y )   = $pos->location();
            my $range = $vis->range;

            for my $other ( grep $entity != $_->{entity}, @others ) {
                my ( $other_x, $other_y ) = $other->{location}->@*;
                my $dx = $x - $other_x;
                my $dy = $y - $other_y;

                if ( abs($dx) < $range && abs($dy) < $range ) {
                    my ( $vx, $vy ) = $other->{velocity}->@*;
                    $xvel_avg          += $vx;
                    $yvel_avg          += $vy;
                    $neighboring_boids += 1;
                }
            }

            if ($neighboring_boids) {
                $xvel_avg = $xvel_avg / $neighboring_boids;
                $yvel_avg = $yvel_avg / $neighboring_boids;

                my ( $vx, $vy ) = $pos->velocity();
                $pos->vx( $vx + ( $xvel_avg - $vx ) * $matching_factor );
                $pos->vy( $vy + ( $yvel_avg - $vy ) * $matching_factor );
            }
        }
    }
}

class Cohesion : isa(System) {
    field $centering_factor = 0.0002;

    method update ($ecs) {
        my @others =
          map { entity => $_, location => [ $_->{'Position'}->location ], },
          $ecs->entities_with('Position');

        for my $entity ( $ecs->entities_with( 'Position', 'Vision' ) ) {
            my $xpos_avg          = 0;
            my $ypos_avg          = 0;
            my $neighboring_boids = 0;

            my ( $pos, $vis ) = $entity->@{ 'Position', 'Vision' };
            my ( $x,   $y )   = $pos->location();
            my $range = $vis->range;

            for my $other ( grep $entity != $_->{entity}, @others ) {
                my ( $other_x, $other_y ) = $other->{location}->@*;
                my $dx = $x - $other_x;
                my $dy = $y - $other_y;

                if ( abs($dx) < $range && abs($dy) < $range ) {
                    $xpos_avg          += $other_x;
                    $ypos_avg          += $other_y;
                    $neighboring_boids += 1;
                }
            }
            if ($neighboring_boids) {
                $xpos_avg = $xpos_avg / $neighboring_boids;
                $ypos_avg = $ypos_avg / $neighboring_boids;
                my ( $vx, $vy ) = $pos->velocity();

                $pos->vx( $vx + ( $xpos_avg - $x ) * $centering_factor );
                $pos->vy( $vy + ( $ypos_avg - $y ) * $centering_factor );

            }

        }
    }
}

class ScreenEdge : isa(System) {
    field $width : param;
    field $height : param;

    field $turn_factor : param = 0.02;
    field $margin : param      = 150;

    method update ($ecs) {
        for my $entity ( $ecs->entities_with('Position') ) {
            my $pos = $entity->{'Position'};
            my ( $x,  $y )  = $pos->location();
            my ( $vx, $vy ) = $pos->velocity();

            if ( $x <= $margin )           { $pos->vx( $vx + $turn_factor ) }
            if ( $y <= $margin )           { $pos->vy( $vy + $turn_factor ) }
            if ( $x >= $width - $margin )  { $pos->vx( $vx - $turn_factor ) }
            if ( $y >= $height - $margin ) { $pos->vy( $vy - $turn_factor ) }
        }
    }
}

class SpeedLimits : isa(System) {
    field $min_speed = 2.0;
    field $max_speed = 4.0;

    method update ($ecs) {
        for my $entity ( $ecs->entities_with('Position') ) {
            my $pos = $entity->{'Position'};

            my ( $vx, $vy ) = $pos->velocity();
            my $speed = sqrt( $vx * $vx + $vy * $vy ) || $min_speed;
            if ( $speed < $min_speed ) {
                $pos->vx( ( $vx / $speed ) * $min_speed );
                $pos->vy( ( $vy / $speed ) * $min_speed );
            }

            if ( $speed > $max_speed ) {
                $pos->vx( ( $vx / $speed ) * $max_speed );
                $pos->vy( ( $vy / $speed ) * $max_speed );
            }
        }
    }
}

class Movement : isa(System) {

    method update ($ecs) {
        for my $entity ( $ecs->entities_with('Position') ) {
            $entity->{'Position'}->update_location();
        }
    }
}

class Renderer : isa(System) {
    field $app : param;
    field $boid = Raylib::Text->new(
        text  => 'x',
        color => Raylib::Color::WHITE,
        size  => 10,
    );
    field $fps = Raylib::Text::FPS->new();

    method update ($ecs) {
        my $boid_count = Raylib::Text->new(
            text  => sprintf( "boids: %s", scalar $ecs->entity_count ),
            color => Raylib::Color::WHITE,
            size  => 10,
        );
        $app->draw(
            sub {
                $app->clear();
                $fps->draw();
                $boid_count->draw( 0, 20 );
                for my $entity ( $ecs->entities_with('Position') ) {
                    $boid->draw( $entity->{'Position'}->location() );
                }
            }
        );
    }
}

my $app = Raylib::App->window( 800, 600, 'Boids' );

my $ecs = ECS->new(
    systems => [
        Alignment->new(),
        Avoidance->new(),
        Cohesion->new(),
        ScreenEdge->new(
            width  => $app->width,
            height => $app->height,
        ),
        SpeedLimits->new(),
        Movement->new(),
    ]
);

sub add_boid {
    my $entity = $ecs->add_entity();
    $ecs->add_component(
        $entity,
        Position->new(
            x => int rand( $app->width ),
            y => int rand( $app->height ),
        )
    );
    $ecs->add_component( $entity, Vision->new() );
    $ecs->add_component( $entity, Proximity->new() );
}

sub remove_boid() {
    my $entity = int rand( $ecs->entity_count );
    $ecs->destroy_entity($entity);
}

$app->fps(70);
add_boid(); # at least one boid;
while ( !$app->exiting ) {
    if( $app->fps < 50 ) {
        remove_boid();
    }
    if ($app->fps >= 65) {
        add_boid();
    }
    $ecs->update();
    state $r = Renderer->new( app => $app );
    $r->update($ecs);
}
