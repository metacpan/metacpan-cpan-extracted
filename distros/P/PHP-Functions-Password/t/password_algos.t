use strict;
use warnings;
use Test::More;
use lib qw(../lib);

my @methods = map { $_, "password_$_"; } qw(
	algos
);


plan tests => 1 + scalar(@methods) + 2;

my $class = 'PHP::Functions::Password';
use_ok($class) || BAIL_OUT("Failed to use $class");

foreach my $method (@methods) {
	can_ok($class, $method);
	if ($method =~ /^password/) {
		$class->import($method);
	}
}

my @algos = password_algos();
ok(@algos > 0, 'password_algos() returns an array of at least 1 element');
ok((grep { $_ eq '2y' } @algos), 'Result of password_algos() contains at least "2y"');

unless($ENV{'HARNESS_ACTIVE'}) {
	#require Data::Dumper; Data::Dumper->import('Dumper'); no warnings; local $Data::Dumper::Terse = 1;
	note('password_algos: ' . join(', ', @algos));
}
