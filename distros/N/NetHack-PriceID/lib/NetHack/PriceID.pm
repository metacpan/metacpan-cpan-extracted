package NetHack::PriceID;
BEGIN {
  $NetHack::PriceID::AUTHORITY = 'cpan:SARTAK';
}
{
  $NetHack::PriceID::VERSION = '0.05';
}
use strict;
use warnings;
use integer;
# ABSTRACT: identify NetHack items using shopkeepers

use base 'Exporter';
our @EXPORT_OK = qw(priceid priceid_buy priceid_sell priceid_base);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

our %glyph2type = (
    '"' => 'amulet',
    '?' => 'scroll',
    '+' => 'spellbook',
    '=' => 'ring',
    '!' => 'potion',
    '/' => 'wand',
    '(' => 'tool',
    '[' => 'armor',
);

our %item_table = (
    amulet => {
        0     => ['cheap plastic imitation of the Amulet of Yendor'],
        150   => ['change', 'ESP', 'life saving', 'magical breathing',
                  'reflection', 'restful sleep', 'strangulation',
                  'unchanging', 'versus poison'],
        30000 => ['Amulet of Yendor'],
    },

    scroll => {
        20  => ['identify'],
        50  => ['light'],
        60  => ['blank paper', 'enchant weapon'],
        80  => ['enchant armor', 'remove curse'],
        100 => ['confuse monster', 'destroy armor', 'fire',
                'food detection', 'gold detection', 'magic mapping',
                'scare monster', 'teleportation'],
        200 => ['amnesia', 'create monster', 'earth', 'taming'],
        300 => ['charging', 'genocide', 'punishment', 'stinking cloud'],
    },

    spellbook => {
        100 => ['detect monsters', 'force bolt', 'healing', 'jumping',
                'knock', 'light', 'protection', 'sleep'],
        200 => ['confuse monster', 'create monster', 'cure blindness',
                'detect food', 'drain life', 'magic missile',
                'slow monster', 'wizard lock'],
        300 => ['cause fear', 'charm monster', 'clairvoyance',
                'cure sickness', 'detect unseen', 'extra healing',
                'haste self', 'identify', 'remove curse',
                'stone to flesh'],
        400 => ['cone of cold', 'detect treasure', 'fireball',
                'invisibility', 'levitation', 'restore ability'],
        500 => ['dig', 'magic mapping'],
        600 => ['create familiar', 'polymorph', 'teleport away',
                'turn undead'],
        700 => ['cancellation', 'finger of death'],
    },

    potion => {
        0   => ['uncursed water'],
        50  => ['booze', 'fruit juice', 'see invisible', 'sickness'],
        100 => ['confusion', 'extra healing', 'hallucination', 'healing',
                'restore ability', 'sleeping', '(un)holy water'],
        150 => ['blindness', 'gain energy', 'invisibility',
                'monster detection', 'object detection'],
        200 => ['enlightenment', 'full healing', 'levitation', 'polymorph',
                'speed'],
        250 => ['acid', 'oil'],
        300 => ['gain ability', 'gain level', 'paralysis'],
    },

    ring => {
        100 => ['adornment', 'hunger', 'protection',
                'protection from shape changers', 'stealth',
                'sustain ability', 'warning'],
        150 => ['aggravate monster', 'cold resistance',
                'gain constitution', 'gain strength', 'increase accuracy',
                'increase damage', 'invisibility', 'poison resistance',
                'see invisible', 'shock resistance'],
        200 => ['fire resistance', 'free action', 'levitation',
                'regeneration', 'searching', 'slow digestion',
                'teleportation'],
        300 => ['conflict', 'polymorph', 'polymorph control',
                'teleport control'],
    },

    wand => {
        0   => ['uncharged'],
        100 => ['light', 'nothing'],
        150 => ['digging', 'enlightenment', 'locking', 'magic missile',
                'make invisible', 'opening', 'probing',
                'secret door detection', 'slow monster', 'speed monster',
                'striking', 'undead turning'],
        175 => ['cold', 'fire', 'lightning', 'sleep'],
        200 => ['cancellation', 'create monster', 'polymorph',
                'teleportation'],
        500 => ['death', 'wishing'],
    },

    bag => {
        2   => ['sack'],
        100 => ['bag of holding', 'oilskin sack', 'bag of tricks'],
    },

    lamp => {
        10 => ['oil lamp'],
        50 => ['magic lamp'],
    },

    flute => {
        12 => ['wooden flute'],
        36 => ['magic flute'],
    },

    horn => {
        15 => ['tooled horn'],
        50 => ['fire horn', 'frost horn', 'horn of plenty'],
    },

#    shirt => {
#        2 => ['T-shirt'],
#        3 => ['Hawaiian shirt'],
#    },

#    suit => {
#    },

    cloak => {
        50 => ['cloak of displacement', 'cloak of protection', 'oilskin cloak'],
        60 => ['cloak of invisibility', 'cloak of magic resistance',
               'elven cloak'],
    },

    helmet => {
         1 => ['dunce cap'],
        10 => ['helmet'],
        50 => ['helm of brilliance', 'helm of opposite alignment',
               'helm of telepathy'],
        80 => ['cornuthaum'],
    },

    gloves => {
         8 => ['leather gloves'],
        50 => ['gauntlets of dexterity', 'gauntlets of fumbling',
               'gauntlets of power'],
    },

#    shield => {
#        1 => [],
#    },

    boots => {
         8 => ['elven boots', 'kicking boots'],
        30 => ['fumble boots', 'levitation boots'],
        50 => ['jumping boots', 'speed boots', 'water walking boots'],
    },
);

