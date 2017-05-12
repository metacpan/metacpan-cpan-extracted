#!/usr/bin/perl

package SDLx::Betweener::eg_06::Circle;

use Moose;

has xy     => (is => 'rw', required => 1);
has radius => (is => 'rw', required => 1);

sub paint {
    my ($self, $surface) = @_;
    $surface->draw_circle_filled($self->xy, $self->radius, 0xFFCC00FF);
    $surface->draw_circle($self->xy, $self->radius, 0x0000EEFF, 1);
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
my $circle   = SDLx::Betweener::eg_06::Circle->new(radius=>30, xy=>[320,380]);

my ($tween_1, $tween_2, $tween_3);

# note you can set a completer using a callback or an object/method pair
# here we show how to use both to achieve the same effect

$tween_1 = $tweener->tween_path(
    t    => 3_000,
    to   => [320, 100],
    on   => {xy => $circle},
    ease => 'p4_in_out',
    done => sub { $tween_2->start(shift) },
);

$tween_2 = $tweener->tween_int(
    t      => 2_000,
    to     => 90,
    on     => {radius => $circle},
    ease   => 'p4_in_out',
    repeat => 2,
    bounce => 1,
    done   => sub { $tween_3->start(shift) },
);

$tween_3 = $tweener->tween_path(
    t    => 3_000,
    on   => {xy => $circle},
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
    $circle->paint($app);
    $app->update;
});

$tween_1->start;
$app->run;

