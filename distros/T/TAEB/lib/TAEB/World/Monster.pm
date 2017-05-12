package TAEB::World::Monster;
use TAEB::OO;
use TAEB::Util qw/:colors align2str/;
use List::Util qw/max min/;

use overload %TAEB::Meta::Overload::default;

has glyph => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has color => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has tile => (
    is       => 'ro',
    isa      => 'TAEB::World::Tile',
    weak_ref => 1,
    handles  => [qw/x y z level in_shop in_temple in_los distance/],
);

sub is_shk {
    my $self = shift;

    # if we've seen a nurse recently, then this monster is probably that nurse
    # we really need proper monster tracking! :)
    return 0 if TAEB->turn < (TAEB->last_seen_nurse || -100) + 3;

    return 0 unless $self->glyph eq '@' && $self->color eq COLOR_WHITE;

    # a shk isn't a shk if it's outside of its shop!
    # this also catches angry shks, but that's not too big of a deal
    return 0 unless $self->tile->type eq 'obscured'
                 || $self->tile->type eq 'floor';
    return $self->in_shop ? 1 : undef;
}

sub is_priest {
    my $self = shift;
    return 0 unless $self->glyph eq '@' && $self->color eq COLOR_WHITE;
    return ($self->in_temple ? 1 : undef);
}

sub is_oracle {
    my $self = shift;

    # we know the oracle level.. is it this one?
    if (my $oracle_level = TAEB->dungeon->special_level->{oracle}) {
        return 0 if $self->level != $oracle_level;
    }
    # if we don't know the oracle level, well, is this level in the right range?
    else {
        return 0 if $self->z < 5 || $self->z > 9;
    }

    return 0 unless $self->x == 39 && $self->y == 12;
    return 1 if TAEB->is_hallucinating
             || ($self->glyph eq '@' && $self->color eq COLOR_BRIGHT_BLUE);
    return 0;
}

sub is_vault_guard {
    my $self = shift;
    return 0 unless TAEB->following_vault_guard;
    return 1 if $self->glyph eq '@' && $self->color eq COLOR_BLUE;
    return 0;
}

sub is_quest_friendly {
    my $self = shift;

    # Attacking @s in quest level 1 will screw up your quest. So...don't.
    return 1 if $self->level->known_branch
             && $self->level->branch eq 'quest'
             && $self->z == 1
             && $self->glyph eq '@';
    return 0;
}

sub is_quest_nemesis {
    return 0; #XXX
}

sub is_enemy {
    my $self = shift;
    return 0 if $self->is_oracle;
    return 0 if $self->is_coaligned_unicorn;
    return 0 if $self->is_vault_guard;
    return 0 if $self->is_peaceful_watchman;
    return 0 if $self->is_quest_friendly;
    return 0 if $self->is_shk || $self->is_priest;
    return unless (defined $self->is_shk || defined $self->is_priest);
    return 1;
}

# Yes, this is different from is_enemy.  Enemies are monsters we should
# attack, hostiles are monsters we expect to attack us.  Even if they
# were perfect they'd be different, pick-wielding dwarves for instance.
#
# But they're not perfect, which makes the difference bigger.  If we
# decide to ignore the wrong monster, it will kill us, so is_enemy
# has to be liberal.  If we let a peaceful monster chase us, we'll
# starve, so is_hostile has to be conservative.

my %hate = ();

for (qw/HumGno OrcHum OrcElf OrcDwa/)
    { /(...)(...)/; $hate{$1}{$2} = $hate{$2}{$1} = 1; }

sub is_hostile {
    my $self = shift;

    # Otherwise, 1 if the monster is guaranteed hostile
    return 0 if !$self->spoiler;
    return 1 if $self->spoiler->{hostile};
    return 0 if $self->spoiler->{peaceful};
    return 0 if $self->is_quest_friendly;
    return 1 if $self->is_quest_nemesis;

    return 1 if $hate{TAEB->race}{$self->spoiler->{cannibal} || ''};

    return 1 if align2str $self->spoiler->{alignment} ne TAEB->align;

    # do you have the amulet? is it a minion?  is it cross-aligned?
    return;
}

