use strict;
use warnings;
use Test::More tests => 37;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/tests');

ok($scanner->run, 'Tests run');

my %expectedcompile = (
    'Test::More' => {
        count => 1,
        lines => [ 1 ],
    },
    Alfa => {
        count => 1,
        lines => [ 2 ],
    },
    Beta => {
        count => 1,
        lines => [ 3 ],
    },
    Charlie => {
        count => 1,
        lines => [ 4 ],
    },
    Delta => {
        count => 1,
        lines => [ 5 ],
    },
    Lima => {
        count => 1,
        lines => [ 13 ],
    },
    'Mike::November' => {
        count => 1,
        lines => [ 14 ],
    },
    Mo => {
        count => 3,
        lines => [ 9 .. 11 ],
    },
    'Mo::default' => {
        count => 2,
        lines => [ 9, 10 ],
    },
    'Mo::is' => {
        count => 2,
        lines => [ 9, 10 ],
    },
    'Mo::isa' => {
        count => 1,
        lines => [ 11 ],
    },
    'Mo::xs' => {
        count => 2,
        lines => [ 9, 10 ],
    },
    Oscar => {
        count => 1,
        lines => [ 18 ],
    },
    parent => {
        count => 1,
        lines => [ 13 ],
    },
);

my %expectedruntime = (
    Echo => {
        count => 1,
        lines => [ 6 ],
    },
    Foxtrot => {
        count => 1,
        lines => [ 7 ],
    },
    India => {
        count => 1,
        lines => [ 8 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expectedcompile], 'Tests compile');
for (sort keys %expectedcompile) {
    is(scalar @{$scanner->compile->{$_}}, $expectedcompile{$_}->{count},
        "Tests compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expectedcompile{$_}->{lines}, "Tests compile line numbers ($_)");
}
is_deeply([sort keys %{$scanner->runtime}], [sort keys %expectedruntime], 'Tests runtime');
for (sort keys %expectedruntime) {
    is(scalar @{$scanner->runtime->{$_}}, $expectedruntime{$_}->{count},
        "Tests runtime count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->runtime->{$_}} ],
        $expectedruntime{$_}->{lines}, "Tests runtime line numbers ($_)");
}
