package SPOPS::LDAP;

# $Id: LDAP.pm,v 3.4 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base qw( SPOPS );
use Log::Log4perl qw( get_logger );
use Data::Dumper     qw( Dumper );
use Net::LDAP        qw();
use Net::LDAP::Entry qw();
use Net::LDAP::Util  qw();
use SPOPS;
use SPOPS::Exception::LDAP;
use SPOPS::Secure    qw( :level );

my $log = get_logger();

$SPOPS::LDAP::VERSION   = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);


########################################
# CONFIG
########################################

# LDAP config items available from class/object

sub no_insert                { return $_[0]->CONFIG->{no_insert}   || {}  }
sub no_update                { return $_[0]->CONFIG->{no_update}   || {}  }
sub skip_undef               { return $_[0]->CONFIG->{skip_undef}  || {}  }
sub base_dn {
    unless ( $_[0]->CONFIG->{ldap_base_dn} ) {
        SPOPS::Exception->throw( "No Base DN defined" );
    }
    return $_[0]->CONFIG->{ldap_base_dn};
}
sub id_value_field           { return $_[0]->CONFIG->{id_value_field} }
sub ldap_object_class        { return $_[0]->CONFIG->{ldap_object_class} }
sub ldap_fetch_object_class  { return $_[0]->CONFIG->{ldap_fetch_object_class} }
sub ldap_update_only_changed { return $_[0]->CONFIG->{ldap_update_only_changed} }

sub get_superuser_id         { return $_[0]->CONFIG->{ldap_root_dn} }
sub get_supergroup_id        { return $_[0]->CONFIG->{ldap_root_group_dn} }

sub is_superuser {
    my ( $class, $id ) = @_;
    return ( $id eq $class->get_superuser_id );
}

sub is_supergroup {
    my ( $class, @id ) = @_;
    my $super_gid = $class->get_supergroup_id;
    return grep { $_ eq $super_gid } @id;
}


########################################
# CONNECTION RETRIEVAL
########################################

# Subclass must override -- see POD for info

sub global_datasource_handle { return undef }
sub connection_info          { return undef }


########################################
# CLASS CONFIGURATION
########################################

sub behavior_factory {
    my ( $class ) = @_;
    require SPOPS::ClassFactory::LDAP;
    $log->is_debug &&
        $log->debug( "Installing SPOPS::LDAP behaviors for ($class)" );
    return { read_code => \&SPOPS::ClassFactory::LDAP::conf_read_code,
             has_a     => \&SPOPS::ClassFactory::LDAP::conf_relate_has_a,
             links_to  => \&SPOPS::ClassFactory::LDAP::conf_relate_links_to,
             fetch_by  => \&SPOPS::ClassFactory::LDAP::conf_fetch_by, };

}


########################################
# CLASS INITIALIZATION
########################################

sub class_initialize {
    my ( $class )  = @_;
    $class->_class_initialize;
    return 1;
}

sub _class_initialize {}


########################################
# OBJECT INFO
########################################

sub dn {
    my ( $self, $dn ) = @_;
    unless ( ref $self ) {
        SPOPS::Exception->throw( "Cannot call dn() as class method" );
    }
    $self->{tmp_dn} = $dn if ( $dn );
    return $self->{tmp_dn};
}


########################################
# FETCH
########################################

sub create_id_filter {
    my ( $item, $id ) = @_;
    return join( '=', $item->id_field, $id )  if ( $id );
    unless ( ref $item ) {
        SPOPS::Exception->throw(
               "Cannot create ID filter with a class method call and no ID" );
    }
    return join( '=', $item->id_field, $item->id );
}


# TODO: If the object is requested with a 'filter' argument rather
# than the ID, we might need to fetch the object twice, or perhaps
# fetch the object and create it, and then call 'fetch' again with an
# 'object' argument which we can clone rather than executing the
# actual fetch again. Fetching via filter plays a little havoc with
# the security check and pre_fetch_action -- right now we've
# duct-taped it but it should be fixed shortly...