sub probably_sleeping {
    my $self = shift;

    return 0 if TAEB->noisy_turn && TAEB->noisy_turn + 40 > TAEB->turn;
    return $self->glyph =~ /[ln]/ || TAEB->senses->is_stealthy;
}

# Would this monster chase us if it wanted to and noticed us?
sub would_chase {
    my $self = shift;

    # Unicorns won't step next to us anyway
    return 0 if $self->is_unicorn;

    # Leprechauns avoid the player once they have gold
    return 0 if $self->glyph eq 'l';

    # Monsters that can't move won't take initiative
    return 0 if !$self->can_move;

    return 1;
}

sub will_chase {
    my $self = shift;

    return $self->would_chase
        && $self->is_hostile
        && !$self->probably_sleeping;
}

sub is_meleeable {
    my $self = shift;

    return 0 unless $self->is_enemy;

    # floating eye (paralysis)
    return 0 if $self->color eq COLOR_BLUE
             && $self->glyph eq 'e'
             && !TAEB->is_blind;

    # blue jelly (cold)
    return 0 if $self->color eq COLOR_BLUE
             && $self->glyph eq 'j'
             && !TAEB->cold_resistant;

    # spotted jelly (acid)
    return 0 if $self->color eq COLOR_GREEN
             && $self->glyph eq 'j';

    # gelatinous cube (paralysis)
    return 0 if $self->color eq COLOR_CYAN
             && $self->glyph eq 'b'
             && $self->level->has_enemies > 1;

    return 1;
}

# Yes, I know the name is long, but I couldn't think of anything better.
#  -Sebbe.
sub is_seen_through_warning {
    my $self = shift;
    return $self->glyph =~ /[1-5]/;
}

sub is_sleepable {
    my $self = shift;
    return $self->is_meleeable;
}

sub respects_elbereth {
    my $self = shift;

    return 0 if $self->glyph =~ /[A@]/;
    return 0 if $self->is_minotaur;
    # return 0 if $self->is_rider;
    # return 0 if $self->is_blind && !$self->is_permanently_blind;

    return 1;
}

sub is_minotaur {
    my $self = shift;
    $self->glyph eq 'H' && $self->color eq COLOR_BROWN
}

sub is_nymph {
    my $self = shift;
    $self->glyph eq 'n';
}

sub is_unicorn {
    my $self = shift;
    return 0 if $self->glyph ne 'u';
    return 0 if $self->color eq COLOR_BROWN;

    # this is coded somewhat strangely to deal with black unicorns being
    # blue or dark gray
    if ($self->color eq COLOR_WHITE) {
        return 'Law';
    }

    if ($self->color eq COLOR_GRAY) {
        return 'Neu';
    }

    return 'Cha';
}

sub is_coaligned_unicorn {
    my $self = shift;
    my $uni = $self->is_unicorn;

    return $uni && $uni eq TAEB->align;
}

sub is_peaceful_watchman {
    my $self = shift;
    return 0 unless $self->level->is_minetown;
    return 0 if $self->level->angry_watch;
    return 0 unless $self->glyph eq '@';

    return $self->color eq COLOR_GRAY || $self->color eq COLOR_GREEN;
}

sub is_ghost {
    my $self = shift;

    return $self->glyph eq ' ' if $self->level->is_rogue;
    return $self->glyph eq 'X';
}

sub can_move {
    my $self = shift;

    # spotted jelly, blue jelly
    return 0 if $self->glyph eq 'j';

    # brown yellow green red mold
    return 0 if $self->glyph eq 'F';

    return 0 if $self->is_oracle;
    return 1;
}

sub debug_line {
    my $self = shift;
    my @bits;

    push @bits, sprintf '(%d,%d)', $self->x, $self->y;
    push @bits, 'g<' . $self->glyph . '>';
    push @bits, 'c<' . $self->color . '>';

    return join ' ', @bits;
}

=head2 spoiler :: hash

Returns the monster spoiler (L<TAEB::Spoiler::Monster>) entry for this thing,
or undef if the symbol does not uniquely determine the monster.

=cut

sub spoiler {
    my $self = shift;

    my %candidates = TAEB::Spoilers::Monster->search(
        glyph => $self->glyph,
        color => $self->color,
    );
    return values %candidates if wantarray;
    return if values %candidates > 1;
    return (values %candidates)[0];
}

