package VCP::Revs ;

=head1 NAME

VCP::Revs - A collection of VCP::Rev objects.

=head1 SYNOPSIS

=head1 DESCRIPTION

Right now, all revs are kept in memory, but we will enable storing them to
disk and recovering them at some point so that we don't gobble huge
tracts of RAM.

=head1 METHODS

=over

=cut

$VERSION = 1 ;

use strict ;

use VCP::Logger qw( BUG );
use VCP::Debug ":debug" ;
use VCP::Rev ;

use fields (
   'REVS',           ## The revs, sorted or not
   'BY_ID',          ## A HASH of revisions, indexed by ID
   'BY_NAME_BRANCH_ID', ## A HASH of revisions, indexed by name and branch_id

) ;


=item new

=cut

sub new {
   my $class = CORE::shift ;
   $class = ref $class || $class ;

   my $self ;

   {
      no strict 'refs' ;
      $self = bless [ \%{"$class\::FIELDS"} ], $class ;
   }

   $self->{REVS} = [] ;
   $self->{BY_ID} = {} ;

   return $self ;
}


=item add

   $revs->add( $rev ) ;
   $revs->add( $rev1, $rev2, ... ) ;

Adds a revision or revisions to the collection.

The ( name, rev_id, branch_id ) tuple must be unique, if a second rev
is C<add()>ed with the same values, an exception is thrown.

=cut

sub add {
   my VCP::Revs $self = CORE::shift ;

   Carp::confess "undef passed" if grep ! defined, @_;

   if ( debugging ) {
      debug "queuing ", $_->as_string for @_ ;
   }

   for my $r ( @_ ) {
      my $id = $r->id;

      ## CVS seems to allow multiple branch tags per branch
      ## so we can have multiple placeholder revs with the
      ## same name and rev_id.  Sigh.
      die "vcp: can't add same revision twice: '" . $r->as_string
         if $self->{BY_ID}->{$id} && ! $r->is_placeholder_rev;

      push @{$self->{REVS}}, $r ;
      $self->{BY_ID}->{$id} = $r ;
      $self->{BY_NAME_BRANCH_ID}->{$r->_name_branch_id} = $r;
   }
}


=item set

   $revs->set( $rev ) ;
   $revs->set( $rev1, $rev2, ... ) ;

Sets the list of revs.

=cut

sub set {
   my VCP::Revs $self = CORE::shift ;

   Carp::confess "undef passed" if grep !defined, @_;

   if ( debugging ) {
      require UNIVERSAL;
      BUG "unblessed ref passed" if grep !UNIVERSAL::can( $_, "as_string" ), @_;
      debug "queuing ", $_->as_string for @_ ;
   }

   @{$self->{REVS}} = @_ ;
}


=item get

   @revs = $revs->get ;        ## return a list of all revs
   $rev = $revs->get( $id ) ;  ## return the rev with a given ID (or die())

=cut

sub get {
   my VCP::Revs $self = CORE::shift ;

   return @{$self->{REVS}} unless @_;

   my ( $id ) = @_;

   Carp::confess "Could not find revision with id='$id'"
      unless exists $self->{BY_ID}->{$id};

   return $self->{BY_ID}->{$id};
}


=item get_last_added

   my $previous_r = $revs->get_last_added( $r );

Gets the last revision of the named file on this branch.  This is used
because most repositories output the most recent revision first, and
we need to point each revision at its preceding revision for branching
and for RevML to do diffs.

die()s unless a previous revision is found.

=cut

sub get_last_added {
   my VCP::Revs $self = shift;
   my ( $r ) = @_;

   my $nb = $r->_name_branch_id;

   die "Could not find revision with name(branch_id)='$nb'\n"
      unless exists $self->{BY_NAME_BRANCH_ID}->{$nb};
   $self->{BY_NAME_BRANCH_ID}->{$nb};
}


=item sort

   # Using a custom sort function:
   $revs->sort( sub { ... } ) ;

Note: Don't use $a and $b in your sort function.  They're package globals
and that's not your package.  See L<VCP::Dest/rev_cmp_sub> for more details.

=cut

sub sort {
   my VCP::Revs $self = CORE::shift ;

   my ( $sort_func ) = @_ ;

   @{$self->{REVS}} = sort $sort_func, @{$self->{REVS}} ;
}


=item remove_all

Returns and removes all as an array reference.
A lot faster than ->shift()ing them out.

=cut

sub remove_all {
   my VCP::Revs $self = CORE::shift ;

   my $revs = $self->{REVS};
   $self->{REVS} = [];
   %{$self->{BY_ID}} = ();
   %{$self->{BY_NAME_BRANCH_ID}} = ();
   return $revs;
}


=item as_array_ref

Returns an ARRAY ref of all revs.

=cut

sub as_array_ref {
   my VCP::Revs $self = CORE::shift ;

   return $self->{REVS} ;
}

## I put the file fetching stuff here in case we ever need to handle
## multiple sources at the same time (this means we want to encapsulate
## this functionality) or allow VCP::Revs to write metadata to disk
## (which means that VCP::Revs might need to do some sort of query).

=item set_file_fetcher

   VCP::Revs->set_file_fetcher( $self );
   VCP::Revs->set_file_fetcher( undef );


Sets/clears the object responsible for fetching files.

This is called from VCP::Source::*

=cut

my $file_fetcher;

sub set_file_fetcher { $file_fetcher = $_[1] }

=item fetch_files

    my @fns = VCP::Revs->fetch_files( @revs );

Fetch the files for one or more revs and return the paths to those files.

@source_fns will be in the same order as @revs.  It is an error to
attempt to fetch an unfetchable file (like a placeholder).

You may call fetch_files once for each file but calling it for a batch
of files may allow some sources to operate more efficiently.  Setting
the dest_work_path for the file may also allow some sources to just
create the file in place for you, which you should check for by seeing
if the filename returned is the same as the dest_work_path.  Not
setting the dest_work_path will prevent this; the source will pick
a filename for the dest.

Dies if called in a scalar or void context.

=cut

## This just encapsulates the VCP::Source method for now.  Later it
## might do more.

sub fetch_files {
   Carp::confess( "fetch_files() not called in list context" )
      unless wantarray;
   shift;
   $file_fetcher->fetch_files( @_ );
}

=back

=head1 SUBCLASSING

This class uses the fields pragma, so you'll need to use base and 
possibly fields in any subclasses.

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1
