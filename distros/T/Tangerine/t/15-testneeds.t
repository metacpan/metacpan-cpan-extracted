use strict;
use warnings;
use Test::More tests => 22;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/testneeds');

ok($scanner->run, 'Test::Needs run');

my %expectedcompile = (
    Alfa => {
        count => 1,
        lines => [ 1 ],
    },
    Bravo => {
        count => 1,
        lines => [ 2 ],
    },
    Charlie => {
        count => 1,
        lines => [ 2 ],
    },
    Delta => {
        count => 1,
        lines => [ 3 ],
    },
    Echo => {
        count => 1,
        lines => [ 3 ],
    },
    'Test::Needs' => {
        count => 3,
        lines => [ 1..3 ],
    },
);

my %expectedreqs = (
    Foxtrot => {
        count => 1,
        lines => [ 7 ],
    },
    Golf => {
        count => 1,
        lines => [ 8 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expectedcompile], 'Test::Needs compile');
for (sort keys %expectedcompile) {
    is(scalar @{$scanner->compile->{$_}}, $expectedcompile{$_}->{count},
        "Test::Needs compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expectedcompile{$_}->{lines}, "Needs compile line numbers ($_)");
}

is_deeply([sort keys %{$scanner->runtime}], [sort keys %expectedreqs], 'Test::Needs runtime');
for (sort keys %expectedreqs) {
    is(scalar @{$scanner->runtime->{$_}}, $expectedreqs{$_}->{count},
        "Test::Needs runtime count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->runtime->{$_}} ],
        $expectedreqs{$_}->{lines}, "Needs runtime line numbers ($_)");
}

is($scanner->compile->{Delta}->[0]->version, '1.00', 'Test::Needs Delta version');
is($scanner->compile->{Echo}->[0]->version, '2.00', 'Test::Needs Echo version');
is($scanner->runtime->{Golf}->[0]->version, '3.00', 'Test::Needs Golf version');
