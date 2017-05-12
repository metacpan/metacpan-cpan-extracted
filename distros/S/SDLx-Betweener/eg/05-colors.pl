#!/usr/bin/perl

package SDLx::Betweener::eg_05::Circle;

use Moose;

has color      => (is => 'rw', default => 0x000000FF);
has position   => (is => 'ro', required => 1);
has to         => (is => 'ro', required => 1);
has tweener    => (is => 'ro', required => 1, weak_ref => 1);
has tween_type => (is => 'ro', required => 1);
has tween      => (is => 'ro', lazy_build => 1);

sub _build_tween {
    my $self = shift;
    my $type = 'tween_'. $self->tween_type;
    return $self->tweener->$type(
        on      => {color => $self},
        to      => $self->to,
        t       => 2_000,
        forever => 1,
        bounce  => 1,
        ease    => 'p2_in_out',
    );
}

sub paint {
    my ($self, $surface) = @_;
    $surface->draw_circle_filled($self->position, 100, $self->color);
    $surface->draw_circle($self->position, 100, 0x000000FF, 1);
}

# force tween build
sub BUILD { shift->tween }

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/..", "$Bin/../lib", "$Bin/../blib/arch", "$Bin/../blib/lib");
use SDL::Events;
use SDLx::App;
use SDLx::Text;
use SDLx::Betweener;

my $w = 800;
my $h = 600;

my @circle_defs = (
    ["tween=fade from=0xFF000000 to=0xFF", 
        fade => [200, 150], 0xFF0000FF, 0x00,
    ],
    ["tween=rgba from=0x00FF0044 to=0x0000FFCC",
        rgba => [200, 320], 0x00FF0044, 0x0000FFCC,
    ],
    ["tween=rgba from=0xFF00FF77 to=0x00000077",
        rgba => [330, 150], 0xFF00FF77, 0x00000077,
    ],
    ["tween=rgba from=0xFFFF0088 to=0xFFFFFF88",
        rgba => [330, 320], 0xFFFF0088, 0xFFFFFF88,
    ],
);

my (@circles, @text);

my $app = SDLx::App->new(title=>'Color Tweens', width=>$w, height=>$h, eoq => 1);
my $tweener = SDLx::Betweener->new(app => $app);

for my $def (@circle_defs) {
    my ($text, $type, $xy, $color, $to) = @$def;
    push @circles, SDLx::Betweener::eg_05::Circle->new(
        position   => $xy,
        color      => $color,
        to         => $to,
        tweener    => $tweener,
        tween_type => $type,
    );
    # push description text of circle into @text
    my $row; for my $part (split / /, $text) {
        push @text, SDLx::Text->new(
            x       => $xy->[0] - 45,
            y       => $xy->[1] - 30 + 18 * $row++,
            text    => $part,
            color   => [0, 0, 0],
            size    => 16,
        );
    }
}

$app->add_show_handler(sub {
    $app->draw_rect(undef, 0xF3F3F3FF);
    $_->write_to($app) for @text;
    $_->paint($app) for @circles;
    $app->update;
});

$_->tween->start(0) for @circles;

$app->run;
