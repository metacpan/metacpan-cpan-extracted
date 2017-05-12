package NetHack::Item;
{
  $NetHack::Item::VERSION = '0.21';
}
use 5.008001;
use Moose -traits => 'NetHack::Item::Meta::Trait::InstallsSpoilers';

use NetHack::ItemPool;

use NetHack::Item::Meta::Trait::IncorporatesUndef;
use NetHack::Item::Meta::Types;

with 'NetHack::ItemPool::Role::HasPool';

has tracker => (
    is        => 'ro',
    writer    => '_set_tracker',
    clearer   => '_clear_tracker',
    isa       => 'NetHack::ItemPool::Tracker',
    predicate => 'has_tracker',
);

has raw => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has identity => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_identity',
);

has appearance => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_appearance',
);

has artifact => (
    is        => 'rw',
    isa       => 'Str',
);

has slot => (
    traits    => [qw/IncorporatesUndef/],
    is        => 'rw',
    isa       => 'Maybe[Str]',
);

has quantity => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);

has cost_each => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has specific_name => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_specific_name',
    trigger   => sub {
        # recalculate whether this item is an artifact or not (e.g. Sting)
        my $self = shift;
        $self->pool->incorporate_artifact($self)
            if $self->is_artifact && $self->has_pool;
    },
);

has generic_name => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_generic_name',
);

has container => (
    is        => 'rw',
    isa       => 'NetHack::Item',
    clearer   => 'clear_container',
    predicate => 'is_in_container',
    weak_ref  => 1,
);

for my $type (qw/wield quiver grease offhand/) {
    my $is = "is_$type";

    unless ($type =~ /offhand/) {
        $is .= 'e' unless $is =~ /e$/; # avoid "greaseed"
        $is .= 'd';
    }

    has $is => (
        traits    => [qw/Bool IncorporatesUndef/],
        is        => 'rw',
        isa       => 'Bool',
        default   => 0,
        handles   => {
            "$type"   => 'set',
            "un$type" => 'unset',
        },
    )
}

for my $buc (qw/is_blessed is_uncursed is_cursed/) {
    my %others = map { $_ => 1 } qw/is_blessed is_uncursed is_cursed/;
    delete $others{$buc};
    my @others = keys %others;

    has $buc => (
        is      => 'rw',
        isa     => 'Bool',
        trigger => sub {
            my $self = shift;
            my $set  = shift;

            # if this is true, the others must be false
            if ($set) {
                $self->$_(0) for @others;
            }
            # if this is false, then see if only one can be true
            elsif (defined($set)) {
                my %other_vals = map { $_ => $self->$_ } @others;

                my $unknown = 0;

                for (values %other_vals) {
                    return if $_; # we already have a true value
                    ++$unknown if !defined;
                }

                # multiple items are unknown, we can't narrow it down
                return if $unknown > 1;

                # if only one item is unknown, find it and set it to true
                my @must_be_true = grep { !defined($other_vals{$_}) }
                                   @others;

                # no unknowns, we're good
                return if @must_be_true == 0;

                my ($must_be_true) = @must_be_true;

                $self->$must_be_true(1);
            }
        },
    );
}

sub is_holy   { shift->is_blessed(@_) }
sub is_unholy { shift->is_cursed(@_)  }

sub buc {
    my $self = shift;

    if (@_) {
        my $new_buc = shift;
        my $is_new_buc = "is_$new_buc";
        return $self->$is_new_buc(1);
    }

    for my $buc (qw/blessed uncursed cursed/) {
        my $is_buc = "is_$buc";
        return $buc if $self->$is_buc;
    }

    return undef;
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args;
    if (@_ == 1 && !ref($_[0])) {
        $args = { raw => $_[0] };
    }
    else {
        $args = $orig->($class, @_);
    }

    if ($args->{buc}) {
        $args->{"is_$args->{buc}"} = 1;
    }

    $args->{is_blessed} = delete $args->{is_holy}
        if exists $args->{is_holy};
    $args->{is_cursed} = delete $args->{is_unholy}
        if exists $args->{is_unholy};

    return $args;
};

sub BUILD {
    my $self = shift;
    my $args = shift;

    $self->_rebless_into($args->{type}) if $args->{type};

    $self->parse_raw;
}

sub choose_item_class {
    my $self    = shift;
    my $type    = shift;
    my $subtype = shift;

    my $class = "NetHack::Item::" . ucfirst lc $type;
    $class .= '::' . ucfirst lc $subtype
        if $subtype;

    return $class;
}

