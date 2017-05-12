package VCP::Source::cvs ;

=head1 NAME

VCP::Source::cvs - A CVS repository source

=head1 SYNOPSIS

   vcp cvs:module/... -d ">=2000-11-18 5:26:30" <dest>
                                  # All file revs newer than a date/time

   vcp cvs:module/... -r foo      # all files in module and below labelled foo
   vcp cvs:module/... -r foo:     # All revs of files labelled foo and newer,
                                  # including files not tagged with foo.
   vcp cvs:module/... -r 1.1:1.10 # revs 1.1..1.10
   vcp cvs:module/... -r 1.1:     # revs 1.1 and up on main trunk

   ## NOTE: Unlike cvs, vcp requires spaces after option letters.

=head1 DESCRIPTION

Source driver enabling L<C<vcp>|vcp> to extract versions form a cvs
repository.

The source specification for CVS looks like:

    cvs:cvsroot:module/filespec [<options>]

or optionally, if the C<CVSROOT> environment variable is set:

    cvs:module/filespec [<options>]
    
The cvsroot is passed to C<cvs> with cvs' C<-d> option.

The filespec and E<lt>optionsE<gt> determine what revisions
to extract.

C<filespec> may contain trailing wildcards, like C</a/b/...> to extract
an entire directory tree.

If the cvsroot looks like a local filesystem (if it doesn't
start with ":" and if it points to an existing directory or file), this
module will read the RCS files directly from the hard drive unless
--use-cvs is passed.  This is more accurate (due to poor design of
the cvs log command) and much, much faster.

=head1 OPTIONS

=over

=item -b, --bootstrap

   -b ...
   --bootstrap=...
   -b file1[,file2[, etc.]]
   --bootstrap=file1[,file2[, etc. ]]

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

=item --cd

Used to set the CVS working directory.  VCP::Source::cvs will cd to this
directory before calling cvs, and won't initialize a CVS workspace of
it's own (normally, VCP::Source::cvs does a "cvs checkout" in a
temporary directory).

This is an advanced option that allows you to use a CVS workspace you
establish instead of letting vcp create one in a temporary directory
somewhere.  This is useful if you want to read from a CVS branch or if
you want to delete some files or subdirectories in the workspace.

If this option is a relative directory, then it is treated as relative
to the current directory.

=item -kb, -k b

Pass the -kb option to cvs, forces a binary checkout.  This is
useful when you want a text file to be checked out with Unix linends,
or if you know that some files in the repository are not flagged as
binary files and should be.

=item --rev-root

B<Experimental>.

Falsifies the root of the source tree being extracted; files will
appear to have been extracted from some place else in the hierarchy.
This can be useful when exporting RevML, the RevML file can be made
to insert the files in to a different place in the eventual destination
repository than they existed in the source repository.

The default C<rev-root> is the file spec up to the first path segment
(directory name) containing a wildcard, so

   cvs:/a/b/c...

would have a rev-root of C</a/b>.

In direct repository-to-repository transfers, this option should not be
necessary, the destination filespec overrides it.

=item C<-r>

   -r v_0_001:v_0_002
   -r v_0_002:

Passed to C<cvs log> as a C<-r> revision specification.  This corresponds
to the C<-r> option for the rlog command, not either of the C<-r>
options for the cvs command.  Yes, it's confusing, but "cvs log" calls
"rlog" and passes the options through.

IMPORTANT: When using tags to specify CVS file revisions, ordinarily a
number of unwanted revisions are selected.  This is because the cvs
log command dumps the entire log history for any files that do not
contain the tag.  To work around this, VCP will keep track of the
maximum date range of all revisions of tagged files.  Then it will
capture the histories of untagged files and only include revisions
that fall in the date range.

Be cautious using HEAD as the end of a revision range, this seems to
cause the delete actions for files deleted in the last revision to be
missed.  Not sure why.

=item --continue

Starts this transfer where the previous one (to the same destination)
left off.  This uses the destination's state database to detect what
was transferred last time and to begin this transfer where the
previous one left off.

=for implementor
This is defined and accessed in a base class.

=item --use-cvs

Do not try to read local repositories directly; use the cvs command
line interface.  This is much slower than reading the files directly
but is useful to see if there is a bug in the RCS file parser or
possibly when dealing with corrupt RCS files that cvs will read.

If you find that this option makes something work, then there is a
discrepancy between the code that reads the RCS files directly (in the
absence of this option) and cvs itself.  Please let me know
(barrie@slaysys.com).  Thanks.

=item C<-d>

   -d "2000-11-18 5:26:30<="

Passed to 'cvs log' as a C<-d> date specification. 

WARNING: if this string doesn't contain a '>' or '<', you're probably doing
something wrong, since you're not specifying a range.  vcp may warn about this
in the future.

see "log" command in cvs(1) man page for syntax of the date specification.

=back

=head2 Files that aren't tagged

CVS has one peculiarity that this driver works around.

If a file does not contain the tag(s) used to select the source files,
C<cvs log> outputs the entire life history of that file.  We don't want
to capture the entire history of such files, so L<VCP::Source::cvs>
ignores any revisions before and after the oldest and newest tagged file.

=head2 Branches with multiple tags

CVS allows branches to be tagged with multiple tags using a command
like 

   cvs admin second_branch_tag:branch_tag

When VCP::Source::cvs notices this, it creates multiple branches with
identical revisions.  For instance, if file foo is branched once in to a
branch tagged with "bar" and later a "goof" tag is aliased to the "bar"
tag, then

    main      bar                  goof
    =======   =======              =======

    foo#1.1
      |    \
      |     \
      |      \
     ...      foo#1.1.1.1<bar>
                 |            \
                 |             \
                 |              \
                 |              foo#1.1.1.1<goof>
                 |
              foo#1.1.1.2<bar>                   
                 |            \
                 |             \
                 |              \
                 |              foo#1.1.1.2<goof>
                 |
                ...

This is EXPERIMENTAL and it's likely to give VCP::Dest::cvs fits.

You may use a Map: section in the .vcp file to discard one branch
or the other:

    Map:
        ...<goof>   <<delete>>

=head1 LIMITATIONS

   "What we have here is a failure to communicate!"
       - The warden in Cool Hand Luke

CVS does not try to protect itself from people checking in things that look
like snippets of CVS log file: they come out exactly like they went in,
confusing the log file parser.  So, if a repository contains messages in the
log file that look like the output from some other "cvs log" command, things
will likely go awry when using remote repositories (local repositories are
read directly and do not suffer this problem).

CVS stores the -k keyword expansion setting per file, not per revision,
so vcp will mark all revisions of a file with the current setting of
the -k flag for a file.

At least one cvs repository out there has multiple revisions of a single file
with the same rev number.  The second and later revisions with the same rev
number are ignored with a warning like "Can't add same revision twice:...".

=for test_script t/80rcs_parser.t t/91cvs2revml.t

=cut

$VERSION = 1.2 ;

# Removed docs for -f, since I now think it's overcomplicating things...
#Without a -f This will normally only replicate files which are tagged.  This
#means that files that have been added since, or which are missing the tag for
#some reason, are ignored.
#
#Use the L</-f> option to force files that don't contain the tag to be
#=item -f
#
#This option causes vcp to attempt to export files that don't contain a
#particular tag but which occur in the date range spanned by the revisions
#specified with -r.  The typical use is to get all files from a certain
#tag to now.
#
#It does this by exporting all revisions of files between the oldest and
#newest files that the -r specified.  Without C<-f>, these would
#be ignored.
#
#It is an error to specify C<-f> without C<-r>.
#
#exported.


=begin developerdocs

CVS branching needs some help to allow VCP::Dest::* drivers to branch
files appropriately because CVS branch creation (cvs rtag -b) does not
actually create a branched revision, it marks the parent revision for a
branch.

However, we need to include information about all the files that should
be branched when a branch is created.  CVS does not reliably record the
data of branch creation (though we might be able to find it in CVS
history, I have not found that to be a reliable approach; different CVS
versions seem to capture different things, at least by default).

There's a dilemma here: we need to create branched revisions for created
branches, but we don't know when to do it.  So the first time we see a
change on a branch, we create dummy revisions for all files that are
also on that branch.

These dummy revisions are VCP::Rev instances with a ".0" rev_id and with
no <digest>, <delta>, <content>, or <delete> elements.

See the docs for VCP::Rev::is_placeholder_rev().

Detection of branches that have been initiated this transfer has to
occur after unwanted revisions are thrown out (due to rev_id <
last_rev_in_filebranch or due to culling of unwanted revs) so we don't
think all branches have been created this transfer.

=end developerdocs

=cut

use strict ;

use Carp ;
use Regexp::Shellish qw( :all ) ;
use VCP::Branches;
use VCP::Branch;
use VCP::Debug qw( :debug :profile ) ;
use VCP::Logger qw( pr lg BUG );
use VCP::Rev qw( iso8601format );
use VCP::Source ;
use VCP::Utils qw( empty shell_quote start_dir copy_file );
use VCP::Utils::cvs ;

use constant debug_parser => 0;

