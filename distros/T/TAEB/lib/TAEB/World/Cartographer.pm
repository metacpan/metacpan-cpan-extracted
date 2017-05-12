package TAEB::World::Cartographer;
use TAEB::OO;
use NetHack::FOV 'calculate_fov';
use TAEB::Util 'assert';

has dungeon => (
    is       => 'ro',
    isa      => 'TAEB::World::Dungeon',
    weak_ref => 1,
    required => 1,
);

has x => (
    is  => 'rw',
    isa => 'Int',
);

has y => (
    is  => 'rw',
    isa => 'Int',
);

has fov => (
    isa       => 'ArrayRef',
    is        => 'ro',
    default   => sub { calculate_fov(TAEB->x, TAEB->y, sub {
            my $tile = TAEB->current_level->at(@_);
            $tile && $tile->is_transparent ? 1 : 0;
        }) },
    clearer   => 'invalidate_fov',
    lazy      => 1,
);

# The last two locations the TAEB's been to, so we know which
# way we're going when entering a shop or other room.
has _earlier_location => (
    isa       => 'TAEB::World::Tile',
    is        => 'rw',
);

has _last_location => (
    isa       => 'TAEB::World::Tile',
    is        => 'rw',
    trigger   => sub {
        my $self = shift;
        my $new  = shift;
        return if $self->_last_location == $new;
        $self->_earlier_location($self->_last_location);
    }
);

sub update {
    my $self  = shift;

    my ($old_x, $old_y) = ($self->x, $self->y);
    my $old_level = $self->dungeon->current_level;

    my ($Tx, $Ty) = (TAEB->vt->x, TAEB->vt->y);
    $self->x($Tx);
    $self->y($Ty);

    return if $self->is_engulfed;

    return unless $self->check_dlvl;

    my $level = $self->dungeon->current_level;

    my $tile_changed = 0;

    $level->iterate_tile_vt(sub {
        my ($tile, $glyph, $color, $x, $y) = @_;

        $tile->_clear_monster if $tile->has_monster;
        $tile->try_monster($glyph, $color)
            unless $Tx == $x && $Ty == $y;

        if ($glyph ne $tile->glyph || $color != $tile->color) {
            $tile_changed = 1;
            $level->update_tile($x, $y, $glyph, $color);
        }
        # XXX: this should be checking for 'visual range' (taking blindness and
        # lamps into account) - currently blindness is tested for in
        # Tile::update
        elsif (abs($x - $Tx) <= 1
            && abs($y - $Ty) <= 1
            && $tile->type eq 'unexplored') {
            $level->update_tile($x, $y, $glyph, $color);
        }

        return 1;
    });

    $old_level->step_off($old_x, $old_y) if defined($old_x);
    $level->step_on($self->x, $self->y);

    if ($tile_changed) {
        $self->autoexplore;
        $self->dungeon->current_level->detect_branch;
        TAEB->enqueue_message('tile_changes');
    }

    if ($tile_changed || $self->x != $old_x || $self->y != $old_y) {
        $self->invalidate_fov;
    }
}

=head2 map_like Regex -> Bool

Returns whether any part of the map (not the entire screen) matches Regex.

=cut

sub map_like {
    my $self = shift;
    my $re = shift;

    defined TAEB->vt->find_row(sub {
        my ($row, $y) = @_;
        $y > 0 && $y < 22 && $row =~ $re;
    });
}

=head2 check_dlvl

Updates the current_level if Dlvl appears to have changed.

=cut

sub check_dlvl {
    my $self = shift;

    my $botl = TAEB->vt->row_plaintext(23);
    $botl =~ /^(Dlvl|Home|Fort Ludios|End Game|Astral Plane)(?::| )?(\d*) /
        or do {
            TAEB->log->cartographer("Unable to parse the botl for dlvl: $botl",
                                    level => 'error');
            return;
    };

    my $level = $self->dungeon->current_level;
    my $descriptor = $1;
    my $dlvl = $2 || $level->z;
    my $was_ludios = $level->known_branch && $level->branch eq 'ludios';
    my $is_ludios = $descriptor eq 'Fort Ludios';

    if ($level->z != $dlvl || $was_ludios != $is_ludios) {
        TAEB->log->cartographer("Oh! We seem to be on a different map. Was ".$level->z.", now $dlvl.");

        my @levels = $self->dungeon->get_levels($dlvl);
        my $newlevel;

        for my $level (@levels) {
            if ($level->matches_vt) {
                $newlevel = $level;
                last;
            }
        }

        unless ($newlevel) {
            $newlevel = $self->dungeon->create_level($dlvl);
            if ($dlvl >= 2 && $dlvl <= 10) {
                if ($newlevel->detect_sokoban_vt) {
                    $newlevel->branch('sokoban');
                }
            }
            if ($dlvl >= 10 && $dlvl <= 12) {
                if ($newlevel->detect_bigroom_vt) {
                    $newlevel->branch('dungeons');
                    $newlevel->is_bigroom(1);
                }
            }
            if ($botl =~ /\*:\d+/) {
                $newlevel->branch('dungeons');
                $newlevel->is_rogue(1);
            }
            else { $newlevel->is_rogue(0) }
            if ($descriptor eq 'Home') {
                $newlevel->branch('quest');
            }
            elsif ($descriptor eq 'Fort Ludios') {
                $newlevel->branch('ludios');
            }
        }

        TAEB->log->cartographer("Created level: $newlevel");

        $self->dungeon->current_level($newlevel);
        TAEB->enqueue_message('dlvl_change', $level->z => $dlvl);
    }

    return 1;
}

