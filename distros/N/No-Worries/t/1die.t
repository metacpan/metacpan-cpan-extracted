#!perl

use strict;
use warnings;
use Test::More tests => 12;

use No::Worries::Die qw(*);

$No::Worries::Die::Prefix = "XXX";

sub test ($@) {
    my($message, @arguments) = @_;
    dief($message, @arguments);
}

foreach my $env ("", qw(whatever confess croak)) {
    if ($env) {
	$ENV{NO_WORRIES} = $env;
    } else {
	delete($ENV{NO_WORRIES});
    }
    eval { test("error code: %d") };
    is($@, "error code: %d\n", "string+$env");
    eval { test("error code: %d", 123) };
    is($@, "error code: 123\n", "format+$env");
    eval { test("  error code: %d\n", 123) };
    is($@, "error code: 123\n", "spaces+$env");
}
