package PerlBean::Method::Constructor;

use 5.005;
use base qw( PerlBean::Method );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Method::Constructor - contains bean constructor method information

=head1 SYNOPSIS

 TODO

=head1 ABSTRACT

Abstract PerlBean method information

=head1 DESCRIPTION

C<PerlBean::Method> class for bean constructor method information. This is a subclass from C<PerlBean::Method> with the purpose to differentiate between plain methods and constructors.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<PerlBean::Method::Constructor> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> inherited through package B<C<PerlBean::Method>> may include:

=over

=item B<C<body>>

Passed to L<set_body()>.

=item B<C<description>>

Passed to L<set_description()>.

=item B<C<documented>>

Passed to L<set_documented()>. Defaults to B<1>.

=item B<C<exception_class>>

Passed to L<set_exception_class()>. Defaults to B<'Error::Simple'>.

=item B<C<implemented>>

Passed to L<set_implemented()>. Defaults to B<1>.

=item B<C<interface>>

Passed to L<set_interface()>.

=item B<C<method_name>>

Passed to L<set_method_name()>. Mandatory option.

=item B<C<parameter_description>>

Passed to L<set_parameter_description()>.

=item B<C<perl_bean>>

Passed to L<set_perl_bean()>.

=item B<C<volatile>>

Passed to L<set_volatile()>.

=back

=back

=head1 METHODS

=over

=item get_body()

This method is inherited from package C<PerlBean::Method>. Returns the method's body.

=item get_description()

This method is inherited from package C<PerlBean::Method>. Returns the method description.

=item get_exception_class()

This method is inherited from package C<PerlBean::Method>. Returns the class to throw in eventual interface implementations.

=item get_method_name()

This method is inherited from package C<PerlBean::Method>. Returns the method's name.

=item get_package()

This method is inherited from package C<PerlBean::Method>. Returns the package name. The package name is obtained from the C<PerlBean> to which the C<PerlBean::Attribute> belongs. Or, if the C<PerlBean::Attribute> does not belong to a C<PerlBean>, C<main> is returned.

=item get_parameter_description()

This method is inherited from package C<PerlBean::Method>. Returns the parameter description.

=item get_perl_bean()

This method is inherited from package C<PerlBean::Method>. Returns the PerlBean to which this method belongs.

=item is_documented()

This method is inherited from package C<PerlBean::Method>. Returns whether the method is documented or not.

=item is_implemented()

This method is inherited from package C<PerlBean::Method>. Returns whether the method is implemented or not.

=item is_interface()

This method is inherited from package C<PerlBean::Method>. Returns whether the method is defined as interface or not.

=item is_volatile()

This method is inherited from package C<PerlBean::Method>. Returns whether the method is volatile or not.

=item set_body(VALUE)

This method is inherited from package C<PerlBean::Method>. Set the method's body. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item .*

=back

=back

=item set_description(VALUE)

This method is inherited from package C<PerlBean::Method>. Set the method description. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_documented(VALUE)

This method is inherited from package C<PerlBean::Method>. State that the method is documented. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_exception_class(VALUE)

This method is inherited from package C<PerlBean::Method>. Set the class to throw in eventual interface implementations. C<VALUE> is the value. Default value at initialization is C<Error::Simple>. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_implemented(VALUE)

This method is inherited from package C<PerlBean::Method>. State that the method is implemented. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_interface(VALUE)

This method is inherited from package C<PerlBean::Method>. State that the method is defined as interface. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_method_name(VALUE)

This method is inherited from package C<PerlBean::Method>. Set the method's name. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item ^\w+$

=back

=back

=item set_parameter_description(VALUE)

This method is inherited from package C<PerlBean::Method>. Set the parameter description. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_perl_bean(VALUE)

This method is inherited from package C<PerlBean::Method>. Set the PerlBean to which this method belongs. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must be a (sub)class of:

=over

=item PerlBean

=back

=back

=item set_volatile(VALUE)

This method is inherited from package C<PerlBean::Method>. State that the method is volatile. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item write_code(FILEHANDLE)

This method is inherited from package C<PerlBean::Method>. Write the code for the method to C<FILEHANDLE>. C<FILEHANDLE> is an C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.

=item write_pod(FILEHANDLE)

This method is inherited from package C<PerlBean::Method>. Write the documentation for the method to C<FILEHANDLE>. C<FILEHANDLE> is an C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.

=back

=head1 SEE ALSO

L<PerlBean>,
L<PerlBean::Attribute>,
L<PerlBean::Attribute::Boolean>,
L<PerlBean::Attribute::Factory>,
L<PerlBean::Attribute::Multi>,
L<PerlBean::Attribute::Multi::Ordered>,
L<PerlBean::Attribute::Multi::Unique>,
L<PerlBean::Attribute::Multi::Unique::Associative>,
L<PerlBean::Attribute::Multi::Unique::Associative::MethodKey>,
L<PerlBean::Attribute::Multi::Unique::Ordered>,
L<PerlBean::Attribute::Single>,
L<PerlBean::Collection>,
L<PerlBean::Dependency>,
L<PerlBean::Dependency::Import>,
L<PerlBean::Dependency::Require>,
L<PerlBean::Dependency::Use>,
L<PerlBean::Described>,
L<PerlBean::Described::ExportTag>,
L<PerlBean::Method>,
L<PerlBean::Method::Factory>,
L<PerlBean::Style>,
L<PerlBean::Symbol>

=head1 BUGS

None known (yet.)

=head1 HISTORY

First development: February 2003
Last update: September 2003

=head1 AUTHOR

Vincenzo Zocca

=head1 COPYRIGHT

Copyright 2003 by Vincenzo Zocca

=head1 LICENSE

This file is part of the C<PerlBean> module hierarchy for Perl by
Vincenzo Zocca.

The PerlBean module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The PerlBean module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the PerlBean module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut

