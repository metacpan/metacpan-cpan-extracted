
use 5.10.0;

use strict;
use warnings;

use Term::Caca qw/ :events /;

my $t = Term::Caca->new;
$t->refresh;

while(1) {
    my $event = $t->wait_for_event( mask => $KEY_PRESS | $QUIT, timeout => -5 );

    say ">>> ", ref $event;

    if ( $event->isa( 'Term::Caca::Event::Mouse::Motion' ) ) {
        say join ":", $event->pos;
    } 
    
    if ( $event->isa( 'Term::Caca::Event::Resize' ) ) {
        say join ":", $event->size;
    }

    if ( $event->isa( 'Term::Caca::Event::Quit' ) ) {
        say "quitting...";
        exit;
    }

    if ( $event->isa( 'Term::Caca::Event::Key' ) ) {
        say "character: ", $event->char;
    }

    if ( $event->isa( 'Term::Caca::Event::Mouse::Button' ) ) {
        my @buttons = qw/ dummy left middle right /;
        say "button pressed: ", $buttons[ $event->index ];
    }
}
