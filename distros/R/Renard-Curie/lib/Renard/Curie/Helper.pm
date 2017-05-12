use Renard::Curie::Setup;
package Renard::Curie::Helper;
# ABSTRACT: Collection of helper utilities for Gtk3 and Glib
$Renard::Curie::Helper::VERSION = '0.001';

use Class::Method::Modifiers;
use Gtk3;
use Function::Parameters;

fun import {
	# Note: The code below is marked as uncoverable because it only applies
	# to a single version of GTK+ and thus is not part of the general
	# coverage. The functionality that it adds is tested in other ways.
	# uncoverable branch true
	if( not Gtk3::CHECK_VERSION('3', '8', '0') ) {
		# For versions of Gtk+ less than v3.8.0, we need to call
		# `Gtk3::ScrolledWindow->add_with_viewport( ... )` so that the
		# child widget gets placed in a viewport.
		#
		# Newer versions of Gtk+ automatically create the viewport when
		# `Gtk3::ScrolledWindow->add( ... )` is called.
		#
		# See:
		# - <https://developer.gnome.org/gtk3/3.6/GtkScrolledWindow.html>
		# - <https://developer.gnome.org/gtk3/3.8/GtkScrolledWindow.html>
		Class::Method::Modifiers::install_modifier
			"Gtk3::ScrolledWindow",
			around => add => fun {
				# uncoverable subroutine
				my $orig = shift;             # uncoverable statement
				my $self = shift;             # uncoverable statement
				$self->add_with_viewport(@_); # uncoverable statement
			};                                    # uncoverable statement
	}

	return;
}

# Note: :prototype($$) would help here, but is only possible on Perl v5.20+

classmethod gval( $glib_typename, $value ) { ## no critic
	# GValue wrapper shortcut
	Glib::Object::Introspection::GValueWrapper->new('Glib::'.ucfirst($glib_typename) => $value);
}

classmethod genum( $package, $sv ) {
	Glib::Object::Introspection->convert_sv_to_enum($package, $sv);
}

classmethod callback( $invocant, $callback_name, @args ) {
	my $fun = $invocant->can( $callback_name );
	$fun->( @args, $invocant );
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords gval genum

=head1 NAME

Renard::Curie::Helper - Collection of helper utilities for Gtk3 and Glib

=head1 VERSION

version 0.001

=head1 CLASS METHODS

=head2 C<gval>

  classmethod gval( $glib_typename, $value )

Given a L<Glib type name|https://developer.gnome.org/glib/stable/glib-Basic-Types.html>, wraps a
Perl value in an object that can be passed to other L<Glib>-based functions.

=over 4

=item *

C<$glib_typename>

The name of a type under the C<Glib::> namespace. For
example, passing in C<"int"> gives a wrapper to the C<gint>
C type which is known as C<Glib::Int> in Perl.

=item *

C<$value>

The value to put inside the wrapper.

=back

See L<Glib::Object::Introspection::GValueWrapper> in
L<Glib::Object::Introspection> for more information.

=head2 genum

  classmethod genum( $package, $sv )

Returns an enumeration value of type C<$package> which contains the matching
enum value given in C<$sv> as a string.

=over 4

=item *

C<$package>

The package name of a L<Glib> enumeration.

=item *

C<$sv>

A string representation of the enumeration value.

=back

For example, for
L<GtkPackType|https://developer.gnome.org/gtk3/stable/gtk3-Standard-Enumerations.html#GtkPackType>
enum, we set C<$package> to C<'Gtk3::PackType'> and C<$sv> to C<'GTK_PACK_START'>.
This can be passed on to other L<Glib::Object::Introspection> methods.

=head2 callback

  classmethod callback( $invocant, $callback_name, @args )

A helper function to redirect to other callback functions. Given an
C<$invocant> and the name of the callback function, C<$callback_name>, which is
defined in the package of C<$invocant>, calls that function with arguments
C<( @args, $invocant )>.

For example, if we are trying to call the callback function
C<Target::Package::on_event_cb> and C<$target> is a blessed reference of type
C<Target::Package>, then by using

  Renard::Curie::Helper->callback( $target, on_event_cb => @rest_of_args );

effectively calls

  Target::Package::on_event_cb( @rest_of_args, $target );

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
