package TAEB::World::Spell;
use TAEB::OO;
use List::Util qw/max min/;

use overload %TAEB::Meta::Overload::default;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has learned_at => (
    is       => 'rw',
    isa      => 'Int',
    default  => sub { TAEB->turn },
);

has fail => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has slot => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has spoiler => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        NetHack::Item::Spoiler->spoiler_for("spellbook of " . $self->name);
    },
);

for my $attribute (qw/level read marker role emergency/) {
    __PACKAGE__->meta->add_method($attribute => sub {
        my $self = shift;
        $self->spoiler->{$attribute};
    });
}

=head2 castable

Can this spell be cast this turn? This does not only take into account spell
age, but also whether you're confused, have enough power, etc.

=cut

sub castable {
    my $self = shift;

    return 0 if $self->forgotten;
    return 0 if $self->power > TAEB->power;

    # "You are too hungry to cast!" (detect food is exempted by NH itself)
    return 0 if TAEB->nutrition <= 10 && $self->name ne 'detect food';

    return 1;
}

sub failure_rate {
    my $self = shift;
    my %penalties = (
        # role base emergency shield suit int/wis
        Arc => [ 5,   0,  2,  10, 'int' ],
        Bar => [ 14,  0,  0,  8,  'int' ],
        Cav => [ 12,  0,  1,  8,  'int' ],
        Hea => [ 3,  -3,  2,  10, 'wis' ],
        Kni => [ 8,  -2,  0,  9,  'wis' ],
        Mon => [ 8,  -2,  2,  20, 'wis' ],
        Pri => [ 3,  -3,  2,  10, 'wis' ],
        Ran => [ 9,   2,  1,  10, 'int' ],
        Rog => [ 8,   0,  1,  9,  'int' ],
        Sam => [ 10,  0,  0,  8,  'int' ],
        Tou => [ 5,   1,  2,  10, 'int' ],
        Val => [ 10, -2,  0,  9,  'wis' ],
        Wiz => [ 1,   0,  3,  10, 'int' ],
    );

    my $penalty = $penalties{TAEB->role}->[0];

    # this is where inventory penalty calculation would go

    $penalty += $penalties{TAEB->role}->[1] if $self->emergency;
    $penalty -= 4 if $self->role eq TAEB->role;

    my $chance;
    my $SKILL = 0; # XXX: this needs to reference skill levels
    my $basechance = int(TAEB->($penalties{TAEB->role}->[4]) * 11 / 2);
    my $diff = (($self->level - 1) * 4 - ($SKILL * 6 + int(TAEB->xl / 3) + 1));
    if ($diff > 0) {
        $chance = $basechance - int(sqrt(900 * $diff + 2000));
    }
    else {
        my $learning = int(((-15) * $diff) / $SKILL);
        $chance = $basechance + min($learning, 20);
    }

    $chance = max(min($chance, 120), 0);

    # shield and special spell

    $chance = int($chance * (20 - $penalty) / 15) - $penalty;
    $chance = max(min($chance, 100), 0);

    return $chance;
}

sub forgotten {
    my $self = shift;
    return TAEB->turn > $self->learned_at + 20_000;
}

sub debug_line {
    my $self = shift;

    return sprintf '%s - %s (%d]',
           $self->slot,
           $self->name,
           $self->learned_at;
}

sub power { 5 * shift->level }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