sub fetch {
    my ( $class, $id, $p ) = @_;
    $p ||= {};
    $log->is_debug &&
        $log->debug( "Trying to fetch an item of $class with ID $id and params ",
                    join " // ",
                    map { $_ . ' -> ' . ( defined( $p->{$_} ) ? $p->{$_} : '' ) }
                          keys %{ $p } );
    return undef unless ( $id or $p->{filter} );

    my $info = $class->_perform_prefetch( $p );

    # Run the search

    my $filter = ( $p->{no_filter} )
                   ? '' : $p->{filter} || $class->create_id_filter( $id );
    my $entry = $class->_fetch_single_entry({ connect_key => $p->{connect_key},
                                              ldap        => $p->{ldap},
                                              base        => $p->{base},
                                              scope       => $p->{scope},
                                              filter      => $filter });
    unless ( $entry ) {
        $log->is_info &&
            $log->info( "No entry found matching object ID ($id)" );
        return undef;
    }
    my $obj = $class->_perform_postfetch( $p, $info, $entry );
    return $obj;
}


sub _perform_prefetch {
    my ( $class, $p, $info ) = @_;
    $info ||= {};

    # If an ID was not passed in but a filter was, we need to delay
    # security checks until after the object has already been fetched
    # so we can grab the ID from the object

    $info->{delay_security_check} = ( ! $p->{id} and $p->{filter} ) ? 1 : 0;

    # Let security errors bubble up

    $info->{level} = $p->{security_level};
    unless ( $info->{delay_security_check} or $p->{skip_security} ) {
        $info->{level} ||= $class->check_action_security({ id       => $p->{id},
                                                           required => SEC_LEVEL_READ });
    }

    # Do any actions the class wants before fetching -- note that if
    # any of the actions returns undef (false), we bail.

    return undef unless ( $class->pre_fetch_action({ %{ $p }, id => $p->{id} }) );
    $log->is_info &&
        $log->info( "Pre fetch actions executed ok" );
    return $info;
}


sub _perform_postfetch {
    my ( $class, $p, $info, $entry ) = @_;
    $log->is_info &&
        $log->info( "Single entry found ok; setting values into object",
                    "(Delay security: $info->{delay_security_check})" );
    my $obj = $class->new({ skip_default_values => 1 });
    $obj->_fetch_assign_row( undef, $entry );
    if ( $info->{delay_security_check} && !  $p->{skip_security} ) {
        $info->{level} ||= $class->check_action_security({ id       => $obj->id,
                                                           required => SEC_LEVEL_READ })
    }
    $obj->_fetch_post_process( $p, $info->{level} );
    return $obj;
}


sub _fetch_single_entry {
    my ( $class, $p ) = @_;
    my $ldap = $p->{ldap} || $class->global_datasource_handle( $p->{connect_key} );
    $log->is_info &&
        $log->info( "Base DN (", $class->base_dn( $p->{connect_key} ), ")",
                    "and filter <<$p->{filter}>> being used to fetch single object" );
    my %args = ( base   => $p->{base} || $class->base_dn( $p->{connect_key} ),
                 scope  => $p->{scope} || 'sub' );
    $args{filter} = $p->{filter} if ( $p->{filter} );
    my $ldap_msg = $ldap->search( %args );
    $class->_check_error( $ldap_msg, 'fetch' );

    # Go ahead and use $count here since we've hopefully only
    # retrieved a single record and don't have to worry about blocking
    # (etc.) for a long time

    my $count = $ldap_msg->count;
    if ( $count > 1 ) {
        SPOPS::Exception::LDAP->throw( "Trying to retrieve unique record, retrieved [$count]",
                                       { filter => $p->{filter} } );
    }
    if ( $count == 0 ) {
        $log->is_info &&
            $log->info( "No entry found matching filter ($p->{filter})" );
        return undef;
    }
    return $ldap_msg->entry( 0 );
}


# Given a DN, return an object

sub fetch_by_dn {
    my ( $class, $dn, $p ) = @_;
    $p->{base}   = $dn;
    $p->{scope}  = 'base';
    $p->{filter} = '(objectclass=*)';
    return $class->fetch( undef, $p );
}


# Return implementation of SPOPS::Iterator with results

