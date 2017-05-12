#!/usr/bin/perl
# $Id: basic.t,v 1.6 2003/11/29 14:34:17 nothingmuch Exp $

### these sets of tests are not a model for a efficiency (code or programmer), but rather for clarity.
### when editing, please keep in mind that it must be absolutely clear what's going on, to ease debugging when we've forgotten what's going on.
### make sure to use lexical scoping to isolate tests from each other - you should not carry garbage around
### make sure you are coherent regarding the order of things
### make sure you comment, clearly and loudly, wherever something may look like it's doing something that it's not
### thanks,
### yuval, nothingmuch@woobling.org

use strict;
use warnings;

use Object::Meta::Plugin;
use Object::Meta::Plugin::Host;

use lib "t/lib";
use OMPTest;

$| = 1; # nicer to pipes
$\ = "\n"; # less to type?

my @test = ( # a series of test subs, which return true for success, 0 otherwise
	sub { # 1 test that we can create new instances
		Object::Meta::Plugin::Host->new() && Object::Meta::Plugin::Useful->new() && 1; # throwaway # useful makes no replacements, alles gŸtt
	},
	sub { # 2 tests that things can plug
		my $host = Object::Meta::Plugin::Host->new() or return undef;
		
		my @plugins = sort (qw/OMPTest::Plugin::Selfish OMPTest::Plugin::Nice::One OMPTest::Plugin::Nice::Two OMPTest::Plugin::Upset::One OMPTest::Plugin::Upset::Two/);
		
		$host->plug($_->new()) or return undef for @plugins;
		
		# make sure everything is listed
		
		my $i = 0; ref $_ ne $plugins[$i++] and return undef for (sort keys %{ $host->plugins });
		
		return 1; # if we made it to here everything plugged in ok
	},
	sub { # 3 basic plugin functionality, order matters
		# initialize a new set of things
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();

		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::One
			OMPTest::Plugin::Nice::Two
		/);
		
		my @steps = (
			qr/Nice::Two::foo$/,
			qr/Nice::Two::bar$/,
			qr/Nice::One::gorch$/,
		);
		
		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
	},
	sub { # 4 registering of methods is order sensitive, make sure theres a difference between this test and the previous one
		# initialize a new set of things
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();
		
		#### FIRST TWO THEN ONE
		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::Two
			OMPTest::Plugin::Nice::One
		/);
		
		my @steps = (
			qr/Nice::One::foo$/,
			qr/Nice::One::gorch$/,
		);
		
		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
	},
	sub { # 5 super method, as well as the more complex lack of thereof
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();
		
		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::One
			OMPTest::Plugin::Selfish
			OMPTest::Plugin::Nice::Two
		/);
		
		my @steps = (
			qr/Nice::Two::foo$/,
			qr/Nice::Two::bar$/,
			qr/Selfish::gorch$/,
			qr/Selfish::bar$/,
			qr/Nice::One::ding$/,
		);
		
		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
	},
	sub { # 6 offsets
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();
		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::One
			OMPTest::Plugin::Upset::Two
			OMPTest::Plugin::Upset::One
			OMPTest::Plugin::Nice::Two
		/);
		
		my @steps = (
			qr/Nice::Two::foo$/,
			qr/Nice::Two::bar$/,
			qr/Upset::One::gorch$/,
			qr/Upset::Two::bar$/,
			qr/Upset::One::bar$/,
			qr/Nice::One::gorch$/,
		);
		
		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
	},
	sub { # 7 unplugging
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();
		
		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Upset::One
			OMPTest::Plugin::Nice::One
			OMPTest::Plugin::Selfish
			OMPTest::Plugin::Nice::Two
			OMPTest::Plugin::Selfish
			OMPTest::Plugin::Upset::Two
		/);
		
		$host->unplug(grep { not /OMPTest::Plugin::Nice/ } keys %{ $host->plugins } ); # unplug anything which isn't nice
		
		return undef if grep { not /OMPTest::Plugin::Nice/ } keys %{ $host->plugins };
		
		my @steps = (
			qr/Nice::Two::foo$/,
			qr/Nice::Two::bar$/,
			qr/Nice::One::gorch$/,
		);
		
		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
	},
	sub { # 8 multiplicity
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();
		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::Two
			OMPTest::Plugin::Nice::One
		/);
		$host->plug($_) for ((OMPTest::Plugin::Upset::One->new) x 2);
		
		my @steps = (
			qr/Upset::One::bar$/,
			qr/Upset::One::gorch$/,
			qr/Nice::Two::bar$/,
			qr/Upset::One::gorch$/,
			qr/Upset::One::bar$/,
			qr/Nice::One::gorch$/,
		);
		
		### test that multiple instances of the same plugin work
		
		### THE FOLLOWING CALL IS ON bar, NOT foo!!!
		($_ =~ (shift @steps)) or return undef foreach (@{$host->bar($o)}); return not @steps;
	},
	sub { # 9 multpiplicity + unplug
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();
		my $p =	OMPTest::Plugin::Upset::One->new();
		$host->plug($_) for (($p) x 2, (map { $_->new() } qw/
			OMPTest::Plugin::Nice::One
			OMPTest::Plugin::Nice::Two
		/), $p);
		$host->unplug($p); # unplug it out once, it should disappear once.

		my @steps = (
			qr/Nice::Two::foo$/,
			qr/Nice::Two::bar$/,
			qr/Nice::One::gorch$/,
		);

		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
	},
	sub { # 10 hosts as plugins
		my $o = OMPTest::Object::Thingy->new();
		
		my $host = Object::Meta::Plugin::Host->new();
		
		use Object::Meta::Plugin::Useful::Meta;
		
		my $one = Object::Meta::Plugin::Useful::Meta->new();
		my $two = Object::Meta::Plugin::Useful::Meta->new();
		
		
		$one->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::One
		/);
		
		$two->plug($_->new()) for (qw/
			OMPTest::Plugin::Funny
			OMPTest::Plugin::Upset::Two
			OMPTest::Plugin::Upset::One
			OMPTest::Plugin::Nice::Two
		/);
		
		$host->plug($_) for ($one, $two);
		
		my @steps = (
			qr/Nice::Two::foo$/,
			qr/Nice::Two::bar$/,
			qr/Upset::One::gorch$/,
			qr/Upset::Two::bar$/,
			qr/Upset::One::bar$/,
			qr/Funny::gorch$/,
			qr/Nice::One::ding$/,
		);
		
		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
		
	},
	sub { # 11 hosts as plugins
	
		#return "Not implemented yet.";
		my $o = OMPTest::Object::Thingy->new();
		
		my $host = Object::Meta::Plugin::Host->new();
		
		my $one = Object::Meta::Plugin::Host->new();
		my $two = Object::Meta::Plugin::Host->new();
		
		
		$one->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::One
			OMPTest::Plugin::MetaPlugin
		/);
		
		$two->plug($_->new()) for (qw/
			OMPTest::Plugin::Funny
			OMPTest::Plugin::Upset::Two
			OMPTest::Plugin::Upset::One
			OMPTest::Plugin::Nice::Two
			OMPTest::Plugin::MetaPlugin
		/);
		
		$host->plug($_) for ($one, $two);
		
		my @steps = (
			qr/Nice::Two::foo$/,
			qr/Nice::Two::bar$/,
			qr/Upset::One::gorch$/,
			qr/Upset::Two::bar$/,
			qr/Upset::One::bar$/,
			qr/Funny::gorch$/,
			qr/Nice::One::ding$/,
		);
		
		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
		
	},
	sub { # 12 unregistering - make sure that ExportLists unmerge correctly
		my $host = Object::Meta::Plugin::Host->new();
		my $plugin = OMPTest::Plugin::Nice::One->new();
		$host->plug($plugin);
		$host->unregister(Object::Meta::Plugin::ExportList->new($plugin, qw/gorch ding/));
		
		
		my @foo;
		@foo = qw/foo/; return undef if grep { @foo or return undef; not $_ eq shift @foo } $host->plugins->{$plugin}->list(); return undef if @foo;
		@foo = qw/foo/; return undef if grep { @foo or return undef; not $_ eq shift @foo } keys %{ $host->methods }; return undef if @foo;
		
		return 1;
	},
	sub { # 13 registering - make sure that ExportLists merge correctly
		my $host = Object::Meta::Plugin::Host->new();
		my $plugin = OMPTest::Plugin::Nice::One->new();
		$host->plug($plugin);
		$host->unregister(Object::Meta::Plugin::ExportList->new($plugin, qw/gorch ding/));
		$host->register(Object::Meta::Plugin::ExportList->new($plugin, qw/foo gorch ding/));
		
		
		my @foo;
		@foo = sort qw/ding foo gorch/; return undef if grep { @foo or return undef; not $_ eq shift @foo } sort $host->plugins->{$plugin}->list(); return undef if @foo;
		@foo = sort qw/ding foo gorch/; return undef if grep { @foo or return undef; not $_ eq shift @foo } sort keys %{ $host->methods }; return undef if @foo;
		
		return 1;
	},
	sub { # 14 summary - actually retests stuff that was already done, but just in case
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();
		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::One
			OMPTest::Plugin::Selfish
			OMPTest::Plugin::Upset::Two
			OMPTest::Plugin::Upset::One
			OMPTest::Plugin::Nice::Two
		/);
		
		my @steps = (
			qr/Nice::Two::foo$/,
			qr/Nice::Two::bar$/,
			qr/Upset::One::gorch$/,
			qr/Upset::Two::bar$/,
			qr/Upset::One::bar$/,
			qr/Selfish::gorch$/,
			qr/Selfish::bar$/,
			qr/Nice::One::ding$/,
		);
		
		($_ =~ (shift @steps)) or return undef foreach (@{$host->foo($o)}); return not @steps;
	},
);

