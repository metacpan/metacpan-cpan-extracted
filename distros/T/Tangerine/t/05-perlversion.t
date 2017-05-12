use strict;
use warnings;
use Test::More tests => 3;
use Tangerine;

my $scanner = Tangerine->new(file => 't/data/perlversion');

ok($scanner->run, 'Perlversion run');

is_deeply([keys %{$scanner->runtime}], [], 'Perlversion runtime');
is_deeply([keys %{$scanner->compile}], [], 'Perlversion compile');
