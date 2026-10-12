use v5.32;
use warnings;
use utf8;

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::UI::Revision qw(current_revision);
use InputTest;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Canvas;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::Slider;
use Term::Fabulous::Widget::TextField;

# Whether running the code raised the process-wide revision.
sub bumps {
	my ($code) = @_;
	my $before = current_revision();
	$code->();
	return current_revision() > $before ? 1 : 0;
}

subtest 'Canvas' => sub {
	my $canvas = Term::Fabulous::Widget::Canvas->new;
	$canvas->fit_to( 4, 2 );
	is bumps( sub { $canvas->put( 1, 0, 'a' ) } ),           1, 'put marks the canvas changed';
	is bumps( sub { $canvas->cell( 1, 0 ) } ),               0, 'cell does not';
	is bumps( sub { $canvas->set_content_origin( 3, 3 ) } ), 0, 'recording the origin of a frame does not';
};

subtest 'Checkbox' => sub {
	my $box = Term::Fabulous::Widget::Checkbox->new( label => 'Accept' );
	my $ui  = layout_ui($box);
	is bumps( sub { $box->checked(1) } ), 1, 'checked writes mark it changed';
	is bumps( sub { $box->checked } ),    0, 'checked reads do not';
	is bumps( sub { $box->toggle } ),     1, 'toggle marks it changed';
};

subtest 'Slider' => sub {
	my $slider = Term::Fabulous::Widget::Slider->new;
	my $ui     = layout_ui($slider);
	is bumps( sub { $slider->value(40) } ), 1, 'value writes mark it changed';
	is bumps( sub { $slider->value } ),     0, 'value reads do not';
};

subtest 'TextField' => sub {
	my $field = Term::Fabulous::Widget::TextField->new;
	is bumps( sub { $field->preferred_columns(30) } ), 1, 'a size change before the first frame marks it changed';

	my $ui = layout_ui($field);
	is bumps( sub { $field->value('hello') } ), 1, 'value writes mark it changed';
	is bumps( sub { $field->value } ),          0, 'value reads do not';
};

subtest 'Dropdown' => sub {
	my $dropdown = Term::Fabulous::Widget::Dropdown->new( options => [qw(Red Green Blue)] );
	my $ui       = layout_ui($dropdown);
	is bumps( sub { $dropdown->value('Green') } ), 1, 'value writes mark it changed';
	is bumps( sub { $dropdown->value } ),          0, 'value reads do not';
	is bumps( sub { $dropdown->open } ),           1, 'open marks it changed';
	is bumps( sub { $dropdown->is_open } ),        0, 'is_open does not';
};

subtest 'border_style_top' => sub {
	my $box = Term::Fabulous::Widget::Box->new( bordered => 1 );
	is bumps( sub { $box->border_style_top( Term::Fabulous::Enum::BorderStyle->Round ) } ), 1, 'writes mark the widget changed';
	is bumps( sub { $box->border_style_top } ),                                             0, 'reads do not';
	ref_is $box->border_style_top, Term::Fabulous::Enum::BorderStyle->Round, 'the style is stored';
};

subtest 'Input disabled' => sub {
	my $box = Term::Fabulous::Widget::Checkbox->new( label => 'Accept' );
	my $ui  = layout_ui($box);
	is bumps( sub { $box->disabled(1) } ), 1, 'disabling marks it changed';
	is bumps( sub { $box->disabled } ),    0, 'reads do not';
	is bumps( sub { $box->disabled(1) } ), 0, 'writing the same state does not';
};

done_testing;
