package TAEB::World::Tile;
use TAEB::OO;
use TAEB::Util qw/delta2vi vi2delta display :colors/;
use List::MoreUtils qw/any all apply/;

with 'TAEB::Role::Reblessing';

use overload %TAEB::Meta::Overload::default;

has level => (
    is       => 'ro',
    isa      => 'TAEB::World::Level',
    weak_ref => 1,
    required => 1,
    handles  => [qw/z known_branch branch glyph_to_type/],
);

#has room => (
#    isa      => 'TAEB::World::Room',
#    weak_ref => 1,
#);

has type => (
    is      => 'rw',
    isa     => 'TAEB::Type::Tile',
    default => 'unexplored',
);

has glyph => (
    is      => 'rw',
    isa     => 'Str',
    default => ' ',
);

has floor_glyph => (
    is      => 'rw',
    isa     => 'Str',
    default => ' ',
);

has color => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has stepped_on => (
    is        => 'ro',
    metaclass => 'Counter',
);

has x => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has y => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has searched => (
    is        => 'ro',
    metaclass => 'Counter',
);

has explored => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
);

has engraving => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
    trigger => sub {
        my $self = shift;
        my $engraving = shift;
        if (length($engraving) > 255) {
            $self->engraving(substr($engraving, 0, 255));
        }
    },
);

has engraving_type => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
    documentation => "Store the writing type",
);

has is_interesting => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    writer  => 'set_interesting',
);

has monster => (
    is        => 'rw',
    isa       => 'TAEB::World::Monster',
    clearer   => '_clear_monster',
    predicate => 'has_monster',
);

has items => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[NetHack::Item]',
    default    => sub { [] },
    auto_deref => 1,
    provides   => {
        push   => 'add_item',
        clear  => 'clear_items',
        delete => 'remove_item',
        count  => 'item_count',
    },
);

has last_step => (
    is            => 'rw',
    isa           => 'Int',
    documentation => "The last step that we were on this tile",
);

has last_turn => (
    is            => 'rw',
    isa           => 'Int',
    default       => 0,
    documentation => "The last turn that we were on this tile",
);

has in_shop => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => "Is this tile inside a shop?",
);

has in_temple => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => "Is this tile inside a temple?",
);

has in_vault => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => "Is this tile inside a vault?",
);

has in_zoo => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => "Is this tile inside a zoo?",
);

has is_lit => (
    is            => 'rw',
    isa           => 'Maybe[Bool]',
    documentation => "Is this tile probably lit?  Will usually be wrong except on floor and corridors.",
);

has kill_times => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef',
    default   => sub { [] },
    provides  => {
        push  => '_add_kill_time',
        clear => '_clear_kill_times',
    },
    documentation => "Kills which have been committed on this tile.  " .
        "Each element is an arrayref with a monster name, a turn number, " .
        "and a force_verboten (used for unseen kills) flag.",
);

has intrinsic_cost => (
    is      => 'ro',
    isa     => 'Int',
    builder => '_build_intrinsic_cost',
    clearer => 'invalidate_intrinsic_cost_cache',
    lazy    => 1,
);

sub _build_intrinsic_cost {
    my $self = shift;
    my $cost = 100;

    $cost *= 20  if $self->has_monster;
    $cost *= 10  if $self->type eq 'trap';
    $cost *= 4   if $self->type eq 'ice';
    $cost *= 1.1 if !$self->is_engravable;

    # prefer tiles we've stepped on to avoid traps
    $cost = $cost * .9 if $self->stepped_on;

    return int($cost);
}

