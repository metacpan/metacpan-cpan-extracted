#!/usr/bin/perl

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/..", "$Bin/../lib", "$Bin/../blib/arch", "$Bin/../blib/lib");
use Math::Trig;
use SDL::GFX::Primitives;
use SDL::Events;
use SDLx::App;
use SDLx::Text;
use SDLx::Betweener;

my $COUNT = 20000;

my $w = 640;
my $h = 480;

my $app = SDLx::App->new(title=>'Seeker Behavior', width=>$w, height=>$h);
my $tweener = SDLx::Betweener->new(app => $app);

my $player = [320, 200];
my @creeps;

my $i; while($i++ < $COUNT) {
    my $theta  = rand(2 * pi);
    my $from   = [int cos($theta)*$w + $w/2, int sin($theta)*$h + $h/2];
    my $creep  = [$from, undef];
    my $seeker = $tweener->tween_seek(
        on    => $from,
        speed => (rand(150) + 50) / 1_000,
        to    => $player,
        done  => sub { $creep->[1]->restart },
    );
    $creep->[1] = $seeker;
    push @creeps, $creep;
}

$app->add_show_handler(sub {
    $app->draw_rect(undef, 0xFFFFFFFF);
    SDL::GFX::Primitives::pixel_color($app, @{$_->[0]}, 0x000000FF)
        for @creeps;
    $app->update;
});

$app->add_event_handler(sub {
    my ($e, $app) = @_;
       if ($e->type == SDL_QUIT       ) { $app->stop }
    elsif ($e->type == SDL_MOUSEMOTION) {
        $player->[0] = $e->motion_x;
        $player->[1] = $e->motion_y;
    }
});

$_->[1]->start for @creeps;
$app->run;
