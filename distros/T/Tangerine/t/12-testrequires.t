use strict;
use warnings;
use Test::More tests => 28;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/testrequires');

ok($scanner->run, 'Test::Requires run');

my %expectedcompile = (
    Alfa => {
        count => 1,
        lines => [ 1 ],
    },
    Beta => {
        count => 1,
        lines => [ 1 ],
    },
    Charlie => {
        count => 1,
        lines => [ 1 ],
    },
    Delta => {
        count => 1,
        lines => [ 2 ],
    },
    Echo => {
        count => 1,
        lines => [ 2 ],
    },
    Foxtrot => {
        count => 1,
        lines => [ 2 ],
    },
    Golf => {
        count => 1,
        lines => [ 3 ],
    },
    Hotel => {
        count => 1,
        lines => [ 3 ],
    },
    'Test::Requires' => {
        count => 3,
        lines => [ 1 .. 3 ],
    },
);

my %expectedreqs = (
    India => {
        count => 1,
        lines => [ 7 ],
    },
    Juliett => {
        count => 1,
        lines => [ 8 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expectedcompile], 'Test::Requires compile');
for (sort keys %expectedcompile) {
    is(scalar @{$scanner->compile->{$_}}, $expectedcompile{$_}->{count},
        "Test::Requires compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expectedcompile{$_}->{lines}, "Requires compile line numbers ($_)");
}

is_deeply([sort keys %{$scanner->runtime}], [sort keys %expectedreqs], 'Test::Requires runtime');
for (sort keys %expectedreqs) {
    is(scalar @{$scanner->runtime->{$_}}, $expectedreqs{$_}->{count},
        "Test::Requires runtime count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->runtime->{$_}} ],
        $expectedreqs{$_}->{lines}, "Requires runtime line numbers ($_)");
}

is($scanner->compile->{Golf}->[0]->version, '1.00', 'Test::Requires Golf version');
is($scanner->compile->{Hotel}->[0]->version, '2.00', 'Test::Requires Hotel version');
is($scanner->runtime->{Juliett}->[0]->version, '3.00', 'Test::Requires Juliett version');
