use 5.006;
use strict;
use warnings;

package Sub::ArgShortcut;
$Sub::ArgShortcut::VERSION = '1.021';
# ABSTRACT: simplify writing functions that use default arguments

sub croak { require Carp; goto &Carp::croak }

sub argshortcut(&) {
	my ( $code ) = @_;
	return sub {
		my @byval;
		my $nondestructive = defined wantarray;
		$code->(
			$nondestructive
			? ( @byval = @_ ? @_ : $_ )
			: (          @_ ? @_ : $_ )
		);
		return $nondestructive ? @byval[ 0 .. $#byval ] : ();
	};
}

sub import {
	my $class = shift;
	my $install_pkg = caller;
	die q(Something mysterious happened) if not defined $install_pkg;
	{ no strict 'refs'; *{"${install_pkg}::argshortcut"} = \&argshortcut; }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::ArgShortcut - simplify writing functions that use default arguments

=head1 VERSION

version 1.021

=head1 SYNOPSIS

 use Sub::ArgShortcut::Attr;

 sub mychomp : ArgShortcut { chomp @_ }

 while ( <> ) {
     # make a chomped copy of $_ without modifying it
     my $chomped_line = mychomp;
 
     # or, modify $_ in place
     mychomp;
 
     # ...
 }

=head1 DESCRIPTION

This module encapsulates the logic required for functions that assume C<$_> as
their argument when called with an empty argument list, and which modify their
arguments in void context but return modified copies in any other context. You
only need to write code which modifies the elements of C<@_> in-place.

=head1 INTERFACE

=head2 C<argshortcut(&)>

This function takes a code reference as input, wraps a function around it and
returns a reference to that function. The code that is passed in should modify
the values in C<@_> in whatever fashion desired. The function from the
L<synopsis|/SYNOPSIS> could therefore also be written like this:

 use Sub::ArgShortcut;
 my $mychomp = argshortcut { chomp @_ };

=head2 C<:ArgShortcut>

Instead of using L<argshortcut|/C<argshortcut(&)>> to wrap a code reference,
you can write regular subs and then add Sub::ArgShortcut functionality to them
implicitly. Simply C<use Sub::Shortcut::Attr> instead of Sub::Shortcut, then
request its behaviour using the C<:ArgShortcut> attribute on functions:

 sub mychomp : ArgShortcut { chomp @_ }

 my $mychomp = sub : ArgShortcut { chomp @_ };

=head1 EXPORTS

Sub::ArgShortcut exports C<argshortcut> by default.

=head1 BUGS AND LIMITATIONS

Passing an empty array to a shortcutting function will probably surprise you:
assuming C<foo> is a function with C<:ArgShortcut> and C<@bar> is an empty
array, then calling C<foo( @bar )> will cause C<foo> to operate on C<$_>! This
is because C<foo> has no way of distinguishing whether it was called without
any arguments or called with arguments that evaluate to an empty list.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
