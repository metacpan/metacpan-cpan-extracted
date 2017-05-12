package VCP::Dest::p4 ;

=head1 NAME

VCP::Dest::p4 - p4 destination driver

=head1 SYNOPSIS

   vcp <source> p4:user:password@p4port:<dest>
   vcp <source> p4:user(client):password@p4port:<dest>
   vcp <source> p4:<dest>

=head1 DESCRIPTION

The <dest> spec is a perforce repository spec and must begin with // and
a depot name ("//depot"), not a local filesystem spec or a client spec.
There should be a trailing "/..." specified.

If no user name, password, or port are given, the underlying p4 command
will look at that standard environment variables.

VCP sets the environment P4PASSWD rather than giving p4 the password
on the command line so it won't be logged in debugging or error
messages.  The other options are passed on the command line.

If no client name is given, a temporary client name like "vcp_tmp_1234"
will be created and used.  The P4CLIENT environment variable will not be
used.  If an existing client name is given, the named client spec will
be saved off, altered, used, and restored.  If the client was created for
this import, it will be deleted when complete, regardless of whether the
client was specified by the user or was randomly generated.  WARNING: If
perl coredumps or is killed with a signal that prevents cleanup--like a
SIGKILL (9)--the the client deletion or restoral will not occur. The
client view is not saved on disk, either, so back it up manually if you
care.

THE CLIENT SAVE/RESTORE FEATURE IS EXPERIMENTAL AND MAY CHANGE BASED ON
USER FEEDBACK.

VCP::Dest::p4 attempts change set aggregation by sorting incoming
revisions.  See L<VCP::Dest/rev_cmp_sub> for the order in which
revisions are sorted. Once sorted, a change is submitted whenever the
change number (if present) changes, the comment (if present) changes, or
a new rev of a file with the same name as a revision that's pending.
THIS IS EXPERIMENTAL, PLEASE DOUBLE CHECK EVERYTHING!

=head1 OPTIONS

=for test_scripts
  t/90revml2p4_0.t t/90revml2p4_1.t t/90revml2p4_2.t t/90revml2p4_3.t

=over


=item --run-p4d

Runs a p4d instance in the directory indicated by repo_server (use a
directory path rather than a host name).  If repo_server contains a
port, that port will be used, otherwise a random port will be used.

Dies unless the directory exists and contains files matching db.* (to
help prevent unexpected initializing of empty directories).

VCP will kill this p4d when it's done.

=item --init-p4d

