package PerlBean::Attribute;

use 5.005;
use base qw( PerlBean::Method::Factory );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use PerlBean::Style qw(:codegen);

# Legacy count variable
our $LEGACY_COUNT = 0;

# Used by _initialize
our %DEFAULT_VALUE = (
    'documented' => 1,
    'exception_class' => 'Error::Simple',
    'mandatory' => 0,
);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Attribute - contains bean attribute information

=head1 SYNOPSIS

None. This is an abstract class.

=head1 ABSTRACT

Abstract PerlBean attribute information

=head1 DESCRIPTION

C<PerlBean::Attribute> abstract class for bean attribute information. Attribute access methods are implemented and code and documentation generation interface methods are defined.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<PerlBean::Attribute> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<default_value>>

Passed to L<set_default_value()>.

=item B<C<documented>>

Passed to L<set_documented()>. Defaults to B<1>.

=item B<C<exception_class>>

Passed to L<set_exception_class()>. Defaults to B<'Error::Simple'>.

=item B<C<mandatory>>

Passed to L<set_mandatory()>. Defaults to B<0>.

=item B<C<method_base>>

Passed to L<set_method_base()>.

=item B<C<short_description>>

Passed to L<set_short_description()>.

=back

Options for C<OPT_HASH_REF> inherited through package B<C<PerlBean::Method::Factory>> may include:

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

=item get_default_value()

Returns attribute default value.

=item get_exception_class()

Returns the class to throw when an exception occurs.

=item get_method_base()

Returns the method base name.

=item get_method_factory_name()

This method is inherited from package C<PerlBean::Method::Factory>. Returns method factory's name.

=item get_package()

Returns the package name. The package name is obtained from the C<PerlBean> to which the C<PerlBean::Attribute> belongs. Or, if the C<PerlBean::Attribute> does not belong to a C<PerlBean>, C<main> is returned.

=item get_package_us()

Calls C<get_package()> and replaces C<:+> with C <_>.

=item get_perl_bean()

This method is inherited from package C<PerlBean::Method::Factory>. Returns the PerlBean to which this method factory belongs.

=item get_short_description()

Returns the attribute description.

=item is_documented()

Returns whether the attribute is documented or not.

=item is_mandatory()

Returns whether the attribute is mandatory for construction or not.

=item mk_doc_clauses()

Returns a string containing the documentation for the clauses to which the contents the contents of the attribute must adhere.

=item set_default_value(VALUE)

Set attribute default value. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_documented(VALUE)

State that the attribute is documented. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_exception_class(VALUE)

Set the class to throw when an exception occurs. C<VALUE> is the value. Default value at initialization is C<Error::Simple>. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_mandatory(VALUE)

State that the attribute is mandatory for construction. C<VALUE> is the value. Default value at initialization is C<0>. On error an exception C<Error::Simple> is thrown.

=item set_method_base(VALUE)

Set the method base name. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_method_factory_name(VALUE)

This method is inherited from package C<PerlBean::Method::Factory>. Set method factory's name. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item ^\w+$

=back

=back

=item set_perl_bean(VALUE)

This method is inherited from package C<PerlBean::Method::Factory>. Set the PerlBean to which this method factory belongs. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must be a (sub)class of:

=over

=item PerlBean

=back

=back

=item set_short_description(VALUE)

Set the attribute description. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item type()

Determines and returns the type of the attribute. The type is either C<BOOLEAN>, C<SINGLE> or C<MULTI>.

=item write_constructor_option_code()

This is an interface method. Writes constructor code for the attribute option.

=item write_constructor_option_doc()

This is an interface method. Writes constructor documentation for the attribute option.

=item write_default_value()

This is an interface method. Returns a C<%DEFAULT_VALUE> line string for the attribute.

=back

=head1 SEE ALSO

L<PerlBean>,
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
L<PerlBean::Method::Factory>,
L<PerlBean::Style>,
L<PerlBean::Symbol>

=head1 BUGS

None known (yet.)

=head1 HISTORY

First development: November 2002
Last update: September 2003

=head1 AUTHOR

Vincenzo Zocca

=head1 COPYRIGHT

