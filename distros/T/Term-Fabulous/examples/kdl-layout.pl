#!/usr/bin/env perl

# A screen described in a KDL layout file, examples/kdl-layout.kdl: a
# title bar, a sidebar of buttons, a main panel and a status line. The
# program loads the file, finds widgets by their ids and attaches the
# behavior: a click on a server button (or Enter on it) shows that
# server in the main panel. Ctrl+C quits.
#
#     perl examples/kdl-layout.pl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Layout;

my %SERVERS = (
	web  => 'nginx 1.26, 14 days up, 210 requests per second',
	db   => 'PostgreSQL 16, 41 days up, 38 connections',
	mail => 'Postfix 3.8, 3 days up, 12 messages queued',
);

my $layout = Term::Fabulous::Layout->new( file => "$FindBin::Bin/kdl-layout.kdl" );
my $root   = $layout->build;

my $title = $root->find_by_id('details-title');
my $text  = $root->find_by_id('details-text');

# Activate bubbles from the button up to the sidebar, so one listener
# serves all buttons; the event's target is the button.
$root->find_by_id('sidebar')->on(
	Activate => sub ($event) {
		my $server = $event->target->id;
		$title->text("Server: $server");
		$text->text( $SERVERS{$server} );
		return;
	}
);

Term::Fabulous->new( width => 80, height => 24, root => $root )->run;
