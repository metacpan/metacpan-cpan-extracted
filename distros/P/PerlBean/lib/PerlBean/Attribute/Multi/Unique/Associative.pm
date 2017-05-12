package PerlBean::Attribute::Multi::Unique::Associative;

use 5.005;
use base qw( PerlBean::Attribute::Multi );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use PerlBean::Style qw(:codegen);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Attribute::Multi::Unique::Associative - contains unique associative MULTI bean attribute information

=head1 SYNOPSIS

 use strict;
 use PerlBean::Attribute::Multi::Unique::Associative;
 my $attr = PerlBean::Attribute::Multi::Unique::Associative->new( {
     method_factory_name => 'ssns_i_know_from_people',
     short_description => 'all SSNs I know from people',
 } );

=head1 ABSTRACT

Unique, associative MULTI bean attribute information

=head1 DESCRIPTION

C<PerlBean::Attribute::Multi::Unique::Associative> contains unique associative MULTI bean attribute information. It is a subclass of C<PerlBean::Attribute::Multi>. The code generation and documentation methods from C<PerlBean::Attribute> are implemented.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<PerlBean::Attribute::Multi::Unique::Associative> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

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

Options for C<OPT_HASH_REF> inherited through package B<C<PerlBean::Attribute::Single>> may include:

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

