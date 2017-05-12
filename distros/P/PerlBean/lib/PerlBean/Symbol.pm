package PerlBean::Symbol;

use 5.005;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use PerlBean::Style qw(:codegen);

# Used by _value_is_allowed
our %ALLOW_ISA = (
);

# Used by _value_is_allowed
our %ALLOW_REF = (
);

# Used by _value_is_allowed
our %ALLOW_RX = (
    'export_tag' => [ '^\S*$' ],
    'symbol_name' => [ '^\S+$' ],
);

# Used by _value_is_allowed
our %ALLOW_VALUE = (
);

# Used by _initialize
our %DEFAULT_VALUE = (
    'declared' => 1,
);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Symbol - Symbol in a Perl bean

=head1 SYNOPSIS

 use strict;
 use PerlBean;
 use PerlBean::Attribute::Factory;
 
 my $bean = PerlBean->new( {
     package => 'MyPackage',
 } );
 my $factory = PerlBean::Attribute::Factory->new();
 my $attr = $factory->create_attribute( {
     method_factory_name => 'true',
     short_description => 'something is true',
 } );
 $bean->add_method_factory($attr);
 
 use IO::File;
 -d 'tmp' || mkdir('tmp');
 my $fh = IO::File->new('> tmp/PerlBean.pl.out');
 $bean->write($fh);

=head1 ABSTRACT

Symbol in a Perl bean

=head1 DESCRIPTION

C<PerlBean::Symbol> allows to specify, declare, assign an export a symbol from a C<PerlBean>.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<PerlBean::Symbol> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<assignment>>

Passed to L<set_assignment()>.

=item B<C<comment>>

Passed to L<set_comment()>.

=item B<C<declared>>

Passed to L<set_declared()>. Defaults to B<1>.

=item B<C<description>>

Passed to L<set_description()>.

=item B<C<export_tag>>

Passed to L<set_export_tag()>. Must be an C<ARRAY> reference.

=item B<C<symbol_name>>

Passed to L<set_symbol_name()>.

=item B<C<volatile>>

Passed to L<set_volatile()>.

=back

=back

=head1 METHODS

=over

=item add_export_tag(ARRAY)

Add additional values on the list of tags with which the symbol is exported. NOTE: The C<default> tag lets the symbol be exported by default. C<ARRAY> is the list value. The addition may not yield to multiple identical elements in the list. Hence, multiple occurrences of the same element cause the last occurrence to be inserted. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must match regular expression:

=over

=item ^\S*$

=back

=back

=item delete_export_tag(ARRAY)

Delete elements from the list of tags with which the symbol is exported. NOTE: The C<default> tag lets the symbol be exported by default. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item exists_export_tag(ARRAY)

Returns the count of items in C<ARRAY> that are in the list of tags with which the symbol is exported. NOTE: The C<default> tag lets the symbol be exported by default.

=item get_assignment()

Returns the value assigned to the symbol during declaration.

=item get_comment()

Returns the comment for the symbol declaration.

=item get_description()

Returns the description of the symbol.

=item get_symbol_name()

Returns the symbol's name (e.g. C<$var> or C<@list>).

=item is_declared()

Returns whether the symbol is to be declared with C<our> or not.

=item is_volatile()

Returns whether the symbol is volatile or not.

=item set_assignment(VALUE)

Set the value assigned to the symbol during declaration. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_comment(VALUE)

Set the comment for the symbol declaration. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_declared(VALUE)

State that the symbol is to be declared with C<our>. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_description(VALUE)

Set the description of the symbol. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_export_tag(ARRAY)

Set the list of tags with which the symbol is exported. NOTE: The C<default> tag lets the symbol be exported by default absolutely. C<ARRAY> is the list value. Each element in the list is allowed to occur only once. Multiple occurrences of the same element yield in the last occurring element to be inserted and the rest to be ignored. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must match regular expression:

=over

=item ^\S*$

=back

=back

=item set_symbol_name(VALUE)

Set the symbol's name (e.g. C<$var> or C<@list>). C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item ^\S+$

=back

=back

=item set_volatile(VALUE)

State that the symbol is volatile. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item values_export_tag()

Returns an C<ARRAY> containing all values of the list of tags with which the symbol is exported. NOTE: The C<default> tag lets the symbol be exported by default.

=item write(FILEHANDLE)