=head2 can_be_outrun :: bool

Return true if the player can definitely outrun the monster.

=cut

sub can_be_outrun {
    my $self = shift;

    my $spoiler = $self->spoiler || return 0;
    my $spd = $spoiler->{speed};
    my ($pmin, $pmax) = TAEB->speed;

    return $spd < $pmin || ($spd == $pmin && $spd < $pmax);
}

=head2 can_be_infraseen :: Bool

Returns true if the player could see this monster using infravision.

=cut

sub can_be_infraseen {
    my $self = shift;

    return TAEB->has_infravision
        && $self->glyph !~ /[abceijmpstvwyDEFLMNPSWXZ';:~]/; # evil evil should be in T:M:S XXX
}

=head2 speed :: Int

Returns the (base for now) speed of this monster.  If we can't exactly
tell what it is, return the speed of the fastest possibility.

=cut

sub speed {
    max map { $_->{speed} } shift->spoiler;
}

sub _hitchance {
    # need to be above a 1dN
    my ($min_to_hit, $max_to_hit, $die_size) = @_;

    my $cases = $max_to_hit - $min_to_hit + 1;

    my $lowest_random  = max(2, $min_to_hit);
    my $highest_random = min($max_to_hit, $die_size - 1);

    my $random_cases = $highest_random - $lowest_random + 1;

    my $chance = 0;

    # no chance contribution from the auto miss range

    if ($lowest_random <= $highest_random) {
        my $avg_tohit = ($lowest_random + $highest_random) / 2;

        my $random_chance = ($avg_tohit - 1) / $die_size;

        $chance += $random_chance * $random_cases / $cases;
    }

    if ($max_to_hit > $highest_random) {
        my $min_unrandom = max($min_to_hit, $die_size);
        $chance += ($max_to_hit - $min_unrandom + 1) / $cases;
    }

    $chance;
}

sub _read_attack_string {
    my $spoil = shift;

    my $total_max = 0;
    my $total_avg = 0;

    # highest and lowest to-hit ('tmp' in mattacku) values, accounting
    # for AC rerolling
    my $min_to_hit = TAEB->ac + 10 + $spoil->{level};
    my $max_to_hit = TAEB->ac < 0 ? (9 + $spoil->{level}) : $min_to_hit;

    my $atk_index = 0;

    for my $token (split / /, $spoil->{attacks}) {
        $atk_index++;

        # Active attacks only
        next unless $token =~ /^(.??)([0-9]+)d([0-9]+)(.??)$/;

        # Ignore the attacks of yellow and black lights, since they do
        # _large_ amounts of damage that's actually a duration (10d20
        # and 10d12 respectively).
        next if $4 eq "b" || $4 eq "h";

        # Ignore non-melee
        next if $1 eq "M" || $1 eq "B" || $1 eq "G" || $1 eq "S";

        # Ignore attacks that the player has res to
        next if $4 eq "C" && TAEB->cold_resistant;
        next if $4 eq "F" && TAEB->fire_resistant;
        next if $4 eq "E" && TAEB->shock_resistant;

        my $hitch = _hitchance($min_to_hit, $max_to_hit, 20 + $atk_index - 1);

        $hitch = 1 if $1 eq "E";

        $total_max += $2 * $3;

        # Ballpark the AC reduction, getting it right seems not worth it

        my $damage = $2 * ($3 + 1) / 2;

        if (TAEB->ac < 0) {
            my $acreduce = - TAEB->ac / 2;

            $damage -= ($acreduce * $damage) / ($acreduce + $damage);
        }

        $total_avg += $hitch * $damage;
    }

    return ($total_avg, $total_max);
}

=head2 maximum_melee_damage :: Int

How much damage can this monster do in a single round of attacks if it
connects and does full damage with each hit?

=cut

sub maximum_melee_damage {
    max map { (_read_attack_string $_)[1] } shift->spoiler
}

=head2 average_melee_damage :: Int

How much damage can this monster do in a single round of attacks in
the average case, accounting for AC?

=cut

sub average_melee_damage {
    max map { (_read_attack_string $_)[0] } shift->spoiler
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

