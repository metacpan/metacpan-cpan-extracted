#!/usr/bin/perl
# $Id: error_handling.t,v 1.5 2003/11/29 14:48:37 nothingmuch Exp $

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
use OMPTest; # auxillery testing libs

$| = 1; # nicer to pipes
$\ = "\n"; # less to type?

my @test = ( # a series of test subs, which return true for success, 0 otherwise
	sub { # 1 prev & next at the end of the stack should break
		my $host = Object::Meta::Plugin::Host->new();
		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Upset::Two
			OMPTest::Plugin::Upset::One
		/);
		
		eval { $host->foo(OMPTest::Object::Thingy->new()) };
		return undef unless $@ =~ /^The offset is out of the range of the method stack for foo/;
		
		eval { $host->gorch(OMPTest::Object::Thingy->new()) };
		return undef unless $@ =~ /^The offset is out of the range of the method stack for gorch/;
		
		return 1;
	},
	sub { # 2 bad call
		my $host = Object::Meta::Plugin::Host->new();
		$host->plug($_->new()) for (qw/
			OMPTest::Plugin::Nice::One
		/);
		
		eval { $host->bar(OMPTest::Object::Thingy->new()) };
		return $@ =~ /^Can't locate object method "bar" via any plugin in/
	},
	sub { # 3 bad call
		my $host = Object::Meta::Plugin::Host->new();
		eval { $host->next(OMPTest::Object::Thingy->new()) };
		return $@ =~ /^Method next is reserved for use by the context object/;
	},
	sub { # 4 garbage
		my $host = Object::Meta::Plugin::Host->new();
		eval { $host->plug(OMPTest::Plugin::Naughty::Nextport->new()) };
		return $@ =~ /^Method next is reserved for use by the context object/;
	},
	sub { # 5 garbage
		
		my $host = Object::Meta::Plugin::Host->new();
		eval { $host->plug(OMPTest::Plugin::Naughty::Empty->new()) };
		return $@ =~ /^Doesn't look like a plugin/;
	},
	sub { # 6 garbage
		my $host = Object::Meta::Plugin::Host->new();
		eval { $host->plug(OMPTest::Plugin::Naughty::Undefs->new()) };
		return $@ =~ /^init\(\) did not return an export list/;
	},
	sub { # 7 garbage
		my $host = Object::Meta::Plugin::Host->new();
		eval { $host->plug(OMPTest::Plugin::Naughty::Crap->new()) };
		return $@ =~ /^That doesn't look like a valid export list/;
	},
	sub { # 8 garbage
		my $host = Object::Meta::Plugin::Host->new();
		eval { $host->plug(OMPtest::Plugin::Naughty::Exports->new()) };
		return $@ =~ /^Can't locate object method "method_i_dont_have" via package  "OMPtest::Plugin::Naughty::Exports"/;
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

t/error_handling.t - Test suite to make sure Object::Meta::Plugin expects the unexpected.

=head1 DESCRIPTION

This test suite attempts to do a variety of ghastly things to the poor host. It tries to plug ugly things into it, it tries to call inexistent methods, it tries to find loop holes, and so forth.

The main purpose of this test suite is that every time a flaw is found it will always be tested for. This way flaws will probably not resurface unexpectedly.

=head1 TESTS

=over 4

=item 1

This test tries to call prev and next when there are no previous or next plugins in the method stack, and expects a proper error.

=item 2

This test tries to call an method which isn't there, and expects a proper error.

=item 3

This test tries to trick C<AUTOLOAD> to call a Object::Meta::Plugin::Host::Context builtin as if it were a method.

=item 4

This test tries to plug in a plugin which defines the method C<next>.

=item 5

This test tries to plug an empty class into the host, and expects a proper error.

=item 6

This test tries to plug a class which doesn't function properly (init() returns undef), and expects a proper error.

=item 7

This test tries to plug a class which looks like it functions properly (init() returns an object), but the values are actually bad (the object init() returns does not have the mandatory methods an export list needs).

=item 8

This test tries to plug a plugin which exports a method it doesn'd define.

=back

=head1 TODO

=over 4

=item *

Audit code for possible loopholes. Test them.

=back

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<t/basic.t>, L<t/extremes.t>, L<t/greedy.t>.

=cut
