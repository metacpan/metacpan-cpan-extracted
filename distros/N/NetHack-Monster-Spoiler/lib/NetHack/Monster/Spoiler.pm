package NetHack::Monster::Spoiler;
use Moose;
with 'MooseX::Role::Matcher' => { default_match => 'name' };
use YAML::Any qw(Load);
use MooseX::ClassAttribute;
use Moose::Util::TypeConstraints;

our $VERSION = '0.05';

=head1 NAME

NetHack::Monster::Spoiler - information on a type of monster

=head1 SYNOPSIS

    use NetHack::Monster::Spoiler;

    my $s = NetHack::Monster::Spoiler->lookup(glyph => 'A', color => 'magenta');

    $s->is_spellcaster;          # returns 'wizard'
    $s->name                     # 'Archon'
    $s->never_leaves_corpse      # 1
    $s->ignores_elbereth         # 1
    $s->resists('petrification') # 0

=head1 DESCRIPTION

NetHack::Monster::Spoiler is a machine-readable database of information
on the various monsters that inhabit the NetHack universe.  It is a sort
of metaclass of monsters; an instance of NetHack::Monster::Spoiler is
associated with each type of monster, so there is one for Archons, one
for black puddings, et cetera.  The C<lookup> class method allows one
to find the correct instance for an observed monster, from which general
information can be obtained using accessors.

=cut

class_has _list => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy       => 1,
    auto_deref => 1,
    default    => sub {
        local $/ = undef;
        my $data = <DATA>;
        close DATA;
        [ Load($data) ];
    }
);

class_has list => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy       => 1,
    auto_deref => 1,
    default    => sub {
        my $class = shift;

        [ map { $class->new(%$_) } $class->_list ];
    },
);

=head2 lookup %ARGS

C<lookup> is used to find instances of NetHack::Monster::Spoiler.  It takes
an optional named argument for each accessor, and returns only those monsters
that match the fields.  As a special exception, ANSI color numbers are
automatically translated into the correct NetHack colors.  Note that there
is no munging for name, so in general directly using the return from farlook
will do the wrong thing.

Returns all matches in list context; in scalar context it returns an unambiguous
result, or undef on failure or ambiguity.

=cut

sub lookup {
    my ($class, @props) = @_;

    my @cand = $class->grep_matches((scalar $class->list), @props);

    wantarray ? @cand : (@cand == 1 ? $cand[0] : undef );
}

=head2 PRIMITIVE ACCESSORS

The following primitive accessors are availiable.  Each of them corresponds to
one field in the NetHack monster structure, with three exceptions: all
breathless monsters get amphibious for free, mimics do not cling to the ceiling,
and dwarves do not eat rock.

The return values of C<resist> is a hashref which maps a truth value to each
resistance the monster possesses The return value of C<attacks> is an arrayref
of hashrefs which describe each of the monster's attack(s) in terms of mode,
type, and damage.

=over

=item absent_from_gehennom

=item ac

=item acidic_corpse

=item alignment

=item always_hostile

=item always_peaceful

=item attacks

=item can_eat_metal

=item can_eat_rock

=item can_fly

=item can_swim

=item cannot_pickup_items

=item clings_to_ceiling

=item color

=item corpse_nutrition

=item extra_nasty

=item follows_stair_users

=item food_makes_peaceful

=item gehennom_exclusive

=item glyph

=item has_infravision

=item has_proper_name

=item has_teleport_control

=item has_teleportitis

=item has_thick_hide

=item hides_on_ceiling

=item hides_under_item

=item hitdice

=item humanoid_body

=item ignores_walls

=item immobile_until_disturbed

=item immobile_until_seen

=item infravision_detectable

=item invalid_polymorph_target

=item is_always_female

=item is_always_male

=item is_amorphous

=item is_amphibious

=item is_animal

=item is_breathless

=item is_carnivorous

=item is_demon

=item is_dwarf

=item is_elf

=item is_genderless

=item is_genocidable

=item is_giant

=item is_gnome

=item is_herbivorous

=item is_human

=item is_lycanthrope

=item is_mercenary

=item is_mindless

=item is_minion

=item is_orc

=item is_rank_lord

=item is_rank_prince

=item is_undead

=item is_unique

=item is_very_strong

=item is_wanderer

=item lacks_eyes

=item lacks_hands

=item lacks_head

=item lacks_limbs

=item large_group

=item lays_eggs

=item made_of_gas

=item mr

=item name

=item never_drops_corpse

=item not_randomly_generated

=item poisonous_corpse

=item rarity

=item regenerates_quickly

=item resist

=item sees_invisible

=item serpentine_body

=item size

=item small_group

=item sound

=item speed

=item throws_boulders

=item tunnels_with_pick

=item wants_amulet

=item wants_bell

=item wants_book

=item wants_candelabrum

=item wants_gems

=item wants_gold

=item wants_magic_items

=item wants_quest_artifact

=item wants_wargear

=item weight

=back

=cut

has [qw/absent_from_gehennom acidic_corpse always_hostile always_peaceful
  can_eat_metal can_eat_rock can_fly can_swim cannot_pickup_items
  clings_to_ceiling extra_nasty follows_stair_users
  food_makes_peaceful gehennom_exclusive has_infravision has_proper_name
  has_teleport_control has_teleportitis has_thick_hide hides_on_ceiling
  hides_under_item humanoid_body ignores_walls immobile_until_disturbed
  immobile_until_seen infravision_detectable invalid_polymorph_target
  is_always_female is_always_male is_amorphous is_amphibious is_animal
  is_breathless is_carnivorous is_demon is_dwarf is_elf is_genderless
  is_genocidable is_giant is_gnome is_herbivorous is_human is_lycanthrope
  is_mercenary is_mindless is_minion is_orc is_rank_lord is_rank_prince
  is_undead is_unique is_very_strong is_wanderer lacks_eyes lacks_hands
  lacks_head lacks_limbs large_group lays_eggs made_of_gas never_drops_corpse
  not_randomly_generated poisonous_corpse regenerates_quickly sees_invisible
  serpentine_body small_group throws_boulders tunnels_with_pick wants_amulet
  wants_bell wants_book wants_candelabrum wants_gems wants_gold
  wants_magic_items wants_quest_artifact wants_wargear/] => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has [qw/weight speed rarity corpse_nutrition mr hitdice ac/] => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

has alignment => (
    is      => 'ro',
    isa     => 'Str'
);

enum 'NetHack::Monster::Size' => qw/tiny small medium large huge gigantic/;

has size => (
    is      => 'ro',
    isa     => 'NetHack::Monster::Size',
);

=head2 numeric_size :: Int

C<numeric_size> returns a number with the correct ordering properties for
the monster's size if called as a method, or translates strings into the
same set of numbers if called as a function.  The numbers used are the
same as NetHack's MZ_XXX defines.

=cut

my %numeric_sizes = qw/tiny 0 small 1 medium 2 large 3 huge 4 gigantic 7/;

sub numeric_size {
    my $thing = shift;

    $numeric_sizes{ ref $thing ? $thing->size : $thing };
}

has [qw/sound name glyph color/] => (
    is      => 'ro',
    isa     => 'Str',
);

has [qw/resist _corpse/] => (
    is      => 'ro',
    isa     => 'HashRef',
);

has attacks => (
    is      => 'ro',
    isa     => 'ArrayRef',
);

=head2 is_rider

Returns true if the monster is one of the three Riders of the Astral
Plane^W^WApocalypse.

=cut

sub is_rider {
    my $self = shift;

    return $self->name =~ /Death|Pestilence|Famine/ ? 1 : 0;
}

=head2 ignores_elbereth

Returns true if the monster will always ignore Elbereth.  Peacefuls, blind
monsters, and monsters with special AIs will ignore regardless.

=cut

sub ignores_elbereth {
    my $self = shift;

    return 1 if $self->glyph =~ /[A@]/;
    return 1 if $self->name eq 'minotaur';
    return 1 if $self->is_rider;
    return 0;
}

=head2 has_attack MODE

Return true if the monster has an attack of the specified mode or type.

=cut

sub has_attack {
    my ($self, $mode) = @_;

    my @atk = grep { defined $mode
                   ? ($_->{mode} eq $mode || $_->{type} eq $mode)
                   : 1 } @{$self->attacks};

    return @atk ? $atk[0] : undef;
}

=head2 is_spellcaster

Return undef if the monster is not a spellcaster.  Otherwise return the type
of magic used.

=cut

sub is_spellcaster {
    my $cast = shift->has_attack('magic');

    return $cast ? $cast->{type} : undef;
}

my %elements = qw(petrification stone  stoning stone  electricity elec
    shock elec  disintegration disint);

=head2 resists ELEMENT

Return true if the monster resists the provided element.  Supported elements
are fire, cold, elec, electricity, acid, petrification, stoning, stone, shock,
disintegration, disint, sleep, and poison.

=cut

sub resists {
    my ($self, $element) = @_;

    $element = $elements{$element} || $element;

    return $self->resist->{$element} || 0;
}

=head2 can_float

Return true if the monster is capable of levitation, if not flight.

=cut

sub can_float {
    my ($self) = @_;

    return $self->glyph eq 'e';
}

=head2 is_noncorporeal

Return true if the monster is non-corporeal (a ghost or shade).

=cut

sub is_noncorporeal {
    my ($self) = @_;

    return $self->name =~ /shade|ghost/;
}

=head2 is_whirly

Return true if the monster is made of whirls of gas, and for instance can be
disrupted with slowing.

=cut

sub is_whirly {
    my ($self) = @_;

    return $self->glyph eq 'v' || $self->name eq 'air elemental';
}

=head2 is_flaming

Return true if the monster is already on fire and cannot be ignited further.

=cut

sub is_flaming {
    my ($self) = @_;

    return $self->name =~ /fire (?:vortex|elemental)|flaming sphere|salamander/;
}

=head2 is_telepathic

Return true if the monster is intrinsically telepathic.

=cut

sub is_telepathic {
    my ($self) = @_;

    return $self->name =~ /floating eye|mind flayer/;
}

=head2 uses_weapons

Return true if the monster uses weapons in the wild.  If you are polymorphed,
you want could_wield, not this.

=cut

sub uses_weapons {
    return defined shift->has_attack('weapon');
}

=head2 is_unicorn