Writes the code for the symbol. C<FILEHANDLE> is an C<IO::Handle> object.

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
L<PerlBean::Method::Factory>,
L<PerlBean::Style>

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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Symbol::_initialize, first argument must be 'HASH' reference.");

    # assignment, SINGLE
    exists( $opt->{assignment} ) && $self->set_assignment( $opt->{assignment} );

    # comment, SINGLE
    exists( $opt->{comment} ) && $self->set_comment( $opt->{comment} );

    # declared, BOOLEAN, with default value
    $self->set_declared( exists( $opt->{declared} ) ? $opt->{declared} : $DEFAULT_VALUE{declared} );

    # description, SINGLE
    exists( $opt->{description} ) && $self->set_description( $opt->{description} );

    # export_tag, MULTI
    if ( exists( $opt->{export_tag} ) ) {
        ref( $opt->{export_tag} ) eq 'ARRAY' || throw Error::Simple("ERROR: PerlBean::Symbol::_initialize, specified value for option 'export_tag' must be an 'ARRAY' reference.");
        $self->set_export_tag( @{ $opt->{export_tag} } );
    }
    else {
        $self->set_export_tag();
    }

    # symbol_name, SINGLE
    exists( $opt->{symbol_name} ) && $self->set_symbol_name( $opt->{symbol_name} );

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

sub add_export_tag {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'export_tag', @_ ) || throw Error::Simple("ERROR: PerlBean::Symbol::add_export_tag, one or more specified value(s) '@_' is/are not allowed.");

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Symbol}{export_tag}{$val} = $val;
    }
}

sub delete_export_tag {
    my $self = shift;

    # Delete values
    my $del = 0;
    foreach my $val (@_) {
        exists( $self->{PerlBean_Symbol}{export_tag}{$val} ) || next;
        delete( $self->{PerlBean_Symbol}{export_tag}{$val} );
        $del ++;
    }
    return($del);
}

sub exists_export_tag {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val (@_) {
        $count += exists( $self->{PerlBean_Symbol}{export_tag}{$val} );
    }
    return($count);
}

sub get_assignment {
    my $self = shift;

    return( $self->{PerlBean_Symbol}{assignment} );
}

sub get_comment {
    my $self = shift;

    return( $self->{PerlBean_Symbol}{comment} );
}

sub get_description {
    my $self = shift;

    return( $self->{PerlBean_Symbol}{description} );
}

sub get_symbol_name {
    my $self = shift;

    return( $self->{PerlBean_Symbol}{symbol_name} );
}

sub is_declared {
    my $self = shift;

    if ( $self->{PerlBean_Symbol}{declared} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_volatile {
    my $self = shift;

    if ( $self->{PerlBean_Symbol}{volatile} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub set_assignment {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'assignment', $val ) || throw Error::Simple("ERROR: PerlBean::Symbol::set_assignment, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Symbol}{assignment} = $val;
}

sub set_comment {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'comment', $val ) || throw Error::Simple("ERROR: PerlBean::Symbol::set_comment, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Symbol}{comment} = $val;
}

sub set_declared {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Symbol}{declared} = 1;
    }
    else {
        $self->{PerlBean_Symbol}{declared} = 0;
    }
}

sub set_description {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'description', $val ) || throw Error::Simple("ERROR: PerlBean::Symbol::set_description, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Symbol}{description} = $val;
}

sub set_export_tag {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'export_tag', @_ ) || throw Error::Simple("ERROR: PerlBean::Symbol::set_export_tag, one or more specified value(s) '@_' is/are not allowed.");

    # Empty list
    $self->{PerlBean_Symbol}{export_tag} = {};

    # Add values
    foreach my $val (@_) {
        $self->{PerlBean_Symbol}{export_tag}{$val} = $val;
    }
}

sub set_symbol_name {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'symbol_name', $val ) || throw Error::Simple("ERROR: PerlBean::Symbol::set_symbol_name, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Symbol}{symbol_name} = $val;
}

sub set_volatile {
    my $self = shift;

    if (shift) {
        $self->{PerlBean_Symbol}{volatile} = 1;
    }
    else {
        $self->{PerlBean_Symbol}{volatile} = 0;
    }
}

sub values_export_tag {
    my $self = shift;

    # Return all values
    return( values( %{ $self->{PerlBean_Symbol}{export_tag} } ) );
}

sub write {
    my $self = shift;
    my $fh = shift;

    # Do nothing if symbol should not be declared
    $self->is_declared() || return;

    my $name = $self->get_symbol_name() || '';

    my $comment = $self->get_comment() || '';

    my $decl = $self->get_assignment() ?
            "$AO=$AO" . $self->get_assignment() : ";\n";

    $fh->print( "${comment}our ${name}${decl}\n" );
}

