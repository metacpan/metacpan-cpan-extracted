package PerlBean::Attribute::Factory;

use 5.005;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Package version
our ( $VERSION ) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Attribute::Factory - factory package to generate C<PerlBean::Attribute> objects

=head1 SYNOPSIS

 use strict;
 use PerlBean::Attribute::Factory;
 my $factory = PerlBean::Attribute::Factory->new();
 my $attr = $factory->create_attribute( {
     type => 'BOOLEAN',
     method_factory_name => 'true',
     short_description => 'something is true',
 } );

=head1 ABSTRACT

C<PerlBean::Attribute> object factory

=head1 DESCRIPTION

C<PerlBean::Attribute::Factory> objects create instances of C<PerlBean::Attribute> objects.

=head1 CONSTRUCTOR

=over

=item new()

Creates a new C<PerlBean::Attribute::Factory> object.

=back

=head1 METHODS

=over

=item create_attribute(OPT_HASH_REF)

Returns C<PerlBean::Attribute> objects based on C<OPT_HASH_REF>. C<OPT_HASH_REF> is a hash reference used to pass initialization options. The selected subclass of C<PerlBean::Attribute> is initialized using C<OPT_HASH_REF>. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> used by this method may include:

=over

=item associative

Boolean flag. States that the returned attribute must be unique, associative C<MULTI>. Defaults to B<0>. Only makes sense if C<type> is B<MULTI> and B<unique> is true.

=item method_key

Boolean flag. States that the returned attribute must be unique, associative C<MULTI>. Defaults to B<0>. Only makes sense if C<type> is B<MULTI> and B<unique> is true.

=item ordered

Boolean flag. States that the returned attribute must be an ordered list. Defaults to B<0>. Only makes sense if C<type> is B<MULTI>.

=item type

If C<type> is B<BOOLEAN> a C<PerlBean::Attribute::Boolean>, on B<SINGLE> a C<PerlBean::Attribute::Single> and on B<MULTI> a C<PerlBean::Attribute::Multi> is returned. Defaults to B<'SINGLE'>. B<NOTE:> B<type> has precedence over B<ordered> and B<unique>.

=item unique

Boolean flag. States that the items in the C<MULTI> attribute must be unique. Defaults to B<0>. Only makes sense if C<type> is B<MULTI>.

=back

Options for C<OPT_HASH_REF> passed to package B<C<PerlBean::Attribute>> may include:

=over

=item B<C<default_value>>

Passed to L<set_default_value()>.

=item B<C<exception_class>>

Passed to L<set_exception_class()>. Defaults to B<'Error::Simple'>.

=item B<C<mandatory>>

Passed to L<set_mandatory()>. Defaults to B<0>.

=item B<C<method_base>>

Passed to L<set_method_base()>.

=item B<C<method_factory_name>>

Passed to L<set_method_factory_name()>. Mandatory option.

=item B<C<perl_bean>>

Passed to L<set_perl_bean()>.

=item B<C<short_description>>

Passed to L<set_short_description()>.

=back

Options for C<OPT_HASH_REF> passed to package B<C<PerlBean::Attribute::Single>> may include:

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

=back

=head1 SEE ALSO

L<PerlBean>,
L<PerlBean::Attribute>,
L<PerlBean::Attribute::Boolean>,
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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Attribute::Factory::_initialize, first argument must be 'HASH' reference.");

    # Return $self
    return($self);
}

sub create_attribute {
    my $self = shift;
    my $opt = shift || {};

    # Switch attribute type
    if ( ! defined($opt->{type} ) || $opt->{type} eq 'SINGLE') {
        require PerlBean::Attribute::Single;
        return( PerlBean::Attribute::Single->new($opt) );
    }
    elsif ( $opt->{type} eq 'BOOLEAN' ) {
        require PerlBean::Attribute::Boolean;
        return( PerlBean::Attribute::Boolean->new($opt) );
    }
    elsif ( $opt->{type} eq 'MULTI' ) {
        if ( $opt->{unique} ) {
            if ( $opt->{ordered} ) {
                require PerlBean::Attribute::Multi::Unique::Ordered;
                return( PerlBean::Attribute::Multi::Unique::Ordered->new($opt) );
            }
            elsif ( $opt->{associative} ) {
                if ( $opt->{method_key} ) {
                    require PerlBean::Attribute::Multi::Unique::Associative::MethodKey;
                    return( PerlBean::Attribute::Multi::Unique::Associative::MethodKey->new($opt) );
                }
                else {
                    require PerlBean::Attribute::Multi::Unique::Associative;
                    return( PerlBean::Attribute::Multi::Unique::Associative->new($opt) );
                }
            }
            else {
                require PerlBean::Attribute::Multi::Unique;
                return( PerlBean::Attribute::Multi::Unique->new($opt) );
            }
        }
        else {
            require PerlBean::Attribute::Multi::Ordered;
            return( PerlBean::Attribute::Multi::Ordered->new($opt) );
        }
    }
    else {
        throw Error::Simple("ERROR: PerlBean::Attribute::Factory::attribute, option 'type' must be one of 'BOOLEAN', 'SINGLE' or 'MULTI' and NOT '$opt->{type}'.");
    }
}

