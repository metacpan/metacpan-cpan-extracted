use strict;
use warnings;
use Test::More tests => 17;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/if');

ok($scanner->run, 'If run');

my %expected = (
    if => {
        count => 6,
        lines => [ 1 .. 6 ],
    },
    Alfa => {
        count => 1,
        lines => [ 1 ],
    },
    Beta => {
        count => 1,
        lines => [ 2 ],
    },
    Delta => {
        count => 1,
        lines => [ 4 ],
    },
    Mo => {
        count => 1,
        lines => [ 5 ],
    },
    'Mo::default' => {
        count => 1,
        lines => [ 5 ],
    },
    'Mo::xs' => {
        count => 1,
        lines => [ 5 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expected], 'If compile');
for (sort keys %expected) {
    is(scalar @{$scanner->compile->{$_}}, $expected{$_}->{count},
        "If compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expected{$_}->{lines}, "If compile line number ($_)");
}
is($scanner->compile->{if}->[3]->version, '0.05', 'If version');
