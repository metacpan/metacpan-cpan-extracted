#!/usr/bin/perl

package SDLx::Betweener::eg_01::Circle;
use Moose;
has radius => (is => 'rw', default => 0);

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use lib ("$Bin/..", "$Bin/../lib", "$Bin/../blib/arch", "$Bin/../blib/lib");
use SDL;
use SDLx::App;
use SDLx::Betweener;

my $circle = SDLx::Betweener::eg_01::Circle->new;

my $app = SDLx::App->new(
    title  => 'Circle With Tweened Radius',
    width  => 640,
    height => 480,
    eoq    => 1,
);

my $tweener = SDLx::Betweener->new(app => $app);

my $tween = $tweener->tween_int(
    t       => 3_000,
    to      => 200,
    on      => {radius => $circle},
    ease    => 'p4_in_out',
    bounce  => 1,
    forever => 1,
);

$app->add_show_handler(sub {
    $app->draw_rect(undef, 0x000000FF);
    $app->draw_circle_filled([320, 200], $circle->radius, 0x3300DDFF);
    $app->draw_circle([320, 200], $circle->radius, 0xDD3311FF);
    $app->update;
});

$tween->start;
$app->run;

