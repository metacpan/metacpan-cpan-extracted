package SPOPS::GDBM;

# $Id: GDBM.pm,v 3.4 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base  qw( SPOPS );
use Log::Log4perl qw( get_logger );
use Data::Dumper  qw( Dumper );
use GDBM_File;
use SPOPS;
use SPOPS::Exception qw( spops_error );

my $log = get_logger();

$SPOPS::GDBM::VERSION = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

# Make this the default for everyone -- they can override it
# themselves...

sub class_initialize {
    my ( $class, $CONFIG ) = @_;
    $class->_class_initialize( $class->CONFIG ); # allow subclasses to do their own thing

    # Turn off warnings in this block so we don't get the 'subroutine
    # id redefined' message (yes, we know what we're doing)

    {
        no strict 'refs';
        local $^W = 0;
        *{ $class . '::id' } = \&id;
    }
    return 1;
}

# Dummy for subclasses to override

sub _class_initialize { return 1 }

# Override the default SPOPS initialize call so we can use mixed-case
# fields

sub initialize {
    my ( $self, $p ) = @_;
    return unless ( ref $p and scalar keys %{ $p } );

    # Set the GDBM filename if it was passed

    if ( $p->{GDBM_FILENAME} ) {
        $self->{tmp_gdbm_filename} = $p->{GDBM_FILENAME};
        delete $p->{GDBM_FILENAME};
    }

    # We allow the user to substitute id => value instead for the
    # specific fieldname.

    if ( my $id = $p->{id} ) {
        $p->{ $self->id_field } ||= $id;
        delete $p->{id};
    }

    # Go through the field list and set any that are passed in

    foreach my $field ( @{ $self->field_list } ) {
        next unless ( $p->{ $field } );
        $self->{ $field } = $p->{ $field };
        $log->is_debug &&
            $log->debug( "Initialized [$field] to [$self->{ $field }]" );
    }
    return $self;
}

# Override this to get the db handle from somewhere else, if necessary

sub global_gdbm_tie {
    my $item = shift;
    return $item->global_datasource_handle( @_ );
}

sub global_datasource_handle {
    my ( $item, $p ) = @_;
    return $p->{db}    if ( ref $p->{db} );

    my $gdbm_filename = $p->{filename};
    unless ( $gdbm_filename ) {
        if ( ref $item ) {
            $gdbm_filename   = $item->{tmp_gdbm_filename};
        }
        if ( $item->CONFIG->{gdbm_info}{file_fragment} and $p->{directory} ) {
            $log->is_info &&
                $log->info( "Found file fragent and directory" );
            $gdbm_filename ||= join( '/', $p->{directory},
                                          $item->CONFIG->{gdbm_info}{file_fragment} );
        }
        $gdbm_filename ||= $item->CONFIG->{gdbm_info}{filename};
        $gdbm_filename ||= $item->global_config->{gdbm_info}{filename};
    }
    $log->is_info &&
        $log->info( "Trying file ($gdbm_filename) to connect" );
    unless ( $gdbm_filename ) {
        spops_error "Insufficient/incorrect information to tie to ",
                    "GDBM file [$gdbm_filename]";
    }

    $log->is_debug &&
        $log->debug( "Beginning perm: ", defined( $p->{perm} ) ? $p->{perm} : '' );
    $p->{perm}   = 'create' unless ( -e $gdbm_filename );
    $p->{perm} ||= 'read';
    $log->is_debug &&
        $log->debug( "Final perm: $p->{perm}" );

    my $perm = GDBM_File::GDBM_READER;
    $perm    = GDBM_File::GDBM_WRITER  if ( $p->{perm} eq 'write' );
    $perm    = GDBM_File::GDBM_WRCREAT if ( $p->{perm} eq 'create' );
    $log->is_info &&
        $log->info( "Trying to use perm ($perm) to connect" );
    my %db = ();
    tie( %db, 'GDBM_File', $gdbm_filename, $perm, 0666 );
    if ( $p->{perm} eq 'create' && ! -w $gdbm_filename ) {
        spops_error "Failed to create GDBM file! [$gdbm_filename]";
    }

    return \%db;
}

# Override the SPOPS method for finding ID values

sub id {
    my ( $self ) = @_;
    if ( my $id_field = $self->id_field ) {
        return $self->{ $id_field };
    }
    return $self->CONFIG->{create_id}->( $self );
}