Initializes a directory and starts a p4d in it on the given port.
Refuses to init a non-empty directory.  In this case the p4port portion
of the destination specification must point to a directory; and the port,
if present, will be used for the port (otherwise a randomized port number
other than p4d's 1666 default will be used.)

A temporary p4d will be started that should be shut down upon process
exit.  If the process does not exit cleanly (for instance, if sent the
QUIT signal), this shutdown may not occur.

=item --delete-p4d-dir

If C<--init-p4d> is passed and the target directory is not empty, it
will be removed before running the p4d.  THIS IS DANGEROUS AND SHOULD
ONLY BE USED IN TEST ENVIRONMENTS.

=item --change-branch-rev-1

Some SCMs don't create a branch of a file until there is actually a
change made to that file.  So the first revision of a file on a branch
is different from its parent on the main branch.  Normally, p4 does
not work this way: rev #1 of a branched file is a very inexpensive
copy of the parent revision: you do a p4 integrate, submit, edit,
submit sequence to branch a file and introduce it's changes.

This option forces VCP to do a p4 integrate, add, submit sequence to
branch files, thus capturing the branch and the file alterations in
one change.

Using this option allows VCP to more exactly model the source
repository in the destination repository revision-for-revision, but
leaves you with a perforce repository that may not be consistent with
your work practices, so it is not the default behavior.

=back

=head1 NOTES

The p4 destination driver allows branching from deleted revisions of
files to accomodate source repositories that allow it.  It does this
by branching from the revision prior to the deleted revision.

The p4 destination driver also allows the first revision of a file to be
a deleted revision by forcing an empty "add" followed by a "delete".
CVS does this on the main trunk (rev 1.1 is "dead", ie deleted) when you
add a file on a branch.

=cut

$VERSION = 1 ;

use strict ;
use vars qw( $debug ) ;

$debug = 0 ;

use Carp ;
use File::Basename ;
use File::Path ;
use VCP::Debug ':debug' ;
use VCP::Dest ;
use VCP::Logger qw( lg lg_fh pr );
use VCP::Rev ;
use VCP::Utils qw( empty );
use VCP::Utils::p4 qw( underscorify_name );

## If we ever want to store state in the dest repo, this constant
## turns that on.  It should become an option if it is ever
## reenabled, probably replacing the VCP::RevMapDB.
use constant store_state_in_repo => 0;

use base qw( VCP::Dest VCP::Utils::p4 ) ;
use fields (
#   'P4_SPEC',               ## The root of the tree to update
   'P4_PENDING',            ## Revs pending the next submit
   'P4_WORK_DIR',           ## Where to do the work.
   'P4_REPO_CLIENT',        ## See VCP::Utils::p4 for accessors and usage...
   'P4_INIT_P4D',           ## --init-p4d flag
   'P4_DELETE_P4D_DIR',     ## --delete_p4d flag (delete temp p4d dir before starting p4d)
   'P4_RUN_P4D',            ## --run_p4d flag (run temp p4d)

   'P4_LABEL_FORM',         ## A cached label form
   'P4_ADDED_LABELS',       ## A hash of labels that we've already added.
                            ## TODO: Preload this using the p4 labels command
                            ## to save some time when writing to big repos?

   'P4_CHANGE_BRANCH_REV_1', ## Which command sequence to use when
                             ## branching a file.  See POD above.

   ## members for change number divining:
   'P4_PREV_CHANGE_ID',    ## The change_id in the r sequence, if any
   'P4_PREV_COMMENT',      ## Used to detect change boundaries
   'P4_REV_MAP',           ## RevMapDB
) ;

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Dest::p4 $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_p4_repo_spec( $spec )
      unless empty $spec;

   $self->parse_options(
      $options,
      "init-p4d!"            => \$self->{P4_INIT_P4D},
      "change-branch-rev-1!" => \$self->{P4_CHANGE_BRANCH_REV_1},
      "delete-p4d-dir!"      => \$self->{P4_DELETE_P4D_DIR},
      "run-p4d!"             => \$self->{P4_RUN_P4D},
   );

   return $self ;
}


sub init {
   my VCP::Dest::p4 $self = shift ;

   ## We use the rev_root only to munge branch specs. 
   ## We let p4 set the rev_root by setting the
   ## client view to the destination path the user specified, so as perforce
   ## adds each file in our working dir, it puts them in the right spot
   ## in the repository (under the destination rev_root).
   $self->deduce_rev_root( $self->repo_filespec );

   if ( $self->{P4_INIT_P4D} ) {
      if ( $self->{P4_DELETE_P4D_DIR} ) {
         $self->rev_map->delete_db;
         $self->head_revs->delete_db;
         $self->files->delete_db;
      }
      $self->init_p4d;
   }
   else {
      pr "ignoring --delete-p4d-dir, which is only useful with --init-p4d\n"
         if $self->{P4_DELETE_P4D_DIR};

      $self->run_p4d if $self->{P4_RUN_P4D};
   }

   $self->rev_map->open_db;
   $self->head_revs->open_db;
   $self->files->open_db;
   $self->set_up_p4_user_and_client;

   $self->init_p4_view ;
}


sub init_p4d {
   my $self = shift;

   my ( $dir, $port ) = split ":", $self->repo_server, 2;

   my @files;

   @files =  glob "$dir/*" if -d $dir;

   if ( @files && $self->{P4_DELETE_P4D_DIR} ) {
      require File::Path;
      rmtree [ @files ];
      @files =  glob "$dir/*";
   }

   die "cannot --init-p4d on non-empty dir $dir\n"
      if @files;

   $self->mkdir( $dir ) unless -e $dir;

   ## VCPP4LICENSE env var, if present, points to a p4 license file to
   ## use.  Link to it.
   my $license = $ENV{VCPP4LICENSE} ;
   if ( ! empty $license && -r $license && ! -f "$dir/license" ) {
      symlink $license, "$dir/license"
         or die "failed to link '$dir/license' to '$license' (p4 license)";
      pr "linked '$dir/license' to '$license' (p4 license)\n";
   }

   ## Ok, this is wierd: we need to fork & run p4d in foreground mode
   ## so that we can capture it's PID and kill it later.  There
   ## doesn't seem to be the equivalent of a 'p4d.pid' file. If we let
   ## it daemonize, then I don't know how to get it's PID.

   $port = $self->launch_p4d( $dir, $port );
   $self->repo_server( "localhost:$port" );
}