Return true (specifically, the 3-letter code for the unicorn's alignment) if
this monster is a unicorn.

=cut

sub is_unicorn {
    my ($self) = @_;

    return undef if $self->glyph ne 'u';

    return 'Law' if $self->color eq 'white';
    return 'Neu' if $self->color eq 'gray';
    return 'Cha' if $self->color eq 'black';

    return undef;
}

=head2 is_bat

Return true if the current monster is a true bat, not a bird.

=cut

sub is_bat {
    return shift->name =~ /^(vampire |giant |)bat$/;
}

=head2 is_golem

Return true for golems.

=cut

sub is_golem {
    return shift->glyph eq "'";
}

=head2 is_verysmall

Return true if this monster is very small (can pass between bars, etc).

=cut

sub is_verysmall {
    return shift->size eq 'tiny';
}

=head2 is_bigmonst

Return true if this monster is quite large (cannot fit through crevice, etc).

=cut

sub is_bigmonst {
    return shift->numeric_size >= numeric_size('large');
}

=head2 could_wield

Return true if this monster is capable of using weapons.  For whether it will
use weapons in the wild, see uses_weapons.

=cut

sub could_wield {
    my ($self) = @_;

    return !$self->lacks_hands && !$self->is_verysmall;
}

=head2 could_wear_armor

Return true if the current monster is capable of wearing armor.  Note that
animals, mindless monsters, and monsters which do not wants_wargear will
not actually ever wear anything.

=cut

sub could_wear_armor {
    my ($self) = @_;

    return !$self->would_break_armor && !$self->would_slip_armor;
}

=head2 can_dualwield

Return true if the player can dualwield while polymorphed into this.

=cut

sub can_dualwield {
    my ($self) = @_;

    # Yes, this is the NetHack check!
    return @{$self->attacks} >= 2 && $self->attacks->[1]->{mode} eq 'weapon';
}

=head2 is_normal_demon

Return true if this is a non-unique true demon.

=cut

sub is_normal_demon {
    my ($self) = @_;

    return $self->is_demon && !$self->is_rank_lord && !$self->is_rank_prince;
}

=head2 is_demon_prince

Return true if this is a demon prince.

=cut

sub is_demon_prince {
    my ($self) = @_;

    return $self->is_demon && $self->is_rank_prince;
}

=head2 is_demon_lord

Return true if this is a demon lord.

=cut

sub is_demon_lord {
    my ($self) = @_;

    return $self->is_demon && $self->is_rank_lord;
}

=head2 makes_webs

Returns true if this monster is capable of spinning webs.

=cut

sub makes_webs {
    return shift->name =~ /^(cave|giant) spider$/;
}

=head2 can_breathe

Returns true if this monster has a breath weapon.

=cut

sub can_breathe {
    return defined shift->has_attack('breathe');
}

# is_longworm omitted

=head2 is_player_monster

Return true if this is a role monster (valkyrie, etc).

=cut

sub is_player_monster {
    my ($self) = @_;

    return $self->hitdice == 10 && $self->glyph eq '@' &&
        $self->color eq 'white' && $self->name ne 'elf';
}

=head2 is_covetous

Returns true if this uses the covetous AI extension (teleporting to stairs,
you, picking up invocation items; does B<not> imply a theft attack).

=cut

sub is_covetous {
    my ($self) = @_;

    return $self->wants_amulet || $self->wants_book || $self->wants_bell ||
        $self->wants_candelabrum || $self->wants_quest_artifact;
}

# reviver omitted: NHI

=head2 emits_light

Return true if this monster is always surrounded by a 1-square lit region.

=cut

sub emits_light {
    my ($self) = @_;

    return $self->glyph eq 'y' || $self->name =~
        /^(?:(?:flam|shock)ing sphere|fire (?:vortex|elemental))$/;
}

=head2 likes_lava

Return true if this monster suffers no penalties in lava.

=cut

sub likes_lava {
    my ($self) = @_;

    return $self->name eq 'salamander' || $self->name eq 'fire elemental';
}

=head2 naturally_invisible

Return true if this monster is automatically invisible.

=cut

sub naturally_invisible {
    my ($self) = @_;

    return $self->name eq 'stalker' || $self->name eq 'black light';
}

=head2 likes_fire

Return true if this monster is not penalized by fire.

=cut

sub likes_fire {
    shift->is_flaming;
}

=head2 touch_petrifies

Return true for monsters whose flesh is fatal on contact petrification.

=cut

sub touch_petrifies {
    shift->name =~ /^c(?:o|hi)ckatrice$/;
}

=head2 is_mind_flayer

Can this monster use mental blasts?

=cut

sub is_mind_flayer {
    shift->name =~ /mind flayer/;
}

=head2 is_nonliving

Return true if this monster is not considered alive.

=cut

sub is_nonliving {
    my ($self) = @_;

    return $self->name eq 'manes' || $self->is_undead || $self->glyph eq 'v' ||
        $self->is_golem;
}

# attacktype_fordmg omitted, dead code in NH

# polymorphs_when_stoned omitted, requires geno data

=head2 resists_drain_life

Return true if this monster intrinsically cannot be life drained.

=cut

sub resists_drain_life {
    my ($self) = @_;

    return $self->is_lycanthrope || $self->is_undead || $self->is_demon ||
       $self->name eq 'Death';
}

=head2 resists_magic

Return true if this monster has the C<magic resistance> special property,
giving it immunity to several special attacks.  This is distinct from the 
mr accessor, which is a percentage save against a much wider range of attacks.

=cut

sub resists_magic {
    my ($self) = @_;

    return $self->name =~ /gray dragon|Yeenoghu|Oracle|Angel|Chromatic Dragon/;
}

=head2 resists_blinding

Return true if this monster intrinsically cannot be blinded.

=cut

sub resists_blinding {
    my ($self) = @_;

    return $self->lacks_eyes || $self->name =~ /yellow light|Archon/;
}

# can_blind omitted, depends too much on mon data

# could_range_attack omitted - probably useless without has-ammo tracking

=head2 is_vulnerable_to_silver

Return true if this monster takes d20 bonus damage from silver attacks.

=cut

sub is_vulnerable_to_silver {
    my ($self) = @_;

    return 0 if $self->name eq 'tengu';
    return $self->glyph =~ /[iV]/ || $self->is_lycanthrope || $self->is_demon
        || $self->name eq 'shade';
}

=head2 ignores_bars

Return true if this monster can walk through, between, or around iron bars.

=cut

sub ignores_bars {
    my ($self) = @_;

    return $self->ignores_walls || $self->is_amorphous || $self->is_whirly ||
        $self->is_verysmall || ($self->serpentine_body && !$self->is_bigmonst);
}

=head2 would_slip_armor

Return true if body armor would always fall off this monster.

=cut

sub would_slip_armor {
    my ($self) = @_;

    return $self->is_whirly || $self->is_noncorporeal || $self->numeric_size <=
        numeric_size('small');
}

=head2 would_break_armor

Return true if any armor worn by this monster would break.

=cut

sub would_break_armor {
    my ($self) = @_;

    return 0 if $self->would_slip_armor;

    return !$self->humanoid_body || $self->is_bigmonst
        || $self->name eq 'marilith' || $self->name eq 'winged gargoyle';
}

=head2 can_stick

Return true if this monster has an adhesion/grabbing attack, and is immune to
such attacks.

=cut

sub can_stick {
    my ($self) = @_;

    return scalar grep { $_->{mode} eq 'crush' || $_->{type} eq 'stick'
        || $_->{type} eq 'wrap' } @{ $self->attacks };
}

=head2 has_horns

Return true if this monster has one or more horns preventing the use of helmets.

=cut

sub has_horns {
    shift->name =~ /horned devil|minotaur|Asmodeus|balrog|ki-rin|unicorn/;
}

=head2 vegan

Return true if eating this monster or its corpse won't break vegan conduct.

=cut

sub vegan {
    my $self = shift;
    return 0 if $self->name eq 'stalker'
             || $self->name eq 'leather golem'
             || $self->name eq 'flesh golem';
    return 1 if $self->glyph =~ /[bjFvyE'X]/;
    return 0;
}

=head2 vegetarian

Return true if eating this monster or its corpse won't break vegetarian conduct.

=cut

sub vegetarian {
    my $self = shift;
    return 1 if $self->vegan;
    return 0 if $self->name eq 'black pudding';
    return 1 if $self->glyph eq 'P';
    return 0;
}

=head2 corpse

Returns a hashref with all effects that eating a corpse will provide.

=cut

sub corpse {
    my $self = shift;

    my $corpse_type = $self->corpse_type;
    my $name = $corpse_type->name;
    my $glyph = $corpse_type->glyph;

    my %corpse_data;

    # initial effects (cprefx)
    # XXX: should we mark these separately?
    return { die => 1 }
        if $corpse_type->is_rider;
    $corpse_data{acidic} = 1
        if $corpse_type->acidic_corpse;
    $corpse_data{poisonous} = 1
        if $corpse_type->poisonous_corpse;
    $corpse_data{petrify} = 1
        if $corpse_type->touch_petrifies || $name eq 'Medusa';
    $corpse_data{aggravate} = 1
        if $name =~ /(?:dog|cat|kitten)$/;
    $corpse_data{cure_stone} = 1
        if ($name eq 'lizard') || $corpse_type->acidic_corpse;
    $corpse_data{slime} = 1
        if $name eq 'green slime';
    $corpse_data{cannibal} = 'Hum'
        if $corpse_type->is_human;
    $corpse_data{cannibal} = 'Dwa'
        if $corpse_type->is_dwarf;
    $corpse_data{cannibal} = 'Elf'
        if $corpse_type->is_elf;
    $corpse_data{cannibal} = 'Gno'
        if $corpse_type->is_gnome;

    # final effects (cpostfx)
    if ($name eq 'newt') {
        $corpse_data{energy} = 1;
    }
    elsif ($name eq 'wraith') {
        $corpse_data{gain_level} = 1;
    }
    elsif ($name =~ /^were/) {
        $corpse_data{lycanthropy} = 1;
    }
    elsif ($name eq 'nurse') {
        $corpse_data{heal} = 1;
    }
    elsif ($name eq 'stalker') {
        $corpse_data{invisibility} = 1;
        $corpse_data{see_invisible} = 1; # XXX ?
        $corpse_data{stun} = 60;
    }
    elsif ($name eq 'yellow light') {
        $corpse_data{stun} = 60;
    }
    elsif ($name eq 'giant bat') {
        $corpse_data{stun} = 60;
    }
    elsif ($name eq 'bat') {
        $corpse_data{stun} = 30;
    }
    elsif ($glyph eq 'm') {
        $corpse_data{mimic} = $name =~ /giant/ ? 50
                            : $name =~ /large/ ? 40
                            :                    20;
    }
    elsif ($name eq 'quantum mechanic') {
        $corpse_data{speed_toggle} = 1;
    }
    elsif ($name eq 'lizard') {
        $corpse_data{less_confused} = 2;
        $corpse_data{less_stunned} = 2;
    }
    elsif ($name eq 'chameleon' || $name eq 'doppelganger') {
        $corpse_data{polymorph} = 1;
    }
    elsif ($corpse_type->is_mind_flayer) {
        $corpse_data{intelligence} = 1;
        $corpse_data{telepathy} = 1;
    }
    else {
        if ($corpse_type->has_attack('stun')
         || $corpse_type->has_attack('hallucination')
         || $name eq 'violet fungus') {
            $corpse_data{hallucination} = 200;
        }
        if ($corpse_type->is_giant) {
            $corpse_data{strength} = 1;
        }

        my %trans = (shock => 'elec', disintegration => 'disint');
        for my $resist (qw/fire sleep cold disintegration shock poison/) {
            my $trans_resist = $trans{$resist} || $resist;
            $corpse_data{"${resist}_resistance"} = 1
                if exists $corpse_type->_corpse->{$trans_resist};
        }
        $corpse_data{teleportitis} = 1
            if $corpse_type->has_teleportitis;
        $corpse_data{teleport_control} = 1
            if $corpse_type->has_teleport_control;
        $corpse_data{telepathy} = 1
            if $corpse_type->is_telepathic;
    }

    return \%corpse_data;
}

=head2 corpse_type

Returns the monster corresponding to the type of corpse that a monster will
leave (i.e. vampires leave human corpses).

=cut

sub corpse_type {
    my $self = shift;
    my $type;
    if ($self->glyph eq 'Z') {
        ($type = $self->name) =~ s/ zombie//;
    }
    elsif ($self->glyph eq 'M') {
        ($type = $self->name) =~ s/ mummy//;
    }
    elsif ($self->glyph eq 'V') {
        $type = 'human';
    }
    return $self->lookup(name => $type) if $type;
    return $self;
}

=head2 corpse_reanimates

Return true if the corpse will reanimate after sitting on the floor for a
while.

=cut

sub corpse_reanimates {
    my $self = shift;
    return $self->glyph eq 'T';
}

=head2 parse_description $name

Attempt to decypher a monster description returned by NetHack. The return
value is a hashref of information about the monster which could be obtained
from the string:

=over

=item B<name> Monster's (C)alled name, or shopkeeper name.

=item B<god> Monster's god of minionhood.

=item B<priest> Monster is a priest.

=item B<renegade> Monster is a renegade priest.

=item B<high_priest> Monster is a high priest.

=item B<tame> Monster is tame.

=item B<invisible> Monster is invisible.

=item B<saddled> Monster is saddled.

=back

If an item is undef, the field cannot be determined from the information given.

=cut

my %roledata = (
    Archeologist => [ ["Quetzalcoatl", "Camaxtli", "Huhetotl"],
        ["Digger", "Field Worker", "Investigator", "Exhumer", "Excavator",
         "Spelunker", "Speleologist", "Collector", "Curator"] ],
    Barbarian    => [ ["Mitra", "Crom", "Set"],
        ["Plunderer", "Plunderess", "Pillager", "Bandit", "Brigand", "Raider",
         "Reaver", "Slayer", "Chieftain", "Chieftainess", "Conqueror",
         "Conqueress"] ],
    Caveman      => [ ["Anu", "_Ishtar", "Anshar"],
        ["Cavewoman", "Troglodyte", "Aborigine", "Wanderer", "Vagrant",
         "Wayfarer", "Roamer", "Nomad", "Rover", "Pioneer"] ],
    Healer       => [ ["_Athena", "Hermes", "Poseidon"],
        ["Rhizotomist", "Empiric", "Embalmer", "Dresser", "Medicus ossium",
         "Medica ossium", "Herbalist", "Magister", "Magistra", "Physician",
         "Chirurgeon"] ],
    Knight       => [ ["Lugh", "_Brigit", "Manannan Mac Lir"],
        ["Gallant", "Esquire", "Bachelor", "Sergeant", "Knight", "Banneret",
         "Chevalier", "Chevaliere", "Seignieur", "Dame", "Paladin"] ],
    Monk         => [ ["Shan Lai Ching", "Chih Sung-tzu", "Huan Ti"],
        ["Candidate", "Novice", "Initiate", "Student of Stones",
         "Student of Waters", "Student of Metals", "Student of Winds",
         "Student of Fire", "Master"] ],
    Priest       => [ ["Matriarch", "High Priest", "High Priestess"],
        ["Priestess", "Aspirant", "Acolyte", "Adept", "Priest", "Priestess",
         "Curate", "Canon", "Canoness", "Lama", "Patriarch"] ],
    Rogue        => [ ["Issek", "Mog", "Kos"],
        ["Footpad", "Cutpurse", "Rogue", "Pilferer", "Robber", "Burglar",
         "Filcher", "Magsman", "Magswoman", "Thief"] ],
    Ranger       => [ ["Hiril", "Aredhel", "Arwen"],
        ["Edhel", "Elleth", "Edhel", "Elleth", "Ohtar", "Ohtie", "Kano",
         "Kanie", "Arandur", "Aranduriel", "Hir"] ],
    Samurai      => [ ["_Amaterasu Omikami", "Raijin", "Susanowo"],
        ["Hatamoto", "Ronin", "Ninja", "Kunoichi", "Joshu", "Ryoshu",
         "Kokushu", "Daimyo", "Kuge", "Shogun"] ],
    Tourist      => [ ["Blind Io", "_The Lady", "Offler"],
        ["Rambler", "Sightseer", "Excursionist", "Peregrinator",
         "Peregrinatrix", "Traveler", "Journeyer", "Voyager", "Explorer",
         "Adventurer"] ],
    Valkyrie     => [ ["Tyr", "Odin", "Loki"],
        ["Stripling", "Skirmisher", "Fighter", "Man-at-arms", "Woman-at-arms",
         "Warrior", "Swashbuckler", "Hero", "Heroine", "Champion", "Lord",
         "Lady"] ],
    Wizard       => [ ["Ptah", "Thoth", "Anhur"],
        ["Evoker", "Conjurer", "Thaumaturge", "Magician", "Enchanter",
         "Enchantress", "Sorcerer", "Sorceress", "Necromancer", "Wizard",
         "Mage"] ],
);

my %valid_god = map { if (/_(.*)/) { $_ = $1; } $_ => 1 }
    'Moloch', map { @{ $_->[0] } } values %roledata;
my %rank2mon = map { my $k = $_; map { lc $_, lc $k } @{$roledata{$k}->[1]} }
    keys %roledata;

my %shkname = map { $_ => 1 } "Abisko", "Abitibi", "Adjama", "Akalapi",
    "Akhalataki", "Aklavik", "Akranes", "Aksaray", "Akureyri", "Alaca", "Aned",
    "Angmagssalik", "Annootok", "Ardjawinangun", "Artvin", "Asidonhopo",
    "Avasaksa", "Ayancik", "Babadag", "Baliga", "Ballingeary", "Balya",
    "Bandjar", "Banjoewangi", "Bayburt", "Beddgelert", "Beinn a Ghlo",
    "Berbek", "Berhala", "Bicaz", "Birecik", "Bnowr Falr", "Bojolali",
    "Bordeyri", "Boyabai", "Braemar", "Brienz", "Brig", "Brzeg", "Budereyri",
    "Burglen", "Caergybi", "Cahersiveen", "Cannich", "Carignan", "Cazelon",
    "Chibougamau", "Chicoutimi", "Cire Htims", "Clonegal", "Corignac", "Corsh",
    "Cubask", "Culdaff", "Curig", "Demirci", "Dirk", "Djasinga", "Djombang",
    "Dobrinishte", "Donmyar", "Dorohoi", "Droichead Atha", "Drumnadrochit",
    "Dunfanaghy", "Dunvegan", "Eauze", "Echourgnac", "Eed-morra", "Eforie",
    "Ekim-p", "Elm", "Enniscorthy", "Ennistymon", "Enontekis", "Enrobwem",
    "Ermenak", "Erreip", "Ettaw-noj", "Evad'kh", "Eygurande", "Eymoutiers",
    "Eypau", "Falo", "Fauske", "Fenouilledes", "Fetesti", "Feyfer", "Fleac",
    "Flims", "Flugi", "Gairloch", "Gaziantep", "Gellivare", "Gheel",
    "Glenbeigh", "Gliwice", "Gomel", "Gorlowka", "Guizengeard", "Gweebarra",
    "Haparanda", "Haskovo", "Havic", "Haynin", "Hebiwerie", "Hoboken",
    "Holmavik", "Hradec Kralove", "Htargcm", "Hyeghu", "Imbyze", "Inishbofin",
    "Inniscrone", "Inuvik", "Inverurie", "Iskenderun", "Ivrajimsal", "Izchak",
    "Jiu", "Jonzac", "Jumilhac", "Juyn", "Kabalebo", "Kachzi Rellim",
    "Kadirli", "Kahztiy", "Kajaani", "Kalecik", "Kanturk", "Karangkobar",
    "Kars", "Kautekeino", "Kediri", "Kerloch", "Kesh", "Kilgarvan", "Kilmihil",
    "Kiltamagh", "Kinnegad", "Kinojevis", "Kinsky", "Kipawa", "Kirikkale",
    "Kirklareli", "Kittamagh", "Kivenhoug", "Klodzko", "Konosja", "Kopasker",
    "Krnov", "Kyleakin", "Kyzyl", "Labouheyre", "Laguiolet", "Lahinch", "Lapu",
    "Lechaim", "Lerignac", "Leuk", "Lexa", "Lez-tneg", "Liorac", "Lisnaskea",
    "Llandrindod", "Llanerchymedd", "Llanfair-ym-muallt", "Llanrwst",
    "Lochnagar", "Lom", "Lonzac", "Lovech", "Lucrezia", "Ludus",
    "Lugnaquillia", "Lulea", "Maesteg", "Maganasipi", "Makharadze", "Makin",
    "Malasgirt", "Malazgirt", "Mallwyd", "Mamaia", "Manlobbi", "Massis",
    "Matagami", "Matray", "Melac", "Midyat", "Monbazillac", "Morven", "Moy",
    "Mron", "Mured-oog", "Nairn", "Nallihan", "Narodnaja", "Nehoiasu",
    "Nehpets", "Nenagh", "Nenilukah", "Neuvicq", "Ngebel", "Nhoj-lee", "Nieb",
    "Niknar", "Niod", "Nisipitu", "Niskal", "Nivram", "Njalindoeng", "Njezjin",
    "Nosalnef", "Nosid-da'r", "Noskcirdneh", "Noslo", "Nosnehpets", "Oeloe",
    "Olycan", "Oryahovo", "Ossipewsk", "Ouiatchouane", "Pakka Pakka",
    "Pameunpeuk", "Panagyuritshte", "Papar", "Parbalingga", "Pasawahan",
    "Patjitan", "Pemboeang", "Pengalengan", "Pernik", "Pervari", "Picq",
    "Polatli", "Pons", "Pontarfynach", "Possogroenoe", "Queyssac", "Raciborz",
    "Rastegaisa", "Rath Luirc", "Razboieni", "Rebrol-nek", "Regien", "Rellenk",
    "Renrut", "Rewuorb", "Rhaeader", "Rhydaman", "Rouffiac", "Rovaniemi",
    "Sablja", "Sadelin", "Samoe", "Sarangan", "Sarnen", "Saujon", "Schuls",
    "Semai", "Sgurr na Ciche", "Siboga", "Sighisoara", "Siirt", "Silistra",
    "Sipaliwini", "Siverek", "Skibbereen", "Slanic", "Sliven", "Smolyan",
    "Sneem", "Snivek", "Sperc", "Stewe", "Storr", "Svaving", "Swidnica",
    "Syktywkar", "Tapper", "Tefenni", "Tegal", "Telloc Cyaj", "Terwen", "Thun",
    "Tipor", "Tirebolu", "Tirgu Neamt", "Tjibarusa", "Tjisolok", "Tjiwidej",
    "Tonbar", "Touverac", "Trahnil", "Trallwng", "Trenggalek", "Tringanoe",
    "Troyan", "Tsew-mot", "Tsjernigof", "Tuktoyaktuk", "Tulovo", "Turriff",
    "Uist", "Upernavik", "Urignac", "Vals", "Vanzac", "Varjag Njarga",
    "Varvara", "Vaslui", "Vergt", "Voulgezac", "Walbrzych", "Weliki Oestjoeg",
    "Wirix", "Wonotobo", "Y-Fenni", "Y-crad", "Yad", "Yao-hang", "Yawolloh",
    "Ydna-s", "Yelpur", "Yildizeli", "Yl-rednow", "Ymla", "Ypey",
    "Yr Wyddgrug", "Ytnu-haled", "Zarnesti", "Zimnicea", "Zlatna", "Zonguldak",
    "Zum Loch";

sub parse_description {
    my ($class, $s) = @_;

    my %r;

    # case #1, It.

    if ($s =~ /^[iI]t$/) {
        return \%r;
    }

    my $article = '';

    $article = 'the'    if $s =~ s/^the //i;
    $article = 'a'      if $s =~ s/^an? //i;
    $article = 'your'   if $s =~ s/^your //i;

    # Avoid ambiguity caused by user-provided names whenever possible.
    my $g_or_c = $s =~ /ghost|called/;

    # case #2, priests and minions.  These are identified by of... except
    # in a couple situations.  If someone names a pet with 'of God' in it, they
    # get what they deserve...  be careful with monk titles.

    # special case #2.1 for Astral obfuscation
    if ($s =~ /^(?:the )?high priest(?:ess)?$/) {
        $r{priest} = 1;
        $r{high_priest} = 1;
        $r{monster} = 'high priest';
        return \%r;
    }

    if ($s !~ /Minion of Huhetotl/ && $s =~ /(.*) of (.*)/ && $valid_god{$2}
            && !$g_or_c) {

        $r{god} = $2;
        $s = $1;

        $s =~ s/^the //i;
        $r{invisible} = 1   if $s =~ s/^invisible //i;

        if ($s =~ s/(?:poobah|priest|priestess)$//i) {
            $r{priest} = 1;

            $r{high_priest} = 1 if $s =~ s/high $//i;
            $r{renegade} = 1    if $s =~ s/renegade $//i;

            # If anything's left, it's a monster.

            $s =~ s/ $//;

            $r{monster} = $s || ($r{high_priest} ?
                'high priest' : 'aligned priest');
        } else {
            $r{tame} = 1        if $s =~ s/^guardian //;

            $r{monster} = $s;
        }

        return \%r;
    }

    # case #3: things with internal the: polymorphed shopkeepers, invisible
    # shopkeepers, mplayers.  The same comments about pets apply.

    if ($s !~ /Neferet the Green/ && $s !~ /Vlad the Impaler/ &&
            $s =~ /(.*) the (.*)/ && !$g_or_c) {
        $r{name} = $1;
        $s = $2;
    }

    # case #4: things that have 'called'

    if ($s =~ /(.*?) called (.*)/) {
        $r{name} = $2;
        $s = $1;
    }

    $r{invisible} = 1       if $s =~ s/invisible //i;
    $r{saddled} = 1         if $s =~ s/saddled //i;

    # case #5: ghosts

    if ($s =~ /(.*?)'?s? ghost/) {
        $r{name} = $1;
        $r{monster} = 'ghost';
        return \%r;
    }

    # case #6: mplayers (name was stripped above)

    if ($r{monster} = $rank2mon{lc $s}) {
        return \%r;
    }

    # case #7: normal monsters

    $s =~ s/coyote - .*/coyote/;

    if ($class->lookup(name => $s)) {
        $r{monster} = $s;

        return \%r;
    }

    $r{name} = $s;

    if ($shkname{$s}) {
        $r{monster} = 'shopkeeper';
    }

    return \%r;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=head1 AUTHOR

Stefan O'Rear, C<< <stefanor@cox.net> >>

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-nethack-monster at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NetHack-Monster>.

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Stefan O'Rear.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<NetHack::Item>, L<MooseX::Role::Matcher>

=cut

__DATA__
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: physical
color: brown
corpse_nutrition: 10
glyph: a
hitdice: 2
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: giant ant
rarity: 3
resist: {}
size: tiny
small_group: 1
sound: silent
speed: 18
weight: 10
---
_corpse:
  poison: 1
ac: -1
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: sting
    type: poison
can_fly: 1
color: yellow
corpse_nutrition: 5
glyph: a
hitdice: 1
is_always_female: 1
is_animal: 1
is_genocidable: 1
lacks_hands: 1
large_group: 1
mr: 0
name: killer bee
poisonous_corpse: 1
rarity: 2
resist:
  poison: 1
size: tiny
sound: buzz
speed: 18
weight: 1
---
_corpse:
  poison: 1
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d4
    mode: bite
    type: physical
  - damage: 3d4
    mode: sting
    type: poison
color: blue
corpse_nutrition: 5
glyph: a
hitdice: 3
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: soldier ant
poisonous_corpse: 1
rarity: 2
resist:
  poison: 1
size: tiny
small_group: 1
sound: silent
speed: 18
weight: 20
---
_corpse:
  fire: 1
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d4
    mode: bite
    type: physical
  - damage: 2d4
    mode: bite
    type: fire
color: red
corpse_nutrition: 10
glyph: a
hitdice: 3
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
lays_eggs: 1
mr: 10
name: fire ant
rarity: 1
resist:
  fire: 1
size: tiny
small_group: 1
sound: silent
speed: 18
weight: 30
---
_corpse:
  poison: 1
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d6
    mode: bite
    type: physical
color: black
corpse_nutrition: 10
glyph: a
hitdice: 5
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: giant beetle
poisonous_corpse: 1
rarity: 3
resist:
  poison: 1
size: large
sound: silent
speed: 6
weight: 10
---
_corpse:
  poison: 1
ac: -4
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d8
    mode: sting
    type: poison
can_fly: 1
color: magenta
corpse_nutrition: 5
glyph: a
hitdice: 9
is_always_female: 1
is_animal: 1
is_genocidable: 1
is_rank_prince: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: queen bee
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  poison: 1
size: tiny
sound: buzz
speed: 24
weight: 1
---
_corpse:
  stone: 1
ac: 8
acidic_corpse: 1
alignment: 0
attacks:
  - damage: 1d8
    mode: passive
    type: acid
color: green
corpse_nutrition: 10
glyph: b
hitdice: 1
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
is_wanderer: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: acid blob
rarity: 2
resist:
  acid: 1
  poison: 1
  sleep: 1
  stone: 1
size: tiny
sound: silent
speed: 3
weight: 30
---
_corpse:
  poison: 1
ac: 8
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d8
    mode: touch
    type: physical
color: white
corpse_nutrition: 100
glyph: b
hitdice: 5
is_genderless: 1
is_genocidable: 1
is_mindless: 1
is_wanderer: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: quivering blob
rarity: 2
resist:
  poison: 1
  sleep: 1
size: small
sound: silent
speed: 1
weight: 200
---
_corpse:
  cold: 1
  elec: 1
  fire: 1
  sleep: 1
ac: 8
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d4
    mode: touch
    type: paralyze
  - damage: 1d4
    mode: passive
    type: paralyze
color: cyan
corpse_nutrition: 150
glyph: b
hitdice: 6
is_carnivorous: 1
is_genderless: 1
is_genocidable: 1
is_herbivorous: 1
is_mindless: 1
is_wanderer: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: gelatinous cube
rarity: 2
resist:
  acid: 1
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
size: large
sound: silent
speed: 6
weight: 600
---
_corpse:
  poison: 1
  stone: 1
ac: 8
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d2
    mode: bite
    type: physical
  - damage: 0d0
    mode: touch
    type: petrify
  - damage: 0d0
    mode: passive
    type: petrify
color: brown
corpse_nutrition: 10
glyph: c
hitdice: 4
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
lacks_hands: 1
mr: 30
name: chickatrice
rarity: 1
resist:
  poison: 1
  stone: 1
size: tiny
small_group: 1
sound: hiss
speed: 4
weight: 10
---
_corpse:
  poison: 1
  stone: 1
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: bite
    type: physical
  - damage: 0d0
    mode: touch
    type: petrify
  - damage: 0d0
    mode: passive
    type: petrify
color: yellow
corpse_nutrition: 30
glyph: c
hitdice: 5
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
lacks_hands: 1
lays_eggs: 1
mr: 30
name: cockatrice
rarity: 5
resist:
  poison: 1
  stone: 1
size: small
sound: hiss
speed: 6
weight: 30
---
_corpse:
  fire: 1
  poison: 1
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: gaze
    type: fire
color: red
corpse_nutrition: 30
glyph: c
hitdice: 6
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
lacks_hands: 1
lays_eggs: 1
mr: 30
name: pyrolisk
rarity: 1
resist:
  fire: 1
  poison: 1
size: small
sound: hiss
speed: 6
weight: 30
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d2
    mode: bite
    type: physical
color: brown
corpse_nutrition: 250
glyph: d
hitdice: 0
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: jackal
rarity: 3
resist: {}
size: small
small_group: 1
sound: bark
speed: 12
weight: 300
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: bite
    type: physical
color: red
corpse_nutrition: 250
glyph: d
hitdice: 0
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: fox
rarity: 1
resist: {}
size: small
sound: bark
speed: 15
weight: 300
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: physical
color: brown
corpse_nutrition: 250
glyph: d
hitdice: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: coyote
rarity: 1
resist: {}
size: small
small_group: 1
sound: bark
speed: 12
weight: 300
---
_corpse: {}
ac: 7
alignment: -7
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: lycanthropy
color: brown
corpse_nutrition: 250
glyph: d
hitdice: 2
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_lycanthrope: 1
lacks_hands: 1
mr: 10
name: werejackal
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
regenerates_quickly: 1
resist:
  poison: 1
size: small
sound: bark
speed: 12
weight: 300
---
_corpse: {}
ac: 6
alignment: 0
attacks:
  - damage: 1d6
    mode: bite
    type: physical
color: white
corpse_nutrition: 150
food_makes_peaceful: 1
glyph: d
hitdice: 2
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: little dog
rarity: 1
resist: {}
size: small
sound: bark
speed: 18
weight: 150
---
_corpse: {}
ac: 5
alignment: 0
attacks:
  - damage: 1d6
    mode: bite
    type: physical
color: white
corpse_nutrition: 200
food_makes_peaceful: 1
glyph: d
hitdice: 4
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: dog
rarity: 1
resist: {}
size: medium
sound: bark
speed: 16
weight: 400
---
_corpse: {}
ac: 4
alignment: 0
attacks:
  - damage: 2d4
    mode: bite
    type: physical
color: white
corpse_nutrition: 250
food_makes_peaceful: 1
glyph: d
hitdice: 6
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 0
name: large dog
rarity: 1
resist: {}
size: medium
sound: bark
speed: 15
weight: 800
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
color: yellow
corpse_nutrition: 200
glyph: d
hitdice: 4
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: dingo
rarity: 1
resist: {}
size: medium
sound: bark
speed: 16
weight: 400
---
_corpse: {}
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d4
    mode: bite
    type: physical
color: brown
corpse_nutrition: 250
glyph: d
hitdice: 5
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: wolf
rarity: 2
resist: {}
size: medium
small_group: 1
sound: bark
speed: 12
weight: 500
---
_corpse: {}
ac: 4
alignment: -7
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: lycanthropy
color: brown
corpse_nutrition: 250
glyph: d
hitdice: 5
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_lycanthrope: 1
lacks_hands: 1
mr: 20
name: werewolf
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
regenerates_quickly: 1
resist:
  poison: 1
size: medium
sound: bark
speed: 12
weight: 500
---
_corpse: {}
ac: 4
alignment: -5
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
color: brown
corpse_nutrition: 350
glyph: d
hitdice: 7
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: warg
rarity: 2
resist: {}
size: medium
small_group: 1
sound: bark
speed: 12
weight: 850
---
_corpse:
  cold: 1
absent_from_gehennom: 1
ac: 4
alignment: -5
always_hostile: 1
attacks:
  - damage: 1d8
    mode: bite
    type: physical
  - damage: 1d8
    mode: breathe
    type: cold
color: cyan
corpse_nutrition: 200
glyph: d
hitdice: 5
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: winter wolf cub
rarity: 2
resist:
  cold: 1
size: small
small_group: 1
sound: bark
speed: 12
weight: 250
---
_corpse:
  cold: 1
absent_from_gehennom: 1
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
  - damage: 2d6
    mode: breathe
    type: cold
color: cyan
corpse_nutrition: 300
glyph: d
hitdice: 7
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 20
name: winter wolf
rarity: 1
resist:
  cold: 1
size: large
sound: bark
speed: 12
weight: 700
---
_corpse:
  fire: 1
ac: 4
alignment: -5
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
  - damage: 2d6
    mode: breathe
    type: fire
color: red
corpse_nutrition: 200
gehennom_exclusive: 1
glyph: d
hitdice: 7
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 20
name: hell hound pup
rarity: 1
resist:
  fire: 1
size: small
small_group: 1
sound: bark
speed: 12
weight: 200
---
_corpse:
  fire: 1
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d6
    mode: bite
    type: physical
  - damage: 3d6
    mode: breathe
    type: fire
color: red
corpse_nutrition: 300
gehennom_exclusive: 1
glyph: d
hitdice: 12
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 20
name: hell hound
rarity: 1
resist:
  fire: 1
size: medium
sound: bark
speed: 14
weight: 600
---
_corpse: {}
ac: 10
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d6
    mode: boom
    type: physical
can_fly: 1
color: gray
corpse_nutrition: 10
glyph: e
hitdice: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: gas spore
never_drops_corpse: 1
rarity: 1
resist: {}
size: small
sound: silent
speed: 3
weight: 10
---
_corpse: {}
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d70
    mode: passive
    type: paralyze
can_fly: 1
cannot_pickup_items: 1
color: blue
corpse_nutrition: 10
glyph: e
hitdice: 2
infravision_detectable: 1
is_amphibious: 1
is_genderless: 1
is_genocidable: 1
lacks_head: 1
lacks_limbs: 1
mr: 10
name: floating eye
rarity: 5
resist: {}
size: small
sound: silent
speed: 1
weight: 10
---
_corpse:
  cold: 1
absent_from_gehennom: 1
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d6
    mode: explode
    type: cold
can_fly: 1
cannot_pickup_items: 1
color: white
corpse_nutrition: 10
glyph: e
hitdice: 6
infravision_detectable: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: freezing sphere
never_drops_corpse: 1
rarity: 2
resist:
  cold: 1
size: small
sound: silent
speed: 13
weight: 10
---
_corpse:
  fire: 1
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d6
    mode: explode
    type: fire
can_fly: 1
color: red
corpse_nutrition: 10
glyph: e
hitdice: 6
infravision_detectable: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: flaming sphere
never_drops_corpse: 1
rarity: 2
resist:
  fire: 1
size: small
sound: silent
speed: 13
weight: 10
---
_corpse:
  elec: 1
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d6
    mode: explode
    type: electricity
can_fly: 1
color: bright_blue
corpse_nutrition: 10
glyph: e
hitdice: 6
infravision_detectable: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: shocking sphere
never_drops_corpse: 1
rarity: 2
resist:
  elec: 1
size: small
sound: silent
speed: 13
weight: 10
---
_corpse: {}
ac: 6
alignment: 0
attacks:
  - damage: 1d6
    mode: bite
    type: physical
color: white
corpse_nutrition: 150
food_makes_peaceful: 1
glyph: f
hitdice: 2
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_wanderer: 1
lacks_hands: 1
mr: 0
name: kitten
rarity: 1
resist: {}
size: small
sound: mew
speed: 18
weight: 150
---
_corpse: {}
ac: 5
alignment: 0
attacks:
  - damage: 1d6
    mode: bite
    type: physical
color: white
corpse_nutrition: 200
food_makes_peaceful: 1
glyph: f
hitdice: 4
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: housecat
rarity: 1
resist: {}
size: small
sound: mew
speed: 16
weight: 200
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d8
    mode: bite
    type: physical
color: brown
corpse_nutrition: 300
glyph: f
hitdice: 4
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: jaguar
rarity: 2
resist: {}
size: large
sound: growl
speed: 15
weight: 600
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d10
    mode: bite
    type: physical
color: cyan
corpse_nutrition: 300
glyph: f
hitdice: 5
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: lynx
rarity: 1
resist: {}
size: small
sound: growl
speed: 15
weight: 600
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d10
    mode: bite
    type: physical
color: black
corpse_nutrition: 300
glyph: f
hitdice: 5
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: panther
rarity: 1
resist: {}
size: large
sound: growl
speed: 15
weight: 600
---
_corpse: {}
ac: 4
alignment: 0
attacks:
  - damage: 2d4
    mode: bite
    type: physical
color: white
corpse_nutrition: 250
food_makes_peaceful: 1
glyph: f
hitdice: 6
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 0
name: large cat
rarity: 1
resist: {}
size: small
sound: mew
speed: 15
weight: 250
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 1d10
    mode: bite
    type: physical
color: yellow
corpse_nutrition: 300
glyph: f
hitdice: 6
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: tiger
rarity: 2
resist: {}
size: large
sound: growl
speed: 12
weight: 600
---
_corpse:
  poison: 1
ac: 2
alignment: -9
attacks:
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d4
    mode: bite
    type: physical
  - damage: 0d0
    mode: claw
    type: stealintrinsic
can_swim: 1
color: green
corpse_nutrition: 20
follows_stair_users: 1
glyph: g
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_genocidable: 1
mr: 25
name: gremlin
poisonous_corpse: 1
rarity: 2
resist:
  poison: 1
size: small
sound: laugh
speed: 12
weight: 100
---
_corpse:
  stone: 1
ac: -4
alignment: -9
always_hostile: 1
attacks:
  - damage: 2d6
    mode: claw
    type: physical
  - damage: 2d6
    mode: claw
    type: physical
  - damage: 2d4
    mode: bite
    type: physical
color: brown
corpse_nutrition: 200
glyph: g
has_thick_hide: 1
hitdice: 6
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: gargoyle
rarity: 2
resist:
  stone: 1
size: medium
sound: grunt
speed: 10
weight: 1000
---
_corpse:
  stone: 1
ac: -2
alignment: -12
always_hostile: 1
attacks:
  - damage: 3d6
    mode: claw
    type: physical
  - damage: 3d6
    mode: claw
    type: physical
  - damage: 3d4
    mode: bite
    type: physical
can_fly: 1
color: magenta
corpse_nutrition: 300
glyph: g
has_thick_hide: 1
hitdice: 9
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_rank_lord: 1
is_very_strong: 1
lays_eggs: 1
mr: 0
name: winged gargoyle
rarity: 1
resist:
  stone: 1
size: medium
sound: grunt
speed: 15
wants_magic_items: 1
weight: 1200
---
_corpse: {}
ac: 10
alignment: 6
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: green
corpse_nutrition: 200
glyph: h
has_infravision: 1
hitdice: 1
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
mr: 0
name: hobbit
rarity: 2
resist: {}
size: small
sound: humanoid
speed: 9
wants_wargear: 1
weight: 500
---
_corpse: {}
ac: 10
alignment: 4
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
color: red
corpse_nutrition: 300
glyph: h
has_infravision: 1
hitdice: 2
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_dwarf: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
mr: 10
name: dwarf
rarity: 3
resist: {}
size: medium
sound: humanoid
speed: 6
tunnels_with_pick: 1
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 900
---
_corpse: {}
ac: 5
alignment: -6
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: brown
corpse_nutrition: 250
glyph: h
has_infravision: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
mr: 0
name: bugbear
rarity: 1
resist: {}
size: large
sound: growl
speed: 9
wants_wargear: 1
weight: 1250
---
_corpse: {}
ac: 10
alignment: 5
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 2d4
    mode: weapon
    type: physical
color: blue
corpse_nutrition: 300
glyph: h
has_infravision: 1
hitdice: 4
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_dwarf: 1
is_genocidable: 1
is_herbivorous: 1
is_rank_lord: 1
is_very_strong: 1
mr: 10
name: dwarf lord
rarity: 2
resist: {}
size: medium
sound: humanoid
speed: 6
tunnels_with_pick: 1
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 900
---
_corpse: {}
ac: 10
alignment: 6
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
  - damage: 2d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 300
glyph: h
has_infravision: 1
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_dwarf: 1
is_genocidable: 1
is_herbivorous: 1
is_rank_prince: 1
is_very_strong: 1
mr: 20
name: dwarf king
rarity: 1
resist: {}
size: medium
sound: humanoid
speed: 6
tunnels_with_pick: 1
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 900
---
_corpse: {}
ac: 5
alignment: -8
always_hostile: 1
attacks:
  - damage: 1d4
    mode: weapon
    type: physical
  - damage: 2d1
    mode: tentacle
    type: eatbrain
  - damage: 2d1
    mode: tentacle
    type: eatbrain
  - damage: 2d1
    mode: tentacle
    type: eatbrain
can_fly: 1
color: magenta
corpse_nutrition: 400
extra_nasty: 1
glyph: h
has_infravision: 1
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
mr: 90
name: mind flayer
rarity: 1
resist: {}
sees_invisible: 1
size: medium
sound: hiss
speed: 12
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: -8
always_hostile: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 2d1
    mode: tentacle
    type: eatbrain
  - damage: 2d1
    mode: tentacle
    type: eatbrain
  - damage: 2d1
    mode: tentacle
    type: eatbrain
  - damage: 2d1
    mode: tentacle
    type: eatbrain
  - damage: 2d1
    mode: tentacle
    type: eatbrain
can_fly: 1
color: magenta
corpse_nutrition: 400
extra_nasty: 1
glyph: h
has_infravision: 1
hitdice: 13
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
mr: 90
name: master mind flayer
rarity: 1
resist: {}
sees_invisible: 1
size: medium
sound: hiss
speed: 12
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 7
alignment: -7
always_hostile: 1
attacks:
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d4
    mode: bite
    type: physical
color: red
corpse_nutrition: 100
follows_stair_users: 1
glyph: i
has_infravision: 1
hitdice: 1
infravision_detectable: 1
is_genocidable: 1
large_group: 1
mr: 0
name: manes
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
  sleep: 1
size: small
sound: silent
speed: 3
weight: 100
---
_corpse:
  poison: 1
  sleep: 1
ac: 6
alignment: -7
attacks:
  - damage: 1d3
    mode: bite
    type: sleep
can_fly: 1
color: green
corpse_nutrition: 100
follows_stair_users: 1
glyph: i
has_infravision: 1
hitdice: 2
infravision_detectable: 1
is_genocidable: 1
mr: 10
name: homunculus
poisonous_corpse: 1
rarity: 2
resist:
  poison: 1
  sleep: 1
size: tiny
sound: silent
speed: 12
weight: 60
---
_corpse: {}
ac: 2
alignment: -7
attacks:
  - damage: 1d4
    mode: claw
    type: physical
color: red
corpse_nutrition: 10
follows_stair_users: 1
glyph: i
has_infravision: 1
hitdice: 3
infravision_detectable: 1
is_genocidable: 1
is_wanderer: 1
mr: 20
name: imp
rarity: 1
regenerates_quickly: 1
resist: {}
size: tiny
sound: cuss
speed: 12
weight: 20
---
_corpse:
  sleep: 1
ac: 7
alignment: -7
always_hostile: 1
attacks:
  - damage: 1d3
    mode: claw
    type: physical
color: brown
corpse_nutrition: 100
follows_stair_users: 1
gehennom_exclusive: 1
glyph: i
has_infravision: 1
hitdice: 3
infravision_detectable: 1
is_genderless: 1
is_genocidable: 1
is_wanderer: 1
large_group: 1
mr: 0
name: lemure
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  poison: 1
  sleep: 1
size: medium
sound: silent
speed: 3
weight: 150
---
_corpse:
  poison: 1
ac: 2
alignment: -7
attacks:
  - damage: 1d2
    mode: claw
    type: poisondex
  - damage: 1d2
    mode: claw
    type: poisondex
  - damage: 1d4
    mode: bite
    type: physical
color: blue
corpse_nutrition: 200
follows_stair_users: 1
glyph: i
has_infravision: 1
hitdice: 3
infravision_detectable: 1
is_genocidable: 1
mr: 20
name: quasit
rarity: 2
regenerates_quickly: 1
resist:
  poison: 1
size: small
sound: silent
speed: 15
weight: 200
---
_corpse:
  poison: 1
ac: 5
alignment: 7
attacks:
  - damage: 1d7
    mode: bite
    type: physical
color: cyan
corpse_nutrition: 200
follows_stair_users: 1
glyph: i
has_infravision: 1
has_teleport_control: 1
has_teleportitis: 1
hitdice: 6
infravision_detectable: 1
is_genocidable: 1
mr: 30
name: tengu
rarity: 3
resist:
  poison: 1
size: small
sound: sqawk
speed: 13
weight: 300
---
_corpse:
  cold: 1
  poison: 1
ac: 8
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d6
    mode: passive
    type: cold
cannot_pickup_items: 1
color: blue
corpse_nutrition: 20
glyph: j
hitdice: 4
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 10
name: blue jelly
rarity: 2
resist:
  cold: 1
  poison: 1
size: medium
sound: silent
speed: 0
weight: 50
---
_corpse: {}
ac: 8
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d6
    mode: passive
    type: acid
cannot_pickup_items: 1
color: green
corpse_nutrition: 20
glyph: j
hitdice: 5
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 10
name: spotted jelly
rarity: 1
resist:
  acid: 1
  stone: 1
size: medium
sound: silent
speed: 0
weight: 50
---
_corpse: {}
ac: 8
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d6
    mode: engulf
    type: acid
  - damage: 3d6
    mode: passive
    type: acid
cannot_pickup_items: 1
color: brown
corpse_nutrition: 20
glyph: j
hitdice: 6
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 20
name: ochre jelly
rarity: 2
resist:
  acid: 1
  stone: 1
size: medium
sound: silent
speed: 3
weight: 50
---
_corpse: {}
ac: 10
alignment: -2
always_hostile: 1
attacks:
  - damage: 1d4
    mode: weapon
    type: physical
color: brown
corpse_nutrition: 100
glyph: k
has_infravision: 1
hitdice: 0
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
mr: 0
name: kobold
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
size: small
sound: orc
speed: 6
wants_wargear: 1
weight: 400
---
_corpse: {}
ac: 10
alignment: -3
always_hostile: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: red
corpse_nutrition: 150
glyph: k
has_infravision: 1
hitdice: 1
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
mr: 0
name: large kobold
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
size: small
sound: orc
speed: 6
wants_wargear: 1
weight: 450
---
_corpse: {}
ac: 10
alignment: -4
always_hostile: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 200
glyph: k
has_infravision: 1
hitdice: 2
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_rank_lord: 1
mr: 0
name: kobold lord
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
size: small
sound: orc
speed: 6
wants_wargear: 1
weight: 500
---
_corpse: {}
ac: 6
alignment: -4
always_hostile: 1
attacks:
  - damage: 0d0
    mode: magic
    type: wizardspell
color: bright_blue
corpse_nutrition: 150
glyph: k
has_infravision: 1
hitdice: 2
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
mr: 10
name: kobold shaman
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
size: small
sound: orc
speed: 6
wants_magic_items: 1
weight: 450
---
_corpse: {}
ac: 8
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d2
    mode: claw
    type: stealgold
color: green
corpse_nutrition: 30
glyph: l
has_teleportitis: 1
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_genocidable: 1
mr: 20
name: leprechaun
rarity: 4
resist: {}
size: tiny
sound: laugh
speed: 15
wants_gold: 1
weight: 60
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d4
    mode: claw
    type: physical
color: brown
corpse_nutrition: 200
glyph: m
has_thick_hide: 1
hitdice: 7
is_amorphous: 1
is_amphibious: 1
is_animal: 1
is_breathless: 1
is_carnivorous: 1
is_genocidable: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: small mimic
rarity: 2
resist:
  acid: 1
size: medium
sound: silent
speed: 3
weight: 300
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d4
    mode: claw
    type: stick
clings_to_ceiling: 1
color: red
corpse_nutrition: 400
glyph: m
has_thick_hide: 1
hitdice: 8
is_amorphous: 1
is_amphibious: 1
is_animal: 1
is_breathless: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 10
name: large mimic
rarity: 1
resist:
  acid: 1
size: large
sound: silent
speed: 3
weight: 600
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d6
    mode: claw
    type: stick
  - damage: 3d6
    mode: claw
    type: stick
clings_to_ceiling: 1
color: magenta
corpse_nutrition: 500
glyph: m
has_thick_hide: 1
hitdice: 9
is_amorphous: 1
is_amphibious: 1
is_animal: 1
is_breathless: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 20
name: giant mimic
rarity: 1
resist:
  acid: 1
size: large
sound: silent
speed: 3
weight: 800
---
_corpse: {}
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d0
    mode: claw
    type: stealitem
  - damage: 0d0
    mode: claw
    type: seduce
color: green
corpse_nutrition: 300
glyph: n
has_teleportitis: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_always_female: 1
is_genocidable: 1
mr: 20
name: wood nymph
rarity: 2
resist: {}
size: medium
sound: seduce
speed: 12
wants_wargear: 1
weight: 600
---
_corpse: {}
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d0
    mode: claw
    type: stealitem
  - damage: 0d0
    mode: claw
    type: seduce
can_swim: 1
color: blue
corpse_nutrition: 300
glyph: n
has_teleportitis: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_always_female: 1
is_genocidable: 1
mr: 20
name: water nymph
rarity: 2
resist: {}
size: medium
sound: seduce
speed: 12
wants_wargear: 1
weight: 600
---
_corpse: {}
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d0
    mode: claw
    type: stealitem
  - damage: 0d0
    mode: claw
    type: seduce
color: brown
corpse_nutrition: 300
glyph: n
has_teleportitis: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_always_female: 1
is_genocidable: 1
mr: 20
name: mountain nymph
rarity: 2
resist: {}
size: medium
sound: seduce
speed: 12
wants_wargear: 1
weight: 600
---
_corpse: {}
ac: 10
alignment: -3
attacks:
  - damage: 1d4
    mode: weapon
    type: physical
color: gray
corpse_nutrition: 100
glyph: o
has_infravision: 1
hitdice: 0
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_orc: 1
mr: 0
name: goblin
rarity: 2
resist: {}
size: small
sound: orc
speed: 6
wants_wargear: 1
weight: 400
---
_corpse: {}
ac: 10
alignment: -4
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: brown
corpse_nutrition: 200
glyph: o
has_infravision: 1
hitdice: 1
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_orc: 1
is_very_strong: 1
mr: 0
name: hobgoblin
rarity: 2
resist: {}
size: medium
sound: orc
speed: 9
wants_wargear: 1
weight: 1000
---
_corpse: {}
ac: 10
alignment: -3
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
color: red
corpse_nutrition: 150
glyph: o
has_infravision: 1
hitdice: 1
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_orc: 1
is_very_strong: 1
large_group: 1
mr: 0
name: orc
not_randomly_generated: 1
resist: {}
size: medium
sound: orc
speed: 9
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 850
---
_corpse: {}
ac: 10
alignment: -4
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: yellow
corpse_nutrition: 200
glyph: o
has_infravision: 1
hitdice: 2
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_orc: 1
is_very_strong: 1
large_group: 1
mr: 0
name: hill orc
rarity: 2
resist: {}
size: medium
sound: orc
speed: 9
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1000
---
_corpse: {}
ac: 10
alignment: -5
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: blue
corpse_nutrition: 200
glyph: o
has_infravision: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_orc: 1
is_very_strong: 1
large_group: 1
mr: 0
name: Mordor orc
rarity: 1
resist: {}
size: medium
sound: orc
speed: 5
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1200
---
_corpse: {}
ac: 10
alignment: -4
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
color: black
corpse_nutrition: 300
glyph: o
has_infravision: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_orc: 1
is_very_strong: 1
large_group: 1
mr: 0
name: Uruk-hai
rarity: 1
resist: {}
size: medium
sound: orc
speed: 7
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1300
---
_corpse: {}
ac: 5
alignment: -5
attacks:
  - damage: 0d0
    mode: magic
    type: wizardspell
color: bright_blue
corpse_nutrition: 300
glyph: o
has_infravision: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_orc: 1
is_very_strong: 1
mr: 10
name: orc shaman
rarity: 1
resist: {}
size: medium
sound: orc
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 1000
---
_corpse: {}
ac: 10
alignment: -5
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 2d4
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 350
glyph: o
has_infravision: 1
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_orc: 1
is_very_strong: 1
mr: 0
name: orc-captain
rarity: 1
resist: {}
size: medium
sound: orc
speed: 5
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1350
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
cannot_pickup_items: 1
clings_to_ceiling: 1
color: gray
corpse_nutrition: 200
glyph: p
hides_on_ceiling: 1
hitdice: 3
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_eyes: 1
lacks_limbs: 1
mr: 0
name: rock piercer
rarity: 4
resist: {}
size: small
sound: silent
speed: 1
weight: 200
---
_corpse: {}
ac: 0
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d6
    mode: bite
    type: physical
cannot_pickup_items: 1
clings_to_ceiling: 1
color: cyan
corpse_nutrition: 300
glyph: p
hides_on_ceiling: 1
hitdice: 5
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_eyes: 1
lacks_limbs: 1
mr: 0
name: iron piercer
rarity: 2
resist: {}
size: medium
sound: silent
speed: 1
weight: 400
---
_corpse: {}
ac: 0
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d6
    mode: bite
    type: physical
cannot_pickup_items: 1
clings_to_ceiling: 1
color: white
corpse_nutrition: 300
glyph: p
hides_on_ceiling: 1
hitdice: 7
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_eyes: 1
lacks_limbs: 1
mr: 0
name: glass piercer
rarity: 1
resist:
  acid: 1
size: medium
sound: silent
speed: 1
weight: 400
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: bite
    type: physical
  - damage: 1d8
    mode: bite
    type: physical
color: brown
corpse_nutrition: 100
glyph: q
hitdice: 2
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
lacks_hands: 1
mr: 0
name: rothe
rarity: 4
resist: {}
size: large
small_group: 1
sound: silent
speed: 9
weight: 400
---
_corpse: {}
ac: 0
alignment: -2
always_hostile: 1
attacks:
  - damage: 4d12
    mode: headbutt
    type: physical
  - damage: 2d6
    mode: bite
    type: physical
color: gray
corpse_nutrition: 500
glyph: q
has_thick_hide: 1
hitdice: 5
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_hands: 1
mr: 0
name: mumak
rarity: 1
resist: {}
size: large
sound: roar
speed: 9
weight: 2500
---
_corpse: {}
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: claw
    type: physical
  - damage: 2d6
    mode: bite
    type: physical
  - damage: 2d6
    mode: claw
    type: physical
color: red
corpse_nutrition: 500
glyph: q
hitdice: 6
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: leocrotta
rarity: 2
resist: {}
size: large
sound: imitate
speed: 18
weight: 1200
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d6
    mode: bite
    type: physical
clings_to_ceiling: 1
color: cyan
corpse_nutrition: 500
glyph: q
hitdice: 8
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: wumpus
rarity: 1
resist: {}
size: large
sound: burble
speed: 3
weight: 2500
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d8
    mode: claw
    type: physical
color: gray
corpse_nutrition: 650
glyph: q
has_thick_hide: 1
hitdice: 12
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_hands: 1
mr: 0
name: titanothere
rarity: 2
resist: {}
size: large
sound: silent
speed: 12
weight: 2650
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 5d4
    mode: claw
    type: physical
  - damage: 5d4
    mode: claw
    type: physical
color: gray
corpse_nutrition: 800
glyph: q
has_thick_hide: 1
hitdice: 14
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_hands: 1
mr: 0
name: baluchitherium
rarity: 2
resist: {}
size: large
sound: silent
speed: 12
weight: 3800
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d8
    mode: headbutt
    type: physical
  - damage: 4d8
    mode: headbutt
    type: physical
color: black
corpse_nutrition: 800
glyph: q
has_thick_hide: 1
hitdice: 20
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_hands: 1
mr: 0
name: mastodon
rarity: 1
resist: {}
size: large
sound: silent
speed: 12
weight: 3800
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: bite
    type: physical
color: brown
corpse_nutrition: 12
glyph: r
hitdice: 0
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: sewer rat
rarity: 1
resist: {}
size: tiny
small_group: 1
sound: sqeek
speed: 12
weight: 20
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: bite
    type: physical
color: brown
corpse_nutrition: 30
glyph: r
hitdice: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: giant rat
rarity: 2
resist: {}
size: tiny
small_group: 1
sound: sqeek
speed: 10
weight: 30
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d4
    mode: bite
    type: poisoncon
color: brown
corpse_nutrition: 5
glyph: r
hitdice: 2
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: rabid rat
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
size: tiny
sound: sqeek
speed: 12
weight: 30
---
_corpse: {}
ac: 6
alignment: -7
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: lycanthropy
color: brown
corpse_nutrition: 30
glyph: r
hitdice: 2
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_lycanthrope: 1
lacks_hands: 1
mr: 10
name: wererat
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
regenerates_quickly: 1
resist:
  poison: 1
size: tiny
sound: sqeek
speed: 12
weight: 40
---
_corpse: {}
ac: 0
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
can_eat_metal: 1
can_eat_rock: 1
color: gray
corpse_nutrition: 30
glyph: r
hitdice: 3
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
lacks_hands: 1
mr: 20
name: rock mole
rarity: 2
resist: {}
size: small
sound: silent
speed: 3
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 30
---
_corpse: {}
ac: 0
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
can_eat_rock: 1
can_swim: 1
color: brown
corpse_nutrition: 30
glyph: r
hitdice: 3
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
is_herbivorous: 1
is_wanderer: 1
lacks_hands: 1
mr: 20
name: woodchuck
not_randomly_generated: 1
resist: {}
size: small
sound: silent
speed: 3
weight: 30
---
_corpse:
  poison: 1
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d2
    mode: bite
    type: physical
color: gray
corpse_nutrition: 50
glyph: s
hides_under_item: 1
hitdice: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: cave spider
rarity: 2
resist:
  poison: 1
size: tiny
small_group: 1
sound: silent
speed: 12
weight: 50
---
_corpse:
  poison: 1
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: bite
    type: poison
color: yellow
corpse_nutrition: 50
glyph: s
hides_under_item: 1
hitdice: 2
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: centipede
rarity: 1
resist:
  poison: 1
size: tiny
sound: silent
speed: 4
weight: 50
---
_corpse:
  poison: 1
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d4
    mode: bite
    type: poison
color: magenta
corpse_nutrition: 100
glyph: s
hitdice: 5
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: giant spider
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
size: large
sound: silent
speed: 15
weight: 100
---
_corpse:
  poison: 1
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d2
    mode: claw
    type: physical
  - damage: 1d2
    mode: claw
    type: physical
  - damage: 1d4
    mode: sting
    type: poison
color: red
corpse_nutrition: 100
glyph: s
hides_under_item: 1
hitdice: 5
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: scorpion
poisonous_corpse: 1
rarity: 2
resist:
  poison: 1
size: small
sound: silent
speed: 15
weight: 50
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d8
    mode: engulf
    type: digest
can_fly: 1
color: gray
corpse_nutrition: 350
follows_stair_users: 1
glyph: t
hides_on_ceiling: 1
hitdice: 10
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: lurker above
rarity: 2
resist: {}
size: huge
sound: silent
speed: 3
weight: 800
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d10
    mode: engulf
    type: digest
color: green
corpse_nutrition: 350
follows_stair_users: 1
glyph: t
hides_on_ceiling: 1
hitdice: 12
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: trapper
rarity: 2
resist: {}
size: huge
sound: silent
speed: 3
weight: 800
---
_corpse:
  poison: 1
ac: 2
alignment: 7
attacks:
  - damage: 1d12
    mode: headbutt
    type: physical
  - damage: 1d6
    mode: kick
    type: physical
color: white
corpse_nutrition: 300
glyph: u
hitdice: 4
infravision_detectable: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
is_wanderer: 1
lacks_hands: 1
mr: 70
name: white unicorn
rarity: 2
resist:
  poison: 1
size: large
sound: neigh
speed: 24
wants_gems: 1
weight: 1300
---
_corpse:
  poison: 1
ac: 2
alignment: 0
attacks:
  - damage: 1d12
    mode: headbutt
    type: physical
  - damage: 1d6
    mode: kick
    type: physical
color: gray
corpse_nutrition: 300
glyph: u
hitdice: 4
infravision_detectable: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
is_wanderer: 1
lacks_hands: 1
mr: 70
name: gray unicorn
rarity: 1
resist:
  poison: 1
size: large
sound: neigh
speed: 24
wants_gems: 1
weight: 1300
---
_corpse:
  poison: 1
ac: 2
alignment: -7
attacks:
  - damage: 1d12
    mode: headbutt
    type: physical
  - damage: 1d6
    mode: kick
    type: physical
color: black
corpse_nutrition: 300
glyph: u
hitdice: 4
infravision_detectable: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
is_wanderer: 1
lacks_hands: 1
mr: 70
name: black unicorn
rarity: 1
resist:
  poison: 1
size: large
sound: neigh
speed: 24
wants_gems: 1
weight: 1300
---
_corpse: {}
ac: 6
alignment: 0
attacks:
  - damage: 1d6
    mode: kick
    type: physical
  - damage: 1d2
    mode: bite
    type: physical
color: brown
corpse_nutrition: 250
food_makes_peaceful: 1
glyph: u
hitdice: 3
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
is_wanderer: 1
lacks_hands: 1
mr: 0
name: pony
rarity: 2
resist: {}
size: medium
sound: neigh
speed: 16
weight: 1300
---
_corpse: {}
ac: 5
alignment: 0
attacks:
  - damage: 1d8
    mode: kick
    type: physical
  - damage: 1d3
    mode: bite
    type: physical
color: brown
corpse_nutrition: 300
food_makes_peaceful: 1
glyph: u
hitdice: 5
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
is_wanderer: 1
lacks_hands: 1
mr: 0
name: horse
rarity: 2
resist: {}
size: large
sound: neigh
speed: 20
weight: 1500
---
_corpse: {}
ac: 4
alignment: 0
attacks:
  - damage: 1d10
    mode: kick
    type: physical
  - damage: 1d4
    mode: bite
    type: physical
color: brown
corpse_nutrition: 350
food_makes_peaceful: 1
glyph: u
hitdice: 7
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
is_wanderer: 1
lacks_hands: 1
mr: 0
name: warhorse
rarity: 2
resist: {}
size: large
sound: neigh
speed: 24
weight: 1800
---
_corpse: {}
ac: 0
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: engulf
    type: physical
can_fly: 1
color: gray
glyph: v
hitdice: 3
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
made_of_gas: 1
mr: 0
name: fog cloud
never_drops_corpse: 1
nutrition: 0
rarity: 2
resist:
  poison: 1
  sleep: 1
  stone: 1
size: huge
sound: silent
speed: 1
weight: 0
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d8
    mode: engulf
    type: blind
can_fly: 1
color: brown
glyph: v
hitdice: 4
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 30
name: dust vortex
never_drops_corpse: 1
nutrition: 0
rarity: 2
resist:
  poison: 1
  sleep: 1
  stone: 1
size: huge
sound: silent
speed: 20
weight: 0
---
_corpse: {}
absent_from_gehennom: 1
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: engulf
    type: cold
can_fly: 1
color: cyan
glyph: v
hitdice: 5
infravision_detectable: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 30
name: ice vortex
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
  stone: 1
size: huge
sound: silent
speed: 20
weight: 0
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: engulf
    type: electricity
  - damage: 0d0
    mode: engulf
    type: drainenergy
  - damage: 0d4
    mode: passive
    type: electricity
can_fly: 1
color: bright_blue
glyph: v
hitdice: 6
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
made_of_gas: 1
mr: 30
name: energy vortex
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  disint: 1
  elec: 1
  poison: 1
  sleep: 1
  stone: 1
size: huge
sound: silent
speed: 20
weight: 0
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d8
    mode: engulf
    type: fire
can_fly: 1
color: blue
gehennom_exclusive: 1
glyph: v
hitdice: 7
infravision_detectable: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
made_of_gas: 1
mr: 30
name: steam vortex
never_drops_corpse: 1
nutrition: 0
rarity: 2
resist:
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
size: huge
sound: silent
speed: 22
weight: 0
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d10
    mode: engulf
    type: fire
  - damage: 0d4
    mode: passive
    type: fire
can_fly: 1
color: yellow
gehennom_exclusive: 1
glyph: v
hitdice: 8
infravision_detectable: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
made_of_gas: 1
mr: 30
name: fire vortex
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
size: huge
sound: silent
speed: 22
weight: 0
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
cannot_pickup_items: 1
color: brown
corpse_nutrition: 250
glyph: w
hitdice: 8
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
mr: 0
name: baby long worm
resist: {}
serpentine_body: 1
size: large
sound: silent
speed: 3
weight: 600
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
color: magenta
corpse_nutrition: 250
glyph: w
hitdice: 8
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
mr: 0
name: baby purple worm
resist: {}
serpentine_body: 1
size: large
sound: silent
speed: 3
weight: 600
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: physical
cannot_pickup_items: 1
color: brown
corpse_nutrition: 500
extra_nasty: 1
glyph: w
hitdice: 8
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_limbs: 1
lays_eggs: 1
mr: 10
name: long worm
rarity: 2
resist: {}
serpentine_body: 1
size: gigantic
sound: silent
speed: 3
weight: 1500
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d8
    mode: bite
    type: physical
  - damage: 1d10
    mode: engulf
    type: digest
color: magenta
corpse_nutrition: 700
extra_nasty: 1
glyph: w
hitdice: 15
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_limbs: 1
lays_eggs: 1
mr: 20
name: purple worm
rarity: 2
resist: {}
serpentine_body: 1
size: gigantic
sound: silent
speed: 9
weight: 2700
---
_corpse: {}
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d1
    mode: bite
    type: electricity
color: magenta
corpse_nutrition: 10
glyph: x
hitdice: 0
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
mr: 0
name: grid bug
never_drops_corpse: 1
rarity: 3
resist:
  elec: 1
  poison: 1
size: tiny
small_group: 1
sound: buzz
speed: 12
weight: 15
---
_corpse:
  poison: 1
ac: -4
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: sting
    type: legs
can_fly: 1
color: red
corpse_nutrition: 300
glyph: x
hitdice: 7
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: xan
poisonous_corpse: 1
rarity: 3
resist:
  poison: 1
size: tiny
sound: buzz
speed: 18
weight: 300
---
_corpse: {}
ac: 0
alignment: 0
always_hostile: 1
attacks:
  - damage: 10d20
    mode: explode
    type: blind
can_fly: 1
cannot_pickup_items: 1
color: yellow
glyph: y
hitdice: 3
infravision_detectable: 1
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
made_of_gas: 1
mr: 0
name: yellow light
never_drops_corpse: 1
nutrition: 0
rarity: 4
resist:
  acid: 1
  cold: 1
  disint: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
size: small
sound: silent
speed: 15
weight: 0
---
_corpse: {}
ac: 0
alignment: 0
always_hostile: 1
attacks:
  - damage: 10d12
    mode: explode
    type: hallucination
can_fly: 1
cannot_pickup_items: 1
color: black
glyph: y
hitdice: 5
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
made_of_gas: 1
mr: 0
name: black light
never_drops_corpse: 1
nutrition: 0
rarity: 2
resist:
  acid: 1
  cold: 1
  disint: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
sees_invisible: 1
size: small
sound: silent
speed: 15
weight: 0
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d4
    mode: claw
    type: physical
  - damage: 3d4
    mode: claw
    type: physical
  - damage: 3d6
    mode: bite
    type: physical
color: brown
corpse_nutrition: 600
glyph: z
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: zruty
rarity: 2
resist: {}
size: large
sound: silent
speed: 8
weight: 1200
---
_corpse: {}
absent_from_gehennom: 1
ac: 5
alignment: 7
attacks:
  - damage: 2d4
    mode: bite
    type: poison
  - damage: 1d3
    mode: bite
    type: physical
  - damage: 2d4
    mode: crush
    type: wrap
can_fly: 1
color: green
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: A
has_infravision: 1
hitdice: 8
infravision_detectable: 1
is_minion: 1
is_very_strong: 1
mr: 30
name: couatl
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
size: large
small_group: 1
sound: hiss
speed: 10
weight: 900
---
_corpse: {}
absent_from_gehennom: 1
ac: 0
alignment: 7
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d4
    mode: kick
    type: physical
color: yellow
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: A
has_infravision: 1
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
is_minion: 1
mr: 30
name: Aleax
never_drops_corpse: 1
rarity: 1
resist:
  cold: 1
  elec: 1
  poison: 1
  sleep: 1
sees_invisible: 1
size: medium
sound: imitate
speed: 8
wants_wargear: 1
weight: 1450
---
_corpse: {}
absent_from_gehennom: 1
ac: -4
alignment: 12
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 2d6
    mode: magic
    type: magicmissile
can_fly: 1
color: white
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: A
has_infravision: 1
hitdice: 14
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_minion: 1
is_very_strong: 1
mr: 55
name: Angel
never_drops_corpse: 1
rarity: 1
resist:
  cold: 1
  elec: 1
  poison: 1
  sleep: 1
sees_invisible: 1
size: medium
sound: cuss
speed: 10
wants_wargear: 1
weight: 1450
---
_corpse: {}
absent_from_gehennom: 1
ac: -5
alignment: 15
attacks:
  - damage: 2d4
    mode: kick
    type: physical
  - damage: 2d4
    mode: kick
    type: physical
  - damage: 3d6
    mode: headbutt
    type: physical
  - damage: 2d6
    mode: magic
    type: wizardspell
can_fly: 1
color: yellow
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: A
has_infravision: 1
hitdice: 16
infravision_detectable: 1
invalid_polymorph_target: 1
is_minion: 1
is_rank_lord: 1
is_very_strong: 1
mr: 90
name: ki-rin
never_drops_corpse: 1
rarity: 1
resist: {}
sees_invisible: 1
size: large
sound: neigh
speed: 18
weight: 1450
---
_corpse: {}
absent_from_gehennom: 1
ac: -6
alignment: 15
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 2d6
    mode: gaze
    type: blind
  - damage: 1d8
    mode: claw
    type: physical
  - damage: 4d6
    mode: magic
    type: wizardspell
can_fly: 1
color: magenta
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: A
has_infravision: 1
hitdice: 19
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_minion: 1
is_rank_lord: 1
is_very_strong: 1
mr: 80
name: Archon
never_drops_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
sees_invisible: 1
size: large
sound: cuss
speed: 16
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 8
alignment: 0
attacks:
  - damage: 1d4
    mode: bite
    type: physical
can_fly: 1
color: brown
corpse_nutrition: 20
glyph: B
hitdice: 0
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_wanderer: 1
lacks_hands: 1
mr: 0
name: bat
rarity: 1
resist: {}
size: tiny
small_group: 1
sound: sqeek
speed: 22
weight: 20
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
can_fly: 1
color: red
corpse_nutrition: 30
glyph: B
hitdice: 2
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_wanderer: 1
lacks_hands: 1
mr: 0
name: giant bat
rarity: 2
resist: {}
size: small
sound: sqeek
speed: 22
weight: 30
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
  - damage: 1d6
    mode: claw
    type: blind
can_fly: 1
color: black
corpse_nutrition: 20
glyph: B
hitdice: 4
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_wanderer: 1
lacks_hands: 1
mr: 0
name: raven
rarity: 2
resist: {}
size: small
sound: sqawk
speed: 20
weight: 40
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
  - damage: 0d0
    mode: bite
    type: poison
can_fly: 1
color: black
corpse_nutrition: 20
glyph: B
hitdice: 5
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
lacks_hands: 1
mr: 0
name: vampire bat
poisonous_corpse: 1
rarity: 2
regenerates_quickly: 1
resist:
  poison: 1
  sleep: 1
size: small
sound: sqeek
speed: 20
weight: 30
---
_corpse: {}
ac: 4
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: kick
    type: physical
color: brown
corpse_nutrition: 500
glyph: C
hitdice: 4
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
mr: 0
name: plains centaur
rarity: 1
resist: {}
size: large
sound: humanoid
speed: 18
wants_gold: 1
wants_wargear: 1
weight: 2500
---
_corpse: {}
ac: 3
alignment: -1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 1d6
    mode: kick
    type: physical
color: green
corpse_nutrition: 600
glyph: C
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
mr: 10
name: forest centaur
rarity: 1
resist: {}
size: large
sound: humanoid
speed: 18
wants_gold: 1
wants_wargear: 1
weight: 2550
---
_corpse: {}
ac: 2
alignment: -3
attacks:
  - damage: 1d10
    mode: weapon
    type: physical
  - damage: 1d6
    mode: kick
    type: physical
  - damage: 1d6
    mode: kick
    type: physical
color: cyan
corpse_nutrition: 500
glyph: C
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
mr: 10
name: mountain centaur
rarity: 1
resist: {}
size: large
sound: humanoid
speed: 20
wants_gold: 1
wants_wargear: 1
weight: 2550
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: gray
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby gray dragon
resist: {}
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: gray
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby silver dragon
resist: {}
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: red
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby red dragon
resist:
  fire: 1
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: white
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby white dragon
resist:
  cold: 1
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: orange
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby orange dragon
resist:
  sleep: 1
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: black
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby black dragon
resist:
  disint: 1
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: blue
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby blue dragon
resist:
  elec: 1
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: green
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby green dragon
poisonous_corpse: 1
resist:
  poison: 1
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: 2
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_fly: 1
color: yellow
corpse_nutrition: 500
glyph: D
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 10
name: baby yellow dragon
resist:
  acid: 1
  stone: 1
size: huge
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
weight: 1500
---
_corpse: {}
ac: -1
alignment: 4
always_hostile: 1
attacks:
  - damage: 4d6
    mode: breathe
    type: magicmissile
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: gray
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: gray dragon
rarity: 1
resist: {}
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse: {}
ac: -1
alignment: 4
always_hostile: 1
attacks:
  - damage: 4d6
    mode: breathe
    type: cold
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: gray
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: silver dragon
rarity: 1
resist:
  cold: 1
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse:
  fire: 1
ac: -1
alignment: -4
always_hostile: 1
attacks:
  - damage: 6d6
    mode: breathe
    type: fire
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: red
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: red dragon
rarity: 1
resist:
  fire: 1
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse:
  cold: 1
ac: -1
alignment: -5
always_hostile: 1
attacks:
  - damage: 4d6
    mode: breathe
    type: cold
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: white
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: white dragon
rarity: 1
resist:
  cold: 1
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse:
  sleep: 1
ac: -1
alignment: 5
always_hostile: 1
attacks:
  - damage: 4d25
    mode: breathe
    type: sleep
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: orange
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: orange dragon
rarity: 1
resist:
  sleep: 1
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse:
  disint: 1
ac: -1
alignment: -6
always_hostile: 1
attacks:
  - damage: 4d10
    mode: breathe
    type: disintegration
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: black
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: black dragon
rarity: 1
resist:
  disint: 1
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse:
  elec: 1
ac: -1
alignment: -7
always_hostile: 1
attacks:
  - damage: 4d6
    mode: breathe
    type: electricity
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: blue
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: blue dragon
rarity: 1
resist:
  elec: 1
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse:
  poison: 1
ac: -1
alignment: 6
always_hostile: 1
attacks:
  - damage: 4d6
    mode: breathe
    type: poison
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: green
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: green dragon
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse:
  stone: 1
ac: -1
acidic_corpse: 1
alignment: 7
always_hostile: 1
attacks:
  - damage: 4d6
    mode: breathe
    type: acid
  - damage: 3d8
    mode: bite
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
can_fly: 1
color: yellow
corpse_nutrition: 1500
extra_nasty: 1
glyph: D
has_thick_hide: 1
hitdice: 15
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 20
name: yellow dragon
rarity: 1
resist:
  acid: 1
  stone: 1
sees_invisible: 1
size: gigantic
sound: roar
speed: 9
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
weight: 4500
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d4
    mode: claw
    type: physical
can_fly: 1
color: white
corpse_nutrition: 400
follows_stair_users: 1
glyph: E
has_infravision: 1
hitdice: 8
is_animal: 1
is_genocidable: 1
is_very_strong: 1
is_wanderer: 1
mr: 0
name: stalker
rarity: 3
resist: {}
sees_invisible: 1
size: large
sound: silent
speed: 12
weight: 900
---
_corpse: {}
ac: 2
alignment: 0
attacks:
  - damage: 1d10
    mode: engulf
    type: physical
can_fly: 1
color: cyan
glyph: E
hitdice: 8
is_genderless: 1
is_mindless: 1
is_very_strong: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
made_of_gas: 1
mr: 30
name: air elemental
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  stone: 1
size: huge
sound: silent
speed: 36
weight: 0
---
_corpse: {}
ac: 2
alignment: 0
attacks:
  - damage: 3d6
    mode: claw
    type: fire
  - damage: 0d4
    mode: passive
    type: fire
can_fly: 1
cannot_pickup_items: 1
color: yellow
glyph: E
hitdice: 8
infravision_detectable: 1
is_genderless: 1
is_mindless: 1
is_very_strong: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
made_of_gas: 1
mr: 30
name: fire elemental
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  fire: 1
  poison: 1
  stone: 1
size: huge
sound: silent
speed: 12
weight: 0
---
_corpse: {}
ac: 2
alignment: 0
attacks:
  - damage: 4d6
    mode: claw
    type: physical
color: brown
glyph: E
has_thick_hide: 1
hitdice: 8
ignores_walls: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_mindless: 1
is_very_strong: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 30
name: earth elemental
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  cold: 1
  fire: 1
  poison: 1
  stone: 1
size: huge
sound: silent
speed: 6
weight: 2500
---
_corpse: {}
ac: 2
alignment: 0
attacks:
  - damage: 5d6
    mode: claw
    type: physical
can_swim: 1
color: blue
glyph: E
hitdice: 8
is_amphibious: 1
is_genderless: 1
is_mindless: 1
is_very_strong: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 30
name: water elemental
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  stone: 1
size: huge
sound: silent
speed: 6
weight: 2500
---
_corpse: {}
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d0
    mode: touch
    type: stick
cannot_pickup_items: 1
color: bright_green
corpse_nutrition: 200
glyph: F
hitdice: 0
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: lichen
rarity: 4
resist: {}
size: small
sound: silent
speed: 1
weight: 20
---
_corpse:
  cold: 1
  poison: 1
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d6
    mode: passive
    type: cold
cannot_pickup_items: 1
color: brown
corpse_nutrition: 30
glyph: F
hitdice: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: brown mold
rarity: 1
resist:
  cold: 1
  poison: 1
size: small
sound: silent
speed: 0
weight: 50
---
_corpse:
  poison: 1
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d4
    mode: passive
    type: stun
cannot_pickup_items: 1
color: yellow
corpse_nutrition: 30
glyph: F
hitdice: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: yellow mold
poisonous_corpse: 1
rarity: 2
resist:
  poison: 1
size: small
sound: silent
speed: 0
weight: 50
---
_corpse:
  stone: 1
ac: 9
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d4
    mode: passive
    type: acid
cannot_pickup_items: 1
color: green
corpse_nutrition: 30
glyph: F
hitdice: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: green mold
rarity: 1
resist:
  acid: 1
  stone: 1
size: small
sound: silent
speed: 0
weight: 50
---
_corpse:
  fire: 1
  poison: 1
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d4
    mode: passive
    type: fire
cannot_pickup_items: 1
color: red
corpse_nutrition: 30
glyph: F
hitdice: 1
infravision_detectable: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: red mold
rarity: 1
resist:
  fire: 1
  poison: 1
size: small
sound: silent
speed: 0
weight: 50
---
_corpse:
  poison: 1
ac: 7
alignment: 0
always_hostile: 1
attacks: []
cannot_pickup_items: 1
color: magenta
corpse_nutrition: 100
glyph: F
hitdice: 3
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: shrieker
rarity: 1
resist:
  poison: 1
size: small
sound: shriek
speed: 1
weight: 100
---
_corpse:
  poison: 1
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: touch
    type: physical
  - damage: 0d0
    mode: touch
    type: stick
cannot_pickup_items: 1
color: magenta
corpse_nutrition: 100
glyph: F
hitdice: 3
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_genocidable: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: violet fungus
rarity: 2
resist:
  poison: 1
size: small
sound: silent
speed: 1
weight: 100
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: brown
corpse_nutrition: 100
glyph: G
has_infravision: 1
hitdice: 1
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_gnome: 1
is_herbivorous: 1
mr: 4
name: gnome
rarity: 1
resist: {}
size: small
small_group: 1
sound: orc
speed: 6
wants_wargear: 1
weight: 650
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
color: blue
corpse_nutrition: 120
glyph: G
has_infravision: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_genocidable: 1
is_gnome: 1
is_herbivorous: 1
is_rank_lord: 1
mr: 4
name: gnome lord
rarity: 2
resist: {}
size: small
sound: orc
speed: 8
wants_wargear: 1
weight: 700
---
_corpse: {}
ac: 4
alignment: 0
attacks:
  - damage: 0d0
    mode: magic
    type: wizardspell
color: bright_blue
corpse_nutrition: 120
glyph: G
has_infravision: 1
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_gnome: 1
is_herbivorous: 1
mr: 10
name: gnomish wizard
rarity: 1
resist: {}
size: small
sound: orc
speed: 10
wants_magic_items: 1
weight: 700
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 150
glyph: G
has_infravision: 1
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_genocidable: 1
is_gnome: 1
is_herbivorous: 1
is_rank_prince: 1
mr: 20
name: gnome king
rarity: 1
resist: {}
size: small
sound: orc
speed: 10
wants_wargear: 1
weight: 750
---
_corpse: {}
ac: 0
alignment: 2
attacks:
  - damage: 2d10
    mode: weapon
    type: physical
color: red
corpse_nutrition: 750
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_giant: 1
is_very_strong: 1
mr: 0
name: giant
not_randomly_generated: 1
rarity: 1
resist: {}
size: huge
sound: boast
speed: 6
throws_boulders: 1
wants_gems: 1
wants_wargear: 1
weight: 2250
---
_corpse: {}
ac: 0
alignment: 2
attacks:
  - damage: 2d10
    mode: weapon
    type: physical
color: gray
corpse_nutrition: 750
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_giant: 1
is_very_strong: 1
mr: 0
name: stone giant
rarity: 1
resist: {}
size: huge
small_group: 1
sound: boast
speed: 6
throws_boulders: 1
wants_gems: 1
wants_wargear: 1
weight: 2250
---
_corpse: {}
ac: 6
alignment: -2
attacks:
  - damage: 2d8
    mode: weapon
    type: physical
color: cyan
corpse_nutrition: 700
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 8
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_giant: 1
is_very_strong: 1
mr: 0
name: hill giant
rarity: 1
resist: {}
size: huge
small_group: 1
sound: boast
speed: 10
throws_boulders: 1
wants_gems: 1
wants_wargear: 1
weight: 2200
---
_corpse:
  fire: 1
ac: 4
alignment: 2
attacks:
  - damage: 2d10
    mode: weapon
    type: physical
color: yellow
corpse_nutrition: 750
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_giant: 1
is_very_strong: 1
mr: 5
name: fire giant
rarity: 1
resist:
  fire: 1
size: huge
small_group: 1
sound: boast
speed: 12
throws_boulders: 1
wants_gems: 1
wants_wargear: 1
weight: 2250
---
_corpse:
  cold: 1
absent_from_gehennom: 1
ac: 3
alignment: -3
attacks:
  - damage: 2d12
    mode: weapon
    type: physical
color: white
corpse_nutrition: 750
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_giant: 1
is_very_strong: 1
mr: 10
name: frost giant
rarity: 1
resist:
  cold: 1
size: huge
small_group: 1
sound: boast
speed: 12
throws_boulders: 1
wants_gems: 1
wants_wargear: 1
weight: 2250
---
_corpse:
  elec: 1
ac: 3
alignment: -3
attacks:
  - damage: 2d12
    mode: weapon
    type: physical
color: blue
corpse_nutrition: 750
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 16
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_giant: 1
is_very_strong: 1
mr: 10
name: storm giant
rarity: 1
resist:
  elec: 1
size: huge
small_group: 1
sound: boast
speed: 12
throws_boulders: 1
wants_gems: 1
wants_wargear: 1
weight: 2250
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d8
    mode: weapon
    type: physical
  - damage: 3d6
    mode: weapon
    type: physical
color: brown
corpse_nutrition: 500
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: ettin
rarity: 1
resist: {}
size: huge
sound: grunt
speed: 12
wants_wargear: 1
weight: 1700
---
_corpse: {}
ac: -3
alignment: 9
attacks:
  - damage: 2d8
    mode: weapon
    type: physical
  - damage: 0d0
    mode: magic
    type: wizardspell
can_fly: 1
color: magenta
corpse_nutrition: 900
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 16
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_herbivorous: 1
is_very_strong: 1
mr: 70
name: titan
rarity: 1
resist: {}
size: huge
sound: spell
speed: 18
throws_boulders: 1
wants_magic_items: 1
wants_wargear: 1
weight: 2300
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d10
    mode: claw
    type: physical
  - damage: 3d10
    mode: claw
    type: physical
  - damage: 2d8
    mode: headbutt
    type: physical
color: brown
corpse_nutrition: 700
extra_nasty: 1
glyph: H
has_infravision: 1
hitdice: 15
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: minotaur
not_randomly_generated: 1
resist: {}
size: large
sound: silent
speed: 15
weight: 1500
---
_corpse: {}
ac: -2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d10
    mode: bite
    type: physical
  - damage: 2d10
    mode: bite
    type: physical
  - damage: 2d10
    mode: claw
    type: physical
  - damage: 2d10
    mode: claw
    type: physical
can_fly: 1
color: orange
corpse_nutrition: 600
extra_nasty: 1
glyph: J
hitdice: 15
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 50
name: jabberwock
rarity: 1
resist: {}
size: large
sound: burble
speed: 12
wants_wargear: 1
weight: 1300
---
_corpse: {}
ac: 10
alignment: 9
always_hostile: 1
attacks:
  - damage: 1d4
    mode: weapon
    type: physical
color: blue
corpse_nutrition: 200
glyph: K
hitdice: 1
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_genocidable: 1
is_human: 1
is_wanderer: 1
large_group: 1
mr: 10
name: Keystone Kop
not_randomly_generated: 1
resist: {}
size: medium
sound: arrest
speed: 6
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 10
always_hostile: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: blue
corpse_nutrition: 200
glyph: K
hitdice: 2
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_genocidable: 1
is_human: 1
is_very_strong: 1
is_wanderer: 1
mr: 10
name: Kop Sergeant
not_randomly_generated: 1
resist: {}
size: medium
small_group: 1
sound: arrest
speed: 8
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 11
always_hostile: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
color: cyan
corpse_nutrition: 200
glyph: K
hitdice: 3
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_genocidable: 1
is_human: 1
is_very_strong: 1
is_wanderer: 1
mr: 20
name: Kop Lieutenant
not_randomly_generated: 1
resist: {}
size: medium
sound: arrest
speed: 10
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 12
always_hostile: 1
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 200
glyph: K
hitdice: 4
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_genocidable: 1
is_human: 1
is_very_strong: 1
is_wanderer: 1
mr: 20
name: Kop Kaptain
not_randomly_generated: 1
resist: {}
size: medium
sound: arrest
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse:
  cold: 1
ac: 0
alignment: -9
always_hostile: 1
attacks:
  - damage: 1d10
    mode: touch
    type: cold
  - damage: 0d0
    mode: magic
    type: wizardspell
color: brown
corpse_nutrition: 100
glyph: L
has_infravision: 1
hitdice: 11
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_undead: 1
mr: 30
name: lich
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
sound: mumble
speed: 6
wants_magic_items: 1
weight: 1200
---
_corpse:
  cold: 1
ac: -2
alignment: -12
always_hostile: 1
attacks:
  - damage: 3d4
    mode: touch
    type: cold
  - damage: 0d0
    mode: magic
    type: wizardspell
color: red
corpse_nutrition: 100
glyph: L
has_infravision: 1
hitdice: 14
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_undead: 1
mr: 60
name: demilich
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
sound: mumble
speed: 9
wants_magic_items: 1
weight: 1200
---
_corpse:
  cold: 1
  fire: 1
ac: -4
alignment: -15
always_hostile: 1
attacks:
  - damage: 3d6
    mode: touch
    type: cold
  - damage: 0d0
    mode: magic
    type: wizardspell
color: magenta
corpse_nutrition: 100
gehennom_exclusive: 1
glyph: L
has_infravision: 1
hitdice: 17
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_undead: 1
mr: 90
name: master lich
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  cold: 1
  fire: 1
  poison: 1
  sleep: 1
size: medium
sound: mumble
speed: 9
wants_book: 1
wants_magic_items: 1
weight: 1200
---
_corpse:
  cold: 1
  fire: 1
ac: -6
alignment: -15
always_hostile: 1
attacks:
  - damage: 5d6
    mode: touch
    type: cold
  - damage: 0d0
    mode: magic
    type: wizardspell
color: magenta
corpse_nutrition: 100
gehennom_exclusive: 1
glyph: L
has_infravision: 1
hitdice: 25
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_undead: 1
mr: 90
name: arch-lich
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
size: medium
sound: mumble
speed: 9
wants_book: 1
wants_magic_items: 1
weight: 1200
---
_corpse: {}
ac: 6
alignment: -2
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
color: brown
corpse_nutrition: 50
glyph: M
has_infravision: 1
hitdice: 3
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
mr: 20
name: kobold mummy
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: small
sound: silent
speed: 8
weight: 400
---
_corpse: {}
ac: 6
alignment: -3
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
color: red
corpse_nutrition: 50
glyph: M
has_infravision: 1
hitdice: 4
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_gnome: 1
is_mindless: 1
is_undead: 1
mr: 20
name: gnome mummy
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: small
sound: silent
speed: 10
weight: 650
---
_corpse: {}
ac: 5
alignment: -4
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
color: gray
corpse_nutrition: 75
glyph: M
has_infravision: 1
hitdice: 5
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_orc: 1
is_undead: 1
mr: 20
name: orc mummy
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
sound: silent
speed: 10
wants_gems: 1
wants_gold: 1
weight: 850
---
_corpse: {}
ac: 5
alignment: -4
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
color: red
corpse_nutrition: 150
glyph: M
has_infravision: 1
hitdice: 5
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_dwarf: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
mr: 20
name: dwarf mummy
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
sound: silent
speed: 10
wants_gems: 1
wants_gold: 1
weight: 900
---
_corpse: {}
ac: 4
alignment: -5
always_hostile: 1
attacks:
  - damage: 2d4
    mode: claw
    type: physical
color: green
corpse_nutrition: 175
glyph: M
has_infravision: 1
hitdice: 6
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_elf: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
mr: 30
name: elf mummy
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
sound: silent
speed: 12
weight: 800
---
_corpse: {}
ac: 4
alignment: -5
always_hostile: 1
attacks:
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: claw
    type: physical
color: gray
corpse_nutrition: 200
glyph: M
has_infravision: 1
hitdice: 6
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
mr: 30
name: human mummy
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
sound: silent
speed: 12
weight: 1450
---
_corpse: {}
ac: 4
alignment: -6
always_hostile: 1
attacks:
  - damage: 2d6
    mode: claw
    type: physical
  - damage: 2d6
    mode: claw
    type: physical
color: blue
corpse_nutrition: 250
glyph: M
has_infravision: 1
hitdice: 7
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
is_very_strong: 1
mr: 30
name: ettin mummy
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: huge
sound: silent
speed: 12
weight: 1700
---
_corpse: {}
ac: 3
alignment: -7
always_hostile: 1
attacks:
  - damage: 3d4
    mode: claw
    type: physical
  - damage: 3d4
    mode: claw
    type: physical
color: cyan
corpse_nutrition: 375
glyph: M
has_infravision: 1
hitdice: 8
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_giant: 1
is_mindless: 1
is_undead: 1
is_very_strong: 1
mr: 30
name: giant mummy
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: huge
sound: silent
speed: 14
wants_gems: 1
weight: 2050
---
_corpse:
  fire: 1
  poison: 1
ac: 6
alignment: 0
attacks:
  - damage: 1d4
    mode: bite
    type: physical
cannot_pickup_items: 1
color: red
corpse_nutrition: 100
glyph: N
has_thick_hide: 1
hitdice: 3
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_limbs: 1
mr: 0
name: red naga hatchling
resist:
  fire: 1
  poison: 1
serpentine_body: 1
size: large
sound: mumble
speed: 10
weight: 500
---
_corpse:
  poison: 1
  stone: 1
ac: 6
acidic_corpse: 1
alignment: 0
attacks:
  - damage: 1d4
    mode: bite
    type: physical
cannot_pickup_items: 1
color: black
corpse_nutrition: 100
glyph: N
has_thick_hide: 1
hitdice: 3
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_limbs: 1
mr: 0
name: black naga hatchling
resist:
  acid: 1
  poison: 1
  stone: 1
serpentine_body: 1
size: large
sound: mumble
speed: 10
weight: 500
---
_corpse:
  poison: 1
ac: 6
alignment: 0
attacks:
  - damage: 1d4
    mode: bite
    type: physical
cannot_pickup_items: 1
color: yellow
corpse_nutrition: 100
glyph: N
has_thick_hide: 1
hitdice: 3
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_limbs: 1
mr: 0
name: golden naga hatchling
resist:
  poison: 1
serpentine_body: 1
size: large
sound: mumble
speed: 10
weight: 500
---
_corpse:
  poison: 1
ac: 6
alignment: 0
attacks:
  - damage: 1d4
    mode: bite
    type: physical
cannot_pickup_items: 1
color: green
corpse_nutrition: 100
glyph: N
has_thick_hide: 1
hitdice: 3
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_limbs: 1
mr: 0
name: guardian naga hatchling
resist:
  poison: 1
serpentine_body: 1
size: large
sound: mumble
speed: 10
weight: 500
---
_corpse:
  fire: 1
  poison: 1
ac: 4
alignment: -4
attacks:
  - damage: 2d4
    mode: bite
    type: physical
  - damage: 2d6
    mode: breathe
    type: fire
cannot_pickup_items: 1
color: red
corpse_nutrition: 400
glyph: N
has_thick_hide: 1
hitdice: 6
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: red naga
rarity: 1
resist:
  fire: 1
  poison: 1
serpentine_body: 1
size: huge
sound: mumble
speed: 12
weight: 2600
---
_corpse:
  poison: 1
  stone: 1
ac: 2
acidic_corpse: 1
alignment: 4
attacks:
  - damage: 2d6
    mode: bite
    type: physical
  - damage: 0d0
    mode: spit
    type: acid
cannot_pickup_items: 1
color: black
corpse_nutrition: 400
glyph: N
has_thick_hide: 1
hitdice: 8
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_limbs: 1
lays_eggs: 1
mr: 10
name: black naga
rarity: 1
resist:
  acid: 1
  poison: 1
  stone: 1
serpentine_body: 1
size: huge
sound: mumble
speed: 14
weight: 2600
---
_corpse:
  poison: 1
ac: 2
alignment: 5
attacks:
  - damage: 2d6
    mode: bite
    type: physical
  - damage: 4d6
    mode: magic
    type: wizardspell
cannot_pickup_items: 1
color: yellow
corpse_nutrition: 400
glyph: N
has_thick_hide: 1
hitdice: 10
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_limbs: 1
lays_eggs: 1
mr: 70
name: golden naga
rarity: 1
resist:
  poison: 1
serpentine_body: 1
size: huge
sound: mumble
speed: 14
weight: 2600
---
_corpse:
  poison: 1
ac: 0
alignment: 7
attacks:
  - damage: 1d6
    mode: bite
    type: paralyze
  - damage: 1d6
    mode: spit
    type: poison
  - damage: 2d4
    mode: crush
    type: physical
cannot_pickup_items: 1
color: green
corpse_nutrition: 400
glyph: N
has_thick_hide: 1
hitdice: 12
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
lacks_limbs: 1
lays_eggs: 1
mr: 50
name: guardian naga
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
serpentine_body: 1
size: huge
sound: mumble
speed: 16
weight: 2600
---
_corpse: {}
ac: 5
alignment: -3
attacks:
  - damage: 2d5
    mode: weapon
    type: physical
color: brown
corpse_nutrition: 500
glyph: O
has_infravision: 1
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: ogre
rarity: 1
resist: {}
size: large
small_group: 1
sound: grunt
speed: 10
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1600
---
_corpse: {}
ac: 3
alignment: -5
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
color: red
corpse_nutrition: 700
glyph: O
has_infravision: 1
hitdice: 7
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_genocidable: 1
is_rank_lord: 1
is_very_strong: 1
mr: 30
name: ogre lord
rarity: 2
resist: {}
size: large
sound: grunt
speed: 12
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1700
---
_corpse: {}
ac: 4
alignment: -7
attacks:
  - damage: 3d5
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 750
glyph: O
has_infravision: 1
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_genocidable: 1
is_rank_prince: 1
is_very_strong: 1
mr: 60
name: ogre king
rarity: 2
resist: {}
size: large
sound: grunt
speed: 14
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1700
---
_corpse:
  cold: 1
  fire: 1
  poison: 1
ac: 8
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d8
    mode: bite
    type: rust
color: gray
corpse_nutrition: 250
glyph: P
hitdice: 3
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_carnivorous: 1
is_genderless: 1
is_genocidable: 1
is_herbivorous: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: gray ooze
rarity: 2
resist:
  acid: 1
  cold: 1
  fire: 1
  poison: 1
  stone: 1
size: medium
sound: silent
speed: 1
weight: 500
---
_corpse:
  cold: 1
  elec: 1
  poison: 1
ac: 8
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d0
    mode: bite
    type: decay
color: brown
corpse_nutrition: 250
glyph: P
hitdice: 5
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_carnivorous: 1
is_genderless: 1
is_genocidable: 1
is_herbivorous: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: brown pudding
rarity: 1
resist:
  acid: 1
  cold: 1
  elec: 1
  poison: 1
  stone: 1
size: medium
sound: silent
speed: 3
weight: 500
---
_corpse:
  cold: 1
  elec: 1
  poison: 1
ac: 6
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d8
    mode: bite
    type: corrode
  - damage: 0d0
    mode: passive
    type: corrode
color: black
corpse_nutrition: 250
glyph: P
hitdice: 10
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_carnivorous: 1
is_genderless: 1
is_genocidable: 1
is_herbivorous: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: black pudding
rarity: 1
resist:
  acid: 1
  cold: 1
  elec: 1
  poison: 1
  stone: 1
size: large
sound: silent
speed: 6
weight: 900
---
_corpse: {}
ac: 6
acidic_corpse: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: touch
    type: slime
  - damage: 0d0
    mode: passive
    type: slime
color: green
corpse_nutrition: 150
gehennom_exclusive: 1
glyph: P
hitdice: 6
is_amorphous: 1
is_amphibious: 1
is_breathless: 1
is_carnivorous: 1
is_genderless: 1
is_genocidable: 1
is_herbivorous: 1
is_mindless: 1
lacks_eyes: 1
lacks_head: 1
lacks_limbs: 1
mr: 0
name: green slime
poisonous_corpse: 1
rarity: 1
resist:
  acid: 1
  cold: 1
  elec: 1
  poison: 1
  stone: 1
size: large
sound: silent
speed: 6
weight: 400
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: teleport
color: cyan
corpse_nutrition: 20
glyph: Q
has_teleportitis: 1
hitdice: 7
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
mr: 10
name: quantum mechanic
poisonous_corpse: 1
rarity: 3
resist:
  poison: 1
size: medium
sound: humanoid
speed: 12
weight: 1450
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 0d0
    mode: touch
    type: rust
  - damage: 0d0
    mode: touch
    type: rust
  - damage: 0d0
    mode: passive
    type: rust
can_eat_metal: 1
can_swim: 1
color: brown
corpse_nutrition: 250
glyph: R
hitdice: 5
infravision_detectable: 1
is_animal: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: rust monster
rarity: 2
resist: {}
size: medium
sound: silent
speed: 18
weight: 1000
---
_corpse: {}
ac: -10
alignment: -3
always_hostile: 1
attacks:
  - damage: 4d4
    mode: claw
    type: disenchant
  - damage: 0d0
    mode: passive
    type: disenchant
color: blue
corpse_nutrition: 200
gehennom_exclusive: 1
glyph: R
hitdice: 12
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
mr: 0
name: disenchanter
rarity: 2
resist: {}
size: large
sound: growl
speed: 12
weight: 750
---
_corpse: {}
ac: 8
alignment: 0
attacks:
  - damage: 1d2
    mode: bite
    type: physical
can_swim: 1
cannot_pickup_items: 1
color: green
corpse_nutrition: 60
glyph: S
hides_under_item: 1
hitdice: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
large_group: 1
lays_eggs: 1
mr: 0
name: garter snake
rarity: 1
resist: {}
serpentine_body: 1
size: tiny
sound: hiss
speed: 8
weight: 50
---
_corpse:
  poison: 1
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: poison
can_swim: 1
cannot_pickup_items: 1
color: brown
corpse_nutrition: 80
glyph: S
hides_under_item: 1
hitdice: 4
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: snake
poisonous_corpse: 1
rarity: 2
resist:
  poison: 1
serpentine_body: 1
size: small
sound: hiss
speed: 15
weight: 100
---
_corpse:
  poison: 1
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: poison
can_swim: 1
cannot_pickup_items: 1
color: red
corpse_nutrition: 80
glyph: S
hides_under_item: 1
hitdice: 4
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
large_group: 1
lays_eggs: 1
mr: 0
name: water moccasin
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  poison: 1
serpentine_body: 1
size: small
sound: hiss
speed: 15
weight: 150
---
_corpse:
  poison: 1
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: poison
  - damage: 1d4
    mode: bite
    type: poison
can_swim: 1
cannot_pickup_items: 1
color: blue
corpse_nutrition: 60
glyph: S
has_infravision: 1
hides_under_item: 1
hitdice: 6
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: pit viper
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
serpentine_body: 1
size: medium
sound: hiss
speed: 15
weight: 100
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: physical
  - damage: 0d0
    mode: touch
    type: physical
  - damage: 1d4
    mode: crush
    type: wrap
  - damage: 2d4
    mode: crush
    type: physical
can_swim: 1
cannot_pickup_items: 1
color: magenta
corpse_nutrition: 100
glyph: S
has_infravision: 1
hitdice: 6
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: python
rarity: 1
resist: {}
serpentine_body: 1
size: large
sound: hiss
speed: 3
weight: 250
---
_corpse:
  poison: 1
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d4
    mode: bite
    type: poison
  - damage: 0d0
    mode: spit
    type: blind
can_swim: 1
cannot_pickup_items: 1
color: blue
corpse_nutrition: 100
glyph: S
hides_under_item: 1
hitdice: 6
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: cobra
poisonous_corpse: 1
rarity: 1
resist:
  poison: 1
serpentine_body: 1
size: medium
sound: hiss
speed: 18
weight: 250
---
_corpse: {}
ac: 4
alignment: -3
always_hostile: 1
attacks:
  - damage: 4d2
    mode: weapon
    type: physical
  - damage: 4d2
    mode: claw
    type: physical
  - damage: 2d6
    mode: bite
    type: physical
color: brown
corpse_nutrition: 350
follows_stair_users: 1
glyph: T
has_infravision: 1
hitdice: 7
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: troll
rarity: 2
regenerates_quickly: 1
resist: {}
size: large
sound: grunt
speed: 12
wants_wargear: 1
weight: 800
---
_corpse:
  cold: 1
absent_from_gehennom: 1
ac: 2
alignment: -3
always_hostile: 1
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
  - damage: 2d6
    mode: claw
    type: cold
  - damage: 2d6
    mode: bite
    type: physical
color: white
corpse_nutrition: 300
follows_stair_users: 1
glyph: T
has_infravision: 1
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 20
name: ice troll
rarity: 1
regenerates_quickly: 1
resist:
  cold: 1
size: large
sound: grunt
speed: 10
wants_wargear: 1
weight: 1000
---
_corpse: {}
ac: 0
alignment: -3
always_hostile: 1
attacks:
  - damage: 3d6
    mode: weapon
    type: physical
  - damage: 2d8
    mode: claw
    type: physical
  - damage: 2d6
    mode: bite
    type: physical
color: cyan
corpse_nutrition: 300
follows_stair_users: 1
glyph: T
has_infravision: 1
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: rock troll
rarity: 1
regenerates_quickly: 1
resist: {}
size: large
sound: grunt
speed: 12
wants_wargear: 1
weight: 1200
---
_corpse: {}
ac: 4
alignment: -3
always_hostile: 1
attacks:
  - damage: 2d8
    mode: weapon
    type: physical
  - damage: 2d8
    mode: claw
    type: physical
  - damage: 2d6
    mode: bite
    type: physical
can_swim: 1
color: blue
corpse_nutrition: 350
follows_stair_users: 1
glyph: T
has_infravision: 1
hitdice: 11
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 40
name: water troll
not_randomly_generated: 1
regenerates_quickly: 1
resist: {}
size: large
sound: grunt
speed: 14
wants_wargear: 1
weight: 1200
---
_corpse: {}
ac: -4
alignment: -7
always_hostile: 1
attacks:
  - damage: 3d6
    mode: weapon
    type: physical
  - damage: 2d8
    mode: claw
    type: physical
  - damage: 2d6
    mode: bite
    type: physical
color: magenta
corpse_nutrition: 400
follows_stair_users: 1
glyph: T
has_infravision: 1
hitdice: 13
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: Olog-hai
rarity: 1
regenerates_quickly: 1
resist: {}
size: large
sound: grunt
speed: 12
wants_wargear: 1
weight: 1500
---
_corpse: {}
ac: 2
alignment: 0
attacks:
  - damage: 3d4
    mode: claw
    type: physical
  - damage: 3d4
    mode: claw
    type: physical
  - damage: 2d5
    mode: bite
    type: physical
  - damage: 0d0
    mode: gaze
    type: conf
can_eat_rock: 1
color: brown
corpse_nutrition: 500
glyph: U
hitdice: 9
infravision_detectable: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 25
name: umber hulk
rarity: 2
resist: {}
size: large
sound: silent
speed: 6
weight: 1200
---
_corpse: {}
ac: 1
alignment: -8
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d6
    mode: bite
    type: drain
can_fly: 1
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: V
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_undead: 1
is_very_strong: 1
mr: 25
name: vampire
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  poison: 1
  sleep: 1
size: medium
sound: vampire
speed: 12
weight: 1450
---
_corpse: {}
ac: 0
alignment: -9
always_hostile: 1
attacks:
  - damage: 1d8
    mode: claw
    type: physical
  - damage: 1d8
    mode: bite
    type: drain
can_fly: 1
color: blue
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: V
hitdice: 12
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_rank_lord: 1
is_undead: 1
is_very_strong: 1
mr: 50
name: vampire lord
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  poison: 1
  sleep: 1
size: medium
sound: vampire
speed: 14
weight: 1450
---
_corpse: {}
ac: -3
alignment: -10
always_hostile: 1
attacks:
  - damage: 1d10
    mode: weapon
    type: physical
  - damage: 1d10
    mode: bite
    type: drain
can_fly: 1
color: magenta
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: V
has_proper_name: 1
hitdice: 14
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_amphibious: 1
is_breathless: 1
is_rank_prince: 1
is_undead: 1
is_unique: 1
is_very_strong: 1
mr: 80
name: Vlad the Impaler
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
regenerates_quickly: 1
resist:
  poison: 1
  sleep: 1
size: medium
sound: vampire
speed: 18
wants_candelabrum: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 5
alignment: -3
always_hostile: 1
attacks:
  - damage: 0d0
    mode: weapon
    type: drain
  - damage: 0d0
    mode: magic
    type: wizardspell
  - damage: 1d4
    mode: claw
    type: physical
color: gray
follows_stair_users: 1
glyph: W
hitdice: 3
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_undead: 1
mr: 5
name: barrow wight
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
sound: spell
speed: 12
wants_wargear: 1
weight: 1200
---
_corpse: {}
ac: 4
alignment: -6
always_hostile: 1
attacks:
  - damage: 1d6
    mode: touch
    type: drain
can_fly: 1
color: black
follows_stair_users: 1
glyph: W
hitdice: 6
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_undead: 1
made_of_gas: 1
mr: 15
name: wraith
nutrition: 0
rarity: 2
resist:
  cold: 1
  poison: 1
  sleep: 1
  stone: 1
size: medium
sound: silent
speed: 12
weight: 0
---
_corpse: {}
ac: 0
alignment: -17
always_hostile: 1
attacks:
  - damage: 1d4
    mode: weapon
    type: drain
  - damage: 2d25
    mode: breathe
    type: sleep
color: magenta
follows_stair_users: 1
glyph: W
hitdice: 13
humanoid_body: 1
invalid_polymorph_target: 1
is_always_male: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_undead: 1
is_very_strong: 1
mr: 25
name: Nazgul
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
sound: spell
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse:
  stone: 1
ac: -2
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 4d6
    mode: bite
    type: physical
can_eat_metal: 1
color: brown
corpse_nutrition: 700
glyph: X
has_thick_hide: 1
hitdice: 8
ignores_walls: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_very_strong: 1
mr: 20
name: xorn
rarity: 1
resist:
  cold: 1
  fire: 1
  stone: 1
size: medium
sound: roar
speed: 9
weight: 1200
---
_corpse: {}
ac: 6
alignment: 0
attacks:
  - damage: 0d0
    mode: claw
    type: stealitem
  - damage: 1d3
    mode: bite
    type: physical
color: gray
corpse_nutrition: 50
glyph: Y
hitdice: 2
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
mr: 0
name: monkey
rarity: 1
resist: {}
size: small
sound: growl
speed: 12
weight: 100
---
_corpse: {}
ac: 6
alignment: 0
attacks:
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d6
    mode: bite
    type: physical
color: brown
corpse_nutrition: 500
glyph: Y
hitdice: 4
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: ape
rarity: 2
resist: {}
size: large
small_group: 1
sound: growl
speed: 12
weight: 1100
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 2d8
    mode: crush
    type: physical
color: brown
corpse_nutrition: 700
extra_nasty: 1
glyph: Y
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: owlbear
rarity: 3
resist: {}
size: large
sound: roar
speed: 12
weight: 1700
---
_corpse:
  cold: 1
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d4
    mode: bite
    type: physical
color: white
corpse_nutrition: 700
glyph: Y
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: yeti
rarity: 2
resist:
  cold: 1
size: large
sound: growl
speed: 15
weight: 1600
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d8
    mode: crush
    type: physical
color: black
corpse_nutrition: 550
glyph: Y
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
mr: 0
name: carnivorous ape
rarity: 1
resist: {}
size: large
sound: growl
speed: 12
weight: 1250
---
_corpse: {}
ac: 6
alignment: 2
attacks:
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d8
    mode: kick
    type: physical
color: gray
corpse_nutrition: 750
glyph: Y
hitdice: 7
humanoid_body: 1
infravision_detectable: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_very_strong: 1
mr: 0
name: sasquatch
rarity: 1
resist: {}
sees_invisible: 1
size: large
sound: growl
speed: 15
weight: 1550
---
_corpse: {}
ac: 10
alignment: -2
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
color: brown
corpse_nutrition: 50
follows_stair_users: 1
glyph: Z
has_infravision: 1
hitdice: 0
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
mr: 0
name: kobold zombie
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: small
sound: silent
speed: 6
weight: 400
---
_corpse: {}
ac: 10
alignment: -2
always_hostile: 1
attacks:
  - damage: 1d5
    mode: claw
    type: physical
color: brown
corpse_nutrition: 50
follows_stair_users: 1
glyph: Z
has_infravision: 1
hitdice: 1
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_gnome: 1
is_mindless: 1
is_undead: 1
mr: 0
name: gnome zombie
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: small
sound: silent
speed: 6
weight: 650
---
_corpse: {}
ac: 9
alignment: -3
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
color: gray
corpse_nutrition: 75
follows_stair_users: 1
glyph: Z
has_infravision: 1
hitdice: 2
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_orc: 1
is_undead: 1
mr: 0
name: orc zombie
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
small_group: 1
sound: silent
speed: 6
weight: 850
---
_corpse: {}
ac: 9
alignment: -3
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
color: red
corpse_nutrition: 150
follows_stair_users: 1
glyph: Z
has_infravision: 1
hitdice: 2
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_dwarf: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
mr: 0
name: dwarf zombie
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
small_group: 1
sound: silent
speed: 6
weight: 900
---
_corpse: {}
ac: 9
alignment: -3
always_hostile: 1
attacks:
  - damage: 1d7
    mode: claw
    type: physical
color: green
corpse_nutrition: 175
follows_stair_users: 1
glyph: Z
has_infravision: 1
hitdice: 3
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_elf: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
mr: 0
name: elf zombie
never_drops_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
small_group: 1
sound: silent
speed: 6
weight: 800
---
_corpse: {}
ac: 8
alignment: -3
always_hostile: 1
attacks:
  - damage: 1d8
    mode: claw
    type: physical
color: white
corpse_nutrition: 200
follows_stair_users: 1
glyph: Z
has_infravision: 1
hitdice: 4
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
mr: 0
name: human zombie
never_drops_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: medium
small_group: 1
sound: silent
speed: 6
weight: 1450
---
_corpse: {}
ac: 6
alignment: -4
always_hostile: 1
attacks:
  - damage: 1d10
    mode: claw
    type: physical
  - damage: 1d10
    mode: claw
    type: physical
color: blue
corpse_nutrition: 250
follows_stair_users: 1
glyph: Z
has_infravision: 1
hitdice: 6
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
is_very_strong: 1
mr: 0
name: ettin zombie
never_drops_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: huge
sound: silent
speed: 8
weight: 1700
---
_corpse: {}
ac: 6
alignment: -4
always_hostile: 1
attacks:
  - damage: 2d8
    mode: claw
    type: physical
  - damage: 2d8
    mode: claw
    type: physical
color: cyan
corpse_nutrition: 375
follows_stair_users: 1
glyph: Z
has_infravision: 1
hitdice: 8
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_giant: 1
is_mindless: 1
is_undead: 1
is_very_strong: 1
mr: 0
name: giant zombie
never_drops_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: huge
sound: silent
speed: 8
weight: 2050
---
_corpse: {}
ac: 10
alignment: -2
always_hostile: 1
attacks:
  - damage: 1d2
    mode: claw
    type: paralyze
  - damage: 1d3
    mode: claw
    type: physical
color: black
corpse_nutrition: 50
glyph: Z
has_infravision: 1
hitdice: 3
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genocidable: 1
is_mindless: 1
is_undead: 1
is_wanderer: 1
mr: 0
name: ghoul
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
size: small
sound: silent
speed: 6
weight: 400
---
_corpse: {}
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: touch
    type: slow
color: white
corpse_nutrition: 5
extra_nasty: 1
glyph: Z
has_infravision: 1
has_thick_hide: 1
hitdice: 12
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_mindless: 1
is_undead: 1
is_very_strong: 1
is_wanderer: 1
mr: 0
name: skeleton
never_drops_corpse: 1
not_randomly_generated: 1
resist:
  cold: 1
  poison: 1
  sleep: 1
  stone: 1
size: medium
sound: bones
speed: 8
wants_wargear: 1
weight: 300
---
_corpse: {}
ac: 10
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d2
    mode: claw
    type: physical
  - damage: 1d2
    mode: claw
    type: physical
color: yellow
glyph: "'"
hitdice: 3
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_mindless: 1
mr: 0
name: straw golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 12
weight: 400
---
_corpse: {}
ac: 10
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: claw
    type: physical
color: white
glyph: "'"
hitdice: 3
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_mindless: 1
mr: 0
name: paper golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 12
weight: 400
---
_corpse: {}
ac: 8
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 6d1
    mode: crush
    type: physical
color: brown
glyph: "'"
hitdice: 4
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_mindless: 1
mr: 0
name: rope golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 9
weight: 450
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d3
    mode: claw
    type: physical
  - damage: 2d3
    mode: claw
    type: physical
color: yellow
glyph: "'"
has_thick_hide: 1
hitdice: 5
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_mindless: 1
mr: 0
name: gold golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  acid: 1
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 9
weight: 450
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: claw
    type: physical
  - damage: 1d6
    mode: claw
    type: physical
color: brown
glyph: "'"
hitdice: 6
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_mindless: 1
mr: 0
name: leather golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 6
weight: 800
---
_corpse: {}
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d4
    mode: claw
    type: physical
color: brown
glyph: "'"
has_thick_hide: 1
hitdice: 7
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_genderless: 1
is_mindless: 1
mr: 0
name: wood golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 3
weight: 900
---
_corpse:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
ac: 9
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d8
    mode: claw
    type: physical
  - damage: 2d8
    mode: claw
    type: physical
color: red
corpse_nutrition: 600
glyph: "'"
hitdice: 9
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_mindless: 1
is_very_strong: 1
mr: 30
name: flesh golem
rarity: 1
resist:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 8
weight: 1400
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d10
    mode: claw
    type: physical
color: brown
glyph: "'"
has_thick_hide: 1
hitdice: 11
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_mindless: 1
is_very_strong: 1
mr: 40
name: clay golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 7
weight: 1550
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d8
    mode: claw
    type: physical
color: gray
glyph: "'"
has_thick_hide: 1
hitdice: 14
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_mindless: 1
is_very_strong: 1
mr: 50
name: stone golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  poison: 1
  sleep: 1
  stone: 1
size: large
sound: silent
speed: 6
weight: 1900
---
_corpse: {}
ac: 1
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d8
    mode: claw
    type: physical
  - damage: 2d8
    mode: claw
    type: physical
color: cyan
glyph: "'"
has_thick_hide: 1
hitdice: 16
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_mindless: 1
is_very_strong: 1
mr: 50
name: glass golem
never_drops_corpse: 1
nutrition: 0
rarity: 1
resist:
  acid: 1
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 6
weight: 1800
---
_corpse: {}
ac: 3
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d10
    mode: weapon
    type: physical
  - damage: 4d6
    mode: breathe
    type: poison
color: cyan
glyph: "'"
has_thick_hide: 1
hitdice: 18
humanoid_body: 1
is_amphibious: 1
is_breathless: 1
is_mindless: 1
is_very_strong: 1
mr: 60
name: iron golem
never_drops_corpse: 1
nutrition: 0
poisonous_corpse: 1
rarity: 1
resist:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
size: large
sound: silent
speed: 6
wants_wargear: 1
weight: 2000
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 0
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 0
name: human
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -7
always_hostile: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: brown
corpse_nutrition: 400
glyph: '@'
hitdice: 2
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_lycanthrope: 1
mr: 10
name: wererat
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  poison: 1
size: medium
sound: were
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -7
always_hostile: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: red
corpse_nutrition: 400
glyph: '@'
hitdice: 2
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_lycanthrope: 1
mr: 10
name: werejackal
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  poison: 1
size: medium
sound: were
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -7
always_hostile: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: orange
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_lycanthrope: 1
mr: 20
name: werewolf
poisonous_corpse: 1
rarity: 1
regenerates_quickly: 1
resist:
  poison: 1
size: medium
sound: were
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse:
  sleep: 1
ac: 10
alignment: -3
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
color: white
corpse_nutrition: 350
glyph: '@'
has_infravision: 1
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_elf: 1
is_herbivorous: 1
is_very_strong: 1
mr: 2
name: elf
not_randomly_generated: 1
resist:
  sleep: 1
sees_invisible: 1
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 800
---
_corpse:
  sleep: 1
ac: 10
alignment: -5
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: green
corpse_nutrition: 350
glyph: '@'
has_infravision: 1
hitdice: 4
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_elf: 1
is_genocidable: 1
is_herbivorous: 1
mr: 10
name: Woodland-elf
rarity: 2
resist:
  sleep: 1
sees_invisible: 1
size: medium
small_group: 1
sound: humanoid
speed: 12
wants_wargear: 1
weight: 800
---
_corpse:
  sleep: 1
ac: 10
alignment: -6
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: bright_green
corpse_nutrition: 350
glyph: '@'
has_infravision: 1
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_elf: 1
is_genocidable: 1
is_herbivorous: 1
mr: 10
name: Green-elf
rarity: 2
resist:
  sleep: 1
sees_invisible: 1
size: medium
small_group: 1
sound: humanoid
speed: 12
wants_wargear: 1
weight: 800
---
_corpse:
  sleep: 1
ac: 10
alignment: -7
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: gray
corpse_nutrition: 350
glyph: '@'
has_infravision: 1
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
is_carnivorous: 1
is_elf: 1
is_genocidable: 1
is_herbivorous: 1
mr: 10
name: Grey-elf
rarity: 2
resist:
  sleep: 1
sees_invisible: 1
size: medium
small_group: 1
sound: humanoid
speed: 12
wants_wargear: 1
weight: 800
---
_corpse:
  sleep: 1
ac: 10
alignment: -9
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 2d4
    mode: weapon
    type: physical
color: bright_blue
corpse_nutrition: 350
glyph: '@'
has_infravision: 1
hitdice: 8
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_elf: 1
is_genocidable: 1
is_herbivorous: 1
is_rank_lord: 1
is_very_strong: 1
mr: 20
name: elf-lord
rarity: 2
resist:
  sleep: 1
sees_invisible: 1
size: medium
small_group: 1
sound: humanoid
speed: 12
wants_wargear: 1
weight: 800
---
_corpse:
  sleep: 1
ac: 10
alignment: -10
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 2d4
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 350
glyph: '@'
has_infravision: 1
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_carnivorous: 1
is_elf: 1
is_genocidable: 1
is_herbivorous: 1
is_rank_prince: 1
is_very_strong: 1
mr: 25
name: Elvenking
rarity: 1
resist:
  sleep: 1
sees_invisible: 1
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 800
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d12
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 20
name: doppelganger
rarity: 1
resist:
  sleep: 1
size: medium
sound: imitate
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse:
  poison: 1
ac: 0
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: claw
    type: heal
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 11
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_human: 1
mr: 0
name: nurse
rarity: 3
resist:
  poison: 1
size: medium
sound: nurse
speed: 6
weight: 1450
---
_corpse: {}
ac: 0
alignment: 0
always_peaceful: 1
attacks:
  - damage: 4d4
    mode: weapon
    type: physical
  - damage: 4d4
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 12
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 50
name: shopkeeper
not_randomly_generated: 1
resist: {}
size: medium
sound: sell
speed: 18
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 10
always_peaceful: 1
attacks:
  - damage: 4d10
    mode: weapon
    type: physical
color: blue
corpse_nutrition: 400
glyph: '@'
hitdice: 12
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_mercenary: 1
is_very_strong: 1
mr: 40
name: guard
not_randomly_generated: 1
resist: {}
size: medium
sound: guard
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 12
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 0
name: prisoner
not_randomly_generated: 1
resist: {}
size: medium
sound: djinni
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 0
always_peaceful: 1
attacks:
  - damage: 0d4
    mode: passive
    type: magicmissile
color: bright_blue
corpse_nutrition: 400
glyph: '@'
hitdice: 12
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
mr: 50
name: Oracle
not_randomly_generated: 1
resist: {}
size: medium
sound: oracle
speed: 0
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks:
  - damage: 4d10
    mode: weapon
    type: physical
  - damage: 1d4
    mode: kick
    type: physical
  - damage: 0d0
    mode: magic
    type: clericalspell
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 12
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_rank_lord: 1
mr: 50
name: aligned priest
not_randomly_generated: 1
resist:
  elec: 1
size: medium
sound: priest
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 7
alignment: 0
attacks:
  - damage: 4d10
    mode: weapon
    type: physical
  - damage: 2d8
    mode: kick
    type: physical
  - damage: 2d8
    mode: magic
    type: clericalspell
  - damage: 2d8
    mode: magic
    type: clericalspell
color: white
corpse_nutrition: 400
extra_nasty: 1
glyph: '@'
hitdice: 25
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_minion: 1
is_rank_prince: 1
is_unique: 1
mr: 70
name: high priest
not_randomly_generated: 1
resist:
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
sees_invisible: 1
size: medium
sound: priest
speed: 15
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -2
always_hostile: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
color: gray
corpse_nutrition: 400
follows_stair_users: 1
glyph: '@'
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_human: 1
is_mercenary: 1
is_very_strong: 1
mr: 0
name: soldier
rarity: 1
resist: {}
size: medium
small_group: 1
sound: soldier
speed: 10
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -3
always_hostile: 1
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
color: red
corpse_nutrition: 400
follows_stair_users: 1
glyph: '@'
hitdice: 8
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_human: 1
is_mercenary: 1
is_very_strong: 1
mr: 5
name: sergeant
rarity: 1
resist: {}
size: medium
small_group: 1
sound: soldier
speed: 10
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -4
always_hostile: 1
attacks:
  - damage: 3d4
    mode: weapon
    type: physical
  - damage: 3d4
    mode: weapon
    type: physical
color: green
corpse_nutrition: 400
follows_stair_users: 1
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_human: 1
is_mercenary: 1
is_very_strong: 1
mr: 15
name: lieutenant
rarity: 1
resist: {}
size: medium
sound: soldier
speed: 10
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -5
always_hostile: 1
attacks:
  - damage: 4d4
    mode: weapon
    type: physical
  - damage: 4d4
    mode: weapon
    type: physical
color: blue
corpse_nutrition: 400
follows_stair_users: 1
glyph: '@'
hitdice: 12
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_human: 1
is_mercenary: 1
is_very_strong: 1
mr: 15
name: captain
rarity: 1
resist: {}
size: medium
sound: soldier
speed: 10
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -2
always_peaceful: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
color: gray
corpse_nutrition: 400
follows_stair_users: 1
glyph: '@'
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_human: 1
is_mercenary: 1
is_very_strong: 1
mr: 0
name: watchman
not_randomly_generated: 1
rarity: 1
resist: {}
size: medium
small_group: 1
sound: soldier
speed: 10
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -4
always_peaceful: 1
attacks:
  - damage: 3d4
    mode: weapon
    type: physical
  - damage: 3d4
    mode: weapon
    type: physical
color: green
corpse_nutrition: 400
follows_stair_users: 1
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_genocidable: 1
is_herbivorous: 1
is_human: 1
is_mercenary: 1
is_very_strong: 1
mr: 15
name: watch captain
not_randomly_generated: 1
rarity: 1
resist: {}
size: medium
sound: soldier
speed: 10
wants_wargear: 1
weight: 1450
---
_corpse:
  poison: 1
  stone: 1
ac: 2
alignment: -15
always_hostile: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 1d8
    mode: claw
    type: physical
  - damage: 0d0
    mode: gaze
    type: petrify
  - damage: 1d6
    mode: bite
    type: poison
can_fly: 1
can_swim: 1
color: bright_green
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_amphibious: 1
is_carnivorous: 1
is_herbivorous: 1
is_unique: 1
is_very_strong: 1
mr: 50
name: Medusa
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  poison: 1
  stone: 1
size: large
sound: hiss
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse:
  fire: 1
  poison: 1
ac: -8
alignment: none
always_hostile: 1
attacks:
  - damage: 2d12
    mode: claw
    type: stealamulet
  - damage: 0d0
    mode: magic
    type: wizardspell
can_fly: 1
color: magenta
corpse_nutrition: 400
extra_nasty: 1
glyph: '@'
has_teleport_control: 1
has_teleportitis: 1
hitdice: 30
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_amphibious: 1
is_breathless: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_rank_prince: 1
is_unique: 1
is_very_strong: 1
mr: 100
name: Wizard of Yendor
not_randomly_generated: 1
regenerates_quickly: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
size: medium
sound: cuss
speed: 12
wants_amulet: 1
wants_bell: 1
wants_book: 1
wants_candelabrum: 1
wants_magic_items: 1
wants_quest_artifact: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 15
always_hostile: 1
attacks:
  - damage: 4d10
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_rank_prince: 1
is_unique: 1
is_very_strong: 1
mr: 40
name: Croesus
not_randomly_generated: 1
resist: {}
sees_invisible: 1
size: medium
sound: guard
speed: 15
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: -5
alignment: -5
always_hostile: 1
attacks:
  - damage: 1d1
    mode: touch
    type: physical
can_fly: 1
color: gray
follows_stair_users: 1
glyph: X
has_infravision: 1
hitdice: 10
humanoid_body: 1
ignores_walls: 1
invalid_polymorph_target: 1
is_amphibious: 1
is_breathless: 1
is_undead: 1
made_of_gas: 1
mr: 50
name: ghost
never_drops_corpse: 1
not_randomly_generated: 1
nutrition: 0
resist:
  cold: 1
  disint: 1
  poison: 1
  sleep: 1
  stone: 1
size: medium
sound: silent
speed: 3
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: touch
    type: paralyze
  - damage: 1d6
    mode: touch
    type: slow
can_fly: 1
color: black
extra_nasty: 1
follows_stair_users: 1
glyph: X
has_infravision: 1
hitdice: 12
humanoid_body: 1
ignores_walls: 1
invalid_polymorph_target: 1
is_amphibious: 1
is_breathless: 1
is_undead: 1
is_wanderer: 1
made_of_gas: 1
mr: 0
name: shade
never_drops_corpse: 1
not_randomly_generated: 1
nutrition: 0
resist:
  cold: 1
  disint: 1
  poison: 1
  sleep: 1
  stone: 1
sees_invisible: 1
size: medium
sound: wail
speed: 10
weight: 1450
---
_corpse: {}
ac: -4
alignment: -7
always_hostile: 1
attacks:
  - damage: 1d3
    mode: weapon
    type: physical
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: bite
    type: physical
can_swim: 1
color: blue
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '&'
has_infravision: 1
hitdice: 8
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_demon: 1
mr: 30
name: water demon
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
size: medium
sound: djinni
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: -5
alignment: 11
always_hostile: 1
attacks:
  - damage: 1d4
    mode: weapon
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 2d3
    mode: bite
    type: physical
  - damage: 1d3
    mode: sting
    type: physical
color: brown
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_thick_hide: 1
hitdice: 6
infravision_detectable: 1
is_demon: 1
mr: 50
name: horned devil
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 2
resist:
  fire: 1
  poison: 1
size: medium
sound: silent
speed: 9
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: -9
always_hostile: 1
attacks:
  - damage: 0d0
    mode: bite
    type: succubus
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: claw
    type: physical
can_fly: 1
color: gray
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '&'
has_infravision: 1
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
is_always_female: 1
is_demon: 1
mr: 70
name: succubus
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  fire: 1
  poison: 1
size: medium
sound: seduce
speed: 12
weight: 1450
---
_corpse: {}
ac: 0
alignment: -9
always_hostile: 1
attacks:
  - damage: 0d0
    mode: bite
    type: succubus
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: claw
    type: physical
can_fly: 1
color: gray
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '&'
has_infravision: 1
hitdice: 6
humanoid_body: 1
infravision_detectable: 1
is_always_male: 1
is_demon: 1
mr: 70
name: incubus
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  fire: 1
  poison: 1
size: medium
sound: seduce
speed: 12
weight: 1450
---
_corpse: {}
ac: 2
alignment: 10
always_hostile: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: poison
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 7
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_demon: 1
is_very_strong: 1
mr: 30
name: erinys
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 2
resist:
  fire: 1
  poison: 1
size: medium
small_group: 1
sound: silent
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 8
always_hostile: 1
attacks:
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 3d4
    mode: sting
    type: physical
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_thick_hide: 1
hitdice: 8
infravision_detectable: 1
is_demon: 1
mr: 35
name: barbed devil
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 2
resist:
  fire: 1
  poison: 1
size: medium
small_group: 1
sound: silent
speed: 12
weight: 1450
---
_corpse: {}
ac: -6
alignment: -12
always_hostile: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 2d4
    mode: weapon
    type: physical
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: claw
    type: physical
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 7
humanoid_body: 1
infravision_detectable: 1
is_always_female: 1
is_demon: 1
mr: 80
name: marilith
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
serpentine_body: 1
size: large
sound: cuss
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: -9
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d8
    mode: claw
    type: physical
  - damage: 1d8
    mode: claw
    type: physical
  - damage: 1d6
    mode: bite
    type: physical
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 8
infravision_detectable: 1
is_demon: 1
mr: 50
name: vrock
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 2
resist:
  fire: 1
  poison: 1
size: large
small_group: 1
sound: silent
speed: 12
weight: 1450
---
_corpse: {}
ac: -2
alignment: -10
always_hostile: 1
attacks:
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 1d3
    mode: claw
    type: physical
  - damage: 4d4
    mode: bite
    type: physical
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 9
humanoid_body: 1
infravision_detectable: 1
is_demon: 1
mr: 55
name: hezrou
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 2
resist:
  fire: 1
  poison: 1
size: large
small_group: 1
sound: silent
speed: 6
weight: 1450
---
_corpse: {}
ac: -1
alignment: -9
always_hostile: 1
attacks:
  - damage: 3d4
    mode: weapon
    type: physical
  - damage: 2d4
    mode: sting
    type: poison
color: gray
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 9
infravision_detectable: 1
is_demon: 1
mr: 40
name: bone devil
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 2
resist:
  fire: 1
  poison: 1
size: large
small_group: 1
sound: silent
speed: 15
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: -4
alignment: -12
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: bite
    type: physical
  - damage: 3d4
    mode: sting
    type: cold
color: white
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 11
infravision_detectable: 1
is_demon: 1
mr: 55
name: ice devil
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 2
resist:
  cold: 1
  fire: 1
  poison: 1
sees_invisible: 1
size: large
sound: silent
speed: 6
weight: 1450
---
_corpse: {}
ac: -1
alignment: -11
always_hostile: 1
attacks:
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 1d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: bite
    type: physical
  - damage: 0d0
    mode: magic
    type: wizardspell
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 11
humanoid_body: 1
infravision_detectable: 1
is_demon: 1
mr: 65
name: nalfeshnee
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  fire: 1
  poison: 1
size: large
sound: spell
speed: 9
weight: 1450
---
_corpse: {}
ac: -3
alignment: -13
always_hostile: 1
attacks:
  - damage: 4d2
    mode: weapon
    type: physical
  - damage: 4d2
    mode: weapon
    type: physical
  - damage: 2d4
    mode: crush
    type: physical
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 13
infravision_detectable: 1
is_demon: 1
mr: 65
name: pit fiend
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 2
resist:
  fire: 1
  poison: 1
sees_invisible: 1
size: large
sound: growl
speed: 6
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: -2
alignment: -14
always_hostile: 1
attacks:
  - damage: 8d4
    mode: weapon
    type: physical
  - damage: 4d6
    mode: weapon
    type: physical
can_fly: 1
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 16
infravision_detectable: 1
is_demon: 1
is_very_strong: 1
mr: 75
name: balrog
never_drops_corpse: 1
poisonous_corpse: 1
rarity: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
size: large
sound: silent
speed: 5
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: -7
acidic_corpse: 1
alignment: -15
always_hostile: 1
attacks:
  - damage: 4d10
    mode: engulf
    type: sickness
  - damage: 3d6
    mode: spit
    type: acid
can_fly: 1
color: bright_green
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 50
immobile_until_seen: 1
invalid_polymorph_target: 1
is_always_male: 1
is_amorphous: 1
is_amphibious: 1
is_demon: 1
is_rank_lord: 1
is_unique: 1
lacks_head: 1
mr: 65
name: Juiblex
never_drops_corpse: 1
not_randomly_generated: 1
nutrition: 0
poisonous_corpse: 1
resist:
  acid: 1
  fire: 1
  poison: 1
  stone: 1
sees_invisible: 1
size: large
sound: gurgle
speed: 3
wants_amulet: 1
weight: 1500
---
_corpse: {}
ac: -5
alignment: -15
always_hostile: 1
attacks:
  - damage: 3d6
    mode: weapon
    type: physical
  - damage: 2d8
    mode: weapon
    type: conf
  - damage: 1d6
    mode: claw
    type: paralyze
  - damage: 2d6
    mode: magic
    type: magicmissile
can_fly: 1
color: magenta
corpse_nutrition: 500
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 56
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_demon: 1
is_rank_lord: 1
is_unique: 1
mr: 80
name: Yeenoghu
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
size: large
sound: orc
speed: 18
wants_amulet: 1
wants_wargear: 1
weight: 900
---
_corpse: {}
ac: -6
alignment: -20
always_hostile: 1
attacks:
  - damage: 3d6
    mode: weapon
    type: physical
  - damage: 3d4
    mode: claw
    type: physical
  - damage: 3d4
    mode: claw
    type: physical
  - damage: 8d6
    mode: magic
    type: wizardspell
  - damage: 2d4
    mode: sting
    type: poison
can_fly: 1
color: magenta
corpse_nutrition: 500
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 66
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_demon: 1
is_rank_prince: 1
is_unique: 1
mr: 85
name: Orcus
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
size: huge
sound: orc
speed: 9
wants_amulet: 1
wants_book: 1
wants_wargear: 1
weight: 1500
---
_corpse: {}
ac: -3
alignment: 15
always_hostile: 1
attacks:
  - damage: 3d6
    mode: claw
    type: physical
  - damage: 3d6
    mode: claw
    type: physical
  - damage: 2d4
    mode: sting
    type: poison
can_fly: 1
color: magenta
corpse_nutrition: 500
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 72
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_demon: 1
is_rank_prince: 1
is_unique: 1
mr: 75
name: Geryon
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
serpentine_body: 1
size: huge
sound: bribe
speed: 3
wants_amulet: 1
weight: 1500
---
_corpse: {}
ac: -2
alignment: 15
always_hostile: 1
attacks:
  - damage: 4d6
    mode: weapon
    type: physical
  - damage: 6d6
    mode: magic
    type: wizardspell
can_fly: 1
color: magenta
corpse_nutrition: 500
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 78
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_demon: 1
is_rank_prince: 1
is_unique: 1
mr: 80
name: Dispater
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
size: medium
sound: bribe
speed: 15
wants_amulet: 1
wants_wargear: 1
weight: 1500
---
_corpse: {}
ac: -5
alignment: 20
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: poison
  - damage: 2d6
    mode: gaze
    type: stun
can_fly: 1
color: magenta
corpse_nutrition: 500
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 89
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_demon: 1
is_rank_prince: 1
is_unique: 1
mr: 85
name: Baalzebub
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
size: large
sound: bribe
speed: 9
wants_amulet: 1
weight: 1500
---
_corpse: {}
ac: -7
alignment: 20
always_hostile: 1
attacks:
  - damage: 4d4
    mode: claw
    type: physical
  - damage: 6d6
    mode: magic
    type: cold
can_fly: 1
color: magenta
corpse_nutrition: 500
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 105
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_demon: 1
is_rank_prince: 1
is_unique: 1
is_very_strong: 1
mr: 90
name: Asmodeus
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  cold: 1
  fire: 1
  poison: 1
sees_invisible: 1
size: huge
sound: bribe
speed: 12
wants_amulet: 1
weight: 1500
---
_corpse: {}
ac: -8
alignment: -20
always_hostile: 1
attacks:
  - damage: 8d6
    mode: magic
    type: wizardspell
  - damage: 1d4
    mode: sting
    type: drain
  - damage: 1d6
    mode: claw
    type: sickness
  - damage: 1d6
    mode: claw
    type: sickness
can_fly: 1
color: magenta
corpse_nutrition: 500
extra_nasty: 1
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 106
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_demon: 1
is_rank_prince: 1
is_unique: 1
lacks_hands: 1
mr: 95
name: Demogorgon
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
sees_invisible: 1
size: huge
sound: growl
speed: 15
wants_amulet: 1
weight: 1500
---
_corpse: {}
ac: -5
alignment: 0
always_hostile: 1
attacks:
  - damage: 8d8
    mode: touch
    type: Death
  - damage: 8d8
    mode: touch
    type: Death
can_fly: 1
color: magenta
corpse_nutrition: 1
extra_nasty: 1
follows_stair_users: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
has_teleport_control: 1
hitdice: 30
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_unique: 1
is_very_strong: 1
mr: 100
name: Death
not_randomly_generated: 1
regenerates_quickly: 1
resist:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
sees_invisible: 1
size: medium
sound: rider
speed: 12
weight: 1450
---
_corpse: {}
ac: -5
alignment: 0
always_hostile: 1
attacks:
  - damage: 8d8
    mode: touch
    type: Pestilence
  - damage: 8d8
    mode: touch
    type: Pestilence
can_fly: 1
color: magenta
corpse_nutrition: 1
extra_nasty: 1
follows_stair_users: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
has_teleport_control: 1
hitdice: 30
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_unique: 1
is_very_strong: 1
mr: 100
name: Pestilence
not_randomly_generated: 1
regenerates_quickly: 1
resist:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
sees_invisible: 1
size: medium
sound: rider
speed: 12
weight: 1450
---
_corpse: {}
ac: -5
alignment: 0
always_hostile: 1
attacks:
  - damage: 8d8
    mode: touch
    type: Famine
  - damage: 8d8
    mode: touch
    type: Famine
can_fly: 1
color: magenta
corpse_nutrition: 1
extra_nasty: 1
follows_stair_users: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
has_teleport_control: 1
hitdice: 30
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_unique: 1
is_very_strong: 1
mr: 100
name: Famine
not_randomly_generated: 1
regenerates_quickly: 1
resist:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
sees_invisible: 1
size: medium
sound: rider
speed: 12
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks: []
can_fly: 1
can_swim: 1
color: bright_blue
corpse_nutrition: 300
follows_stair_users: 1
glyph: '&'
has_infravision: 1
hitdice: 56
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_amphibious: 1
is_breathless: 1
mr: 127
name: mail daemon
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  cold: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
sees_invisible: 1
size: medium
sound: silent
speed: 24
weight: 600
---
_corpse: {}
ac: 4
alignment: 0
attacks:
  - damage: 2d8
    mode: weapon
    type: physical
can_fly: 1
color: yellow
corpse_nutrition: 400
follows_stair_users: 1
glyph: '&'
hitdice: 7
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
mr: 30
name: djinni
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  poison: 1
  stone: 1
size: medium
sound: djinni
speed: 12
wants_wargear: 1
weight: 1500
---
_corpse: {}
ac: 4
alignment: -5
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
  - damage: 2d6
    mode: weapon
    type: physical
color: gray
corpse_nutrition: 400
follows_stair_users: 1
gehennom_exclusive: 1
glyph: '&'
has_infravision: 1
hitdice: 13
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_very_strong: 1
mr: 60
name: sandestin
never_drops_corpse: 1
rarity: 1
resist:
  stone: 1
size: medium
sound: cuss
speed: 12
wants_wargear: 1
weight: 1500
---
_corpse:
  poison: 1
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d3
    mode: sting
    type: poison
can_swim: 1
cannot_pickup_items: 1
color: blue
corpse_nutrition: 20
glyph: ;
hitdice: 3
is_amphibious: 1
is_genocidable: 1
lacks_limbs: 1
mr: 0
name: jellyfish
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  poison: 1
serpentine_body: 1
size: small
sound: silent
speed: 3
weight: 80
---
_corpse: {}
ac: 4
alignment: 0
always_hostile: 1
attacks:
  - damage: 2d6
    mode: bite
    type: physical
can_swim: 1
cannot_pickup_items: 1
color: red
corpse_nutrition: 30
glyph: ;
hitdice: 5
is_amphibious: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: piranha
not_randomly_generated: 1
resist: {}
serpentine_body: 1
size: small
small_group: 1
sound: silent
speed: 12
weight: 60
---
_corpse: {}
ac: 2
alignment: 0
always_hostile: 1
attacks:
  - damage: 5d6
    mode: bite
    type: physical
can_swim: 1
cannot_pickup_items: 1
color: gray
corpse_nutrition: 350
glyph: ;
has_thick_hide: 1
hitdice: 7
is_amphibious: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: shark
not_randomly_generated: 1
resist: {}
serpentine_body: 1
size: large
sound: silent
speed: 12
weight: 500
---
_corpse: {}
ac: -1
alignment: 0
always_hostile: 1
attacks:
  - damage: 3d6
    mode: bite
    type: physical
  - damage: 0d0
    mode: touch
    type: wrap
can_swim: 1
cannot_pickup_items: 1
color: cyan
corpse_nutrition: 250
glyph: ;
hitdice: 5
infravision_detectable: 1
is_amphibious: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: giant eel
not_randomly_generated: 1
resist: {}
serpentine_body: 1
size: huge
sound: silent
speed: 9
weight: 200
---
_corpse:
  elec: 1
ac: -3
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d6
    mode: bite
    type: electricity
  - damage: 0d0
    mode: touch
    type: wrap
can_swim: 1
cannot_pickup_items: 1
color: bright_blue
corpse_nutrition: 250
glyph: ;
hitdice: 7
infravision_detectable: 1
is_amphibious: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_limbs: 1
lays_eggs: 1
mr: 0
name: electric eel
not_randomly_generated: 1
resist:
  elec: 1
serpentine_body: 1
size: huge
sound: silent
speed: 10
weight: 200
---
_corpse: {}
ac: 6
alignment: -3
always_hostile: 1
attacks:
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d6
    mode: crush
    type: wrap
  - damage: 5d4
    mode: bite
    type: physical
can_swim: 1
color: red
corpse_nutrition: 1000
glyph: ;
hitdice: 20
infravision_detectable: 1
invalid_polymorph_target: 1
is_amphibious: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
mr: 0
name: kraken
not_randomly_generated: 1
resist: {}
size: huge
sound: silent
speed: 3
weight: 1800
---
_corpse: {}
ac: 8
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d2
    mode: bite
    type: physical
can_swim: 1
color: yellow
corpse_nutrition: 20
glyph: ':'
hitdice: 0
is_amphibious: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: newt
rarity: 5
resist: {}
size: tiny
sound: silent
speed: 6
weight: 10
---
_corpse: {}
ac: 8
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d3
    mode: bite
    type: physical
color: green
corpse_nutrition: 20
glyph: ':'
hitdice: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: gecko
rarity: 5
resist: {}
size: tiny
sound: sqeek
speed: 6
weight: 10
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: physical
color: brown
corpse_nutrition: 30
glyph: ':'
hitdice: 2
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: iguana
rarity: 5
resist: {}
size: tiny
sound: silent
speed: 6
weight: 30
---
_corpse: {}
ac: 7
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d4
    mode: bite
    type: physical
can_swim: 1
color: brown
corpse_nutrition: 200
glyph: ':'
hitdice: 3
is_amphibious: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 0
name: baby crocodile
resist: {}
size: medium
sound: silent
speed: 6
weight: 200
---
_corpse:
  stone: 1
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 1d6
    mode: bite
    type: physical
color: green
corpse_nutrition: 40
glyph: ':'
hitdice: 5
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 10
name: lizard
rarity: 5
resist:
  stone: 1
size: tiny
sound: silent
speed: 6
weight: 10
---
_corpse: {}
ac: 6
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d2
    mode: bite
    type: physical
color: brown
corpse_nutrition: 100
glyph: ':'
hitdice: 6
invalid_polymorph_target: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
lacks_hands: 1
mr: 10
name: chameleon
rarity: 2
resist: {}
size: tiny
sound: silent
speed: 5
weight: 100
---
_corpse: {}
ac: 5
alignment: 0
always_hostile: 1
attacks:
  - damage: 4d2
    mode: bite
    type: physical
  - damage: 1d12
    mode: claw
    type: physical
can_swim: 1
color: brown
corpse_nutrition: 400
glyph: ':'
has_thick_hide: 1
hitdice: 6
is_amphibious: 1
is_animal: 1
is_carnivorous: 1
is_genocidable: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: crocodile
rarity: 1
resist: {}
size: large
sound: silent
speed: 9
weight: 1450
---
_corpse:
  fire: 1
ac: -1
alignment: -9
always_hostile: 1
attacks:
  - damage: 2d8
    mode: weapon
    type: physical
  - damage: 1d6
    mode: touch
    type: fire
  - damage: 2d6
    mode: crush
    type: physical
  - damage: 3d6
    mode: crush
    type: fire
color: orange
corpse_nutrition: 400
follows_stair_users: 1
gehennom_exclusive: 1
glyph: ':'
has_thick_hide: 1
hitdice: 8
humanoid_body: 1
infravision_detectable: 1
mr: 0
name: salamander
poisonous_corpse: 1
rarity: 1
resist:
  fire: 1
  sleep: 1
serpentine_body: 1
size: medium
sound: mumble
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1500
---
_corpse: {}
ac: 10
alignment: 3
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 1
name: archeologist
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
tunnels_with_pick: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 1
name: barbarian
not_randomly_generated: 1
resist:
  poison: 1
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 0
name: caveman
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 0
name: cavewoman
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 1
name: healer
not_randomly_generated: 1
resist:
  poison: 1
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 3
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 1
name: knight
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d8
    mode: claw
    type: physical
  - damage: 1d8
    mode: kick
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 2
name: monk
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 2
name: priest
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 2
name: priestess
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -3
attacks:
  - damage: 1d4
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 2
name: ranger
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -3
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 1
name: rogue
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_gems: 1
wants_gold: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 3
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 1d8
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 1
name: samurai
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 1
name: tourist
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 1d8
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 1
name: valkyrie
not_randomly_generated: 1
resist:
  cold: 1
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 10
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 3
name: wizard
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 20
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 30
name: Lord Carnarvon
not_randomly_generated: 1
resist: {}
size: medium
sound: leader
speed: 12
tunnels_with_pick: 1
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 30
name: Pelias
not_randomly_generated: 1
resist:
  poison: 1
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 20
always_peaceful: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 30
name: Shaman Karnov
not_randomly_generated: 1
resist: {}
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 40
name: Hippocrates
not_randomly_generated: 1
resist:
  poison: 1
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 20
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 40
name: King Arthur
not_randomly_generated: 1
resist: {}
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 0
always_peaceful: 1
attacks:
  - damage: 4d10
    mode: claw
    type: physical
  - damage: 2d8
    mode: kick
    type: physical
  - damage: 2d8
    mode: magic
    type: clericalspell
  - damage: 2d8
    mode: magic
    type: clericalspell
color: black
corpse_nutrition: 400
extra_nasty: 1
glyph: '@'
hitdice: 25
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 70
name: Grand Master
not_randomly_generated: 1
resist:
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
sees_invisible: 1
size: medium
sound: leader
speed: 12
wants_magic_items: 1
weight: 1450
---
_corpse: {}
ac: 7
alignment: 0
always_peaceful: 1
attacks:
  - damage: 4d10
    mode: weapon
    type: physical
  - damage: 2d8
    mode: kick
    type: physical
  - damage: 2d8
    mode: magic
    type: clericalspell
  - damage: 2d8
    mode: magic
    type: clericalspell
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 25
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 70
name: Arch Priest
not_randomly_generated: 1
resist:
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
sees_invisible: 1
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
can_swim: 1
color: magenta
corpse_nutrition: 400
glyph: '@'
has_infravision: 1
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_amphibious: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 30
name: Orion
not_randomly_generated: 1
resist: {}
sees_invisible: 1
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: -20
always_peaceful: 1
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
  - damage: 2d6
    mode: weapon
    type: physical
  - damage: 2d4
    mode: claw
    type: stealamulet
color: magenta
corpse_nutrition: 400
glyph: '@'
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 30
name: Master of Thieves
not_randomly_generated: 1
resist:
  stone: 1
size: medium
sound: leader
speed: 12
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 20
always_peaceful: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 30
name: Lord Sato
not_randomly_generated: 1
resist: {}
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 20
name: Twoflower
not_randomly_generated: 1
resist: {}
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: magenta
corpse_nutrition: 400
glyph: '@'
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 80
name: Norn
not_randomly_generated: 1
resist:
  cold: 1
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 2d8
    mode: magic
    type: wizardspell
color: green
corpse_nutrition: 400
glyph: '@'
has_proper_name: 1
hitdice: 20
humanoid_body: 1
immobile_until_disturbed: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 60
name: Neferet the Green
not_randomly_generated: 1
resist: {}
size: medium
sound: leader
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: -2
alignment: -14
always_hostile: 1
attacks:
  - damage: 8d4
    mode: weapon
    type: physical
  - damage: 4d6
    mode: weapon
    type: physical
  - damage: 0d0
    mode: magic
    type: wizardspell
  - damage: 2d6
    mode: claw
    type: stealamulet
can_fly: 1
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '&'
has_infravision: 1
hitdice: 16
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_demon: 1
is_unique: 1
is_very_strong: 1
mr: 75
name: Minion of Huhetotl
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
  stone: 1
sees_invisible: 1
size: large
sound: nemesis
speed: 12
wants_quest_artifact: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: -14
always_hostile: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 0d0
    mode: magic
    type: wizardspell
  - damage: 0d0
    mode: magic
    type: wizardspell
  - damage: 1d4
    mode: claw
    type: stealamulet
color: magenta
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '@'
has_proper_name: 1
hitdice: 16
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 10
name: Thoth Amon
never_drops_corpse: 1
not_randomly_generated: 1
resist:
  poison: 1
  stone: 1
size: medium
sound: nemesis
speed: 12
wants_magic_items: 1
wants_quest_artifact: 1
wants_wargear: 1
weight: 1450
---
_corpse:
  cold: 1
  disint: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
ac: 0
alignment: -14
always_hostile: 1
attacks:
  - damage: 6d8
    mode: breathe
    type: randombreath
  - damage: 0d0
    mode: magic
    type: wizardspell
  - damage: 2d8
    mode: claw
    type: stealamulet
  - damage: 4d8
    mode: bite
    type: physical
  - damage: 4d8
    mode: bite
    type: physical
  - damage: 1d6
    mode: sting
    type: physical
color: magenta
corpse_nutrition: 1700
extra_nasty: 1
follows_stair_users: 1
glyph: D
has_thick_hide: 1
hitdice: 16
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_carnivorous: 1
is_unique: 1
is_very_strong: 1
lacks_hands: 1
mr: 30
name: Chromatic Dragon
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  acid: 1
  cold: 1
  disint: 1
  elec: 1
  fire: 1
  poison: 1
  sleep: 1
  stone: 1
sees_invisible: 1
size: gigantic
sound: nemesis
speed: 12
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
wants_quest_artifact: 1
weight: 4500
---
_corpse: {}
ac: 0
alignment: -15
always_hostile: 1
attacks:
  - damage: 4d8
    mode: weapon
    type: physical
  - damage: 4d8
    mode: weapon
    type: physical
  - damage: 2d6
    mode: claw
    type: stealamulet
color: gray
corpse_nutrition: 700
extra_nasty: 1
follows_stair_users: 1
glyph: H
has_infravision: 1
hitdice: 18
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_giant: 1
is_herbivorous: 1
is_unique: 1
is_very_strong: 1
mr: 0
name: Cyclops
not_randomly_generated: 1
resist:
  stone: 1
size: huge
sound: nemesis
speed: 12
throws_boulders: 1
wants_gems: 1
wants_quest_artifact: 1
wants_wargear: 1
weight: 1900
---
_corpse:
  fire: 1
ac: -1
alignment: -14
always_hostile: 1
attacks:
  - damage: 8d6
    mode: breathe
    type: fire
  - damage: 4d8
    mode: bite
    type: physical
  - damage: 0d0
    mode: magic
    type: wizardspell
  - damage: 2d4
    mode: claw
    type: physical
  - damage: 2d4
    mode: claw
    type: stealamulet
can_fly: 1
color: red
corpse_nutrition: 1600
extra_nasty: 1
follows_stair_users: 1
glyph: D
has_proper_name: 1
has_thick_hide: 1
hitdice: 15
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_unique: 1
is_very_strong: 1
lacks_hands: 1
mr: 20
name: Ixoth
not_randomly_generated: 1
resist:
  fire: 1
  stone: 1
sees_invisible: 1
size: gigantic
sound: nemesis
speed: 12
wants_gems: 1
wants_gold: 1
wants_magic_items: 1
wants_quest_artifact: 1
weight: 4500
---
_corpse:
  poison: 1
ac: -10
alignment: -20
always_hostile: 1
attacks:
  - damage: 16d2
    mode: claw
    type: physical
  - damage: 16d2
    mode: claw
    type: physical
  - damage: 0d0
    mode: magic
    type: clericalspell
  - damage: 1d4
    mode: claw
    type: stealamulet
color: magenta
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '@'
has_proper_name: 1
hitdice: 25
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 10
name: Master Kaen
not_randomly_generated: 1
resist:
  poison: 1
  stone: 1
sees_invisible: 1
size: medium
sound: nemesis
speed: 12
wants_magic_items: 1
wants_quest_artifact: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: -2
alignment: -127
always_hostile: 1
attacks:
  - damage: 8d4
    mode: weapon
    type: physical
  - damage: 4d6
    mode: weapon
    type: physical
  - damage: 0d0
    mode: magic
    type: wizardspell
  - damage: 2d6
    mode: claw
    type: stealamulet
can_fly: 1
color: red
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '&'
has_infravision: 1
has_proper_name: 1
hitdice: 16
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_demon: 1
is_unique: 1
is_very_strong: 1
mr: 85
name: Nalzok
never_drops_corpse: 1
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  fire: 1
  poison: 1
  stone: 1
sees_invisible: 1
size: large
sound: nemesis
speed: 12
wants_quest_artifact: 1
wants_wargear: 1
weight: 1450
---
_corpse:
  poison: 1
ac: 10
alignment: -15
always_hostile: 1
attacks:
  - damage: 2d6
    mode: claw
    type: physical
  - damage: 2d6
    mode: claw
    type: stealamulet
  - damage: 1d4
    mode: sting
    type: sickness
color: magenta
corpse_nutrition: 350
extra_nasty: 1
follows_stair_users: 1
glyph: s
has_proper_name: 1
hitdice: 15
immobile_until_seen: 1
invalid_polymorph_target: 1
is_animal: 1
is_carnivorous: 1
is_unique: 1
is_very_strong: 1
lacks_hands: 1
lays_eggs: 1
mr: 0
name: Scorpius
not_randomly_generated: 1
poisonous_corpse: 1
resist:
  poison: 1
  stone: 1
size: medium
sound: nemesis
speed: 12
wants_magic_items: 1
wants_quest_artifact: 1
wants_wargear: 1
weight: 750
---
_corpse: {}
ac: 0
alignment: 18
always_hostile: 1
attacks:
  - damage: 2d6
    mode: weapon
    type: poison
  - damage: 2d8
    mode: weapon
    type: physical
  - damage: 2d6
    mode: claw
    type: stealamulet
color: magenta
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '@'
hitdice: 15
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 30
name: Master Assassin
not_randomly_generated: 1
resist:
  stone: 1
size: medium
sound: nemesis
speed: 12
wants_magic_items: 1
wants_quest_artifact: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 0
alignment: -13
always_hostile: 1
attacks:
  - damage: 2d6
    mode: weapon
    type: physical
  - damage: 2d6
    mode: weapon
    type: physical
  - damage: 2d6
    mode: claw
    type: stealamulet
color: magenta
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '@'
has_proper_name: 1
hitdice: 15
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 40
name: Ashikaga Takauji
never_drops_corpse: 1
not_randomly_generated: 1
resist:
  stone: 1
size: medium
sound: nemesis
speed: 12
wants_magic_items: 1
wants_quest_artifact: 1
wants_wargear: 1
weight: 1450
---
_corpse:
  fire: 1
ac: 2
alignment: 12
always_hostile: 1
attacks:
  - damage: 2d10
    mode: weapon
    type: physical
  - damage: 2d10
    mode: weapon
    type: physical
  - damage: 2d6
    mode: claw
    type: stealamulet
color: magenta
corpse_nutrition: 850
extra_nasty: 1
follows_stair_users: 1
glyph: H
has_infravision: 1
has_proper_name: 1
hitdice: 15
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_male: 1
is_carnivorous: 1
is_giant: 1
is_herbivorous: 1
is_unique: 1
is_very_strong: 1
mr: 50
name: Lord Surtur
not_randomly_generated: 1
resist:
  fire: 1
  stone: 1
size: huge
sound: nemesis
speed: 12
throws_boulders: 1
wants_gems: 1
wants_quest_artifact: 1
wants_wargear: 1
weight: 2250
---
_corpse: {}
ac: 0
alignment: -10
always_hostile: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d4
    mode: claw
    type: stealamulet
  - damage: 0d0
    mode: magic
    type: wizardspell
color: black
corpse_nutrition: 400
extra_nasty: 1
follows_stair_users: 1
glyph: '@'
hitdice: 15
humanoid_body: 1
immobile_until_seen: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_unique: 1
is_very_strong: 1
mr: 80
name: Dark One
never_drops_corpse: 1
not_randomly_generated: 1
resist:
  stone: 1
size: medium
sound: nemesis
speed: 12
wants_magic_items: 1
wants_quest_artifact: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 3
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: student
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
tunnels_with_pick: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: chieftain
not_randomly_generated: 1
resist:
  poison: 1
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 1
always_peaceful: 1
attacks:
  - damage: 2d4
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: neanderthal
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 3
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: attendant
not_randomly_generated: 1
resist:
  poison: 1
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 3
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: page
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks:
  - damage: 8d2
    mode: claw
    type: physical
  - damage: 3d2
    mode: kick
    type: stun
  - damage: 0d0
    mode: magic
    type: clericalspell
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 20
name: abbot
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 0d0
    mode: magic
    type: clericalspell
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 20
name: acolyte
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -7
always_peaceful: 1
attacks:
  - damage: 1d4
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
has_infravision: 1
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: hunter
not_randomly_generated: 1
resist: {}
sees_invisible: 1
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -3
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 1d6
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: thug
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_gold: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 3
always_hostile: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 1d8
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: ninja
not_randomly_generated: 1
resist: {}
size: medium
sound: humanoid
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 3
always_peaceful: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 1d8
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: roshi
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 0d0
    mode: magic
    type: wizardspell
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 20
name: guide
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: -1
always_peaceful: 1
attacks:
  - damage: 1d8
    mode: weapon
    type: physical
  - damage: 1d8
    mode: weapon
    type: physical
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_always_female: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 10
name: warrior
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_wargear: 1
weight: 1450
---
_corpse: {}
ac: 10
alignment: 0
always_peaceful: 1
attacks:
  - damage: 1d6
    mode: weapon
    type: physical
  - damage: 0d0
    mode: magic
    type: wizardspell
color: white
corpse_nutrition: 400
glyph: '@'
hitdice: 5
humanoid_body: 1
infravision_detectable: 1
invalid_polymorph_target: 1
is_carnivorous: 1
is_herbivorous: 1
is_human: 1
is_very_strong: 1
mr: 30
name: apprentice
not_randomly_generated: 1
resist: {}
size: medium
sound: guardian
speed: 12
wants_magic_items: 1
wants_wargear: 1
weight: 1450
