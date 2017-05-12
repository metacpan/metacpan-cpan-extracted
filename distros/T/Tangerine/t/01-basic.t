use strict;
use warnings;
use Test::More tests => 20;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/basic');

ok($scanner->run, 'Basic run');

is_deeply([sort keys %{$scanner->package}], [qw/Alfa/], 'Basic package');
is(scalar @{$scanner->package->{Alfa}}, 1, 'Basic package count');
is($scanner->package->{Alfa}->[0]->line, 1, 'Basic package line number');

is_deeply([sort keys %{$scanner->runtime}], [qw/Echo Foxtrot Golf/], 'Basic runtime');
is(scalar @{$scanner->runtime->{Echo}}, 1, 'Basic runtime count (Echo)');
is(scalar @{$scanner->runtime->{Foxtrot}}, 1, 'Basic runtime count (Foxtrot)');
is(scalar @{$scanner->runtime->{Golf}}, 1, 'Basic runtime count (Golf)');
is($scanner->runtime->{Echo}->[0]->line, 6, 'Basic runtime line number (Echo)');
is($scanner->runtime->{Foxtrot}->[0]->line, 7, 'Basic runtime line number (Foxtrot)');
is($scanner->runtime->{Golf}->[0]->line, 8, 'Basic runtime line number (Golf)');

my %expected = (
    Bravo => {
        count => 2,
        lines => [ 2, 3 ],
    },
    Charlie => {
        count => 1,
        lines => [ 4 ],
    },
    Delta => {
        count => 1,
        lines => [ 5 ],
    },
    Hotel => {
        count => 1,
        lines => [ 12 ],
    },
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expected], 'Basic compile');
for (sort keys %expected) {
    is(scalar @{$scanner->compile->{$_}}, $expected{$_}->{count},
        "Basic compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expected{$_}->{lines}, "Basic compile line number ($_)");
}