sub checkout_file {
   my VCP::Dest::p4 $self = shift ;
   my VCP::Rev $r ;
   ( $r ) = @_ ;

confess unless defined $self && defined $self->header ;

   debug "retrieving '", $r->as_string, "' from p4 dest repo"
      if debugging;

   ## The rev_root was put in the client view, p4 will "denormalize"
   ## the name for us.
   my $work_path = $self->work_path( $r->name ) ;
   debug "work_path '$work_path'" if debugging;

   my ( undef, $work_dir ) = fileparse( $work_path ) ;
   $self->mkpdir( $work_path ) unless -d $work_dir ;

   my $tag = store_state_in_repo
       ? "\@vcp_" . underscorify_name $r->id
       : "#" . ($self->rev_map->get( [ $r->source_repo_id, $r->id ] ))[1];

   ## The -f forces p4 to sync even if it thinks it doesn't have to.  It's
   ## not in there for any known reason, just being conservative.
   $self->p4( ['sync', '-f', $r->name . $tag ] ) ;
   die "'$work_path' not created in backfill" unless -e $work_path ;

   return $work_path ;
}


sub handle_header {
   my VCP::Dest::p4 $self = shift ;
   my ( $h ) = @_;

   $self->{P4_PENDING}        = [] ;
   $self->{P4_PREV_COMMENT}   = undef ;
   $self->{P4_PREV_CHANGE_ID} = undef ;
   $self->{P4_LABEL_FORM}     = undef ;
   $self->{P4_ADDED_LABELS}   = {};
   $self->SUPER::handle_header( @_ ) ;
   if ( $h->{branches} ) {
      for my $b ( $h->{branches}->get ) {
         my $spec = $b->p4_branch_spec;
         next if empty $spec;

         ## Re-root the view.
         my $found_it;
         $spec = $self->build_p4_form( 
            map {
               if ( $found_it ) {
                  ( my $source_root = $h->{  rev_root} ) =~ s{^/*}{//};
                  ( my $dest_root   = $self->rev_root  ) =~ s{^/*}{//};
                  s{\Q$source_root}{$dest_root}g;
                  undef $found_it;
               }
               $found_it = $_ eq "View";
               $_;
            } $self->parse_p4_form( $spec )
         );

         $self->p4( [qw(branch -i -f)], \$spec );
      }
   }
}


sub handle_rev {
   my VCP::Dest::p4 $self = shift ;
   my VCP::Rev $r ;
   ( $r ) = @_ ;

   debug "handle_rev got ", $r->as_string if debugging;
   my $change_id = $r->change_id;
   if ( 
      @{$self->{P4_PENDING}}
      && ! $self->{P4_CHANGE_BRANCH_REV_1}
         ? $change_id ne $self->{P4_PREV_CHANGE_ID}
            && ( debugging()
               ? debug "time to submit: change_id changed"
               : 1
            )
         : (
            defined $r->comment && defined $self->{P4_PREV_COMMENT}
            &&      $r->comment ne         $self->{P4_PREV_COMMENT}
            && ( debugging()
               ? debug "time to submit: comment changed [",
                  $r->comment, "] vs [", $self->{P4_PREV_COMMENT}, "]"
               : 1
            )
         )
         || (
            ! $r->is_placeholder_rev
            && grep(
               ! $_->is_placeholder_rev && $r->name eq $_->name,
               @{$self->{P4_PENDING}}
            )
            && ( debugging()
               ? debug "time to submit: name repeated"
               : 1
            )
         )
         || ( $r->previous
            && grep(
               ! $_->is_placeholder_rev && $_ == $r->previous,
               @{$self->{P4_PENDING}}
            )
            && ( debugging()
               ? debug "time to submit: need a previous revision for ",
                  "\n",
                  "   ",
                  $r->as_string,
                  "\n",
                  map
                     "     " . $_->as_string . "\n",
                     grep( $_ == $r->previous, @{$self->{P4_PENDING}} )
               : 1
            )
         )
   ) {
      $self->submit;
      $self->{P4_PREV_COMMENT}   = $r->comment;
   }

   $self->{P4_PREV_CHANGE_ID} = $change_id;

   ## TODO: batch these too so that we can pass them all to
   ## fetch_files() and allow the source to perhaps operate
   ## more efficiently.
   if ( $r->is_base_rev ) {
      my ( $work_path ) = VCP::Revs->fetch_files( $r );
      $self->compare_base_revs( $r, $work_path );
      return;
   }

   push @{$self->{P4_PENDING}}, $r;
}


sub _add_it {
   my VCP::Dest::p4 $self = shift;
   my VCP::Rev $r ;
   ( $r ) = @_ ;

   my $fn = $r->name ;
   my $work_path = $self->work_path( $fn ) ;
   ! -e $work_path;
}


sub handle_footer {
   my VCP::Dest::p4 $self = shift ;

   $self->submit if @{$self->{P4_PENDING}};
   $self->SUPER::handle_footer ;
}


{
my $lg_fh = lg_fh;
my $change_spec;

sub p4_submit {
   my VCP::Dest::p4 $self = shift;
   my ( $max_time, $description, $is_integrate, @revs ) = @_;

   unless ( $change_spec ) {
      $self->p4( [ "change", "-o" ], undef, \$change_spec ) ;

      ## ASSume the Files & Description are the last two fields in
      ## the spec.
      $change_spec =~ s/^(Description|Files):.*\r?\n\r?.*//ms
         or die "couldn't remove change file list and description\n$change_spec" ;
   }

   my @revs_to_submit = grep
      $is_integrate
         ? $_->is_placeholder_rev
         : ! $_->is_placeholder_rev,
      @revs;

   if ( length $description ) {
      $description =~ s/^/\t/gm ;
      chomp $description;
   }

   my $files =
      join "",
         map
            "\t//" . $self->denormalize_name( $_->name ) . "\n",
            @revs_to_submit;

   my $change = $change_spec . <<END_SPEC;
Description:
$description

Files:
$files
END_SPEC

   my $submit_log;
   $self->p4([ "submit", "-i"], \$change, \$submit_log ) ;
   ## extract the change number and the file list from the submit output
   print $lg_fh $submit_log;
   my $change_number;
   my %p4_rev_ids;
   {
      while ( $submit_log =~ m{\G(.*)([\r\n]+|\z)}g ) {
         my $line = $1;
         if ( $line =~ m{^\w+\s+//(.*)#(\d+)\z} ) {
            $p4_rev_ids{$1} = $2;
         }
         elsif ( $line =~ m{^Change (\d+) } ) {
            $change_number = $1;
         }
      }
   }

   pr "p4 change $change_number submitted" if defined $change_number;

   ## Force the correct date and a user id
   {
      my $repl = "Change:\t$change_number\n\n";
      $repl .= "Date:\t$max_time\n\n" if defined $max_time;

      $change =~ s/^Change:.*\r?\n/$repl/m
         or die "couldn't modify change number:\n$change";

      $change =~ s/^Status:.*\r?\n/Status: submitted\n\n/m
         or die "couldn't modify status:\n$change";

      ## ASSume the files list is last
      $change =~ s/^Files:.*\r?\n//ms
         or die "couldn't remove files list:\n$change";

      my $user_id;
      for ( @{$self->{P4_PENDING}} ) {
         unless ( empty $_->user_id ) {
            $user_id = underscorify_name( $_->user_id ); 
            last;
         }
      }
      if ( defined $user_id ) {
         $change =~ s/^User:.*/User:\t$user_id/m
            or die "couldn't modify change user\n$change" ;
      }

      $self->p4( [ "change", "-i", "-f" ], \$change ) ;
   }

   for my $r ( @revs_to_submit ) {

      my $denorm_name = $self->denormalize_name( $r->name );
      my $rev_id = $p4_rev_ids{$denorm_name};

      unless ( defined $rev_id ) {
        $submit_log =~ s/^/    /mg;
        require Data::Dumper;
         die "no rev number found in p4 submit output for ",
            $r->as_string,
            ":\n",
            $submit_log,
            "looked for: $denorm_name\n",
            "p4 revs parsed: ",
            Data::Dumper::Dumper( \%p4_rev_ids );
      }

      $self->rev_map->set(
         [ $r->source_repo_id, $r->id ],
         $denorm_name,
         $rev_id,
         $self->files->get( [ $denorm_name ] ),
      );

      $self->head_revs->set(
         [ $r->source_repo_id, $r->source_filebranch_id ],
         $r->source_rev_id
      );
   }
}
}


my $branch_spec;

sub _integrate_pending {
   my VCP::Dest::p4 $self = shift ;

   my @to_integrate;
   my @to_resolve;
   my @integrated;
   my $max_time;
   for my $r ( @{$self->{P4_PENDING}} ) {

      my $pr = $r->previous;
      if ( $pr
##         && $self->_add_it( $r )
         && ( $pr->branch_id || "" ) ne ( $r->branch_id || "" )
      ) {
         ## Branch the previous version to make the new one.  Leave
         ## add_it set so we can drop the new one in over the
         ## branched version in case it's changed.
         my $fn = $r->name ;
         my $work_path = $self->work_path( $fn ) ;
         my $denorm_name = $self->denormalize_name( $fn );

         my ( $pfull_name, $prev_id, $pstate ) =
            $self->rev_map->get( [ $pr->source_repo_id, $pr->id ] );

         die "Can't integrate from unknown revision:\n",
            "parent: ", $pr->as_string, "\n",
            "child:  ", $r->as_string, "\n"
            unless defined $pstate;

         if ( $pstate eq "deleted" ) {
            ## CVS allows branching from "deleted" revisions,
            ## let's hope that the revision before the previous
            ## revision is *not* deleted.
            $prev_id--;
         }

         push @to_integrate, [
            $r,
            $fn,
            $denorm_name,
            $work_path,
            $pfull_name,
            $prev_id,
         ];
         $max_time = $r->time if ! defined $max_time || $r->time > $max_time ;
      }
   }

   return unless @to_integrate;

   unless ( $branch_spec ) {
      $self->p4( [ "branch", "-o", "vcp_$$" ], \undef, \$branch_spec );
      $branch_spec =~ s/^(View:).*/$1\n/ms;
   }

   my $this_branch_spec = join "", $branch_spec, map {
      my ( $r, $fn, $denorm_name, $work_path, $pfull_name, $prev_id ) = @$_;
      qq{\t "//$pfull_name" "//$denorm_name"\n};
   } @to_integrate;

   $self->p4( [ "branch", "-i" ], \$this_branch_spec );

   my $to_integrate = join "", map {
         my ( $r, $fn, $denorm_name, $work_path, $pfull_name, $prev_id ) = @$_;
         "//$denorm_name#$prev_id\n"
      } @to_integrate;

   $self->p4_x(
      [ "integrate", "-b", "vcp_$$" ], \$to_integrate
   );

   for my $i ( @to_integrate ) {
      my ( $r, $fn, $denorm_name, $work_path, $pfull_name, $prev_id ) = @$i;
#      $self->p4( [ "integrate", "//$pfull_name#$prev_id", $fn ] ) ;
      push @to_resolve, $fn
         if $self->files->exists( [ $denorm_name ] );
      $self->files->set( [ $denorm_name ], "integrated to" );

      if ( $self->{P4_CHANGE_BRANCH_REV_1} ) {
         ## Force it to be `p4 add`ed as well by _add_edit_delete()
         debug "unlinking $work_path so it will be added\n"
            if debugging;
         unlink $work_path or die "$! unlinking $work_path\n"
            if -e $work_path;
      }
      else {
         ## Integrate the first change
         push @integrated, $i;
      }
   }

   $self->p4( [ "resolve", "-at" ] ) if @to_resolve;

   return unless @integrated;

   $self->p4_submit(
      $max_time, "create branches", "is integrate", map $_->[0], @integrated
   );

   for my $i ( @integrated ) {
      my ( $r, $fn, $denorm_name, $work_path, $pfull_name, $prev_id ) = @$i;
      lg "syncing recently integrated file $fn";
      $self->p4( [ "sync", "$fn" ] ) unless -e $work_path;
   }
}


sub _pre_add_pending_initial_deletes {
   my VCP::Dest::p4 $self = shift ;

   my @to_add;
   my $max_time;
   for my VCP::Rev $r ( @{$self->{P4_PENDING}} ) {
      next if $r->is_placeholder_rev;

      if ( $r->action eq "delete" ) {
         my $fn = $r->name ;
         my $work_path = $self->work_path( $fn ) ;
         my $denorm_name = $self->denormalize_name( $fn );

         my ( @state ) = $self->files->get( [ $denorm_name ] );

         unless ( @state ) {
            ## Never seen this file before.
            ##
            ## This could be a fake deletion from CVS, which does this when
            ## a file is added on a branch.  So we fake up an empty
            ## file and add it.
            lg "creating '$work_path' so that it may be deleted";
            $self->mkpdir( $work_path );
            open F, ">$work_path" or die "$! opening $work_path\n";
            close F;
            $r->dest_work_path( $work_path ) ;
            push @to_add, [ $r, $denorm_name ];
            $self->files->set( [ $denorm_name ], "touched and added" );
            $max_time = $r->time
               if ! defined $max_time || $r->time > $max_time ;
         }
      }
   }

   if ( @to_add ) {
      $self->p4_x( [ "add" ], [ map $_->[0]->name . "\n", @to_add ] );
      $self->p4_submit(
         $max_time, "spoof addition of deleted file", 0, map $_->[0], @to_add
      );
   }
}


## Revs are only queued up by handle_rev() because we need to
## deal with integrate commands before we deal with other commands.
sub _add_edit_delete_pending {
   my VCP::Dest::p4 $self = shift;

   my $do_submit;
   my @to_delete;
   my %to_add;   ## Keyed on filetype
   my %to_edit;  ## Keyed on filetype
   my @to_link;

   for my VCP::Rev $r ( @{$self->{P4_PENDING}} ) {
      next if $r->is_placeholder_rev;
      ++$do_submit;

      my $fn = $r->name ;
      my $work_path = $self->work_path( $fn ) ;
      debug "work_path '$work_path'" if debugging;

      my $denorm_name = $self->denormalize_name( $r->name );

      if ( $r->action eq "delete" ) {
         my ( @state ) = $self->files->get( [ $denorm_name ] );

         my $deleteit = $state[0] ne "deleted";

         if ( $deleteit && ! -e $work_path ) {
            $self->p4( [ "sync", "-f", $fn ] );
         }

         if ( -e $work_path ) {
            unlink $work_path or die "$! unlinking $work_path" ;
         }

         push @to_delete, $fn if $deleteit;
         $self->files->set( [ $denorm_name ], "deleted" );
      }
      else {  ## add or edit
         my $filetype = defined $r->p4_info && $r->p4_info =~ /\((\S+)\)$/
            ? $1
            : $r->type ;

         if ( $self->_add_it( $r ) ) {
            $self->mkpdir( $work_path ) ;
            push @{$to_add{$filetype}}, $r;
            $self->files->set( [ $denorm_name ], "added" );
         }
         else {
            push @{$to_edit{$filetype}}, $r;
            $self->files->set( [ $denorm_name ], "edited" );
         }

         my $work_path = $self->work_path( $r->name ) ;
         $r->dest_work_path( $work_path ) ;
         push @to_link, $r;

         ## TODO: Provide command line options for user-defined tag prefixes
         $r->add_label( "vcp_" . $r->id )
            if store_state_in_repo;
      }
   }

   $self->p4_x( [ "delete" ], [ map "$_\n", @to_delete ] ) if @to_delete;
   for ( keys %to_edit ) {
      my @to_edit = @{$to_edit{$_}};

      $self->p4_x( [ "edit", "-t", $_ ], [ map $_->name . "\n", @to_edit ] );
      for my $r ( @to_edit ) {
         my $work_path = $self->work_path( $r->name ) ;
         unlink $self->work_path( $r->name )
            or die "$! unlinking $work_path"
      }
   }

   my @source_fns = VCP::Revs->fetch_files( @to_link );

   for my $r ( @to_link ) {
      my $source_fn = shift @source_fns;

      my $work_path = $r->dest_work_path;

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
   }

   $self->p4_x( [ "add", "-t", $_ ], [ map $_->name . "\n", @{$to_add{$_}} ] )
      for keys %to_add;

   return $do_submit;
}


sub submit {
   my VCP::Dest::p4 $self = shift ;

   ## Take care of any integrations up front so that they're
   ## present if the first rev on a branch has changes on it so it
   ## can be "p4 edit"ed in the main submit.
   $self->_integrate_pending;

   ## CVS can create initial revs that are deleted; p4 must add them
   ## then delete them.
   $self->_pre_add_pending_initial_deletes( $_ );

   my $things_to_submit = $self->_add_edit_delete_pending;

   if ( $things_to_submit ) {
      my %pending_labels ;
      my %comments ;
      my $max_time ;

      if ( @{$self->{P4_PENDING}} ) {
         for my $r ( @{$self->{P4_PENDING}} ) {
            $comments{$r->comment} = $r->name if defined $r->comment ;
            $max_time = $r->time if ! defined $max_time || $r->time > $max_time ;
            for my $l ( $r->labels ) {
               push @{$pending_labels{$l}}, $r->dest_work_path ;
            }
         }

         if ( defined $max_time ) {
            my @f = reverse( (localtime $max_time)[0..5] ) ;
            $f[0] += 1900 ;
            ++$f[1] ; ## Day of month needs to be 1..12
            $max_time = sprintf "%04d/%02d/%02d %02d:%02d:%02d", @f ;
         }
         elsif ( debugging ) {
            debug "No max_time found" ;
         }
      }

      my $description = join( "\n", keys %comments ) ;

      $self->p4_submit( $max_time, $description, 0, @{$self->{P4_PENDING}} );

      ## Create or add a label spec for each of the labels.  The 'sort' is to
      ## make debugging output more legible.
      ## TODO: Modify RevML to allow label metadata (owner, desc, options)
      ## to be passed through.  Same for user, client, jobs metadata etc.
      ## The assumption is made that most labels will apply to a single change
      ## number, so we do the labelling once per submit.  I don't think that
      ## this will break if it doesn't, but TODO: add more labelling tests.
      pr "storing " . keys( %pending_labels ) . " labels"
         if keys %pending_labels > 25;
      for my $label ( sort keys %pending_labels ) {
         my $p4_label = underscorify_name $label;
         $self->{P4_ADDED_LABELS}->{$p4_label} ||= do {
            $self->{P4_LABEL_FORM} ||= do {
               my $out;
               $self->p4( [qw( label -o ), $p4_label], undef, \$out ) ;
               $out =~ s/(^.+:\s+)\Q$p4_label\E$/$1<<<LABEL>>>/gm;
               $out;
            };
            ( my $l_desc = $self->{P4_LABEL_FORM} )
               =~ s/<<<LABEL>>>/$p4_label/g;
            $self->p4( [qw( label -i ) ], \$l_desc, \my $dev_null ) ;
            1;
         };

         my $files_to_label = join( "\n", @{$pending_labels{$label}} ) . "\n" ;
         $self->p4_x(
            [qw( labelsync -a -l ), $p4_label ],
            \$files_to_label,
            \my $dev_null
         ) ;
      }
   }

   ## Make GC and file cleanup occur ASAP
   for ( @{$self->{P4_PENDING}} ) {
      $_->previous( undef );
      $_->set_work_path( undef ) if defined $_->work_path;
   }

   @{$self->{P4_PENDING}} = () ;
}

## Prevent VCP::Plugin from rmtree-ing the workspace we're borrowing
sub DESTROY {
   my VCP::Dest::p4 $self = shift ;

   $self->work_root( undef ) ;
   $self->SUPER::DESTROY ;
}


=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