Copyright 2002, 2003 by Vincenzo Zocca

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

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Attribute::_initialize, first argument must be 'HASH' reference.");

    # Legacy support for attribute_name
    if ( exists( $opt->{attribute_name} ) ) {
        $LEGACY_COUNT++;
        if ( exists( $opt->{method_factory_name} ) ) {
            ( $LEGACY_COUNT < 4 ) && print STDERR "WARNING: PerlBean::Attribute::_initialize, you use both attributes named 'attribute_name' and 'method_factory_name'. Attribute named 'attribute_name' is discarded. This warning will be discontinued from the 4th of April 2004 on. Change your code and remove the 'attribute_name' attribute.\nNOW!\n";
        }
        else {
            $opt->{method_factory_name} = $opt->{attribute_name};
            ( $LEGACY_COUNT < 4 ) && print STDERR "WARNING: PerlBean::Attribute::_initialize, attribute named 'attribute_name' has legacy support which will be discontinued from the 4th of April 2004 on. Change your code to use the 'method_factory_name' attribute.\nNOW!\n";
        }
        ( $LEGACY_COUNT == 3 ) && print STDERR "Oh bother...\n";
    }

    # default_value, SINGLE
    exists( $opt->{default_value} ) && $self->set_default_value( $opt->{default_value} );

    # documented, BOOLEAN, with default value
    $self->set_documented( exists( $opt->{documented} ) ? $opt->{documented} : $DEFAULT_VALUE{documented} );

    # exception_class, SINGLE, with default value
    $self->set_exception_class( exists( $opt->{exception_class} ) ? $opt->{exception_class} : $DEFAULT_VALUE{exception_class} );

    # mandatory, BOOLEAN, with default value
    $self->set_mandatory( exists( $opt->{mandatory} ) ? $opt->{mandatory} : $DEFAULT_VALUE{mandatory} );

    # method_base, SINGLE
    exists( $opt->{method_base} ) && $self->set_method_base( $opt->{method_base} );

    # short_description, SINGLE
    exists( $opt->{short_description} ) && $self->set_short_description( $opt->{short_description} );

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _esc_apos {
    my $self = shift;

    my @in = @_;
    my @el = ();
    foreach my $el (@in) {
        if ( $el =~ /^[+-]?\d+$/ ) {
            $el = ( int($el) );
        }
        else {
            $el =~ s/'/\\'/g;
            $el = '\'' . $el . '\'';
        }
        push( @el, $el );
    }
    if (wantarray) {
        return(@el);
    }
    else {
        return( join( ', ', @el ) );
    }
}

sub _esc_aq {
    my $self = shift;

    my $do_quote = 0;
    foreach my $el (@_) {
        if ($el =~ /[\n\r\t\f\a\e]/) {
            $do_quote = 1;
            last;
        }
    }

    if (wantarray) {
        return (
            $do_quote ?
                ( $self->_esc_quote(@_) ) :
                ( $self->_esc_apos(@_) )
        );
    }
    else {
        return (
            $do_quote ?
                scalar( $self->_esc_quote(@_) ) :
                scalar( $self->_esc_apos(@_) )
        );
    }
}

