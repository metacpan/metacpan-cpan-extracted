use strict;
use warnings;
use Test::More;
use NetHack::Logfile::Entry;

my %values = (
    ascended       => '',
    birth_date     => 19991125,
    current_depth  => 11,
    current_hp     => 0,
    death          => 'killed by a leocrotta',
    death_date     => 19991126,
    deaths         => 1,
    deepest_depth  => 11,
    dungeon        => 'The Gnomish Mines',
    dungeon_number => 2,
    gender         => 'female',
    maximum_hp     => 101,
    player         => 'Shana',
    role           => 'valkyrie',
    score          => 31744,
    uid            => 1,
    version        => '3.2.2',
);

plan tests => 1 + keys %values;

my $line = "3.2.2 31744 2 11 11 0 101 1 19991126 19991125 1 VF Shana,killed by a leocrotta";
my $entry = NetHack::Logfile::Entry->new_from_line($line);

for my $method (sort keys %values) {
    is_deeply($entry->$method, $values{$method}, $method);
}

is($line, $entry->as_line, 'parse <-> as_line are reversible');
