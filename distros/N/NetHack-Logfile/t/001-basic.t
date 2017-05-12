use strict;
use warnings;
use Test::More;
use NetHack::Logfile::Entry;

my %values = (
    alignment      => 'neutral',
    ascended       => 1,
    birth_date     => 20070414,
    current_depth  => -5,
    current_hp     => 997,
    death          => 'ascended',
    death_date     => 20070414,
    deaths         => 0,
    deepest_depth  => 50,
    dungeon        => 'Endgame',
    dungeon_number => 7,
    gender         => 'male',
    maximum_hp     => 1083,
    player         => 'Conducty1',
    race           => 'gnome',
    role           => 'healer',
    score          => 106150,
    uid            => 1031,
    version        => '3.4.3',
);

plan tests => 1 + keys %values;

my $line = "3.4.3 106150 7 -5 50 997 1083 0 20070414 20070414 1031 Hea Gno Mal Neu Conducty1,ascended";
my $entry = NetHack::Logfile::Entry->new_from_line($line);

for my $method (sort keys %values) {
    is_deeply($entry->$method, $values{$method}, $method);
}

is($line, $entry->as_line, 'parse <-> as_line are reversible');
