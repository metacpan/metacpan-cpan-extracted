package VCP::Source::p4 ;

=head1 NAME

VCP::Source::p4 - A Perforce p4 repository source

=head1 SYNOPSIS

   vcp p4://depot/...@10          # all files after change 10 applied
   vcp p4://depot/...@1,10        # changes 1..10
   vcp p4://depot/...@-2,10       # changes 8..10
   vcp p4://depot/...@1,#head     # changes 1..#head
   vcp p4://depot/...@-2,#head    # changes 8..10
   vcp p4:...@-2,#head            # changes 8..10, if only one depot

To specify a user name of 'user', P4PASSWD 'pass', port 'host:1666',
and p4 client 'client' use this syntax:

   vcp p4:user(client):pass@host:1666:files

Or, to run against a private p4d in a local directory, use this syntax
and the --run-p4d option:

   vcp p4:user(client):pass@/dir:files
   vcp p4:user(client):pass@/dir:1666:files

Note: VCP will set the environment variable P4PASSWD rather than
sending the password to p4 via the command line, so it shouldn't show
up in error messages.  This means that a password specified in a
P4CONFIG file will override the one set on the VCP command line.  This
is a bug.  User, client and the server string will be passed as
command line options to make them show up in error output.

You may use the P4... environment variables instead of any or all of the
fields in the p4: repository specification.  The repository spec
overrides the environment variables.

=head1 DESCRIPTION

Driver to allow L<vcp|vcp> to extract files from a
L<Perforce|http://perforce.com/> repository.

Note that not all metadata is extracted: users, clients and job tracking
information is not exported, and only label names are exported.

Also, the 'time' and 'mod_time' attributes will lose precision, since
p4 doesn't report them down to the minute.  Hmmm, seems like p4 never
sets a true mod_time.  It gets set to either the submit time or the
sync time.  From C<p4 help client>:

    modtime         Causes 'p4 sync' to force modification time 
                    to when the file was submitted.

    nomodtime *     Leaves modification time set to when the
                    file was fetched.

=head1 OPTIONS

=over

=item --run-p4d

Runs a p4d instance in the directory indicated by repo_server (use a
directory path rather than a host name).  If repo_server contains a
port, that port will be used, otherwise a random port will be used.

Dies unless the directory exists and contains files matching db.* (to
help prevent unexpected initializing of empty directories).

VCP will kill this p4d when it's done.

=item -b, --bootstrap

   -b '...'
   --bootstrap='...'
   -b file1[,file2[,...]]
   --bootstrap=file1[,file2[,...]]

(the C<...> there is three periods, a
L<Regexp::Shellish|Regexp::Shellish> wildcard borrowed from C<p4>
path syntax).

Forces bootstrap mode for an entire export (C<-b ...>) or for certain
files.  Filenames may contain wildcards, see L<Regexp::Shellish> for
details on what wildcards are accepted.

This switch controls how the first revision of a file is exported.  A
bootstrap export of a file contains the entire contents of the first
revision exported.  This is automatic if the export contains the first
revision of a file in the SCM.

In contrast to a bootstrap export of a file, an incremental export of
a file contains a digest of the revision preceding the first revision
in the revision range, followed by a delta record between that
revision and the first revision.  This allows the destination import
function to make sure that the incremental export begins where the
last export left off.

This option is necessary when exporting only more recent revisions from
a repository.

=item --continue

Starts this transfer where the previous one (to the same destination)
left off.  This uses the destination's state database to detect what
was transferred last time and to begin this transfer where the
previous one left off.

=for implementor
This is defined and accessed in a base class.

=item --follow-branch-into

Causes VCP to notice "branch into" messages in the output of p4's
filelog command and.  If the file that's the target of the p4
integrate (branch) command is revision number #1, adds the target to
the list of exported files.  This usually needs a --rev-root option to
set the rev root to be high enough in the directory tree to include
all branches (it's an error to export a file that is not under the rev
root).

=item -r, --rev-root

Sets the "revisions" root of the source tree being extracted; without this
option, VCP assumes that you are extracting the directory tree ending in the
last path segment in the filespec without a wildcard.  This allows you to
specify a shorter root directory, which can be useful especially with
--follow-branch-into, since branches may often lead off from the current
directory to peer directories or even in to entirely different trees.

The default C<rev-root> is the file spec up to the first path segment
(directory name) containing a wildcard, so

   p4:/a/b/c...

