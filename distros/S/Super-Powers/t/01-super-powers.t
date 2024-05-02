use Test::More;
use strict;
use warnings;
use Super::Powers;

my $sapien = Super::Powers->new();

for (qw/motor vision hearing mind speech smell taste touch emotion/) {
	$sapien->{$_}->print;
	print "\n";
}

ok(1);

done_testing();

