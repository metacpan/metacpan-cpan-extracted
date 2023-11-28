use Test::More;

use lib 't/lib';
use Role;
eval {
	my $k = Role->new();
};

like($@, qr/Can't locate object method "new" via package "Role"/);

ok(1);

done_testing();
