package PerlBean::Method;

use 5.005;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use PerlBean::Style qw(:codegen);

# Variable to not confuse AutoLoader
our $SUB = 'sub';

# Used by _value_is_allowed
our %ALLOW_ISA = (
    'perl_bean' => [ 'PerlBean' ],
);

# Used by _value_is_allowed
our %ALLOW_REF = (
);

# Used by _value_is_allowed
our %ALLOW_RX = (
    'body' => [ '.*' ],
    'method_name' => [ '^\w+$' ],
);

# Used by _value_is_allowed
our %ALLOW_VALUE = (
);

# Used by _initialize
our %DEFAULT_VALUE = (
    'documented' => 1,
    'exception_class' => 'Error::Simple',
    'implemented' => 1,
);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Method - contains bean method information

=head1 SYNOPSIS

 TODO

=head1 ABSTRACT

Abstract PerlBean method information

=head1 DESCRIPTION

C<PerlBean::Method> class for bean method information.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<PerlBean::Method> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

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

Returns the method's body.

=item get_description()

Returns the method description.

=item get_exception_class()

Returns the class to throw in eventual interface implementations.

=item get_method_name()

Returns the method's name.

=item get_package()

Returns the package name. The package name is obtained from the C<PerlBean> to which the C<PerlBean::Attribute> belongs. Or, if the C<PerlBean::Attribute> does not belong to a C<PerlBean>, C<main> is returned.

=item get_parameter_description()

Returns the parameter description.

=item get_perl_bean()

Returns the PerlBean to which this method belongs.

=item is_documented()

Returns whether the method is documented or not.

=item is_implemented()

Returns whether the method is implemented or not.

=item is_interface()

Returns whether the method is defined as interface or not.

=item is_volatile()

Returns whether the method is volatile or not.

=item set_body(VALUE)

Set the method's body. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item .*

=back

=back

=item set_description(VALUE)

Set the method description. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_documented(VALUE)

State that the method is documented. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_exception_class(VALUE)

Set the class to throw in eventual interface implementations. C<VALUE> is the value. Default value at initialization is C<Error::Simple>. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_implemented(VALUE)

State that the method is implemented. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_interface(VALUE)

State that the method is defined as interface. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_method_name(VALUE)

Set the method's name. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item ^\w+$

=back

=back

=item set_parameter_description(VALUE)

Set the parameter description. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_perl_bean(VALUE)

Set the PerlBean to which this method belongs. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must be a (sub)class of:

=over

=item PerlBean

=back

=back

=item set_volatile(VALUE)

State that the method is volatile. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item write_code(FILEHANDLE)

Write the code for the method to C<FILEHANDLE>. C<FILEHANDLE> is an C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.

=item write_pod(FILEHANDLE)

Write the documentation for the method to C<FILEHANDLE>. C<FILEHANDLE> is an C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.

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
L<PerlBean::Method::Constructor>,
L<PerlBean::Method::Factory>,
L<PerlBean::Style>,
L<PerlBean::Symbol>

=head1 BUGS

None known (yet.)

=head1 HISTORY

First development: January 2003
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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Method::_initialize, first argument must be 'HASH' reference.");

    # body, SINGLE
    exists( $opt->{body} ) && $self->set_body( $opt->{body} );

    # description, SINGLE
    exists( $opt->{description} ) && $self->set_description( $opt->{description} );

    # documented, BOOLEAN, with default value
    $self->set_documented( exists( $opt->{documented} ) ? $opt->{documented} : $DEFAULT_VALUE{documented} );

    # exception_class, SINGLE, with default value
    $self->set_exception_class( exists( $opt->{exception_class} ) ? $opt->{exception_class} : $DEFAULT_VALUE{exception_class} );

    # implemented, BOOLEAN, with default value
    $self->set_implemented( exists( $opt->{implemented} ) ? $opt->{implemented} : $DEFAULT_VALUE{implemented} );

    # interface, BOOLEAN
    exists( $opt->{interface} ) && $self->set_interface( $opt->{interface} );

    # method_name, SINGLE, mandatory
    exists( $opt->{method_name} ) || throw Error::Simple("ERROR: PerlBean::Method::_initialize, option 'method_name' is mandatory.");
    $self->set_method_name( $opt->{method_name} );

    # parameter_description, SINGLE
    exists( $opt->{parameter_description} ) && $self->set_parameter_description( $opt->{parameter_description} );

    # perl_bean, SINGLE
    exists( $opt->{perl_bean} ) && $self->set_perl_bean( $opt->{perl_bean} );

    # volatile, BOOLEAN
    exists( $opt->{volatile} ) && $self->set_volatile( $opt->{volatile} );

    # Return $self
    return($self);
}