sub update {
    my $self        = shift;
    my $newglyph    = shift;
    my $color       = shift;
    my $oldtype     = $self->type;
    my $hadfriendly = $self->has_friendly;

    # gas spore explosions should not update the map
    return if $newglyph =~ m{^[\\/-]$} && $color == 1;

    $self->glyph($newglyph);
    $self->color($color);

    $self->update_lit;

    $self->invalidate_intrinsic_cost_cache;

    # dark rooms
    return if $self->glyph eq ' ' && $self->floor_glyph eq '.';

    my $newtype = $self->glyph_to_type($newglyph, $color);

    # rock next to where we're standing is definitely rock, unless
    # we're blinded; otherwise, it's unexplored if it was unexplored
    # before or if we weren't sure
    if ($newtype eq 'rock') {
        $newtype = 'unexplored' if $self->type eq 'unexplored'
                                || $self->type eq 'obscured';
        $newtype = 'rock' if abs($self->x - TAEB->x) <= 1
                          && abs($self->y - TAEB->y) <= 1
                          && !TAEB->is_blind;
    }

    # if we unveil a square and it was previously rock, then it's obscured
    # perhaps we entered a room and a tile changed from ' ' to '!'
    # if the tile's type was anything else, then it *became* obscured, and we
    # don't want to change what we know about it
    # XXX: if the type is olddoor then we probably kicked/opened the door and
    # something walked onto it. this needs improvement
    if ($newtype eq 'obscured') {
        # ghosts and xorns and earth elementals should not update the map
        return if $newglyph eq 'X'
               || ($newglyph eq 'E' && $color == COLOR_BROWN);

        $self->set_interesting(1)
            unless $self->has_monster
                || $self->has_boulder
                || $hadfriendly; # if a friendly stepped off it, we don't
                                 # want it marked as interesting.

        return unless $oldtype eq 'rock'
                   || $oldtype eq 'unexplored'
                   || $oldtype eq 'wall'
                   || $oldtype eq 'closeddoor';
    } else {
        # If the tile is not obscured, there are no items on it.
        $self->clear_items;
    }

    $self->change_type($newtype => $newglyph);
}

my %is_walkable = map { $_ => 1 } qw/obscured stairsdown stairsup trap altar opendoor floor ice grave throne sink fountain corridor/;
sub is_walkable {
    my $self = shift;
    my $through_unknown = shift;
    my $dont_check_current_tile = shift;

    # current tile is always walkable, but don't check it if our caller
    # asked us not to (that check is rather slow)
    return 1 if !defined($dont_check_current_tile)
             && $self == TAEB->current_tile;

    # pathing through boulders is handled by dedicated behaviors
    return 0 if $self->has_boulder;

    # monsters are not pathable!
    return 0 if $self->has_monster;

    # traps are unpathable in Sokoban
    return 0 if $self->type eq 'trap'
             && $self->level->known_branch
             && $self->level->branch eq 'sokoban';

    # we can path through unlit areas that we haven't seen as rock for sure yet
    # if we're blind, then all bets are off
    return 1 if $through_unknown
             && !TAEB->is_blind
             && $self->type eq 'unexplored';

    return $is_walkable{ $self->type };
}

=head2 update_lit :: ()

Looks at the current glyph and position to make inferences about lighting
state.

=cut

sub update_lit {
    my $self = shift;

    my $within_night_vision = abs(TAEB->x - $self->x) <= 1
                           && abs(TAEB->y - $self->y) <= 1;

    # A square which is displayed as . must be lit from some source, unless
    # it is right next to us.

    $self->is_lit(1) if $self->glyph eq '.' && !$within_night_vision;

    # If it was displayed as ., but turned to a space, it must not have been
    # lit after all, or it would have stayed ..

    $self->is_lit(0) if $self->glyph eq ' ' && $self->floor_glyph eq '.';

    # Corridors are lit if and only if they are brightly colored.

    $self->is_lit($self->color == 15) if $self->glyph eq '#';

    # Other types of tiles cannot have light status easily determined.
    # Fortunately, they are rare and we usually do not fight on them.
}

sub step_on {
    my $self = shift;

    $self->inc_stepped_on;
    $self->explored(1);
    $self->last_turn(TAEB->turn);
    $self->last_step(TAEB->step);
    $self->set_interesting(0);
}

sub step_off {
    my $self = shift;

    $self->set_interesting(0);

    if ($self->level == TAEB->current_level) {
        # When we step off a tile, anything that's nearby and still . is lit
        $self->each_adjacent(sub {
            my ($tile, $dir) = @_;
            $tile->update_lit;
        });
    }
}

sub witness_kill {
    my ($self, $critter) = @_;

    return if TAEB->is_hallucinating;
    $self->_add_kill_time([ $critter, TAEB->turn, 0 ]);
}

sub iterate_tiles {
    my $self       = shift;
    my $controller = shift;
    my $usercode   = shift;
    my $directions = shift;

    my ($x, $y) = ($self->x, $self->y);

    if ($y <= 0) {
        TAEB->log->tile("" . (caller 1)[3] . " called with a y argument of ".$self->y.". This usually indicates an unhandled prompt.", level => 'error');
    }

    my $level = $self->level;

    my @tiles = grep { defined } map {
                                     $level->at_safe(
                                         $x + $_->[0],
                                         $y + $_->[1]
                                     )
                                 } @$directions;

    $controller->(sub {
        $usercode->($_, delta2vi($_->x - $x, $_->y - $y));
    }, @tiles);
}

