package SPOPS::Tie;

# $Id: Tie.pm,v 3.8 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base  qw( Exporter );
use vars  qw( $PREFIX_TEMP $PREFIX_INTERNAL );
use Data::Dumper     qw( Dumper );
use Log::Log4perl    qw( get_logger );
use SPOPS::Exception qw( spops_error );

@SPOPS::Tie::EXPORT_OK = qw( IDX_DATA IDX_CHANGE IDX_SAVE IDX_INTERNAL IDX_TEMP
                             IDX_CHECK_FIELDS IDX_LAZY_LOADED
                             $PREFIX_TEMP $PREFIX_INTERNAL );
$SPOPS::Tie::VERSION   = sprintf("%d.%02d", q$Revision: 3.8 $ =~ /(\d+)\.(\d+)/);

use constant IDX_DATA          => '_dat';
use constant IDX_CHANGE        => '_chg';
use constant IDX_SAVE          => '_svd';
use constant IDX_INTERNAL      => '_int';
use constant IDX_TEMP          => '_tmp';
use constant IDX_IS_LAZY_LOAD  => '_ill';
use constant IDX_LAZY_LOADED   => '_ll';
use constant IDX_LAZY_LOAD_SUB => '_lls';
use constant IDX_CHECK_FIELDS  => '_chk';
use constant IDX_IS_MULTIVALUE => '_imv';
use constant IDX_MULTIVALUE    => '_mv';
use constant IDX_IS_FIELD_MAP  => '_ifm';
use constant IDX_FIELD_MAP     => '_fm';

my $log = get_logger();

$PREFIX_TEMP       = 'tmp_';
$PREFIX_INTERNAL   = '_internal';

# Tie interface stuff below here; see 'perldoc perltie' for what
# each method does. (Or better yet, read Damian Conway's discussion
# of tie in 'Object Oriented Perl'.)


# First activate the callback for the field check, then return the
# object. The object always keeps track of the actual properties, the
# class, whether the object's properties have been changed and keeps
# any temporary data that lives only for the object's lifetime.

sub TIEHASH {
    my ( $class, $base_class, $p ) = @_;
    $p ||= {};

    # See if we're supposed to do any field checking

    my $HAS_FIELD = $class->_field_check( $base_class, $p );

    # Be able to deal with either an arrayref or a hashref of multivalue fields

    if ( ref $p->{multivalue} eq 'HASH' ) {
        $p->{multivalue} = { map { lc $_ => lc $p->{multivalue}{ $_ } } keys %{ $p->{multivalue} } };
    }

    if ( ref $p->{multivalue} eq 'ARRAY' ) {
        $p->{multivalue} = { map { lc $_ => 1 } @{ $p->{multivalue} } };
    }

    # Be sure all field map fields are lower-cased
    if ( ref $p->{field_map} eq 'HASH' ) {
        $p->{field_map} = { map { lc $_ => lc $p->{field_map}{ $_ } } keys %{ $p->{field_map} } };
    }

    return bless ({ class              => $base_class,
                    IDX_TEMP()         => {},
                    IDX_INTERNAL()     => {},
                    IDX_CHANGE()       => 0,
                    IDX_SAVE()         => 0,
                    IDX_DATA()         => {},
                    IDX_IS_LAZY_LOAD() => $p->{is_lazy_load},
                    IDX_LAZY_LOADED()  => {},
                    IDX_LAZY_LOAD_SUB()=> $p->{lazy_load_sub},
                    IDX_IS_MULTIVALUE()=> ( ref $p->{multivalue} eq 'HASH' ),
                    IDX_MULTIVALUE()   => $p->{multivalue},
                    IDX_IS_FIELD_MAP() => ( ref $p->{field_map} eq 'HASH' ),
                    IDX_FIELD_MAP()    => $p->{field_map},
                    IDX_CHECK_FIELDS() => $HAS_FIELD }, $class );
}

sub _field_check { return undef; }

# Just go through each of the possible things that could be
# set and do the appropriate action.

