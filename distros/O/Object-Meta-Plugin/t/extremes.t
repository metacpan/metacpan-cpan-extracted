#!/usr/bin/perl
# $Id: extremes.t,v 1.3 2003/11/29 14:48:37 nothingmuch Exp $

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
	### try to plug a Clas::Classless object into the mess. Repeat for each classless implementation to make sure we work, or it works. Skip if we can't load them (i.e. require Class::Classless or return "Can't load Class::Classless")
	
	sub {
		eval { require Class::Classless } or return "can't find Class::Classless $@";
		
		my $o = OMPTest::Object::Thingy->new();
		my $host = Object::Meta::Plugin::Host->new();
		my $p = defined $Class::Classless::ROOT ? $Class::Classless::ROOT->clone() : return "can't load Class::Classless";
		
		$p->{METHODS}{init} = sub {
			Object::Meta::Plugin::ExportList->new($_[0]);
		};
		$p->{METHODS}{exports} = sub {
			qw/foo bar/;
		};
		$p->{METHODS}{foo} = sub {
			my $self = shift;
			my $obj = shift;
			$obj->add();
			$self->bar($obj)
		};
		$p->{METHODS}{bar} = sub {
			my $self = shift;
			my $obj = shift;
			$obj->add();
		};
		
		$host->plug($p);
		
		return "Must get \$self->self issue resolved.";
		
		# $host->foo($o);
	},
	sub {
		my $pkg = 'Class::Object';
		eval { require $pkg } or return "can't find $pkg";
		
		return "Not yet implemented";
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

t/extremes.t - Weird ideas that should theoretically be possible. Breaking these will mean that we're doing something we probably don't want to be doing.

=head1 DESCRIPTION

The aim of this test file is to build a set of tests that should work in theory, and do work in practice, now that the implementation is simple an unoptimized.

As the Object::Meta::Plugin implementation matures, and becomes more magical, I expect things to break without noticing.

If the standards regarding what works and what doesn't are set now, compatibility can be enforced, and perhaps ensured in the future.

=head1 TESTS

=over 4

=item 1

Class::Classless - not yet implemented.

=item 2

Class::Object - not yet implemented.

=back

=head1 TODO

=over 4

=item *

Find obscure implementations of objects that should work, and try them. Classless and such.

=back

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<t/basic.t>, L<t/error_handling.t>, L<t/greedy.t>, L<Class::Classless>, L<Class::Prototyped>, L<Class::Object>.

=cut
