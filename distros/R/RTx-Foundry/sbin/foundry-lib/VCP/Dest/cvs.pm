package VCP::Dest::cvs ;

=head1 NAME

VCP::Dest::cvs - cvs destination driver

=head1 SYNOPSIS

   vcp <source> cvs:module
   vcp <source> cvs::pserver:cvs.foo.com:module
   vcp <source> cvs:/path/to/cvsroot:module --init-cvsroot
   vcp <source> cvs:/path/to/cvsroot:module --init-cvsroot --delete-cvsroot

where module is a cvs module or directory that already exists within CVS.

=head1 DESCRIPTION

This driver allows L<vcp|vcp> to insert revisions in to a CVS repository.

Checks out the indicated module or directory in to a temporary directory and
use it to add, delete, and alter files.

If the module does not exist, it is created with "cvs import."

TODO: Skip all directories named "CVS", in case a CVS tree is being imported.
Perhaps make it fatal, but use an option to allow it.  In this case, CVS
directories can be detected by scanning revs before doing anything.

=head1 OPTIONS

=over

=item --init-cvsroot

Initializes a cvs repository in the directory indicated in the cvs
CVSROOT spec.  Refuses to init a non-empty directory.

=item --delete-cvsroot

If C<--init-cvsroot> is passed and the target directory is not empty, it
will be deleted.  THIS IS DANGEROUS AND SHOULD ONLY BE USED IN TEST
ENVIRONMENTS.

=back

=cut

$VERSION = 1 ;

use strict ;
use vars qw( $debug ) ;

$debug = 0 ;

use Carp ;
use File::Basename ;
use File::Path ;
use VCP::Debug qw( :debug );
use VCP::Logger qw( pr lg );
use VCP::Rev ;
use VCP::Utils qw( empty );
use VCP::Utils::cvs qw( RCS_underscorify_tag );

## If we ever want to store state in the dest repo, this constant
## turns that on.  It should become an option if it is ever
## reenabled, probably replacing the VCP::RevMapDB.
use constant store_state_in_repo => 0;

use base qw( VCP::Dest VCP::Utils::cvs ) ;
use fields (
   'CVS_CHANGE_ID',  ## The current change_id in the rev_meta sequence, if any
   'CVS_LAST_MOD_TIME',  ## A HASH keyed on working files of the mod_times of
                     ## the previous revisions of those files.  This is used
		     ## to make sure that new revision get a different mod_time
		     ## so that CVS never thinks that a new revision hasn't
		     ## changed just because the VCP::Source happened to create
		     ## two files with the same mod_time.
   'CVS_PENDING_COMMAND', ## "add" or "edit"
   'CVS_PENDING',    ## Revs to be committed

   'CVS_INIT_CVSROOT',   ## cvs option to initialize cvs root directory
   'CVS_DELETE_CVSROOT', ## cvs option to delete cvs root directory

## These next fields are used to detect changes between revs that cause a
## commit. Commits are batched for efficiency's sake.
   'CVS_PREV_CHANGE_ID', ## Change ID of previous rev
   'CVS_LAST_SEEN_BRANCH',  ## HASH of last seen revisions, keyed by name
) ;

## Optimization note: The slowest thing is the call to "cvs commit" when
## something's been added or altered.  After all the changed files have
## been checked in by CVS, there's a huge pause (at least with a CVSROOT
## on the local filesystem).  So, we issue "cvs add" whenever we need to,
## but we queue up the files until a non-add is seem.  Same for when
## a file is edited.  This preserves the order of the files, without causing
## lots of commits.  Note that we commit before each delete to make sure
## that the order of adds/edits and deletes is maintained.

#=item new
#
#Creates a new instance of a VCP::Dest::cvs.  Contacts the cvsd using the cvs
#command and gets some initial information ('cvs info' and 'cvs labels').
#
#=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Dest::cvs $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_cvs_repo_spec( $spec )
      unless empty $spec;

   $self->parse_options(
      $options,
      "init-cvsroot"     => \$self->{CVS_INIT_CVSROOT},
      "delete-cvsroot"   => \$self->{CVS_DELETE_CVSROOT},
   );

   $self->command_stderr_filter(
      qr{^(?:cvs (?:server|add|remove): (re-adding|use 'cvs commit' to).*)\n}
   ) ;

   return $self ;
}


