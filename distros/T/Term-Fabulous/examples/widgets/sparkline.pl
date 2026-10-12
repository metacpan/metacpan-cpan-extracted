#!/usr/bin/env perl

# Term::Fabulous::Widget::Sparkline: a list of servers, each with the
# load of the last minute as a line, an area and bars that move every
# second. Ctrl+C quits.
#
#     perl examples/widgets/sparkline.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use IO::Async::Timer::Periodic;
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Sparkline;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $muted = [ 150, 160, 180, 255 ];
my $title = Term::Fabulous::Widget::Text->new( text => 'Server load, last 60 seconds', text_color => [ 235, 238, 243, 255 ] );
$root->add_child($title);

# One row per server: its name, the current load and three sparklines.
my $tick = 0;

sub load ( $server, $second ) {
	return 50 + 30 * sin( ( $second + 7 * $server ) / 6 ) + 12 * sin( ( $second + $server ) / 1.7 );
}

my @rows;
foreach my $server ( 0 .. 3 ) {
	my @history = map { load( $server, $_ ) } -59 .. 0;
	my $name    = Term::Fabulous::Widget::Text->new( text => sprintf( 'web-%02d', $server + 1 ), text_color => $muted );
	my $value   = Term::Fabulous::Widget::Text->new( text => sprintf( '%3.0f%%', $history[-1] ), text_color => [ 230, 230, 230, 255 ] );
	my %line    = ( min => 0, max => 100, max_points => 60, layout => { sizing => { width => sizing_fixed(16) } } );
	my @sparks  = (
		Term::Fabulous::Widget::Sparkline->new( %line, type => 'line', values => \@history ),
		Term::Fabulous::Widget::Sparkline->new( %line, type => 'area', values => \@history, color => '#d95926' ),
		Term::Fabulous::Widget::Sparkline->new( %line, type => 'bar',  values => \@history, color => '#199e70' ),
	);
	my $row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 2 } );
	$row->add_child( $name, $value, @sparks );
	$root->add_child($row);
	push @rows, { server => $server, value => $value, sparks => \@sparks };
}

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );

# Every second each server reports its load; the sparklines keep 60.
my $timer = IO::Async::Timer::Periodic->new(
	interval => 1,
	on_tick  => sub {
		$tick++;
		foreach my $row (@rows) {
			my $load = load( $row->{server}, $tick );
			$row->{value}->text( sprintf '%3.0f%%', $load );
			$_->add_values($load) foreach $row->{sparks}->@*;
		}
		return;
	},
);
$root->on(
	Start => sub ($event) {
		$ui->loop->add( $timer->start );
		return;
	}
);
$ui->run;
