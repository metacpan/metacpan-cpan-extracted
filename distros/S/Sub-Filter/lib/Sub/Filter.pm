=head1 NAME

Sub::Filter - automatically filter function's return value

=head1 SYNOPSIS

	use Sub::Filter qw(mutate_sub_filter_return);

	mutate_sub_filter_return(\&get_height, \&num_checker);

	use Sub::Filter qw(filter_return);

	sub get_height :filter_return(num_checker) { ...

=head1 DESCRIPTION

This module allows a function to be augmented with a filter that will be
applied to its return values.  Whenever the function returns, by whatever
means, the value (or list of values) being returned is passed through the
filter before going to the caller.  The filter may be any function, and
may perform type checking/coercion, logging, or any other manipulation.
The filtering is invisible to the body of the augmented function: the
stack shows its normal caller, not a wrapping stack frame.

=head2 Return filtering

When using a return filter, the resulting augmented function is
effectively composed from two simpler functions, the main function and
the filter function.  When the augmented function is called, first the
main function executes, then when that returns the filter function has
a chance to munge the return value.  The main function doesn't actually
have an independent callable identity.  The filter function, however,
is completely distinct, callable in its own right, and can act as a
filter for several augmented functions simultaneously.

When the main function executes, it appears to be being called
independently in the normal manner.  The L<caller|perlfunc/caller>
function shows that the immediate caller is whatever code actually
called the augmented function, and lower-level tricks that get a more
detailed view of the stack show the same situation.  The main function
body is aware of the calling context as usual, which it can check using
L<wantarray|perlfunc/wantarray>.

When the main body returns, the filter function is implicitly called.
L<caller|perlfunc/caller> will show that it is called from (the return
statement of) the augmented function.  The filter function executes
with the same calling context that the main function had, and whatever
the filter function returns will be used as the return value of the
augmented function.  The values returned by the main function body are
available to the filter function as its arguments.  The nature of these
arguments will depend on the calling context: in scalar context it will
be exactly one value, and in void context it will be no values at all.
The filter function must be prepared for these situations.

If the main function, written in Perl, does a C<goto &>, this replaces
the entire stack frame of the augmented function, and the filter function
will not be called.  Likewise, L<Scope::Upper/unwind> can bypass the
filter, returning directly to the caller of the augmented function.
These are ugly tricks that mess with the stack.  Throwing an exception,
by L<die|perlfunc/die>, also causes the filter not to run, but in this
case there is no return value to filter.

The main function to which a filter is to be applied may be either pure
Perl or XS (native code, usually written in C).  The filter function
may also be either pure Perl or XS, and either type of filter function
can be attached to either type of main function.  It is also possible
to apply multiple filters to one main function, effectively using an
augmented function (main plus filter) as the main function to attach
another filter to.

=cut

package Sub::Filter;

{ use 5.008001; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.004";

my %SUB_EXPORT_OK = map { $_ => undef } qw(mutate_sub_filter_return);

sub import {
	my $package = shift(@_);
	foreach(@_) {
		if(exists $SUB_EXPORT_OK{$_}) {
			no strict "refs";
			*{caller()."::".$_} = \&$_;
		} elsif($_ eq "filter_return") {
			require Attribute::Lexical;
			Attribute::Lexical->VERSION(0.004);
			require Sub::Mutate;
			Sub::Mutate->VERSION(0.005);
			Attribute::Lexical->import("CODE:filter_return" =>
				\&_handle_attr_filter_return);
		} else {
			croak "\"$_\" is not exported by the $package module";
		}
	}
}

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 FUNCTION

=over

=item mutate_sub_filter_return(SUB, FILTER)

I<SUB> and I<FILTER> must both be references to subroutines.  I<SUB> is
modified in place, such that whatever I<SUB> returns will be filtered
through I<FILTER>.  The subroutine's identity is not changed, but the
behaviour of the existing subroutine is changed.  Beware of action at
a distance.

This is best done at compile time, preferably in a C<BEGIN> block
immediately after the initial definition of I<SUB>.  It is preferable,
where possible, to use the subroutine attribute described below.
This function exists mainly for awkward situations where the attribute
is difficult to use.

=back

=head1 SUBROUTINE ATTRIBUTE

The visibility of this attribute is controlled by lexical (block)
scoping, managed by L<Attribute::Lexical>.  To make it available in the
current block, include C<filter_return> in the import list in the C<use>
statement for this module, as shown in the synopsis.

=over

=item :filter_return(FILTER)

The function to which this attribute is applied will be augmented, such
that whatever it returns will be filtered through the function specified
by I<FILTER>.

I<FILTER> must be the name of a function.  It may be either
fully-qualified (e.g., C<Foo::num_checker>), or an unqualified name
(e.g., C<num_checker>) referring to a function in the current package
(current where the attribute is used).  (It is not possible to use an
anonymous filter function this way; see L</mutate_sub_filter_return>
if you need to do that.)

=cut

sub _handle_attr_filter_return {
	my($target, $attname, $arg, $caller) = @_;
	$arg = "" unless defined $arg;
	my $filterer;
	if($arg =~ /\A[A-Za-z_][0-9A-Za-z_]*\z/) {
		no strict "refs";
		$filterer = \&{$caller->[0]."::".$arg};
	} elsif($arg =~ /\A(?:[0-9A-Za-z_]+::)+[A-Za-z_][0-9A-Za-z_]*\z/) {
		no strict "refs";
		$filterer = \&$arg;
	} else {
		croak "attribute :$attname needs a function name argument";
	}
	Sub::Mutate::when_sub_bodied($target, sub {
		mutate_sub_filter_return($_[0], $filterer);
	});
}

=back

=head1 BUGS

A filter cannot be attached to a Perl function that shares its op tree
with another.  This can happen due to threading, or due to closures (where
all closures from a single source share one op tree).  This limitation
should be removed in a future version.  The problem does not occur if
a filter is attached before the sharing arises.

Filtering on an lvalue subroutine currently breaks the lvalue behaviour.

The way a filter is attached to a pure Perl main function confuses
L<B::Deparse>.  The resulting augmented function consists of a network of
op nodes, just like a pure Perl function, but the nodes fit together in
a structure that the Perl compiler never generates.  This is ultimately
because the call to the filter function is difficult to express in pure
Perl, due to the context-dependent behaviour.

=head1 SEE ALSO

L<Attribute::Lexical>,
L<Sub::Mutate>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2013 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
