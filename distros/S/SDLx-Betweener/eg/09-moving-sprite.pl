#!/usr/bin/perl

package SDLx::Betweener::eg_09::Sprite;


use Moose;
use SDLx::Rect;
use SDLx::Surface;

has [qw(tweener image frames)] => (is => 'ro', required => 1);

has xy          => (is => 'rw', required => 0);
has wh          => (is => 'ro', required => 0);
has sequence    => (is => 'rw', lazy_build => 1);
has frame       => (is => 'rw', default    => 0);
has frame_count => (is => 'ro', lazy_build => 1);
has surface     => (is => 'ro', lazy_build => 1, handles => ['blit']);
has sequences   => (is => 'ro', lazy_build => 1);
has walk_tween  => (is => 'ro', lazy_build => 1);

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    $args{wh} = [@{ $args{rect} }[2,3]];
    return $class->$orig(%args);
};

sub _build_sequence    { shift->frames->[0] }
sub _build_frame_count { scalar @{shift->frames->[1]} }
sub _build_surface     { SDLx::Surface->load(shift->image) }

sub _build_sequences {
    my $self = shift;
    my %f = @{$self->frames};
    my ($w, $h) = @{$self->wh};
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
    $self->blit($surface, $src_rect, SDLx::Rect->new(@{$self->xy}, @{$self->wh}));

    return;
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/..", "$Bin/../lib", "$Bin/../blib/arch", "$Bin/../blib/lib");
use Math::Trig ':pi';
use SDLx::App;
use SDLx::Betweener;

my $app = SDLx::App->new
    (title=>'Chaining Tweens', width=>640, height=>480, eoq=>1);

my $tweener  = SDLx::Betweener->new(app => $app);
my $sprite   = SDLx::Betweener::eg_09::Sprite->new(
    tweener => $tweener,
    image   => "$Bin/resources/images/64x64/walk.png",
    rect    => [320 - 64, 200 - 64, 64, 64],
    frames  => [
        right => [ map { [$_, 0] } 0..7 ],
        left  => [ map { [$_, 1] } 0..7 ],
    ],
    xy => [0,0],
);

my ($tween_1, $tween_3);

# note you can set a completer using a callback or an object/method pair
# here we show how to use both to achieve the same effect

$tween_1 = $tweener->tween_path(
    t    => 3_000,
    to   => [320, 100],
    on   => {xy => $sprite},
    ease => 'p4_in_out',
    done => sub { $tween_3->start(shift) },
);

$tween_3 = $tweener->tween_path(
    t    => 3_000,
    on   => {xy => $sprite},
    ease => 'p4_in_out',
    done => {start => $tween_1},
    path => [circular => {
        center => [320,240],
        radius => 140,
        from   => 3*pip2,
        to     => pip2,
    }],
);

$app->add_show_handler(sub {
    $app->draw_rect(undef, 0xFFFFFFFF);
    $sprite->paint($app);
    $app->update;
});

$tween_1->start;
$app->run;