sub FETCH {
    my ( $self, $key ) = @_;
    return unless ( $key );
    my $cmp_key = lc $key;
    $log->is_debug &&
        $log->debug( " tie: Trying to retrieve value for ($key)" );
    return $self->{ IDX_CHANGE() }                 if ( $key eq IDX_CHANGE );
    return $self->{ IDX_SAVE() }                   if ( $key eq IDX_SAVE );
    return $self->{ IDX_TEMP() }{ $cmp_key }     if ( $key =~ /^$PREFIX_TEMP/ );
    return $self->{ IDX_INTERNAL() }{ $cmp_key } if ( $key =~ /^$PREFIX_INTERNAL/ );
    return undef unless ( $self->_can_fetch( $key ) );
    if ( $self->{ IDX_IS_FIELD_MAP() } and
         $self->{ IDX_FIELD_MAP() }{ $cmp_key } ) {
        #warn "(FETCH) using field map: old value ($cmp_key) new ($self->{ IDX_FIELD_MAP() }{ $cmp_key })";
        $cmp_key = $self->{ IDX_FIELD_MAP() }{ $cmp_key };
    }
    if ( $self->{ IDX_IS_LAZY_LOAD() } and
         ! $self->{ IDX_LAZY_LOADED() }{ $cmp_key } ) {
        $self->_lazy_load( $key );
    }
    if ( $self->{ IDX_IS_MULTIVALUE() } and $self->{ IDX_MULTIVALUE() }{ $cmp_key } ) {
        #warn "(FETCH) using multivalue for key $cmp_key";
        return [ keys %{ $self->{ IDX_DATA() }{ $cmp_key } } ];
    }
    return $self->{ IDX_DATA() }{ $cmp_key };
}


sub _can_fetch { return 1 }


sub _lazy_load {
    my ( $self, $key ) = @_;
    my $cmp_key = lc $key;
    unless ( ref $self->{ IDX_LAZY_LOAD_SUB() } eq 'CODE' ) {
        spops_error "Lazy loading activated but no load function specified!";
    }
    $log->is_info &&
        $log->info( "Lazy loading [$key]; is-loaded marker empty" );
    $self->{ IDX_DATA() }{ $cmp_key } = 
                    $self->{ IDX_LAZY_LOAD_SUB() }->( $self->{class},
                                                      $self->{ IDX_DATA() },
                                                      $key );
    $self->{ IDX_LAZY_LOADED() }{ $cmp_key }++;
}


# Similar to FETCH

sub STORE {
    my ( $self, $key, $value ) = @_;
    my $cmp_key = lc $key;
    $log->is_debug &&
        $log->debug( " tie: Storing [$key] => [", ( defined $value ) ? $value : 'undef', "]" );
    return $self->{ IDX_CHANGE() } = $value                 if ( $key eq IDX_CHANGE );
    return $self->{ IDX_SAVE() } = $value                   if ( $key eq IDX_SAVE );
    return $self->{ IDX_TEMP() }{ $cmp_key } = $value     if ( $key =~ /^$PREFIX_TEMP/ );
    return $self->{ IDX_INTERNAL() }{ $cmp_key } = $value if ( $key =~ /^$PREFIX_INTERNAL/ );
    return undef unless ( $self->_can_store( $key, $value ) );
    $self->{ IDX_CHANGE() }++;

    if ( $self->{ IDX_IS_FIELD_MAP() } and 
         $self->{ IDX_FIELD_MAP() }{ $cmp_key } ) {
        #warn "(STORE) using field map: old value ($cmp_key) new ($self->{ IDX_FIELD_MAP() }{ $cmp_key })";
        $cmp_key = $self->{ IDX_FIELD_MAP() }{ $cmp_key };
    }

    # Non-multivalue properties just return the newly stored value

    unless ( $self->{ IDX_IS_MULTIVALUE() } and $self->{ IDX_MULTIVALUE() }{ $cmp_key } ) {
        $self->{ IDX_IS_LAZY_LOAD() } && $self->{ IDX_LAZY_LOADED() }{ $cmp_key }++;
        return $self->{ IDX_DATA() }{ $cmp_key } = $value;
    }

    #warn "(STORE) using multivalue for key $cmp_key";

    # If we're using multiple values we need to see what type of
    # $value we've got

    # If $value is undef, we clear out all values in the object

    unless ( defined $value ) {
        $self->{ IDX_DATA() }{ $cmp_key } = {};
        return undef;
    }

    my $typeof = ref $value;

    # If a scalar, just set it

    unless ( $typeof ) {
        $self->{ IDX_DATA() }{ $cmp_key }{ $value } = 1;
        return $value;
    }

    # If array, set it (if the array is empty, then we're
    # resetting the values)

    if ( $typeof eq 'ARRAY' ) {
        #warn "(STORE) Current value of ($cmp_key)", Dumper( $self->{ IDX_DATA() }{ $cmp_key } ), "";
        $self->{ IDX_DATA() }{ $cmp_key } = { map { $_ => 1 } @{ $value } };
        #warn "(STORE) Value after set of ($cmp_key)", Dumper( $self->{ IDX_DATA() }{ $cmp_key } ), "";
        return undef;
    }

    # If hash, go through each of the potential options and
    # perform the action; everything else is ignored

    if ( $typeof eq 'HASH' ) {
        my $remove_fields =  ( ref $value->{remove} eq 'ARRAY' ) ? $value->{remove} : [ $value->{remove} ];
        foreach my $rmv ( @{ $remove_fields } ) {
            next unless ( $rmv );
            delete $self->{ IDX_DATA() }{ $cmp_key }{ $rmv };
        }

        my $modify_fields = $value->{modify} || {};
        foreach my $mdfy ( keys %{ $modify_fields } ) {
            delete $self->{ IDX_DATA() }{ $cmp_key }{ $mdfy };
            $self->{ IDX_DATA() }{ $cmp_key }{ $modify_fields->{ $mdfy } } = 1
        }
        return undef;
    }

    # We don't know how to handle anything else

    spops_error "Cannot handle a value type of [$typeof] with multivalues";
}