sub init {
   my VCP::Dest::cvs $self = shift;

   $self->deduce_rev_root( $self->repo_filespec ) ;

   if ( $self->{CVS_INIT_CVSROOT} ) {
      if ( $self->{CVS_DELETE_CVSROOT} ) {
         $self->rev_map->delete_db;
         $self->head_revs->delete_db;
         $self->main_branch_id->delete_db;
         $self->files->delete_db;
      }
      $self->init_cvsroot;
   }
   else {
      pr "ignoring --delete-cvsroot, which is only useful with --init-cvsroot"
         if $self->{CVS_DELETE_CVSROOT};
   }

   $self->rev_map->open_db;
   $self->head_revs->open_db;
   $self->main_branch_id->open_db;
   $self->files->open_db;
}


sub init_cvsroot {
   my VCP::Dest::cvs $self = shift;

   my $root = $self->cvsroot;

   die "cvsroot undefined\n"
      unless defined $root;

   die "cvsroot is empty string\n"
      if $root eq "";

   die "cvsroot not specified\n"
      if substr( $root, 0, 1 ) eq ":";

   die "cannot cvs init non local root $root\n"
      if substr( $root, 0, 1 ) eq ":";

   die "$root is not a dir\n"
      if -e $root && ! -d _;

   my @files;

   @files =  glob "$root/*" if -d $root;

   if ( @files && $self->{CVS_DELETE_CVSROOT} ) {
      require File::Path;
      rmtree [ @files ];
      @files =  glob "$root/*";
   }

   die "cannot cvs init non-empty dir $root\n"
      if @files;

   $self->cvs( [ qw( init ) ], { in_dir => $root } );
}


sub handle_header {
   my VCP::Dest::cvs $self = shift ;

   $self->rev_root( $self->header->{rev_root} )
      unless defined $self->rev_root ;

   $self->create_cvs_workspace(
      create_in_repository => 1,
   ) ;

   $self->{CVS_PENDING_COMMAND} = "" ;
   $self->{CVS_PENDING}         = [] ;
   $self->{CVS_PREV_CHANGE_ID}  = undef ;

   $self->SUPER::handle_header( @_ ) ;
}


sub checkout_file {
   my VCP::Dest::cvs $self = shift ;
   my VCP::Rev $r ;
   ( $r ) = @_ ;

   lg "$r checking out ", $r->as_string, " from cvs dest repo";

   my $fn = $self->denormalize_name( $r->name );
   my $work_path = $self->work_path( $fn ) ;
   debug "work_path '$work_path'" if debugging;

#   $self->{CVS_LAST_SEEN_BRANCH}->{$r->name} = $r;

   my ( undef, $work_dir ) = fileparse( $work_path ) ;
   $self->mkpdir( $work_path ) unless -d $work_dir ;

   my $tag = store_state_in_repo
       ? RCS_underscorify_tag "vcp_" . $r->id
       : ($self->rev_map->get( [ $r->source_repo_id, $r->id ] ))[0];

   ## Ok, the tricky part: we need to use a tag, but we don't want it
   ## to be sticky, or we get an error the next time we commit this
   ## file, since the tag is not likely to be a branch revision.
   ## Apparently the way to do this is to print it to stdout on update
   ## (or checkout, but we used update so it works with a $fn relative
   ## to the cwd, ie a $fn with no module name first).
## The -kb is a hack to get the tests to pass on Win32, where \n
## becomes \r\n on checkout otherwise.  TODO: figure out what is
## the best thing to do.  We might try it without the -kb, then
## if the digest check fails, try it again with -kb.  Problem is
## that said digest check occurs in VCP/Source/revml, not here,
## so we need to add a "can retry" return result to the API and
## modify the Sources to use it if a digest check fails.
   $self->cvs(
      [ qw( update -d -kb -p ), -r => $tag, $fn ],
      \undef,
      $work_path,
   ) ;

   die "'$work_path' not created by cvs checkout" unless -e $work_path ;

   return $work_path;
}


