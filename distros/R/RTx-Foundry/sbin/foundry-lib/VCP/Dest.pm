package VCP::Dest ;

=head1 NAME

VCP::Dest - A base class for VCP destinations

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXTERNAL METHODS

=over

=for test_scripts t/01sort.t

=cut

use strict ;

use Carp ;
use File::Spec ;
use File::Spec::Unix ;
use UNIVERSAL qw( isa ) ;
use VCP::Revs ;
use VCP::Debug qw(:debug) ;
use VCP::Logger qw( pr );
use VCP::Utils qw( start_dir escape_filename empty );

use vars qw( $VERSION $debug ) ;

$VERSION = 0.1 ;

$debug = 0 ;

use base 'VCP::Plugin' ;

use fields (
   'DEST_HEADER',          ## Holds header info until first rev is seen.
#   'DEST_SORT_KEYS',       ## HASH of sort keys, indexed by name and rev.
#   'DEST_COMMENT_TIMES',   ## The average time of all instances of a comment
#   'DEST_DEFAULT_COMMENT', ## The comment to use when a comment is undefined
#                           ## This is used when presorting/merging so
#                           ## that comment will still be used to
#                           ## compare when selecting the next rev to
#                           ## merge, otherwise it would be removed as
#                           ## a sporadic field.

   'DEST_HEAD_REVS',       ## Map of head revision on each branch of each file
   'DEST_REV_MAP',         ## Map of source rev id to destination file & rev
   'DEST_MAIN_BRANCH_ID',  ## Container of main branch_id for each file
   'DEST_FILES',           ## Map of files->state, for CVS' sake
   'DEST_DB_DIR',          ## Directory name in which to store the transfer
                           ## state databases
);

use VCP::Revs ;


=item new

Creates an instance, see subclasses for options.  The options passed are
usually native command-line options for the underlying repository's
client.  These are usually parsed and, perhaps, checked for validity
by calling the underlying command line.

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Dest $self = $class->SUPER::new( @_ ) ;

   ## rev_id is here in case the change id isn't,
   ## name is here for VSS deletes, which have no other data.

   return $self ;
}

=back


###############################################################################

=head1 SUBCLASSING

This class uses the fields pragma, so you'll need to use base and 
possibly fields in any subclasses.

=head2 SUBCLASS API

These methods are intended to support subclasses.

=over


=item parse_options

    $self->parse_options( \@options, @specs );

Parses common options.

=cut

sub parse_options {
   my VCP::Dest $self = shift;

   $self->SUPER::parse_options( 
      @_,
      "db-dir=s"  => sub { $self->db_dir( $_[1] ) },
   );

   if( ! empty $self->db_dir && empty $self->repo_id ) {
      pr "--repo-id required if --db-dir present";
      $self->usage_and_exit ;
   }
}


=item digest

    $self->digest( "/tmp/readers" ) ;

Returns the Base64 MD5 digest of the named file.  Used to compare a base
rev (which is the revision *before* the first one we want to transfer) of
a file from the source repo to the existing head rev of a dest repo.

The Base64 version is returned because that's what RevML uses and we might
want to cross-check with a .revml file when debugging.

=cut

sub digest {
   shift ;  ## selfless little bugger, isn't it?
   my ( $path ) = @_ ;

   require Digest::MD5 ;
   my $d= Digest::MD5->new ;
   open DEST_P4_F, "<$path" or die "$!: $path" ;
   $d->addfile( \*DEST_P4_F ) ;

   my $digest = $d->b64digest ;
   close DEST_P4_F ;
   return $digest ;
}


=item compare_base_revs

   $self->compare_base_revs( $rev ) ;

Checks out the indicated revision from the destination repository and
compares it (using digest()) to the file from the source repository
(as indicated by $rev->work_path). Dies with an error message if the
base revisions do not match.

Calls $self->checkout_file( $rev ), which the subclass must implement.

=cut

sub compare_base_revs {
   my VCP::Dest $self = shift ;
   my ( $rev, $source_path ) = @_ ;

   ## This line is a bandaid until we fully cut over to using fetch_files(),
   ## at which point work_path will no longer be needed.
   $source_path = $rev->work_path unless defined $source_path;

   ## This block should only be run when transferring an incremental rev.
   ## from a "real" repo.  If it's from a .revml file, the backfill will
   ## already be done for us.
   ## Grab it and see if it's the same...
   my $backfilled_path = $self->checkout_file( $rev );

   my $source_digest = $self->digest( $source_path ) ;
   my $dest_digest     = $self->digest( $backfilled_path );

   die( "vcp: base revision\n",
       $rev->as_string, "\n",
       "differs from the last version in the destination p4 repository.\n",
       "    source digest: $source_digest (in ", $source_path, ")\n",
       "    dest. digest:  $dest_digest (in ", $backfilled_path, ")\n"
   ) unless $source_digest eq $dest_digest ;
}


=item header

Gets/sets the $header passed to handle_header().

Generally not overridden: all error checking is done in new(), and
no output should be generated until output() is called.

=cut

sub header {
   my VCP::Dest $self = shift ;
   $self->{DEST_HEADER} = shift if @_ ;
   return $self->{DEST_HEADER} ;
}


=item db_dir

Set or return the directory name where the transfer state databases
are stored.

This is the directory to store the state information for this transfer
in.  This includes the mapping of source repository versions
(name+rev_id, usually) to destination repository versions and the
status of the last transfer, so that incremental transfers may restart
where they left off.

=cut

