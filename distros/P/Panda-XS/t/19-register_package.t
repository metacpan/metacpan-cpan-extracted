use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

ok(!exists $INC{'My/Jopa.pm'});

my $pxs_path = $INC{'Panda/XS.pm'};
ok($pxs_path);

my $ok = Panda::XS::Test::register_package('My::Jopa', 'Panda::XS');
ok($ok, "package registered ok");

is($INC{'My/Jopa.pm'}, $pxs_path, "registration path is ok");

$ok = Panda::XS::Test::register_package('My::Gopota', 'Panda::XS::NotExists');
ok(!$ok, "package is not registered within unexisting source");

done_testing();