sub handle_rev {
   my VCP::Dest::cvs $self = shift ;

   my VCP::Rev $r ;
   ( $r ) = @_ ;

   my $change_id = $r->change_id;

   if ( @{$self->{CVS_PENDING}} ) {
      if ( @{$self->{CVS_PENDING}} > 25 ) {
         $self->commit( "more than 25 pending changes" );
      }
      elsif ( $change_id ne $self->{CVS_PREV_CHANGE_ID} ) {
         $self->commit(
            "end of change ",
            $self->{CVS_PREV_CHANGE_ID},
            " reached"
         );
      }
   }

   $self->{CVS_PREV_CHANGE_ID} = $change_id ;

   $self->compare_base_revs( $r )
      if $r->is_base_rev && defined $r->work_path ;

   return if $r->is_base_rev ;

   my $fn = $self->denormalize_name( $r->name ) ;
   my $work_path = $self->work_path( $fn ) ;

   if ( $r->action eq 'delete' ) {
#      $self->commit( "time to do a delete" ) if @{$self->{CVS_PENDING}};
      unlink $work_path || die "$! unlinking $work_path" ;
      $self->cvs( ["remove", $fn] ) ;
      ## Do this commit by hand since there are no CVS_PENDING revs, which
      ## means $self->commit will not work. It's relatively fast, too.
      $self->cvs( ["commit", "-m", $r->comment || "", $fn] ) ;
      delete $self->{CVS_LAST_SEEN_BRANCH}->{$r->name};
      ## TODO: update rev_map here?
      $self->head_revs->set( [ $r->source_repo_id, $r->source_filebranch_id ],
                             $r->source_rev_id, $r->action );
      $self->files->set( [ $fn ], "deleted" );
   }
   else {
      ## TODO: Move this in to commit().
      {
	 my ( $vol, $work_dir, undef ) = File::Spec->splitpath( $work_path ) ;
	 unless ( -d $work_dir ) {
	    my @dirs = File::Spec->splitdir( $work_dir ) ;
	    my $this_dir = shift @dirs  ;
	    my $base_dir = File::Spec->catpath( $vol, $this_dir, "" ) ;
	    do {
	       ## Warn: MacOS danger here: "" is like Unix's "..".  Shouldn't
	       ## ever be a problem, we hope.
	       if ( length $base_dir && ! -d $base_dir ) {
	          $self->mkdir( $base_dir ) ;
		  ## We dont' queue these to a PENDING because these
		  ## should be pretty rare after the first checkin.  Could
		  ## have a modal CVS_PENDING with modes like "add", "remove",
		  ## etc. and commit whenever the mode's about to change,
		  ## I guess.
		  $self->cvs( ["add", $base_dir] ) ;
	       }
	       $this_dir = shift @dirs  ;
	       $base_dir = File::Spec->catdir( $base_dir, $this_dir ) ;
	    } while @dirs ;
	 }
      }

      my $branch_id = $r->branch_id;
      $branch_id = "" unless defined $branch_id;
      ## See if this should be the main branch for this file.
      my ( $main_branch_id ) = $self->main_branch_id->get( [ $fn ] );

      my $switch_branches = do {
         my $last_seen_branch_id = $self->{CVS_LAST_SEEN_BRANCH}->{$fn};
         $self->{CVS_LAST_SEEN_BRANCH}->{$fn} = $branch_id
            unless $r->action eq "placeholder";

         ## By definition, the first revision of a file must
         ## predate any descendants, so if we have no main_branch_id
         ## for a file, we can ASSume that it is the main
         ## dev branch, or trunk.
         unless ( defined $main_branch_id ) {
            $main_branch_id = $r->branch_id;
            $main_branch_id = "" unless defined $main_branch_id;
            $self->main_branch_id->set( [ $fn ], $main_branch_id );
         }

         debug "dev trunk (main branch) for '$fn' is '$main_branch_id',",
           " current rev is on '$branch_id'",
           defined $last_seen_branch_id
              ? ( ", last seen this run was '$last_seen_branch_id' " )
              : ()
           if debugging;

         defined $last_seen_branch_id
            ? $last_seen_branch_id ne $branch_id
            : $branch_id ne $main_branch_id;
      };

      if ( $r->action eq "placeholder" ) {
         if ( $switch_branches ) {
            ## ASSume it's a branch founding placeholder and set the tag.
            my $branch_tag = RCS_underscorify_tag $branch_id;

            ## See if this is the spawning of a new branch: IOW, if the
            ## parent's branch_id is not the same as our branch_id
            my ( $previous_rev_id ) =
               defined $r->previous_id
                  ? eval {
                     $self->rev_map->get(
                        [ $r->source_repo_id, $r->previous_id ]
                     );
                  }
                  : ();

            # create the new branch.
            $self->cvs(
               [ "tag", "-b", "-r" . $previous_rev_id, $branch_tag, $fn ]
            );
         }

         $self->rev_map->set( [ $r->source_repo_id, $r->id ],
                              "<placeholder has no destination rev_id>",
                              defined $r->branch_id ? $r->branch_id : ""
         );
         return;
      }

      $self->commit(
         "switching to ",
         empty $branch_id ? "main" : $branch_id,
         " branch"
      ) if $switch_branches;

      ## CVS must see the mod_time change to recognize a file as new.
      ## So we peek at the previously entered one and studiously avoid
      ## committing a new version with the same mod_time.  This is
      ## an issue when importing files from a source that does not
      ## track mod_times because we can easily fire multiple versions
      ## at cvs within a second.
      my $mod_time_to_avoid;

      if ( -e $work_path ) {
         unlink $work_path or die "$! unlinking $work_path";
         $mod_time_to_avoid = (stat $work_path)[9];
      }

      if ( $switch_branches ) {
         if ( $branch_id eq $main_branch_id ) {
            ## head back to the main branch
            $self->cvs( [ "update", "-A", $fn ] );
         }
         else {
            my $branch_tag = RCS_underscorify_tag $branch_id;

            ## See if this is the spawning of a new branch: IOW, if the
            ## parent's branch_id is not the same as our branch_id
            my ( $previous_rev_id, $previous_branch_id ) =
               defined $r->previous_id
                  ? eval {
                     $self->rev_map->get(
                        [ $r->source_repo_id, $r->previous_id ]
                     );
                  }
                  : ();

            $previous_branch_id = "" unless defined $previous_branch_id;

            if ( $branch_id ne $previous_branch_id ) {
               # create the new branch.
               $self->cvs(
                  [ "tag", "-b", "-r" . $previous_rev_id, $branch_tag, $fn ]
               );
            }

            $self->cvs( [ "update", "-r" . $branch_tag, $fn ] )
               unless $r->action eq "placeholder";
         }

         $mod_time_to_avoid = (stat $work_path)[9];

         unlink $work_path or die "$! unlinking $work_path"
            if -e $work_path;
      }

      ## TODO: Don't assume same filesystem or working link().
      ## TODO: Batch these.
      $r->dest_work_path( $work_path ) ;
      my ( $source_fn ) = VCP::Revs->fetch_files( $r );

      if ( $source_fn ne $work_path ) {
          debug "linking $source_fn to $work_path"
             if debugging;

          link $source_fn, $work_path
             or die "$! linking '$source_fn' -> '$work_path'" ;
      }

      if ( defined $r->mod_time ) {
         utime $r->mod_time, $r->mod_time, $work_path
            or die "$! changing times on $work_path" ;
      }

      my ( $acc_time, $mod_time ) = (stat( $work_path ))[8,9] ;
      while ( ( $self->{CVS_LAST_MOD_TIME}->{$work_path} || 0 ) == $mod_time
         || ( ( $mod_time_to_avoid || 0 ) == $mod_time )
      ) {
         lg "tweaking mod_time on '$work_path' from ",
             "".localtime $mod_time,
             " to ",
             "".localtime $mod_time + 1,
             " at ",
             "".localtime;
         ++$mod_time ;
         utime $acc_time, $mod_time, $work_path
            or die "$! changing times on $work_path" ;
      }
      $self->{CVS_LAST_MOD_TIME}->{$work_path} = $mod_time ;

      my @file_state = $self->files->get( [ $fn ] );

      unless ( @file_state && $file_state[0] ne "deleted" ) {
         ## New file.
         my @bin_opts = $r->type ne "text" ? "-kb" : () ;
#         $self->commit if $self->{CVS_PENDING_COMMAND} ne "add" ;
         $self->cvs( [ "add", @bin_opts, "-m", $r->comment || '', $fn ] ) ;
#         $self->{CVS_PENDING_COMMAND} = "add" ;
         $self->files->set( [ $fn ], "added" );
      }
      else {
         ## Change the existing file
#         $self->commit if $self->{CVS_PENDING_COMMAND} ne "edit" ;
#         $self->{CVS_PENDING_COMMAND} = "edit" ;
      }

      push @{$self->{CVS_PENDING}}, $r ;
  }

}