use base qw( VCP::Source VCP::Utils::cvs ) ;
use fields (
   'CVS_CUR',            ## The current change number being processed
   'CVS_IS_INCREMENTAL', ## Hash of filenames, 0->bootstrap, 1->incremental
   'CVS_INFO',           ## Results of the 'cvs --version' command and CVSROOT
   'CVS_LABEL_CACHE',    ## ->{$name}->{$rev} is a list of labels for that rev
   'CVS_LABELS',         ## Array of labels from 'p4 labels'
   'CVS_REV_SPEC',       ## The revision spec to pass to `cvs log`
   'CVS_DATE_SPEC',      ## The date spec to pass to `cvs log`
   'CVS_FORCE_MISSING',  ## Set if -r was specified.
   'CVS_WORK_DIR',       ## working directory set via --cd option
   'CVS_USE_CVS',        ## holds the value of the --use-cvs option

   'CVS_K_OPTION',       ## Which of the CVS/RCS "-k" options to use, if any

   'CVS_DIRECT',         ## Read CVS files directly instead of through the
                         ## cvs command.  Used if the CVSROOT looks local.

   'CVS_LOG_FILE_DATA',  ## Data about all revs of a file from the log file
   'CVS_LOG_STATE',      ## Parser state machine state
   'CVS_LOG_REV',        ## The revision being parsed (a hash)

   'CVS_NAME_REP_NAME',  ## A mapping of repository names to names, used to
                         ## figure out what files to ignore when a cvs log
			 ## goes ahead and logs a file which doesn't match
			 ## the revisions we asked for.

   'CVS_NEEDS_BASE_REV', ## What base revisions are needed.  Base revs are
                         ## needed for incremental (ie non-bootstrap) updates,
			 ## which is decided on a per-file basis by looking
			 ## at VCP::Source::is_bootstrap_mode( $file ) and
			 ## the file's rev number (ie does it end in .1).
   'CVS_SAW_EQUALS',     ## Set when we see the ==== lines in log file [1]

   ## The following are for parsing RCS files directly
   'CVS_RCS_FILE_PATH',  ## The file currently being scanned when reading
                         ## RCS files directly.
   'CVS_RCS_FILE_BUFFER', ## The file currently being scanned when reading
   'CVS_RCS_FILE_LINES', ## How many lines have already been purged from
                         ## CVS_RCS_FILE_BUFFER.
   'CVS_RCS_FILE_EOF',   ## Set if we've read the end of file.
   'CVS_MIN_REV',        ## The first desired rev_id or tag, if defined
   'CVS_MAX_REV',        ## The first desired rev_id or tag, if defined
   'CVS_FILE_DATA',      ## All the revs that were parsed for all files.
                         ## This is accumulated first, so that the
                         ## revs that don't have a particular label
                         ## can be cleaned up if force_missing.
   'CVS_CULL_OLD_REVS_FROM',  ## Files that did not have a revision labelled
                         ## with the beginning label from a -rfoo:bar spec
                         ## and thus need to have some old revs thrown away
   'CVS_CULL_NEW_REVS_FROM',  ## Files that did not have a revision labelled
                         ## with the end label from a -rfoo:bar spec
                         ## and thus need to have some young revs thrown away

   'CVS_READ_SIZE',      ## Used in test suite to probe the RCS parser by
                         ## forcing a really tiny buffer size on it.
   'CVS_PRINTING_HASHES',
   'CVS_FIRST_BRANCHED_REVS',   ## HASH of files that have been branched using
                         ## given branch tags, so that we can put
                         ## placholders in for any that *weren't*
                         ## branched for a given tag.
   'CVS_BRANCH_PARENTS', ## All revisions that are the parents of
                         ## branches.  Keyed on tag, each value is
                         ## an array of [ $filename, $rev_id ]s for
                         ## parent revs for that branch.
   'CVS_ALIASED_BRANCH_TAGS', ## CVS allows filebranches to have more than
                               ## one tag.  In this case, we clone all entries
                               ## on the oldest tag in to entries on the
                               ## newer tags, rev by rev, almost as though
                               ## each was branched on to the new dest.

   'CVS_APPLIED_TAGS_COUNT',  ## Statistics gathering
) ;


sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Source::cvs $self = $class->SUPER::new( @_ ) ;

   $self->{CVS_READ_SIZE} = 100_000;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_cvs_repo_spec( $spec )
      unless empty $spec;

   $self->parse_options( $options,
      "cd=s"          => sub { $self->{CVS_WORK_DIR} = $_[1] },
      "d=s"           => \my $date_spec,
      "k=s"           => sub { $self->{CVS_K_OPTION} = $_[1] },
      "kb"            => sub { $self->{CVS_K_OPTION} = "b" },
      "r=s"           => \my $rev_spec,
      "use-cvs"       => \$self->{CVS_USE_CVS},
#      "f+"            => \my $force_missing,
   );

#   if ( $force_missing && ! defined $rev_spec ) {
#      print STDERR
#         "Force missing (-f) may not be used without a revision spec (-r)\n" ;
#      $self->usage_and_exit ;
#   }
#

   $self->rev_spec( $rev_spec ) ;
   $self->date_spec( $date_spec ) ;
   $self->force_missing( defined $rev_spec ) ;
#   $self->force_missing( $force_missing ) ;

   return $self ;
}



sub init {
   my VCP::Source::cvs $self= shift ;

   $self->{CVS_DIRECT} = ! $self->{CVS_USE_CVS} && do {
       # If the CVSROOT does not start with a colon, it must be
       # a direct read.  But check to see if it exists anyway,
       # because we'd prefer CVS give the error messages around here.
       my $root = $self->cvsroot;
       substr( $root, 0, 1 ) ne ":" && -d $root;
   };

   my $files = $self->repo_filespec ;
   $self->deduce_rev_root( $files ) 
      unless defined $self->rev_root;

   ## Don't normalize the filespec.
   $self->repo_filespec( $files ) ;

   ## Make sure the cvs command is available
   $self->command_stderr_filter(
      qr{^
         (?:cvs\s
             (?:
                (?:server|add|remove):\suse\s'cvs\scommit'\sto.*
                |tag.*(?:waiting for.*lock|obtained_lock).*
		|update:\swarning:\s.*pertinent
             )
        )\n
      }x
   ) ;

   ## Doing a CVS command or two here also forces cvs to be found in new(),
   ## or an exception will be thrown.
   if ( $self->{CVS_DIRECT} ) {
      my $root = $self->cvsroot;
      $self->{CVS_INFO} = <<TOHERE;
CVSROOT=$root
TOHERE
      my $rev_spec = $self->rev_spec;
      if ( defined $rev_spec ) {
         for ( $rev_spec ) {
            if ( /^([^:]*):([^:]*)\z/ ) {
               @$self{qw( CVS_MIN_REV CVS_MAX_REV )} = ( $1, $2 );
            }
            else {
               die "can't parse revision specification '$rev_spec'";
            }
         }
      }
   }
   else {
      $self->cvs( ['--version' ], undef, \$self->{CVS_INFO} ) ;

      ## This does a checkout, so we'll blow up quickly if there's a problem.
      my $work_dir = $self->{CVS_WORK_DIR};
      unless ( defined $work_dir ) {
         $self->create_cvs_workspace ;
      }
      else {
         $self->work_root( File::Spec->rel2abs( $work_dir, start_dir ) ) ; 
         $self->command_chdir( $self->work_path ) ;
      }
   }
}


sub is_incremental {
   my VCP::Source::cvs $self= shift ;
   my ( $r ) = @_;

   my ( $file, $rev_id ) = ( $r->vcp_source_scm_fn, $r->rev_id );

   my $bootstrap_mode = (
      $r->is_founding_rev
      || $self->is_bootstrap_mode( $file )
   );

   return $bootstrap_mode ? 0 : "incremental" ;
}


sub rev_spec {
   my VCP::Source::cvs $self = shift ;
   $self->{CVS_REV_SPEC} = shift if @_ ;
   return $self->{CVS_REV_SPEC} ;
}


sub rev_spec_cvs_option {
   my VCP::Source::cvs $self = shift ;
   return defined $self->rev_spec? "-r" . $self->rev_spec : (),
}


sub date_spec {
   my VCP::Source::cvs $self = shift ;
   $self->{CVS_DATE_SPEC} = shift if @_ ;
   return $self->{CVS_DATE_SPEC} ;
}


sub date_spec_cvs_option {
   my VCP::Source::cvs $self = shift ;
   return defined $self->date_spec ? "-d" . $self->date_spec : (),
}


sub force_missing {
   my VCP::Source::cvs $self = shift ;
   $self->{CVS_FORCE_MISSING} = shift if @_ ;
   return $self->{CVS_FORCE_MISSING} ;
}


sub denormalize_name {
   my VCP::Source::cvs $self = shift ;
   ( my $n = '/' . $self->SUPER::denormalize_name( @_ ) ) =~ s{/+}{/}g;
   return $n;
}


sub handle_header {
   my VCP::Source::cvs $self = shift ;
   my ( $header ) = @_ ;

   $header->{rep_type} = 'cvs' ;
   $header->{rep_desc} = $self->{CVS_INFO} ;
   $header->{rev_root} = $self->rev_root ;
   $header->{branches} = $self->branches;

   $self->dest->handle_header( $header ) ;
   return ;
}

sub _fix_state {
    my ($self, $state, $file) = @_;

    my $cvsroot = $self->repo_id;
    $cvsroot =~ s/^.*://;
    $state->{file} =~ s|^$cvsroot/||;
    $state->{file} =~ s|Attic/([^/]+)$|$1|;

    if (exists $file->{$state->{file}}) {
	my $r = $file->{$state->{file}};
	debug "doing $state->{file} $state->{rev}" if debugging;
	if ($r->rev_id eq $state->{rev}) {
	    my $wp = $self->work_path( "revs", $r->source_name, $r->source_rev_id );
	    $r->work_path( $wp ) ;
	    $self->mkpdir( $wp ) ;

	    copy_file($r->vcp_source_scm_fn, $wp);
	}
	else {
	    debug "failback to individual checkout";
	    $self->get_rev($r);
	}
    }
}

sub _cvs_status_output {
    my ($self, $fh, $file) = @_;
    my $state;

    while (<$fh>) {
	if (m|^===================================================================|) {
	    $self->_fix_state($state, $file) if $state;
	    my $state = {};
	}
	elsif (m/Working revision:\s+([\d\.]+)/) {
	    $state->{rev} = $1;
	}
	elsif (m/Repository revision:\s+[\d\.]+\s+(.*),v/) {
	    $state->{file} = $1;
	}
    }
    $self->_fix_state($state, $file) if $state;
}

