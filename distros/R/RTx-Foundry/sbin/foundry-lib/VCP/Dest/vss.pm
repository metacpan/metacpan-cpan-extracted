package VCP::Dest::vss ;

=head1 NAME

VCP::Dest::vss - vss destination driver

=head1 SYNOPSIS

   vcp <source> vss:module
   vcp <source> vss:VSSROOT:module

where module is a module or directory that already exists within VSS.

This destination driver will check out the indicated destination in
a temporary directory and use it to add, delete, and alter files.

=head1 DESCRIPTION

B<Experimental>.  See L<NOTES|/NOTES> for details.

This driver allows L<vcp|vcp> to insert revisions in to a VSS
repository.  There are no options at this time.

=cut

$VERSION = 1 ;

use strict ;
use Carp ;
use File::Basename ;
use File::Path ;
use File::Spec ;
use File::Spec::Unix ;
use VCP::Debug ':debug' ;
use VCP::Rev ;
use VCP::Utils qw( empty );

use base qw( VCP::Dest VCP::Utils::vss ) ;
use fields (
   'VSS_FILES',      ## HASH of all VSS files, managed by VCP::Utils::vss
   'VSS_CHECKED_OUT', ## HASH of whether or not a file has been checked out.
) ;

## Optimization note: The slowest thing is the call to "vss commit" when
## something's been added or altered.  After all the changed files have
## been checked in by VSS, there's a huge pause (at least with a VSSROOT
## on the local filesystem).  So, we issue "vss add" whenever we need to,
## but we queue up the files until a non-add is seem.  Same for when
## a file is edited.  This preserves the order of the files, without causing
## lots of commits.  Note that we commit before each delete to make sure
## that the order of adds/edits and deletes is maintained.

#=item new
#
#Creates a new instance of a VCP::Dest::vss.  Contacts the vssd using the vss
#command and gets some initial information ('vss info' and 'vss labels').
#
#=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Dest::vss $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_vss_repo_spec( $spec )
      unless empty $spec;

   $self->parse_options(
      $options,
      "NoFreakinOptionsAllowed" => \undef,
   );

   return $self ;
}


sub init {
   my VCP::Dest::vss $self = shift ;

   $self->deduce_rev_root( $self->repo_filespec ) ;

   ## We need to know about the hierarchy under the target path.
   my $dest_path = $self->repo_filespec;
   $dest_path =~ s{([\\/]|[\\/](\.\.\.|\*\*))?\z}{/...};
   $self->get_vss_file_list( $dest_path );
}


sub handle_header {
   my VCP::Dest::vss $self = shift ;

   $self->rev_root( $self->header->{rev_root} )
      unless defined $self->rev_root ;

   $self->create_vss_workspace ;

   $self->{VSS_CHECKED_OUT} = {};

   $self->SUPER::handle_header( @_ ) ;
}


sub checkout_file {
   my VCP::Dest::vss $self = shift ;
   my VCP::Rev $r ;
   ( $r ) = @_ ;

   debug "checking out ", $r->as_string, " from vss dest repo"
      if debugging ;

   my $fn = $self->denormalize_name( $r->name ) ;
   my $work_path = $self->work_path( "co", $fn ) ;
   debug "work_path '$work_path'" if debugging ;

   my $saw = $self->last_seen( $r ) ;

   Carp::confess "Can't backfill already seen file '", $r->name, "'" if $saw ;
   die "Can't backfill already seen file '", $r->name, "'" if $saw ;

   my ( $file, $work_dir ) = fileparse( $work_path ) ;
   $self->mkpdir( $work_path ) unless -d $work_dir ;
   $work_dir =~ s{[\\/]+$}{}g;

#   my $tag = "r_" . $r->rev_id ;
#   $tag =~ s/\W+/_/g ;
#
   my ( undef, $dirs ) = fileparse( $fn );

   $self->ss( [ "cp", "\$/$dirs" ] );
   ## This -GN is a hack; it's here because the test suite uses
   ## Unix lineends and the checksums require it.
   $self->ss( [ "Get", $file, "-GL$work_dir", "-GN" ] );
   die "'$work_path' not created by vss checkout" unless -e $work_path ;

   return $work_path ;
}