sub fetch_iterator {
    my ( $class, $p ) = @_;
    require SPOPS::Iterator::LDAP;
    $log->is_info &&
        $log->info( "Trying to create an Iterator with: ", Dumper( $p ) );
    $p->{class}                    = $class;
    ( $p->{offset}, $p->{max} )    = SPOPS::Utility->determine_limit( $p->{limit} );
    unless ( ref $p->{id_list} ) {
        $p->{ldap_msg} = $class->_execute_multiple_record_query( $p );
        $class->_check_error( $p->{ldap_msg}, 'fetch_iterator' );
    }
    return SPOPS::Iterator::LDAP->new( { %{ $p }, skip_default_values => 1 });
}


# Given a filter, return an arrayref of objects

sub fetch_group {
    my ( $class, $p ) = @_;
    my ( $offset, $max ) = SPOPS::Utility->determine_limit( $p->{limit} );
    my $ldap_msg = $class->_execute_multiple_record_query( $p );
    $class->_check_error( $ldap_msg, 'fetch_group' );

    my $entry_count = 0;
    my @group = ();
ENTRY:
    while ( my $entry = $ldap_msg->shift_entry ) {
        my $obj = $class->new({ skip_default_values => 1 });
        $obj->_fetch_assign_row( undef, $entry );
        my $level = ( $p->{skip_security} )
                      ? SEC_LEVEL_WRITE
                      : eval { $obj->check_action_security({ required => SEC_LEVEL_READ }) };
        if ( $@ ) {
            $log->is_info &&
                $log->info( "Security check for object (", $obj->dn, ")",
                            "in fetch_group() failed, skipping." );
            next ENTRY;
        }

        if ( $offset and ( $entry_count < $offset ) ) {
            $entry_count++;
            next ENTRY
        }
        last ENTRY if ( $max and ( $entry_count >= $max ) );
        $entry_count++;

        $obj->_fetch_post_process( $p, $level );
        push @group, $obj;
    }
    return \@group;
}


sub _execute_multiple_record_query {
    my ( $class, $p ) = @_;
    my $filter = $p->{where} || $p->{filter} || '';

    # If there is a filter, be sure it's in ()
    if ( $filter and $filter !~ /^\(.*\)$/ ) {
        $filter = "($filter)";
    }

    # Specify an object class in the filter if the filter doesn't
    # already specify an object class and our config says we should

    if ( ( my $fetch_oc = $class->ldap_fetch_object_class ) and $filter !~ /objectclass/ ) {
        my $oc_filter = "(objectclass=$fetch_oc)";
        $log->is_debug &&
            $log->debug( "Adding filter for object class ($fetch_oc)" );
        $filter = ( $filter ) ? "(&$oc_filter$filter)" : $oc_filter;
    }
    my $ldap = $p->{ldap} || $class->global_datasource_handle( $p->{connect_key} );
    $log->is_info &&
        $log->info( "Base DN (", $class->base_dn( $p->{connect_key} ), ")\nFilter <<$filter>>\n",
                    "being used to fetch one or more objects" );
    return $ldap->search( base   => $class->base_dn( $p->{connect_key} ),
                          scope  => 'sub',
                          filter => $filter );
}


sub _fetch_assign_row {
    my ( $self, $field_list, $entry ) = @_;
    $log->is_info &&
        $log->info( "Setting data from row into", ref $self, "using DN of entry ", $entry->dn  );
    $self->clear_all_loaded();
    my $CONF = $self->CONFIG;
    $field_list ||= $self->field_list;
    foreach my $field ( @{ $field_list } ) {
        my @values = $entry->get_value( $field );
        if ( $CONF->{multivalue}{ $field } ) {
            $self->{ $field } = \@values;
            $log->is_info &&
                $log->info( sprintf( " ( multi) %-20s --> %s", $field, join( '||', @values ) ) );
        }
        else {
            $self->{ $field } = $values[0];
            $log->is_info &&
                $log->info( sprintf( " (single) %-20s --> %s", $field, $values[0] ) );
        }
        $self->set_loaded( $field );
    }
    $self->dn( $entry->dn );
    return $self;
}


sub _fetch_post_process {
    my ( $self, $p, $security_level ) = @_;

    # Create an entry for this object in the cache unless either the
    # class or this call to fetch() doesn't want us to.

    $self->set_cached_object( $p );

    # Execute any actions the class (or any parent) wants after
    # creating the object (see SPOPS.pm)

    return undef unless ( $self->post_fetch_action( $p ) );

    # Set object flags

    $self->clear_change;
    $self->has_save;

    # Set the security fetched from above into this object
    # as a temporary property (see SPOPS::Tie for more info
    # on temporary properties); note that this is set whether
    # we retrieve a cached copy or not

    $self->{tmp_security_level} = $security_level;
    $log->is_info &&
        $log->info( ref $self, "(", $self->id, ") : cache set (if available),",
                    "post_fetch_action() done, change flag cleared and save ",
                    "flag set. Security: $security_level" );
    return $self;
}