sub object_key {
    my ( $self, $id ) = @_;
    $id ||= $self->id  if ( ref $self );
    unless ( $id ) {
        spops_error "Cannot create object key without object or id!";
    }
    my $class = ref $self || $self;
    return join( '--', $class, $id );
}


# Given a key, return the data structure from the db file

sub _return_structure_for_key {
    my ( $class, $key, $p ) = @_;
    my $db    = $class->global_datasource_handle( $p );
    my $item_info = $db->{ $key };
    return undef unless ( $item_info );
    my $data = undef;
    {
        no strict 'vars';
        $data = eval $item_info;
    }
    if ( $@ ) {
        spops_error "Cannot rebuild object! Error: $@";
    }
    return $data;
}


# Retreive an object

sub fetch {
    my ( $class, $id, $p ) = @_;
    $log->is_debug &&
        $log->debug( "Trying to fetch ID ($id)" );
    my $data = $p->{data} || {};
    unless ( scalar keys %{ $data } ) {
        return undef unless ( $id and $id !~ /^tmp/ );
        return undef unless ( $class->pre_fetch_action( { id => $id } ) );
        $data = $class->_return_structure_for_key( $class->object_key( $id ),
                                                   { filename  => $p->{filename},
                                                     directory => $p->{directory} } );
        $log->is_debug &&
            $log->debug( "Returned data from GDBM: ", Dumper( $data ) );
    }
    my $obj = $class->new({ %{ $data }, skip_default_values => 1 });
    $obj->clear_change;
    return undef unless ( $class->post_fetch_action );
    return $obj;
}

# Return all objects in a particular class

sub fetch_group {
    my ( $item, $p ) = @_;
    my $db = $item->global_datasource_handle( $p );
    my $class = ref $item || $item;
    $log->is_info &&
        $log->info( "Trying to find keys beginning with ($class)" );
    my @object_keys = grep /^$class/, keys %{ $db };
    $log->is_debug &&
        $log->debug( "Keys found in DB: ", join( ", ", @object_keys ) );
    my @objects = ();
    foreach my $key ( @object_keys ) {
        my $data = eval { $class->_return_structure_for_key( $key, { db => $db } ) };
        next unless ( $data );
        push @objects, $class->fetch( undef, { data => $data } );
    }
    return \@objects;
}

# Save (either insert or update) an item in the db

sub save {
    my ( $self, $p ) = @_;
    $p->{perm} ||= 'write';
    $log->is_info &&
        $log->info( "Trying to save a <<", ref $self, ">>" );
    my $id = $self->id;
    my $is_add = ( $p->{is_add} or ! $id or $id =~ /^tmp/ );
    unless ( $is_add or $self->changed ) {
        $log->is_info &&
            $log->info( "This object exists and has not changed. Exiting." );
        return $id;
    }
    return undef unless ( $self->pre_save_action( { is_add => $is_add } ) );

    # Build the data and dump to string

    my %data = %{ $self };
    local $Data::Dumper::Indent = 0;
    my $obj_string = Data::Dumper->Dump( [ \%data ], [ 'data' ] );

    # Save to DB

    my $obj_index  = $self->object_key;
    my $db = $self->global_datasource_handle( $p );
    $db->{ $obj_index } = $obj_string;

    return undef unless ( $self->post_save_action( { is_add => $is_add } ) );
    $self->clear_change;
    return $self;
}

# Remove an item from the db

sub remove {
    my ( $self, $p ) = @_;
    my $obj_index  = $self->object_key;
    my $db = $self->global_datasource_handle({ perm => 'write', %{ $p } });
    $self->clear_change;
    $self->clear_save;
    return delete $db->{ $obj_index };
}

1;

__END__

=head1 NAME

SPOPS::GDBM - Store SPOPS objects in a GDBM database

=head1 SYNOPSIS

 my $obj = Object::Class->new;
 $obj->{parameter1} = 'this';
 $obj->{parameter2} = 'that';
 my $id = $obj->save;

=head1 DESCRIPTION

Implements SPOPS persistence in a GDBM database. Currently the
interface is not as robust or powerful as the L<SPOPS::DBI|SPOPS::DBI>
implementation, but if you want more robust data storage, retrieval
and searching needs you should probably be using a SQL database
anyway.

