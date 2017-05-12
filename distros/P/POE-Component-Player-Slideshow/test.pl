#!/usr/bin/perl

#	test suite

use Test::Simple tests => 15;

use POE;
use POE::Component::Player::Slideshow;
ok(1, 'use PoCo::Player::Slideshow');

$test = -1;
$ENV{DEBUG} = 1 if $ENV{DEBUG} eq "Y";

$p = POE::Component::Player::Slideshow->new(
	disp	=> $ENV{DISPLAY},
	delay	=> 10,
	debug	=> $ENV{DEBUG},
	window	=> 1,
	noscale	=> 1,
	);

ok(defined $p && $p->isa('POE::Component::Player::Slideshow')
	, "component instantiated"
	);

@events = qw/cmdtest done died/;
$s = POE::Session->create(
	package_states => ["main" => \@events],
	inline_states => {
		_start => sub {
			my $kernel = $_[KERNEL];
			$kernel->alias_set("main");

			$w = $p->play("./pix");    # do slideshow
			ok($w, "play issued");

			$kernel->delay("cmdtest", 2);
			}
		}
	);

ok(defined($s), "session created");

# POEtry in motion

POE::Kernel->run();
ok(1, "done");

# --- event handlers ----------------------------------------------------------

sub cmdtest {
	$test++;
	if ($test == 0) {
		ok(1, "command testing");
		$p->pause();
		$p->rotleft();
		ok(1, "rotate left");
		}
	elsif ($test == 1) {
		$p->flipvert();
		ok(1, "flip vertical");
		}
	elsif ($test == 2) {
		$p->fliphorz();
		ok(1, "flip horizontal");
		}
	elsif ($test == 3) {
		$p->restore();
		ok(1, "restored");
		}
	elsif ($test == 4) {
		$p->fullscreen();
		ok(1, "full screen");
		}
	elsif ($test == 5) {
		ok(1, "zoom in");
		$p->zoomin();
		$p->zoomin();
		}
	elsif ($test == 6) {
		ok(1, "zoom out");
		$p->zoomout();
		$p->zoomout();
		$p->fullscreen();
		}
	elsif ($test == 7) {
		ok(1, "next");
		$p->next();
		}
	elsif ($test == 8) {
		$p->next();
		}
	elsif ($test == 9) {
		ok(1, "prev");
		$p->prev();
		$p->prev();
		}
	elsif ($test == 10) {
		$p->quit();
		}
	else {
		return;
		}
	POE::Kernel->delay("cmdtest", 1);
	}

sub done {
	$_[KERNEL]->alias_remove("main");
	}

sub died {
	ok(0, "died");
	exit;
	}
