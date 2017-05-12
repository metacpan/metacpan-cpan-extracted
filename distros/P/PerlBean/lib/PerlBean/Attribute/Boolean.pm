package PerlBean::Attribute::Boolean;

use 5.005;
use base qw( PerlBean::Attribute );
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

PerlBean::Attribute::Boolean - contains BOOLEAN bean attribute information

=head1 SYNOPSIS

 use strict;
 use PerlBean::Attribute::Boolean;
 my $attr = PerlBean::Attribute::Boolean->new( {
     method_factory_name => 'true',
     short_description => 'something is true',
 } );

=head1 ABSTRACT

BOOLEAN bean attribute information

=head1 DESCRIPTION

C<PerlBean::Attribute::Boolean> contains BOOLEAN bean attribute information. It is a subclass of C<PerlBean::Attribute>. The code generation and documentation methods are implemented.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<PerlBean::Attribute::Boolean> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

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

=item create_methods()

This method is an implementation from package C<PerlBean::Attribute>. Returns a list of C<PerlBean::Attribute::Method> objects.

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

=item is_documented()

This method is inherited from package C<PerlBean::Attribute>. Returns whether the attribute is documented or not.

=item is_mandatory()

This method is inherited from package C<PerlBean::Attribute>. Returns whether the attribute is mandatory for construction or not.

=item mk_doc_clauses()

This method is overloaded from package C<PerlBean::Attribute>. Returns a string containing the documentation for the clauses to which the contents the contents of the attribute must adhere.

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

sub create_method_is {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('is');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ? $self->get_short_description() : 'not described option';

    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        volatile => 1,
        documented => $self->is_documented(),
        description => <<EOF,
Returns whether ${desc} or not.
EOF
        body => <<EOF,
${IND}my \$self${AO}=${AO}shift;

${IND}if${BCP}(${ACS}\$self->{$pkg_us}{$an}${ACS})${PBOC[1]}{
${IND}${IND}return${BFP}(1);
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}return${BFP}(0);
${IND}}
EOF
    } ) );
}

sub create_method_set {
    my $self = shift;

    my $an = $self->get_method_factory_name();
    my $op = &{$MOF}('set');
    my $mb = $self->get_method_base();
    my $pkg_us = $self->get_package_us();
    my $desc = defined( $self->get_short_description() ) ?
        $self->get_short_description() : 'not described option';
    my $def = defined( $self->get_default_value() ) ?
        ' Default value at initialization is C<' .
            $self->_esc_aq( $self->get_default_value() ) . '>.' :
        '';
    my $exc = ' On error an exception C<' . $self->get_exception_class() .
        '> is thrown.';
    my $attr_overl = $self->_get_overloaded_attribute();
    my $overl = defined($attr_overl) ?
        " B<NOTE:> Methods B<C<*$mb ()>> are overloaded from package C<" .
            $attr_overl->get_perl_bean()->get_package() .'>.' :
        '';

    return( PerlBean::Method->new( {
        method_name => "$op$mb",
        parameter_description => 'VALUE',
        volatile => 1,
        documented => $self->is_documented(),
        description => <<EOF,
State that $desc. C<VALUE> is the value.$def$exc$overl
EOF
        body => <<EOF,
${IND}my \$self${AO}=${AO}shift;

${IND}if${BCP}(shift)${PBOC[1]}{
${IND}${IND}\$self->{$pkg_us}{$an}${AO}=${AO}1;
${IND}}${PBCC[1]}else${PBOC[1]}{
${IND}${IND}\$self->{$pkg_us}{$an}${AO}=${AO}0;
${IND}}
EOF
    } ) );
}

sub create_methods {
    my $self = shift;

    return(
        $self->create_method_is(),
        $self->create_method_set()
    );
}

sub mk_doc_clauses {
    return('');
}

sub write_allow_isa {
    return('');
}

sub write_allow_ref {
    return('');
}

sub write_allow_rx {
    return('');
}

sub write_allow_value {
    return('');
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
    if ($self->is_mandatory()) {
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
        if ( defined( $self->get_default_value () ) ) {
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

    defined( $self->get_default_value() ) || return('');

    my $an = $self->_esc_aq( $self->get_method_factory_name() );
    my $dv = $self->get_default_value() ? 1 : 0;

    return( "${IND}$an${AO}=>${AO}$dv,\n" );
}

