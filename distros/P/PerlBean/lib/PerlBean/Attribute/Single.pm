package PerlBean::Attribute::Single;

use 5.005;
use base qw( PerlBean::Attribute );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use PerlBean::Method;
use PerlBean::Style qw(:codegen);

# Used by _initialize
our %DEFAULT_VALUE = (
    'allow_empty' => 1,
);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Attribute::Single - contains SINGLE bean attribute information

=head1 SYNOPSIS

 use strict;
 use PerlBean::Attribute::Single;
 my $attr = PerlBean::Attribute::Single->new( {
     method_factory_name => 'name',
     short_description => 'my name',
 } );

=head1 ABSTRACT

SINGLE bean attribute information

=head1 DESCRIPTION

C<PerlBean::Attribute::Single> contains SINGLE bean attribute information. It is a subclass of C<PerlBean::Attribute>. The code and documentation methods are implemented.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<PerlBean::Attribute::Single> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<allow_empty>>

Passed to L<set_allow_empty()>. Defaults to B<1>.

=item B<C<allow_isa>>

Passed to L<set_allow_isa()>. Must be an C<ARRAY> reference.

=item B<C<allow_ref>>

Passed to L<set_allow_ref()>. Must be an C<ARRAY> reference.

=item B<C<allow_rx>>

Passed to L<set_allow_rx()>. Must be an C<ARRAY> reference.

=item B<C<allow_value>>

Passed to L<set_allow_value()>. Must be an C<ARRAY> reference.

=back

Options for C<OPT_HASH_REF> inherited through package B<C<PerlBean::Attribute>> may include:

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

=item add_allow_isa(ARRAY)

Add additional values on the list of allowed classes. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=item add_allow_ref(ARRAY)

Add additional values on the list of allowed references. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=item add_allow_rx(ARRAY)

Add additional values on the list of allow regular expressions. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=item add_allow_value(ARRAY)

Add additional values on allowed values. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=item create_methods()

This method is an implementation from package C<PerlBean::Attribute>. Returns a list of C<PerlBean::Attribute::Method> objects.

=item delete_allow_isa(ARRAY)

Delete elements from the list of allowed classes. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item delete_allow_ref(ARRAY)

Delete elements from the list of allowed references. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item delete_allow_rx(ARRAY)

Delete elements from the list of allow regular expressions. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item delete_allow_value(ARRAY)

Delete elements from allowed values. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item exists_allow_isa(ARRAY)

Returns the count of items in C<ARRAY> that are in the list of allowed classes.

=item exists_allow_ref(ARRAY)

Returns the count of items in C<ARRAY> that are in the list of allowed references.

=item exists_allow_rx(ARRAY)

Returns the count of items in C<ARRAY> that are in the list of allow regular expressions.

=item exists_allow_value(ARRAY)

Returns the count of items in C<ARRAY> that are in allowed values.

=item get_default_value()

This method is inherited from package C<PerlBean::Attribute>. Returns attribute default value.

=item get_exception_class()

This method is inherited from package C<PerlBean::Attribute>. Returns the class to throw when an exception occurs.

=item get_method_base()

This method is inherited from package C<PerlBean::Attribute>. Returns the method base name.

=item get_method_factory_name()

This method is inherited from package C<PerlBean::Method::Factory>. Returns method factory's name.

=item get_package()

This method is inherited from package C<PerlBean::Attribute>. Returns the package name. The package name is obtained from the C<PerlBean> to which the C<PerlBean::Attribute> belongs. Or, if the C<PerlBean::Attribute> does not belong to a C<PerlBean>, C<main> is returned.

=item get_package_us()

This method is inherited from package C<PerlBean::Attribute>. Calls C<get_package()> and replaces C<:+> with C <_>.

=item get_perl_bean()

This method is inherited from package C<PerlBean::Method::Factory>. Returns the PerlBean to which this method factory belongs.

=item get_short_description()

