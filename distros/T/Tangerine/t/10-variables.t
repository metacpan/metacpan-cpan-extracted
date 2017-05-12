use strict;
use warnings;
use Test::More tests => 7;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/variables');

ok($scanner->run, 'Variables run');

my %expectedcompile = (
    Echo => {
        count => 1,
        lines => [ 5 ],
    },
);

my %expectedruntime = (
    Foxtrot => {
        count => 1,
        lines => [ 6 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expectedcompile], 'Variables compile');
for (sort keys %expectedcompile) {
    is(scalar @{$scanner->compile->{$_}}, $expectedcompile{$_}->{count},
        "Variables compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expectedcompile{$_}->{lines}, "Variables compile line numbers ($_)");
}
is_deeply([sort keys %{$scanner->runtime}], [sort keys %expectedruntime], 'Variables runtime');
for (sort keys %expectedruntime) {
    is(scalar @{$scanner->runtime->{$_}}, $expectedruntime{$_}->{count},
        "Variables runtime count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->runtime->{$_}} ],
        $expectedruntime{$_}->{lines}, "Variables runtime line numbers ($_)");
}
