package VCP::DB;

=head1 NAME

VCP::DB - Persistant storage for id -> (name, rev_id) maps

=head1 SYNOPSIS

    use base qw( VCP::DB );

=head1 DESCRIPTION

By default, most VCP::Dest::* drivers keep track of the relationship
between the id field assigned by the (original) VCP::Source::* driver
and the final name and rev_id (or whatever fields are important to it)
in the destination repository so that the previous_id fields, which
refer to the original id, may be resolved when backfilling or branching.

The VCP::*::revml drivers do not do this; they do not need to resolve id
fields.

The intent for this file is to serve as a base class so that individual
sites may write their own ", ref $self, " plugins to, for instance, store this
state in a RDBMS table.  This is not quite offered at this time; we need
to add an option to the appropriate VCP::Dest::* modules to allow the
appropriate ", ref $self, " file to be loaded.

To write your own ", ref $self, " file, see VCP::DB::sdbm.

=for test_script t/01db_file.t

=cut

$VERSION = 1 ;

use strict ;
use Carp;
use VCP::Debug qw( :debug );
use VCP::Utils qw( start_dir );

use fields (
   'Store',      ## object used to store the database
);

=head2 Methods

=over

=cut

=item new

   VCP::DB::foo->new(
      StoreLoc => $dir,  ## path to a dir to keep the state store in
   );

The C<Store> field indicates where the ", ref $self, " should be stored, for
instance a DBI specification string or a directory to place a
"revmap.db" file in.  There is no control over the filename, as
different storage modes may need different conventions.

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my %options = @_;
   my $type = delete $options{Type} || "sdbm";

   my $self = do {
      no strict 'refs' ;
      bless [ \%{"${class}::FIELDS"} ], $class;
   };

   $self->{Store} ||= do {
      my $try_type = "VCP::DB_File::$type";
      eval "require $try_type"
         ? $type = $try_type
         : (
            eval "require $type;"
            || Carp::confess
               "Could not load VCP::DB_File subclass $type for $options{TableName}"
         );

      $type->new( @_ );
   };

   return $self ;
}

=item store_loc

Gets (does not set) the StoreLoc field as an absolute path.

=cut

sub store_loc { shift->{Store}->store_loc( @_ ) }

=item delete_db

   $db->delete_db;

Deletes the persitent store.  This should remove all files, lock files,
etc.  for filesystem stores and drop any tables for RDBMS stores.

Default action is to call close_db; subclasses should

(subclasses should call C<$self->SUPER::delete_db before doing anything
else in their delete_db() overrides).

=cut

sub delete_db { shift->{Store}->delete_db( @_ ) }

=item open_db

   $db->open_db;

Creates a new or opens an existing db.

(subclasses should call C<$self->SUPER::open_db before doing anything
else in their open_db() overrides).

=cut

sub open_db { shift->{Store}->open_db( @_ ) }

=item open_existing_db

   $db->open_existing_db;

Opens an existing db.

(subclasses should call C<$self->SUPER::open_existing_db before doing anything
else in their open_existing_db() overrides).

=cut

sub open_existing_db { shift->{Store}->open_existing_db( @_ ) }

=item close_db

   $db->close_db;

(subclasses should call C<$self->SUPER::close_db before doing anything
else in their close_db() overrides).

=cut

sub close_db { shift->{Store}->close_db( @_ ) }

=item set

   $db->set( $key, @values );

Sets the values for $key.

=cut

sub set { shift->{Store}->set( @_ ) }

=item get

   my @values = $db->get( $key );

Gets the values for $key.

=cut

sub get { shift->{Store}->get( @_ ) }

=item exists

   $db->exists( $key );

Tests that key exists

=cut

sub exists { shift->{Store}->exists( @_ ) }


=item dump

   $db->dump( \*STDOUT );
   my $s = $db->dump;
   my @l = $db->dump;

Dumps keys and values from a DB, in lexically sorted key order.
If a filehandle reference is provided, prints to that filehandle.
Otherwise, returns a string or array containing the entire dump,
depending on context.


=cut

sub dump { shift->{Store}->dump( @_ ) }




=back

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