sub _can_store { return 1 }


# For EXISTS and DELETE, We can only do these actions on the actual
# data; use the object methods for the other information.

sub EXISTS {
    my ( $self, $key ) = @_;
    $log->is_debug &&
        $log->debug( " tie: Checking for existence of ($key)" );
    return exists $self->{ IDX_DATA() }{ lc $key };
    $log->error( "Field '$key' is not valid, cannot check existence" );
}


sub DELETE {
    my ( $self, $key ) = @_;
    $log->is_debug &&
        $log->debug( " tie: Clearing value for ($key)" );
    delete $self->{ IDX_DATA() }{ lc $key };
    $self->{ IDX_CHANGE() }++;
}


# We've disabled the ability to do: $object = {} or %{ $object } = ();
# nothing bad happens, it's just a no-op

sub CLEAR {
    my ( $self ) = @_;
    $log->error( "Trying to clear object through hash means failed; use object interface" );
}


# Note that you only see the data when you cycle through the keys 
# or even do a Data::Dumper::Dumper( $object ); you do not see
# the meta-data being tracked. This is a feature.

sub FIRSTKEY {
    my ( $self ) = @_;
    $log->is_debug &&
        $log->debug( " tie: Finding first key in data object" );
    keys %{ $self->{ IDX_DATA() } };
    my $first_key = each %{ $self->{ IDX_DATA() } };
    return undef unless defined $first_key;
    return $first_key;
}


sub NEXTKEY {
    my ( $self ) = @_;
    $log->is_debug &&
        $log->debug( " tie: Finding next key in data object" );
    my $next_key = each %{ $self->{ IDX_DATA() } };
    return undef unless defined $next_key;
    return $next_key;
}

1;

__END__

=pod

=head1 NAME

SPOPS::Tie - Simple class implementing tied hash with some goodies

=head1 SYNOPSIS

 # Create the tied hash
 use SPOPS::Tie;
 my ( %data );
 my @fields = qw( first_name last_name login birth_date );
 tie %data, 'SPOPS::Tie', $class, \@fields;

 # Store some simple properties
 $data{first_name} = 'Charles';
 $data{last_name}  = 'Barkley';
 $data{login}      = 'cb';
 $data{birth_date} = '1957-01-19';

 # Store a temporary property
 $data{tmp_rebound_avg} = 11.3;

 while ( my ( $prop, $val ) = each %data ) {
   printf( "%-15s: %s\n", $prop, $val );
 }

 # Note that output does not include 'tmp_rebound_avg'
 >first_name     : Charles
 >login          : cb
 >last_name      : Barkley
 >birth_date     : 1957-01-19

 print "Rebounding Average: $data{tmp_rebound_avg}\n";

 # But you can access it still the same
 >Rebounding Average: 11.3