sub handle_footer {
   my VCP::Dest::cvs $self = shift ;

   $self->commit( "end of transfer" )
       if $self->{CVS_PENDING} && @{$self->{CVS_PENDING}} ;#|| $self->{CVS_DELETES_PENDING} ;
   $self->SUPER::handle_footer ;
}


sub commit {
   my VCP::Dest::cvs $self = shift ;

   lg "committing: ", @_;

   return unless @{$self->{CVS_PENDING}} ;

   ## All comments should be the same, since we alway commit when the 
   ## comment changes.
   my $comment = $self->{CVS_PENDING}->[0]->comment || '' ;

   ## @names was originally to try to convince cvs to commit things in the
   ## preferred order.  No go: cvs chooses some order I can't fathom without
   ## reading it's source code.  I'm leaving this in for now to keep cvs
   ## from having to scan the working dirs for changes, which may or may
   ## not be happening now (need to check at some point).
   my @names = map $_->dest_work_path, @{$self->{CVS_PENDING}} ;

   my $commit_log;
   $self->cvs( ['commit', '-m', $comment, @names ], undef, \$commit_log ) ;

   pr "committed " . @names, " files (", @_, ")";

   ## Parse out the rev numbers that CVS assigned.
   my %cvs_rev_ids;
   {
      my $fn;
      while ( $commit_log =~ m/\G(.*)([\r\n]+|\z)/g ) {
         my $line = $1;
         if ( $line =~ /^Checking in (.*);/ ) {
            $fn = $1;
            next;
         }
         elsif ( $line =~ /^\w+ revision:\s+([.0-9]+)/ ) {
            $cvs_rev_ids{$fn} = $1;
            undef $fn;
         }
      }
   }

   for my $r ( @{$self->{CVS_PENDING}} ) {
      my $cvs_rev_id = $cvs_rev_ids{$r->dest_work_path};

      unless ( defined $cvs_rev_id ) {
         if ( $r->previous
            &&    ( $r->source_branch_id           || "" )
               ne ( $r->previous->source_branch_id || "" )
         ) {
             ## Ignore missing rev numbers from the first rev on
             ## a branch.  These are often unchanged.
         }
         else {
            $commit_log =~ s/^/    /mg;
            require Data::Dumper;
            die "no rev number found in cvs commit log output for ",
               $r->as_string,
               ":\n",
               $commit_log,
               "cvs revs parsed: ",
               Data::Dumper::Dumper( \%cvs_rev_ids );
        }
      }
      else {
         lg $r->as_string, " committed as $cvs_rev_id";

         $self->rev_map->set( [ $r->source_repo_id, $r->id ],
                              $cvs_rev_id,
                              defined $r->branch_id ? $r->branch_id : ""
         );
      }
      $self->head_revs->set( [ $r->source_repo_id, $r->source_filebranch_id ],
                             $r->source_rev_id, $r->action );
   }
   
   $commit_log = undef;

   for my $r ( @{$self->{CVS_PENDING}} ) {
      $self->tag( $_, $r->dest_work_path ) for (
	 store_state_in_repo && defined $r->id ? "vcp_" . $r->id : (),
	 $r->labels,
      ) ;
   }

   @{$self->{CVS_PENDING}} = () ;
   $self->{CVS_PENDING_COMMAND} = "" ;
}


sub tag {
   my VCP::Dest::cvs $self = shift ;

   my $tag = RCS_underscorify_tag shift;
   $self->cvs( ['tag', $tag, @_] ) ;
}


=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
