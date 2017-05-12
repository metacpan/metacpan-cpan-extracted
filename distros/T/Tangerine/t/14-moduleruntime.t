use strict;
use warnings;
use Test::More tests => 13;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/moduleruntime');

ok($scanner->run, 'Module::Runtime run');

my %expecteduse = (
    'Module::Runtime' => {
        count => 1,
        lines => [ 1 ],
    },
);
my %expectedreq = (
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
);

is_deeply([sort keys %{$scanner->compile}], [sort keys %expecteduse], 'Module::Runtime compile');
for (sort keys %expecteduse) {
    is(scalar @{$scanner->compile->{$_}}, $expecteduse{$_}->{count},
        "Module::Runtime compile count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{$_}} ],
        $expecteduse{$_}->{lines}, "Module::Runtime compile line number ($_)");
}
is_deeply([sort keys %{$scanner->runtime}], [sort keys %expectedreq], 'Module::Runtime runtime');
for (sort keys %expectedreq) {
    is(scalar @{$scanner->runtime->{$_}}, $expectedreq{$_}->{count},
        "Module::Runtime runtime count ($_)");
    is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->runtime->{$_}} ],
        $expectedreq{$_}->{lines}, "Module::Runtime runtime line number ($_)");
}
is($scanner->runtime->{Bravo}->[0]->version, '1.23', 'Module::Runtime Bravo version');
is($scanner->runtime->{Charlie}->[0]->version, '4.567', 'Module::Runtime Charlie version');