This method is inherited from package C<PerlBean::Attribute::Single>. Add additional values on the list of allowed classes. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=item add_allow_ref(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Add additional values on the list of allowed references. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=item add_allow_rx(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Add additional values on the list of allow regular expressions. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=item add_allow_value(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Add additional values on allowed values. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=item create_methods()

This method is an implementation from package C<PerlBean::Attribute::Multi>. Returns a list of C<PerlBean::Attribute::Method> objects. Access methods are B<set...>, B<add...>, B<delete...>, B<exists...>, B<keys...> and B<values...>.',

=item delete_allow_isa(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Delete elements from the list of allowed classes. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item delete_allow_ref(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Delete elements from the list of allowed references. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item delete_allow_rx(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Delete elements from the list of allow regular expressions. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item delete_allow_value(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Delete elements from allowed values. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item exists_allow_isa(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Returns the count of items in C<ARRAY> that are in the list of allowed classes.

=item exists_allow_ref(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Returns the count of items in C<ARRAY> that are in the list of allowed references.

=item exists_allow_rx(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Returns the count of items in C<ARRAY> that are in the list of allow regular expressions.

=item exists_allow_value(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Returns the count of items in C<ARRAY> that are in allowed values.

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

This method is inherited from package C<PerlBean::Attribute::Single>. Returns whether the attribute is allowed to be empty or not.

=item is_documented()

This method is inherited from package C<PerlBean::Attribute>. Returns whether the attribute is documented or not.

=item is_mandatory()

This method is inherited from package C<PerlBean::Attribute>. Returns whether the attribute is mandatory for construction or not.

=item mk_doc_clauses()

This method is inherited from package C<PerlBean::Attribute::Single>. Returns a string containing the documentation for the clauses to which the contents the contents of the attribute must adhere.

=item set_allow_empty(VALUE)

This method is inherited from package C<PerlBean::Attribute::Single>. State that the attribute is allowed to be empty. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_allow_isa(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Set the list of allowed classes absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

=item set_allow_ref(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Set the list of allowed references absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

=item set_allow_rx(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Set the list of allow regular expressions absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

=item set_allow_value(ARRAY)

This method is inherited from package C<PerlBean::Attribute::Single>. Set allowed values absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

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

This method is inherited from package C<PerlBean::Attribute::Single>. Returns an C<ARRAY> containing all values of the list of allowed classes.

=item values_allow_ref()

This method is inherited from package C<PerlBean::Attribute::Single>. Returns an C<ARRAY> containing all values of the list of allowed references.

=item values_allow_rx()

This method is inherited from package C<PerlBean::Attribute::Single>. Returns an C<ARRAY> containing all values of the list of allow regular expressions.

=item values_allow_value()

This method is inherited from package C<PerlBean::Attribute::Single>. Returns an C<ARRAY> containing all values of allowed values.

=item write_constructor_option_code()

This method is inherited from package C<PerlBean::Attribute::Multi>. Writes constructor code for the attribute option.

=item write_constructor_option_doc()

This method is inherited from package C<PerlBean::Attribute::Multi>. Writes constructor documentation for the attribute option.

=item write_default_value()

This method is inherited from package C<PerlBean::Attribute::Multi>. Returns a C<%DEFAULT_VALUE> line string for the attribute.

=back

=head1 SEE ALSO

L<PerlBean>,
L<PerlBean::Attribute>,
L<PerlBean::Attribute::Boolean>,
L<PerlBean::Attribute::Factory>,
L<PerlBean::Attribute::Multi>,
L<PerlBean::Attribute::Multi::Ordered>,
L<PerlBean::Attribute::Multi::Unique>,
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

sub create_method_add {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_apos($an);
    my $op = &{$MOF}('add');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Separate keys/values
    $body .= <<EOF;
${IND}# Separate keys/values
${IND}my \@key${AO}=${AO}();
${IND}my \@value${AO}=${AO}();
${IND}while${BCP}(${ACS}my \$key${AO}=${AO}shift${BFP}(\@_)${ACS})${PBOC[1]}{
${IND}${IND}push${BFP}(${ACS}\@key,${AC}\$key${ACS});
${IND}${IND}push${BFP}(${ACS}\@value,${AC}shift${BFP}(\@_)${ACS});
${IND}}

EOF

    # Check if isas/refs/rxs/values are allowed
    $body .= <<EOF;
${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\@value${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@value' is/are not allowed.");

EOF

    # Method tail
    $body .= <<EOF;
${IND}# Add keys/values
${IND}foreach my \$key (\@key)${PBOC[1]}{
${IND}${IND}\$self->{$pkg_us}{$an}{\$key}${AO}=${AO}shift${BFP}(\@value);
${IND}}
EOF

    # Make description
    my $description = <<EOF;
Add additional keys/values on ${desc}. C<KEY, VALUE> are key/value pairs. The addition may not yield to multiple identical keys in the list. Hence, multiple occurrences of the same key cause the last occurrence to be inserted.${exc}
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => "${ACS}\[${ACS}KEY, VALUE ...${ACS}]${ACS}",
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
    } ) );
}

sub create_method_delete {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_apos($an);
    my $op = &{$MOF}('delete');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $empt = $self->is_allow_empty() ? '' : ' After deleting at least one element must remain.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Check if list value is allowed to be empty
    if ( ! $self->is_allow_empty() ) {
        $body .= <<EOF;
${IND}# List value for $an_esc is not allowed to be empty
${IND}my \%would_delete${AO}=${AO}();
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}\$would_delete{\$val}${AO}=${AO}\$val if${BCP}(${ACS}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$val}${ACS})${ACS})
${IND}}
${IND}(${ACS}scalar${BFP}(${ACS}keys${BFP}(${ACS}\%{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS})${ACS})${AO}==${AO}scalar${BFP}(${ACS}keys${BFP}(${ACS}\%would_delete)${ACS})${ACS})${AO}&&${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, list value may not be empty.");

EOF
    }

    # Method tail
    $body .= <<EOF;
${IND}# Delete values
${IND}my \$del${AO}=${AO}0;
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$val}${ACS})${AO}||${AO}next;
${IND}${IND}delete${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$val}${ACS});
${IND}${IND}\$del${AO}++;
${IND}}
${IND}return${BFP}(\$del);
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'ARRAY',
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Delete elements from ${desc}.${empt} Returns the number of deleted elements.${exc}
EOF
        body => $body,
    } ) );
}

sub create_method_exists {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('exists');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

${IND}# Count occurrences
${IND}my \$count${AO}=${AO}0;
${IND}foreach my \$val (\@_)${PBOC[1]}{
${IND}${IND}\$count${AO}+=${AO}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$val}${ACS});
${IND}}
${IND}return${BFP}(\$count);
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'ARRAY',
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Returns the count of items in C<ARRAY> that are in ${desc}.
EOF
        body => $body,
    } ) );
}

sub create_method_keys {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('keys');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

${IND}# Return all keys
${IND}return${BFP}(${ACS}keys${BFP}(${ACS}\%{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS})${ACS});
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Returns an C<ARRAY> containing the keys of ${desc}.
EOF
        body => $body,
    } ) );
}