This is also a little different than the L<SPOPS::DBI|SPOPS::DBI>
module in that you have a little more flexibility as to how you refer
to the actual GDBM file required. Instead of defining one database
throughout the operation, you can change in midstream. (To be fair,
you can also do this with the L<SPOPS::DBI|SPOPS::DBI> module, it is
just a little more difficult.) For example:

 # Read objects from one database, save to another
 my @objects = Object::Class->fetch_group({ filename => '/tmp/object_old.gdbm' });
 foreach my $obj ( @objects ) {
     $obj->save({ is_add => 1, gdbm_filename => '/tmp/object_new.gdbm' });
 }

=head1 METHODS

B<id_field>

If you want to define an ID field for your class, override this. Can
be a class or object method.

B<class_initialize>

Much the same as in DBI. (Nothing interesting.)

B<initialize( \%params )>

Much the same as in DBI, although you are able to initialize an object
to use a particular filename by passing a value for the
'GDBM_FILENAME' key in the hashref for parameters when you create a
new object:

 my $obj = Object::Class->new( { GDBM_FILENAME = '/tmp/mydata.gdbm' } );

B<global_datasource_handle( \%params )>

Returns a tied hashref if successful.

Note: This is renamed from C<global_gdbm_tie()>. The old method will
still work for a while.

There are many different ways of creating a filename used for
GDBM. You can define a default filename in your package configuration;
you can pass it in with every request (using the parameter
'filename'); you can define a file fragment (non-specific directory
name plus a filename, like 'conf/package.gdbm') and then pass a
directory to anchor the filename with every request.

Parameters:

=over 4

=item *

B<perm> ($) (default 'read')

Defines the permissions to open the GDBM file. GDBM recognizes three
permissions: 'GDBM_READER', 'GDBM_WRITER', 'GDBM_WRCREAT' (for
creating and having write access to the file). You only need to pass
'read', 'write', or 'create' instead of these constants.

If you pass nothing, L<SPOPS::GDBM|SPOPS::GDBM> will assume
'read'. Also note that on some GDBM implementations, specifying
'write' permission to a file that has not yet been created still
creates it, so 'create' might be redundant on your system.

B<filename> ($) (optional)

Filename to use. If it is not passed, we look into the
'tmp_gdbm_filename' field of the object, and then the 'filename' key
of the 'gdbm_info' key of the class config, and then the 'filename'
key of the 'gdbm_info' key of the global configuration.

B<directory> ($) (optional)

Used if you have defined 'file_fragment' within your package
configuration; we join the directory and filename with a '/' to create
the gdbm filename.

=back

B<id()>

If you have defined a routine that returns the 'id_field' of an
object, it returns the value of that for a particular
object. Otherwise it executes the coderef found in the 'create_id' key
of the class configuration for the object. Usually this is something
quite simple:

 ...
 'create_id' => sub { return join( '--', $_[0]->{name}, $_[0]->{version} ) }
 ...

In the config file just joins the 'name' and 'version' parameters of
an object and returns the result.

B<object_key>

Creates a key to store the object in GDBM. The default is to prepend
the class to the value returned by I<id()> to prevent ID collisions
between objects in different classes. But you can make it anything you
want.

B<fetch( $id, \%params >

Retrieve a object from a GDBM database. Note that $id corresponds
B<not> to the object key, or the value used to store the data. Instead
it is a unique identifier for objects within this class.

You can pass normal db parameters.

B<fetch_group( \%params )>

Retrieve all objects from a GDBM database from a particular class. If
you modify the 'object_key' method, you will probably want to modify
this as well.

You can pass normal db parameters.

B<save( \%params )>

Save (either insert or update) an object in a GDBM database.

You can pass normal db parameters.

B<remove( \%params )>

Remove an object from a GDBM database.

You can pass normal db parameters.

=head2 Private Methods

B<_return_structure_for_key( \%params )>

Returns the data structure in the GDBM database corresponding to a
particular key. This data structure is B<not> blessed yet, it is
likely just a hashref of data (depending on how you implement your
objects, although the default method for SPOPS objects is a tied
hashref).

This is an internal method, so do not use it.

You can pass normal db parameters.

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 SEE ALSO

GDBM software:

 http://www.fsf.org/gnulist/production/gdbm.html

GDBM on Perl/Win32:

 http://www.roth.net/perl/GDBM/

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>

See the L<SPOPS|SPOPS> module for the full author/helper list.
