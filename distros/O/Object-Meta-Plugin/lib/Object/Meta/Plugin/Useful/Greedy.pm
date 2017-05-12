#!/usr/bin/perl
# $Id: Greedy.pm,v 1.2 2003/11/29 14:48:37 nothingmuch Exp $

package Object::Meta::Plugin::Useful::Greedy;

use strict;
use warnings;

use base 'Object::Meta::Plugin::Useful';

use Devel::Symdump;

sub exports {
	my $self = shift;
	
	return _filter(_collect_functions(ref $self));
	
	sub _collect_functions {
		my $pkg = shift;
		my @f = map { s/.*:://; $_ } Devel::Symdump->new($pkg)->functions();;
		
		my $isaisa;
		no strict 'refs';
		foreach $isaisa (@{"$pkg\::ISA"}) {
			push @f, _collect_functions($isaisa);
		}
		@f;
	}
}

sub _filter {
	my %seen;
	return grep { not $seen{$_}++ } grep { !/^(?:
		croak	|
		carp	|
		exports	|
		next	|
		init	|
		new		
	)$/x } grep { /^(?!_)\w/ } @_;
}


1; # Keep your mother happy.

__END__

=pod

=head1 NAME

Object::Meta::Plugin::Useful::Greedy - a plugin base class which gobbles up reasonable parts of the symbol table at export time.

=head1 SYNOPSIS

	package Foo;

	use base 'Object::Meta::Plugin::Useful::Greedy';

	sub ppretty {
		# ...
	}

	sub ver_pretty {
		# ...
	}

	sub ugly { # will not be exported because of the pattern
		# ...
	}

	sub _filter {
		grep {/pretty/} @_;
	}

=head1 DESCRIPTION

This is a base class for a pretty standard, pretty easy plugin. When C<export > is called it goes through the symbol table of the plugin's package, as per C<ref $self>, and so forth through all the @ISAs it finds. The functions it finds along the way are collected, and filtered.

=head1 METHODS

=over 4

=item _filter LIST

This takes a list of method names, and munges it into something. The current example will filter things that don't look pretty, that are a bit too general (new, init, croak), and then fishes out duplicates.

You really should define it in your class, if you want more control of the patterns.

=back

=head1 CAVEATS

=over 4

=item *

Does not work on classless objects and such. The plugin in question must be a real set of classes.

=item *

Relies on the non core module Devel::Symdump.

=back

=head1 BUGS

Peh! You must be kididgn!

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<Object::Meta::Plugin>, L<Object::Meta::Plugin::Useful>, L<Object::meta::Plugin::Useful::Generic>, L<Object::Meta::Plugin::Useful::Meta>.

=cut
