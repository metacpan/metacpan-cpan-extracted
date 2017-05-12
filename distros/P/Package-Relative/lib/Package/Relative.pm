#!/usr/bin/perl

package Package::Relative;

use strict;
use warnings;

our $VERSION = "0.01";

use overload (
	'""' => 'stringify',
	'.' => 'concat',
	fallback => 1,
);

our @EXPORT = qw/PKG/;
use base qw/Exporter/;

sub PKG {
	my $caller = caller;
	return bless \$caller, __PACKAGE__;
}

sub stringify {
	${ $_[0] };
}

sub concat {
	my $self = shift;
	my $other = shift;
	my $reversed = shift;

	($self, $other) = ($other, $self) if $reversed;

	my @pkg = grep { length } split '::', "$self";
	
	/^\.\.$/ ? pop @pkg : push @pkg, $_ for (grep { length } split '::', "$other");

	my $pkg = join("::", @pkg);

	$reversed ? bless \$pkg, __PACKAGE__ : $pkg;
}

sub AUTOLOAD {
	my $self = shift;
	my $pkg = $self->stringify;

	# FIXME: perhaps this should croak? After all, without concatenating you might as well use __PACKAGE__

	my ($method) = (our $AUTOLOAD =~ /:([^:]+)$/);

	$pkg->$method(@_);
}

sub DESTROY {}

__PACKAGE__

__END__

=pod

=head1 NAME

Package::Relative - Support for '..' style relative paths in perl namespaces.

=head1 SYNOPSIS

	package My::Pkg;

	use Package::Relative;

	(PKG . "..::Foo")->method; # My::Foo
	(PKG . "Bar")->method; # My::Pkg::Bar

=head1 DESCRIPTION

This module exports the L</PKG> function, which returns an overloaded object.

This object overloads the stringification and concatenation operations,
treating ".." in paths as a relative notation. See the L</SYNOPSIS>.

=head1 EXPORTS

=over 4

=item PKG

C<__PACKAGE__> work alike that returns an overloaded object instead of a string.

=back

=head1 METHODS

=over 4

=item stringify

Returns the string for the package.

=item concat

Implements the C<.> operator.

=item AUTOLOAD

This is to support

	PKG->method;

Although that is greatly discouraged. If you are doing that, why not use

	__PACKAGE__->method;

In the future a warning might be emitted.

=back

=head1 CAVEAT - THE CONCAT OPERATOR'S RETURN VALUE

When the object is the right hand side of a concatenation, e.g.

	"Foo" . PKG;

Then an object is returned. This means that

	my $pkg = PKG;
	"Foo::${pkg}::..::Bar";

will DWIM.

On the other hand, when the object is the left hand side of a concatenation, a
plain string is returned.

This means that

	package My::Pkg;
	PKG . "..::Foo" . "..::Bar";

is really equal to C<My::Foo..::Bar> instead of what you'd expect.

The reason this is done is to simplify the generic case:

	(PKG . "..::Foo")->method;

If an object were returned, method would have been dispatched to it, and
C<AUTOLOAD> yuckiness could not be avoided.

The workaround, which is not too bad is to always parenthesize:

	PKG . ("..::Foo::" . "..::Bar"); # notice the extra colons after Foo

=cut