This method is inherited from package C<PerlBean::Attribute>. Returns the attribute description.

=item is_allow_empty()

Returns whether the attribute is allowed to be empty or not.

=item is_documented()

This method is inherited from package C<PerlBean::Attribute>. Returns whether the attribute is documented or not.

=item is_mandatory()

This method is inherited from package C<PerlBean::Attribute>. Returns whether the attribute is mandatory for construction or not.

=item mk_doc_clauses()

This method is overloaded from package C<PerlBean::Attribute>. Returns a string containing the documentation for the clauses to which the contents the contents of the attribute must adhere.

=item set_allow_empty(VALUE)

State that the attribute is allowed to be empty. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_allow_isa(ARRAY)

Set the list of allowed classes absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

=item set_allow_ref(ARRAY)

Set the list of allowed references absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

=item set_allow_rx(ARRAY)

Set the list of allow regular expressions absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

=item set_allow_value(ARRAY)

Set allowed values absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

=item set_default_value(VALUE)

This method is inherited from package C<PerlBean::Attribute>. Set attribute default value. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_documented(VALUE)

This method is inherited from package C<PerlBean::Attribute>. State that the attribute is documented. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_exception_class(VALUE)

This method is inherited from package C<PerlBean::Attribute>. Set the class to throw when an exception occurs. C<VALUE> is the value. Default value at initialization is C<Error::Simple>. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_mandatory(VALUE)

This method is inherited from package C<PerlBean::Attribute>. State that the attribute is mandatory for construction. C<VALUE> is the value. Default value at initialization is C<0>. On error an exception C<Error::Simple> is thrown.

=item set_method_base(VALUE)

This method is inherited from package C<PerlBean::Attribute>. Set the method base name. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

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

This method is inherited from package C<PerlBean::Attribute>. Set the attribute description. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item type()

This method is inherited from package C<PerlBean::Attribute>. Determines and returns the type of the attribute. The type is either C<BOOLEAN>, C<SINGLE> or C<MULTI>.

=item values_allow_isa()

Returns an C<ARRAY> containing all values of the list of allowed classes.

=item values_allow_ref()

Returns an C<ARRAY> containing all values of the list of allowed references.

=item values_allow_rx()

Returns an C<ARRAY> containing all values of the list of allow regular expressions.

=item values_allow_value()

Returns an C<ARRAY> containing all values of allowed values.

=item write_constructor_option_code()

This method is an implementation from package C<PerlBean::Attribute>. Writes constructor code for the attribute option.

=item write_constructor_option_doc()

This method is an implementation from package C<PerlBean::Attribute>. Writes constructor documentation for the attribute option.

=item write_default_value()

This method is an implementation from package C<PerlBean::Attribute>. Returns a C<%DEFAULT_VALUE> line string for the attribute.

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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Attribute::Single::_initialize, first argument must be 'HASH' reference.");

    # allow_empty, BOOLEAN, with default value
    $self->set_allow_empty( exists( $opt->{allow_empty} ) ? $opt->{allow_empty} : $DEFAULT_VALUE{allow_empty} );

    # allow_isa, MULTI
    if ( exists( $opt->{allow_isa} ) ) {
        ref( $opt->{allow_isa} ) eq 'ARRAY' || throw Error::Simple("ERROR: PerlBean::Attribute::Single::_initialize, specified value for option 'allow_isa' must be an 'ARRAY' reference.");
        $self->set_allow_isa( @{ $opt->{allow_isa} } );
    }
    else {
        $self->set_allow_isa();
    }

    # allow_ref, MULTI
    if ( exists( $opt->{allow_ref} ) ) {
        ref( $opt->{allow_ref} ) eq 'ARRAY' || throw Error::Simple("ERROR: PerlBean::Attribute::Single::_initialize, specified value for option 'allow_ref' must be an 'ARRAY' reference.");
        $self->set_allow_ref( @{ $opt->{allow_ref} } );
    }
    else {
        $self->set_allow_ref();
    }

    # allow_rx, MULTI
    if ( exists( $opt->{allow_rx} ) ) {
        ref( $opt->{allow_rx} ) eq 'ARRAY' || throw Error::Simple("ERROR: PerlBean::Attribute::Single::_initialize, specified value for option 'allow_rx' must be an 'ARRAY' reference.");
        $self->set_allow_rx( @{ $opt->{allow_rx} } );
    }
    else {
        $self->set_allow_rx();
    }

    # allow_value, MULTI
    if ( exists( $opt->{allow_value} ) ) {
        ref( $opt->{allow_value} ) eq 'ARRAY' || throw Error::Simple("ERROR: PerlBean::Attribute::Single::_initialize, specified value for option 'allow_value' must be an 'ARRAY' reference.");
        $self->set_allow_value( @{ $opt->{allow_value} } );
    }
    else {
        $self->set_allow_value();
    }

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub add_allow_isa {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'allow_isa', @_ ) || throw Error::Simple("ERROR: PerlBean::Attribute::Single::add_allow_isa, one or more specified value(s) '@_' is/are not allowed.");

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Attribute_Single}{allow_isa}{$val} = $val;
    }
}

