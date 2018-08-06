
use 5.10.0;

use strict;
use warnings;

use Term::Caca::Constants qw/ :events /;
use Term::Caca;

use Data::Printer;

use experimental qw/
    signatures
    postderef
/;

my $t = Term::Caca->new;
$t->refresh;

my @events = qw/ 
    Mouse::Motion 
    Resize 
    Quit 
    Key::Press 
    Key::Release 
    Key 
    Mouse::Button 
    Mouse::Button::Press 
    Mouse::Button::Release 
/;

my %seen = map { $_ => 0 } @events;

my $bye;

my %report = (
    'Quit' => sub { say "quitting"; $bye = 1; },
    Key    => sub { say "character: ", $_[0]->char },
    'Mouse::Button' => sub { 
        my $data = {
            map { $_ => $_[0]->$_ } qw/ left right middle index /
        };
        p $data;
    },
    'Mouse::Motion' => sub { printf "x: %i, y: %i, pos: %s\n", 
        $_[0]->x,
        $_[0]->y,
        join ',', $_[0]->pos->@*,
    },
    'Resize' => sub { printf "w: %i, y: %i, size %s\n", 
        $_[0]->width,
        $_[0]->height,
        join ',', $_[0]->size->@*,
    },
);

sub print_report {
    print "\n\n";
    while( my ( $event, $seen ) = each %seen ) {
        printf "%20s => %s\n", $event, $seen || 0;
    }
}

until($bye) {

    my $event = $t->wait_for_event( undef, -1 );

    my $type = $event->type;

    say $type;

    $seen{$_}++ for grep { $event->isa( 'Term::Caca::Event::' . $_ ) } keys %seen;

    for my $t ( sort keys %report ) {
        $report{$t}->($event) if $event->isa("Term::Caca::Event::$t");
    }

    print_report();
}
