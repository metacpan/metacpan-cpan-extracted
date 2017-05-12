use strict;
use warnings;
use Test::More tests => 18;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/inline');

ok($scanner->run, 'Inline run');

my %expected = (
    Alfa => {
        count => 1,
        lines => [ 6 ],
    },
    Bravo => {
        count => 1,
        lines => [ 7 ],
    },
    Charlie => {
        count => 1,
        lines => [ 7 ],
    },
    Delta => {
        count => 1,
        lines => [ 7 ],
    },
    Inline => {
        count => 10,
        lines => [ 1 .. 10 ],
    },
    'Inline::C' => {
        count => 1,
        lines => [ 2 ],
    },
    'Inline::Java' => {
        count => 1,
        lines => [ 3 ],
    },
    'Inline::Python' => {
        count => 3,
        lines => [ 8 .. 10 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expected], 'Inline compile');
for (sort keys %expected) {
    is(scalar @{$scanner->compile->{$_}}, $expected{$_}->{count},
        "Inline compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expected{$_}->{lines}, "Inline compile line number ($_)");
}