sub add_allow_ref {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'allow_ref', @_ ) || throw Error::Simple("ERROR: PerlBean::Attribute::Single::add_allow_ref, one or more specified value(s) '@_' is/are not allowed.");

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Attribute_Single}{allow_ref}{$val} = $val;
    }
}

sub add_allow_rx {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'allow_rx', @_ ) || throw Error::Simple("ERROR: PerlBean::Attribute::Single::add_allow_rx, one or more specified value(s) '@_' is/are not allowed.");

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Attribute_Single}{allow_rx}{$val} = $val;
    }
}

sub add_allow_value {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'allow_value', @_ ) || throw Error::Simple("ERROR: PerlBean::Attribute::Single::add_allow_value, one or more specified value(s) '@_' is/are not allowed.");

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Attribute_Single}{allow_value}{$val} = $val;
    }
}

sub create_method_get {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('get');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Returns ${desc}.
EOF
        body => <<EOF,
${IND}my \$self${AO}=${AO}shift;

${IND}return${BFP}(${ACS}\$self->{$pkg_us}{$an}${ACS});
EOF
    } ) );
}

sub create_method_set {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_aq($an);
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();

    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $def = defined( $self->get_default_value() ) ? ' Default value at initialization is C<' . $self->get_default_value() . '>.' : '';
    my $empt = $self->is_allow_empty() ? '' : ' C<VALUE> may not be C<undef>.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';
    my $attr_overl = $self->_get_overloaded_attribute();
    my $overl = defined($attr_overl) ? " B<NOTE:> Methods B<C<*$mb ()>> are overloaded from package C<". $attr_overl->get_package() .'>.': '';


    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;
${IND}my \$val${AO}=${AO}shift;

EOF

    # Check if value is allowed to be empty
    if ( ! $self->is_allow_empty() ) {
        $body .= <<EOF;
${IND}# Value for $an_esc is not allowed to be empty
${IND}defined${BFP}(\$val)${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, value may not be empty.");

EOF
    }

    # Check if isa/ref/rx/value is allowed
    $body .= <<EOF;
${IND}# Check if isa/ref/rx/value is allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\$val${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, the specified value '\$val' is not allowed.");

EOF

    # Assignment and method tail
    $body .= <<EOF;
${IND}# Assignment
${IND}\$self->{$pkg_us}{$an}${AO}=${AO}\$val;
EOF

    # Make description
    my $description = <<EOF;
Set ${desc}. C<VALUE> is the value.${def}${empt}${exc}${overl}
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'VALUE',
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
    } ) );
}

sub create_methods {
    my $self = shift;

    return(
        $self->create_method_get(),
        $self->create_method_set()
    );
}

