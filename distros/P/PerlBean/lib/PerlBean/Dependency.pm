package PerlBean::Dependency;

use 5.005;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Used by _value_is_allowed
our %ALLOW_ISA = (
);

# Used by _value_is_allowed
our %ALLOW_REF = (
);

# Used by _value_is_allowed
our %ALLOW_RX = (
    'dependency_name' => [ '^.*[a-zA-Z].*$' ],
);

# Used by _value_is_allowed
our %ALLOW_VALUE = (
);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Dependency - Dependency in a Perl bean

=head1 SYNOPSIS

None, this is an abstract class.

=head1 ABSTRACT

Dependency (use, require or import) in a Perl bean

=head1 DESCRIPTION

C<PerlBean::Dependency> is an abstract class to express dependencies to classes/modules/files in a C<PerlBean>.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<PerlBean::Dependency> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

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

Returns the dependency name.

=item is_volatile()

Returns whether the dependency is volatile or not.

=item set_dependency_name(VALUE)

Set the dependency name. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item ^.*[a-zA-Z].*$

=back

=back

=item set_volatile(VALUE)

State that the dependency is volatile. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item write(FILEHANDLE)

This is an interface method. Writes code for the dependency. C<FILEHANDLE> is an C<IO::Handle> object.

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
L<PerlBean::Dependency::Import>,
L<PerlBean::Dependency::Require>,
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

sub new {
    my $class = shift;

    my $self = {};
    bless( $self, ( ref($class) || $class ) );
    return( $self->_initialize(@_) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Dependency::_initialize, first argument must be 'HASH' reference.");

    # dependency_name, SINGLE
    exists( $opt->{dependency_name} ) && $self->set_dependency_name( $opt->{dependency_name} );

    # volatile, BOOLEAN
    exists( $opt->{volatile} ) && $self->set_volatile( $opt->{volatile} );

    # Return $self
    return($self);
}

sub _value_is_allowed {
    my $name = shift;

    # Value is allowed if no ALLOW clauses exist for the named attribute
    if ( ! exists( $ALLOW_ISA{$name} ) && ! exists( $ALLOW_REF{$name} ) && ! exists( $ALLOW_RX{$name} ) && ! exists( $ALLOW_VALUE{$name} ) ) {
        return(1);
    }

    # At this point, all values in @_ must to be allowed
    CHECK_VALUES:
    foreach my $val (@_) {
        # Check ALLOW_ISA
        if ( ref($val) && exists( $ALLOW_ISA{$name} ) ) {
            foreach my $class ( @{ $ALLOW_ISA{$name} } ) {
                &UNIVERSAL::isa( $val, $class ) && next CHECK_VALUES;
            }
        }

        # Check ALLOW_REF
        if ( ref($val) && exists( $ALLOW_REF{$name} ) ) {
            exists( $ALLOW_REF{$name}{ ref($val) } ) && next CHECK_VALUES;
        }

        # Check ALLOW_RX
        if ( defined($val) && ! ref($val) && exists( $ALLOW_RX{$name} ) ) {
            foreach my $rx ( @{ $ALLOW_RX{$name} } ) {
                $val =~ /$rx/ && next CHECK_VALUES;
            }
        }

        # Check ALLOW_VALUE
        if ( ! ref($val) && exists( $ALLOW_VALUE{$name} ) ) {
            exists( $ALLOW_VALUE{$name}{$val} ) && next CHECK_VALUES;
        }

        # We caught a not allowed value
        return(0);
    }

    # OK, all values are allowed
    return(1);
}

sub get_dependency_name {
    my $self = shift;

    return( $self->{PerlBean_Dependency}{dependency_name} );
}

sub is_volatile {
    my $self = shift;

    if ( $self->{PerlBean_Dependency}{volatile} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub set_dependency_name {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'dependency_name', $val ) || throw Error::Simple("ERROR: PerlBean::Dependency::set_dependency_name, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Dependency}{dependency_name} = $val;
}

sub set_volatile {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Dependency}{volatile} = 1;
    }
    else {
        $self->{PerlBean_Dependency}{volatile} = 0;
    }
}

sub write {
    throw Error::Simple("ERROR: PerlBean::Dependency::write, call this method in a subclass that has implemented it.");
}

