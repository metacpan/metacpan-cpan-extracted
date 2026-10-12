#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Enum::Bubble;
use Clay::UI::Enum::Result;
use Clay::UI::Events::Event;
use Term::Fabulous::Widget::Box;

# An event class with data of its own. event_name is the name listeners
# register for.
class My::Event::Saved :isa(Clay::UI::Events::Event) :strict(params) {
	field $path :param :reader;

	method event_name :common { 'Saved' }
}

my $app    = Term::Fabulous::Widget::Box->new( id => 'app' );
my $editor = Term::Fabulous::Widget::Box->new( id => 'editor' );
$app->add_child($editor);

$editor->on(
	Saved => sub ($event) {
		say 'editor: saved ', $event->path;
		return Clay::UI::Enum::Result->CONTINUE;    # let the ancestors see it too
	}
);
$app->on(
	Saved => sub ($event) {
		say 'app: ', $event->target->id, ' saved ', $event->path;
		return;
	}
);
$app->on( Refresh => sub ($event) { say 'app: refresh requested by ', $event->target->id; return } );

# Fire an event of the class; every event object can be fired once.
$editor->fire_event( My::Event::Saved->new( path => '/tmp/notes.txt' ) );

# A plain event needs only a name. ALWAYS bubbles to every ancestor,
# whatever the listeners return.
$editor->fire_event( Clay::UI::Events::Event->new( name => 'Refresh', bubble_mode => Clay::UI::Enum::Bubble->ALWAYS ) );