sub delete_allow_isa {
    my $self = shift;

    # Delete values
    my $del = 0;
    foreach my $val (@_) {
        exists( $self->{PerlBean_Attribute_Single}{allow_isa}{$val} ) || next;
        delete( $self->{PerlBean_Attribute_Single}{allow_isa}{$val} );
        $del ++;
    }
    return($del);
}

sub delete_allow_ref {
    my $self = shift;

    # Delete values
    my $del = 0;
    foreach my $val (@_) {
        exists( $self->{PerlBean_Attribute_Single}{allow_ref}{$val} ) || next;
        delete( $self->{PerlBean_Attribute_Single}{allow_ref}{$val} );
        $del ++;
    }
    return($del);
}

sub delete_allow_rx {
    my $self = shift;

    # Delete values
    my $del = 0;
    foreach my $val (@_) {
        exists( $self->{PerlBean_Attribute_Single}{allow_rx}{$val} ) || next;
        delete( $self->{PerlBean_Attribute_Single}{allow_rx}{$val} );
        $del ++;
    }
    return($del);
}

sub delete_allow_value {
    my $self = shift;

    # Delete values
    my $del = 0;
    foreach my $val (@_) {
        exists( $self->{PerlBean_Attribute_Single}{allow_value}{$val} ) || next;
        delete( $self->{PerlBean_Attribute_Single}{allow_value}{$val} );
        $del ++;
    }
    return($del);
}

sub exists_allow_isa {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val (@_) {
        $count += exists( $self->{PerlBean_Attribute_Single}{allow_isa}{$val} );
    }
    return($count);
}

sub exists_allow_ref {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val (@_) {
        $count += exists( $self->{PerlBean_Attribute_Single}{allow_ref}{$val} );
    }
    return($count);
}

sub exists_allow_rx {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val (@_) {
        $count += exists( $self->{PerlBean_Attribute_Single}{allow_rx}{$val} );
    }
    return($count);
}

sub exists_allow_value {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val (@_) {
        $count += exists( $self->{PerlBean_Attribute_Single}{allow_value}{$val} );
    }
    return($count);
}

sub is_allow_empty {
    my $self = shift;

    if ( $self->{PerlBean_Attribute_Single}{allow_empty} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub mk_doc_clauses {
    my $self = shift;

    # Return empty if no clauses at all
    return('') if ( ! scalar( $self->values_allow_isa() ) &&
        ! scalar( $self->values_allow_ref() ) &&
        ! scalar( $self->values_allow_rx() ) &&
        ! scalar( $self->values_allow_value() )
    );

    # Make the clauses head for documentation
    my $doc = <<EOF;
\=over

EOF

    # Make body
    $doc .= $self->mk_doc_clauses_allow_isa(@_);
    $doc .= $self->mk_doc_clauses_allow_ref(@_);
    $doc .= $self->mk_doc_clauses_allow_rx(@_);
    $doc .= $self->mk_doc_clauses_allow_value(@_);

    # Make tail
    $doc .= <<EOF;
\=back
EOF

    # Return the clauses for documentation
    return($doc);
}

sub mk_doc_clauses_allow_isa {
    my $self = shift;

    # Return empty string if no values_allow_isa
    return('') if ( ! scalar( $self->values_allow_isa() ) );

    # Make clauses head
    my $clauses = <<EOF;
\=item VALUE must be a (sub)class of:

\=over

EOF

    # Make clauses body
    foreach my $class ( sort( $self->values_allow_isa() ) ) {
        $clauses .= <<EOF;
\=item ${class}

EOF
    }

    # Make clauses tail
    $clauses .= <<EOF;
\=back

EOF

    # Return clauses
    return($clauses);
}

sub mk_doc_clauses_allow_ref {
    my $self = shift;

    # Return empty string if no values_allow_ref
    return('') if ( ! scalar( $self->values_allow_ref() ) );

    # Make $or for other clauses that apply and that are written before these
    # clauses
    my $or = scalar( $self->values_allow_isa() ) ? 'Or, ' : '';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or}VALUE must be a reference of:

\=over

EOF

    # Make clauses body
    foreach my $class ( sort( $self->values_allow_ref() ) ) {
        $clauses .= <<EOF;
\=item ${class}

EOF
    }

    # Make clauses tail
    $clauses .= <<EOF;
\=back

EOF

    # Return clauses
    return($clauses);
}

sub mk_doc_clauses_allow_rx {
    my $self = shift;

    # Return empty string if no values_allow_rx
    return('') if ( ! scalar( $self->values_allow_rx() ) );

    # Make $or for other clauses that apply and that are written before these
    # clauses
    my $or = scalar( $self->values_allow_isa() || $self->values_allow_ref() ) ?
        'Or, ' : '';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or}VALUE must match regular expression:

\=over

EOF

    # Make clauses body
    foreach my $class ( sort( $self->values_allow_rx() ) ) {
        $clauses .= <<EOF;
\=item ${class}

EOF
    }

    # Make clauses tail
    $clauses .= <<EOF;
\=back

EOF

    # Return clauses
    return($clauses);
}

