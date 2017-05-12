#!/usr/bin/perl

package Sub::Clone;

use strict;
use warnings;

BEGIN {
	our $VERSION = '0.03';

	my $e = do {
		local $@;

		eval {
			require XSLoader;
			__PACKAGE__->XSLoader::load($VERSION);
		};
		   
		$@;
	};

	if ( $e && $e !~ /object version|loadable object/ ) {
		warn $e;
		require DynaLoader;
		push our @ISA, 'DynaLoader';
		__PACKAGE__->bootstrap($VERSION);
	}
}

use Sub::Exporter -setup => {
	exports => [qw(is_cloned clone_sub clone_if_immortal)],
	groups  => { default => [qw(is_cloned clone_sub)] },
};

# Pure Perl implementation:
unless ( defined &is_cloned ) {
	eval '
use B qw(svref_2object CVf_CLONED);
use Scalar::Util qw(blessed);

sub is_cloned ($) {
	my $sub = shift;
	svref_2object($sub)->CvFLAGS & CVf_CLONED;
}

sub clone_sub ($) {
	my $sub = shift;
	my $clone = sub { goto $sub };

	if ( defined( my $class = blessed($sub) ) ) {
		bless $clone, $class;
	}

	return $clone;
}

sub clone_if_immortal ($) {
	my $sub = shift;
	is_cloned($sub) ? $sub : clone_sub($sub)
}
';
}

__PACKAGE__

__END__

=pod

=head1 NAME

Sub::Clone - Clone subroutine refs for garbage collection/blessing purposes

=head1 SYNOPSIS

	use Sub::Clone;

=head1 DESCRIPTION

A surprising fact about Perl is that anonymous subroutines that do not close
over variables are actually shared, and do not garbage collect until global
destruction:

	sub get_callback {
		return sub { "hi!" };
	}

	my $first = get_callback();
	my $second = get_callback();

	warn "$first == $second"; # prints the same refaddr

This means that blessing such a sub would change all other copies (since they
are, in fact, not copies at all), and that C<DESTROY> will never be called.

=head1 EXPORTS

L<Sub::Clone> uses L<Sub::Exporter> so its C<import> has all the implied
goodness (renaming, etc).

=over 4

=item is_cloned $sub

Returns true if C<CVf_CLONED> is true (meaning that this subroutine is a clone
of a proto sub and being refcounted).

=item clone_sub $sub

Returns a clone of the sub, that is guaranteed to be refcounted, and can be
safely blessed.

=item clone_if_immortal $sub

Clones the sub if it's not C<is_cloned>.

=back

=head1 PURE PERL VS XS

This module is implemented in both XS and pure Perl, and the reference counting
behavior of the two is slightly different.

The XS implementation of C<clone_sub> uses C<cv_clone> internally, the function
that captures closure state into a clone of the code ref struct (sharing the
optree etc), which means that it's a real clone (the prototype's reference
count does not go up), whereas the pure Perl version must wrap the proto.

This means that in the pure Perl version C<DESTROY> might not be called as
early for the cloned sub as the XS version.

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