sub db_dir {
   my VCP::Dest $self = shift ;
   
   $self->{DEST_DB_DIR} = shift if @_;
   return $self->{DEST_DB_DIR};
}

=item _db_store_location

Determine the location to store the transfer state databases.

Uses the absolute path provided by the --db-dir option if present,
else use directory 'vcp_state' in the directory the program was
started in.  The file name is an escaped repo_id.

=cut

sub _db_store_location {
   my VCP::Dest $self = shift ;

   my $loc = $self->db_dir;
   $loc = ( empty $loc )
      ? File::Spec->catdir( start_dir, "vcp_state" )
      : File::Spec::Unix->rel2abs( $loc, start_dir ) ;

   return File::Spec->catfile( $loc, escape_filename $self->repo_id );
}

=item rev_map

Set or return a reference to the RevMapDB in use.

=cut

sub rev_map {
   my VCP::Dest $self = shift ;
   
   $self->{DEST_REV_MAP} ||= do {
      require VCP::RevMapDB;
      VCP::RevMapDB->new( 
         StoreLoc => $self->_db_store_location,
      );
   };
}

=item head_revs

Set or return a reference to the HeadRevsDB in use.

=cut

sub head_revs {
   my VCP::Dest $self = shift ;
   
   $self->{DEST_HEAD_REVS} ||= do {
      require VCP::HeadRevsDB;

      $self->{DEST_HEAD_REVS} = VCP::HeadRevsDB->new( 
         StoreLoc => $self->_db_store_location,
      );
   };
}

=item main_branch_id

Set or return a reference to the MainBranchIdDB in use.

=cut

sub main_branch_id {
   my VCP::Dest $self = shift;
   
   $self->{DEST_MAIN_BRANCH_ID} ||= do {
      require VCP::MainBranchIdDB;
      $self->{DEST_MAIN_BRANCH_ID} = VCP::MainBranchIdDB->new(
         StoreLoc => $self->_db_store_location,
      );
   };
}

=item files

Set or return a reference to the HeadRevsDB in use.

=cut

sub files {
   my VCP::Dest $self = shift ;
   
   $self->{DEST_FILES} ||= do {
      require VCP::FilesDB;
      $self->{DEST_FILES} = VCP::FilesDB->new(
         StoreLoc => $self->_db_store_location,
      );
   }
}

=back

=head2 SUBCLASS OVERLOADS

These methods are overloaded by subclasses.

=over

=item backfill

   $dest->backfill( $rev ) ;

Checks the file indicated by VCP::Rev $rev out of the target repository if
this destination supports backfilling.  Currently, only the revml destination
does not support backfilling.

The $rev->workpath must be set to the filename the backfill was put
in.

This is used when doing an incremental update, where the first revision of
a file in the update is encoded as a delta from the prior version.  A digest
of the prior version is sent along before the first version delta to
verify it's presence in the database.

So, the source calls backfill(), which returns TRUE on success, FALSE if the
destination doesn't support backfilling, and dies if there's an error in
procuring the right revision.

If FALSE is returned, then the revisions will be sent through with no
working path, but will have a delta record.

MUST BE OVERRIDDEN.

=cut

sub backfill {
   my VCP::Dest $self = shift ;
   my ( $r ) = @_;

   die ref( $self ) . "::checkout_file() not found for ", $r->as_string, "\n"
      unless $self->can( "checkout_file" );

   my $work_path = $self->checkout_file( $r );

   link $work_path, $r->work_path
      or die "$! linking $work_path to ", $r->work_path;
   unlink $work_path or die "$! unlinking $work_path";
}


=item handle_footer

   $dest->handle_footer( $footer ) ;

Does any cleanup necessary.  Not required.  Don't call this from the override.

=cut

sub handle_footer {
   my VCP::Dest $self = shift ;
   return ;
}

=item handle_header

   $dest->handle_header( $header ) ;

Stows $header in $self->header.  This should only rarely be overridden,
since the first call to handle_rev() should output any header info.

=cut

sub handle_header {
   my VCP::Dest $self = shift ;

   my ( $header ) = @_ ;

   $self->header( $header ) ;

   return ;
}

=item handle_rev

   $dest->handle_rev( $rev ) ;

Outputs the item referred to by VCP::Rev $rev.  If this is the first call,
then $self->none_seen will be TRUE and any preamble should be emitted.

MUST BE OVERRIDDEN.  Don't call this from the override.

=cut

=item last_rev_in_filebranch

   my $rev_id = $dest->last_rev_in_filebranch(
      $source_repo_id,
      $source_filebranch_id
   );

Returns the last revision for the file and branch indicated by
$source_filebranch_id.  This is used to support --continue.

Returns undef if not found.

=cut

sub last_rev_in_filebranch {
   my VCP::Dest $self = shift;
   return 0 unless defined $self->{DEST_HEAD_REVS};
   return ($self->head_revs->get( \@_ ))[0];
}

=back


=head1 NOTES

Several fields are jury rigged for "base revisions": these are fake
revisions used to start off incremental, non-bootstrap transfers with
the MD5 digest of the version that must be the last version in the
target repository.  Since these are "faked", they don't contain
comments or timestamps, so the comment and timestamp fields are treated as
"" and 0 by the sort routines.

There is a special sortkey C<avg_comment_time> that allows revisions within
the same time period (second, minute, day) to be sorted according to the
average time of the comment for the revision (across all revisions with
that comment).  This causes changes that span more than one time period
to still be grouped properly.

=cut

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1
