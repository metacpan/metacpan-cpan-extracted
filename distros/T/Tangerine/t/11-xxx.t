use strict;
use warnings;
use Test::More tests => 10;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/xxx');

ok($scanner->run, 'XXX run');

my %expectedcompile = (
    'Data::Dump::Color' => {
        count => 1,
        lines => [ 4 ],
    },
    'Data::Dumper' => {
        count => 1,
        lines => [ 2 ],
    },
    XXX => {
        count => 4,
        lines => [ 1 .. 4 ],
    },
    YAML => {
        count => 1,
        lines => [ 3 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expectedcompile], 'XXX compile');
for (sort keys %expectedcompile) {
    is(scalar @{$scanner->compile->{$_}}, $expectedcompile{$_}->{count},
        "XXX compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expectedcompile{$_}->{lines}, "XXX compile line numbers ($_)");
}