my %tiletypes = (
    diagonal => [
        [-1, -1],          [-1, 1],

        [ 1, -1],          [ 1, 1],
    ],
    orthogonal => [
                  [-1, 0],
        [ 0, -1],          [ 0, 1],
                  [ 1, 0],
    ],
    adjacent => [
        [-1, -1], [-1, 0], [-1, 1],
        [ 0, -1],          [ 0, 1],
        [ 1, -1], [ 1, 0], [ 1, 1],
    ],
    adjacent_inclusive => [
        [-1, -1], [-1, 0], [-1, 1],
        [ 0, -1], [ 0, 0], [ 0, 1],
        [ 1, -1], [ 1, 0], [ 1, 1],
    ],
);
my %controllers = (
    each => \&apply,
    all  => \&all,
    any  => \&any,
    grep => sub { my $code = shift; grep { $code->($_) } @_ },
);

for my $tiletype (keys %tiletypes) {
    for my $name (keys %controllers) {
        __PACKAGE__->meta->add_method("${name}_${tiletype}" => sub {
            my $self = shift;
            my $code = shift;
            $self->iterate_tiles($controllers{$name},
                                 $code,
                                 $tiletypes{$tiletype})
        })
    }
}

sub elbereths {
    my $self = shift;
    my $engraving = $self->engraving;
    return $engraving =~ s/elbereth//gi || 0;
}

sub floodfill {
    my $self               = shift;
    my $continue_condition = shift;
    my $update_tile        = shift;

    return unless $continue_condition->($self);

    my @queue = $self;
    my %seen;

    while (my $tile = shift @queue) {
        next if $seen{$tile}++;
        $update_tile->($tile);

        $tile->each_adjacent(sub {
            my $t = shift;
            if (!$seen{$t} && $continue_condition->($t)) {
                push @queue, $t;
            }
        });
    }
}

sub base_class { __PACKAGE__ }

sub change_type {
    my $self     = shift;
    my $newtype  = shift;
    my $newglyph = shift;

    return if $self->type eq $newtype && $self->floor_glyph eq $newglyph;
    return if $self->level->is_rogue && $self->type eq 'stairsup';
    TAEB->enqueue_message('tile_update' => $self);

    $self->level->unregister_tile($self);

    $self->type($newtype);
    $self->floor_glyph($newglyph);

    $self->level->register_tile($self);

    $self->rebless("TAEB::World::Tile::\L\u$newtype", @_);
}

sub debug_line {
    my $self = shift;
    my @bits;

    push @bits, sprintf '(%d,%d)', $self->x, $self->y;
    push @bits, $1 if (blessed $self) =~ /TAEB::World::Tile::(.+)/;
    push @bits, 't=' . $self->type;

    push @bits, 'g<' . $self->glyph . '>';
    push @bits, 'f<' . $self->floor_glyph . '>'
        if $self->glyph ne $self->floor_glyph;

    push @bits, sprintf 'i=%d%s',
                    $self->item_count,
                    $self->is_interesting ? '*' : '';

    if ($self->engraving) {
        push @bits, sprintf 'E=%d/%d',
                        length($self->engraving),
                        $self->elbereths;
    }

    push @bits, 'lit'   if defined $self->is_lit && $self->is_lit;
    push @bits, 'unlit' if defined $self->is_lit && !$self->is_lit;
    push @bits, 'shop'  if $self->in_shop;
    push @bits, 'vault' if $self->in_vault;

    if ($self->has_enemy) {
        push @bits, 'enemy';
    }
    elsif ($self->has_monster) {
        push @bits, 'monster';
    }

    return join ' ', @bits;
}

sub try_monster {
    my ($self, $glyph, $color) = @_;

    # attempt to handle ghosts on the rogue level, which are always the
    # same glyphs as rocks. rogue level ignores your glyph settings.
    if ($self->level->is_rogue && !TAEB->is_blind && $glyph eq ' ') {
        return unless abs($self->x - TAEB->x) <= 1
                   && abs($self->y - TAEB->y) <= 1;

        # if we're standing in a corridor, unexplored wall tiles are still
        # ' ' glyphs. this does mean that ghosts in corridors won't be noticed,
        # but there's not much we can do about that
        return unless TAEB->current_tile->type ne 'corridor'
                   && $self->any_adjacent(sub { shift->type eq 'floor' });

        $glyph = 'X';
        $color = COLOR_GRAY;
    }
    else {
        return unless $self->level->glyph_is_monster($glyph);
    }

    my $monster = TAEB::World::Monster->new(
        glyph => $glyph,
        color => $color,
        tile  => $self,
    );

    $self->monster($monster);
    $self->level->add_monster($monster);
}

