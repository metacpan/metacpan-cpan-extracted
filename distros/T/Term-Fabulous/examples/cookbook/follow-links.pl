#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::RichText;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);

# The pages of a small help text, in markup. A link's target is the
# name of another page, or a URL.
my %markup_of_page = (
	start => join(
		' ',
		"[bold]Help[/]\n\nStart with the [link=keys]keys[/link], or read what a [link=links]link[/link] is.",
		'The whole manual is on [link=https://metacpan.org/pod/Term::Fabulous]MetaCPAN[/link].',
	),
	keys => join(
		' ',
		"[bold]Keys[/]\n\nTab selects the first link of a page, Left and Right select the others,",
		'Enter follows the selected one. Backspace goes back to the page before,',
		'or click [link=start]the start page[/link].',
	),
	links => join(
		' ',
		"[bold]Links[/]\n\nA link is a range of the text with a target. Following it fires LinkActivate,",
		'and the program decides what the target means: here, the name of a page such as',
		'[bold][link=keys]keys[/link][/] (a bold link) or a URL.',
	),
);

# Links in the theme's success green instead of the accent color; the
# selected link is green with dark text.
my $theme = Term::Fabulous::Theme->new(
	name    => 'green-links',
	extends => 'dark',
	slots   => {
		'text.link'                     => 'success',
		'text.link.selected'            => 'text_inverse',
		'text.link.background.selected' => 'success',
	},
);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1, bottom => 1 },
		child_gap        => 1,
	},
);

# The page wraps at 60 columns: the width of the box around it.
my $page_box = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(60) } } );
my $page     = Term::Fabulous::Widget::RichText->new( markup => $markup_of_page{start} );
$page_box->add_child($page);
my $status = Term::Fabulous::Widget::Text->new( text => 'Tab selects a link, Enter follows it.', text_color => [ 150, 160, 180, 255 ] );

# A footer whose links are given from Perl: any value can be a target,
# here the code to run.
my $footer = Term::Fabulous::Widget::RichText->new( text => 'Back   Quit' );
$root->add_child( $page_box, $footer, $status );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root, theme => $theme );

my $current_page = 'start';
my @history;

sub show_page ($name) {
	push @history, $current_page;
	$current_page = $name;
	$page->markup( $markup_of_page{$name} );
	$status->text("You are on the page '$name'.");
	return;
}

sub go_back () {
	my $name = pop @history // return;
	$current_page = $name;
	$page->markup( $markup_of_page{$name} );
	$status->text("Back on the page '$name'.");
	return;
}

$footer->add_link( \&go_back,               0, 4 );
$footer->add_link( sub { $ui->loop->stop }, 7, 11 );

# LinkActivate bubbles up from both RichTexts, so one listener on the
# root follows every link, clicked or chosen with the keyboard.
$root->on(
	LinkActivate => sub ($event) {
		my $target = $event->link;
		return $target->() if ref $target eq 'CODE';
		return show_page($target) if exists $markup_of_page{$target};
		$status->text("This would open $target in a browser.");
		return;
	}
);

# Keys the focused RichText does not use bubble on to the root.
$root->on(
	KeyPress => sub ($event) {
		my $key = $event->key_name // '';
		return go_back() if $key eq 'Backspace';
		return $ui->loop->stop if $key eq 'Escape';
		return;
	}
);

$ui->run;
