#!/usr/bin/perl

package Sub::SmartMatch;

use strict;
use warnings;

use 5.010;

use Carp qw(croak);
use Scalar::Util qw(reftype);

our $VERSION = "0.02";

use base qw(Exporter);

our @EXPORT = our @EXPORT_OK = qw(multi multi_default def_multi exactly);



BEGIN {
	# If we have Sub::Name, great. If not, nevermoose

	local $@;

	eval {
		require Sub::Name;
		no warnings 'redefine';
		*subname = \&Sub::Name::subname;
	};

	*subname = sub { $_[1] } unless defined &subname;
}

sub exactly ($) {
	my $value = shift;

	if ( ref($value) and ref($value) eq 'ARRAY' ) {
		bless \$value, __PACKAGE__ . "::Exact";
	} else {
		return $value;
	}
}

# guess the fully qualified name for a sub using caller()
sub full_name ($) {
	my $name = shift;

	croak "A subroutine name is required"
		unless defined($name) and length($name);

	return $name if $name =~ /::/;

	foreach my $level ( 0 .. 2 ) {
		my $pkg = caller($level);
		next if $pkg eq __PACKAGE__;
		return join "::", $pkg, $name;
	}
}


our ( %variants, %default );

sub multi ($$$) {
	my ( $name, $case, $body ) = @_;

	$name = full_name($name);


	unless ( ref($body) and reftype($body) eq 'CODE' ) {
		my $body_str = defined($body)
			? ( ref($body) ? $body : "'$body'" )
			: "undef";

		croak "$body_str is not a code reference";
	}

	def_multi($name);

	my $exact = ref($case) && ref($case) eq __PACKAGE__ . "::Exact";
	$case = $$case if $exact;

	my $partial_match = not($exact) && ref($case) && ref($case) eq 'ARRAY' && @$case;

	push @{ $variants{$name} }, [ $partial_match, $case, $body ];

	return $body;
}

sub multi_default ($$) {
	my ( $name, $body ) = @_;

	croak "$body is not a code reference"
		unless ref($body) and reftype($body) eq 'CODE';

	$name = full_name($name);

	def_multi($name);

	$default{$name} = $body;
}

sub def_multi ($;@) {
	my ( $name, @args ) = @_;
	$name = full_name($name);

	unless ( exists $variants{$name} ) {
		my @variants;

		my $sub = sub {
			given ( \@_ ) {
				foreach my $variant ( @variants ) {
					my ( $partial, $case, $body ) = @$variant;

					if ( $partial ) {
						given ( [ @_[0 .. $#$case] ] ) {
							when ( $case ) { goto $body }
						}
					} else {
						when ( $case ) { goto $body }
					}
				}

				default {
					if ( my $default = $default{$name} ) {
						goto $default;
					} else {
						croak "No variant found for arguments";
					}
				}
			}
		};

		{
			no strict 'refs';
			*$name = subname $name, $sub;
		}

		$variants{$name} = \@variants;
	}

	def_variants($name, @args) if @args;
}

sub def_variants ($;) {
	my ( $name, @variants ) = @_;

	$name = full_name($name);

	def_multi($name);

	croak "The variant list is not even sized"
		unless @variants % 2 == 0;

	while ( @variants ) {
	   	my ( $case, $body ) = splice(@variants, 0, 2);

		if ( not ref($case) and $case ~~ 'default' ) {
			multi_default $name, $body;
		} else{
			multi $name, $case, $body;
		}
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

Sub::SmartMatch - Use smart matching to define multi subs

=head1 SYNOPSIS

	use Sub::SmartMatch;

	use SmartMatch::Sugar qw(any);

	# variants will be tried in a given/when
	# clause in the order they are defined

	multi fact => [ 0 ], sub { 1 };

	multi fact => any, sub {
		my $n = shift;
		return $n * fact($n - 1);
	}

=head1 DESCRIPTION

This module provides Haskell/ML style subroutine variants based on Perl's
smartmatch operator.

This doesn't do argument binding, just value matching.

To define methods use C<SmartMatch::Sugar>'s C<object> test:

	multi new [ class ]  => sub {
		 # invoked as a class method
	}

	multi new [ object ] => sub {
		# invoked as an object method
		# this should clone, i guess
	}

=head1 EXPORTS

=over 4

=item exactly $case

This marks this case for exact matching. This means that it will match on
C<\@_>, not on the slice C<<[ @_[0 .. $#$case] ]>>.

This only applies to cases which are array references themselves.

=item multi $name, $case, &body

Define a variant for the sub name C<$name>.

C<$case> will be smartmatched against an array reference of the arguments to
the subroutine.

As a special case to allow variable arguments at the end of the list, if
C<$case> is an array reference it will only be matched against the slice of
C<@_> with the corresponding number of elements, not all of C<@_>. Use
C<exactly> to do a match on all of C<@_>. This does not apply to an empty array
(otherwise that would always match, instead of matching empty arrays).

=item multi_default $name, &body

Define the C<default> for a multi sub. This variant is always tried last if no
other variant matched.

=item def_multi $name, [ $case => &body, $case => &body, default => ... ]

Define a multi sub in one go.

	def_multi foo => (
		$case   => $body,
		...     => ...,
		default => $default,
	);

=back

=head1 SEE ALSO

L<SmartMatch::Sugar>, L<Sub::PatternMatch>, L<perlsyn>, L<Class::Multimethods::Pure>

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
