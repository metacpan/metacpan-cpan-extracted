use v5.32;
use warnings;

use Test2::V0;

use Clay::UI;
use Clay::XS qw(CLAY_RENDER_COMMAND_TYPE_TEXT);
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;

subtest 'a border adds a cell to the padding of its side' => sub {
	my $box    = Term::Fabulous::Widget::Box->new( bordered => 1, layout => { padding => { left => 2 }, child_gap => 1 } );
	my $config = $box->to_config;
	is $config->{layout}{padding}, { left => 3, right => 1, top => 1, bottom => 1 }, 'every side';
	is $config->{border}{width}, { left => 1, right => 1, top => 1, bottom => 1, between_children => 0 }, 'Clay draws every side';
	is $config->{layout}{child_gap}, 1, 'other layout keys are kept';

	my $sides = Term::Fabulous::Widget::Box->new( bordered => { left => 1, top => 1 }, layout => { padding => { left => 1 } } );
	is $sides->to_config->{layout}{padding}, { left => 2, right => 0, top => 1, bottom => 0 }, 'some sides, with padding inside the border';

	my $button = Term::Fabulous::Widget::Button->new( bordered => 1 );
	is $button->to_config->{layout}{padding}, { left => 1, right => 1, top => 1, bottom => 1 }, 'subclasses get the inset too';

	my $plain = Term::Fabulous::Widget::Box->new( layout => { padding => { left => 2 } } );
	is $plain->to_config->{layout}, $plain->layout, 'without a border the layout is passed through';
	ok !exists $plain->to_config->{border}, 'and Clay draws no border';

	like dies { Term::Fabulous::Widget::Box->new( border_width => 1 ) }, qr/border_width is not a parameter of Term::Fabulous widgets; use bordered/, 'border_width dies with a hint';
	like dies { $plain->border_width },                                  qr/use bordered/,                                                            'so does its accessor';
	like dies { Term::Fabulous::Widget::Box->new( bordered => { middle => 1 } ) }, qr/bordered must be a boolean or a hash reference of booleans under the sides .*unknown side middle/,
		'an unknown side dies';
};

subtest 'Hidden sides take no space and draw nothing' => sub {
	my $hidden = Term::Fabulous::Enum::BorderStyle->Hidden;
	my $box    = Term::Fabulous::Widget::Box->new( bordered => 1, border_style_top => $hidden, border_style_left => $hidden );
	my $config = $box->to_config;
	is $config->{layout}{padding}, { left => 0, right => 1, top => 0, bottom => 1 },                        'only the other sides add an inset';
	is $config->{border}{width},   { left => 0, right => 1, top => 0, bottom => 1, between_children => 0 }, 'Clay sees a width of 0 on the Hidden sides';
	is $box->bordered,             { left => 1, right => 1, top => 1, bottom => 1 },                        'the widget stays bordered';
	is $box->drawn_border_sides,   { left => 0, right => 1, top => 0, bottom => 1 },                        'drawn_border_sides leaves the Hidden sides out';
};

subtest 'the stored layout is never modified' => sub {
	my $box    = Term::Fabulous::Widget::Box->new( bordered => 1, layout => { padding => { left => 2 } } );
	my $first  = $box->to_config;
	my $second = $box->to_config;
	is $second->{layout}{padding}, $first->{layout}{padding}, 'repeated to_config gives the same padding';
	is $box->layout, { padding => { left => 2 } }, 'widget layout unchanged';
};

subtest 'Clay places content inside the border' => sub {
	my $root = Term::Fabulous::Widget::Box->new( bordered => 1, layout => { padding => { left => 1 } } );
	$root->add_child( Term::Fabulous::Widget::Text->new( text => 'hi' ) );
	my $ui = Clay::UI->new(
		width        => 20,
		height       => 5,
		root         => $root,
		measure_text => sub { return { width => length $_[0], height => 1 } },
	);
	my ($text) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @{ $ui->render };
	is [ @{ $text->{boundingBox} }{qw(x y)} ], [ 2, 1 ], 'text starts after border and padding';
};

done_testing;
