#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow);
use Term::Fabulous;
use Term::Fabulous::Document;
use Term::Fabulous::Document::Look;
use Term::Fabulous::Widget::DocumentView;

# The styles of the document: two built-in kinds changed, three kinds
# added. Colors are palette tokens of the theme, so the styles follow a
# theme switch.
class My::ManualLook :isa(Term::Fabulous::Document::Look) {

	method recipes :common () {
		return (
			$class->SUPER::recipes,
			heading1  => { words => 'bold', color => 'success' },
			code      => { color => 'accent' },
			key       => { words => 'bold', color => 'text_bright', background => 'surface_raised' },
			underline => { words => 'underline' },
			highlight => { color => 'text_inverse', background => 'warning' },
		);
	}
}

# A piece is a plain string or [ KIND => 'text' ].
sub marked (@pieces) {
	my ( $text, @marks ) = ('');
	foreach my $piece (@pieces) {
		my ( $kind, $words ) = ref $piece ? @$piece : ( undef, $piece );
		my $start = length $text;
		$text .= $words;
		push @marks, [ $start, length $text, $kind ] if defined $kind;
	}
	return { text => $text, marks => \@marks };
}

# The document names the look its factories style the marks with; a
# kind the look does not know dies at once.
my $document = Term::Fabulous::Document->new( look => 'My::ManualLook' );
$document->heading( 1, 'Keys of the editor' );
$document->paragraph(
	marked( 'Press ', [ key => 'Ctrl+S' ], ' to save the file and ', [ key => 'Ctrl+Q' ], ' to quit. Unsaved changes are ', [ underline => 'never' ], ' lost: the editor asks first.' ) );
$document->paragraph(
	marked( 'The settings live in ', [ code => '~/.editorrc' ], '. ', [ highlight => 'New in version 3:' ], ' ', [ key => 'F2' ], ' switches between the dark and the light theme.' ) );
$document->heading( 2, 'Moving around' );
$document->paragraph( marked( [ key => 'Home' ], ' and ', [ key => 'End' ], ' go to the start and the end of a line, ', [ bold => 'Ctrl' ], ' with them to the start and the end of the file.' ) );

my $view = Term::Fabulous::Widget::DocumentView->new(
	id       => 'manual',
	document => $document,
	indent   => 4,
	layout   => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 1, right => 1, top => 1 } },
);

my $ui = Term::Fabulous->new( root => $view, width => 80, height => 24 );

$view->on(
	KeyPress => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless ( $event->key_name // '' ) eq 'F2';
		$ui->theme( $ui->theme->name eq 'dark' ? 'light' : 'dark' );
		return;
	}
);

$ui->interaction->set_focused_widget($view);
$ui->run;
