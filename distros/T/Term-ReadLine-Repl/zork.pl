#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long ();
use Term::ANSIColor qw(colored);

#use lib './lib';  # Uncomment to run from the repo root without installing
use Term::ReadLine::Repl;

# =============================================================================
# Game state
# =============================================================================

my %state = (
    location => 'clearing',
    moves    => 0,
    score    => 0,
);
my @inventory;

# =============================================================================
# World definition
# =============================================================================

my %rooms = (
    clearing => {
        name  => 'West of House',
        desc  => 'You are standing in an open field west of a white house, '
               . 'with a boarded front door. A mailbox stands nearby.',
        long  => 'You are standing in an open field west of a white house, '
               . 'with a boarded front door. The windows are dark and shuttered. '
               . 'A weathered mailbox leans by the path. A trail winds north '
               . 'into the forest; a gravel path leads south into a gully.',
        exits => { north => 'forest', south => 'gully' },
        items => [qw(lantern leaflet)],
    },
    forest => {
        name  => 'Forest',
        desc  => 'You are in a dimly lit forest. Trees press in from all sides. '
               . 'A path leads south back toward the house.',
        long  => 'You are deep in a pine forest. The canopy overhead blocks most '
               . 'of the sky. Roots push up through the leaf litter underfoot. '
               . 'The only clear path leads south, back toward the house. '
               . 'Something on the ground catches your eye.',
        exits => { south => 'clearing' },
        items => [qw(sword)],
    },
    gully => {
        name  => 'Rocky Gully',
        desc  => 'You are in a steep rocky gully. The path continues north. '
               . 'A narrow cave entrance gapes open to the east.',
        long  => 'You are in a steep gully carved by an ancient stream. '
               . 'Mossy boulders crowd the walls. The path winds north back '
               . 'toward the house. To the east, an ominous cave entrance '
               . 'exhales cold, stale air.',
        exits => { north => 'clearing', east => 'cave' },
        items => [],
    },
    cave => {
        name  => 'Dark Cave',
        desc  => 'You are in a damp cave. Water drips from the ceiling. '
               . 'The exit is to the west.',
        long  => 'You are in a narrow cave. Stalactites hang from the ceiling '
               . 'and the walls glisten with moisture. Something large seems '
               . 'to be lurking just out of sight. The exit is to the west.',
        exits => { west => 'gully' },
        items => [qw(treasure)],
        dark  => 1,
    },
);

my %items = (
    lantern => {
        name => 'brass lantern',
        desc => 'A battery-powered brass lantern. It will keep the dark at bay.',
    },
    leaflet => {
        name => 'leaflet',
        desc => 'A small leaflet. It reads: '
              . '"WELCOME TO ZORK! Your quest: find the treasure '
              . 'hidden in the cave and return it to the clearing. '
              . 'Beware of the grue."',
    },
    sword => {
        name => 'elvish sword',
        desc => 'A sword of elvish workmanship. The blade glows faintly blue, '
              . 'a sure sign of nearby danger.',
    },
    treasure => {
        name => 'pile of treasure',
        desc => 'Gold coins, priceless jewels, and ancient artifacts. '
              . 'This must be worth a fortune!',
    },
);

# =============================================================================
# Helpers
# =============================================================================

sub has_item {
    my ($item) = @_;
    return grep { $_ eq $item } @inventory;
}

sub room_has_item {
    my ($room_id, $item) = @_;
    return grep { $_ eq $item } @{ $rooms{$room_id}{items} };
}

sub describe_room {
    my ($verbose) = @_;
    my $room = $rooms{ $state{location} };

    # Dark rooms are impassable without the lantern.
    if ($room->{dark} && !has_item('lantern')) {
        print "\n", colored('Darkness', 'bold'), "\n";
        print "It is pitch black. You can't see a thing.\n\n";
        return;
    }

    print "\n", colored($room->{name}, 'bold'), "\n";
    print( $verbose ? $room->{long} : $room->{desc} );
    print "\n";

    if (@{ $room->{items} }) {
        my @names = map { $items{$_}{name} } @{ $room->{items} };
        print "You can see: ", join(', ', @names), ".\n";
    }

    my @exits = sort keys %{ $room->{exits} };
    print "Exits: ", join(', ', @exits), ".\n\n";
}

# =============================================================================
# get_opts callback
#
# Called by the REPL before each command dispatch.  Parses flags out of the
# raw input line (via @ARGV) and stores results in %opts so command handlers
# can read them.  'pass_through' suppresses warnings for unrecognised options
# typed for commands that don't use any flags.
# =============================================================================

my %opts;

sub parse_flags {
    %opts = ( verbose => 0 );
    Getopt::Long::Configure('pass_through');
    Getopt::Long::GetOptions( \%opts, 'verbose|v' );
}

# =============================================================================
# custom_logic callback
#
# Called by the REPL every iteration, before command dispatch.  Handles
# global game-loop concerns: move counting, darkness death, and win detection.
# Returning { action => 'last' } exits the REPL loop entirely.
# =============================================================================

