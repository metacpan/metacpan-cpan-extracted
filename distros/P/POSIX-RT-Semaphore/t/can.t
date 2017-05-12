#! /usr/bin/perl
#
# cancan.t
#
# Basic semaphore method tests
#

use Test::More tests => 26;
use POSIX::RT::Semaphore;
use UNIVERSAL qw(can);
use strict;

ok(1, "use/import ok");

our @METHODS_COMMON  = qw(wait trywait timedwait post getvalue name);
our @METHODS_NAMED   = qw(open close);
our @METHODS_UNNAMED = qw(init destroy);
our @METHODS_NONOBJ  = qw(unlink);

sub cando($@) {
	my ($class, @methods) = @_;
	for my $m (@methods) {
		can_ok($class, $m);
	}
}

sub cannotdo($@) {
	my ($class, @methods) = @_;
	for my $m (@methods) {
		ok(!$class->can($m), "$class cannot $m()");
	}
}

# -- Base package methods

cando("POSIX::RT::Semaphore", qw(init open));
cando("POSIX::RT::Semaphore", @METHODS_NONOBJ);

# -- Named psem methods

cando("POSIX::RT::Semaphore::Named", @METHODS_COMMON);
cando("POSIX::RT::Semaphore::Named", @METHODS_NAMED);

cannotdo("POSIX::RT::Semaphore::Named", @METHODS_UNNAMED);
cannotdo("POSIX::RT::Semaphore::Named", @METHODS_NONOBJ);

# -- Unnamed psem methods

cando("POSIX::RT::Semaphore::Unnamed", @METHODS_COMMON);
cando("POSIX::RT::Semaphore::Unnamed", @METHODS_UNNAMED);

cannotdo("POSIX::RT::Semaphore::Unnamed", @METHODS_NAMED);
cannotdo("POSIX::RT::Semaphore::Unnamed", @METHODS_NONOBJ);