sub mk_doc_clauses_allow_value {
    my $self = shift;

    # Return empty string if no values_allow_value
    return('') if ( ! scalar( $self->values_allow_value() ) );

    # Make $or for other clauses that apply and that are written before these
    # clauses
    my $or = scalar( $self->values_allow_isa() || $self->values_allow_ref() ||
        $self->values_allow_rx() ) ? 'Or, ' : '';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or}VALUE must be a one of:

\=over

EOF

    # Make clauses body
    foreach my $val ( sort( $self->values_allow_value() ) ) {
        $clauses .= <<EOF;
\=item ${val}

EOF
    }

    # Make clauses tail
    $clauses .= <<EOF;
\=back

EOF

    # Return clauses
    return($clauses);
}

sub set_allow_empty {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Attribute_Single}{allow_empty} = 1;
    }
    else {
        $self->{PerlBean_Attribute_Single}{allow_empty} = 0;
    }
}

sub set_allow_isa {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'allow_isa', @_ ) || throw Error::Simple("ERROR: PerlBean::Attribute::Single::set_allow_isa, one or more specified value(s) '@_' is/are not allowed.");

    # Empty list
    $self->{PerlBean_Attribute_Single}{allow_isa} = {};

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Attribute_Single}{allow_isa}{$val} = $val;
    }
}

sub set_allow_ref {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'allow_ref', @_ ) || throw Error::Simple("ERROR: PerlBean::Attribute::Single::set_allow_ref, one or more specified value(s) '@_' is/are not allowed.");

    # Empty list
    $self->{PerlBean_Attribute_Single}{allow_ref} = {};

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Attribute_Single}{allow_ref}{$val} = $val;
    }
}

sub set_allow_rx {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'allow_rx', @_ ) || throw Error::Simple("ERROR: PerlBean::Attribute::Single::set_allow_rx, one or more specified value(s) '@_' is/are not allowed.");

    # Empty list
    $self->{PerlBean_Attribute_Single}{allow_rx} = {};

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Attribute_Single}{allow_rx}{$val} = $val;
    }
}

sub set_allow_value {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'allow_value', @_ ) || throw Error::Simple("ERROR: PerlBean::Attribute::Single::set_allow_value, one or more specified value(s) '@_' is/are not allowed.");

    # Empty list
    $self->{PerlBean_Attribute_Single}{allow_value} = {};

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Attribute_Single}{allow_value}{$val} = $val;
    }
}

sub values_allow_isa {
    my $self = shift;

    # Return all values
    return( values( %{ $self->{PerlBean_Attribute_Single}{allow_isa} } ) );
}

sub values_allow_ref {
    my $self = shift;

    # Return all values
    return( values( %{ $self->{PerlBean_Attribute_Single}{allow_ref} } ) );
}

