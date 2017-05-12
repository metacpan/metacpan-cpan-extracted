use strict;
use warnings;
use Test::More tests => 21;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/moduleload');

ok($scanner->run, 'Module::Load run');

my %expectedcompile = (
    'Module::Load' => {
        count => 1,
        lines => [ 1 ],
    },
);

my %expectedruntime = (
    Alfa => {
        count => 1,
        lines => [ 2 ],
    },
    Bravo => {
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
    POE => {
        count => 1,
        lines => [ 6 ],
    },
    'POE::Driver' => {
        count => 1,
        lines => [ 6 ],
    },
    'POE::Filter' => {
        count => 1,
        lines => [ 6 ],
    },
    'POE::Wheel' => {
        count => 1,
        lines => [ 6 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expectedcompile], 'Module::Load compile');
for (sort keys %expectedcompile) {
    is(scalar @{$scanner->compile->{$_}}, $expectedcompile{$_}->{count},
        "Module::Load compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expectedcompile{$_}->{lines}, "Module::Load compile line numbers ($_)");
}
is_deeply([sort keys %{$scanner->runtime}], [sort keys %expectedruntime], 'Module::Load runtime');
for (sort keys %expectedruntime) {
    is(scalar @{$scanner->runtime->{$_}}, $expectedruntime{$_}->{count},
        "Module::Load runtime count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->runtime->{$_}} ],
        $expectedruntime{$_}->{lines}, "Module::Load runtime line numbers ($_)");
}
