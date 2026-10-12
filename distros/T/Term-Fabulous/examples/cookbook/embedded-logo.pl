#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Image;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(CLAY_TOP_TO_BOTTOM CLAY_ALIGN_Y_CENTER);

# The logo, a 16x16 PNG as base64 text: no file to ship or to find.
# The line breaks are ignored.
my $LOGO = <<'BASE64';
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABiklEQVQ4ja2TwUoCURSGvzujwQRh
JIOBLoSE7AFmIRK0aBXYMqNo2QO09x16AJdiZJsgoZW7iIJ5gAoMWxhUg9LdKJR6W9xJJ5tN0lme
y/9xz/+fIwiptmmqsH5qOBTTvR+Nb2E0p7CyEIlpzkAK+vfweSN+gURQbKzA4vYIa1lBDLD9Rw+Q
0H8RvF8YjB4nEBEU23sjIkkFeSAx9ddX4BoGzwLvZAIZA5aORlirCrag8zlPzbWpNOcAOMh8UHQ8
4tEeXEL/QdA9NkgNhyLSNk0VzSn97bwW754laXT3oVMA4FbWOW9VOd15Jp7vYUlFNKdo35jKALCy
6JkTUHNtLb4r4TylcZ7ScFei0d2n5tp6tJivAQzw3fYNqzTnoFPA6Uk2rspsXJVxehI6hfFI2JOE
jLC8/1IR0DnjqbFht7KO+1aC9UMA3PkYxOscZD7GsQ6kmAD697CQ1VEVHY/zVpXGGri+icTrbC5V
KTqejlNqDQT2YNYY/2eRgpCZVjkIgRmPKQw0XWHn/AWQfdWh/qecnAAAAABJRU5ErkJggg==
BASE64

my $about = Term::Fabulous::Widget::Box->new(
	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Round,
	border_color => [ 120, 160, 220, 255 ],
	layout       => {
		padding         => { left => 2, right => 2, top => 1, bottom => 1 },
		child_gap       => 3,
		child_alignment => { y => CLAY_ALIGN_Y_CENTER },
	},
);
my $text = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 1 } );
$text->add_child(
	Term::Fabulous::Widget::Text->new( text => 'Prism 2.4',                text_color => [ 255, 255, 255, 255 ] ),
	Term::Fabulous::Widget::Text->new( text => 'Colors for your terminal', text_color => [ 150, 160, 180, 255 ] ),
	Term::Fabulous::Widget::Text->new( text => 'Press q to quit.',         text_color => [ 150, 160, 180, 255 ] ),
);
$about->add_child( Term::Fabulous::Widget::Image->new( base64 => $LOGO ), $text );

my $root = Term::Fabulous::Widget::Box->new( layout => { padding => { left => 2, top => 1 } } );
$root->add_child($about);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$root->on(
	KeyPress => sub ($event) {
		$ui->loop->stop if ( $event->key_name // '' ) eq 'q';
		return;
	}
);
$ui->run;
