package PerlBean::Collection;

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
    'license' => [ '.*' ],
);

# Used by _value_is_allowed
our %ALLOW_VALUE = (
);

# Package version
our ($VERSION) = '$Revision: 1.0 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

PerlBean::Collection - contains a collection of PerlBean objects

=head1 SYNOPSIS

 use strict;
 use PerlBean;
 use PerlBean::Collection;
 use PerlBean::Attribute::Factory;
 
 my $bean = PerlBean->new( {
     package => 'Athlete',
 } );
 my $factory = PerlBean::Attribute::Factory->new();
 my $attr = $factory->create_attribute( {
     method_factory_name => 'name',
     short_description => 'the name of the athlete',
 } );
 $bean->add_method_factory($attr);
 
 my $bean2 = PerlBean->new( {
     package => 'Cyclist',
     base => [ qw(Athlete)],
 } );
 my $factory = PerlBean::Attribute::Factory->new();
 my $attr2 = $factory->create_attribute( {
     method_factory_name => 'cycle',
     short_description => 'the cyclist\'s cycle',
 } );
 $bean2->add_method_factory($attr2);
 
 my $collection = PerlBean::Collection->new();
 $collection->add_perl_bean($bean);
 $collection->add_perl_bean($bean2);
 $collection->write('tmp');

=head1 ABSTRACT

Code hierarchy generation for bean like Perl modules

=head1 DESCRIPTION

C<PerlBean::Collection> contains a collection of C<PerlBean> objects in order to generate an hierarchy of Perl modules.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<PerlBean::Collection> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<license>>

Passed to L<set_license()>.

=item B<C<perl_bean>>

Passed to L<set_perl_bean()>. Must be an C<ARRAY> reference.

=back

=back

=head1 METHODS

=over

=item add_perl_bean( [ VALUE ... ] )

Add additional values on the list of PerlBean objects in the collection. Each C<VALUE> is an object out of which the id is obtained through method C<get_package()>. The obtained B<key> is used to store the value and may be used for deletion and to fetch the value. 0 or more values may be supplied. Multiple occurrences of the same key yield in the last occurring key to be inserted and the rest to be ignored. Each key of the specified values is allowed to occur only once. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item PerlBean

=back

=back

=item delete_perl_bean(ARRAY)

Delete elements from the list of PerlBean objects in the collection. Returns the number of deleted elements. On error an exception C<Error::Simple> is thrown.

=item exists_perl_bean(ARRAY)

Returns the count of items in C<ARRAY> that are in the list of PerlBean objects in the collection.

=item get_license()

Returns the software license for the PerlBean collection.

=item keys_perl_bean()

Returns an C<ARRAY> containing the keys of the list of PerlBean objects in the collection.

=item set_license(VALUE)

Set the software license for the PerlBean collection. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must match regular expression:

=over

=item .*

=back

=back

=item set_perl_bean( [ VALUE ... ] )

Set the list of PerlBean objects in the collection absolutely using values. Each C<VALUE> is an object out of which the id is obtained through method C<get_package()>. The obtained B<key> is used to store the value and may be used for deletion and to fetch the value. 0 or more values may be supplied. Multiple occurrences of the same key yield in the last occurring key to be inserted and the rest to be ignored. Each key of the specified values is allowed to occur only once. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item PerlBean

=back

=back

=item values_perl_bean( [ KEY_ARRAY ] )

Returns an C<ARRAY> containing the values of the list of PerlBean objects in the collection. If C<KEY_ARRAY> contains one or more C<KEY>s the values related to the C<KEY>s are returned. If no C<KEY>s specified all values are returned.

=item write(DIRECTORY)

Write the hierarchy of Perl class code to C<DIRECTORY>. C<DIRECTORY> is a directory name. On error an exception C<Error::Simple> is thrown.

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