########################################
# SAVE
########################################

sub save {
    my ( $self, $p ) = @_;
    my $id = $self->id;
    $log->is_info &&
        $log->info( "Trying to save a (", ref $self, ") with ID ($id)" );

    # We can force save() to be an INSERT by passing in a true value
    # for the is_add parameter; otherwise, we rely on the flag within
    # SPOPS::Tie to reflect whether an object has been saved or not.

    my $is_add = ( $p->{is_add} or ! $self->saved );

    # If this is an update and it hasn't changed, we don't need to do
    # anything.

    unless ( $is_add or $self->changed ) {
        $log->is_info &&
            $log->info( "This object exists and has not changed. Exiting." );
        return $self;
    }

    # Check security for create/update

    my ( $level );
    unless ( $p->{skip_security} ) {
        $level = $self->check_action_security({ required => SEC_LEVEL_WRITE,
                                                is_add   => $is_add });
    }
    $log->is_info &&
        $log->info( "Security check passed ok. Continuing." );

    # Callback for objects to do something before they're saved

    return undef unless ( $self->pre_save_action({ %{ $p },
                                                   is_add => $is_add }) );

    # Do the insert/update based on whether the object is new; don't
    # catch the die() that might be thrown -- let that percolate

    if ( $is_add ) { $self->_save_insert( $p )  }
    else           { $self->_save_update( $p )  }

    # Do any actions that need to happen after you save the object

    return undef unless ( $self->post_save_action({ %{ $p },
                                                    is_add => $is_add }) );
    $log->is_info &&
        $log->info( "Post save action executed ok." );

    # Save the newly-created/updated object to the cache

    $self->set_cached_object( $p );

    # Note the action that we've just taken (opportunity for subclasses)

    my $action = ( $is_add ) ? 'create' : 'update';
    unless ( $p->{skip_log} ) {
        $self->log_action( $action, $self->id );
    }

    # Set object flags and we're done

    $self->has_save;
    $self->clear_change;
    return $self;
}


sub _save_insert {
    my ( $self, $p ) = @_;
    $p ||= {};
    $log->is_info &&
        $log->info( 'Treating save as INSERT' );
    my $ldap = $p->{ldap} || $self->global_datasource_handle( $p->{connect_key} );
    $self->dn( $self->build_dn );
    my $num_objectclass = ( ref $self->{objectclass} )
                            ? @{ $self->{objectclass} } : 0;
    if ( $num_objectclass == 0 ) {
        $self->{objectclass} = $self->ldap_object_class;
        $log->is_info &&
            $log->info( "Using object class from config in new object (",
                        join( ', ', @{ $self->{objectclass} } ), ")" );
    }
    $log->is_info &&
        $log->info( "Trying to create record with DN: (", $self->dn, ")" );
    my %insert_data = ();

    $p->{no_insert} ||= [];
    my $no_insert = $self->no_insert;
    map { $no_insert->{ $_ } = 1 } @{ $p->{no_insert} };
    $p->{skip_undef} ||= [];
    my $skip_undef = $self->skip_undef;
    map { $skip_undef->{ $_ } = 1 } @{ $p->{skip_undef} };

    foreach my $attr ( @{ $self->field_list } ) {
        next if ( $no_insert->{ $attr } );
        next if ( $skip_undef->{ $attr } and ! defined $self->{ $attr } );
        $insert_data{ $attr } = $self->{ $attr };

        # Trick LDAP to creating object with multivalue property that
        # has no values

        if ( ref $insert_data{ $attr } eq 'ARRAY'
             and scalar @{ $insert_data{ $attr } } == 0 ) {
            $insert_data{ $attr } = undef;
        }
    }
    $log->is_info &&
        $log->info( "Trying to create a record with:\n", Dumper( \%insert_data ) );
    my $ldap_msg = $ldap->add( dn   => $self->dn,
                               attr => [ %insert_data ]);
    $self->_check_error( $ldap_msg, 'save' );
    $log->is_info &&
        $log->info( "Record created ok." );
}