sub _get_super_method {
    my $self = shift;

    # No super method found if no collection defined
    defined( $self->get_perl_bean() ) || return(undef);
    defined( $self->get_perl_bean()->get_collection() ) || return(undef);

    # Look for the method in super classes
    foreach my $super_pkg ( $self->get_perl_bean()->get_base() ) {
        # Get the superclass bean
        my $super_bean = ( $self->get_perl_bean()->get_collection()->values_perl_bean($super_pkg) )[0];

        # If the super class bean has no bean in the collection then no method is found
        defined($super_bean) || return(undef);

        # See if the super class bean has the method
        my $super_meth = $super_bean->_get_super_method( $self, {
            $self->get_perl_bean()->get_package() => 1,
        } );

        # Return the suprclass method if found
        defined($super_meth) && return($super_meth);
    }

    # Nothing found
    return(undef);
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

sub get_body {
    my $self = shift;

    return( $self->{PerlBean_Method}{body} );
}

sub get_description {
    my $self = shift;

    if ( $self->{PerlBean_Method}{description} ) {
        if ( $self->{PerlBean_Method}{description} =~ /__SUPER_POD__/ ) {
            my $super_meth = $self->_get_super_method();
            my $super_pod = '';
            $super_pod = $super_meth->get_description() if ( defined($super_meth) );
            chomp( $super_pod );
            my $ret = $self->{PerlBean_Method}{description};
            $ret =~ s/__SUPER_POD__/$super_pod/g;
            return($ret);
        }
        else {
            return( $self->{PerlBean_Method}{description} );
        }
    }

    my $super_meth = $self->_get_super_method();
    defined( $super_meth ) && return( $super_meth->get_description() );

    return('');
}

sub get_exception_class {
    my $self = shift;

    return( $self->{PerlBean_Method}{exception_class} );
}

sub get_method_name {
    my $self = shift;

    return( $self->{PerlBean_Method}{method_name} );
}

sub get_package {
    my $self = shift;

    # Get the package name from the PerlBean
    defined( $self->get_perl_bean ) &&
        return( $self->get_perl_bean()->get_package() );

    # Return 'main' as default
    return('main');
}

sub get_parameter_description {
    my $self = shift;

    if ( $self->{PerlBean_Method}{parameter_description} ) {
        if ( $self->{PerlBean_Method}{parameter_description} =~ /__SUPER_POD__/ ) {
            my $super_meth = $self->_get_super_method();
            my $super_pod = '';
            $super_pod = $super_meth->get_parameter_description() if ( defined($super_meth) );
            my $ret = $self->{PerlBean_Method}{parameter_description};
            $ret =~ s/__SUPER_POD__/$super_pod/g;
            return($ret);
        }
        else {
            return( $self->{PerlBean_Method}{parameter_description} );
        }
    }

    my $super_meth = $self->_get_super_method();
    defined($super_meth) && return( $super_meth->get_parameter_description() );

    return('');
}

sub get_perl_bean {
    my $self = shift;

    return( $self->{PerlBean_Method}{perl_bean} );
}

sub is_documented {
    my $self = shift;

    if ( $self->{PerlBean_Method}{documented} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_implemented {
    my $self = shift;

    if ( $self->{PerlBean_Method}{implemented} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_interface {
    my $self = shift;

    if ( $self->{PerlBean_Method}{interface} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_volatile {
    my $self = shift;

    if ( $self->{PerlBean_Method}{volatile} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub set_body {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'body', $val ) || throw Error::Simple("ERROR: PerlBean::Method::set_body, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Method}{body} = $val;
}

sub set_description {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'description', $val ) || throw Error::Simple("ERROR: PerlBean::Method::set_description, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Method}{description} = $val;
}

sub set_documented {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Method}{documented} = 1;
    }
    else {
        $self->{PerlBean_Method}{documented} = 0;
    }
}

sub set_exception_class {
    my $self = shift;
    my $val = shift;

    # Value for 'exception_class' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: PerlBean::Method::set_exception_class, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'exception_class', $val ) || throw Error::Simple("ERROR: PerlBean::Method::set_exception_class, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Method}{exception_class} = $val;
}

sub set_implemented {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Method}{implemented} = 1;
    }
    else {
        $self->{PerlBean_Method}{implemented} = 0;
    }
}

sub set_interface {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Method}{interface} = 1;
    }
    else {
        $self->{PerlBean_Method}{interface} = 0;
    }
}

sub set_method_name {
    my $self = shift;
    my $val = shift;

    # Value for 'method_name' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: PerlBean::Method::set_method_name, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'method_name', $val ) || throw Error::Simple("ERROR: PerlBean::Method::set_method_name, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Method}{method_name} = $val;
}

sub set_parameter_description {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'parameter_description', $val ) || throw Error::Simple("ERROR: PerlBean::Method::set_parameter_description, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Method}{parameter_description} = $val;
}

sub set_perl_bean {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'perl_bean', $val ) || throw Error::Simple("ERROR: PerlBean::Method::set_perl_bean, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Method}{perl_bean} = $val;
}

sub set_volatile {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Method}{volatile} = 1;
    }
    else {
        $self->{PerlBean_Method}{volatile} = 0;
    }
}

sub write_code {
    my $self = shift;
    my $fh = shift;

    # Do nothing if not implemented
    $self->is_implemented() || return;

    my $name = $self->get_method_name();
    my $ec = $self->get_exception_class();
    my $body = $self->is_interface() ?
            "${IND}throw $ec${BFP}(\"ERROR: " .
            $self->get_package() .
            '::' .
            $self->get_method_name() .
            ", call this method in a subclass that has implemented it.\");\n"
        : '';
    $body = defined( $self->get_body() ) ? $self->get_body() : $body;
    $fh->print(<<EOF);
$SUB $name${PBOC[0]}{
$body}

EOF
}

sub write_pod {
    my $self = shift;
    my $fh = shift;
    my $pkg = shift;

    # Do nothing if not documented
    $self->is_documented() || return;

    my $name = $self->get_method_name();
    my $pre = '';
    my $par = $self->get_parameter_description();
    my $desc = $self->get_description() || "\n";;
    if ( $pkg eq $self->get_package() ) {
        if ( $self->is_interface() ) {
            $pre = "This is an interface method. ";
        }
        else {
            my $super_meth = $self->_get_super_method();
            if ( defined($super_meth) ) {
                if ( $super_meth->is_interface() ) {
                    $pre = "This method is an implementation from package C<" .
                        $super_meth->get_package() . ">. ";
                }
                elsif( ! $self->isa('PerlBean::Method::Constructor') ) {
                    $pre = "This method is overloaded from package C<" .
                        $super_meth->get_package() . ">. ";
                }
            }
        }
    }
    elsif( ! $self->isa('PerlBean::Method::Constructor') ) {
        $pre = "This method is inherited from package C<" .
            $self->get_package() . ">. ";
    }
    $fh->print(<<EOF);
\=item $name${BFP}($par)

$pre$desc
EOF
}