First development: December 2002
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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: PerlBean::Collection::_initialize, first argument must be 'HASH' reference.");

    # license, SINGLE
    exists( $opt->{license} ) && $self->set_license( $opt->{license} );

    # perl_bean, MULTI
    if ( exists( $opt->{perl_bean} ) ) {
        ref( $opt->{perl_bean} ) eq 'ARRAY' || throw Error::Simple("ERROR: PerlBean::Collection::_initialize, specified value for option 'perl_bean' must be an 'ARRAY' reference.");
        $self->set_perl_bean( @{ $opt->{perl_bean} } );
    }
    else {
        $self->set_perl_bean();
    }

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

sub add_perl_bean {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'perl_bean', @_ ) || throw Error::Simple("ERROR: PerlBean::Collection::add_perl_bean, one or more specified value(s) '@_' is/are not allowed.");

    # Add keys/values
    foreach my $val (@_) {
        $self->{PerlBean_Collection}{perl_bean}{ $val->get_package() } = $val;
        $val->set_collection($self);
    }
}

sub delete_perl_bean {
    my $self = shift;

    # Delete values
    my $del = 0;
    foreach my $val (@_) {
        exists( $self->{PerlBean_Collection}{perl_bean}{$val} ) || next;
        delete( $self->{PerlBean_Collection}{perl_bean}{$val} );
        $del ++;
    }
    return($del);
}

sub exists_perl_bean {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val (@_) {
        $count += exists( $self->{PerlBean_Collection}{perl_bean}{$val} );
    }
    return($count);
}

sub get_license {
    my $self = shift;

    return( $self->{PerlBean_Collection}{license} );
}

sub keys_perl_bean {
    my $self = shift;

    # Return all keys
    return( keys( %{ $self->{PerlBean_Collection}{perl_bean} } ) );
}

sub set_license {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'license', $val ) || throw Error::Simple("ERROR: PerlBean::Collection::set_license, the specified value '$val' is not allowed.");

    # Assignment
    $self->{PerlBean_Collection}{license} = $val;
}

sub set_perl_bean {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'perl_bean', @_ ) || throw Error::Simple("ERROR: PerlBean::Collection::set_perl_bean, one or more specified value(s) '@_' is/are not allowed.");

    # Empty list
    $self->{PerlBean_Collection}{perl_bean} = {};

    # Add keys/values
    foreach my $val (@_) {
        $self->{PerlBean_Collection}{perl_bean}{ $val->get_package() } = $val;
        $val->set_collection($self);
    }
}

sub values_perl_bean {
    my $self = shift;

    if ( scalar(@_) ) {
        my @ret = ();
        foreach my $key (@_) {
            exists( $self->{PerlBean_Collection}{perl_bean}{$key} ) && push( @ret, $self->{PerlBean_Collection}{perl_bean}{$key} );
        }
        return(@ret);
    }
    else {
        # Return all values
        return( values( %{ $self->{PerlBean_Collection}{perl_bean} } ) );
    }
}

sub write {
    my $self = shift;
    my $dir = shift || '.';

    # Check for directory existence
    ( -d $dir ) ||
        throw Error::Simple("ERROR: PerlBean::Collection::write, directory '$dir' does not exist.");

    # Check for directory write-ability
    ( -w $dir ) ||
        throw Error::Simple("ERROR: PerlBean::Collection::write, directory '$dir' is not writable.");

    # Finalize the PerlBeans
    foreach my $bean ( $self->values_perl_bean() ) {
        $bean->_finalize();
    }

    # Generate the PerlBeans
    foreach my $bean ( $self->values_perl_bean() ) {
        my $pkg = $bean->get_package();
        my @dir = split(/:+/, $pkg);
        my $fn = pop(@dir);
        my $dir_tot = $dir;

        # Make directory
        foreach my $sub_dir (@dir) {
            $dir_tot .= '/' . $sub_dir;
            next if ( -d $dir_tot );
            mkdir($dir_tot);
        }

        # Make the file handle and write bean
        use IO::File;
        my $fh = IO::File->new("> $dir_tot/$fn.pm");
        $bean->write( $fh, $self );
    }

    # Un-finalize the PerlBeans
    foreach my $bean ( $self->values_perl_bean() ) {
        $bean->_unfinalize();
    }
}

