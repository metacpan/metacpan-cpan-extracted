#!/usr/bin/perl

package SDLx::Betweener::eg_08::Sprite;

use Moose;
use SDLx::Rect;
use SDLx::Surface;

has [qw(tweener image rect frames)] => (is => 'ro', required => 1);

has sequence    => (is => 'rw', lazy_build => 1);
has frame       => (is => 'rw', default    => 0);
has frame_count => (is => 'ro', lazy_build => 1);
has surface     => (is => 'ro', lazy_build => 1, handles => ['blit']);
has sequences   => (is => 'ro', lazy_build => 1);
has walk_tween  => (is => 'ro', lazy_build => 1);

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    $args{rect} = SDLx::Rect->new(@{ $args{rect} });
    return $class->$orig(%args);
};

sub _build_sequence    { shift->frames->[0] }
sub _build_frame_count { scalar @{shift->frames->[1]} }
sub _build_surface     { SDLx::Surface->load(shift->image) }

sub _build_sequences {
    my $self = shift;
    my %f = @{$self->frames};
    my ($w, $h) = ($self->rect->size);
    my %seq;
    for my $k (keys %f) {
        $seq{$k} = [map { SDLx::Rect->new($w*$_->[0], $h*$_->[1], $w, $h) }
                   @{$f{$k}}];
    }
    return \%seq;
}

sub _build_walk_tween {
    my $self = shift;
    return $self->tweener->tween_int(
        t       => 2000,
        range   => [0, $self->frame_count],
        on      => {set_frame => $self},
        forever => 1,
    );
}

# clamp frame to max frame count
sub set_frame {
    my ($self, $frame) = @_;
    $self->frame($frame < $self->frame_count? $frame: $frame - 1);
}

sub start_walking { shift->walk_tween->start }

sub paint {
    my ($self, $surface) = @_;
    my $src_rect = $self->sequences->{ $self->sequence }->[ $self->frame ];
    $self->blit($surface, $src_rect, $self->rect);
}

# ------------------------------------------------------------------------------ 

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/..", "$Bin/../lib", "$Bin/../blib/arch", "$Bin/../blib/lib");
use SDLx::App;
use SDL::Events;
use SDLx::Text;
use SDLx::Betweener;

my $app = SDLx::App->new(title=>'Animated Sprite', width=>640, height=>480);
my $tweener = SDLx::Betweener->new(app => $app);

my $sprite = SDLx::Betweener::eg_08::Sprite->new(
    tweener => $tweener,
    image   => "$Bin/resources/images/64x64/walk.png",
    rect    => [320 - 64, 200 - 64, 64, 64],
    frames  => [
        right => [ map { [$_, 0] } 0..7 ],
        left  => [ map { [$_, 1] } 0..7 ],
    ],
);

my $instructions = SDLx::Text->new(
    x     => 90,
    y     => 230,
    text  => 'left/right arrows to change walk direction',
    color => [0, 0, 0],
    size  => 22,
);

$app->add_show_handler(sub {
    $app->draw_rect(undef, 0xFFFFFFFF);
    $sprite->paint($app);
    $instructions->write_to($app);
    $app->update;
});

SDL::Events::enable_key_repeat(600, 100);
$app->add_event_handler(sub {
    my ($e, $app) = @_;
    if($e->type == SDL_QUIT) {
        $app->stop;
    } elsif ($e->type == SDL_KEYDOWN) {
        if ($e->key_sym == SDLK_LEFT) {
            $sprite->sequence('left');
        } elsif ($e->key_sym == SDLK_RIGHT) {
            $sprite->sequence('right');
        }
    }
    return 0;
});

$sprite->start_walking;

$app->run;