print "1..", scalar @test; # the number of tests we have

my $i = 0; # a counter

my $t = times();
foreach (@test) { my $e; print (($e = &$_) ? "ok " . ++$i . ( ($e ne "1") ? " # Skipped: $e" : "") : "not ok " . ++$i) } # test away
print "# tests took ", times() - $t, " cpu time"; 

exit;

1; # keep your mother happy

__END__

=pod

=head1 NAME

t/basic.t - Test suite to make sure Object::Meta::Plugin can perform the bare minimum we expect it to.

=head1 DESCRIPTION

This test suite uses various test plugins under a host several times. The plugins behave in certain ways, meant to exploit the various context modes and so forth of the host.

=head1 TESTS

=over 4

=item 1

This test ensures that the objects Object::Meta::Plugin::Host and Object::Meta::Plugin::Useful (a useful plugin base class) can be instantiated.

=item 2

This test tries to plug all the plugins it knows without doing anything special with them afterwords, except for looking if they're there..

=item 3

This test ensures that the super method of the context object works as expected, by using plugins which use these methods.

=item 4

This test ensures that the super method of the context object, as well as the lack of thereof do not change the behavior of the calls when they shouldn't be doing so.

=item 5

This test ensures that the context object will shortcut method calls when appropriate, to the plugin it's context it represents.

=item 6

This test ensures that the next method of the context object works, and that the offset context generator also works as expected.

=item 7

This test ensures that unplugging works properly (functionality and cleanup).

=item 8

This test plugs two copies of the same plugin in, and makes sure that the two copies are differentiated.

=item 9

This test ensures that two copies of the same plugin will both be expunged when the plugin is unplugged.

=item 10

This test creates plugins from hosts, and makes sure that the various context are still applicable. Moreover, it provides a means for checking that Host.pm's implementation is correct in both cases - normally, and as a plugin.

=item 11

This test also creates plugins from hosts, but it's done not with a subclass of Object::Meta::Plugin::Host, but rather with a plugin that provides the necessary functionality from within, and not from without.

=item 12

This test plugs a plugin, and unregisters specific methods. Then it makes sure that the correct values changed.

=item 13

This test plugs a plugin, then unregisters some methods. It then plugs methods back, and makes sure the values are correct.

=item 14

This test is some of the aspects of the previous tests combined. It makes use of all of the plugins, at one point or another. It tests offsets, super, but not host-as-plugin.

=back

=head1 TODO

=over 4

=item *

Obsess on additional variations based on the current tests.

=back

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<t/error_handling.t>, L<t/extremes.t>, L<t/greedy.t>.

=cut
