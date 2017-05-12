package PerlBean::Dependency::Require;

use 5.005;
use base qw( PerlBean::Dependency );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Dependency::Require - Require dependency in a Perl bean

=head1 SYNOPSIS

TODO

=head1 ABSTRACT

Require dependency in a Perl bean

=head1 DESCRIPTION

C<PerlBean::Dependency::Require> is a class to express C<require> dependencies to classes/modules/files in a C<PerlBean>.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<PerlBean::Dependency::Require> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> inherited through package B<C<PerlBean::Dependency>> may include:

=over

=item B<C<dependency_name>>

Passed to L<set_dependency_name()>.

=item B<C<volatile>>

Passed to L<set_volatile()>.

=back

=back

=head1 METHODS

=over

=item get_dependency_name()

This method is inherited from package C<PerlBean::Dependency>. Returns the dependency name.

=item is_volatile()

This method is inherited from package C<PerlBean::Dependency>. Returns whether the dependency is volatile or not.

=item set_dependency_name(VALUE)

This method is inherited from package C<PerlBean::Dependency>. Set the dependency name. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item ^.*[a-zA-Z].*$

=back

=back

=item set_volatile(VALUE)

This method is inherited from package C<PerlBean::Dependency>. State that the dependency is volatile. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item write(FILEHANDLE)

This method is an implementation from package C<PerlBean::Dependency>. Writes code for the dependency. C<FILEHANDLE> is an C<IO::Handle> object.

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
L<PerlBean::Dependency::Use>,
L<PerlBean::Described>,
L<PerlBean::Described::ExportTag>,
L<PerlBean::Method>,
L<PerlBean::Method::Constructor>,
L<PerlBean::Method::Factory>,
L<PerlBean::Style>,
L<PerlBean::Symbol>

=head1 BUGS

None known (yet.)

=head1 HISTORY

First development: March 2003
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

sub write {
    my $self = shift;
    my $fh = shift;

    my $dn = $self->get_dependency_name();

    $fh->print( "require $dn;\n" )
}