sub _save_update {
    my ( $self, $p ) = @_;
    $p ||= {};
    $log->is_info &&
        $log->info( "Treating save as UPDATE with DN: (", $self->dn, ")" );
    my $ldap = $p->{ldap} || $self->global_datasource_handle( $p->{connect_key} );
    my $entry = $self->_fetch_single_entry({ filter => $self->create_id_filter,
                                             ldap   => $ldap });
    $log->is_info &&
        $log->info( "Loaded entry for update:\n", Dumper( $entry ) );
    $p->{no_update} ||= [];
    my $no_update  = $self->no_update;
    map { $no_update->{ $_ } = 1 } @{ $p->{no_update} };
    $p->{skip_undef} ||= [];
    my $skip_undef = $self->skip_undef;
    map { $skip_undef->{ $_ } = 1 } @{ $p->{skip_undef} };

    my $only_changed = $self->ldap_update_only_changed;

ATTRIB:
    foreach my $attr ( @{ $self->field_list } ) {
        next ATTRIB if ( $no_update->{ $attr } );
        my $object_value = $self->{ $attr };
        next ATTRIB if ( $skip_undef->{ $attr } and ! defined $object_value );
        if ( $only_changed ) {
            my @existing_values = $entry->get_value( $attr );
            $log->is_info &&
                $log->info( "Toggle for updating only changed values set.",
                            "Checking if ($attr) different: ", Dumper( $object_value ),
                            "vs.", Dumper( \@existing_values ) );
            next ATTRIB if ( $self->_values_are_same( $object_value, \@existing_values ) );
            $log->is_info &&
                $log->info( "Values for ($attr) are different. Updating..." );
        }

        # Trick LDAP to updating object with multivalue property that
        # has no values

        if ( ref $object_value eq 'ARRAY' and scalar @{ $object_value } == 0 ) {
            $object_value = undef;
        }
        $entry->replace( $attr, $object_value );
    }
    $log->is_info &&
        $log->info( "Entry before Update:\n", Dumper( $entry ) );
    my $ldap_msg = $entry->update( $ldap );
    $self->_check_error( $ldap_msg, 'save' );
    $log->is_info &&
        $log->info( "Record updated ok." );
}


# Return true if the two values are the same, false if not.

sub _values_are_same {
    my ( $self, $val1, $val2 ) = @_;
    $val1 = ( ref $val1 ) ? $val1 : [ $val1 ];
    $val2 = ( ref $val2 ) ? $val2 : [ $val2 ];
    my %v1 = map { $_ => 1 } @{ $val1 };
    my %v2 = map { $_ => 1 } @{ $val2 };
    foreach my $field ( keys %v1 ) {
        return undef unless ( $v2{ $field } );
    }
    foreach my $field ( keys %v2 ) {
        return undef unless ( $v1{ $field } );
    }
    return 1;
}


########################################
# REMOVE
########################################

sub remove {
    my ( $self, $p ) = @_;

    # Don't remove it unless it's been saved already

    return undef   unless ( $self->is_saved );

    my $level = SEC_LEVEL_WRITE;
    unless ( $p->{skip_security} ) {
        $level = $self->check_action_security({ required => SEC_LEVEL_WRITE });
    }

    $log->is_info &&
        $log->info( "Security check passed ok. Continuing." );

    # Allow members to perform an action before getting removed

    return undef unless ( $self->pre_remove_action( $p ) );

    # Do the removal, building the where clause if necessary

    my $id = $self->id;
    my $dn = $self->dn;
    my $ldap = $p->{ldap} || $self->global_datasource_handle( $p->{connect_key} );;
    my $ldap_msg = $ldap->delete( $dn );
    $self->_check_error( $ldap_msg, 'remove' );

    # Otherwise...
    # ... remove this item from the cache

    if ( $self->use_cache( $p ) ) {
        $self->global_cache->clear({ data => $self });
    }

    # ... execute any actions after a successful removal

    return undef unless ( $self->post_remove_action( $p ) );

    # ... and log the deletion

    $self->log_action( 'delete', $id ) unless ( $p->{skip_log} );

    # Clear flags

    $self->clear_change;
    $self->clear_save;
    return 1;
}


