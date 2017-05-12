package MooseX::Role::Nameable;

=head1 NAME

MooseX::Role::Nameable - automatic class short names

=cut

use strict;
use warnings;

use MooseX::Role::Parameterized;

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

This role provides a method to automatically generate a short name for a Moose
class from the package name.  This is especially useful for classes that are
used in conjunction with the factory pattern.  When this role is included, the
name for the access function is required.  In addition, a regex may be defined
to modify how the value is extracted.  By default, the last namespace in the
package is used.  The short name assumes the package is in camel-case and
normalizes it following some simple rules:

	- convert to lower case
	- words are separated by underscores
	- acronyms are treated as a single word

Example usage:

	package Foo::Base;
	use Moose;
	with
		'MooseX::Role::Nameable' => {name => 'type'},
		'MooseX::Role::Nameable' => {name => 'nationality', regex => qr{::([^:]+)Child$}};
	__PACKAGE__->meta->make_immutable;

	package Foo::AmericanChild;
	use Moose;
	extends 'Foo::Base';
	__PACKAGE__->meta->make_immutable;

	package Foo::BritishChild;
	use Moose;
	extends 'Foo::Base';
	__PACKAGE__->meta->make_immutable;

	package main;

	my $child1 = Foo::AmericanChild->new;
	my $child2 = Foo::BritishChild->new;

	local $\="\n";
	print $_->type . ':' . $_->nationality for ($child1, $child2);
	# =>
	# american_child:american
	# british_child:british

=cut

my %CACHED_NAMES;

parameter name => (isa  => 'Str', required => 1);
parameter regex => ();

role {
	my $p = shift;

	my $name = $p->name;
	my $regex = $p->regex || '([^:]*)$';
	$regex = qr{$regex};

	method $name => sub {
		my $class = shift;
		$class = ref $class || $class;

		my $n = $CACHED_NAMES{"$class\::$name"};
		unless (defined $n) {
			($n) = $class =~ $regex;
			$n =~ s/([[:lower:]])([[:upper:]])/$1\_$2/g;
			$n =~ s/([[:upper:]])([[:upper:]][[:lower:]])/$1\_$2/g;
			$n = $CACHED_NAMES{"$class\::$name"} = lc $n;
		}
		return $n;
	};
};

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-MooseX-Role-Nameable at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-moosex-role-nameable/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Role::Nameable

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-moosex-role-nameable>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-moosex-role-nameable/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-Nameable>

=item * Official CPAN Page

L<http://search.cpan.org/dist/MooseX-Role-Nameable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MooseX::Role::Nameable
