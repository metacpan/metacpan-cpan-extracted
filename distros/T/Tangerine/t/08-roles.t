use strict;
use warnings;
use Test::More tests => 23;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/roles');

ok($scanner->run, 'Roles run');

my %expectedcompile = (
    Moose => {
        count => 1,
        lines => [ 1 ],
    },
);

my %expectedruntime = (
    Alfa => {
        count => 1,
        lines => [ 2 ],
    },
    Beta => {
        count => 1,
        lines => [ 2 ],
    },
    Charlie => {
        count => 1,
        lines => [ 4 ],
    },
    Delta => {
        count => 1,
        lines => [ 4 ],
    },
    Echo => {
        count => 1,
        lines => [ 5 ],
    },
    Foxtrot => {
        count => 1,
        lines => [ 5 ],
    },
    Golf => {
        count => 1,
        lines => [ 6 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expectedcompile], 'Roles compile');
for (sort keys %expectedcompile) {
    is(scalar @{$scanner->compile->{$_}}, $expectedcompile{$_}->{count},
        "Roles compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expectedcompile{$_}->{lines}, "Roles compile line numbers ($_)");
}
is_deeply([sort keys %{$scanner->runtime}], [sort keys %expectedruntime], 'Roles runtime');
for (sort keys %expectedruntime) {
    is(scalar @{$scanner->runtime->{$_}}, $expectedruntime{$_}->{count},
        "Roles runtime count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->runtime->{$_}} ],
        $expectedruntime{$_}->{lines}, "Roles runtime line numbers ($_)");
}

is($scanner->runtime->{Alfa}->[0]->version, 0.01, 'Roles - Alfa version');
is($scanner->runtime->{Beta}->[0]->version, 0.02, 'Roles - Beta version');
is($scanner->runtime->{Foxtrot}->[0]->version, 0.03, 'Roles - Foxtrot version');
is($scanner->runtime->{Golf}->[0]->version, 0.04, 'Roles - Golf version');
