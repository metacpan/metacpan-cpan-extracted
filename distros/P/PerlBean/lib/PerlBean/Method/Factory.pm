package PerlBean::Method::Factory;

use 5.005;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Used by _value_is_allowed
our %ALLOW_ISA = (
    'perl_bean' => [ 'PerlBean' ],
);

# Used by _value_is_allowed
our %ALLOW_REF = (
);

# Used by _value_is_allowed
our %ALLOW_RX = (
    'method_factory_name' => [ '^\w+$' ],
);

# Used by _value_is_allowed
our %ALLOW_VALUE = (
);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Method::Factory - contains bean method factory information

=head1 SYNOPSIS

None. This is an abstract class.

=head1 ABSTRACT

Abstract PerlBean method factory information

=head1 DESCRIPTION

C<PerlBean::Method::Factory> abstract class for method factory information.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<PerlBean::Method::Factory> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<method_factory_name>>

Passed to L<set_method_factory_name()>. Mandatory option.

=item B<C<perl_bean>>

Passed to L<set_perl_bean()>.

=back

=back

=head1 METHODS

=over

=item create_methods()

This is an interface method. Returns a list of C<PerlBean::Attribute::Method> objects.

=item get_method_factory_name()

Returns method factory's name.

=item get_perl_bean()

Returns the PerlBean to which this method factory belongs.

=item set_method_factory_name(VALUE)

Set method factory's name. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item ^\w+$

=back

=back

=item set_perl_bean(VALUE)

Set the PerlBean to which this method factory belongs. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must be a (sub)class of:

=over

=item PerlBean

=back

=back

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
L<PerlBean::Method::Constructor>,
L<PerlBean::Style>,
L<PerlBean::Symbol>

=head1 BUGS

None known (yet.)

=head1 HISTORY

First development: April 2003
Last update: April 2003

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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Method::Factory::_initialize, first argument must be 'HASH' reference.");

    # method_factory_name, SINGLE, mandatory
    exists( $opt->{method_factory_name} ) || throw Error::Simple("ERROR: PerlBean::Method::Factory::_initialize, option 'method_factory_name' is mandatory.");
    $self->set_method_factory_name( $opt->{method_factory_name} );

    # perl_bean, SINGLE
    exists( $opt->{perl_bean} ) && $self->set_perl_bean( $opt->{perl_bean} );

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

sub create_methods {
    throw Error::Simple("ERROR: PerlBean::Method::Factory::create_methods, call this method in a subclass that has implemented it.");
}

sub get_method_factory_name {
    my $self = shift;

    return( $self->{PerlBean_Method_Factory}{method_factory_name} );
}

sub get_perl_bean {
    my $self = shift;

    return( $self->{PerlBean_Method_Factory}{perl_bean} );
}

sub set_method_factory_name {
    my $self = shift;
    my $val = shift;

    # Value for 'method_factory_name' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: PerlBean::Method::Factory::set_method_factory_name, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'method_factory_name', $val ) || throw Error::Simple("ERROR: PerlBean::Method::Factory::set_method_factory_name, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Method_Factory}{method_factory_name} = $val;
}

sub set_perl_bean {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'perl_bean', $val ) || throw Error::Simple("ERROR: PerlBean::Method::Factory::set_perl_bean, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Method_Factory}{perl_bean} = $val;
}