# dynamically construct a list of all tools from each tool subtype
for my $in (qw/bag lamp flute horn/) {
    while (my ($price, $items) = each %{ $item_table{$in} }) {
        @{$item_table{tool}{$price}} = sort @{$item_table{tool}{$price} || []},
                                            @$items;
    }
}

# dynamically construct a list of all armor from each armor subtype
for my $in (qw/shirt suit cloak helmet gloves shield boots/) {
    # automatically calculate +1 .. +6
    my @prices = reverse sort keys %{ $item_table{$in} };
    for my $price (@prices) {
        for my $enchantment (1 .. 6) {
            my $newprice = $price + 10 * $enchantment;

            for my $item (@{ $item_table{$in}{$price} }) {
                push @{ $item_table{$in}{$newprice} }, "+$enchantment $item";
            }
        }
    }

    while (my ($price, $items) = each %{ $item_table{$in} }) {
        @{$item_table{armor}{$price}} = sort @{$item_table{armor}{$price}||[]},
                                             @$items;
    }
}

sub _croak {
    require Carp;
    Carp::croak(@_);
}

sub priceid {
    my %args = _canonicalize_args(@_);
    my @base;

    if ($args{in} eq 'sell') {
        @base = priceid_sell(%args, out => 'base');
    }
    elsif ($args{in} eq 'buy') {
        @base = priceid_buy(%args, out => 'base');
    }
    elsif ($args{in} eq 'base') {
        @base = priceid_base(%args, out => 'base');
    }

    return _canonicalize_output(\%args, @base);
}

sub priceid_buy {
    my %args = _canonicalize_args(@_);
    my @base;

    _croak "Calculating 'buy' prices requires that you set 'charisma'."
        if !defined $args{charisma};

    for my $base (keys %{ $item_table{ $args{type} } }) {
        my $tmp = $base;

        $tmp = 5 if !$tmp;

        my $surcharge = $tmp + $tmp / 3;

        for ($tmp, $surcharge) {
            $_ += $_ / 3 if $args{tourist};
            $_ += $_ / 3 if $args{dunce};

               if ($args{charisma} > 18) { $_ /= 2      }
            elsif ($args{charisma} > 17) { $_ -= $_ / 3 }
            elsif ($args{charisma} > 15) { $_ -= $_ / 4 }
            elsif ($args{charisma} < 6)  { $_ *= 2      }
            elsif ($args{charisma} < 8)  { $_ += $_ / 2 }
            elsif ($args{charisma} < 11) { $_ += $_ / 3 }

            $_ = 1 if $_ <= 0;

            if ($args{angry}) { $_ += ($_ + 2) / 3 }

            if (($_ * $args{quan}) == $args{amount}) {
                push @base, $base;
                last;
            }
        }
    }

    return _canonicalize_output(\%args, @base);
}

