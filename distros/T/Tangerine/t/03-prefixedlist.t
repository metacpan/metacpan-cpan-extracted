use strict;
use warnings;
use Test::More tests => 28;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/prefixedlist');

ok($scanner->run, 'Prefixed list run');

my %expected = (
    Mo => {
        count => 1,
        lines => [ 1 ],
    },
    'Mo::default' => {
        count => 1,
        lines => [ 1 ],
    },
    'Mo::xs' => {
        count => 1,
        lines => [ 1 ],
    },
    POE => {
        count => 2,
        lines => [ 2, 3 ],
    },
    'POE::Alpha' => {
        count => 1,
        lines => [ 2 ],
    },
    'POE::Bravo' => {
        count => 1,
        lines => [ 2 ],
    },
    'POE::Charlie' => {
        count => 1,
        lines => [ 2 ],
    },
    'POE::Delta' => {
        count => 1,
        lines => [ 2 ],
    },
    'POE::Echo' => {
        count => 2,
        lines => [ 2, 3 ],
    },
    'Tk::Foxtrot' => {
        count => 1,
        lines => [ 4 ],
    },
    'Tk::Golf' => {
        count => 1,
        lines => [ 4 ],
    },
    'Tk::Hotel' => {
        count => 1,
        lines => [ 4 ],
    },
    'Tk::widgets' => {
        count => 1,
        lines => [ 4 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expected], 'Prefixed list compile');
for (sort keys %expected) {
    is(scalar @{$scanner->compile->{$_}}, $expected{$_}->{count},
        "Prefixed list compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expected{$_}->{lines}, "Prefixed list compile line number ($_)");
}