sub values_allow_rx {
    my $self = shift;

    # Return all values
    return( values( %{ $self->{PerlBean_Attribute_Single}{allow_rx} } ) );
}

sub values_allow_value {
    my $self = shift;

    # Return all values
    return( values( %{ $self->{PerlBean_Attribute_Single}{allow_value} } ) );
}

sub write_allow_isa {
    my $self = shift;

    scalar( $self->values_allow_isa() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->_esc_aq( sort( $self->values_allow_isa() ) );
    return( "${IND}$an${AO}=>${AO}\[${ACS}$dv${ACS}],\n" );
}

sub write_allow_ref {
    my $self = shift;

    scalar( $self->values_allow_ref() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my @dv = sort( $self->_esc_aq( $self->values_allow_ref() ) );

    my $ass = "${IND}$an${AO}=>${AO}\{\n";
    foreach my $dv (@dv) {
        $ass .= "${IND}${IND}$dv${AO}=>${AO}1,\n";
    }
    $ass .= "${IND}},\n";

    return($ass);
}

sub write_allow_rx {
    my $self = shift;

    scalar( $self->values_allow_rx() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->_esc_aq( sort( $self->values_allow_rx() ) );
    return( "${IND}$an${AO}=>${AO}\[${ACS}$dv${ACS}],\n" );
}

sub write_allow_value {
    my $self = shift;
    my $fh = shift;

    scalar( $self->values_allow_value() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my @dv = sort( $self->_esc_aq( $self->values_allow_value() ) );

    my $ass = "${IND}$an${AO}=>${AO}\{\n";
    foreach my $dv (@dv) {
        $ass .= "${IND}${IND}$dv${AO}=>${AO}1,\n";
    }
    $ass .= "${IND}},\n";
}

sub write_constructor_option_code {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();

    # Comment
    my $code = "${IND}# $an, " . $self->type();
    $code .= $self->is_mandatory() ? ', mandatory' : '';
    $code .= defined( $self->get_default_value() ) ? ', with default value' : '';
    $code .= "\n";

    # is_mandatory check
    if ( $self->is_mandatory() ) {
        $code .= <<EOF;
${IND}exists${BFP}(${ACS}\$opt->{$an}${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::_initialize, option '$an' is mandatory.");
EOF
    }

    if ( $self->is_mandatory() ) {
        $code .= <<EOF;
${IND}\$self->$op$mb${BFP}(${ACS}\$opt->{$an}${ACS});
EOF
    }
    else {
        if ( defined( $self->get_default_value() ) ) {
            $code .= <<EOF;
${IND}\$self->$op$mb${BFP}(${ACS}exists${BFP}(${ACS}\$opt->{$an}${ACS})${AO}?${AO}\$opt->{$an}${AO}:${AO}\$DEFAULT_VALUE{$an}${ACS});
EOF
        }
        else {
            $code .= <<EOF;
${IND}exists${BFP}(${ACS}\$opt->{$an}${ACS})${AO}&&${AO}\$self->$op$mb${BFP}(${ACS}\$opt->{$an}${ACS});
EOF
        }
    }

    # Empty line
    $code .= "\n";

    return($code);
}

sub write_constructor_option_doc {
    my $self = shift;

    # Do nothing if not documented
    $self->is_documented() || return('');

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $mand = $self->is_mandatory() ? ' Mandatory option.' : '';
    my $def = '';
    if ( defined( $self->get_default_value() ) ) {
        $def = ' Defaults to B<' . $self->_esc_aq( $self->get_default_value() ) . '>.';
    }

    return(<<EOF);

\=item B<C<$an>>

Passed to L<$op$mb${BFP}()>.${mand}${def}
EOF
}

sub write_default_value {
    my $self = shift;
    my $fh = shift;

    defined( $self->get_default_value() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->_esc_aq( $self->get_default_value() );

    return( "${IND}$an${AO}=>${AO}$dv,\n" );
}