sub fetch_files {
    my VCP::Source::cvs $self = shift ;
    my $max_time = 0;
    my %file;
    my $common_parent;
    my $common_offset;

    return map $self->get_rev( $_ ), @_
	if $self->{CVS_DIRECT} || $#_ < 3;

    my $samerev = $_[0]->rev_id;
    for my $r (@_) {
	my $t = $r->time ;
	$max_time = $t if $t >= $max_time;
	$file{$r->vcp_source_scm_fn} = $r;

	if (!$common_parent) {
	    $common_parent = $r->vcp_source_scm_fn;
	    $common_parent =~ s|/[^/]+$|/|;
	    $common_offset = index ($common_parent, '/') + 1;
	}
	elsif (index ($common_parent, '/', $common_offset) > 0) {
	    $common_parent =~ s|/[^/]+/$|/|
		while substr($r->vcp_source_scm_fn, 0, length($common_parent))
			     ne $common_parent;
	}

	undef $samerev if $samerev && $r->rev_id ne $_[0]->rev_id;
    }

    chop $common_parent;
    eval {
    $self->cvs(['update', '-d', $samerev ? ('-r', $_[0]->rev_id) :
		('-D', VCP::Rev::iso8601format($max_time), 
		 $_[0]->branch_id ? ('-r', $_[0]->branch_id) : ()), $common_parent]);

    $self->cvs(['status', $common_parent], undef, sub { $self->_cvs_status_output(@_, \%file) });
    };

    debug "fast update error: $@, fallback to iteration"
	if debugging && $@;

    return map $self->get_rev( $_ ), @_ if $@;

    return map { $self->work_path( "revs", $_->source_name, $_->source_rev_id ) ; } @_;
}

sub get_rev {
   my VCP::Source::cvs $self = shift ;

   my VCP::Rev $r ;
   ( $r ) = @_ ;

   BUG "can't check out ", $r->as_string, "\n"
      unless $r->is_base_rev || $r->action eq "add" || $r->action eq "edit";

   my $wp = $self->work_path( "revs", $r->source_name, $r->source_rev_id ) ;
   $r->work_path( $wp ) ;
   $self->mkpdir( $wp ) ;

   if ($self->{CVS_DIRECT}) {
       $self->cvs(["checkout", "-r" . $r->source_rev_id, "-p",
		   $r->vcp_source_scm_fn], undef, $wp);
   }
   else {
       $self->cvs(['update', '-d', '-r', $r->source_rev_id, $r->vcp_source_scm_fn]);
       copy_file($r->vcp_source_scm_fn, $wp);
   }

   return $wp;
}


sub _concoct_base_rev {
   my VCP::Source::cvs $self = shift;
   my ( $r ) = @_;

   Carp::confess "undefined \$r" unless defined $r;

   ## TODO: test for when the base revision is on a different branch?
   if ( ! defined( $r->previous_id ) && $self->is_incremental( $r ) ) {
      my $rev_id = $r->rev_id ;

      $rev_id =~ s{(\d+)$}{$1-1}e ;

      Carp::confess "illegal rev concocted: $rev_id (from ", $r->as_string, ")"
         if $rev_id =~ /\.[^1-9]\d*\z/;

      my $br = VCP::Rev->new(
         id                   => $self->denormalize_name( $r->name )."#$rev_id",
         vcp_source_scm_fn    => $r->vcp_source_scm_fn,
         name                 => $r->name,
         source_name          => $r->source_name,
         source_filebranch_id => $r->source_filebranch_id,
         source_repo_id       => $r->source_repo_id,
         branch_id            => $r->branch_id,
         source_branch_id     => $r->source_branch_id,
         rev_id               => $rev_id,
         source_rev_id        => $rev_id,
         type                 => $r->type,
      );

      $r->previous_id( $br->id );
      $r->previous( $br );

      debug "concocted ", $br->as_string if debugging;

      my $ok = eval {
         my $nr = $self->revs->get_last_added( $br ) ;
         $nr->previous_id( $br->id ) ;
         $nr->previous( $br ) ;
         1 ;
      } ;
      die $@ unless $ok || 0 < index $@, "t find revision";

      $self->revs->add( $br );
   }
}


sub _concoct_placeholder_rev {
   my VCP::Source::cvs $self = shift;
   my ( $r, $branch_tag, $magic_branch_number, $time ) = @_;
   ## $r is either the parent of the branch or the first rev on the branch

   $magic_branch_number =~ /\A((?:\d+\.\d+\.)+)0\.(\d+)\z/
       or BUG "can't parse magic branch number '$magic_branch_number'";
   my ( $branch_number, $rev_id ) = ( "$1$2", "$1$2.0" ); ## .0 'cuz it's a placeholder
   ( my $filebranch_id = $r->source_filebranch_id ) =~ s/<.*>\z/<$branch_number>/;

   my $pr = VCP::Rev->new(
      action               => "placeholder",
      id                   => $self->denormalize_name( $r->name ) . "#$rev_id",
      vcp_source_scm_fn    => $r->vcp_source_scm_fn,
      name                 => $r->name,
      source_name          => $r->source_name,
      source_filebranch_id => $filebranch_id,
      source_repo_id       => $r->source_repo_id,
      time                 => $time,
      branch_id            => $branch_tag,
      source_branch_id     => $branch_tag,
      rev_id               => $rev_id,
      source_rev_id        => $rev_id,
      user_id              => $r->user_id,
   );

   debug "concocted ", $pr->as_string if debugging;

   $self->revs->add( $pr );

   return $pr;
}


sub _concoct_cloned_rev {
   my VCP::Source::cvs $self = shift;
   my ( $r, $branch_tag ) = @_;

   ( my $filebranch_id = $r->source_filebranch_id ) =~ s/<.*>\z/<$branch_tag>/;

   my $pr = VCP::Rev->new(
      action               => "placeholder",
      id                   => $r->id . "<$branch_tag>",
      vcp_source_scm_fn    => $r->vcp_source_scm_fn,
      name                 => $r->name,
      source_name          => $r->source_name,
      source_filebranch_id => $filebranch_id,
      source_repo_id       => $r->source_repo_id,
      time                 => $r->time,
      branch_id            => $branch_tag,
      source_branch_id     => $branch_tag,
      rev_id               => $r->rev_id,
      source_rev_id        => $r->rev_id,
      user_id              => $r->user_id,
      previous_id          => $r->id,
      previous             => $r,
   );

   debug "concocted ", $pr->as_string if debugging;

   $self->revs->add( $pr );

   return $pr;
}