sub priceid_sell {
    my %args = _canonicalize_args(@_);
    my @base;

    for my $base (keys %{ $item_table{ $args{type} } }) {
        my $tmp = $base * $args{quan};

        if ($args{tourist})  { $tmp /= 3 }
        elsif ($args{dunce}) { $tmp /= 3 }
        else                 { $tmp /= 2 }

        my $surcharge = $tmp - $tmp / 4;
        $surcharge = $tmp unless $tmp > 1;

        for ($tmp, $surcharge) {
            if ($_ == $args{amount}) {
                push @base, $base;
                last;
            }
        }
    }

    return _canonicalize_output(\%args, @base);
}

sub priceid_base {
    my %args = _canonicalize_args(@_);
    return _canonicalize_output(\%args, $args{amount});
}

sub _canonicalize_args {
    my %args = (
        in   => 'base',
        out  => 'names',
        quan => 1,
        @_,
    );

    _croak "Price IDing requires that you set 'amount'"
        if !defined $args{amount};

    _croak "Price IDing requires that you set 'type'"
        if !defined $args{type};

    $args{type} = $glyph2type{ $args{type} } || $args{type};

    _croak "Unknown item type: $args{type}"
        if !exists $item_table{ $args{type} };

    return %args;
}

sub _canonicalize_output {
    my $args = shift;

    return map { [$_, @{ $item_table{ $args->{type} }{ $_ } || [] }] } sort @_
        if $args->{out} eq 'both';

    return sort @_ if $args->{out} eq 'base';
    return sort map {@{ $item_table{ $args->{type} }{ $_ } || [] }} @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NetHack::PriceID - identify NetHack items using shopkeepers

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use NetHack::PriceID 'priceid';
    print join ', ', priceid(
        type   => '?',
        amount => 100,
        in     => 'sell',
    );
    # amnesia, create monster, earth, taming

=head1 DESCRIPTION

NetHack, the game of princes, has a large item-identification subgame. The
quickest way to gauge how useful an item is is to "price identify" it. This
involves trying to buy or sell the item in a store, which tells you its price.
Item types (scrolls, potions, wands, etc) are each divided into about five
price groups -- price IDing cuts down a large number of possible identities of
an item.

The calculations for price IDing aren't that difficult, but making sure to get
all the edge cases (such as trying to identify items while the shopkeeper is
attacking you -- and charging you more money) can be twiddly.

This module also comes with a C<priceid> script.

=head1 FUNCTIONS

No functions are exported by default. Any of the following functions may be
exported in the usual manner.

=head2 priceid PARAMHASH

This is the method most people will be using. It will transform an amount and
other information into possible identities. Its arguments are passed as a
hash:

=over 4

=item type => scroll|ring|wand|...|?|=|/|... (required)

The item type. Valid values are the type name or its glyph: scroll (?), ring
(=), wand (/), amulet ("), spellbook (+), potion (!), tool ((), or armor ([).
Tools are broken down further into bag, lamp, flute, and horn. Armor is broken
down further into cloak, helmet, gloves, boots. Not specifying a type, or
specifying an invalid type, will cause an error to be thrown.

=item amount => INT (required)

The amount ("cost") of the item. How the priceid function interprets this
amount is dependent on the C<in> parameter. Not specifying an amount will cause
an error to be thrown.

=item in => buy|sell|base (default: base)

The type of operation. C<base> assumes the C<amount> is the base price. C<buy>
assumes the C<amount> is the amount of money the shopkeeper is charging you for
the item. C<sell> assumes the C<amount> is the number of Zorkmids the
shopkeeper is willing to give you in exchange for the item.

=item charisma => 3..25 (required for 'buy')

The charisma of the character. Base and sell prices are independent of
charisma, so it's required only for buying. This will croak if you try to
buy price-ID without setting the charisma.

=item out => base|names|both (default: names)

The output format. C<base> will return 0, 1, or 2 possible base prices that the
input can possibly be. Buying and selling always map to two prices, but usually
one of those prices has no items, so it is not given. C<names> will return the
actual names of the possible items. C<both> will return a list of array
references with the first element of each being the base price, and following
elements being the item names.

=item tourist => BOOL (default: false)

Determines whether the character suffers from the "tourist" surcharge.
Shopkeepers (as they presumably do in real life) will charge extra if they
think you're a tourist. Characters that are in the tourist class and less than
experience level 15 suffer this charge. Also, B<any> character that is wearing
a Hawaiian shirt or T-shirt without body armor or cloak suffers this charge.

=item dunce => BOOL (default: false)

Determines whether the character suffers from the "dunce" surcharge. This
applies to any character who is wearing a dunce cap. Whoops, should price ID
those conical hats to filter for cornuthaums.

=item angry => BOOL (default: false)

Determines whether the character suffers from the "angry shopkeeper" surcharge.
If the shopkeeper is attacking you, you'll probably want to set this one to
true. Warning: if you try to sell an item to an angry shopkeeper, they'll just
take it. That doesn't help much for identification.

=item quan => INT (default: 1)

How many items in the stack you're buying/selling. Most people try to identify
with only one item, but this is available if you take the path less trodden.

=back

=head2 priceid_buy PARAMHASH

Same as C<priceid> except with a default of C<< in => 'buy' >>.

=head2 priceid_sell PARAMHASH

Same as C<priceid> except with a default of C<< in => 'sell' >>.

=head2 priceid_base PARAMHASH

Same as C<priceid>, which does have a default of C<< in => 'base' >>, but I
cannot abide inconsistency.

=head1 EXAMPLES

=over 4

=item Selling

You are selling an unknown ring and want to know what kind it may be. We have
no unusual surcharges (and charisma is not needed when sell IDing).

    "Wonotobo offers 75 gold pieces for your clay ring.  Sell it?";

    priceid(in => 'sell',
            type => 'ring',
            amount => 75);
    => ('aggravate monster', 'cold resistance', 'fire
         resistance', 'free action', 'gain constitution', 'gain
         strength', 'increase accuracy', 'increase damage',
        'invisibility', 'levitation', 'poison resistance',
        'regeneration', 'searching', 'see invisible', 'shock
         resistance', 'slow digestion', 'teleportation')

Well, that's an awful lot of hits. Let's just look at the actual base prices
that we get back.

    priceid(in => 'sell',
            type => 'ring',
            amount => 75,
            out => 'base');
    => (150, 200)

Ah. So we are at one of those "could be two possible categories" sweet spots.
So we continue dropping the ring until we get a different price (which will
reflect a change in whether we get a random surcharge).

    "Wonotobo offers 100 gold pieces for your clay ring.  Sell it?";

    priceid(in => 'sell',
            type => 'ring',
            amount => 100)
    => ('fire resistance', 'free action', 'levitation',
        'regeneration', 'searching', 'slow digestion',
        'teleportation')

=item Buying with mods

This game has not been going well. This wizard has had his cloak of magic
resistance stolen by a nymph. The conical hat that he hurriedly put on turned
out to be a dunce cap. Furthermore, nothing is covering his cursed Hawaiian
shirt. He has just found a store and is pricing the items in it. He picks up a
wand...

    "For you, most gracious sir; only 888 for this curved wand.";

    priceid(charisma => 9,
            in => 'buy',
            type => 'wand',
            dunce => 1,
            tourist => 1,
            amount => 888)
    => ('death', 'wishing')

He quickly zaps the wand, wishes for a cockatrice corpse with which to kill the
shopkeeper, and turns to stone... oops, no gloves!

=back

=head1 TODO

=over 4

=item User-defined item tables

This would be mostly useful for Slash'EM and Sporkhack. Does Slash'EM even use
the same cost calculations? Probably.

=item Ignore trivial identifications

Yes, we know that C<an unlabeled scroll> is blank paper, and C<clear potion> is
water. We usually don't need the module to report these.

=item How much would this item cost?

This is already implemented, somewhat, it's just hidden in C<priceid_buy> and
C<priceid_sell>. It should be factored out and made into API.

=item Parse the actual NetHack output

It'd be great if all we had to do is hand in the string

    Wonotobo offers 30 gold pieces for your scroll labeled KIRJE.  Sell it?

and have the module figure out the relevant bits. Also, possibly, the entire
screen (so that charisma could be discerned).

=item Ignore items I already know

You could pass in a list of items that you've already identified or ruled out,
and the module would not include those in the list of possibilities.

=back

=head1 SEE ALSO

=over 4

=item Clippy

L<http://nethack.roy.org/clippy/clippy.pl>

=item HiSPeed's NetHack Helper

L<http://nethack.holics.at/nh-helper-public/nh-helper.html>

=item NetHack Object Identification Spoiler

L<http://www.chiark.greenend.org.uk/~damerell/games/nhid.html>

=item Interhack

L<http://taeb.github.io/interhack/>

=back

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
