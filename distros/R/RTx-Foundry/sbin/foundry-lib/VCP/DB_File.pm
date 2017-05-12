package VCP::DB_File;

=head1 NAME

VCP::DB_File - Persistant storage for id -> (name, rev_id) maps

=head1 SYNOPSIS

    use base qw( VCP::DB_File );

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

To write your own ", ref $self, " file, see VCP::DB_File::sdbm.

=for test_script t/01db_file.t

=cut

$VERSION = 1 ;

use strict ;
use Carp;
use VCP::Debug qw( :debug );
use VCP::Utils qw( start_dir );

use fields (
   'StoreLoc',   ## Where the data should be kept.
   'TableName',  ## database table name
);

=head2 Methods

=over

=cut

=item new

   VCP::DB_File::foo->new(
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

   while ( my ( $key, $value ) = each %options ) {
      $self->{$key} = $value;
   }

   Carp::confess "undefined TableName" unless defined $self->{TableName};

   $self->{StoreLoc} = "vcp_state"
      unless defined $self->{StoreLoc};

   $self->{StoreLoc} = File::Spec->rel2abs(
      File::Spec->catdir( $self->{StoreLoc}, $self->{TableName} ),
      start_dir
   );

   debug "storing ", ref $self, " in ", $self->store_loc
      if debugging;

   return $self ;
}

=item store_loc

Gets (does not set) the StoreLoc field as an absolute path.

=cut

sub store_loc {
   my VCP::DB_File $self = shift;
   return $self->{StoreLoc};
}

=item delete_db

   $db->delete_db;

Deletes the persitent store.  This should remove all files, lock files,
etc.  for filesystem stores and drop any tables for RDBMS stores.

Default action is to call close_db; subclasses should

(subclasses should call C<$self->SUPER::delete_db before doing anything
else in their delete_db() overrides).

=cut

sub delete_db {
   my VCP::DB_File $self = shift;

   $self->close_db;
   debug "deleting ", ref $self, " in ", $self->store_loc if debugging;
}


=item open_db

   $db->open_db;

Creates a new or opens an existing db.

(subclasses should call C<$self->SUPER::open_db before doing anything
else in their open_db() overrides).

=cut

sub open_db {
   my VCP::DB_File $self = shift;
   debug "opening ", ref $self, " in ", $self->store_loc if debugging;
}

=item close_db

   $db->close_db;

(subclasses should call C<$self->SUPER::close_db before doing anything
else in their close_db() overrides).

=cut

sub close_db {
   my VCP::DB_File $self = shift;
   debug "closing ", ref $self, " in ", $self->store_loc if debugging;
}

=item set

   $db->set( $key, @values );

Sets the values for $key.

=cut

=item get

   my @values = $db->get( $key );

Gets the values for $key.

=cut

=back

=head1 HELPER METHODS

These are provided to make subclassing a tad easier

=over

=cut

=item mkdir_store_loc

   $self->mkdir_store_loc;

A helper method for subclasses' open_db()s to create the directory
referred to by store_loc and any missing parent dirs.

=cut

sub mkdir_store_loc {
   my VCP::DB_File $self = shift;

   return if -e $self->store_loc;

   debug "making dir ", $self->store_loc
      if debugging;

   require File::Path;
   File::Path::mkpath( [ $self->store_loc ] );
}

=item rmdir_store_loc

   $self->rmdir_store_loc;

A helper method for subclasses' delete_db()s to remove the directory
referred to by store_loc.

=cut

sub rmdir_store_loc {
   my VCP::DB_File $self = shift;

   return unless -e $self->store_loc;

   require File::Path;
   File::Path::rmtree( [ $self->store_loc ] );
}

=item pack_values

   my $v = $self->pack_values( @values );

Combines the parameters in to a single string.

=cut

sub pack_values {
   shift;
   confess "no values to pack" unless @_;
   confess "can't pack undef" if grep !defined, @_;
   join ";", map { my $v = $_; $v =~ s/%/%%/g; $v =~ s/;/%,/; $v } @_;
}

=item upack_values

   my @v = $self->unpack_values( $v );

=cut

sub unpack_values {
   shift;
   confess unless @_ == 1;
   my @v = split /;/, "$_[0];", -1;
   pop @v;
   @v = map { s/%%/%/g; s/%,/;/g; $_ } @v;
   return @v;
}



=back

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