sub _esc_quote {
    my $self = shift;

    my @in = @_;
    my @el = ();
    foreach my $el (@in) {
        if ( $el =~ /^[+-]?\d+$/ ) {
            $el = ( int($el) );
        }
        else {
            $el =~ s/\\/\\\\/g;
            $el =~ s/\n/\\n/g;
            $el =~ s/\r/\\r/g;
            $el =~ s/\t/\\t/g;
            $el =~ s/\f/\\f/g;
            $el =~ s/\a/\\a/g;
            $el =~ s/\e/\\e/g;
            $el =~ s/([\$\@\%"])/\\$1/g;
            $el = '"' . $el . '"';
        }
        push( @el, $el );
    }
    if (wantarray) {
        return(@el);
    }
    else {
        return( join( ', ', @el ) );
    }
}

sub _get_overloaded_attribute {
    my $self = shift;

    # No attribute found if no collection defined
    defined( $self->get_perl_bean() ) || return(undef);
    defined( $self->get_perl_bean()->get_collection() ) || return(undef);

    # Look for the attribute in super classes
    foreach my $super_pkg ( $self->get_perl_bean()->get_base() ) {
        # Get the super class bean
        my $super_bean = ( $self->get_perl_bean()->get_collection()->
                                            values_perl_bean($super_pkg) )[0];

        # If the super class bean has no bean in the collection then no
        # attribute is found
        defined($super_bean) || return(undef);

        # See if the super class bean has an attribute
        my $attr_over = $super_bean->_get_overloaded_attribute( $self, {
            $self->get_perl_bean()->get_package() => 1,
        } );

        # Return the overloaded bean if found
        defined($attr_over) && return($attr_over);
    }

    # Nothing found
    return(undef);
}

sub _value_is_allowed {
    return(1);
}

sub create_methods {
    throw Error::Simple("ERROR: PerlBean::Attribute::create_methods, call this method in a subclass that has implemented it.");
}

sub get_default_value {
    my $self = shift;

    return( $self->{PerlBean_Attribute}{default_value} );
}

sub get_exception_class {
    my $self = shift;

    return( $self->{PerlBean_Attribute}{exception_class} );
}

sub get_method_base {
    my $self = shift;

    defined( $self->{PerlBean_Attribute}{method_base} ) && return( $self->{PerlBean_Attribute}{method_base} );

    my $style = PerlBean::Style->instance();
    return( &{$AN2MBF}( $self->get_method_factory_name() ) );
}

sub get_package {
    my $self = shift;

    defined( $self->get_perl_bean() ) || return('main');
    return( $self->get_perl_bean()->get_package() );
}

sub get_package_us {
    my $self = shift;

    my $pkg = $self->get_package();
    $pkg =~ s/:+/_/g;
    return($pkg);
}

sub get_short_description {
    my $self = shift;

    return( $self->{PerlBean_Attribute}{short_description} );
}

sub is_documented {
    my $self = shift;

    if ( $self->{PerlBean_Attribute}{documented} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_mandatory {
    my $self = shift;

    if ( $self->{PerlBean_Attribute}{mandatory} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub mk_doc_clauses {
    my $self = shift;

    return('') if ( ! scalar( $self->values_allow_isa() ) &&
        ! scalar( $self->values_allow_ref() ) &&
        ! scalar( $self->values_allow_rx() ) &&
        ! scalar( $self->values_allow_value() )
    );

    # Make the clauses for documentation
    my $doc = <<EOF;
\=over

EOF

    $doc .= $self->mk_doc_clauses_allow_isa(@_);
    $doc .= $self->mk_doc_clauses_allow_ref(@_);
    $doc .= $self->mk_doc_clauses_allow_rx(@_);
    $doc .= $self->mk_doc_clauses_allow_value(@_);

    $doc .= <<EOF;
\=back

EOF

    # Return the clauses for documentation
    return($doc);
}

sub set_default_value {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'default_value', $val ) || throw Error::Simple("ERROR: PerlBean::Attribute::set_default_value, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Attribute}{default_value} = $val;
}

sub set_documented {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Attribute}{documented} = 1;
    }
    else {
        $self->{PerlBean_Attribute}{documented} = 0;
    }
}

sub set_exception_class {
    my $self = shift;
    my $val = shift;

    # Value for 'exception_class' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: PerlBean::Attribute::set_exception_class, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'exception_class', $val ) || throw Error::Simple("ERROR: PerlBean::Attribute::set_exception_class, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Attribute}{exception_class} = $val;
}

sub set_mandatory {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Attribute}{mandatory} = 1;
    }
    else {
        $self->{PerlBean_Attribute}{mandatory} = 0;
    }
}

sub set_method_base {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'method_base', $val ) || throw Error::Simple("ERROR: PerlBean::Attribute::set_method_base, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Attribute}{method_base} = $val;
}

sub set_short_description {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'short_description', $val ) || throw Error::Simple("ERROR: PerlBean::Attribute::set_short_description, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Attribute}{short_description} = $val;
}

sub type {
    my $self = shift;

    $self->isa('PerlBean::Attribute::Boolean') && return('BOOLEAN');
    $self->isa('PerlBean::Attribute::Multi') && return('MULTI');
    $self->isa('PerlBean::Attribute::Single') && return('SINGLE');
}

sub write_allow_isa {
    throw Error::Simple("ERROR: PerlBean::Attribute::write_allow_isa, call this method in a subclass that has implemented it.");
}

sub write_allow_ref {
    throw Error::Simple("ERROR: PerlBean::Attribute::write_allow_ref, call this method in a subclass that has implemented it.");
}

sub write_allow_rx {
    throw Error::Simple("ERROR: PerlBean::Attribute::write_allow_rx, call this method in a subclass that has implemented it.");
}

sub write_allow_value {
    throw Error::Simple("ERROR: PerlBean::Attribute::write_allow_value, call this method in a subclass that has implemented it.");
}

sub write_constructor_option_code {
    throw Error::Simple("ERROR: PerlBean::Attribute::write_constructor_option_code, call this method in a subclass that has implemented it.");
}

sub write_constructor_option_doc {
    throw Error::Simple("ERROR: PerlBean::Attribute::write_constructor_option_doc, call this method in a subclass that has implemented it.");
}

sub write_default_value {
    throw Error::Simple("ERROR: PerlBean::Attribute::write_default_value, call this method in a subclass that has implemented it.");
}

