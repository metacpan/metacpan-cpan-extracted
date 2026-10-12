#!/usr/bin/env perl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Enum::BorderStyle;

use Clay::XS qw(:all);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

my $title = Term::Fabulous::Widget::Text->new(
	text       => 'Term::Fabulous automatic text layout (Ctrl+C to quit)',
	text_color => [ 220, 220, 220, 255 ],
);
$root->add_child($title);

my $row = Term::Fabulous::Widget::Box->new(
	layout => {
		sizing    => { width => sizing_grow(), height => sizing_grow() },
		child_gap => 2,
	},
);
$root->add_child($row);

my $japanese = <<EOT;
いろはにほへと　ちりぬるを
わかよたれそ　つねならむ
うゐのおくやま　けふこえて
あさきゆめみし　ゑひもせす
EOT

my $korean = <<EOT;
동해 물과 백두산이
마르고 닳도록
하느님이 보우하사
우리나라 만세
EOT

my $thai = <<EOT;
สวัสดีชาวโลก
ฉันรักการเขียนโปรแกรม
ภาษาไทยมีวรรณยุกต์
ขอให้โชคดีนะครับ
EOT

my $german = <<EOT;
Grüße vom 🍻 Oktoberfest!
Spaß mit Umlauten äöüß 🎉
EOT

my @texts = (
	$japanese,
	$korean,
	$thai,
	$german,
);

foreach my $text (@texts) {
	my $cell = Term::Fabulous::Widget::Box->new(
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => { left  => 1, right => 1, top => 1, bottom => 1 },
		},
		background_color => [ 35,  40,  55,  255 ],
		border_color     => [ 180, 200, 220, 255 ],
		bordered         => 1,
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	);

	my $label = Term::Fabulous::Widget::Text->new(
		text       => $text,
		text_color => [ 255, 255, 255, 255 ],
	);

	$cell->add_child($label);
	$row->add_child($cell);
}

my $ui = Term::Fabulous->new(
	width  => 100,
	height => 32,
	root   => $root,
);

$ui->run();