would have a rev root of C</a/b>.

In direct repository-to-repository transfers, this option should not be
necessary, the destination filespec overrides it.

=back

=head1 BRANCHES

VCP uses the "directory" name of each file as the file's branch_id.
VCP ignores p4 branch specs for several reasons:

=over

=item 1

Branch specs are not version controlled, which means that you can't tell
what a branch spec looked like when a branch was created.

=item 2

Multiple branch specs can point to the same directory or even the same file.

=item 3

branch specs are not necessary in managing a p4 repository.

=back

TODO: build a filter or VCP::Source::p4 option that allows p4 branch
specifications to determine branch_ids.

As the L<VCP Branches|VCP::Branches> chapter mentions, you can use a Map
section in the transfer specification to extract meaningful C<branch_id>s if
you need to.

=for test_script t/9*p4.t

=cut

$VERSION = 1.0 ;

use strict ;

use Carp ;
use Fcntl qw( O_WRONLY O_CREAT ) ;
use File::Basename;
use VCP::Debug ":debug" ;
use VCP::Logger qw( lg BUG pr );
use Regexp::Shellish qw( :all ) ;
use VCP::Branch;
use VCP::Branches;
use VCP::Rev;
use VCP::Utils qw( empty );

use base qw( VCP::Source VCP::Utils::p4 ) ;
use fields (
   'P4_REPO_CLIENT',       ## Set by p4_parse_repo_spec in VCP::Utils::p4
   'P4_INFO',              ## Results of the 'p4 info' command
   'P4_RUN_P4D',           ## whether --run-p4d specified
   'P4_LABEL_CACHE',       ## ->{$name}->{$rev} is a list of labels for that rev
#   'P4_LABELS',           ## Array of labels from 'p4 labels'
   'P4_MAX',               ## The last change number needed
   'P4_MIN',               ## The first change number needed
   'P4_FOLLOW_BRANCH_INTO',  ## Whether or not to follow "branch-into" events
   'P4_BRANCHES_TO_FOLLOW',  ## Branches remaining to be parsed
   'P4_FAKE_BRANCH_COUNTER', ## The current "fake" branch id.
   'P4_BRANCH_IDS',        ## a HASH keyed on in-use branch ids with undef values
   'P4_BRANCH_MAPS',       ## An ARRAY of
                           ## [ $base_re, $target_re, $branch_name ]
                           ## used to categorize branches based on what
                           ## was branched to where.
   'P4_BRANCH_SPECS',      ## A HASH of branch specs by branch_id.  Used to
                           ## pass on the appropriate branch specs to the
                           ## destination.
   'P4_OLDEST_REVS',       ## A hash of the oldest revision to be
                           ## sent in each filebranch.
) ;


sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Source::p4 $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_p4_repo_spec( $spec )
      unless empty $spec;

   $self->parse_options( 
      $options,
      'follow-branch-into' => \$self->{P4_FOLLOW_BRANCH_INTO},
      'run-p4d'            => \$self->{P4_RUN_P4D},
   );

   return $self ;
}


