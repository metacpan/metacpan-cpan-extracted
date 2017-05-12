use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

use FindBin;
use lib $FindBin::Bin;

BEGIN {
	throws_ok {
		eval <<'EOF';
use Module::AnyEvent::Helper::Filter -as => 'TestAsync4Args', -target => 'Test',
	-transformer => 'NotExistent',
	-remove_func => [qw(func1 func2)], -translate_func => [qw(func3)],
	-replace_func => [qw(func4)], -delete_func => [qw(new)];
EOF
		die $@ if $@;
	} qr /Can't load Module::AnyEvent::Helper::PPI::Transform::NotExistent/, 'not-existent transformer';
}
