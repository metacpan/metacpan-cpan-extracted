#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Gtk2;
use Pigment;
use FindBin qw/$Bin/;
use File::Spec::Functions qw/catfile/;

my $vp = Pigment::ViewportFactory->make('opengl');
$vp->set_title('Image');

my $img_path = catfile($Bin, qw/pictures prp.png/);

my $icon = Gtk2::Gdk::Pixbuf->new_from_file($img_path);
$vp->set_icon($icon);

my $canvas = Pigment::Canvas->new;

my $img = Pigment::Image->new_from_file($img_path);
$img->set_size(1, 1);
$img->set_position(1.25, 0.75, -50);
$img->set_bg_color(150, 150, 255, 255);
$img->set_opacity(150);
$img->show;
connect_signals($img);
$canvas->add('middle', $img);

$img = Pigment::Image->new_from_image($img);
$img->set_size(1, 1);
$img->set_position(1.5, 1, 0);
$img->set_bg_color(255, 150, 150, 255);
$img->set_opacity(150);
$img->show;
connect_signals($img);
$canvas->add('middle', $img);

$img = Pigment::Image->new_from_image($img);
$img->set_size(1, 1);
$img->set_position(1.75, 1.25, 50);
$img->set_bg_color(150, 255, 150, 255);
$img->set_opacity(150);
$img->show;
connect_signals($img);
$canvas->add('middle', $img);

$vp->set_canvas($canvas);

my $iconified = FALSE;

$vp->signal_connect('key-press-event' => sub {
    my (undef, $event) = @_;

    state $fullscreen = FALSE;

    given ($event->char) {
        when ('f') {
            $fullscreen = !$fullscreen;
            $vp->set_fullscreen($fullscreen);
        }
        when ('i') {
            $iconified = !$iconified;
            $vp->set_iconified($iconified);
        }
        when ('q') {
            Pigment->main_quit;
        }
    }
});

$vp->signal_connect('delete-event' => sub { Pigment->main_quit });
$vp->signal_connect('state-event' => sub {
    my (undef, $event) = @_;
    my $name = $vp->get('name');
    if ($event->state_mask & 'iconified') {
        $iconified = TRUE;
        say "${name} iconified";
    }
    else {
        $iconified = FALSE;
        say "${name} deiconified";
    }
});

$vp->show;

Pigment->main;

sub connect_signals {
    my ($img) = @_;
    my $name = $img->get('name');

    for my $signal (qw/pressed pressured released clicked double-clicked/) {
        $img->signal_connect($signal => sub {
            say qq{${name} "${signal}"};
            return FALSE;
        });
    }

    $img->signal_connect(scrolled => sub {
        my (undef, $x, $y, $z, $direction) = @_;
        say qq{${name} "scrolled ${direction}"};
        return TRUE;
    });

    $img->signal_connect('drag-begin' => sub {
        my (undef, $x, $y, $z, $button, $time, $pressure) = @_;
        say qq{${name} "drag-begin", (${x}, ${y}, ${z}), ${button}, ${time}, ${pressure}};
        return TRUE;
    });

    $img->signal_connect('drag-motion' => sub {
        my (undef, $x, $y, $z, $button, $time, $pressure) = @_;
        say qq{${name} "drag-motion", (${x}, ${y}, ${z}), ${button}, ${time}, ${pressure}};
        return FALSE;
    });

    $img->signal_connect('drag-end' => sub {
        my (undef, $x, $y, $z, $button, $time) = @_;
        say qq{${name} "drag-end", (${x}, ${y}, ${z}), ${button}, ${time}};
        return TRUE;
    });

    $img->signal_connect(motion => sub {
        my (undef, $x, $y, $z, $time) = @_;
        say qq{${name} "motion", (${x}, ${y}, ${z}), ${time}};
        return TRUE;
    });

    $img->signal_connect(entered => sub {
        my (undef, $x, $y, $z, $time) = @_;
        say qq{${name} "entered", (${x}, ${y}, ${z}), ${time}};
        $img->set_opacity(200);
        return TRUE;
    });

    $img->signal_connect(left => sub {
        my (undef, $x, $y, $z, $time) = @_;
        say qq{${name} "left", (${x}, ${y}, ${z}), ${time}};
        $img->set_opacity(150);
    });
}
