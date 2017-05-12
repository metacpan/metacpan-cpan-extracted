#!/usr/bin/perl
# $Id: greedy.t,v 1.2 2003/11/29 14:48:37 nothingmuch Exp $

use strict;
use warnings;

BEGIN { eval { require Devel::Symdump } or do { print "1..0 # Skipped: no Devel::Symdump to be found"; exit } }	

$| = 1; # nicer to pipes
$\ = "\n"; # less to type?

my @test = (
	sub {
		my $p = Foo->new();
		my @foo = sort qw/bar foo laa_didaa/; return undef if grep { @foo or return undef; not $_ eq shift @foo } sort $p->exports; return undef if @foo;
		return 1;
	},
);

print "1..", scalar @test; # the number of tests we have

my $i = 0; # a counter

my $t = times();
foreach (@test) { my $e; print (($e = &$_) ? "ok " . ++$i . ( ($e ne "1") ? " # Skipped: $e" : "") : "not ok " . ++$i) } # test away
print "# tests took ", times() - $t, " cpu time"; 

exit;

package Foo;

use strict;
use warnings;

use base 'Object::Meta::Plugin::Useful::Greedy';

# define some subs
sub laa_didaa {}
sub foo {}
sub bar {}
# the rest should not be included
sub _ding {}
sub carp {}

1; # Keep your mother happy.

__END__

=pod

=head1 NAME

t/greedy.t - Test that Object::Meta::Plugin::Useful::Greedy is sane.

=head1 SYNOPSIS

	#

=head1 DESCRIPTION

This test suite is apart from the rest because it tests with a module which probably won't be present - L<Devel::Symdump>.

=head1 TESTS

=over 4

=item 1

This test ensures that the export list for a greedy plugin is correct, based on a small class.

=back

=head1 TODO

Nothing right now.

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<t/basic.t>, L<t/error_handling.t>, L<t/extremes.t>.

=cut
