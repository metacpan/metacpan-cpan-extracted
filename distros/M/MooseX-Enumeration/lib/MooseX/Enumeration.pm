use 5.008001;
use strict;
use warnings;

package MooseX::Enumeration;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

{
	my $impl;
	sub _enum_type_implementation
	{
		$impl ||= eval { require Type::Tiny::Enum }
			? 'Type::Tiny::Enum'
			: do {
				require Moose::Meta::TypeConstraint::Enum;
				'Moose::Meta::TypeConstraint::Enum';
			};
	}
}

1;

__END__

=pod

=encoding utf-8

=for stopwords enum enums

=head1 NAME

MooseX::Enumeration - a native attribute trait for enums

=head1 SYNOPSIS

Given this class:

   package MyApp::Result {
      use Moose;
      use Types::Standard qw(Enum);
      has status => (
         is        => "rw",
         isa       => Enum[qw/ pass fail /],
      );
   }

It's quite common to do this kind of thing:

   if ( $result->status eq "pass" ) { ... }

But if you're throwing strings around, it can be quite easy to mistype
them:

   if ( $result->status eq "apss" ) { ... }

And the comparison silently fails. Instead, let's define the class like
this:

   package MyApp::Result {
      use Moose;
      use Types::Standard qw(Enum);
      has status => (
         traits    => ["Enumeration"],
         is        => "rw",
         isa       => Enum[qw/ pass fail /],
         handles   => [qw/ is_pass is_fail /],
      );
   }

So you can use the class like this:

   if ( $result->is_pass ) { ... }

Yay!

=head1 DESCRIPTION

This attribute trait makes it easier to work with enumerated types in
L<Moose>. (Hopefully a L<Moo> implementation will follow soon.)

It will only work on attributes which have an enum type constraint.
This may be a L<Type::Tiny::Enum> or may be a type constraint defined
using Moose's built-in enum types.

=head2 Type Constraint Shortcut

This trait gives you a shortcut for specifying an enum type constraint:

   has status => (
      traits    => ["Enumeration"],
      is        => "rw",
      enum      => [qw/ pass fail /],   # instead of isa
   );

=head2 Delegation

=over

=item C<< is >>

The trait also allows you to delegate "is" to the attribute value.

   # the most longhanded form...
   #
   has status => (
      traits    => ["Enumeration"],
      is        => "rw",
      enum      => [qw/ pass fail /],
      handles   => {
         is_pass  => ["is", "pass"],
         is_fail  => ["is", "fail"],
      }
   );

Note that above, we might have called the delegated method
C<< "did_pass" >> instead of C<< "is_pass" >>. You can call it what you
like.

   has status => (
      traits    => ["Enumeration"],
      is        => "rw",
      enum      => [qw/ pass fail /],
      handles   => {
         did_pass    => ["is", "pass"],
         didnt_pass  => ["is", "fail"],
      }
   );

To save typing, we offer some shorthands for common patterns.

   has status => (
      traits    => ["Enumeration"],
      is        => "rw",
      enum      => [qw/ pass fail /],
      handles   => {
         is_pass  => "is_pass",
         is_fail  => "is_fail",
      }
   );

In the hashref values, we implicitly split on the first underscore, so
C<< "is_pass" >> is equivalent to C<< ["is", "pass"] >>.

This is still repetitive, so how about...

   has status => (
      traits    => ["Enumeration"],
      is        => "rw",
      enum      => [qw/ pass fail /],
      handles   => [ "is_pass", "is_fail" ],
   );

If an arrayref of delegates is given, it mapped like this:

   my %delegate_hash = map { $_ => $_ } @delegate_array;

We can still go one better...

   has status => (
      traits    => ["Enumeration"],
      is        => "rw",
      enum      => [qw/ pass fail /],
      handles   => 1,
   );

This will create a delegated method for each value in the enumeration.

As a slightly more advanced option, which will only work for the
long-hand version, you may match the value against a regular expression
or any other value that may serve as a right-hand side for a
L<match::simple> match operation:

   has status => (
      traits    => ["Enumeration"],
      is        => "rw",
      enum      => [qw/ pass fail skip todo /],
      handles   => {
         is_pass  => [ "is", qr{^pass$} ],
         is_fail  => [ "is", "fail" ],
         is_other => [ "is", [qw(skip todo)] ],
      }
   );

=item C<< assign >>

The Enumeration trait allows you to delegate to "assign":

   has status => (
      traits    => ["Enumeration"],
      is        => "ro",
      enum      => [qw/ pass fail unknown /],
      handles   => {
         "set_status_pass"  => [ "assign", "pass" ],
         "set_status_fail"  => [ "assign", "fail" ],
         "clear_status"     => [ "assign", "unknown" ],
      }
   );
   
   ...;
   $obj->set_status_pass;   # sets the object's status to "pass"

It is possible to restrict allowed transitions by adding an extra
parameter. In the following example you can only set the status to
"pass" if the current status is "unknown", and you can only set the
status to "fail" if the current status begins with "u" (effectively
the same thing).

   has status => (
      traits    => ["Enumeration"],
      is        => "ro",
      enum      => [qw/ pass fail unknown /],
      handles   => {
         "set_status_pass"  => [ "assign", "pass", "unknown" ],
         "set_status_fail"  => [ "assign", "fail", qr{^u} ],
         "clear_status"     => [ "assign", "unknown" ],
      }
   );

Calling C<set_status_pass> if the status is already "pass" is
conceptually a no-op, so is always allowed.

Methods delegated to C<assign> always return C<< $self >> so are
suitable for chaining.

=back

=head1 PERFORMANCE

As of version 0.003, C<< $obj->is_pass >> actually benchmarks I<faster>
than C<< $obj->status eq "pass" >>. The latter comparison can be
accelerated using L<MooseX::XSAccessor> but this module can not (yet)
provide an XS version for C<is_pass>. :-(

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Enumeration>.

=head1 SEE ALSO

L<Moose::Meta::TypeConstraint::Enum>,
L<Type::Tiny::Enum>,
L<Moose::Meta::Attribute::Native>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

