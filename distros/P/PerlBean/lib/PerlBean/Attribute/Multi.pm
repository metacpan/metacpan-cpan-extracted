package PerlBean::Attribute::Multi;

use 5.005;
use base qw( PerlBean::Attribute::Single );
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

PerlBean::Attribute::Multi - contains MULTI bean attribute information

=head1 SYNOPSIS

None. This is an abstract class.

=head1 ABSTRACT

MULTI bean attribute abstraction

=head1 DESCRIPTION

C<PerlBean::Attribute::Multi> is a subclass of C<PerlBean::Attribute> and it's only function is to group the MULTI attribute classes.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<PerlBean::Attribute::Multi> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

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

This is an interface method. Returns a list of C<PerlBean::Attribute::Method> objects.

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

This method is overloaded from package C<PerlBean::Attribute::Single>. Writes constructor code for the attribute option.

=item write_constructor_option_doc()

This method is overloaded from package C<PerlBean::Attribute::Single>. Writes constructor documentation for the attribute option.

=item write_default_value()

This method is overloaded from package C<PerlBean::Attribute::Single>. Returns a C<%DEFAULT_VALUE> line string for the attribute.

=back

=head1 SEE ALSO

L<PerlBean>,
L<PerlBean::Attribute>,
L<PerlBean::Attribute::Boolean>,
L<PerlBean::Attribute::Factory>,
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

sub create_methods {
    throw Error::Simple("ERROR: PerlBean::Attribute::Multi::create_methods, call this method in a subclass that has implemented it.");
}

sub mk_doc_clauses_allow_isa {
    my $self = shift;

    # Return empty string if no values_allow_isa
    return('') if ( ! scalar( $self->values_allow_isa() ) );

    # Make clauses head
    my $clauses = <<EOF;
\=item The values in C<ARRAY> must be a (sub)class of:

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
    my $or = scalar( $self->values_allow_isa() ) ? 'Or, the' : 'The';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or} values in C<ARRAY> must be a reference of:

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
        'Or, the' : 'The';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or} values in C<ARRAY> must match regular expression:

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
        $self->values_allow_rx() ) ? 'Or, the' : 'The';

    # Make clauses head
    my $clauses = <<EOF;
\=item ${or} values in C<ARRAY> must be a one of:

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

sub write_constructor_option_code {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $mb = $self->get_method_base();
    my $ec = $self->get_exception_class();
    my $pkg = $self->get_perl_bean()->get_package();

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

    my $pre = '';
    if ( ! $self->is_mandatory() ) {
        $pre .= "${IND}";
        $code .= <<EOF;
${IND}if${BCP}(${ACS}exists${BFP}(${ACS}\$opt->{$an}${ACS})${ACS})${PBOC[1]}{
EOF
    }
    $code .= <<EOF;
${IND}${pre}ref${BFP}(${ACS}\$opt->{$an}${ACS})${AO}eq${AO}'ARRAY'${AO}||${AO}throw $ec${BFP}("ERROR: ${pkg}::_initialize, specified value for option '$an' must be an 'ARRAY' reference.");
${IND}${pre}\$self->set$mb${BFP}(${ACS}\@{${ACS}\$opt->{$an}${ACS}}${ACS});
EOF
    # default value
    if ( ! $self->is_mandatory() ) {
        if ( defined( $self->get_default_value() ) ) {
            $code .= <<EOF;
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}\$self->set$mb${BFP}(${ACS}\@{${ACS}\$DEFAULT_VALUE{$an}${ACS}}${ACS});
EOF
        }
        else {
            $code .= <<EOF;
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}\$self->set$mb${BFP}();
EOF
            }
        }
    if ( ! $self->is_mandatory()) {
        $code .= <<EOF;
${IND}}
EOF
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
    my $mb = $self->get_method_base();
    my $mand = $self->is_mandatory() ? ' Mandatory option.' : '';
    my $multi = ( $self->isa('PerlBean::Attribute::Multi') ) ? ' Must be an C<ARRAY> reference.' : '';
    my $def = '';
    if ( defined( $self->get_default_value() ) ) {
        my $list = join( '> , B<', $self->_esc_aq( @{ $self->get_default_value() } ) );
        $def = ' Defaults to B<[> B<' . $list . '> B<]>.';
    }

    return(<<EOF);

\=item B<C<$an>>

Passed to L<set$mb${BFP}()>.${multi}${mand}${def}
EOF
}

sub write_default_value {
    my $self = shift;

    defined( $self->get_default_value() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->_esc_aq( @{ $self->get_default_value() } );

    return( "${IND}$an${AO}=>${AO}\[$dv],\n" );
}