sub spoiler_class {
    my $self = shift;
    my $type = shift;
    $type ||= $self->type if $self->can('type');

    my $class = $type
              ? "NetHack::Item::Spoiler::" . ucfirst lc $type
              : "NetHack::Item::Spoiler";
    Class::MOP::load_class($class);
    return $class;
}

sub _rebless_into {
    my $self    = shift;
    my $type    = shift;
    my $subtype = shift;

    return if !blessed($self);

    my $class = $self->choose_item_class($type, $subtype);
    Class::MOP::load_class($class);
    $class->meta->rebless_instance($self);
}

sub extract_stats {
    my $self = shift;
    my $raw  = shift || $self->raw;

    my %stats;

    my @fields = qw/slot quantity buc greased poisoned erosion1 erosion2 proofed
                    used eaten diluted enchantment item generic specific
                    recharges charges candles lit_candelabrum lit laid chained
                    quivered offhand offhand_wielded wielded worn cost cost2 cost3/;

    # the \b in front of "item name" forbids "Amulet of Yendor" being parsed as
    # "A mulet of Yendor"
    @stats{@fields} = $raw =~ m{
        ^                                                      # anchor
        (?:([\w\#\$])\s[+-]\s)?                           \s*  # slot
        ([Aa]n?|[Tt]he|\d+)?                              \s*  # quantity
        (blessed|(?:un)?cursed|(?:un)?holy)?              \s*  # buc
        (greased)?                                        \s*  # grease
        (poisoned)?                                       \s*  # poison
        ((?:(?:very|thoroughly)\ )?(?:burnt|rusty))?      \s*  # erosion 1
        ((?:(?:very|thoroughly)\ )?(?:rotted|corroded))?  \s*  # erosion 2
        (fixed|(?:fire|rust|corrode)proof)?               \s*  # proofed
        (partly\ used)?                                   \s*  # candles
        (partly\ eaten)?                                  \s*  # food
        (diluted)?                                        \s*  # potions
        ([+-]\d+)?                                        \s*  # enchantment
        (?:(?:pair|set)\ of)?                             \s*  # gloves boots
        \b(.*?)                                           \s*  # item name
        (?:called\ (.*?))?                                \s*  # generic name
        (?:named\ (.*?))?                                 \s*  # specific name
        (?:\((\d+):(-?\d+)\))?                            \s*  # charges
        (?:\((no|[1-7])\ candles?(,\ lit|\ attached)\))?  \s*  # candelabrum
        (\(lit\))?                                        \s*  # lit
        (\(laid\ by\ you\))?                              \s*  # eggs
        (\(chained\ to\ you\))?                           \s*  # iron balls
        (\(in\ quiver\))?                                 \s*  # quivered
        (\(alternate\ weapon;\ not\ wielded\))?           \s*  # offhand
        (\(wielded\ in\ other.*?\))?                      \s*  # offhand wield
        (\((?:weapon|wielded).*?\))?                      \s*  # wielding
        (\((?:being|embedded|on).*?\))?                   \s*  # worn

        # shop cost! there are multiple forms, with an optional quality comment
        (?:
            \( unpaid, \  (\d+) \  zorkmids? \)
            |
            \( (\d+) \  zorkmids? \)
            |
            ,\ no\ charge (?:,\ .*)?
            |
            ,\ (?:price\ )? (\d+) \  zorkmids (\ each)? (?:,\ .*)?
        )? \s*

        $                                                      # anchor
    }x;

    # this canonicalization must come early
    if ($stats{item} =~ /^potions? of ((?:un)?holy) water$/) {
        $stats{item} = 'potion of water';
        $stats{buc}  = $1;
    }

    # go from japanese to english if possible
    my $spoiler = $self->spoiler_class;

    $stats{item} = $spoiler->japanese_to_english->{$stats{item}}
                || $stats{item};

    # singularize the item if possible
    $stats{item} = $spoiler->singularize($stats{item})
                || $stats{item};

    $stats{type} = $spoiler->name_to_type($stats{item});

    if ($self->has_pool && ($stats{item} eq $self->pool->fruit_name || $stats{item} eq $self->pool->fruit_plural)) {
        $stats{item} = $self->pool->fruit_name; # singularize
        $stats{is_custom_fruit} = 1;
        $stats{type} = 'food';
    }
    else {
        $stats{is_custom_fruit} = 0;
    }

    confess "Unknown item type for '$stats{item}' from $raw"
        if !$stats{type};

    # canonicalize the rest of the stats

    $stats{quantity} = 1 if !defined($stats{quantity})
                         || $stats{quantity} =~ /\D/;

    $stats{lit_candelabrum} = ($stats{lit_candelabrum}||'') =~ /lit/;
    $stats{lit} = delete($stats{lit_candelabrum}) || $stats{lit};
    $stats{candles} = 0 if ($stats{candles}||'') eq 'no';

    $stats{worn} = !defined($stats{worn})               ? 0
                 : $stats{worn} =~ /\(on (left|right) / ? $1
                                                        : 1;

    # item damage
    for (qw/burnt rusty rotted corroded/) {
        my $match = ($stats{erosion1}||'') =~ $_ ? $stats{erosion1}
                  : ($stats{erosion2}||'') =~ $_ ? $stats{erosion2}
                                           : 0;

        $stats{$_} = $match ? $match =~ /thoroughly/ ? 3
                            : $match =~ /very/       ? 2
                                                     : 1
                                                     : 0;
    }
    delete @stats{qw/erosion1 erosion2/};

    # boolean stats
    for (qw/greased poisoned used eaten diluted lit laid chained quivered offhand offhand_wielded wielded/) {
        $stats{$_} = defined($stats{$_}) ? 1 : 0;
    }

    # maybe-boolean stats
    for (qw/proofed/) {
        $stats{$_} = defined($stats{$_}) ? 1 : undef;
    }

    my $cost2 = delete $stats{cost2};
    $stats{cost} ||= $cost2;

    my $cost3 = delete $stats{cost3};
    $stats{cost} ||= $cost3;

    # numeric, undef = 0 stats
    for (qw/candles cost/) {
        $stats{$_} = 0 if !defined($stats{$_});
    }

    # strings
    for (qw/generic specific/) {
        $stats{$_} = '' if !defined($stats{$_});
    }

    return \%stats;
}

sub parse_raw {
    my $self = shift;
    my $raw  = shift || $self->raw;

    my $stats = $self->extract_stats($raw);

    # exploit the fact that appearances don't show up in the spoiler table as
    # keys
    $self->_set_appearance_and_identity($stats->{item});

    $self->_rebless_into($stats->{type}, $self->subtype);

    $self->incorporate_stats($stats);
}

sub incorporate_stats {
    my $self  = shift;
    my $stats = shift;

    $self->slot($stats->{slot}) if defined $stats->{slot};
    $self->buc($stats->{buc}) if $stats->{buc};

    $self->quantity($stats->{quantity});
    $self->is_wielded($stats->{wielded});
    $self->is_greased($stats->{greased});
    $self->is_quivered($stats->{quivered});
    $self->is_offhand($stats->{offhand});
    $self->generic_name($stats->{generic}) if defined $stats->{generic};
    $self->specific_name($stats->{specific}) if defined $stats->{specific};
    $self->cost_each($stats->{cost});
}

sub is_artifact {
    my $self = shift;

    my $is_artifact = sub {
        return 1 if $self->artifact;

        my $name = $self->specific_name
            or return 0;

        my $spoiler = $self->spoiler_class->artifact_spoiler($name);

        # is there even an artifact with this name?
        return 0 unless $spoiler;

        # is it the same type as us?
        return 0 unless $spoiler->{type} eq $self->type;

        # is it the EXACT name? (e.g. "gray stone named heart of ahriman" fails
        # because it's not properly capitalized and doesn't have "The"
        my $arti_name = $spoiler->{fullname}
                    || $spoiler->{name};
        return 0 unless $arti_name eq $name;

        # if we know our appearance, is it a possible appearance for the
        # artifact?
        if (my $appearance = $self->appearance) {
            return 0 unless grep { $appearance eq ($_||'') }
                            $spoiler->{appearance},
                            @{ $spoiler->{appearances} };
        }

        # if we know our identity, is the artifact's identity the same as ours?
        # if so, then we can know definitively whether this is the artifact
        # or not (see below)
        if (my $identity = $self->identity) {
            if ($identity eq $spoiler->{base}) {
                $self->artifact($spoiler->{name});
                return 1;
            }
            else {
                return 0;
            }
        }

        # otherwise, the best we can say is "maybe". consider the artifact
        # naming bug.  we may have a pyramidal amulet that is named The Eye of
        # the Aethiopica. the naming bug exploits the fact that if pyramidal is
        # NOT ESP, then it will correctly name the amulet. if pyramidal IS ESP
        # then we cannot name it correctly -- the only pyramidal amulet that
        # can have the name is the real Eye

        return undef;
    }->();

    return $is_artifact;
}

sub _set_appearance_and_identity {
    my $self       = shift;
    my $best_match = shift;

    if ($self->has_pool && $best_match eq $self->pool->fruit_name) {
        $self->identity("slime mold");
        $self->appearance($best_match);
    }
    elsif (my $spoiler = $self->spoiler_class->spoiler_for($best_match)) {
        if ($spoiler->{artifact}) {
            $self->artifact($spoiler->{name});
            $spoiler = $self->spoiler_class->spoiler_for($spoiler->{base})
                if $spoiler->{base};
        }

        $self->identity($spoiler->{name});
        if (defined(my $appearance = $spoiler->{appearance})) {
            $self->appearance($appearance);
        }
    }
    else {
        $self->appearance($best_match);
        my @possibilities = $self->possibilities;
        if (@possibilities == 1 && $best_match ne $possibilities[0]) {
            $self->_set_appearance_and_identity($possibilities[0]);
        }
    }
}

sub possibilities {
    my $self = shift;

    if ($self->has_identity) {
        return $self->identity if wantarray;
        return 1;
    }

    return $self->tracker->possibilities if $self->has_tracker;

    return sort @{ $self->spoiler_class->possibilities_for_appearance($self->appearance) };
}

sub spoiler {
    my $self = shift;
    return unless $self->has_identity;
    return $self->spoiler_class->spoiler_for($self->identity);
}

sub spoiler_values {
    my $self = shift;
    my $key  = shift;

    return map { $self->spoiler_class->spoiler_for($_)->{$key} }
           $self->possibilities;
}

sub collapse_spoiler_value {
    my $self = shift;
    my $key  = shift;

    return $self->spoiler_class->collapse_value($key, $self->possibilities);
}

sub can_drop { 1 }

sub is_evolution_of {
    my $new = shift;
    my $old = shift;

    return 0 if $new->type ne $old->type;

    return 0 if $new->has_identity
             && $old->has_identity
             && $new->identity ne $old->identity;

    return 0 if $new->has_appearance
             && $old->has_appearance
             && $new->appearance ne $old->appearance;

    # items can become artifacts but they cannot unbecome artifacts
    return 0 if $old->is_artifact
             && !$new->is_artifact;

    return 1;
}

sub evolve_from {
    my $self = shift;
    my $new  = shift;
    my $args = shift || {};

    return 0 unless $new->is_evolution_of($self);

    my $old_quantity = $self->quantity;
    $self->incorporate_stats_from($new);
    $self->slot($new->slot);
    $self->quantity($old_quantity + $new->quantity)
        if $args->{add} && $self->stackable;

    return 1;
}

sub maybe_is {
    my $self = shift;
    my $other = shift;

    return $self->is_evolution_of($other) || $other->is_evolution_of($self);
}

sub incorporate_stats_from {
    my $self  = shift;
    my $other = shift;

    $other = NetHack::Item->new($other)
        if !ref($other);

    confess "New item (" . $other->raw . ") does not appear to be an evolution of the old item (" . $self->raw . ")" unless $other->is_evolution_of($self);

    my @stats = (qw/slot quantity cost_each specific_name generic_name
                    is_wielded is_quivered is_greased is_offhand is_blessed
                    is_uncursed is_cursed artifact identity appearance/);

    for my $stat (@stats) {
        $self->incorporate_stat($other => $stat);
    }
}

sub incorporate_stat {
    my $self  = shift;
    my $other = shift;
    my $stat  = shift;

    $other = NetHack::Item->new($other)
        if !ref($other);

    my ($old_attr, $new_attr) = map {
        $_->meta->find_attribute_by_name($stat)
            or confess "No attribute named ($stat)";
    } $self, $other;

    my $old_value = $old_attr->get_value($self);
    my $new_value = $new_attr->get_value($other);

    if (!defined($new_value)) {
        # if the stat incorporates undef, then incorporate it!
        return unless $old_attr->does('IncorporatesUndef');
    }

    return if defined($old_value)
           && defined($new_value)
           && $old_value eq $new_value;

    $old_attr->set_value($self, $new_value);
}

sub fork_quantity {
    my $self     = shift;
    my $quantity = shift;

    confess "Unable to fork more ($quantity) than the entire quantity (" . $self->quantity . ") of item ($self)"
        if $quantity > $self->quantity;

    confess "Unable to fork the entire quantity ($quantity) of item ($self)"
        if $quantity == $self->quantity;

    my $new_item = $self->meta->clone_object($self);
    $new_item->quantity($quantity);
    $self->quantity($self->quantity - $quantity);

    return $new_item;
}

# if we have only one possibility, then that is our identity
before 'identity', 'has_identity' => sub {
    my $self = shift;
    return if @_;
    return unless $self->has_tracker;
    return if $self->tracker->possibilities > 1;

    $self->identity($self->tracker->possibilities);
};

sub total_cost {
    my $self = shift;
    confess "Set cost_each instead." if @_;
    return $self->cost_each * $self->quantity;
}

sub throw_range {
    my $self = shift;
    my %args = @_;

    my $range = int($args{strength} / 2);

    if (($self->identity||'') eq 'heavy iron ball') {
        $range -= int($self->weight / 100);
    }
    else {
        $range -= int($self->weight / 40);
    }

    $range = 1 if $range < 1;

    if ($self->type eq 'gem' || ($self->identity||'') =~ /\b(?:arrow|crossbow bolt)\b/) {
        if (0 && "Wielding a bow for arrows or crossbow for bolts or sling for gems") {
            ++$range;
        }
        elsif ($self->type ne 'gem') {
            $range = int($range / 2);
        }
    }

    # are we on Air? are we levitating?

    if (($self->identity||'') eq 'boulder') {
        $range = 20;
    }
    elsif (($self->identity||'') eq 'Mjollnir') {
        $range = int(($range + 1) / 2);
    }

    # are we underwater?

    return $range;
}

sub name {
    my $self = shift;
    $self->artifact || $self->identity || $self->appearance
}

# Anything can be wielded; subclasses may provide more options
sub specific_slots { [] }

sub fits_in_slot {
    my ($self, $slot) = @_;

    return 1 if $slot eq "weapon" || $slot eq "offhand";

    grep { $_ eq $slot } @{ $self->specific_slots };
}

sub did_polymorph { }

sub did_polymorph_from {
    my $self = shift;
    my $older = shift;

    $self->did_polymorph;

    $self->is_blessed($older->is_blessed);
    $self->is_uncursed($older->is_uncursed);
    $self->is_cursed($older->is_cursed);
}

__PACKAGE__->meta->install_spoilers(qw/subtype stackable material weight price
                                       plural glyph/);

# anything can be used as a weapon
__PACKAGE__->meta->install_spoilers(qw/sdam ldam tohit hands/);

around weight => sub {
    my $orig = shift;
    my $self = shift;
    my $weight = $orig->($self, @_);
    return $weight if !defined($weight);
    return $weight * $self->quantity;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

NetHack::Item - parse and interact with a NetHack item

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    use NetHack::Item;
    my $item = NetHack::Item->new("f - a wand of wishing named SWEET (0:3)" );

    $item->slot           # f
    $item->type           # wand
    $item->specific_name  # SWEET
    $item->charges        # 3

    $item->spend_charge;
    $item->wield;
    $item->buc("blessed");

    $item->charges        # 2
    $item->is_wielded     # 1
    $item->is_blessed     # 1
    $item->is_cursed      # 0

=head1 DESCRIPTION

NetHack's items are complex beasts. This library attempts to control that
complexity.

=head1 ATTRIBUTES

These are the attributes common to every NetHack item. Subclasses (e.g. Wand)
may have additional attributes.

=over 4

=item raw

The raw string passed in to L</new>, to be parsed. This is the only required
attribute.

=item identity

The identity of the item (a string). For example, "clear potion" will be
"potion of water". For artifacts, the base item is used for identity, so for
"the Eye of the Aethiopica" you'll have "amulet of ESP".

=item appearance

The appearance of the item (a string). For example, "potion of water" will be
"clear potion". For artifacts, the base item is used for appearance, so for
"the Eye of the Aethiopica" you'll have "pyramidal amulet" (or any of the
random appearances for amulets of ESP).

=item artifact

The name of the artifact, if applicable. The leading "The" is stripped (so
you'll have "Eye of the Aethiopica").

=item slot

The inventory or container slot in which this item resides. Obviously not
applicable to items on the ground.

=item quantity

The item stack's quantity. Usually 1.

=item cost

The amount of zorkmids that a shopkeeper is demanding for this item.

=item specific_name

A name for this specific item, as opposed to a name for all items of this
class. Artifacts use specific name.

=item generic_name

A name for all items of this class, as opposed to a name for a specific item.
Identification uses generic name.

=item is_wielded, is_quivered, is_greased, is_offhand

Interesting boolean states of an item.

=item is_blessed, is_cursed, is_uncursed

Boolean states about the BUC status of an item. If one returns true, the others
will return false.

=item buc

Returns "blessed", "cursed", "uncursed", or C<undef>.

=item is_holy, is_unholy

Synonyms for L</is_blessed> and L</is_cursed>.

=back

=head1 AUTHORS

Shawn M Moore, C<sartak@bestpractical.com>

Jesse Luehrs, C<doy@tozt.net>

Sean Kelly, C<cpan@katron.org>

Stefan O'Rear, C<stefanor@cox.net>

=head1 SEE ALSO

L<http://sartak.org/code/TAEB/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2011 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
