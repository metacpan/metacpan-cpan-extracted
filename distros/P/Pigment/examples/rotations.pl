#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Pigment;
use FindBin qw/$Bin/;
use File::Spec::Functions qw/catfile/;

my $viewport = Pigment::ViewportFactory->make('opengl');
$viewport->set_size(600, 600);
$viewport->set_title('Rotations');

my $img = Pigment::Image->new_from_file(catfile($Bin, qw/pictures prp.png/));
$img->set_size(400, 400);
$img->set_position(100, 100, 0);
$img->set_bg_color(0, 0, 255, 0);
$img->show;

my @labels;
my %labels = (x => 0, y => 1, z => 2);

while (my ($key, $offset) = each %labels) {
    my $label = Pigment::Text->new("Press '${key}': OFF");
    $label->set_weight('bold');
    $label->set_size(300, 20);
    $label->set_position(10, $offset * 20, 0);
    $label->set_bg_color(0, 0, 0, 0);
    $label->show;

    push @labels, $label;
}

my $canvas = Pigment::Canvas->new;
$canvas->set_size(600, 600);
$viewport->set_canvas($canvas);
$canvas->add('middle', $img);
$canvas->add('near', $_) for @labels;

my @rotate = (0) x 3;

$viewport->signal_connect('key-press-event' => sub {
    my ($vp, $event) = @_;

    state $fullscreen = 0;

    given ($event->char) {
        when ('q') {
            Pigment->main_quit;
        }
        when ('f') {
            $fullscreen = !$fullscreen;
            $vp->set_fullscreen($fullscreen);
        }
        when ([qw/x y z/]) {
            my $num = $labels{$_};
            $rotate[$num] = !$rotate[$num];
            my $label = $labels[$num]->get_label;
            $label =~ s/OFF/ON/ if $rotate[$num];
            $label =~ s/ON/OFF/ if !$rotate[$num];
            $labels[$num]->set_label($label);
        }
    }

});

$viewport->signal_connect('delete-event' => sub {
    Pigment->main_quit;
});

my @angles = (0) x 3;
$viewport->signal_connect('update-pass' => sub {
    for my $i (0 .. 2) { $angles[$i] += 0.05 if $rotate[$i] }
    $img->${\"set_rotation_${_}"}($angles[ $labels{$_} ]) for qw/x y z/;
});

$viewport->show;

Pigment->main;
