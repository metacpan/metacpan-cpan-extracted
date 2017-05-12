#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Pigment;

my ($uri) = @ARGV;
die "usage: $0 uri\n" unless defined $uri;

my $viewport = Pigment::ViewportFactory->make('opengl');
$viewport->set_title('Video');
$viewport->set_alpha_blending(0);

my $formats = $viewport->get_pixel_formats;
say "Formats supported by 'opengl' viewport: ", join(q{, }, @{ $formats });

my $img = Pigment::Image->new;
$img->set_size(800, 600);
$img->set_position(0, 0, 0);
$img->set_bg_color(0, 0, 0, 0);
$img->show;

my $canvas = Pigment::Canvas->new;
$canvas->set_size(800, 600);
$viewport->set_canvas($canvas);
$canvas->add('middle', $img);

my $pipeline = GStreamer::ElementFactory->make('playbin', 'pipe');
my $image_sink = GStreamer::ElementFactory->make('pgmimagesink', 'img');
$pipeline->set('uri' => $uri);
$pipeline->set('video-sink' => $image_sink);
$image_sink->set('image' => $img);
$pipeline->set_state('playing');

$viewport->signal_connect('delete-event' => sub {
    Pigment->main_quit;
});

my ($button_pressed, $last_x, $last_y) = (0) x 3;

$viewport->signal_connect('button-press-event' => sub {
    my ($vp, $event) = @_;
    return unless $event->button eq 'left';
    ($last_x, $last_y) = map { $event->$_ } qw/x y/;
    $button_pressed = 1;
});

$viewport->signal_connect('button-release-event' => sub {
    my ($vp, $event) = @_;
    return unless $event->button eq 'left';
    $button_pressed = 0;
});

$viewport->signal_connect('motion-notify-event' => sub {
    my ($vp, $event) = @_;
    return unless $button_pressed;

    my $angle_x = $img->get_rotation_x;
    my $angle_y = $img->get_rotation_y;

    $angle_x += ($last_y - $event->y) / 200;
    $angle_y += ($event->x - $last_x) / 200;

    $img->set_rotation_x($angle_x);
    $img->set_rotation_y($angle_y);

    ($last_x, $last_y) = map { $event->$_ } qw/x y/;
});

$viewport->show;
Pigment->main;