sub create_method_set {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $an_esc = $self->_esc_apos($an);
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_package();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';
    my $def = defined( $self->get_default_value() ) ? ' Default value at initialization is C<' . join( ', ', $self->_esc_aq ( @{ $self->get_default_value() } ) ) . '>.' : '';
    my $empt = $self->is_allow_empty() ? '' : ' C<ARRAY> must at least have one element.';
    my $exc = ' On error an exception C<' . $self->get_exception_class() . '> is thrown.';
    my $attr_overl = $self->_get_overloaded_attribute();
    my $overl = defined($attr_overl) ? " B<NOTE:> Methods B<C<*$mb ()>> are overloaded from package C<". $attr_overl->get_package() .'>.': '';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

EOF

    # Check if list value is allowed to be empty
    if ( ! $self->is_allow_empty() ) {
        $body .= <<EOF;
${IND}# List value for $an_esc is not allowed to be empty
${IND}scalar${BFP}(\@_)${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, list value may not be empty.");

EOF
    }

    # Separate keys/values
    $body .= <<EOF;
${IND}# Separate keys/values
${IND}my \@key${AO}=${AO}();
${IND}my \@value${AO}=${AO}();
${IND}while${BCP}(${ACS}my \$key${AO}=${AO}shift${BFP}(\@_)${ACS})${PBOC[1]}{
${IND}${IND}push${BFP}(${ACS}\@key,${AC}\$key${ACS});
${IND}${IND}push${BFP}(${ACS}\@value,${AC}shift${BFP}(\@_)${ACS});
${IND}}

EOF

    # Check if isas/refs/rxs/values are allowed
    $body .= <<EOF;
${IND}# Check if isas/refs/rxs/values are allowed
${IND}\&_value_is_allowed${BFP}(${ACS}$an_esc,${AC}\@value${ACS})${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::$op$mb, one or more specified value(s) '\@value' is/are not allowed.");

EOF

    # Method tail
    $body .= <<EOF;
${IND}# Empty list
${IND}\$self->{$pkg_us}{$an}${AO}=${AO}\{};

${IND}# Add keys/values
${IND}foreach my \$key (\@key)${PBOC[1]}{
${IND}${IND}\$self->{$pkg_us}{$an}{\$key}${AO}=${AO}shift${BFP}(\@value);
${IND}}
EOF

    # Make description
    my $description = <<EOF;
Set ${desc} absolutely using keys/values. C<KEY, VALUE> are key/value pairs. 0 or more of these pairs may be supplied. Each key in is allowed to occur only once. Multiple occurrences of the same key yield in the last occurring key to be inserted and the rest to be ignored.${def}${empt}${exc}${overl}
EOF

    # Add clauses to the description
    my $clauses = $self->mk_doc_clauses();
    if ($clauses) {
        $description .= "\n" . $clauses;
    }

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => "${ACS}\[${ACS}KEY, VALUE ...${ACS}]${ACS}",
        documented => $self->is_documented(),
        volatile => 1,
        description => $description,
        body => $body,
    } ) );
}

sub create_method_values {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('values');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    # Make body
    my $body = <<EOF;
${IND}my \$self${AO}=${AO}shift;

${IND}if${BCP}(${ACS}scalar${BFP}(\@_)${ACS})${PBOC[1]}{
${IND}${IND}my \@ret${AO}=${AO}();
${IND}${IND}foreach my \$key (\@_)${PBOC[2]}{
${IND}${IND}${IND}exists${BFP}(${ACS}\$self->{$pkg_us}{$an}{\$key}${ACS})${AO}&&${AO}push${BFP}(${ACS}\@ret,${AC}\$self->{$pkg_us}{$an}{\$key}${ACS});
${IND}${IND}}
${IND}${IND}return${BFP}(\@ret);
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}# Return all values
${IND}${IND}return${BFP}(${ACS}values${BFP}(${ACS}\%{${ACS}\$self->{$pkg_us}{$an}${ACS}}${ACS})${ACS});
${IND}}
EOF

    # Create and return the method
    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => "${ACS}\[${ACS}KEY_ARRAY${ACS}]${ACS}",
        documented => $self->is_documented(),
        volatile => 1,
        description => <<EOF,
Returns an C<ARRAY> containing the values of ${desc}. If C<KEY_ARRAY> contains one or more C<KEY>s the values related to the C<KEY>s are returned. If no C<KEY>s specified all values are returned.
EOF
        body => $body,
    } ) );
}

sub create_methods {
    my $self = shift;

    return(
        $self->create_method_add(),
        $self->create_method_delete(),
        $self->create_method_exists(),
        $self->create_method_keys(),
        $self->create_method_set(),
        $self->create_method_values(),
    );
}

