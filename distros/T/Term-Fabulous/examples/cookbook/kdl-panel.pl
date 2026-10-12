#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/lib";    # where My/Panel.pm lives

use Term::Fabulous::Layout;
use Term::Fabulous::Static;

my $root = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Box as Box
use Term::Fabulous::Widget::Text as Text
use My::Panel as Panel

Box {
	layout direction=down gap=1
	sizing width=grow

	Panel "network" {
		title "Network" color="#61afef"
		sizing width=grow
		padding left=1 right=1
		Text { text "Connected to the office network."; text_color "#dcdcdc"; }
	}
	Panel "disk" {
		title "Disk"
		border style=Double color="#e5c07b"
		sizing width=grow
		padding left=1 right=1
		Text { text "42 % used"; text_color "#dcdcdc"; }
	}
}
KDL

Term::Fabulous::Static->new( root => $root, width => 40 )->print;
