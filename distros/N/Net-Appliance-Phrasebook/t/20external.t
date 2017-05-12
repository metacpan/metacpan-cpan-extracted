#!/usr/bin/perl

use strict;
use Test::More tests => 15;

my ($class, $pb);
BEGIN {
    $class = 'Net::Appliance::Phrasebook';
    use_ok($class);
}

my $file = 't/20external.yaml';

eval {$pb = $class->new(source => $file, platform => 'three')};
isa_ok( $pb, 'Data::Phrasebook::Generic', 'New with platform and file');

is( $pb->fetch('dog'), 'woof', 'fetch 1');
eval {$pb->fetch('FGHIJ')};
like( $@, qr/^No mapping for 'FGHIJ'/, 'bogus fetch 1');

eval {$pb = $class->new(source => $file, platform => ['three','four','one'])};
isa_ok( $pb, 'Data::Phrasebook::Generic', 'New with platform and file');

is( $pb->fetch('dog'), 'woof', 'fetch 2');
is( $pb->fetch('god'), 'burning bush', 'fetch 3');
is( $pb->fetch('cabbage'), 'cooked', 'fetch 4');
is( $pb->fetch('sprout'), 'raw', 'fetch 5 - default');


eval {$pb = $class->new(source => $file, platform => ['four','one','five'])};
isa_ok( $pb, 'Data::Phrasebook::Generic', 'New with platform and file');

is( $pb->fetch('dog'), 'cat', 'fetch 6');
is( $pb->fetch('cat'), 'dog', 'fetch 7');
is( $pb->fetch('cabbage'), 'cooked', 'fetch 8');
is( $pb->fetch('sprout'), 'raw', 'fetch 9');

eval {$pb->fetch('KLMNO')};
like( $@, qr/^No mapping for 'KLMNO'/, 'bogus fetch 2');
