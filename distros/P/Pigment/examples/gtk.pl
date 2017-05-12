#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Pigment;
use FindBin qw/$Bin/;
use File::Spec::Functions qw/catfile/;

my $vp = Pigment::ViewportFactory->make('opengl');
$vp->signal_connect('key-press-event' => sub {
    say 'Pigment has the keyboard focus';
});

my $img = Pigment::Image->new_from_file(catfile($Bin, qw/pictures prp.png/));

$img->signal_connect('file-loaded', sub {
    $vp->signal_connect('update-pass' => sub {
        state $angle = 0;
        $img->${\"set_rotation_${_}"}($angle) for qw/x y z/;
        $angle += 0.03;
    });
});

$img->set_size(3, 3);
$img->set_position(0.5, 0, 0);
$img->set_bg_color(1, 1, 1, 0);
$img->show;

my $canvas = Pigment::Canvas->new;
$canvas->add('middle', $img);
$vp->set_canvas($canvas);

my $window = Gtk2::Window->new;
$window->set_title('GTK+ integration');
$window->resize(400, 400);
$window->set_border_width(5);
$window->signal_connect('delete-event' => sub { Gtk2->main_quit });

my $embed = Pigment::Gtk2->new;
$embed->set_viewport($vp);

my $button = Gtk2::Button->new_with_label('GTK+ button');
$button->signal_connect('clicked' => sub {
    say 'GTK+ button clicked';
});

my $entry = Gtk2::Entry->new;
my $vbox = Gtk2::VBox->new(FALSE, 5);
$window->add($vbox);
$vbox->pack_start($button, FALSE, FALSE, 0);
$vbox->pack_start($embed, TRUE, TRUE, 0);
$vbox->pack_start($entry, FALSE, FALSE, 0);
$window->show_all;

Gtk2->main;