=head2 autoexplore

Mark tiles that are obviously explored as such. Things like "a tile
with no unknown neighbors".

=cut

sub autoexplore {
    my $self = shift;
    my $level = $self->dungeon->current_level;

    for my $y (1 .. 21) {
        TILE: for my $x (0 .. 79) {
            my $tile = $level->at($x, $y);

            if (!$tile->explored
             && $tile->type ne 'rock'
             && $tile->type ne 'unexplored') {
                $tile->explored(1) unless $tile->any_adjacent(sub {
                    shift->type eq 'unexplored'
                });
            }
        }
    }
}

sub msg_dungeon_feature {
    my $self    = shift;
    my $feature = shift;
    my ($floor, $type, $subtype);

    if ($feature eq 'staircase down') {
        $floor = '>';
        $type  = 'stairsdown';
    }
    elsif ($feature eq 'staircase up') {
        $floor = '<';
        $type  = 'stairsup';
    }
    elsif ($feature eq 'bad staircase') {
        # Per Eidolos' idea: all stairs in rogue are marked as stairsdown, and
        # we only change them to stairs up if we get a bad staircase message.
        # This code was originally to fix mimics being stairs inside a shop,
        # but we don't have to worry about mimics in Rogue.
        if (!TAEB->current_level->is_rogue) {
            $floor = ' ';
            $type = 'obscured';
        } else {
            $floor = '<';
            $type = 'stairsup';
        }
        # if we get a bad_staircase message, we're obviously confused about
        # things, so make sure we don't leave other_side pointing to strange
        # places
        TAEB->current_tile->clear_other_side
            if TAEB->current_tile->can('clear_other_side');
    }
    elsif ($feature eq 'fountain' || $feature eq 'sink') {
        $floor = '{';
        $type  = $feature;
    }
    elsif ($feature eq 'fountain dries up' || $feature eq 'brokendoor') {
        $floor = '.';
        $type  = 'floor';
    }
    elsif ($feature eq 'trap') {
        $subtype = shift;
        if ($subtype) {
            $floor = '^';
            $type  = 'trap';
        }
        else {
            $floor = '.';
            $type  = 'floor';
        }
    }
    elsif ($feature eq 'grave') {
        $floor = '\\';
        $type = 'grave';
    }
    elsif ($feature =~ /\baltar$/) {
        $floor = '_';
        $type = 'altar';
        $subtype = shift;
    }
    else {
        # we don't know how to handle it :/
        return;
    }

    my $tile     = TAEB->current_tile;
    my $oldtype  = $tile->type;
    my $oldfloor = $tile->floor_glyph;

    if ($oldtype ne $type || $oldfloor ne $floor) {
        TAEB->log->cartographer("msg_dungeon_feature('$feature') caused the current tile to be updated from ('$oldfloor', '$oldtype') to ('$floor', '$type')");
    }

    $tile->change_type($type => $floor, $subtype);
}

sub msg_excalibur {
    my $self = shift;

    TAEB->current_tile->change_type(floor => '.');
}

sub msg_clear_floor {
    my $self = shift;
    my $item = shift;

    TAEB->current_tile->clear_items;
}

sub msg_floor_item {
    my $self = shift;
    my $item = shift;

    TAEB->current_tile->add_item($item) if $item;
}

sub msg_remove_floor_item {
    my $self = shift;
    my $item = shift;
    my $tile = TAEB->current_tile;

    for my $i (0 .. $tile->item_count - 1) {
        my $tile_item = $tile->items->[$i];

        if ($item->maybe_is($tile_item)) {
            $tile->remove_item($i);
            return;
        }
    }

    return if $item->is_auto_picked_up;

    assert(0, "Unable to remove $item from the floor.");
}