########################################
# INTERNAL METHODS
########################################

# Error consolidation routine

sub _check_error {
    my ( $class, $ldap_msg, $action ) = @_;
    my $code = $ldap_msg->code;
    return undef unless ( $code );
    SPOPS::Exception::LDAP->throw(
               Net::LDAP::Util::ldap_error_desc( $code ),
               { code       => $code,
                 action     => $action,
                 error_name => Net::LDAP::Util::ldap_error_name( $code ),
                 error_text => Net::LDAP::Util::ldap_error_text( $code ) } );
}


# Build the full DN

sub build_dn {
    my ( $item, $p ) = @_;
    my $base_dn        = $p->{base_dn}  || $item->base_dn( $p->{connect_key} );
    my $id_field       = $p->{id_field} || $item->id_field;
    my $id_value_field = $p->{id_value_field} || $item->id_value_field;
    my $id_value       = $p->{id};
    unless ( $id_value ) {
        unless ( ref $item ) {
            SPOPS::Exception->throw(
                    "Cannot create DN for object without an ID value as " .
                    "parameter when called as class method" );
        }
        $id_value = $item->{ $id_value_field } || $item->id;
        unless ( $id_value ) {
            SPOPS::Exception->throw(
                    "Cannot create DN for object without an ID value" );
        }
    }
    unless ( $id_field and $id_value and $base_dn ) {
        SPOPS::Exception->throw(
                    "Cannot create Base DN without all parts: ",
                    "field: [$id_field]; ID: [$id_value]; BaseDN: [$base_dn]" );
    }
    return join( ',', join( '=', $id_field, $id_value ), $base_dn );
}

1;

__END__

=head1 NAME

SPOPS::LDAP - Implement object persistence in an LDAP datastore

=head1 SYNOPSIS

 use strict;
 use SPOPS::Initialize;

 # Normal SPOPS configuration

 my $config = {
    class      => 'My::LDAP',
    isa        => [ qw/ SPOPS::LDAP / ],
    field      => [ qw/ cn sn givenname displayname mail
                        telephonenumber objectclass uid ou / ],
    id_field   => 'uid',
    ldap_base_dn => 'ou=People,dc=MyCompany,dc=com',
    multivalue => [ qw/ objectclass / ],
    creation_security => {
                 u => undef,
                 g   => { 3 => 'WRITE' },
                 w   => 'READ',
    },
    track        => { create => 0, update => 1, remove => 1 },
    display      => { url => '/Person/show/' },
    name         => 'givenname',
    object_name  => 'Person',
 };

 # Minimal connection handling...

 sub My::LDAP::global_datasource_handle {
     my $ldap = Net::LDAP->new( 'localhost' );
     $ldap->bind;
     return $ldap;
 }

 # Create the class

 SPOPS::Initialize->process({ config => $config });

 # Search for a group of objects and display information

 my $ldap_filter = '&(objectclass=inetOrgPerson)(mail=*cwinters.com)';
 my $list = My::LDAP->fetch_group({ where => $ldap_filter });
 foreach my $object ( @{ $list } ) {
     print "Name: $object->{givenname} at $object->{mail}\n";
 }

 # The same thing, but with an iterator

 my $ldap_filter = '&(objectclass=inetOrgPerson)(mail=*cwinters.com)';
 my $iter = My::LDAP->fetch_iterator({ where => $ldap_filter });
 while ( my $object = $iter->get_next ) {
     print "Name: $object->{givenname} at $object->{mail}\n";
 }

=head1 DESCRIPTION

This class implements object persistence in an LDAP datastore. It is
similar to L<SPOPS::DBI|SPOPS::DBI> but with some important
differences -- LDAP gurus can certainly find more:

=over 4

=item *

LDAP supports multiple-valued properties.

=item *

Rather than tables, LDAP supports a hierarchy of data information,
stored in a tree. An object can be at any level of a tree under a
particular branch.

=item *

LDAP supports referrals, or punting a query off to another
server. (SPOPS does not support referrals yet, but we fake it with
L<SPOPS::LDAP::MultiDatasource|SPOPS::LDAP::MultiDatasource>.)

=back

=head1 CONFIGURATION