before _clear_monster => sub {
    my $self = shift;
    $self->level->remove_monster($self->monster);
};

sub has_enemy {
    my $monster = shift->monster
        or return 0;
    return $monster->is_enemy ? $monster : undef;
}

sub has_friendly {
    my $monster = shift->monster
        or return 0;
    return $monster->is_enemy ? undef : $monster;
}

sub has_boulder { shift->glyph eq '0' }

sub is_engravable {
    my $self = shift;

    return $self->type ne 'fountain'
        && $self->type ne 'altar'
        && $self->type ne 'grave';
}

sub normal_color {
    my $color = shift->color;
    $color = COLOR_WHITE if $color == COLOR_NONE;
    return display($color);
}

sub debug_color {
    my $self = shift;

    my $color = $self->in_shop || $self->in_temple
              ? display(color => COLOR_GREEN, bold => 1)
              : $self->has_enemy
              ? display(color => COLOR_RED, bold => 1)
              : $self->is_interesting
              ? display(COLOR_RED)
              : $self->searched > 5
              ? display(COLOR_CYAN)
              : $self->stepped_on
              ? display(COLOR_BROWN)
              : $self->explored
              ? display(COLOR_GREEN)
              : display(COLOR_WHITE);

    $color->reverse(1)
        if $self->type eq 'rock'; # known rock, not unexplored

    return $color;
}

sub lit_color {
    my $self = shift;

    return $self->is_lit
         ? display(COLOR_YELLOW)
         : !defined $self->is_lit
         ? display(COLOR_BROWN)
         : display(color => COLOR_WHITE, bold => 1);
}

sub los_color {
    my $self = shift;

    return $self->in_los
         ? display(COLOR_YELLOW)
         : display(color => COLOR_WHITE, bold => 1);
}

sub stepped_color {
    my $self = shift;
    my $stepped = $self->stepped_on;

    return display(color => COLOR_WHITE, bold => 1) if $stepped == 0;
    return display(COLOR_RED)                       if $stepped == 1;
    return display(COLOR_ORANGE)                    if $stepped == 2;
    return display(COLOR_BROWN)                     if $stepped < 5;
    return display(COLOR_YELLOW)                    if $stepped < 8;
    return display(COLOR_MAGENTA);
}

sub time_color {
    my $self = shift;
    my $last_turn = $self->last_turn;
    my $dt = TAEB->turn - $last_turn;

    return display(color => COLOR_WHITE, bold => 1)   if $last_turn == 0;
    return display(COLOR_RED)                         if $dt > 1000;
    return display(COLOR_ORANGE)                      if $dt > 500;
    return display(COLOR_BROWN)                       if $dt > 100;
    return display(COLOR_YELLOW)                      if $dt > 50;
    return display(COLOR_MAGENTA)                     if $dt > 25;
    return display(color => COLOR_MAGENTA, bold => 1) if $dt > 15;
    return display(COLOR_GREEN)                       if $dt > 10;
    return display(color => COLOR_GREEN, bold => 1)   if $dt > 5;
    return display(COLOR_CYAN)                        if $dt > 3;
    return display(color => COLOR_CYAN, bold => 1);
}

sub engraving_color {
    my $self = shift;
    my $engraving = $self->engraving ne '';
    my $bold = $self->elbereths ? 1 : 0;

    return $engraving
         ? display(color => COLOR_GREEN, bold => $bold)
         : display(COLOR_BROWN);
}

sub normal_glyph {
    my $self = shift;
    $self->glyph eq ' ' ? $self->floor_glyph : $self->glyph;
}

sub farlooked {}

# keep track of our items on the level object {{{
after add_item => sub {
    my $self = shift;
    push @{ $self->level->items }, @_;

    for my $item (@_) {
        next unless $item->match(subtype => 'corpse');

        my @kl = @{ $self->kill_times };
        my ($date, $v) = (undef, 0);

        # I think this should be about 749, but the consequences of failure
        # are enough to motivate paranoia
        @kl = grep { $_->[1] >= TAEB->turn - 1000 } @kl;

        for my $kill (@kl) {
            my ($name, $age, $bad) = @$kill;

            if (my $body = TAEB::Spoilers::Monster->monster($name)->
                    {corpse}->{undead}) {
                $name = $body;
                $age -= 100;
            }

            next unless $name eq $item->monster;

            if (!defined($date) || $date > $age) {
                $date = $age;
            }

            $v ||= $bad;
        }

        if (!defined($date)) {
            # This corpse has no kill record!  It must have died out of sight.
            push @kl, [ $item->monster, TAEB->turn, 1 ];
            $date = TAEB->turn;
            $v = 1;
        }

        $item->estimated_date($date);
        $item->is_forced_verboten($v);
        $item->buc('uncursed') unless $v;

        @{ $self->kill_times } = @kl;
    }
};