sub get_revs_from_log_file {
   my VCP::Source::cvs $self = shift;

   $self->{CVS_LOG_STATE} = '' ;
   $self->revs( VCP::Revs->new ) ;

   ## We need to watch STDERR for messages like
   ## cvs log: warning: no revision `ch_3' in `/home/barries/tmp/cvsroot/foo/add/f4,v'
   ## Files that cause this warning need to have some revisions ignored because
   ## cvs log will emit the entire log for these files in addition to 
   ## the warning, including revisions checked in before the first tag and
   ## after the last tag.
   my %ignore_files ;
   my $ignore_file = sub {
      exists $ignore_files{$self->{CVS_NAME_REP_NAME}->{$_[0]}} ;
   } ;

   $self->{CVS_LOG_FILE_DATA} = {} ;
   $self->{CVS_LOG_REV}       = {} ;
   $self->{CVS_SAW_EQUALS}    = 0 ;

   # The log command must be run in the directory above the work root,
   # since we pass in the name of the workroot dir as the first dir in
   # the filespec.
   my $tmpdir = $self->tmp_dir( "co" ) ;

   my $spec = $self->repo_filespec;
   $spec =~ s{/...\z}{}; ## hack, since cvs always recurses.
   my @log_parms = (
      "log",
      $self->rev_spec_cvs_option,
      $self->date_spec_cvs_option,
      length $spec ? $spec : (),
   );
   pr "running ", shell_quote "cvs", @log_parms;
   $self->cvs(
      \@log_parms,
      undef,
      sub { $self->parse_cvs_log_output( @_ ) },
      {
         in_dir => $tmpdir,
         stderr_filter => sub {
            my ( $err_text_ref ) = @_ ;
            $$err_text_ref =~ s{
               ## This regexp needs to gobble newlines.
               ^cvs(?:\.exe)?\slog:\swarning:\sno\srevision\s.*?\sin\s[`"'](.*)[`"']\r?\n\r?  
               }{
                  $ignore_files{$1} = undef ;
            '' ;
            }gxmei ;
         },
      },
   ) ;

   my $revs = $self->revs ;

   ## Figure out the time stamp range for force_missing calcs.
   my ( $min_rev_spec_time, $max_rev_spec_time ) ;
   if ( $self->force_missing ) {
      ## If the rev_spec is /:$/ || /^:/, we tweak the range ends.
      my $max_time = 0 ;
      $max_rev_spec_time = 0 ;
      $min_rev_spec_time = 0 if substr( $self->rev_spec, 0, 1 ) eq ':' ;
      for my $r ( @{$revs->as_array_ref} ) {
         next if $r->is_base_rev ;
         my $t = $r->time ;
         $max_time = $t if $t >= $max_rev_spec_time ;
	 next if $ignore_file->( $r->vcp_source_scm_fn ) ;
         $min_rev_spec_time = $t if $t <= ( $min_rev_spec_time || $t ) ;
         $max_rev_spec_time = $t if $t >= $max_rev_spec_time ;
      }
#      $max_rev_spec_time = $max_time if substr( $self->rev_spec, -1 ) eq ':' ;
      $max_rev_spec_time = undef if substr( $self->rev_spec, -1 ) eq ':' ;

      debug(
	 "including files in ['",
	 localtime( $min_rev_spec_time ),
	 "'..'",
	 defined $max_rev_spec_time
	    ? localtime( $max_rev_spec_time )
	    : "<end_of_time>",
	 "']"
      ) if debugging ;
   }

   ## Remove extra revs from queue by copying from $revs to $self->revs().
   ## TODO: Debug simultaneous use of -r and -d, since we probably are
   ## blowing away revs that -d included that -r didn't.  I haven't
   ## checked to see if we do or don't blow said revs away.
   my %oldest_revs ;
   $self->revs( VCP::Revs->new ) ;
   for my $r ( @{$revs->as_array_ref} ) {
      if ( $ignore_file->( $r->vcp_source_scm_fn ) ) {
	 if (
	       (!defined $min_rev_spec_time || $r->time >= $min_rev_spec_time)
	    && (!defined $max_rev_spec_time || $r->time <= $max_rev_spec_time)
	 ) {
	    debug(
	       "including file ", $r->as_string
	    ) if debugging ;
	 }
	 else {
	    debug(
	       "ignoring file ", $r->as_string,
	       ": no revisions match -r"
	    ) if debugging ;
            ## TODO: do a reverse index.
            for my $nr ( @{$revs->as_array_ref} ) {
               if ( ( $nr->previous_id || "" ) eq $r->id ) {
                  $nr->previous_id( undef );
                  $nr->previous( undef );
                }
            }
	    next ;
	 }
      }
      ## Because of the order of the log file, the last rev set is always
      ## the first rev in the range.
      $oldest_revs{$r->source_filebranch_id} = $r ;

      if ( $r->rev_id =~ /(.*)\.(\d+)\.1\z/ ) {
         my ( $parent_rev_id, $branch_number ) = ( $1, $2 );
         my $magic_branch_number = "$parent_rev_id.0.$branch_number";
         my $pr = $self->_concoct_placeholder_rev(
            $r, $r->branch_id, $magic_branch_number, $r->time
         );
         $pr->previous_id( $r->previous_id );
         $pr->previous( $r->previous );
         $r->previous_id( $pr->id );
         $r->previous( $pr );
         push @{$self->{CVS_FIRST_BRANCHED_REVS}->{$r->branch_id}}, $pr
      }

      $self->revs->add( $r ) ;
   }

   $self->_concoct_base_rev( $_ ) for values %oldest_revs;

   pr "found ", 0+$self->revs->get, " revs\n";
}


sub get_revs_direct {
   my VCP::Source::cvs $self = shift;

   require File::Find;
   require Cwd;

   my $root = $self->cvsroot;
   my $spec = $self->repo_filespec;

#   my $cwd = Cwd::cwd;
   chdir $root or die "$!: $root\n";

   $spec .= "/..." if $spec !~ m{\/...\z} && -d $spec;
   $spec =~ s{^/+}{};

   local $| = 1;
   my $hash_count = 0;
   my $hash_time  = 0;

   my @files;

   $File::Find::prune = 0;  ## Suppress used only once warning.

   my %seen;

   # Jump as far down the directory hierarchy as we can.
   # Figure out if this is a specific file by adding ,v
   # and checking for it (here and in the Attic), but that's
   # not worth the hassle right now.  It would save us some
   # work when pulling a file out of the top of a big dir tree,
   # though.
   ( my $start = $spec ) =~ s{(^|/+)[^/]*(\*|\?|\.\.\.).*}{};

   if ( -f "$start,v" ) {
      push @files, $start;
      $self->parse_rcs_file( $start );
      goto SKIP_FILE_FIND;
   }

   ( my $attic_start = $start ) =~ s{((?:[\\/]|\A))([^\\/]+)\z}{${1}Attic/$2};
   if ( -f "$attic_start,v" ) {
      push @files, $attic_start;
      $self->parse_rcs_file( $attic_start );
      goto SKIP_FILE_FIND;
   }

   while ( length $start && ! -d $start ) {
      last unless $start =~ s{/+[^/]*\z}{};
   }

   $spec = substr( $spec, length $start );
   $spec =~ s{^[\\/]+}{}g;

   my $pat = compile_shellish $spec, { star_star => 0 };

   lg "scanning $root/$start/...";
   print STDERR "scanning $root/$start/...: ";
   $self->{CVS_PRINTING_HASHES} = 1;
   $start = "." unless length $start && -d $start;

   my $ok = eval {
      File::Find::find(
          {
              no_chdir => 1,
              wanted => sub {

                  if ( /CVSROOT\z/ ) {
                      $File::Find::prune = 1;
                      return;
                  }

                  return if -d;

                  s/^\.\///;
                  return unless s/,v\z//;

                  if ( -f _ && $_ =~ $pat ) {
                     ( my $undeleted_path = $_ ) =~ s/(\/)Attic\//$1/;

                     if ( $seen{$undeleted_path}++ ) {
                         print STDERR "\n";
                         pr "scanner found $undeleted_path again";
                         return;
                     }

                     eval {
                        $self->parse_rcs_file( $_ );
                        1;
                     } or do {
                        print STDERR "\n" if $self->{CVS_PRINTING_HASHES};
                        $self->{CVS_PRINTING_HASHES} = 0;
                        die "$@ for $_\n";
                     };

                     push @files, $_;
                  }

                  unless ( $hash_count++ % 50 ) {
                     my $t = time;
                     if ( $t > $hash_time + 5 ) {
                        $hash_time = $t;
                        print STDERR "#";
                     }
                  }

              },
          },
          $start
      );
      1;
   };
   my $x = $@;

   print STDERR "\n" if $self->{CVS_PRINTING_HASHES};
   $self->{CVS_PRINTING_HASHES} = 0;

   die $x unless $ok;

SKIP_FILE_FIND:

   pr "found ", 0+@files, " file(s)";

   if ( @files ) {
      $self->queue_parsed_revs;

   }

#   chdir $cwd or die "$!: $cwd";

   return \@files;
}

## Used to detect symbols for branch tags and vendor branch tags.
sub _is_branch_tag($) {
   return $_[0] =~ /\.0\.\d+\z/
      || ! ( $_[0] =~ tr/.// % 2 );
}


{
   my $special = "\$,.:;\@";
   my $idchar = "[^\\s$special\\d\\.]";  # Differs from man rcsfile(1)
   my $num_re = "[0-9.]+";
   my $id_re = "(?:(?:$num_re)?$idchar(?:$idchar|$num_re)*)";

   my %id_map = (
       # RCS file => "cvs log" (& its parser) field name changes
       "log"    => "comment",
       "expand" => "keyword",
   );

   sub _xdie {
      my VCP::Source::cvs $self = shift;
      my $buffer = $self->{CVS_RCS_FILE_BUFFER};

      my $pos = pos( $$buffer ) || 0;

      my $line = $self->{CVS_RCS_FILE_LINES}
         + ( substr( $$buffer, 0, $pos ) =~ tr/\n// );

      my $near = substr( $$buffer, $pos, 100 );
      $near .= "..." if $pos + 100 > length $$buffer;

      $near =~ s/\n/\\n/g;
      $near =~ s/\r/\\r/g;
      die @_, " in RCS file $self->{CVS_RCS_FILE_PATH}, near line $line: '$near'\n";
   }

   sub _read_rcs_goodness {
      my VCP::Source::cvs $self = shift;
      my ( $fh ) = @_;

      $self->_xdie( "read beyond end of file" )
         if $self->{CVS_RCS_FILE_EOF};

      my $buffer = $self->{CVS_RCS_FILE_BUFFER};

      my $pos = pos( $$buffer ) || 0; ## || 0 in case no matches yet.
      $self->{CVS_RCS_FILE_LINES} += substr( $$buffer, 0, $pos ) =~ tr/\n//;
      substr( $$buffer, 0, $pos ) = "";

      my $c = 0;
      {
         my $little_buffer;
         $c = read $fh, $little_buffer, $self->{CVS_READ_SIZE};

         ## Hmmm, sometimes $c comes bak undefined at end of file,
         ## with $! not TRUE.  most odd.  Tested with 5.6.1 and 5.8.0
         $self->_xdie( "$! reading rcs file" )
            if ! defined $c && $!;

         $$buffer .= $little_buffer if $c;
      };

      pos( $$buffer ) = 0;  ## Prevent undefs from tripping up code later
      $self->{CVS_RCS_FILE_EOF} ||= ! $c;
      1;
   }

   # Read an RCS file in to $self->{CVS_FILE_DATA}
   sub parse_rcs_file {
      my VCP::Source::cvs $self = shift;

      profile_start ref( $self ) . " parse_rcs_file()" if profiling;

      my ( $file ) = @_;

      require File::Spec::Unix;
      my $path = $self->{CVS_RCS_FILE_PATH} = File::Spec::Unix->canonpath(
         join "", $self->cvsroot, "/", $file, ",v"
      );

      debug "going to read $path" if debugging;

      open F, "<$path" or die "$!: $path\n";
      binmode F;

      my $rev_id;

      $file =~ s{\A(.*?)[\\/]+Attic}{$1};

      my $file_data = $self->{CVS_FILE_DATA}->{$file} = {
         rcs     => $path,
         working => $file,
         revs    => {},
      };

      $self->{CVS_RCS_FILE_EOF} = 0;
      $self->{CVS_RCS_FILE_LINES} = 0;
      $self->{CVS_RCS_FILE_BUFFER} = \(my $b = "");
      local $_;
      *_ = $self->{CVS_RCS_FILE_BUFFER};
      pos = 0;

      my $h;  # which hash to stick the data in.  As the parsing progresses,
              # this is pointed at the per-file metadata
              # hash or a per-revision hash so that the low level
              # key/value parsing just parses things and stuffs them 
              # in $h and it'll be stuffing them in the right place.

      my $id; # the name of the element to assign the next value to

   START:
      $self->_read_rcs_goodness( \*F );
      if ( /\A($id_re)\s+(?=\S)/gc ) {
         $h = $file_data;
         $id = $1;
         $id = $id_map{$id} if exists $id_map{$id};

         # had a buggy RE once...
         $self->_xdie( "$id should not have been parsed as an identifier" )
            if $id =~ /\A$num_re\z/o;

         debug "parsing field ", $id
            if debug_parser && debugging;

         goto VALUE;
      }
      else {
         ## ASSume first identifier < 100 chars
         if ( ! $self->{CVS_RCS_FILE_EOF} && length() < 100 ) {
            debug "reading more for START parsing"
               if debug_parser && debugging;

            $self->_read_rcs_goodness( \*F );
            goto START;
         }

         $self->_xdie( "RCS file should begin with an identifier" );
      }

   PARAGRAPH_START:
      if ( /\G($num_re)\r?\n/gc ) {
         $rev_id = $1;

         if ( debug_parser && debugging ) {
            my $is_new = ! exists $file_data->{revs}->{$rev_id};
            debug
               "parsing", $is_new ? () : " MORE", " ", $rev_id, " fields";
         }

         ## Throw away unwanted revs ASAP to save space and so the part of
         ## the culling algorithm that estimates limits can find the
         ## oldest / newest wanted revs easily.
         my $keep = 1;
         $keep &&= VCP::Rev->cmp_id( $rev_id, $file_data->{min_rev_id} ) >= 0
            if defined $file_data->{min_rev_id};
         $keep &&= VCP::Rev->cmp_id( $rev_id, $file_data->{max_rev_id} ) <= 0
            if defined $file_data->{max_rev_id};

         if ( $keep ) {
            ## Reuse the existing hash if this is a second pass
            $h = $file_data->{revs}->{$rev_id} ||= {};
         }
         else {
            ## create a throw-away hash to keep the logic simpler
            ## in the parser (this way it doesn't have to test
            ## $h for definedness each time before writing it).
            $h = {};
         }
         $h->{rev_id} = $rev_id;
         $id = undef;

         goto ID;
      }
      elsif ( /\Gdesc\s+(?=\@)/gc ) {
         ## We're at the end of the first set of per-rev sections of the
         ## RCS file, switch back to the per-file metadata hash to capture
         ## the "desc" field.
         $h = $file_data;
         $id = "desc";
         $id = $id_map{$id} if exists $id_map{$id};
         debug "parsing field ", $id
            if debug_parser && debugging;

         goto VALUE;
      }
      else {
         ## ASSume no identifier or rev number is > approx 1000 chars long
         if ( ! $self->{CVS_RCS_FILE_EOF} && length() - pos() < 1000 ) {
            debug "reading more for PARAGRAPH_START parsing"
               if debug_parser && debugging;

            $self->_read_rcs_goodness( \*F );
            goto PARAGRAPH_START;
         }

         $self->_xdie( "expected an identifier or version string" );
      }

   ID:
      if ( /\G($id_re)(?:\s+(?=\S)|\s*(?=;))/gc ) { # No ^, unlike PARAGRAPH_START's first RE
         $id = exists $id_map{$1} ? $id_map{$1} : $1;

         # had a buggy RE once...
         $self->_xdie( "$id should not have been parsed as an identifier" )
            if debug_parser && $id =~ /\A$num_re\z/o;

         debug "parsing field ", $id
            if debug_parser && debugging;

#         goto VALUE;
      }
      else {
         ## ASSume no identifier > approx 1000 chars long
         if ( ! $self->{CVS_RCS_FILE_EOF} && length() - pos() < 1000 ) {
            debug "reading more for ID parsing"
               if debug_parser && debugging;

            $self->_read_rcs_goodness( \*F );
            goto ID;
         }

         $self->_xdie( "expected an identifier or version string" );
      }

   VALUE:
      $self->_xdie( "already assigned to '$h->{$id}'" )
         if debug_parser && exists $h->{$id};

   VALUE_DATA:
      if ( substr( $_, pos, 1 ) eq ";" ) { #/\G(?=;)/gc ) {
         $h->{$id} = "";
#         goto VALUE_END;
      }
      elsif ( /\G\@/gcs ) {
         # It's an RCS string (@...@)

         goto STRING unless $id eq "text";

      TEXT:
         # Ignore the often veeeerry long text field for now.
         #
         # This line causes segfaults in perl5.6.1 and perl5.8.1
         # under linux:
         #
         # if ( /\G(?:[^\@]|\@\@)*/gc ) {
         #
         # So, instead, we look bite off the chunks by looking for
         # all text up to an @ and eating it.
         if ( /\G[^\@]*/gc ) {
            goto TEXT if /\G\@\@/gc;

            unless ( /\G\@(?=[^\@])/gc ) {
               # NOTE: RCS files must end in a newline, so it's safe
               # to assume a non-@ after the @.
               debug "reading more for TEXT parsing"
                  if debug_parser && debugging;

               $self->_read_rcs_goodness( \*F );
               goto TEXT;
            }
         }

         ## TODO: save this, or the location of the text, so that
         ## we can get it ourselves later instead of executing cvs.
         $h->{text} = "FILE TEXT NOT EXTRACTED FROM RCS FILE $path\n";

         goto VALUE_END;

      STRING:
         if ( /\G((?:[^\@]|\@\@)*)/gc ) {
            $h->{$id} .= $1 unless $id eq "text";
            unless ( /\G\@(?=[^\@])/gc ) {
               # NOTE: RCS files must end in a newline, so it's safe
               # to assume a non-@ after the @.
               debug "reading more for STRING parsing"
                  if debug_parser && debugging;

               $self->_read_rcs_goodness( \*F );
               goto STRING;
            }
         }

         $self->_xdie( "odd number of '\@'s in RCS string for field '$id'" )
             if ( $h->{$id} =~ tr/\@// ) % 2;

         $h->{$id} =~ s/\@\@/\@/g;

#         goto VALUE_END;
      }
      elsif ( /\G(?!\@)/gc ) {
         # Not a string, so it's a semicolon delimited value

      NOT_STRING:
         if ( /\G([^;]+)/gc ) {
            $h->{$id} .= $1;
            unless ( /\G(?=;)/gc ) {
               debug "reading more for NOT_STRING parsing"
                  if debug_parser && debugging;

               $self->_read_rcs_goodness( \*F );
               goto NOT_STRING;
            }
         }

         if ( $id eq "date" ) {
            ## The below seems to monkey with $_, so protect pos().
            my $p = pos;
            $h->{time} = $self->parse_time( $h->{date} );
            pos = $p;
         }

#         goto VALUE_END;
      }
      else {
         # We only need one char.
         if ( ! $self->{CVS_RCS_FILE_EOF} && length() - pos() < 1 ) {
            debug "reading more for VALUE_DATA parsing"
               if debug_parser && debugging;

            $self->_read_rcs_goodness( \*F );
            goto VALUE_DATA;
         }
         $self->_xdie( "unable to parse value for $id" );
      }

   VALUE_END:
      debug "$id='",
         substr( $h->{$id}, 0, 100 ),
         length $h->{$id} > 100 ? "..." : (),
         "'"
         if debug_parser && debugging;

      if ( $id eq "symbols" ) {
         my %tags;

         for ( split /\s+/, $h->{symbols} ) {
            my ( $tag, $rev_id ) = split /:/, $_, 2;
            $tags{$tag} = $rev_id;
            push @{$h->{RTAGS}->{$rev_id}}, $tag;

            ## tags with rev_ids like "1.1.0.2" are branch tags.
            ## tags with an even number of dots like "1.1.1" are vendor
            ## branch tags.
            $self->branches->add( VCP::Branch->new( branch_id => $tag ) )
               if _is_branch_tag $rev_id;
         }
         delete $h->{symbols};


         ## Convert the passed-in min and max revs from symbolic tags
         ## to dotted rev numbers.  The "symbols" $id only occurs
         ## once in a file, so this gets executed once and is setting
         ## fields in the file metadata (not in a rev's metadata).
         if ( defined $self->{CVS_MIN_REV} ) {
            my $t = $self->{CVS_MIN_REV};
            $t = exists $tags{$t} ? $tags{$t} : undef
               if $t =~ /[^\d.]/;

            unless ( empty $t ) {
               $h->{min_rev_id} = [ VCP::Rev->split_id( $t ) ];
            }
            else {
               # note that we only get here if a -r option was
               # passed, so later code can look at this to see if
               # it needs to cull old revs.  Store the
               # file metadata in a list to have too-old revs
               # culled because we could not find the tag in
               # this file.
               push @{$self->{CVS_CULL_OLD_REVS_FROM}}, $h;
            }
         }

         if ( defined $self->{CVS_MAX_REV} ) {
            my $t = $self->{CVS_MAX_REV};
            $t = exists $tags{$t} ? $tags{$t} : undef
               if $t =~ /[^\d.]/;
            unless ( empty $t ) {
               $h->{max_rev_id} = [ VCP::Rev->split_id( $t ) ];
            }
            else {
               # note that we only get here if a -r option was
               # passed, so later code can look at this to see if
               # it needs to cull old revs.  Store the
               # file metadata in a list to have too-old revs
               # culled because we could not find the tag in
               # this file.
               push @{$self->{CVS_CULL_NEW_REVS_FROM}}, $h;
            }
         }
      }

      $id = undef;

   VALUE_END_DELIMETER:
      if ( /\G[ \t]*(?:\r?\n|;[ \t]*(?:\r?\n|(?=[^ \t;]))|(?=[^ \t;]))/gc ) {
      VALUE_END_WS:
         if ( /\G(?=\S)/gc ) {
            goto ID;
         }

         if ( /\G[ \t\r\n]*(\r?\n)+(?=\S)/gc ) {
            goto PARAGRAPH_START;
         }

         ## ASSume no runs of \v or \r\n of mroe than 1000 chars.
         if ( ! $self->{CVS_RCS_FILE_EOF} && length() - pos() < 1000 ) {
            debug "reading more for VALUE_END_WS parsing"
               if debug_parser && debugging;

            $self->_read_rcs_goodness( \*F );
            goto VALUE_END_WS;
         }

         goto FINISHED unless length;

         if ( ! /\G(\r?\n)/gc ) {
            $self->_xdie( "expected newline" );
         }
      }

      # ASSume semi + whitespace + 1 more char is less than 1000 bytes
      if ( length() - pos() < 1000 ) {
         debug "reading more for VALUE_END_DELIMETER parsing"
            if debug_parser && debugging;

         eval {
            $self->_read_rcs_goodness( \*F );
            goto FINISHED if /\G(\r?\n)*\z/gc;
            goto VALUE_END_DELIMETER;
         };
         if ( 0 == index $@, "read beyond end of file" ) {
            goto FINISHED if /\G(\r?\n)*\z/gc;
         }
         else {
            die $@;
         }

      }
      $self->_xdie( "expected optional semicolon and tabs or spaces" );

   FINISHED:

      close F;

## TODO: take out this debug code
my $min_rev_id = $file_data->{min_rev_id};
my $max_rev_id = $file_data->{max_rev_id};
BUG "Unexpected revision: $_"
   for grep(
      ( defined $min_rev_id
          && VCP::Rev->cmp_id( $_, $min_rev_id ) < 0
       )
       || ( defined $max_rev_id
          && VCP::Rev->cmp_id( $_, $max_rev_id ) > 0
       ),
       keys %{$file_data->{revs}}
    );

      ## Convert the hashes in to revs to let VCP::Rev fold comments,
      ## especially, and names in to the global hashes, saving memory.
      my %nexts;
      for my $rev_id ( keys %{$file_data->{revs}} ) {
         my $rev_data = $file_data->{revs}->{$rev_id};

         my $r = $self->_create_rev(
            $file_data,
            $rev_data,
            ( $rev_id =~ tr/.// ) == 1 && empty $rev_data->{next},
         );

         if ( defined $r ) {
            $nexts{$rev_data->{next}} = $r
               unless empty $rev_data->{next};
            $file_data->{revs}->{$rev_id} = $r;
         }
         else {
            delete $file_data->{revs}->{$rev_id};
         }
      }

      $self->_note_duplicate_branch_tags( $file_data->{RTAGS} );
      delete $file_data->{RTAGS}; # conserve memory.
      $self->{CVS_RCS_FILE_BUFFER} = undef;
      profile_end ref( $self ) . " parse_rcs_file()" if profiling;
   }
}


# Queuing is done after parsing so we can cull unwanted revs
# if force_missing is set.
sub queue_parsed_revs {
   my VCP::Source::cvs $self = shift;

   my $files = $self->{CVS_FILE_DATA};
   $self->{CVS_FILE_DATA} = undef; ## Conserve memory

   if ( $self->{CVS_CULL_OLD_REVS_FROM} || $self->{CVS_CULL_NEW_REVS_FROM} ) {

      my ( $min_cull_time, $max_cull_time ) ;
      for my $file_data ( values %$files ) {

         for my $r ( values %{$file_data->{revs}} ) {
            my $t = $r->time;

            $min_cull_time = $t
               if $file_data->{min_rev_id}
                  && ( ! defined $min_cull_time || $t < $min_cull_time ) ;

            $max_cull_time = $t
               if $file_data->{max_rev_id}
                  && ( ! defined $max_cull_time || $t > $max_cull_time ) ;
         }
      }

      my %dead_uns;

      if ( defined $min_cull_time ) {

         for ( @{$self->{CVS_CULL_OLD_REVS_FROM}} ) {
            debug "ignoring revisions in ",
               $_->{working},
               " before ",
               iso8601format $min_cull_time 
                  if debugging;
            my $revs = $_->{revs};

            delete $revs->{$_->rev_id}
               for grep $_->time < $min_cull_time, values %$revs;
         }
      }
      $self->{CVS_CULL_OLD_REVS_FROM} = undef;

      if ( defined $max_cull_time ) {

         for ( @{$self->{CVS_CULL_NEW_REVS_FROM}} ) {
            debug "ignoring revisions in ",
               $_->{working},
               " after  ",
               iso8601format $max_cull_time 
               if debugging;
            my $revs = $_->{revs};

            delete $revs->{$_->{rev_id}}
               for grep $_->{time} > $max_cull_time, values %$revs;
         }
      }
      $self->{CVS_CULL_NEW_REVS_FROM} = undef;
   }

   for my $file_data ( values %$files ) {
      next unless keys %{$file_data->{revs}};

      my %oldest_revs;
      my @file_revs;
      for my $r ( values %{$file_data->{revs}} ) {
         die "undefined rev" unless defined $r;

# for reference when we reimplement -d (but will be during parse time,
# like the -r support.
#            if ( defined $min_time && $_->{time} < $min_time ) {
#               debug "ignoring ", $file_data->{working}, "#",
#                  $_->{rev_id},
#                  ": rev time ",
#                  iso8601format $_->time,
#                  " < min time ",
#                  iso8601format $min_time,
#                  if debugging;
#               next;
#            }
#
#            if ( defined $max_time && $_->{time} > $max_time ) {
#               debug "ignoring ", $file_data->{working}, "#",
#                  $_->{rev_id},
#                  ": rev time ",
#                  iso8601format $_->time,
#                  " > max time ",
#                  iso8601format $max_time,
#                  if debugging;
#               next;
#            }

         if ( $r->rev_id =~ /\A(.*)\.(\d+)\.1\z/ ) {
            my ( $parent_rev_id, $branch_number ) = ( $1, $2 );
            my $magic_branch_number = "$parent_rev_id.0.$branch_number";
            my $pr = $self->_concoct_placeholder_rev(
               $r, $r->branch_id, $magic_branch_number, $r->time
            );
            if ( $pr ) {
               push @{$self->{CVS_FIRST_BRANCHED_REVS}->{
                     defined $r->branch_id ? $r->branch_id : ""
                  }},
                  $pr;

               $pr->previous_id( $r->previous_id );
               $pr->previous( $r->previous );
               $r->previous_id( $pr->id );
               $r->previous( $pr );
               push @file_revs, $pr;
            }
         }

         $self->revs->add( $r );
         push @file_revs, $r;
         my $or = $oldest_revs{$r->source_filebranch_id};
         $oldest_revs{$r->source_filebranch_id} = $r
            if ! $or
               || VCP::Rev->cmp_id( $r->rev_id, $or->rev_id ) < 0;
      }

      $self->_concoct_base_rev( $_ ) for values %oldest_revs;

      # Link all the revs to their predecessors on each branch
      # Could do this while parsing, but would need to disentangle
      # the CVS next and branch fields.
      my %revs_by_filebranch = ();
      for my $r ( @file_revs ) {
         push @{$revs_by_filebranch{$r->source_filebranch_id}}, $r;
      }

      for my $filebranch ( values %revs_by_filebranch ) {
         if ( @$filebranch > 1 ) {
            @$filebranch = sort
               { VCP::Rev->cmp_id( $a->rev_id, $b->rev_id ) }
               @$filebranch;

            my $pr = $filebranch->[0];
            for my $r ( @{$filebranch}[1..$#$filebranch] ) {
               debug "previous id for ", $r->as_string, ": ", $pr->id
                  if debugging;
               $r->previous_id( $pr->id );
               $r->previous( $pr );
               $pr = $r;
            }
         }

         my $r = $filebranch->[0];
         if ( ! empty $r->previous_id && ! $r->previous ) {
            my $pr = $self->revs->get( $r->previous_id );
            $r->previous( $pr );
         }
      }

## TODO: clean this loop out of here once we get beyond some real world
## tests.
      for my $r ( @file_revs ) {
         next if $r->is_base_rev
            || ( grep( $_ == $r, values %oldest_revs )
               && ! $self->is_incremental( $r )
            )
            || ! empty $r->previous_id;

die "no previous rev for ", $_->as_string;

#         my ( $branch_number, $rev_number ) =
#            $r->rev_id =~ /\A([\d.]+)\.(\d+)\z/
#            or die "can't parse $r->{rev_id}";
#         my $prev_id;
#
#         my $file = $r->vcp_source_scm_fn;
#
#         if ( 0 <= index $branch_number, "." ) {
#            if ( $rev_number == 0 ) {
#               ## On a branch, refer back to the parent if this is a placeholder
#               ( $prev_id = "/$file#$branch_number" ) =~ s/\.[^.]+\z//;
#            }
#            else {
#               ## Refer to the previous rev.
#               $prev_id = "/$file#$branch_number." . ( $rev_number - 1 );
#            }
#         }
#         else {
#            ## On the main trunk, only refer back if >= 1.2
#            $prev_id = "/$file#$branch_number." . ( $rev_number - 1 )
#               if $rev_number >= 2;
#         }
#
#         if ( defined $prev_id ) {
#            debug "previous id for ", $r->as_string, ": ", $prev_id
#               if debugging;
#            my $pr = $self->revs->get( $prev_id );
#            $r->previous_id( $pr->id );
#            $r->previous( $pr ) ;
#         }
      }
      delete $file_data->{revs};
   }
}


sub copy_revs {
   my VCP::Source::cvs $self = shift ;

   my $clone_count = 0;
   my $empty_branch_placeholders = 0;

   if ( $self->{CVS_DIRECT} ) {
      $self->{CVS_CULL_OLD_REVS_FROM} = undef;
      $self->{CVS_CULL_NEW_REVS_FROM} = undef;
      $self->get_revs_direct;
   }
   else {
      $self->get_revs_from_log_file;
   }

   ## Figure out what branches were initiated this transfer and create
   ## branch placeholders for any that don't have revisions on them.
   my $last_rev_time;
   for my $branch_tag ( keys %{$self->{CVS_BRANCH_PARENTS}} ) {
      my $min_time;
      my %branches_with_revs = map {
         ## Make the parallel branches occur at the same time as the
         ## first file revision appeared on the branch.
         $min_time = $_->time if ! defined $min_time || $_->time < $min_time;
         ( $_->name => undef );
      } @{$self->{CVS_FIRST_BRANCHED_REVS  }->{$branch_tag}};

      $_->time($min_time), $_->user_id('root')
	for @{$self->{CVS_FIRST_BRANCHED_REVS}{$branch_tag}};

      my @parents_to_be_branched = grep
         ! exists $branches_with_revs{$_->[0]->name},
         @{$self->{CVS_BRANCH_PARENTS}->{$branch_tag}};

      if ( $self->continue && $self->dest ) {
         ## Don't add placeholders for branches that already exist
         ## in destination.
         @parents_to_be_branched = grep {
            my ( $r, $magic_branch_number ) = @$_;

	    # bypass magic number introduced by cvs import
	    ($magic_branch_number =~ /^1\.1\.1$/) ? 0 : do {{
		
            $magic_branch_number =~ /\A(.*)\.0\.(\d+)/
               or BUG "couldn't parse '$magic_branch_number'";

            my $branch_number = "$1.$2";

            ( my $ph_filebranch_id = $r->source_filebranch_id )
               =~ s/<[^<>]*>\z/<$branch_number>/;

            ! defined $self->dest->last_rev_in_filebranch(
               $self->repo_id,
               $ph_filebranch_id
            );
	    }}
         } @parents_to_be_branched;
      }

      ## Use the time of the youngest rev in the transfer as the
      ## timestamp for branch creation.
      unless ( defined $min_time ) {
         unless ( defined $last_rev_time ) {
            for my $r ( $self->revs->get ) {
               $last_rev_time = $r->time
                  if ! defined $last_rev_time
                     || (
                        defined $r->time
                        && $last_rev_time < $r->time
                     );
            }
         }
         $min_time = $last_rev_time + 1;
      }

      for ( @parents_to_be_branched ) {
         my ( $r, $magic_branch_number ) = @$_;

         my $pr = $self->_concoct_placeholder_rev(
            $r, $branch_tag, $magic_branch_number, $min_time
         );

         if ( defined $pr ) {
            ++$empty_branch_placeholders;
            $pr->user_id('root');
            $pr->previous_id( $r->id );
            $pr->previous( $r );
         }
      }
   }

   ## conserve memory
   $self->{CVS_FIRST_BRANCHED_REVS} = undef;
   $self->{CVS_BRANCH_PARENTS}      = undef;

   ## Clone any aliased branches
   if ( $self->{CVS_ALIASED_BRANCH_TAGS} ) {
      my $t = $self->{CVS_ALIASED_BRANCH_TAGS};
      for my $r ( $self->revs->get ) {
         next if empty $r->branch_id || ! exists $t->{$r->branch_id};

         for ( @{$t->{$r->branch_id}} ) {
            $self->_concoct_cloned_rev( $r, $_ );
            ++$clone_count;
         }
      }
   }

   pr "queued ",
      0+$self->revs->get, " rev(s)",
      $clone_count
         ? " ($clone_count cloned)"
         : (),
      $empty_branch_placeholders
         ? " ($empty_branch_placeholders for empty branches)"
         : (),
      defined $self->{CVS_APPLIED_TAGS_COUNT}
         ? " with $self->{CVS_APPLIED_TAGS_COUNT} tag applications"
         : (),
      "\n";

   $self->SUPER::copy_revs;
}


# Here's a typical file log entry.
#
###############################################################################
#
#RCS file: /var/cvs/cvsroot/src/Eesh/Changes,v
#Working file: src/Eesh/Changes
#head: 1.3
#branch:
#locks: strict
#access list:
#symbolic names:
#        Eesh_003_000: 1.3
#        Eesh_002_000: 1.2
#        Eesh_000_002: 1.1
#keyword substitution: kv
#total revisions: 3;     selected revisions: 3
#description:
#----------------------------
#revision 1.3
#date: 2000/04/22 05:35:27;  author: barries;  state: Exp;  lines: +5 -0
#*** empty log message ***
#----------------------------
#revision 1.2
#date: 2000/04/21 17:32:14;  author: barries;  state: Exp;  lines: +22 -0
#Moved a bunch of code from eesh, then deleted most of it.
#----------------------------
#revision 1.1
#date: 2000/03/24 14:54:10;  author: barries;  state: Exp;
#*** empty log message ***
#=============================================================================
###############################################################################

## CVS allows multiple branch tags.  The last one is the master (oldest)
## tag, we need to clone each rev on the master branch in to all aliased
## tags.
sub _note_duplicate_branch_tags {
   my VCP::Source::cvs $self = shift;
   my ( $rtags ) = @_;
   
   for my $rev_id ( keys %$rtags ) {
      next unless _is_branch_tag $rev_id;

      my $tags = $rtags->{$rev_id};
      my $master_tag = pop @$tags;
      next unless @$tags;

      $self->{CVS_ALIASED_BRANCH_TAGS}->{$master_tag} = $tags;
   }
}

sub _create_rev_from_cvs_log_output {
   my VCP::Source::cvs $self = shift;
   return unless keys %{$self->{CVS_LOG_REV}} ;

   $self->{CVS_LOG_REV}->{comment} = ''
      if $self->{CVS_LOG_REV}->{comment} eq '*** empty log message ***' ;

   $self->{CVS_LOG_REV}->{comment} =~ s/\r\n?|\n\r/\n/g ;

   my $r = $self->_create_rev(
      $self->{CVS_LOG_FILE_DATA},
      $self->{CVS_LOG_REV},
      empty $self->{CVS_LOG_REV}->{lines}
   ) ;

   $self->{CVS_LOG_REV} = {} ;

   return unless defined $r;

   my $ok = eval {
      my $nr = $self->revs->get_last_added( $r ) ;
      $nr->previous_id( $r->id ) ;
      $nr->previous( $r ) ;
      1 ;
   } ;
   die $@ unless $ok || 0 < index $@, "t find revision";

   eval {
   $r->previous( $self->revs->get( $r->previous_id ) )
      if defined $r->previous_id;
   };

   die $@ if $@ && !$self->continue;

   $ok = eval {
      $self->revs->add( $r ) ;
      1 ;
   } ;
   unless ( $ok ) {
      if ( $@ =~ /Can't add same revision twice/ ) {
         pr $@ ;
      }
      else {
         die $@ ;
      }
   }
}

sub parse_cvs_log_output {
   my ( $self, $fh ) = @_ ;

   profile_start ref( $self ) . " parse_cvs_log_output()" if profiling;

   local $_ ;

   ## DOS, Unix, Mac lineends spoken here.
   while ( <$fh> ) {
      ## [1] See bottom of file for a footnote explaining this delaying of 
      ## clearing CVS_LOG_FILE_DATA and CVS_LOG_STATE until we see
      ## a ========= line followed by something other than a -----------
      ## line.
      ## TODO: Move to a state machine design, hoping that all versions
      ## of CVS emit similar enough output to not trip it up.

      ## TODO: BUG: Turns out that some CVS-philes like to put text
      ## snippets in their revision messages that mimic the equals lines
      ## and dash lines that CVS uses for delimiters!!

   PLEASE_TRY_AGAIN:
      if ( /^===========================================================*$/ ) {
         $self->_create_rev_from_cvs_log_output;
	 $self->{CVS_SAW_EQUALS} = 1 ;
	 next ;
      }

      if ( /^----------------------------*$/ ) {
         $self->_create_rev_from_cvs_log_output unless $self->{CVS_SAW_EQUALS} ;
	 $self->{CVS_SAW_EQUALS} = 0 ;
	 $self->{CVS_LOG_STATE} = 'rev' ;
	 next ;
      }

      if ( $self->{CVS_SAW_EQUALS} ) {
         $self->_note_duplicate_branch_tags(
            $self->{CVS_LOG_FILE_DATA}->{RTAGS}
         );
	 $self->{CVS_LOG_FILE_DATA} = {} ;
	 $self->{CVS_LOG_STATE} = '' ;
	 $self->{CVS_SAW_EQUALS} = 0 ;
      }

      unless ( $self->{CVS_LOG_STATE} ) {
	 if (
	    /^(RCS file|Working file|head|branch|locks|access list|keyword substitution):\s*(.*)/i
	 ) {
	    $self->{CVS_LOG_FILE_DATA}->{lc( (split /\s+/, $1 )[0] )} = $2 ;
	 }
	 elsif ( /^total revisions:\s*([^;]*)/i ) {
	 }
	 elsif ( /^symbolic names:/i ) {
	    $self->{CVS_LOG_STATE} = 'tags' ;
	    next ;
	 }
	 elsif ( /^description:/i ) {
	    $self->{CVS_LOG_STATE} = 'desc' ;
	    next ;
	 }
	 else {
	    carp "Unhandled CVS log line '$_'" if /\S/ ;
	 }
      }
      elsif ( $self->{CVS_LOG_STATE} eq 'tags' ) {
	 if ( /^\S/ ) {
	    $self->{CVS_LOG_STATE} = '' ;
	    goto PLEASE_TRY_AGAIN ;
	 }
	 my ( $tag, $rev_id ) = m{(\S+):\s+(\S+)} ;
	 unless ( defined $tag ) {
	    carp "Can't parse tag from CVS log line '$_'" ;
	    $self->{CVS_LOG_STATE} = '' ;
	    next ;
	 }
	 push( @{$self->{CVS_LOG_FILE_DATA}->{RTAGS}->{$rev_id}}, $tag ) ; 
         ## tags with rev_ids like "1.1.0.2" are branch tags.
         ## tags with an even number of dots like "1.1.1" are vendor
         ## branch tags.
         $self->branches->add( VCP::Branch->new( branch_id => $tag ) )
            if _is_branch_tag $rev_id;
      }
      elsif ( $self->{CVS_LOG_STATE} eq 'rev' ) {
	 ( $self->{CVS_LOG_REV}->{rev_id} ) = m/([\d.]+)/ ;
	 $self->{CVS_LOG_STATE} = 'rev_meta' ;
	 next ;
      }
      elsif ( $self->{CVS_LOG_STATE} eq 'rev_meta' ) {
	 for ( split /;\s*/ ) {
	    my ( $key, $value ) = m/(\S+):\s+(.*?)\s*$/ ;
	    $self->{CVS_LOG_REV}->{lc($key)} = $value ;
	 }
	 $self->{CVS_LOG_STATE} = 'rev_message' ;
	 next ;
      }
      elsif ( $self->{CVS_LOG_STATE} eq 'rev_message' ) {
	 $self->{CVS_LOG_REV}->{comment} .= $_
            unless /\Abranches: .*;$/;
      }
   }

   ## Never, ever forget the last rev.  "Wait for me! Wait for me!"
   ## Most of the time, this should not be a problem: cvs log puts a
   ## line of "=" at the end.  But just in case I don't know of a
   ## funcky condition where that might not happen...
   $self->_create_rev_from_cvs_log_output ;

   $self->_note_duplicate_branch_tags(
      $self->{CVS_LOG_FILE_DATA}->{RTAGS}
   );
   $self->{CVS_LOG_REV} = undef ;
   $self->{CVS_LOG_FILE_DATA} = undef ;

   profile_end ref( $self ) . " parse_cvs_log_output()" if profiling;
}


# Here's a (probably out-of-date by the time you read this) dump of the args
# for _create_rev:
#
###############################################################################
#$file = {
#  'WORKING' => 'src/Eesh/eg/synopsis',
##  'SELECTED' => '2',
#  'LOCKS' => 'strict',
##  'TOTAL' => '2',
#  'ACCESS' => '',
#  'RCS' => '/var/cvs/cvsroot/src/Eesh/eg/synopsis,v',
#  'KEYWORD' => 'kv',
#  'RTAGS' => {
#    '1.1' => [
#      'Eesh_003_000',
#      'Eesh_002_000'
#    ]
#  },
#  'HEAD' => '1.2',
###  'TAGS' => {   <== not used, so commented out.
###    'Eesh_002_000' => '1.1',
###    'Eesh_003_000' => '1.1'
###  },
#  'BRANCH' => ''
#};
#$rev = {
#  'DATE' => '2000/04/21 17:32:16',
#  'comment' => 'Moved a bunch of code from eesh, then deleted most of it.
#',
#  'STATE' => 'Exp',
#  'AUTHOR' => 'barries',
#  'REV' => '1.1'
#};
###############################################################################

sub _create_rev {
   my VCP::Source::cvs $self = shift ;
   my ( $file_data, $rev_data, $is_founding_rev ) = @_ ;

   $file_data->{working} =~ s{([\\/])[\\/]+}{$1}g;

   my $norm_name = $self->normalize_name( $file_data->{working} ) ;

   my $action = $rev_data->{state} eq "dead" ? "delete" : "edit" ;

   my $type =
      defined $file_data->{keyword}
      && $file_data->{keyword} =~ /[o|b]/
      ? "binary"
      : "text" ;

#debug map "$_ => $rev_data->{$_}, ", sort keys %{$rev_data} if debugging;

   my $rev_id = $rev_data->{rev_id};

   my $branch_id;
   my $previous_id;

   my $denorm_name = $self->denormalize_name( $norm_name );
   my $id = "$denorm_name#$rev_id";
   ( my $branch_number = $rev_id ) =~ s/\.\d+\z//;

   # 1.x, 2.x, etc are all on the main branch in CVS.
   $branch_number = "" unless $branch_number =~ tr/.//;

   ## Using branch number here instead of the $branch_id (which may be
   ## a CVS branch tag so that altering the CVS source by moving or
   ## changing or removing the branch's branch tag does not result in
   ## different filebranch_ids.
   my $filebranch_id = "$denorm_name<$branch_number>";

   if ( $rev_id =~ /\A(\d+(?:\.\d+)+)\.(\d+)\.(\d+)\z/ ) {
      ## It's on a branch
      my ( $parent_rev_id, $branch_number, $rev_number ) = ( $1, $2, $3 );
      $previous_id = $self->denormalize_name( $norm_name ) . "#$parent_rev_id"
         if $rev_number eq "1";
      my $magic_branch_number = "$parent_rev_id.0.$branch_number";
      my $vendor_branch_number = "$parent_rev_id.$branch_number";
      my $branch_ids = exists $file_data->{RTAGS}->{$magic_branch_number}
             ? $file_data->{RTAGS}->{$magic_branch_number}
         : exists $file_data->{RTAGS}->{$vendor_branch_number}
             ? $file_data->{RTAGS}->{$vendor_branch_number}
         : do {
            my $invented_tag = "_branch_$magic_branch_number";
            # TODO: Consider what happens if two files brancehd
            # at the same revision number but aren't really in the
            # same branch.
            #
            # Also: consider doing invented branch consolidation
            # for files that branched around the same time.
            $self->branches->add( VCP::Branch->new(
               branch_id => $invented_tag
            ) );
            [ $invented_tag ];
         };

      ## CVS stores symbols in newest first order.  CVS allows multiple
      ## tags for the same branch.  So we take the oldest branch tag
      ## and use that as the branch_id.  Other code will note and
      ## perform the cloning.
      $branch_id = $branch_ids->[-1]; 
   }
   elsif ( ( $rev_id =~ tr/.// ) > 1 ) {
      die "Did not parse ${rev_id}'s branch number";
   }
  
   my VCP::Rev $r = VCP::Rev->new(
      id                   => $id,
      vcp_source_scm_fn    => $file_data->{working},
      name                 => $norm_name,
      source_name          => $norm_name,
      rev_id               => $rev_id,
      source_rev_id        => $rev_id,
      type                 => $type,
      action               => $action,
      time                 => $self->parse_time( $rev_data->{date} ),
      user_id              => $rev_data->{author},
      comment              => $rev_data->{comment},
#      state                => $rev_data->{state},
      labels               => $file_data->{RTAGS}->{$rev_id},
      branch_id            => $branch_id,
      source_branch_id     => $branch_id,
      source_filebranch_id => $filebranch_id,
      source_repo_id       => $self->repo_id,
      previous_id          => $previous_id,
      is_founding_rev      => $is_founding_rev,
   ) ;

   $self->{CVS_APPLIED_TAGS_COUNT} += @{$file_data->{RTAGS}->{$rev_id}}
      if $file_data->{RTAGS}->{$rev_id};

   $self->{CVS_NAME_REP_NAME}->{$file_data->{working}} = $file_data->{rcs} ;

   my $magic_id_prefix = "$rev_id.0";

   ## Note all branches from this rev (not including vendor branches, they
   ## should work without this logic).
   for my $tag_rev_id (
      grep 0 == index( $_, $magic_id_prefix ) || ! ( tr/.// % 2 ),
      keys %{$file_data->{RTAGS}}
   ) {
      ## CVS allows multiple tags per same revision; note only the
      ## master; cloneing will take care of the slaves.
#      for my $tag ( @{$file_data->{RTAGS}->{$tag_rev_id}} ) {
#         push @{$self->{CVS_BRANCH_PARENTS}->{$tag}},
#            [ $r, $tag_rev_id ];
#      }
       push @{$self->{CVS_BRANCH_PARENTS}->{$file_data->{RTAGS}->{$tag_rev_id}->[-1]}},
          [ $r, $tag_rev_id ];
   }

   if ( $self->continue && $self->dest ) {
      my $previous_rev_id =
         $self->dest->last_rev_in_filebranch(
            $self->repo_id,
            $filebranch_id
         );

      if ( defined $previous_rev_id
         && VCP::Rev->cmp_id( $previous_rev_id, $rev_id ) >= 0
      ) {
         return undef;
      }
   }

   return $r;
}

## FOOTNOTES:
# [1] :pserver:guest@cvs.tigris.org:/cvs hass some goofiness like:
#----------------------------
#revision 1.12
#date: 2000/09/05 22:37:42;  author: thom;  state: Exp;  lines: +8 -4
#
#merge revision history for cvspatches/root/log_accum.in
#----------------------------
#revision 1.11
#date: 2000/08/30 01:29:38;  author: kfogel;  state: Exp;  lines: +8 -4
#(derive_subject_from_changes_file): use \t to represent tab
#characters, not the incorrect \i.
#=============================================================================
#----------------------------
#revision 1.11
#date: 2000/09/05 22:37:32;  author: thom;  state: Exp;  lines: +3 -3
#
#merge revision history for cvspatches/root/log_accum.in
#----------------------------
#revision 1.10
#date: 2000/07/29 01:44:06;  author: kfogel;  state: Exp;  lines: +3 -3
#Change all "Tigris" ==> "Helm" and "tigris" ==> helm", as per Daniel
#Rall's email about how the tigris path is probably obsolete.
#=============================================================================
#----------------------------
#revision 1.10
#date: 2000/09/05 22:37:23;  author: thom;  state: Exp;  lines: +22 -19
#
#merge revision history for cvspatches/root/log_accum.in
#----------------------------
#revision 1.9
#date: 2000/07/29 01:12:26;  author: kfogel;  state: Exp;  lines: +22 -19
#tweak derive_subject_from_changes_file()
#=============================================================================
#----------------------------
#revision 1.9
#date: 2000/09/05 22:37:13;  author: thom;  state: Exp;  lines: +33 -3
#
#merge revision history for cvspatches/root/log_accum.in
#

=head1 SEE ALSO

L<VCP::Dest::cvs>, L<vcp>, L<VCP::Process>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
