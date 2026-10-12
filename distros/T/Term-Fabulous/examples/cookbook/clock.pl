#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use POSIX qw(strftime);
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_ALIGN_X_CENTER CLAY_ALIGN_Y_CENTER);

my $clock = Term::Fabulous::Widget::Text->new( text => '--:--:--', text_color => [ 255, 200, 80, 255 ] );
my $root  = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing          => { width => sizing_grow(),       height => sizing_grow() },
		child_alignment => { x     => CLAY_ALIGN_X_CENTER, y      => CLAY_ALIGN_Y_CENTER },
	},
);
$root->add_child($clock);

my $timer = IO::Async::Timer::Periodic->new(
	interval       => 1,
	first_interval => 0,
	on_tick        => sub { $clock->text( strftime( '%H:%M:%S', localtime ) ) },
);
$timer->start;
IO::Async::Loop->new->add($timer);

Term::Fabulous->new( root => $root, width => 80, height => 24 )->run;