sub init {
   my VCP::Source::p4 $self = shift ;

   $self->run_p4d if $self->{P4_RUN_P4D};

   $self->set_up_p4_user_and_client;

   my $name = $self->repo_filespec ;
   if ( length $name >= 2 && substr( $name, 0, 2 ) ne '//' ) {
      ## No depot on the command line, default it to the only depot
      ## or error if more than one.
      my $depots ;
      $self->p4( ['depots'], undef, \$depots ) ;
      $depots = 'depot' unless length $depots ;
      my @depots = split( /^/m, $depots ) ;
      die "p4 has more than one depot, can't assume //depot/...\n"
         if @depots > 1 ;
      lg "defaulting depot to '$depots[0]'";
      $name = join( '/', '/', $depots[0], $name ) ;
   }
   $self->deduce_rev_root( $name ) ;

   die "no depot name specified for p4 source '$name'\n"
      unless $name =~ m{^//[^/]+/} ;
   $self->repo_filespec( $name ) ;

   $self->load_p4_info ;
   $self->load_p4_labels ;
   $self->load_p4_branches ;

   $self->{P4_FAKE_BRANCH_COUNTER} = 0;
}


sub load_p4_info {
   my VCP::Source::p4 $self = shift ;

   my $errors = '' ;
   $self->p4( ['info'], undef, \$self->{P4_INFO} ) ;
}


sub is_incremental {
   my VCP::Source::p4 $self= shift ;
   my ( $file, $first_rev ) = @_ ;

   my $bootstrap_mode = $first_rev == 1 || $self->is_bootstrap_mode( $file ) ;

   return ! $bootstrap_mode ;
}

# A typical entry in the filelog looks like
#-------8<-------8<------
#//revengine/revml.dtd
#... #6 change 11 edit on 2000/08/28 by barries@barries (text)
#
#        Rev 0.008: Added some modules and tests and fixed lots of bugs.
#
#... #5 change 10 edit on 2000/08/09 by barries@barries (text)
#
#        Got Dest/cvs working, lots of small changes elsewhere
#
#-------8<-------8<------
# And, from a more tangled source tree, perl itself:
#-------8<-------8<------
#... ... branch into //depot/ansiperl/x2p/a2p.h#1
#... ... ignored //depot/maint-5.004/perl/x2p/a2p.h#1
#... ... copy into //depot/oneperl/x2p/a2p.h#3
#... ... copy into //depot/win32/perl/x2p/a2p.h#2
#... #2 change 18 integrate on 1997/05/25 by mbeattie@localhost (text)
#
#        First stab at 5.003 -> 5.004 integration.
#
#... ... branch into //depot/lexwarn/perl/x2p/a2p.h#1
#... ... branch into //depot/oneperl/x2p/a2p.h#1
#... ... copy from //depot/relperl/x2p/a2p.h#2
#... ... branch into //depot/win32/perl/x2p/a2p.h#1
#... #1 change 1 add on 1997/03/28 by mbeattie@localhost (text)
#
#        Perl 5.003 check-in
#
#... ... branch into //depot/mainline/perl/x2p/a2p.h#1
#... ... branch into //depot/relperl/x2p/a2p.h#1
#... ... branch into //depot/thrperl/x2p/a2p.h#1
#-------8<-------8<------
#
# This next regexp is used to parse the lines beginning "... #"

my $filelog_rev_info_re = qr{
   \G                  # Use with /gc!!
   ^\.\.\.\s+
   \#(\d+)\s+          # Revision
   change\s+(\d+)\s+   # Change nubmer
   (\S+)\s+            # Action
   \S+\s+              ### 'on '
   (\S+)\s+            # date
   \S+\s+              ### 'by '
   (\S(?:.*?\S))\s+    # user id.  Undelimited, so hope for best
   \((\S+?)\)          # type
   .*\r?\n
}mx ;

# And this one grabs the comment
my $filelog_comment_re = qr{
   \G
   ^\r?\n
   ((?:^[^\S\r\n].*\r?\n)*)
   ^\r?\n
}mx ;


sub add_rev {
   my VCP::Source::p4 $self = shift ;
   my ( $r ) = @_;

   if ( $self->continue && $self->dest ) {
      my $previous_rev_id =
         $self->dest->last_rev_in_filebranch(
            $self->repo_id,
            $r->source_filebranch_id
         );

      return 
         if defined $previous_rev_id 
            && VCP::Rev->cmp_id( $previous_rev_id, $r->rev_id ) >= 0 ;
   }

   $self->revs->add( $r );

   ## Filelogs are in newest...oldest order, so this should catch
   ## the oldest revision of each file.
   $self->{P4_OLDEST_REVS}->{$r->source_filebranch_id} = $r;
}


sub p4_filelog_parser {
   my $self = shift;
   my ( $fh ) = @_;

   my VCP::Rev $r ;
   my $name ;
   my $comment ;

   local $_;

   my $log_state = "need_file" ;
   while ( <$fh> ) {
   REDO_LINE:
      if ( $log_state eq "need_file" ) {
         die "\$r defined" if defined $r ;
         die "p4 filelog parser: file name expected, got '$_'"
            unless m{^//(.*?)\r?\n\r?} ;

         $name = $1 ;
         $log_state = "revs" ;
      }
      elsif ( $log_state eq "revs" ) {
         if ( $r && m{^\.\.\. #} ) {
            $self->add_rev( $r );
            $r = undef;
         }
         elsif ( m{^\.\.\.\s+\.\.\.\s*(.*?)\s*\r?\n\r?} ) {
            my $chunk = $1;
            if ( $chunk =~ /^branch from (.*)/ ) {
               ## Only pay attention to branch foundings
               next if ! $r || $r->rev_id ne "1";

               my $base_spec = $1;
               my ( $base_name, $base_rev, $source_rev ) =
                  $base_spec =~ m{\A([^#]+)#(\d+)(?:,#(\d+))?\z}
                     or die "Could not parse branch from '$base_spec' for ",
                     $r->as_string;
               ## TODO: $base_rev is usually #1 when a new branch
               ## is created, since the last "add" of the source
               ## file is usually #1.  However, it might not be and I'm
               ## not sure what, if anything, should be done with it.
               $source_rev = $base_rev unless defined $source_rev;
               $r->previous_id( "$base_name#$source_rev" );
            }
            elsif ( $self->{P4_FOLLOW_BRANCH_INTO}
               && $chunk =~ /^branch into (.*)/
            ) {
               my $target_spec = $1;
               my ( $target_name, $target_rev ) =
                  $target_spec =~ m{\A(.*)#(\d+)\z}
                     or die"Could not parse branch into '$target_spec' for ",
                        $r->as_string;
               push @{$self->{P4_BRANCHES_TO_FOLLOW}}, $target_name;
            }
            ## We ignore unrecognized secondary log lines.
            next;
         }

         unless ( m{$filelog_rev_info_re} ) {
            $log_state = "need_file" ;
            $self->add_rev( $r ) if defined $r;
            $r = undef;
            goto REDO_LINE ;
         }

         my $rev_id    = $1;
         my $change_id = $2;
         if ( $change_id < $self->min ) {
            undef $r ;
            $log_state = "need_comment" ;
            next;
         }

         my $action    = $3;
         my $user_id   = $5;
         my $type = $6 ;

         $action = "edit" if $action eq "branch";

         my $norm_name = $self->normalize_name( $name ) ;
         die "\$r defined" if defined $r ;

         my $p4_name = "//$name";
         my $branch_id = (fileparse $p4_name )[1];
         $self->{P4_BRANCH_IDS}->{$branch_id} = undef;
         $r = VCP::Rev->new(
            id                   => "$p4_name#$rev_id",
            name                 => $norm_name,
            source_name          => $norm_name,
            source_filebranch_id => $p4_name,
            branch_id            => $branch_id,
            source_branch_id     => $branch_id,
            source_repo_id       => $self->repo_id,
            rev_id               => $rev_id,
            source_rev_id        => $rev_id,
            change_id            => $change_id,
            source_change_id     => $change_id,
            action               => $action,
            time                 => $self->parse_time( $4 ),
            user_id              => $user_id,
            p4_info              => $_,
            comment              => '',
         ) ;

         my $nr = eval { $self->revs->get_last_added( $r ) };
         if ( $nr ) {
            $nr->previous_id( $r->id ) ;
         }
         elsif ( 0 > index $@, "t find revision" ) {
            die $@;
         }

         my $is_binary = $type =~ /^(?:u?x?binary|x?tempobj|resource)/ ;
         $r->type( $is_binary ? "binary" : "text" ) ;

         $r->set_labels( $self->get_p4_file_labels( $name, $r->rev_id ) );

         $log_state = "need_comment" ;
      }
      elsif ( $log_state eq "need_comment" ) {
         unless ( /^$/ ) {
            die
"p4 filelog parser: expected a blank line before a comment, got '$_'" ;
         }
         $log_state = "comment_accum" ;
      }
      elsif ( $log_state eq "comment_accum" ) {
         if ( /^$/ ) {
            if ( defined $r ) {
               $r->comment( $comment ) ;
            }
            $comment = undef ;
            $log_state = "revs" ;
            next;
         }
         unless ( s/^\s// ) {
            die "p4 filelog parser: expected a comment line, got '$_'" ;
         }
         $comment .= $_ ;
      }
      else {
         die "unknown log_state '$log_state'" ;
      }
   }

   if ( $r ) {
      $self->add_rev( $r );
      $r = undef;
   }
}


sub scan_filelog {
   my VCP::Source::p4 $self = shift ;

   my ( $first_change_id, $last_change_id ) = @_ ;

   my $log = '' ;

   my $delta = $last_change_id - $first_change_id + 1 ;

   my $spec =  join( '', $self->repo_filespec . '@' . $last_change_id ) ;

   $self->{P4_BRANCHES_TO_FOLLOW} = [ $spec ];
   $self->{P4_OLDEST_REVS} = {};

   while ( @{$self->{P4_BRANCHES_TO_FOLLOW}} ) {
      my $s = shift @{$self->{P4_BRANCHES_TO_FOLLOW}};

      $self->p4(
         [qw( filelog -m ), $delta, "-l", $s ],
         undef,
         sub { $self->p4_filelog_parser( @_ ) },
         {
            stderr_filter => 
               sub { qr{//\S* - no file\(s\) at that changelist number\.\s*\r?\n} } 
         }
      ) ;

   }

   pr "found " . $self->revs->get, " revisions";

   ## Link each revision to its previous revision with a reference
   ## by using the previous_id string to find the previous rev.
   for my $r ( $self->revs->get ) {
      next unless defined $r->previous_id;

      ## We assume that any unfound source branches are not wanted and
      ## that the user intends to export a branch without its roots.
      my $pr = eval { $self->revs->get( $r->previous_id ) };

      if ( $pr ) {
         $r->previous( $pr );
      }
      else {
         die $@ unless 0 < index $@, "t find revision";
         $r->previous_id( undef );
      }
   }

   my @base_rev_specs ;
   for my $r ( values %{$self->{P4_OLDEST_REVS}} ) {
      my $rev_id = $r->rev_id ;
      ## filebranch_id is "//foo/bar" for p4, so it is the absolute path
      if ( $self->is_incremental( $r->source_filebranch_id, $r->rev_id ) ) {
         $rev_id -= 1 ;
         push @base_rev_specs, $r->source_filebranch_id . "#" . $rev_id;
      }
      else {
         debug "bootstrapping '", $r->name, "#", $r->rev_id, "'"
            if debugging ;
      }
      delete $self->{P4_OLDEST_REVS}->{$r->source_filebranch_id};
   }

   if ( @base_rev_specs ) {
      undef $log ;
      $self->p4_x(
         [qw( filelog -m 1 -l ) ],
         [ map "$_\n", @base_rev_specs ],
         \$log,
         {
            stderr_filter => sub {
               qr{//\S* - no file\(s\) at that changelist number\.\s*\r?\n}
            },
         }
      ) ;

      while ( $log =~ m{\G(.*?)^//(.*?)\r?\n\r?}gmsc ) {
         pr "ignoring '$1' in p4 filelog output\n" if length $1 ;
         my $name = $2 ;

         my $norm_name = $self->normalize_name( $name ) ;
         while () {
            next if     $log =~ m{\G^\.\.\.\s+\.\.\..*\r?\n\r?}gmc ;

            last unless $log =~ m{$filelog_rev_info_re}gc ;
            my ( $rev_id, $change_id, $type ) = ( $1, $2, $6 );
            my $p4_name = "//$name";
            my $branch_id = (fileparse $p4_name )[1];
            $self->{P4_BRANCH_IDS}->{$branch_id} = undef;

            my VCP::Rev $br = VCP::Rev->new(
               id                   => "$p4_name#$rev_id",
               name                 => $norm_name,
               source_name          => $norm_name,
               source_filebranch_id => $p4_name,
               source_repo_id       => $self->repo_id,
               rev_id               => $rev_id,
               source_branch_id     => $branch_id,
               branch_id            => $branch_id,
               source_rev_id        => $rev_id,
               change_id            => $change_id,
               source_change_id     => $change_id,
               type                 => $type,
               ## No need for more fields in a base rev
            ) ;

            my $nr = eval { $self->revs->get_last_added( $br ) };
            if ( $nr ) {
               $nr->previous_id( $br->id ) ;
               $nr->previous( $br ) ;
            }
            elsif ( 0 > index $@, "t find revision" ) {
               die $@;
            }

            $self->revs->add( $br ) ;

            $log =~ m{$filelog_comment_re}gc ;
         }
      }
   }
}


sub min {
   my VCP::Source::p4 $self = shift ;
   $self->{P4_MIN} = shift if @_ ;
   return $self->{P4_MIN} ;
}


sub max {
   my VCP::Source::p4 $self = shift ;
   $self->{P4_MAX} = shift if @_ ;
   return $self->{P4_MAX} ;
}

# $ p4 labels   
# Label P98.2 1999/06/14 'Perforce98.2-compatible scripts & source files. '
# Label P99.1 1999/06/14 'Perforce99.1-compatible scripts & source files. '
# Label PerForte-1-0 2002/02/27 'Initial version from Axel Wienberg.  Created by david_rees. '
# Label PerForte-1-1 2002/02/28 'Created by david_rees. '
# Label jam2-2-0 1998/09/24 'Jam/MR 2.2 '
# Label jam2-2-4 1998/09/24 'Jam/MR 2.2.4 '
# Label vcp_00_02 2000/12/11 'VCP release 0.02. '
# Label vcp_00_03 2000/12/11 'VCP Release 0.03 '
# Label vcp_00_04 2000/12/19 'VCP release 0.4 '
# Label vcp_00_05 2000/12/19 'VCP release 0.05 '
# Label vcp_00_06 2000/12/20 'VCP Release 0.06 '
# Label vcp_00_068 2001/05/21 'VCP version v0.068 '
# Label vcp_00_07 2002/07/17 'VCP release v0.07 '
# Label vcp_00_08 2001/05/23 'VCP release 0.08 '
# Label vcp_00_09 2001/05/30 'Created by barrie_slaymaker. '
# Label vcp_00_091 2001/06/07 'vcp release 0.091 '
# Label vcp_00_1 2001/07/03 'VCP release 0.1 '
# Label vcp_00_2 2001/07/18 'VCP release 0.2. '
# Label vcp_00_21 2001/07/20 'VCP release 0.21 '
# Label vcp_00_22 2001/12/18 'VCP release 0.22 '
# Label vcp_00_221 2001/07/30 'VCP Release 0.221 '
# Label vcp_00_26 2001/12/18 'VCP release 0.26 '
# Label vcp_00_28 2002/04/30 'VCP release 0.28 '
# Label vcp_00_30 2002/05/24 'VCP release 0.3 '

sub load_p4_labels {
   my VCP::Source::p4 $self = shift ;

   my $labels = '' ;
   my $errors = '' ;
   $self->p4( ['labels'], undef, \$labels ) ;

   my @labels = map(
      /^Label\s*(\S*)/ ? $1 : (),
      split( /^/m, $labels )
   ) ;

   my $marker = "//.../NtLkly" ;
   my $p4_files_args =
      join(
         "",
         ( map {
            ( "$marker\n", "//...\@$_\n" ) ;
         } @labels ),
      ) ;

   $self->p4_x(
      [ qw( -s files) ],
      \$p4_files_args,
      \my $files,
      { ok_result_codes => [ 0, 1 ] },
   );

   my $label ;
   for my $spec ( split /\n/m, $files ) {
      last if $spec =~ /^exit:/ ;
      if ( $spec =~ /^error: $marker/o ) {
         $label = shift @labels ;
         next ;
      }
      next if $spec =~ m{^error: //\.\.\.\@.+ file(\(s\))? not in label.$} ;
      $spec =~ /^.*?: *\/\/(.*)#(\d+)/
         or die "Couldn't parse name & rev from '$spec' in '$files'" ;

      debug "p4 label '$label' => '$1#$2'" if debugging ;
      push @{$self->{P4_LABEL_CACHE}->{$1}->{$2}}, $label ;
   }

   return ;
}


# $ p4 branches
# Branch BoostJam 2001/11/12 'Created by david_abrahams. '
# Branch P4DB_2.1 2002/07/07 'P4DB Version 2.1 '
# Branch gjam 2000/03/22 'Created by grant_glouser to branch the jam sources. '
# Branch jab_triggers 1999/03/18 'Created by jeff_bowles. '
# Branch java_reviewer 2002/08/12 'Created by david_markley. '
# Branch lw2pub 1999/06/18 'Created by laura_wingerd. '
# Branch mwm2pub 1999/06/18 'Created by laura_wingerd. '
# Branch p4hltest 2002/04/24 'Branch for testing FileLogCache stuff out. '
# Branch p4jsp 2002/07/30 'p4jsp to public depot '
# Branch p4package 2001/11/05 'Created by david_markley. '
# Branch scouten-jam 2000/08/18 'ES version of jam. '
# Branch scouten-webkeeper 2000/03/01 'ES version of webkeeper. '
# Branch srv_webkeep_guest_to_main 2001/09/04 'Created by stephen_vance. '
# Branch steve_howell_util 1998/12/31 'Created by steve_howell. '
# Branch tq_cvs2p4 2000/09/09 'Created by thomas_quinot. '
# Branch vsstop4_rc2ps 2002/03/06 'for pulling Roberts branch into mine '

sub load_p4_branches {
   my VCP::Source::p4 $self = shift ;

   $self->p4( ['branches'], undef, \my $branches ) ;

   my @branches = map
      /^Branch\s*(\S*)/ ? $1 : (),
      split /^/m, $branches;

   my $shellish_opts = { star_star => 0 };

   for ( @branches ) {
      $self->p4( ['branch', '-o', $_ ], undef, \my $branch_spec );
      $self->{P4_BRANCH_SPECS}->{$_} = $branch_spec;
      my %branch = $self->parse_p4_form( $branch_spec );
      for ( split /\n/, $branch{View} ) {
         next unless length;
         my ( $source, $dest ) = split /\s+/, $_, 2;
         my $source_re = compile_shellish( $source, $shellish_opts );
         my $dest_re   = compile_shellish( $dest  , $shellish_opts );
         push @{$self->{P4_BRANCH_MAPS}},
            [ $source_re, $dest_re, $branch{Branch} ];
      }
   }

   return ;
}


sub denormalize_name {
   my VCP::Source::p4 $self = shift ;
   my $fn = $self->SUPER::denormalize_name( @_ );
   $fn =~ s{^/*}{//};
   return $fn;
}


sub get_p4_file_labels {
   my VCP::Source::p4 $self = shift ;

   my $name ;
   my VCP::Rev $rev ;
   ( $name, $rev ) = @_ ;

   return (
      (  exists $self->{P4_LABEL_CACHE}->{$name}
      && exists $self->{P4_LABEL_CACHE}->{$name}->{$rev}
      )
         ? $self->{P4_LABEL_CACHE}->{$name}->{$rev}
         : []
   ) ;
}


my $filter_prog = <<'EOPERL' ;
   use strict ;
   my ( $name, $working_path ) = ( shift, shift ) ;
   }
EOPERL


sub get_rev {
   my VCP::Source::p4 $self = shift ;

   my VCP::Rev $r ;

   ( $r ) = @_ ;
   BUG "can't check out ", $r->as_string, "\n"
      unless $r->is_base_rev || $r->action eq "add" || $r->action eq "edit";

   my $fn  = $r->source_name ;
   my $rev = $r->source_rev_id ;
   $r->work_path( $self->work_path( $fn, $rev ) ) ;
   my $wp  = $r->work_path ;
   $self->mkpdir( $wp ) ;

   my $denormalized_name = $self->denormalize_name( $fn ) ;
   my $rev_spec = "$denormalized_name#$rev" ;

#   sysopen( WP, $wp, O_CREAT | O_WRONLY )
#      or die "$!: $wp" ;
#
#   binmode WP ;
#
#   my $re = quotemeta( $rev_spec ) . " - .* change \\d+ \\((.+)\\)";

   ## TODO: look for "+x" in the (...) and pass an executable bit
   ## through the rev structure.
   $self->p4( 
      [ "print", "-q", $rev_spec ],
      undef,
      $wp,
#      sub {
#         my ( $fh ) = @_;
#         my $header_line = <$fh>;
#         local $_;
#         while ( <fh> ) {
#            print WP or die "$! writing to $wp" ;
#         }
#      },
   ) ;

#   close WP or die "$! closing wp" ;
   return $wp;
}


sub handle_header {
   my VCP::Source::p4 $self = shift ;
   my ( $header ) = @_ ;

   $header->{rep_type} = 'p4' ;
   $header->{rep_desc} = $self->{P4_INFO} ;
   $header->{rev_root} = $self->rev_root ;

   $self->revs( VCP::Revs->new ) ;
   $self->scan_filelog( $self->min, $self->max ) ;

   if ( $self->{P4_BRANCH_IDS} ) {
      $header->{branches} = VCP::Branches->new;
      $header->{branches}->add(
         VCP::Branch->new(
            branch_id => $_,
         )
      )
         for sort keys %{$self->{P4_BRANCH_IDS}};
   }

   $self->dest->handle_header( $header ) ;
   return ;
}


=head1 LIMITATIONS

Treats each branched file as a separate branch with a unique branch_id,
although files that are branched together should end up being submitted
together in the destination repository due to change number aggregation.

Ignores branch specs for now.  There may be an option to enable
automatic use of branch specs because most are probably well behaved.
However, in the event of a branch spec being altered after the original
branch, this could lead to odd results.  Not sure how useful branch
specs are vs. how likely a problem this is to be.  We may also want to
support "external" branch specs to allow deleted branch specs to be
used.

=head1 SEE ALSO

L<VCP::Dest::p4>, L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
