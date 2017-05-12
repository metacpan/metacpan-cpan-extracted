#!/usr/bin/perl

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/..", "$Bin/../lib", "$Bin/../blib/arch", "$Bin/../blib/lib");
use Math::Trig;
use SDL::GFX::Primitives;
use SDLx::App;
use SDLx::Betweener;

my $STAR_COUNT = 20000;

my $app = SDLx::App->new(
    title  => 'Starfield',
    width  => 640,
    height => 480,
    eoq    => 1,
);

my $tweener = SDLx::Betweener->new(app => $app);

my ($first_star, $prev_star, @tweens);

my $i; while($i++ < $STAR_COUNT) {
    my $theta = rand(2 * pi);
    my $to    = [cos($theta)*640 + 320, sin($theta)*480 + 240];
    my $star  = [[320,200], undef, undef];
    my $tween = $tweener->tween_path(
        t       => (int(rand 8_000) + 1000),
        to      => $to,
        on      => $star->[0],
        ease    => 'p2_in',
        forever => 1,
    );
    $star->[1] = $tween;

    if ($first_star) { $prev_star->[2] = $star }
    else             { $first_star = $star }
    
    $prev_star = $star;
    push @tweens, $tween;
}

my $show_handler  = sub {
    my $star = $first_star;
    $app->draw_rect(undef, 0x000000FF);
    my ($x, $y);
    while ($star) {
        ($x, $y) = @{$star->[0]};
        SDL::GFX::Primitives::pixel_color($app, $x, $y, 0xFFFFFFFF);
        $star = $star->[2];
    }
    $app->update;
};

$app->add_show_handler($show_handler);

$_->start for @tweens;

$app->run;