sub msg_floor_message {
    my $self = shift;
    my $message = shift;

    TAEB->log->cartographer(TAEB->current_tile . " is now engraved with \'$message\'");
    TAEB->current_tile->engraving($message);

    my @doors = TAEB->current_tile->grep_adjacent(sub { $_->type eq 'closeddoor' });
    if (@doors) {
        if (TAEB::Spoilers::Engravings->is_degradation("Closed for inventory" => $message)) {
            $_->is_shop(1) for @doors;
        }
    }
}

sub msg_engraving_type {
    my $self = shift;
    my $engraving_type = shift;

    TAEB->current_tile->engraving_type($engraving_type);
}

sub msg_pickaxe {
    TAEB->current_level->pickaxe(TAEB->turn);
}

sub floodfill_room {
    my $self = shift;
    my $type = shift;
    my $tile = shift || TAEB->current_tile;
    $tile->floodfill(
        sub {
            my $t = shift;
            $t->type eq 'floor' || $t->type eq 'obscured' || $t->type eq 'altar'
        },
        sub {
            my $t   = shift;
            my $var = "in_$type";
            return if $t->$var;
            TAEB->log->cartographer("$t is in a $type!");
            $t->$var(1);
        },
    );
}

sub msg_debt {
    shift->floodfill_room('shop');
}

sub msg_step {
    shift->_last_location(TAEB->current_tile);
}

sub msg_enter_room {
    my $self     = shift;
    my $type     = shift || return;
    my $subtype  = shift;

    # Okay, so we want to floodfill the room when we enter it.
    # Because we get the message in the doorway, we can't floodfill from that
    # tile.
    # Instead, we take into account which way the TAEB is going. If there's
    # exactly one square that is orthogonal to us, not adjacent to our
    # previous location, and walkable, fill from there. Otherwise we're
    # confused (maybe we teleported into the room?); log a warning and don't
    # fill anything.
    my @possibly_inside;
    my $last_tile = $self->_last_location;
    $last_tile = $self->_earlier_location
        if defined $last_tile && $last_tile == TAEB->current_tile;
    my $ltx = $last_tile ? $last_tile->x : -2;
    my $lty = $last_tile ? $last_tile->y : -2;
    TAEB->current_tile->each_orthogonal(sub {
        my $tile = shift;
        return if abs($tile->x - $ltx) <= 1
               && abs($tile->y - $lty) <= 1;
        return unless $tile->is_walkable(1);
        push @possibly_inside, $tile;
    });

    if (@possibly_inside == 1) {
        $self->floodfill_room($type, $possibly_inside[0]);
    }
    else {
        TAEB->log->cartographer(
            "Can't figure out where the boundaries of this room are: "
          . @possibly_inside . " possibilities",
            level => 'warning'
        );
    }
}

sub msg_vault_guard {
    shift->floodfill_room('vault');
}

=head2 is_engulfed -> Bool

Checks the screen to see if we're engulfed. It'll inform the rest of the system
about our engulfedness. Returns 1 if we're engulfed, 0 if not.

=cut

my @engulf_expected = (
    [-1, -1] => '/',
    [ 0, -1] => '-',
    [ 1, -1] => '\\',
    [-1,  0] => '|',
    [ 1,  0] => '|',
    [-1,  1] => '\\',
    [ 0,  1] => '-',
    [ 1,  1] => '/',
);

sub is_engulfed {
    my $self = shift;

    for (my $i = 0; $i < @engulf_expected; $i += 2) {
        my ($deltas, $glyph) = @engulf_expected[$i, $i + 1];
        my ($dx, $dy) = @$deltas;

        my $got = TAEB->vt->at(TAEB->x + $dx, TAEB->y + $dy);
        next if $got eq $glyph;

        return 0 unless TAEB->is_engulfed;

        TAEB->log->cartographer("We're no longer engulfed! I expected to see $glyph at delta ($dx, $dy) but I saw $got.");
        TAEB->enqueue_message(engulfed => 0);
        return 0;
    }

    TAEB->log->cartographer("We're engulfed!");
    TAEB->enqueue_message(engulfed => 1);
    return 1;
}

sub msg_branch {
    my $self   = shift;
    my $branch = shift;
    my $level  = $self->dungeon->current_level;

    $level->branch($branch)
        unless $level->known_branch;

    return if $level->branch eq $branch;

    TAEB->log->cartographer("Tried to set the branch of $level to $branch but it already has a branch.", level => 'error');
}

sub msg_quest_portal {
    my $self = shift;

    TAEB->current_level->has_quest_portal(1);
}


__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

