use strict;
use warnings;
use Test::More tests => 5;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/versioned');

ok($scanner->run, 'Versioned run');

is_deeply([sort keys %{$scanner->compile}], [qw/Foo/], 'Versioned compile');
is(scalar @{$scanner->compile->{Foo}}, 5, 'Prefixed list compile count');
is_deeply([ sort { $a <=> $b } map { $_->line } @{$scanner->compile->{Foo}} ],
    [ 1 .. 5 ], 'Versioned line numbers');
is_deeply([ sort map { $_->version } @{$scanner->compile->{Foo}} ],
    [ qw/1.00 1.01 1.02 1.99 v2.00.00/ ], 'Versioned versions');
