package NetHack::Logfile::Entry::32;
our $VERSION = '1.00';

use Moose;
use Moose::Util::TypeConstraints 'enum';
use NetHack::Logfile::Util;
extends 'NetHack::Logfile::Entry';

field score => (
    isa => 'Int',
);

field dungeon => (
    isa => (enum [
       "The Dungeons of Doom",
       "Gehennom",
       "The Gnomish Mines",
       "The Quest",
       "Sokoban",
       "Fort Ludios",
       "Vlad's Tower",
       "Endgame",
    ]),
);

field current_depth => (
    isa => 'Int',
);

field deepest_depth => (
    isa => 'Int',
);

field current_hp => (
    isa => 'Int',
);

field maximum_hp => (
    isa => 'Int',
);

field deaths => (
    isa => 'Int',
);

field 'birth_date';

field 'death_date';

field uid => (
    isa => 'Int',
);

field role => (
    isa => (enum [qw/archeologist barbarian caveman elf healer knight priest rogue samurai tourist valkyrie wizard/]),
);

field gender => (
    isa => (enum [qw/male female/]),
);

field 'player';

field 'death';

my @fields = qw/version score dungeon current_depth deepest_depth current_hp
                maximum_hp deaths death_date birth_date uid role gender player
                death/;
sub parse {
    my $self  = shift;
    my $input = shift;

    return unless my @captures = $input =~ m{
        ^             # start of line
        ([\d\.]+) [ ] # version
        ([\d\-]+) [ ] # score
        ([\d\-]+) [ ] # dungeon
        ([\d\-]+) [ ] # current_depth
        ([\d\-]+) [ ] # deepest_depth
        ([\d\-]+) [ ] # current_hp
        ([\d\-]+) [ ] # maximum_hp
        (\d+)     [ ] # deaths
        (\d+)     [ ] # death_date
        (\d+)     [ ] # birth_date
        (\d+)     [ ] # uid
        ([A-Z])       # role
        ([MF])    [ ] # gender
        ([^,]+)       # player
        ,             # literal comma
        (.*)          # death
        $             # end of line
    }x;

    my %parsed;
    @parsed{@fields} = @captures;

    return \%parsed;
}

my @dungeons = (
    "The Dungeons of Doom",
    "Gehennom",
    "The Gnomish Mines",
    "The Quest",
    "Sokoban",
    "Fort Ludios",
    "Vlad's Tower",
    "Endgame",
);
sub canonicalize_dungeon {
    my $self = shift;
    my $dnum = shift;

    return $dungeons[$dnum];
}

my %roles = (
    A => 'archeologist',
    B => 'barbarian',
    C => 'caveman',
    E => 'elf',
    H => 'healer',
    K => 'knight',
    P => 'priest',
    R => 'rogue',
    S => 'samurai',
    T => 'tourist',
    V => 'valkyrie',
    W => 'wizard',
);
sub canonicalize_role {
    my $self   = shift;
    my $letter = shift;

    return $roles{$letter};
}

my %genders = (
    M => 'male',
    F => 'female',
);
sub canonicalize_gender {
    my $self   = shift;
    my $letter = shift;

    return $genders{$letter};
}

my @output_methods = qw/version score dungeon_number current_depth deepest_depth
                        current_hp maximum_hp deaths death_date birth_date uid
                        role_one gender_one player death/;

sub as_line {
    my $self = shift;

    sprintf '%s %d %d %d %d %d %d %d %d %d %d %1.1s%1.1s %s,%s',
        map { $self->$_ } @output_methods;
}


sub ascended { shift->death eq 'ascended' }

my %dungeon_number = (
    "The Dungeons of Doom" => 0,
    "Gehennom"             => 1,
    "The Gnomish Mines"    => 2,
    "The Quest"            => 3,
    "Sokoban"              => 4,
    "Fort Ludios"          => 5,
    "Vlad's Tower"         => 6,
    "Endgame"              => 7,
);
sub dungeon_number {
    my $self    = shift;
    my $dungeon = $self->dungeon || shift;

    return $dungeon_number{$dungeon};
}

sub abbreviate_cg {
    my $self   = shift;
    my $method = shift;

    return ucfirst substr($self->$method, 0, 1);
}
sub role_one   { shift->abbreviate_cg('role')   }
sub gender_one { shift->abbreviate_cg('gender') }

__PACKAGE__->meta->make_immutable;
no Moose;
no Moose::Util::TypeConstraints;

1;

__END__

=head1 NAME

NetHack::Logfile::Entry::32 - a finished game of NetHack 3.2.0 or later

=head1 VERSION

version 1.00

=head1 DESCRIPTION

See the superclass L<NetHack::Logfile::Entry> for some more information.

As this is the oldest version of NetHack supported by this module, all of the
fields are in this module.

=head1 FIELDS

=head2 score

=head2 dungeon

This is a string representing the dungeon, such as "The Gnomish MineS".
You may want L</dungeon_number>.

=head2 current_depth

=head2 deepest_depth

=head2 current_hp

=head2 maximum_hp

=head2 deaths

The number of times the character has died on the adventure. Usually this will
be 1, but could be fewer if the game did not end in death. It could be more if
the character was revived during the course of the adventure.

=head2 birth_date

A string (e.g. C<20090517>) representing the date that the game began.

=head2 end_date

A string (e.g. C<20090517>) representing the date that the game ended.

=head2 uid

The UNIX user ID of the game's human player.

=head2 role

The role of the character, e.g. C<archeologist>.

You may want the L<role_one> method which gives you the role's capital initial (e.g. C<A> for archeologist).

=head2 gender

The gender of the character, C<male> or C<female>.

You may want the L<gender_one> method which gives you the gender's capital
initial (e.g. C<F> for female).

=head2 player

The name of the player or character.

=head2 death

NetHack's description of how the game ended. Ideally it would be C<ascended>.

=head1 METHODS

=head2 as_line

Renders this entry as a line in the logfile. This is constructed dynamically
(instead of being cached from parse time).

=head2 dungeon_number

Provides the dungeon I<number> instead of I<name>. Useful for doing your own
naming or other kind of indexing, I suppose.

=head2 role_one

The capital one-letter abbreviation of the character's role.

=head2 gender_one

The capital one-letter abbreviation of the character's role.

=cut