See L<SPOPS::Manual::Configuration|SPOPS::Manual::Configuration> for
the configuration fields used and LDAP-specific issues.

=head1 METHODS

=head2 Configuration Methods

See relevant discussion for each of these items under L<CONFIGURATION>
(configuration key name is the same as the method name).

B<base_dn> (Returns: $)

B<ldap_objectclass> (Returns: \@) (optional)

B<id_value_field> (Returns: $) (optional)

=head2 Datasource Methdods

B<global_datasource_handle( [ $connect_key ] )>

You need to create a method to return a datasource handle for use by
the various methods of this class. You can also pass in a handle
directory using the parameter 'ldap':

 # This object has a 'global_datasource_handle' method

 my $object = My::Object->fetch( 'blah' );

 # This object does not

 my $object = Your::Object->fetch( 'blah', { ldap => $ldap });

Should return: L<Net::LDAP|Net::LDAP> (or compatible) connection
object that optionally maps to C<$connect_key>.

You can configure your objects to use multiple datasources when
certain conditions are found. For instance, you can configure the
C<fetch()> operation to cycle through a list of datasources until an
object is found -- see
L<SPOPS::LDAP::MultiDatasource|SPOPS::LDAP::MultiDatasource> for an
example.

=head2 Class Initialization

B<class_initialize()>

Just create the 'field_list' configuration parameter.

=head2 Object Information

B<dn( [ $new_dn ] )>

Retrieves and potentially sets the DN (distinguished name) for a
particular object. This is done automatically when you call C<fetch()>
or C<fetch_group()> to retrieve objects so you can always access the
DN for an object. If the DN is empty the object has not yet been
serialized to the LDAP datastore. (You can also call the SPOPS method
C<is_saved()> to check this.)

Returns: DN for this object

B<build_dn()>

Builds a DN from an object -- you should never need to call this and
it might disappear in future versions, only to be used internally.

=head2 Object Serialization

Note that you can pass in the following parameters for any of these
methods:

=over 4

=item *

B<ldap>: A L<Net::LDAP|Net::LDAP> connection object.

=item *

B<connect_key>: A connection key to use for a particular LDAP
connection.

=back

B<fetch( $id, \%params )>

Retrieve an object with ID C<$id> or matching other specified
parameters.

Parameters:

=over 4

=item *

B<filter> ($)

Use the given filter to find an object. Note that the method will die
if you get more than one entry back as a result.

(Synonym: 'where')

=back

B<fetch_by_dn( $dn, \%params )>

Retrieve an object by a full DN (C<$dn>).

B<fetch_group( \%params )>

Retrieve a group of objects

B<fetch_iterator( \%params )>

Instead of returning an arrayref of results, return an object of class
L<SPOPS::Iterator::LDAP|SPOPS::Iterator::LDAP>.

Parameters are the same as C<fetch_group()>.

B<save( \%params )>

Save an LDAP object to the datastore. This is quite straightforward.

B<remove( \%params )>

Remove an LDAP object to the datastore. This is quite straightforward.

=head1 BUGS

B<Renaming of DNs not supported>

Moving an object from one DN to another is not currently supported.

=head1 TO DO

B<Documentation>

("This is quite straightforward" does not cut it.)

B<More Usage>

I have only tested this on an OpenLDAP (version 2.0.11) server. Since
we are using L<Net::LDAP|Net::LDAP> for the interface, we should (B<in
theory>) have no problems connecting to other LDAP servers such as
iPlanet Directory Server, Novell NDS or Microsoft Active Directory.

It would also be good to test with a wider variety of schemas and
objects.

B<Expand LDAP Interfaces>

Currently we use L<Net::LDAP|Net::LDAP> to interface with the LDAP
directory, but Perl/C libraries may be faster and provide different
features. Once this is needed, we will probably need to create
implementation-specific subclasses. This should not be very difficult
-- the actual calls to L<Net::LDAP|Net::LDAP> are minimal and
straightforward.

=head1 SEE ALSO

L<Net::LDAP|Net::LDAP>

L<SPOPS::Iterator::LDAP|SPOPS::Iterator::LDAP>

L<SPOPS|SPOPS>

=head1 COPYRIGHT

Copyright (c) 2001-2004 MSN Marketing Service Nordwest, GmbH. All rights
reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
