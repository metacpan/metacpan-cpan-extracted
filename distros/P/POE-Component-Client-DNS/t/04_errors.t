#!/usr/bin/perl -w
# vim: filetype=perl

# Deliberately trigger errors.

use strict;

sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }
use POE qw(Component::Client::DNS);

use Test::More tests => 10;
use Test::NoWarnings;

# Avoid a warning.
POE::Kernel->run();

{
	eval { POE::Component::Client::DNS->spawn(1); };
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is(
		$err, "POE::Component::Client::DNS requires an even number of parameters"
	);
}

{
	eval { POE::Component::Client::DNS->spawn(moo => "nope"); };
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is(
		$err, "POE::Component::Client::DNS doesn't know these parameters: moo"
	);
}

my $resolver = POE::Component::Client::DNS->spawn();

{
	eval {
		$poe_kernel->call(
			"resolver", "resolve", {
			}
		);
	};
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is($err, "Must include an 'event' in Client::DNS request");
}

{
	eval {
		$poe_kernel->call(
			"resolver", "resolve", {
				event => "moo",
			}
		);
	};
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is($err, "Must include a 'context' in Client::DNS request");
}

{
	eval {
		$poe_kernel->call(
			"resolver", "resolve", {
				event   => "moo",
				context => "bar",
			}
		);
	};
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is($err, "Must include a 'host' in Client::DNS request");
}

{
	eval {
		$resolver->resolve(1);
	};
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is($err, "resolve() needs an even number of parameters");
}

{
	eval {
		$resolver->resolve();
	};
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is($err, "resolve() must include an 'event'");
}

{
	eval {
		$resolver->resolve(
			event => "moo",
		);
	};
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is($err, "resolve() must include a 'context'");
}

{
	eval {
		$resolver->resolve(
			event   => "moo",
			context => "bar",
		);
	};
	my $err = $@;
	$err =~ s/ at \S+ line \d+.*//s;
	is($err, "resolve() must include a 'host'");
}

exit;
