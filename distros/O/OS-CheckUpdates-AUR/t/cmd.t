#!perl -T
use v5.16;
use strict;
use warnings;
use Test::More tests => 2;

subtest "pacman is installed" => sub {
	plan tests => 3;
	ok(-x '/usr/bin/pacman',       'can execute: /usr/bin/pacman');
	ok(-r '/etc/pacman.conf',      'can read: /etc/pacman.conf');
	ok(-d '/var/lib/pacman/local', 'local repo exist: /var/lib/pacman/local');
};


ok(-x '/usr/bin/vercmp', 'vercmp is installed');