=head1 DESCRIPTION

Stores data for a SPOPS object, and also some accompanying materials
such as whether the object has been changed and any temporary
variables.

=head2 Checking Changed State

You can check whether the data have changed since the last fetch by
either calling the method of the SPOPS object (recommended) or asking
for the '_changed' key from the C<tied()> object:

 # See if this object has changed
 if (tied %data){_changed} ) {;
  ...do stuff...
 } 

 # Tell the object that it has changed (force)
 (tied %data){_changed} = 1;

Note that this state is automatically tracked based on whether you set
any property of the object, so you should never need to do this. See
L<SPOPS|SPOPS> for more information about the I<changed> methods.

=head2 Tracking Temporary Variables

Note that this section only holds true if you have field-checking
turned on (by passing an arrayref of fields in the 'field' key of the
hashref passed as the second parameter in the C<tie> call).

At times you might wish to keep information with the object that is
only temporary and not supposed to be serialized with the
object. However, the 'valid property' nature of the tied hash prevents
you from storing information in properties with names other than those
you pass into the initial call to tie(). What to do?

Have no fear! Simply prefix the property with 'tmp_' (or something
else, see below) and SPOPS::Tie will keep the information at the ready
for you:

 my ( %data );
 my $class = 'SPOPS::User';
 tie %data, 'SPOPS::Tie', $class, [ qw/ first_name last_name login / ];
 $data{first_name} = 'Chucky';
 $data{last_name}  = 'Gordon';
 $data{login}      = 'chuckg';
 $data{tmp_inoculation} = 'Jan 16, 1981';

For as long as the hash %data is in scope, you can reference the
property 'tmp_inoculation'. However, you can only reference it
directly. You will not see the property if you iterate through hash
using I<keys> or I<each>.

=head2 Lazy Loading

You can specify you want your object to be lazy loaded when creating
the tie interface:

  my $fields = [ qw/ first_name last_name login life_history / ];
  my $params = { is_lazy_load  => 1,
                 lazy_load_sub => \&load_my_variables,
                 field         => $fields };
  tie %data, 'SPOPS::Tie', $class, $params;

=head2 Storing Information for Internal Use

The final kind of information that can be stored in a SPOPS object is
'internal' information. This is similar to temporary variables, but is
typically only used in the internal SPOPS mechanisms -- temporary
variables are often used to store computed results or other
information for display rather than internal use.

For example, the L<SPOPS::DBI|SPOPS::DBI> module could allow you to
create validating subroutines to ensure that your data conform to some
sort of specification:

 push @{ $obj->{_internal_validate} }, \&ensure_consistent_date;

Most of the time you will not need to deal with this, but check the
documentation for the object you are using.

=head2 Field Mapping

You can setup a mapping of fields to make an SPOPS object look like
another SPOPS object even though its storage is completely
different. For instance, say we were tying a legacy data management of
system of book data to a website. Our web designers do not like to see
FLDNMS LK THS since they are used to the more robust capabilities of
modern data systems.

So we can use the field mapping capabilities of C<SPOPS::Tie> to make
the objects more palatable:

 my $obj = tie %data, 'SPOPS::Tie', 'My::Book',
                      { field_map => { author         => 'AUTH',
                                       title          => 'TTL',
                                       printing       => 'PNUM',
                                       classification => 'CLSF' } };

(See the L<SPOPS|SPOPS> documentation for how to declare this in your
SPOPS configuration.)

So your web designers can use the objects:

 print "Book author: $book->{author}\n",
       "Title: $book->{title}\n";

But the data are actually stored in the object (and retrieved by an
C<each> query on the object -- be careful) using the old, ugly names
'AUTH', 'TTL', 'PNUM' and 'CLSF'.

This can be extremely helpful not only to rename fields for aesthetic
reasons, but also to make objects conform to the same interface.

=head2 Multivalue Fields