before clear_items => sub {
    my $self = shift;
    for ($self->items) {
        $self->_remove_level_item($_);
    }
};

before remove_item => sub {
    my $self = shift;
    my $idx = shift;
    $self->_remove_level_item($self->items->[$idx]);
};

sub _remove_level_item {
    my $self = shift;
    my $item = shift;
    my $level = $self->level;

    for my $i (0 .. $level->item_count - 1) {
        my $level_item = $level->items->[$i];
        if ($item == $level_item) {
            splice @{ $level->items }, $i, 1;
            return;
        }
    }
}
# }}}

# keep track of which tiles are interesting on the level object
before set_interesting => sub {
    my $self = shift;
    my $set = shift(@_) ? 1 : 0;

    my $is_interesting = $self->is_interesting ? 1 : 0;

    # no change? don't care
    return if $set == $is_interesting;

    if ($set) {
        $self->level->register_tile($self => 'interesting');
    }
    else {
        $self->level->unregister_tile($self => 'interesting');
    }
};

=head2 is_empty -> Bool

Returns true if the tile is free from items, monsters, boulders, and the player
character.

It *can* have a dungeon feature, such as a fountain.

=cut

sub is_empty {
    my $self = shift;

    # probably okay for now, we may want to check items monster etc explicitly
    # though
    return $self->glyph eq $self->floor_glyph;
}

=head2 is_transparent -> Bool

Returns true if the player can see through the tile.

=cut

my %opaque = map { $_ => 1 } qw(unexplored rock wall tree closeddoor cloud water);

sub is_transparent {
    my $self = shift;

    return !$opaque{$self->type} && !$self->has_boulder;
}

=head2 shows_items -> Bool

=cut

my %shows_items = map { $_ => 1 } qw(floor ice trap stairsup stairsdown altar grave throne sink fountain corridor air);

sub shows_items {
    my $self = shift;
    return 0 if !$self->is_lit;

    return $shows_items{$self->type};
}

=head2 in_los -> Bool

=cut

sub in_los {
    my $self = shift;

    return 0 if $self->level != TAEB->current_level;

    return TAEB->fov->[$self->x][$self->y];
}

sub distance {
    my $self  = shift;
    my $other = shift || TAEB->current_tile;

    return undef if $self->level != TAEB->current_level;

    return sqrt(($self->x - $other->x) ** 2 + ($self->y - $other->y) ** 2);
}

sub find_item {
    my $self = shift;
    my $raw  = shift;
    my $item = TAEB->new_item($raw);

    for ($self->items) {
        next unless $_->maybe_is($item);
        return $_;
    }

    warn "I can't reconcile $raw with anything on the ground at this tile.";
    return $item;
}

sub unexplored {
    confess "Set 'explored' not 'unexplored'" if @_ > 1;
    not shift->explored;
}

sub is_searchable {
    my $self = shift;

    return $self->type eq 'wall'
        || $self->type eq 'rock'
        || $self->type eq 'unexplored';
}

sub at_direction {
    my $self      = shift;
    my $direction = shift;

    if ($direction eq '<' || $direction eq '>') {
        if ($self->isa('TAEB::World::Tile::Stairs')
         && $self->traverse_command eq $direction) {
            return $self->other_side;
        }
        else {
            my $error = sprintf "Tried to find the other side of %sstaircase",
                $self->isa('TAEB::World::Tile::Stairs')
                    ? "a non-" : "the wrong type of ";
            TAEB->log->level($error, level => 'error');
            return;
        }
    }

    my ($dx, $dy) = vi2delta($direction);
    $self->level->at($self->x + $dx, $self->y + $dy);
}

sub from_direction {
    my $self      = shift;
    my $direction = shift;

    return $self->at_direction('<') if $direction eq '>';
    return $self->at_direction('>') if $direction eq '<';

    my ($dx, $dy) = vi2delta($direction);
    my $from_direction = delta2vi(-$dx, -$dy);

    return $self->at_direction($from_direction);
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