sub game_loop_logic {
    my ($args) = @_;

    $state{moves}++;

    # Darkness check — grue kills the player in any dark room without a lantern.
    if ( $rooms{ $state{location} }{dark} && !has_item('lantern') ) {
        print "\nIt is pitch black. You are likely to be eaten by a grue.\n";
        print "A grue slithers out of the darkness and swallows you whole.\n\n";
        print colored('*** YOU HAVE DIED ***', 'red bold'), "\n\n";
        printf "You lasted %d move%s.\n\n",
            $state{moves}, $state{moves} == 1 ? '' : 's';
        return { action => 'last' };
    }

    # Win check — player has brought the treasure back to the clearing.
    if ( $state{location} eq 'clearing' && has_item('treasure') ) {
        print "\nYou step back into the sunlight, arms full of treasure.\n";
        print "A strange sense of completion washes over you.\n\n";
        print colored('*** YOU HAVE WON ***', 'green bold'), "\n\n";
        printf "Completed in %d move%s with a score of %d.\n\n",
            $state{moves}, $state{moves} == 1 ? '' : 's', $state{score};
        return { action => 'last' };
    }

    return undef;
}

# =============================================================================
# Command handlers
# =============================================================================

sub cmd_look {
    describe_room( $opts{verbose} );
}

sub cmd_go {
    my ($dir) = @_;
    unless ($dir) {
        print "Go where? (north, south, east, west)\n";
        return;
    }
    my $exits = $rooms{ $state{location} }{exits};
    unless ( exists $exits->{$dir} ) {
        print "You can't go $dir from here.\n";
        return;
    }
    $state{location} = $exits->{$dir};
    print "You head $dir.\n";
    describe_room(0);
}

sub cmd_take {
    my ($item_id) = @_;
    unless ($item_id) {
        print "Take what?\n";
        return;
    }
    unless ( exists $items{$item_id} ) {
        print "I don't know what '$item_id' is.\n";
        return;
    }
    unless ( room_has_item( $state{location}, $item_id ) ) {
        print "There is no $items{$item_id}{name} here.\n";
        return;
    }
    push @inventory, $item_id;
    $rooms{ $state{location} }{items} =
        [ grep { $_ ne $item_id } @{ $rooms{ $state{location} }{items} } ];
    $state{score} += 10;
    print "Taken.\n";
}

sub cmd_drop {
    my ($item_id) = @_;
    unless ($item_id) {
        print "Drop what?\n";
        return;
    }
    unless ( has_item($item_id) ) {
        my $name = $items{$item_id} ? $items{$item_id}{name} : $item_id;
        print "You aren't carrying the $name.\n";
        return;
    }
    @inventory = grep { $_ ne $item_id } @inventory;
    push @{ $rooms{ $state{location} }{items} }, $item_id;
    print "Dropped.\n";
}

sub cmd_inventory {
    if (@inventory) {
        print "You are carrying:\n";
        print "  - $items{$_}{name}\n" for @inventory;
    } else {
        print "You are empty-handed.\n";
    }
}

sub cmd_examine {
    my ($item_id) = @_;
    unless ($item_id) {
        print "Examine what?\n";
        return;
    }
    unless ( exists $items{$item_id} ) {
        print "I don't know what '$item_id' is.\n";
        return;
    }
    unless ( has_item($item_id) || room_has_item( $state{location}, $item_id ) ) {
        print "You don't see that here.\n";
        return;
    }
    print "$items{$item_id}{desc}\n";
}

sub cmd_score {
    printf "Moves: %d | Score: %d\n", $state{moves}, $state{score};
}

# =============================================================================
# Build and launch the REPL
# =============================================================================

# Reuse the same completion list (all item IDs) for take/drop/examine.
my $all_items = { map { $_ => undef } keys %items };

my $repl = Term::ReadLine::Repl->new({
    name         => 'zork',
    prompt       => '[%s]>',
    hist_file    => "$ENV{HOME}/.zork_history",
    get_opts     => \&parse_flags,
    custom_logic => \&game_loop_logic,
    cmd_schema   => {
        look => {
            exec => \&cmd_look,
            args => [{ '--verbose' => undef, '-v' => undef }],
        },
        go => {
            exec => \&cmd_go,
            args => [{ north => undef, south => undef,
                       east  => undef, west  => undef }],
        },
        take => {
            exec => \&cmd_take,
            args => [$all_items],
        },
        drop => {
            exec => \&cmd_drop,
            args => [$all_items],
        },
        examine => {
            exec => \&cmd_examine,
            args => [$all_items],
        },
        inventory => {
            exec => \&cmd_inventory,
        },
        score => {
            exec => \&cmd_score,
        },
    },
});

# Print the opening crawl, then describe the starting room before handing
# control to the REPL loop.
print "\n";
print "=" x 58, "\n";
print "  ZORK I: The Great Underground Empire\n";
print "  (A Term::ReadLine::Repl feature demo)\n";
print "=" x 58, "\n";
print "\nType 'help' to list commands. Tab completes commands and args.\n";
print "Use 'look -v' for verbose room descriptions.\n";

describe_room(0);

$repl->run();