Some data storage backends -- such as LDAP -- can store multiple
values for a single field, and C<SPOPS::Tie> can represent it.

Three basic rules when dealing with multivalue fields:

=over 4

=item 1.

No duplicate values allowed.

=item 2.

Values are not sorted. If you need sorted values, use the tools perl
provides you.

=item 3.

Values are always retrieved from a multivalue field as an array
reference.

=back

The interface for setting values is somewhat different, so sit up
straight and pay attention.

B<(0) Telling SPOPS::Tie>

 my $obj = tie %data, 'SPOPS::Tie', 'My::LDAP::Person',
                      { multivalue => [ 'objectclass' ] };

This means only the field 'objectclass' will be treated as a
multivalue field.

B<(1) Creating a new object>

 my $person = My::LDAP::Person->new();
 $person->{objectclass} = [ 'inetOrgPerson', 'organizationalPerson',
                            'person' ];
 $person->{sn}          = 'Winters';
 $person->{givenname}   = 'Chris';
 $person->{mail}        = 'chris@cwinters.com';
 $person->save;

The property 'objectclass' here is multivalued and currently has three
values: 'inetOrgPerson', 'organizationalPerson', and 'person'.

B<(2) Fetching and displaying an object>

 my $person = My::LDAP::Person->fetch( 'chris@cwinters.com' );
 print "Person info: $person->{givenname} $person->{sn} ",
       "(mail: $person->{mail})\n";
 print "Classes: ", join( ', ', @{ $person->{objectclass} } ), "\n";

Displays:

 > Person info: Chris Winters (mail: chris@cwinters.com)
 > Classes: inetOrgPerson, organizationalPerson, person

Note that if there were no values for defined for C<objectclass>, the
value retrieval would return an arrayref. Value retrievals always
return an array reference, even if there are B<no> values. This is to
provide consistency of interface, and so you can always use the value
as an array reference without cumbersome checking to see if the value
is C<undef>.

B<(3) Setting a single value>

 my $person = My::LDAP::Person->fetch( 'chris@cwinters.com' );
 $person->{objectclass} = 'newSchemaPerson';
 $person->save;

The property 'objectclass' now has four values: 'inetOrgPerson',
'organizationalPerson', 'person', and 'newSchemaPerson'.

B<(4) Setting all values>

 my $person = My::LDAP::Person->fetch( 'chris@cwinters.com' );
 $person->{objectclass} = [ 'newSchemaPerson', 'reallyNewPerson' ];
 $person->save;

The property 'objectclass' now has two values: 'newSchemaPerson',
'reallyNewPerson'.

B<(5) Removing one value>

 my $person = My::LDAP::Person->fetch( 'chris@cwinters.com' );
 $person->{objectclass} = { remove => 'newSchemaPerson' };
 $person->save;

The property 'objectclass' now has one value: 'reallyNewPerson'.

 my $object_class_thingy = $person->{objectclass};
 print "Object class return is a: ", ref $object_class_thingy, "\n";

Displays:

 > Object class return is a: ARRAY

Again: when a multivalued property is retrieved it B<always> returns
an arrayref, even if there is only one value.

B<(6) Modifying one value>

 my $person = My::LDAP::Person->fetch( 'chris@cwinters.com' );
 $person->{objectclass} =
      { modify => { reallyNewPerson => 'totallyNewPerson' } };
 $person->save;

The property 'objectclass' still has one value, but it has been
changed to: 'totallyNewPerson'.

Note: you could have gotten the same result in this example by doing:

 $person->{objectclass} = [ 'totallyNewPerson' ];
 $person->save;

B<(7) Removing all values>

 my $person = My::LDAP::Person->fetch( 'chris@cwinters.com' );
 $person->{objectclass} = undef;
 $person->save;

The property 'objectclass' now has no values.

You can also get the same result with:

 $person->{objectclass} = [];
 $person->save;

=head1 METHODS

See L<Tie::Hash|Tie::Hash> or L<perltie> for details of what the
different methods do.

=head1 TO DO

B<Benchmarking>

We should probably benchmark this thing to see what it can do

=head1 BUGS

None known.

=head1 SEE ALSO

L<perltie|perltie>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>

=cut