sub handle_rev {
   my VCP::Dest::vss $self = shift ;

   my VCP::Rev $r ;
   ( $r ) = @_ ;

   $self->compare_base_revs( $r )
      if $r->is_base_rev && defined $r->work_path ;

   ## Don't save the reference.  This forces the DESTROY to happen here,
   ## if possible.  TODO: Keep VCP::Rev from deleting files prematurely.
   my $saw = ! ! $self->last_seen( $r );

   return if $r->is_base_rev ;

   my $fn = File::Spec->catfile(
      $self->rev_root,
      $r->name
   );
   my $work_path = $self->work_path( "co", $fn ) ;

   my ( $vol, $work_dir, undef ) = File::Spec->splitpath( $work_path ) ;
   $work_dir = File::Spec->catpath( $vol, $work_dir, "" );
   $self->mkdir( $work_dir );
   $work_dir =~ s{[\\/]+$}{}; ## vss is picky about trailing slashes in -GLpath

   if ( -e $work_path ) {
      unlink $work_path or die "$! unlinking $work_path" ;
   }

   ## Add the directories we need to VSS as projects
   my ( $file, $dirs ) = fileparse( $fn );
   $dirs =~ s{\\}{/}g;  ## Make debugging output pretty, ss is cool with /
   {
      my @dirs = File::Spec::Unix->splitdir( $dirs );
      shift @dirs while @dirs && ! length $dirs[0];
      pop   @dirs while @dirs && ! length $dirs[-1];

      my $cur_project = "";
      for ( @dirs ) {
         $cur_project .= "/" if length $cur_project;
         $cur_project .= $_;

         unless ( $self->vss_file( $cur_project ) ) {
            $self->ss( [ "Create", "\$/$cur_project", "-C-" ] );
            $self->vss_file( $cur_project, "project" );
         }
      }
   }

   $self->ss( [ "cp", "\$/$dirs" ] );

   if ( $r->action eq "delete" ) {
      $self->ss( [ 'Delete', $file, "-I-y" ],
                 stderr_filter => qr{^You have.*checked out.*Y[\r\n]*$}s,
               );
      $self->vss_file( $fn, 0 );
      $self->{VSS_CHECKED_OUT}->{$fn} = 0;
      ## TODO: Restore the file instead of adding it if it comes back?
   }
   else {
      debug "linking ", $r->work_path, " to $work_path"
         if debugging ;

      link $r->work_path, $work_path
         or die "$! linking '", $r->work_path, "' -> $work_path" ;

      if ( defined $r->mod_time ) {
         utime $r->mod_time, $r->mod_time, $work_path
            or die "$! changing times on $work_path" ;
      }

      my $comment_flag = "-C-";
      if ( defined $r->comment ) {
         my $cfn = $self->work_path( "comment.txt" ) ;
         open COMMENT, ">$cfn"       or die "$!: $cfn";
         print COMMENT $r->comment   or die "$!: $cfn";
         close COMMENT               or die "$!: $cfn";
         $comment_flag = "-C\@$cfn";
      }

      my $check_it_in = 1;

      if ( ! $self->{VSS_CHECKED_OUT}->{$fn} ) {
         my $bin_flag = $r->type ne "text" ? "-B" : "-B-";
#         my $tmp_f = $self->command_stderr_filter;
#         $self->command_stderr_filter(
#            qr{^A deleted file of the same name already exists.*|[\r\n]*$}s
#         ) ;

         my $stderr = "";
         if ( ! $self->vss_file_is_active( $fn ) ) {
            ## If the file has been deleted before, -I-y causes ss to recover it
            ## instead of adding it anew.
            $check_it_in = 0;
            $self->ss(
               [ "Add", $work_path, "-K", $bin_flag, $comment_flag, "-I-y" ],
               '2>', \$stderr,
            );
         }

         if ( $stderr =~ /A deleted file of the same name already exists/ ) {
            $check_it_in = 1;
            $self->ss(
               [ "Checkout", $file, "-G-" ]
            );

         }
         elsif ( length $stderr ) {
            die "unexpected stderr from ss Add:\n", $stderr;
         }
         $self->vss_file( $fn, "file" );
         $self->{VSS_CHECKED_OUT}->{$fn}++;
#         $self->command_stderr_filter( $tmp_f );
      }

      if ( $check_it_in ) {
         ## TODO: Don't assume same filesystem or working link().
         $self->ss( [ "Checkin", $file, "-GL$work_dir", "-K", "-I-y", $comment_flag ],
                    stderr_filter => 
                      qr{^.*was checked out from.*not from the current folder\.\r?\nContinue.*\r?\n},
                   
                  );
      }

      my @labels = map {
         s/^([^a-zA-Z])/tag_$1/ ;
	 s/\W/_/g ;
	 $_ ;
      }(
	 $r->labels,  ## Put the existing label (if any) first
	 defined $r->rev_id    ? "r_" . $r->rev_id     : (),
         defined $r->change_id ? "ch_" . $r->change_id : (),
      ) ;

      my $version;
$self->ss( [ "cp", "\$/$dirs" ] );
      $self->ss( [ "History", $file, "-#1" ], ">", \$version );
      undef $version unless
         $version =~ s/.*^\*+\s+Version\s+(\d+)\s+\*+$(.*)/$1/ms;
      ## Don't replace existing labels; this can happen if the version
      ## was recovered from a previous delete, for instance.
      undef $version if $2 =~ /^Label:\s+/m;

      for ( @labels ) {
         $self->ss( [
            "Label",
            $file,
            "-L$_",
            "-C-",
            "-I-y",   ## Yes, please reuse the label
            defined $version ? "-V$version" : ()
         ]);

         undef $version;
      }
   }
}

=head1 TODO

This module is here purely to support the VCP test suite, which must
import a bunch of files in to VSS before it can test the export.  It works,
but is not field tested.

While I'm sure there exist pressing reasons for importing files in to
VSS from other repositories, I have never had such a request and do not
wish to invest a lot of effort in advance of such a request.

Therefore, this module does not batch checkins, cope with branches,
optimize comment settings, etc.

Patches or contracts welcome.

=head1 NOTES

VSS does not flag individual revisions as binary vs. text; the change is
made on a per-file basis.  This module does not alter the filetype on
C<Checkin>, however it does set binary (-B) vs. text (-B-) on C<Add>.

VSS allows one label per file, and adding a label (by default) causes a
new versions of the file.  This module adds the first label it receives
for a file (which is first may or may not be predictable depending on
the source repository) to the existing version unless the existing
version already has a label, then it just adds new versions as needed.

This leads to the backfilling issue: when backfilling, there are no labels
to request, so backfilling always assumes that the most recent rev is the
base rev for incremental imports.

The C<ss Delete> command does not allow a comment.

Files are recalled from deleted status when added again if they were
deleted.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
