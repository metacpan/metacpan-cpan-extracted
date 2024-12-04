use strict;
use warnings;
use 5.010;
use Test::More;
use Temperature::Calculate::DegreeDays;

my $dd = Temperature::Calculate::DegreeDays->new();  # Defaults
ok( defined $dd, 'new() returned a defined result' );
ok( $dd->isa('Temperature::Calculate::DegreeDays'), '  and it is blessed into the right class!' );

is( $dd->cooling(-50), 0,    '  Test cooling(-50)'   );
is( $dd->cooling(100), 35,   '  Test cooling(100)'   );
is( $dd->cooling(65), 0,     '  Test cooling(65);'   );
is( $dd->cooling(65,85), 10, '  Test cooling(65,85)' );
ok( ! defined($dd->cooling("NaN") <=> 0),    '  Test cooling("NaN")' );
ok( ! defined($dd->cooling("string") <=> 0), '  Test cooling("string")' );
ok( ! defined(eval { $dd->cooling(); }),     '  Test that cooling() croaks' );

is( $dd->heating(100), 0,    '  Test heating(100)'   );
is( $dd->heating(0), 65,     '  Test heating(0)'   );
is( $dd->heating(65), 0,     '  Test heating(65);'   );
is( $dd->heating(45,65), 10, '  Test heating(45,65)' );
ok( ! defined($dd->heating("NaN") <=> 0),    '  Test heating("NaN")' );
ok( ! defined($dd->heating("string") <=> 0), '  Test heating("string")' );
ok( ! defined(eval { $dd->heating(); }),     '  Test that heating() croaks' );

is( $dd->growing(0,10), 0,    '  Test growing(0,10)'   );
is( $dd->growing(60,80), 20,  '  Test growing(60,80)'  );
is( $dd->growing(73,105), 30, '  Test growing(73,105)' );
is( $dd->growing(90,100), 36, '  Test growing(90,100)' );
ok( ! defined(eval { $dd->growing(); }),  '  Test that growing() croaks' );
ok( ! defined(eval { $dd->growing(1); }), '  Test that growing(1) croaks' );

my $dd2 = Temperature::Calculate::DegreeDays->new({ BASE => 18, GBASE => 0, GCEILING => 27, MISSING => -9999 });
ok( defined $dd2, 'new({ BASE => 18, GBASE => 0, GCEILING => 27, MISSING => -9999 }) returned a defined result' );
ok( $dd2->isa('Temperature::Calculate::DegreeDays'), '  and it is blessed into the right class!' );

is( $dd2->cooling(-9999), -9999,    '  Test cooling(-9999)' );
is( $dd2->cooling("NaN"), -9999,    '  Test cooling("NaN")' );
is( $dd2->cooling("string"), -9999, '  Test cooling("string")' );

is( $dd2->heating(-9999), -9999,    '  Test heating(-9999)' );
is( $dd2->heating("NaN"), -9999,    '  Test heating("NaN")' );
is( $dd2->heating("string"), -9999, '  Test heating("string")' );

is( $dd2->growing(-9999,-9999), -9999,       '  Test growing(-9999,-9999)' );
is( $dd2->growing("NaN","NaN"), -9999,       '  Test growing("NaN","NaN")' );
is( $dd2->growing("string","string"), -9999, '  Test growing("string","string")' );

my $bd;
ok( ! defined(eval { $bd = Temperature::Calculate::DegreeDays->new({ BASE     => "not-ok" }) } ), 'new({ BASE => "not-ok" }) croaks' );
ok( ! defined(eval { $bd = Temperature::Calculate::DegreeDays->new({ GBASE    => "not-ok" }) } ), 'new({ GBASE => "not-ok" }) croaks' );
ok( ! defined(eval { $bd = Temperature::Calculate::DegreeDays->new({ GCEILING => "not-ok" }) } ), 'new({ GCEILING => "not-ok" }) croaks' );
ok( ! defined(eval { $bd = Temperature::Calculate::DegreeDays->new({ MISSING  => "not-ok" }) } ), 'new({ MISSING => "not-ok" }) croaks' );

done_testing();

exit 0;

