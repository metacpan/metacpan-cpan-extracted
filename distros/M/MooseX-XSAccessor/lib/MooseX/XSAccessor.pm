package MooseX::XSAccessor;

use 5.008;
use strict;
use warnings;

use Moose 2.0600 ();
use MooseX::XSAccessor::Trait::Attribute ();
use Scalar::Util qw(blessed);

BEGIN {
	$MooseX::XSAccessor::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::XSAccessor::VERSION   = '0.008';
}

our $LVALUE;

use Moose::Exporter;
"Moose::Exporter"->setup_import_methods;

sub init_meta
{
	shift;
	my %p = @_;
	Moose::Util::MetaRole::apply_metaroles(
		for             => $p{for_class},
		class_metaroles => {
			attribute => [qw( MooseX::XSAccessor::Trait::Attribute )],
		},
	);
}

sub is_xs
{
	my $sub = $_[0];
	
	if (blessed($sub) and $sub->isa("Class::MOP::Method"))
	{
		$sub = $sub->body;
	}
	elsif (not ref $sub)
	{
		no strict "refs";
		$sub = \&{$sub};
	}
	
	require B;
	!! B::svref_2object($sub)->XSUB;
}

1;

__END__

=pod

=for stopwords Auto-deref Mouse/Class::XSAccessor

=encoding utf-8

=head1 NAME

MooseX::XSAccessor - use Class::XSAccessor to speed up Moose accessors

=head1 SYNOPSIS

   package MyClass;
   
   use Moose;
   use MooseX::XSAccessor;
   
   has foo => (...);

=head1 DESCRIPTION

This module accelerates L<Moose>-generated accessor, reader, writer and
predicate methods using L<Class::XSAccessor>. You get a speed-up for no
extra effort. It is automatically applied to every attribute in the
class.

=begin private

=item init_meta

=end private

The use of the following features of Moose attributes prevents a reader
from being accelerated:

=over

=item *

Lazy builder or lazy default.

=item *

Auto-deref. (Does anybody use this anyway??)

=back

The use of the following features prevents a writer from being
accelerated:

=over

=item *

Type constraints (except C<Any>; C<Any> is effectively a no-op).

=item *

Triggers

=item *

Weak references

=back

An C<rw> accessor is effectively a reader and a writer glued together, so
both of the above lists apply.

Predicates can always be accelerated, provided you're using Class::XSAccessor
1.17 or above.

Clearers can not be accelerated (as of current versions of Class::XSAccessor).

=head2 Functions

This module also provides one function, which is not exported so needs to be
called by its full name.

=over

=item C<< MooseX::XSAccessor::is_xs($sub) >>

Returns a boolean indicating whether a sub is an XSUB.

C<< $sub >> may be a coderef, L<Class::MOP::Method> object, or a qualified
sub name as a string (e.g. C<< "MyClass::foo" >>).

=back

=head2 Chained accessors and writers

L<MooseX::XSAccessor> can detect chained accessors and writers created
using L<MooseX::Attribute::Chained>, and can accelerate those too.

   package Local::Class;
   use Moose;
   use MooseX::XSAccessor;
   use MooseX::Attribute::Chained;
   
   has foo => (traits => ["Chained"], is => "rw");
   has bar => (traits => ["Chained"], is => "ro", writer => "_set_bar");
   has baz => (                       is => "rw");  # not chained
   
   my $obj = "Local::Class"->new;
   $obj->foo(1)->_set_bar(2);
   print $obj->dump;

=head2 Lvalue accessors

L<MooseX::XSAccessor> will detect lvalue accessors created with
L<MooseX::LvalueAttribute> and, by default, skip accelerating them.

However, by setting C<< $MooseX::XSAccessor::LVALUE >> to true
(preferably using the C<local> Perl keyword), you can force it to
accelerate those too. This introduces a visible change in behaviour
though. L<MooseX::LvalueAttribute> accessors normally allow two
patterns for setting the value:

   $obj->foo = 42;   # as an lvalue
   $obj->foo(42);    # as a method call

However, once accelerated, they may I<only> be set as an lvalue.
For this reason, setting C<< $MooseX::XSAccessor::LVALUE >> to true is
considered an experimental feature.

=head1 HINTS

=over

=item *

Make attributes read-only when possible. This means that type constraints
and coercions will only apply to the constructor, not the accessors, enabling
the accessors to be accelerated.

=item *

If you do need a read-write attribute, consider making the main accessor
read-only, and having a separate writer method. (Like
L<MooseX::SemiAffordanceAccessor>.)

=item *

Make defaults eager instead of lazy when possible, allowing your readers
to be accelerated.

=item *

If you need to accelerate just a specific attribute, apply the attribute
trait directly:

   package MyClass;
   
   use Moose;
   
   has foo => (
      traits => ["MooseX::XSAccessor::Trait::Attribute"],
      ...,
   );

=item *

If you don't want to add a dependency on MooseX::XSAccessor, but do want to
use it if it's available, the following code will use it optionally:

   package MyClass;
   
   use Moose;
   BEGIN { eval "use MooseX::XSAccessor" };
   
   has foo => (...);

=back

=head1 CAVEATS

=over

=item *

Calling a writer method without a parameter in Moose does not raise an
exception:

   $person->set_name();    # sets name attribute to "undef"

However, this is a fatal error in Class::XSAccessor.

=item *

MooseX::XSAccessor does not play nice with attribute traits that alter
accessor behaviour, or define additional accessors for attributes.
L<MooseX::SetOnce> is an example thereof. L<MooseX::Attribute::Chained>
is handled as a special case.

=item *

MooseX::XSAccessor only works on blessed hash storage; not e.g.
L<MooseX::ArrayRef> or L<MooseX::InsideOut>. MooseX::XSAccessor is
usually able to detect such situations and silently switch itself off.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-XSAccessor>.

=head1 SEE ALSO

L<MooseX::XSAccessor::Trait::Attribute>.

L<Moose>, L<Moo>, L<Class::XSAccessor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

