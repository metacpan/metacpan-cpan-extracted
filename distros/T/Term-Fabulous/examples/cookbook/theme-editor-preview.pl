#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous::ThemeEditor;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Divider;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

# The screen of your program, as the program builds it. No widget here is
# given a color, so the theme decides them all.
sub sign_in_screen () {
	my $form = Term::Fabulous::Widget::Box->new(
		bordered => 1,
		layout   => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow( 0, 44 ) },
			padding          => { left  => 1, right => 1 },
			child_gap        => 1,
		},
	);
	my $name     = Term::Fabulous::Widget::TextField->new( placeholder => 'E-mail address', validator => 'email' );
	my $password = Term::Fabulous::Widget::TextField->new( placeholder => 'Password',       mask      => '*' );
	my $sign_in  = Term::Fabulous::Widget::Button->new( classes => ['primary'], bordered => 1, layout => { padding => { left => 1, right => 1 } } );
	$sign_in->add_child( Term::Fabulous::Widget::Text->new( text => 'Sign in' ) );
	my $cancel = Term::Fabulous::Widget::Button->new( bordered => 1, layout => { padding => { left => 1, right => 1 } } );
	$cancel->add_child( Term::Fabulous::Widget::Text->new( text => 'Cancel' ) );
	my $buttons = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
	$buttons->add_child( $sign_in, $cancel );

	$form->add_child(
		Term::Fabulous::Widget::Divider->new( text => 'Sign in', text_position => 'start' ),
		$name, $password,
		Term::Fabulous::Widget::Checkbox->new( label => 'Keep me signed in' ),
		$buttons,
	);
	return $form;
}

# The editor shows the screen on its left, in the theme being edited,
# instead of its gallery of widgets; the editor itself is drawn in the
# built-in light theme. The theme file is the first argument, or
# sign-in.kdl in the current directory, which is made when you save.
Term::Fabulous::ThemeEditor->new(
	files    => [ $ARGV[0] // 'sign-in.kdl' ],
	preview  => sub ($editor) { sign_in_screen() },
	ui_theme => 'light',
)->run;
