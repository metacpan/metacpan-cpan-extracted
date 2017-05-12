#!/usr/bin/perl

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/..", "$Bin/../lib", "$Bin/../blib/arch", "$Bin/../blib/lib");
use SDLx::App;
use SDLx::Rect;
use SDLx::Surface;
use SDLx::Betweener;

# onions are spread equally spaced across duration
# distance in pixels between onions must be integer on spawn
# or onions will appear to be shaking

my $ONION_COUNT    = 302;
my $ONIONS_PER_SEC = 4;
my $INTER_WAVE_T   = 1000 / $ONIONS_PER_SEC;
my $DURATION       = ($ONION_COUNT - 1) * $INTER_WAVE_T;
my $IMAGE          = "$Bin/resources/images/32x32/perl_onion.png";

my $app = SDLx::App->new
    (title=>'Polyline Path', width=>640, height=>480, eoq=>1);

my $tweener  = SDLx::Betweener->new(app => $app);
my $sprite   = SDLx::Surface->load($IMAGE);
my $src_rect = SDLx::Rect->new(0, 0, 32, 32);
my $spawner  = $tweener->tween_spawn
    (t=>$DURATION, waves => $ONION_COUNT, on=>\&spawn_creep);

# list of onion pairs, each pair a rect and its onion tween    
my @onions = map {
    my $rect  = SDLx::Rect->new(-32,-32, 32, 32);
    my $tween = $tweener->tween_path(
        t       => $DURATION,
        on      => sub { $rect->topleft($_[0]->[1], $_[0]->[0]) },
        forever => 1,
        path    => [polyline => [
            [-32, 0], [608, 0], [608, 32], [0, 32],
            (map {
                my $r = $_*2*32;
                ([0, $r], [608, $r], [608, $r+32], [0, $r+32]),
            } 1..6),
            [0, 448], [640, 448],
        ]],
    );
    [$rect, $tween];
} 1..$ONION_COUNT;

$app->add_show_handler(sub {
    $app->draw_rect(undef, 0xFFFFFFFF);
    $sprite->blit($app, $src_rect, $_->[0]) foreach @onions;
    $app->update;
});

$spawner->start;
$app->run;

sub spawn_creep {
    my ($wave, $start_t) = @_;
    my $tween = $onions[$wave - 1]->[1];
    $tween->start($start_t);
}

