package PerlBean::Dependency::Use;

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

PerlBean::Dependency::Use - Use dependency in a Perl bean

=head1 SYNOPSIS

TODO

=head1 ABSTRACT

Use dependency in a Perl bean

=head1 DESCRIPTION

C<PerlBean::Dependency::Use> is a class to express C<use> dependencies to classes/modules/files in a C<PerlBean>.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<PerlBean::Dependency::Use> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<import_list>>

Passed to L<set_import_list()>. Must be an C<ARRAY> reference.

=back

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

=item exists_import_list(ARRAY)

Returns the count of items in C<ARRAY> that are in the list after the C<dependency_name>.

=item get_dependency_name()

This method is inherited from package C<PerlBean::Dependency>. Returns the dependency name.

=item get_import_list( [ INDEX_ARRAY ] )

Returns an C<ARRAY> containing the list after the C<dependency_name>. C<INDEX_ARRAY> is an optional list of indexes which when specified causes only the indexed elements in the ordered list to be returned. If not specified, all elements are returned.

=item is_volatile()

This method is inherited from package C<PerlBean::Dependency>. Returns whether the dependency is volatile or not.

=item pop_import_list()

Pop and return an element off the list after the C<dependency_name>. On error an exception C<Error::Simple> is thrown.

=item push_import_list(ARRAY)

Push additional values on the list after the C<dependency_name>. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=item set_dependency_name(VALUE)

This method is inherited from package C<PerlBean::Dependency>. Set the dependency name. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item ^.*[a-zA-Z].*$

=back

=back

=item set_idx_import_list( INDEX, VALUE )

Set value in the list after the C<dependency_name>. C<INDEX> is the integer index which is greater than or equal to C<0>. C<VALUE> is the value.

=item set_import_list(ARRAY)

Set the list after the C<dependency_name> absolutely. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=item set_num_import_list( NUMBER, VALUE )

Set value in the list after the C<dependency_name>. C<NUMBER> is the integer index which is greater than C<0>. C<VALUE> is the value.

=item set_volatile(VALUE)

This method is inherited from package C<PerlBean::Dependency>. State that the dependency is volatile. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item shift_import_list()

Shift and return an element off the list after the C<dependency_name>. On error an exception C<Error::Simple> is thrown.

=item unshift_import_list(ARRAY)

Unshift additional values on the list after the C<dependency_name>. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

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
L<PerlBean::Dependency::Require>,
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

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Dependency::Use::_initialize, first argument must be 'HASH' reference.");

    # import_list, MULTI
    if ( exists( $opt->{import_list} ) ) {
        ref( $opt->{import_list} ) eq 'ARRAY' || throw Error::Simple("ERROR: PerlBean::Dependency::Use::_initialize, specified value for option 'import_list' must be an 'ARRAY' reference.");
        $self->set_import_list( @{ $opt->{import_list} } );
    }
    else {
        $self->set_import_list();
    }

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub exists_import_list {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val1 (@_) {
        foreach my $val2 ( @{ $self->{PerlBean_Dependency_Use}{import_list} } ) {
            ( $val1 eq $val2 ) && $count ++;
        }
    }
    return($count);
}

sub get_import_list {
    my $self = shift;

    if ( scalar(@_) ) {
        my @ret = ();
        foreach my $i (@_) {
            push( @ret, $self->{PerlBean_Dependency_Use}{import_list}[ int($i) ] );
        }
        return(@ret);
    }
    else {
        # Return the full list
        return( @{ $self->{PerlBean_Dependency_Use}{import_list} } );
    }
}

sub pop_import_list {
    my $self = shift;

    # Pop an element from the list
    return( pop( @{ $self->{PerlBean_Dependency_Use}{import_list} } ) );
}

sub push_import_list {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'import_list', @_ ) || throw Error::Simple("ERROR: PerlBean::Dependency::Use::push_import_list, one or more specified value(s) '@_' is/are not allowed.");

    # Push the list
    push( @{ $self->{PerlBean_Dependency_Use}{import_list} }, @_ );
}

sub set_idx_import_list {
    my $self = shift;
    my $idx = shift;
    my $val = shift;

    # Check if index is a positive integer or zero
    ( $idx == int($idx) ) || throw Error::Simple("ERROR: PerlBean::Dependency::Use::set_idx_import_list, the specified index '$idx' is not an integer.");
    ( $idx >= 0 ) || throw Error::Simple("ERROR: PerlBean::Dependency::Use::set_idx_import_list, the specified index '$idx' is not a positive integer or zero.");

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'import_list', $val ) || throw Error::Simple("ERROR: PerlBean::Dependency::Use::set_idx_import_list, one or more specified value(s) '@_' is/are not allowed.");

    # Set the value in the list
    $self->{PerlBean_Dependency_Use}{import_list}[$idx] = $val;
}

sub set_import_list {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'import_list', @_ ) || throw Error::Simple("ERROR: PerlBean::Dependency::Use::set_import_list, one or more specified value(s) '@_' is/are not allowed.");

    # Set the list
    @{ $self->{PerlBean_Dependency_Use}{import_list} } = @_;
}

sub set_num_import_list {
    my $self = shift;
    my $num = shift;

    # Check if index is an integer
    ( $num == int($num) ) || throw Error::Simple("ERROR: PerlBean::Dependency::Use::set_num_import_list, the specified number '$num' is not an integer.");

    # Call set_idx_import_list
    $self->set_idx_import_list( $num - 1, @_ );
}

sub shift_import_list {
    my $self = shift;

    # Shift an element from the list
    return( shift( @{ $self->{PerlBean_Dependency_Use}{import_list} } ) );
}

sub unshift_import_list {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'import_list', @_ ) || throw Error::Simple("ERROR: PerlBean::Dependency::Use::unshift_import_list, one or more specified value(s) '@_' is/are not allowed.");

    # Unshift the list
    unshift( @{ $self->{PerlBean_Dependency_Use}{import_list} }, @_ );
}

sub write {
    my $self = shift;
    my $fh = shift;

    my $dn = $self->get_dependency_name();
    my $tail ='';

    if ( $self->get_import_list() ) {
        $tail .= ' ';
        $tail .= join( ', ', $self->get_import_list() );
    }
    $fh->print( "use $dn$tail;\n" )
}

