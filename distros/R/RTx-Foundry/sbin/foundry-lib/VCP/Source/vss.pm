package VCP::Source::vss ;

=head1 NAME

VCP::Source::vss - A VSS repository source

=head1 SYNOPSIS

   vcp vss:project/...

=head1 DESCRIPTION

Source driver enabling L<C<vcp>|vcp> to extract versions form a vss
repository.

The source specification for VSS looks like:

    vss:filespec [<options>]

C<filespec> may contain trailing wildcards, like C</a/b/...> to extract
an entire directory tree (this is the normal case).

NOTE: This does not support incremental exports, see LIMITATIONS.

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

Used to set the VSS working directory.  VCP::Source::vss will cd to this
directory before calling vss, and won't initialize a VSS workspace of
it's own (normally, VCP::Source::vss does a "vss checkout" in a
temporary directory).

This is an advanced option that allows you to use a VSS workspace you
establish instead of letting vcp create one in a temporary directory
somewhere.  This is useful if you want to read from a VSS branch or if
you want to delete some files or subdirectories in the workspace.

If this option is a relative directory, then it is treated as relative
to the current directory.

=item --rev-root

B<Experimental>.

Falsifies the root of the source tree being extracted; files will
appear to have been extracted from some place else in the hierarchy.
This can be useful when exporting RevML, the RevML file can be made
to insert the files in to a different place in the eventual destination
repository than they existed in the source repository.

The default C<rev-root> is the file spec up to the first path segment
(directory name) containing a wildcard, so

   vss:/a/b/c...

would have a rev-root of C</a/b>.

In direct repository-to-repository transfers, this option should not be
necessary, the destination filespec overrides it.

=cut

#=item -V
#
#   -V 5
#   -V 5~3
#
#Passed to C<ss History>.

=back

=cut

#=head2 Files that aren't tagged
#
#VSS has one peculiarity that this driver works around.
#
#If a file does not contain the tag(s) used to select the source files,
#C<vss log> outputs the entire life history of that file.  We don't
#want to capture the entire history of such files, so
#L<VCP::Source::vss> ignores any revisions before and after the oldest
#and newest tagged file in the range.
#
#=cut


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
#specified with -r. The typical use is to get all files from a certain
#tag to now.
#
#It does this by exporting all revisions of files between the oldest and
#newest files that the -r specified.  Without C<-f>, these would
#be ignored.
#
#It is an error to specify C<-f> without C<-r>.
#
#exported.

use strict ;

use Carp ;
use File::Basename;
use Regexp::Shellish qw( :all ) ;
use VCP::Rev ;
use VCP::Debug qw(:debug );
use VCP::Logger qw( pr );
use VCP::Source ;
use VCP::Utils qw( empty );
use VCP::Utils::vss ;

use base qw( VCP::Source VCP::Utils::vss ) ;
use fields (
   'VSS_CUR',            ## The current change number being processed
   'VSS_BOOTSTRAP',      ## Forces bootstrap mode
   'VSS_IS_INCREMENTAL', ## Hash of filenames, 0->bootstrap, 1->incremental
   'VSS_INFO',           ## Results of the 'vss --version' command and VSSROOT
   'VSS_LABEL_CACHE',    ## ->{$name}->{$rev} is a list of labels for that rev
   'VSS_LABELS',         ## Array of labels from 'p4 labels'
   'VSS_MAX',            ## The last change number needed
   'VSS_MIN',            ## The first change number needed
   'VSS_VER_SPEC',       ## The revision spec to pass to `ss History`
   'VSS_WORK_DIR',       ## working directory set via --cd option

   'VSS_NAME_REP_NAME',  ## A mapping of names to repository names

   'VSS_K_OPTION',       ## Which of the VSS/RCS "-k" options to use, if any

   'VSS_LOG_CARRYOVER',  ## The unparsed bit of the history file
   'VSS_LOG_STATE',      ## Parser state machine state
   'VSS_LOG_REV',        ## The revision being parsed (a hash)

   'VSS_NEEDS_BASE_REV', ## What base revisions are needed.  Base revs are
                         ## needed for incremental (ie non-bootstrap) updates,
			 ## which is decided on a per-file basis by looking
			 ## at VCP::Source::is_bootstrap_mode( $file ) and
			 ## the file's rev number (ie does it end in .1).
   'VSS_HIGHEST_VERSION',  ## A HASH keyed on filename that contains the
                         ## last rev_id seen for a file.  This allows
                         ## file deletions (which aren't tracked by
                         ## VSS in a file's history) to be given a
                         ## pretend revision number.
   'VSS_REV_ID_OFFSET',  ## After a busy day processing a deleted file,
                         ## it's time to relax and process the not-deleted
                         ## file of the same name.  In order to keep
                         ## from reusing the same version numbers for
                         ## the not-deleted file, this variable contains
                         ## an offset to add to the revisions.  It's the
                         ## value of VSS_HIGHEST_VERSION reached while
                         ## reading the deleted file.

   'VSS_FILES',          ## Managed by VSS::Utils::vss
   'VSS_LOG_LAZY_COMMIT_PENDING',  ## Multiple VSS revisions get compressed
                               ## in to a single VCP revision.  This
                               ## flag is set when a revision is parsed
                               ## that is not immediately converted in
                               ## to a VCP::Rev; right now this applies
                               ## to "Labeled" revisions because we
                               ## accumulate labels in to one
                               ## VCP::Rev.
   'VSS_LOG_PRELIM_FIELDS',  ## When reading ahead to see if the current
                         ## pending lazy commit needs to be committed,
                         ## accumulated data is held here.
   'VSS_LOG_OLDEST_VERSION',    ## The oldest rev parsed for this file.
) ;


sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Source::vss $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   unless( empty $spec ) {
      ## Make it look like a Unix path.
      $spec =~ s{^\$//}{};
      $spec =~ s{\$}{}g;
      $spec =~ s{\\}{/}g;

      $self->parse_vss_repo_spec( $spec );
   }

   $self->parse_options(
      $options,
      "b|bootstrap:s"   => sub {
	 my ( $name, $val ) = @_ ;
	 $self->{VSS_BOOTSTRAP} = $val eq ""
	    ? [ compile_shellish( "..." ) ]
	    : [ map compile_shellish( $_ ), split /,+/, $val ] ;
      },
      "cd=s"          => sub { $self->{VSS_WORK_DIR} = $_[1] } ,
      "V=s"           => sub { $self->{VSS_VER_SPEC} = "-V$_[1]" },
      "k=s"           => sub { $self->{VSS_K_OPTION} = $_[1] } ,
      "kb"            => sub { $self->{VSS_K_OPTION} = "b" } ,
   );

   return $self ;
}


sub init {
   my VCP::Source::vss $self= shift ;

   my $files = $self->repo_filespec ;
   $self->deduce_rev_root( $files )
      unless defined $self->rev_root;

### TODO: Figure out whether we should make rev_root merely set the rev_root
### in the header.  I think we probably should do it that way, as it's more
### flexible and less confusing.

   ## Don't normalize the filespec.
   $self->repo_filespec( $files ) ;

   my $work_dir = $self->{VSS_WORK_DIR};
   unless ( defined $work_dir ) {
      $self->create_vss_workspace ;
   }
   else {
      $self->work_root( File::Spec->rel2abs( $work_dir ) ) ; 
      $self->command_chdir( $self->work_path ) ;
   }

   ## May need to run again with -D to list deleted files
   ## This generates the list of all files we want to scan
   $self->get_vss_file_list( $self->repo_filespec );

   {
      my ( $out, $err );
      ## Dirty trick: send a known bad parm *just* to get ss.exe to
      ## print it's banner without popping open a help screen.
      $self->ss( [ "help", "/illegal arg" ], ">", \$out, "2>", \$err );
      $self->{VSS_INFO} = $out;
   }
}


sub is_incremental {
   my VCP::Source::vss $self= shift ;
   my ( $file, $first_rev ) = @_ ;

   $first_rev =~ s/\.\d+//;  ## Trim down <delete /> rev_ids

   my $bootstrap_mode = $first_rev <= "1"
      || ( $self->{VSS_BOOTSTRAP}
         && grep $file =~ $_, @{$self->{VSS_BOOTSTRAP}}
      ) ;

   return $bootstrap_mode ? 0 : "incremental" ;
}


sub denormalize_name {
   my VCP::Source::vss $self = shift ;
   return '/' . $self->SUPER::denormalize_name( @_ ) ;
}


sub handle_header {
   my VCP::Source::vss $self = shift ;
   my ( $header ) = @_ ;

   $header->{rep_type} = 'vss' ;
   $header->{rep_desc} = $self->{VSS_INFO} ;
   $header->{rev_root} = $self->rev_root ;

   $self->dest->handle_header( $header ) ;
   return ;
}


sub get_rev {
   my VCP::Source::vss $self = shift ;

   my VCP::Rev $r ;
   ( $r ) = @_ ;

   die "can't check out ", $r->as_string, "\n"
      unless $r->action eq "add" || $r->action eq "edit";

   my $wp = $self->work_path( "revs", $r->source_name, $r->source_rev_id ) ;
   $r->work_path( $wp ) ;
   $self->mkpdir( $wp ) ;

   my ( $fn, $dir ) = fileparse( $wp );

   my $ignored_stdout;

confess "Shouldn't be get_rev()ing a rev with no rev_id" unless defined $r->rev_id;

   if ( $self->vss_file_is_deleted( $r->vcp_source_scm_fn ) ) {
      my $rev_id = $r->rev_id;
      $rev_id -= $self->{VSS_REV_ID_OFFSET}->{$r->vcp_source_scm_fn}
         if $rev_id > $self->{VSS_REV_ID_OFFSET}->{$r->vcp_source_scm_fn};
      $self->_swap_in_deleted_file_and(
         $r->vcp_source_scm_fn,
         "ss",
         [ "Get",
            "\$/" . $r->vcp_source_scm_fn,
            "-V"  . $rev_id,
            "-GL" . $dir,
            "-GN",   ## Newlines only, please
         ],
         ">", \$ignored_stdout
      ) ;
   }
   else {
      $self->ss(
         [ "Get",
            "\$/" . $r->vcp_source_scm_fn,
            "-V"  . $r->rev_id,
            "-GL" . $dir,
            "-GN",   ## Newlines only, please
         ],
         ">", \$ignored_stdout
      );
   }

   my $temp_fn = fileparse( $r->vcp_source_scm_fn );

   rename "$dir/$temp_fn", "$dir/$fn" or die "$! renaming $temp_fn to $fn\n";

   return $wp;
}


## History report Parser states
## The code below does things like grep for "commit" and "skip to next"
## in these strings.  Plus, they make debug output easier to read.
use constant SKIP_TO_NEXT                    => "skip to next";
use constant SKIP_TO_NEXT_COMMIT_AT_END      => "skip to next and commit at end";
use constant ENTRY_START                     => "entry start";
use constant READ_ACTION                     => "read action";
use constant READ_COMMENT_AND_COMMIT         => "read comment and commit";
use constant READ_REST_OF_COMMENT_AND_COMMIT => "read rest of comment and commit";

sub _reset_log_parser {
   my VCP::Source::vss $self = shift ;
   $self->{VSS_LOG_STATE} = SKIP_TO_NEXT;
   $self->{VSS_LOG_CARRYOVER} = '' ;
   $self->{VSS_LOG_REV} = {} ;
   $self->{VSS_LOG_OLDEST_VERSION} = undef ;
   $self->{VSS_LOG_LAZY_COMMIT_PENDING} = 0;
   $self->{VSS_LOG_PRELIM_FIELDS} = {};

}

sub _get_file_metadata {
   my VCP::Source::vss $self = shift ;
   my ( $filename ) = @_;

   my $ss_fn = "\$/$filename";

   my $filetype;

   $self->ss( [ "FileType", $ss_fn ], ">", \$filetype );

   $filetype =~ s/\A.*\s(\S+)\r?\n.*/$1/ms
      or die "Can't parse filetype from '$filetype'";
   $filetype = lc $filetype;

   my $tmp_f;
   my $result = 1;

   $self->_reset_log_parser;

   if( defined $self->{VSS_VER_SPEC} ) {
      $self->ss( [ "History",
                   "\$/$filename",
                   $self->{VSS_VER_SPEC},
                 ],
                 '>',
                 sub { $self->parse_log_file( $filename, $filetype, @_ ) },
                 stderr_filter =>
                   sub {
                      my ( $err_text_ref ) = @_ ;
                      $$err_text_ref =~ s{^Version not found\r?\n\r?}[$result = 0; '' ;]mei ;
                   },
               );
   }
   else {
      $self->ss( [ "History",
                   "\$/$filename",
                   (),
                 ],
                 '>',
                 sub { $self->parse_log_file( $filename, $filetype, @_ ) },
               );
   }

   ## Keep scanning until we get the actual checkin, so we get
   ## any intervening labels and the correct metadata for the
   ## checkin. A LAZY_COMMIT_PENDING means that the History
   ## output did not end on a checkin, it ended on a label or
   ## something.
   if ( defined $self->{VSS_LOG_OLDEST_VERSION} ) {
      if ( substr( $self->{VSS_LOG_STATE}, -6 ) eq "commit" ) {
         $self->add_rev_from_log_parser;
         $self->{VSS_LOG_STATE} = SKIP_TO_NEXT;
      }

      my $oldest = $self->{VSS_LOG_OLDEST_VERSION};
      if ( $self->{VSS_LOG_LAZY_COMMIT_PENDING} ) {
         debug "scanning back to checkin"
            if debugging;
         die "Must be in SKIP_TO_NEXT... not $self->{VSS_LOG_STATE}"
            unless 0 == index $self->{VSS_LOG_STATE}, SKIP_TO_NEXT;
         $self->_find_checkin( $filename, $filetype, $oldest );

         if ( substr( $self->{VSS_LOG_STATE}, -6 ) eq "commit" ) {
            $self->add_rev_from_log_parser;
            $self->{VSS_LOG_STATE} = SKIP_TO_NEXT;
         }
         $oldest = $self->{VSS_LOG_OLDEST_VERSION};
      }

      if ( $self->is_incremental( $filename, $oldest ) ) {
         debug "scanning back to base rev"
            if debugging;
         ## Skip the banner
         $self->{VSS_LOG_STATE} = SKIP_TO_NEXT;
         $self->_find_checkin( $filename, $filetype, $oldest );
         if ( substr( $self->{VSS_LOG_STATE}, -6 ) eq "commit" ) {
            $self->add_rev_from_log_parser;
            $self->{VSS_LOG_STATE} = SKIP_TO_NEXT;
         }
         $self->revs->as_array_ref->[-1]->base_revify;
      }
   }
   $self->parse_log_file( $filename, $filetype, undef );

   return $result;
}


sub _swap_in_deleted_file_and {
   my VCP::Source::vss $self = shift ;
   my ( $filename, $method, @args ) = @_;

   my $ss_fn = "\$/$filename";

   my $ignored_stdout;

   my $renamed_active;
   if ( $self->vss_file_is_active( $filename ) ) {
      my $i = "";
      while (1) {
         $renamed_active = "$ss_fn.vcp_bak$i";
         last unless $self->vss_file( $renamed_active );
         $i ||= 0;
         ++$i;
      }
      $self->ss( [ "Rename", $ss_fn, $renamed_active ] );
   }

   my $result;

   my $ok = eval {
##TODO: not ignore this output!
      $self->ss( [ "Recover", $ss_fn ], ">", \$ignored_stdout ) ;

      my $ok = eval { $result = $self->$method( @args ); 1 };

      my $x = $@;
      $self->{VSS_REV_ID_OFFSET}->{$filename} =
          $self->{VSS_HIGHEST_VERSION}->{$filename} || 0;
      $ok = eval {
##TODO: not ignore this output!
         $self->ss( [ "Delete", $ss_fn ], ">", \$ignored_stdout ) ;
         1;
      } && $ok;
      $x = "" unless defined $x;
      die $x.$@ unless $ok;
   };


   my $x = $@;

   if ( defined $renamed_active ) {
      my $myok = eval {
         $self->ss( [ "Rename", $renamed_active, $ss_fn ] );
         1;
      };
      if ( ! $myok ) {
         $x .= $@;
         $ok = 0;
      };
   }

   die $x unless $ok;

   return $result;
}


sub copy_revs {
   my VCP::Source::vss $self = shift ;

   ## Get a list of all files we need to worry about
   $self->get_vss_file_list( $self->repo_filespec );

   $self->revs( VCP::Revs->new ) ;

   for my $filename ( $self->vss_files ) {
      $self->{VSS_REV_ID_OFFSET}->{$filename} = 0;

      my $found_deleted;
      if ( $self->vss_file_is_deleted( $filename ) ) {
         $found_deleted = $self->_swap_in_deleted_file_and(
            $filename, "_get_file_metadata", $filename
         );

         my VCP::Rev $r = VCP::Rev->new(
            vcp_source_scm_fn => $filename,
            name              => $self->normalize_name( $filename ),
            source_name       => $self->normalize_name( $filename ),
            source_repo_id    => $self->repo_id,
            action            => "delete",
            ## Make up a fictional rev number that will allow the
            ## receiver's sort algorithm to put this delete in the
            ## right place and that will be documented in the
            ## receiving repository as a label.
            rev_id            => "$self->{VSS_REV_ID_OFFSET}->{$filename}.1",
            ## Deletes are not logged, no user data, time, etc.
         ) ;

         $self->revs->add( $r );
      }

      my $found_active;
      if ( $self->vss_file_is_active( $filename ) ) {
         my $tmp_ver_spec;
         if ( $found_deleted ) {
            ## If we happen to have been looking for a label and it was
            ## found in the deleted version, then make sure we get all
            ## the revs from the active file.
            $tmp_ver_spec = $self->{VSS_VER_SPEC};
            $self->{VSS_VER_SPEC} = undef;
         }

         $found_active = $self->_get_file_metadata( $filename );

         $self->{VSS_VER_SPEC} = $tmp_ver_spec
            if $found_deleted;
      }

      if ( defined $self->{VSS_VER_SPEC}
         && ! ( $found_deleted || $found_active )
      ) {
         pr "$self->{VSS_VER_SPEC} did not match any revisions of $filename, not transferring\n";
      }
      
      if ( keys %{$self->{VSS_LOG_REV}} ) {
         require Data::Dumper;
         die "Data left over in VSS_LOG_REV, state $self->{VSS_LOG_STATE}:\n",
         Data::Dumper::Dumper(
            $self->{VSS_LOG_REV}
         );
      }
   }

   $self->SUPER::copy_revs;
}


# Here's a typical history
#
###############################################################################
##D:\src\vcp>ss history
#History of $/90vss.t ...
#
#*****************  Version 9   *****************
#User: Admin        Date:  3/05/02   Time:  9:32
#readd recovered
#
#*****  a_big_file  *****
#Version 3
#User: Admin        Date:  3/05/02   Time:  9:32
#Checked in $/90vss.t
#Comment: comment 3
#
#
#*****  binary  *****
#Version 3
#User: Admin        Date:  3/05/02   Time:  9:32
#Checked in $/90vss.t
#Comment: comment 3
#
#
#*****************  Version 8   *****************
#User: Admin        Date:  3/05/02   Time:  9:32
#readd deleted
#
#*****  binary  *****
#Version 2
#User: Admin        Date:  3/05/02   Time:  9:32
#Checked in $/90vss.t
#Comment: comment 2
#
#
#*****************  Version 7   *****************
#User: Admin        Date:  3/05/02   Time:  9:32
#readd added
#
#*****  a_big_file  *****
#Version 2
#User: Admin        Date:  3/05/02   Time:  9:32
#Checked in $/90vss.t
#Comment: comment 2
#
#
#*****************  Version 6   *****************
#User: Admin        Date:  3/05/02   Time:  9:32
#$del added
#
#*****************  Version 5   *****************
#User: Admin        Date:  3/05/02   Time:  9:32
#binary added
#
#*****************  Version 4   *****************
#User: Admin        Date:  3/05/02   Time:  9:31
#$add added
#
#*****************  Version 3   *****************
#User: Admin        Date:  3/05/02   Time:  9:31
#a_big_file added
#
#*****************  Version 2   *****************
#User: Admin        Date:  3/05/02   Time:  9:31
#$a added
#
#*****************  Version 1   *****************
#User: Admin        Date:  3/05/02   Time:  9:31
#Created
#
#
#D:\src\vcp>ss dir /r
#$/90vss.t:
#$a
#$add
#$del
#a_big_file
#binary
#readd
#
#$/90vss.t/a:
#$deeply
#
#$/90vss.t/a/deeply:
#$buried
#
#$/90vss.t/a/deeply/buried:
#file
#
#$/90vss.t/add:
#f1
#f2
#f3
#
#$/90vss.t/del:
#f4
#
#13 item(s)
#
#D:\src\vcp>
#
###############################################################################


sub _is_rev_a_checkin {
   my ( $self, $fn, $filetype, $rev_id ) = @_;

   $rev_id -= $self->{VSS_REV_ID_OFFSET}->{$fn}
      if $rev_id > $self->{VSS_REV_ID_OFFSET}->{$fn};

   $self->ss(
      [ "History", "\$/$fn", "-V$rev_id", "-#1" ],
      ">", \my $history
   );

   $self->parse_log_file( $fn, $filetype, $history );

   ## Note: similar regexp in parse_log_file
   return $history =~ /^(Checked in .*|Created|.* recovered)$/m ? 1 : 0;
}


sub _find_checkin {
   my $self = shift;
   my ( $fn, $filetype, $rev_id ) = @_;

   $rev_id =~ s/\.\d+//;  # ignore faked-up revs.
   return if $rev_id <= 1;

   while ( --$rev_id ) {
      if ( $rev_id <= $self->{VSS_REV_ID_OFFSET}->{$fn} ) {
         last if $self->_swap_in_deleted_file_and(
            $fn,
            "_is_rev_a_checkin",
            $fn,
            $filetype,
            $rev_id
         );
      }
      else {
         last if $self->_is_rev_a_checkin( $fn, $filetype, $rev_id );
      }
   }
}


sub parse_log_file {
   my ( $self, $filename, $filetype, $input ) = @_ ;

   if ( defined $input ) {
      $self->{VSS_LOG_CARRYOVER} .= $input ;
   }
   else {
      ## Last call...
      ## There can only be leftovers if they don't end in a "\n".  I've never
      ## seen that happen, but given large comments, I could be surprised...
      $self->{VSS_LOG_CARRYOVER} .= "\n" if length $self->{VSS_LOG_CARRYOVER} ;
   }

   my $p = $self->{VSS_LOG_REV};

   local $_ ;

   ## DOS, Unix, Mac lineends spoken here.
   while ( $self->{VSS_LOG_CARRYOVER} =~ s/^(.*(?:\r\n|\n\r|\n))// ) {
      $_ = $1 ;
      if ( debugging ) {
         my $foo = $1;
         chomp $foo;
         debug "[$foo]     $self->{VSS_LOG_STATE}\n";
      }

      ## This is crude, but effective: it sets the values every time
      $p->{Name} = $filename;
      $p->{Type} = $filetype;

      if ( /^\*{17}  Version (\d+) +\*{17}/ ) {
         $self->add_rev_from_log_parser
            if substr( $self->{VSS_LOG_STATE}, -6 ) eq "commit";
         $self->{VSS_LOG_STATE} = ENTRY_START;

         ## This will overwrite the newer/higher version number
         ## with the lower/older one until we reach the check-in
         ## we want
         $self->{VSS_LOG_OLDEST_VERSION} = $p->{Version} = $1;
         next;
      }

      if ( /^\*{5}\s+(.*?)\s+\*{5}$/ ) {
         $self->add_rev_from_log_parser
            if substr( $self->{VSS_LOG_STATE}, -6 ) eq "commit";
         $self->{VSS_LOG_STATE} = ENTRY_START;
         $p->{_banner_name} = $1;
         next;
      }

      next if 0 == index $self->{VSS_LOG_STATE}, SKIP_TO_NEXT;

      if ( $self->{VSS_LOG_STATE} eq ENTRY_START ) {
         if ( /^Label:\s*"([^"]+)"/ ) {
            ## Unshift because we're reading from newest to oldest yet
            ## we want oldest first so vss->vss is relatively consistent
            unshift @{$p->{Labels}}, $1;
            next;
         }
         if ( /^User:\s+(.*?)\s+Date:\s+(.*?)\s+Time:\s+(\S+)/ ) {
            $self->{VSS_LOG_PRELIM_FIELDS}->{User} = $1;
            $self->{VSS_LOG_PRELIM_FIELDS}->{Date} = $2;
            $self->{VSS_LOG_PRELIM_FIELDS}->{Time} = $3;
            $self->{VSS_LOG_STATE} = READ_ACTION;
            next;
         }
      }

      if ( $self->{VSS_LOG_STATE} eq READ_ACTION ) {
         if ( /Labeled/ ) {
            ## It's a label-add only, ignore the rest.
            ## for incremental exports, we'll need to commit at the
            ## end of the log if the last thing was a "Labeled"
            ## version.  We don't want to commit after each "Labeled"
            ## because we want to aggregate labels.
            $self->{VSS_LOG_STATE} = SKIP_TO_NEXT_COMMIT_AT_END;
            $p->{Action} = "edit";
            $p->{$_} = delete $self->{VSS_LOG_PRELIM_FIELDS}->{$_}
               for keys %{$self->{VSS_LOG_PRELIM_FIELDS}};
            $self->{VSS_LOG_LAZY_COMMIT_PENDING} = 1;
            next;
         }

         ## Note: similar regexp in is_rev_a_checkin
         if ( /^(Checked in .*|Created|.* recovered)$/ ) {
            $self->{VSS_LOG_STATE} = READ_COMMENT_AND_COMMIT;
            $p->{$_} = delete $self->{VSS_LOG_PRELIM_FIELDS}->{$_}
               for keys %{$self->{VSS_LOG_PRELIM_FIELDS}};
            $p->{Action} = "edit";
            next;
         }
      }

      if ( $self->{VSS_LOG_STATE} eq READ_COMMENT_AND_COMMIT ) {
         if ( s/Comment: // ) {
            $p->{Comment} = $_;
            $self->{VSS_LOG_STATE} = READ_REST_OF_COMMENT_AND_COMMIT;
            next;
         }
      }

      if ( $self->{VSS_LOG_STATE} eq READ_REST_OF_COMMENT_AND_COMMIT ) {
          $p->{Comment} .= $_;
          next;
      }

      require Data::Dumper;
      local $Data::Dumper::Indent    = 1;
      local $Data::Dumper::Quotekeys = 0;
      local $Data::Dumper::Terse     = 1;

      die
         "unhandled VSS log line '$_' in state $self->{VSS_LOG_STATE} for:\n",
         Data::Dumper::Dumper( $self->{VSS_LOG_REV} );
   }

   if ( ! defined $input ) {
      $self->add_rev_from_log_parser
         if 0 <= index( $self->{VSS_LOG_STATE}, "commit" )
            ||  $self->{VSS_LOG_LAZY_COMMIT_PENDING};

      $self->{VSS_LOG_STATE} = SKIP_TO_NEXT;
   }
}


# Here's a (probably out-of-date by the time you read this) dump of the args
# for _add_rev:
#
###############################################################################
#$file = {
#  'WORKING' => 'src/Eesh/eg/synopsis',
#  'SELECTED' => '2',
#  'LOCKS' => 'strict',
#  'TOTAL' => '2',
#  'ACCESS' => '',
#  'RCS' => '/var/vss/vssroot/src/Eesh/eg/synopsis,v',
#  'KEYWORD' => 'kv',
#  'RTAGS' => {
#    '1.1' => [
#      'Eesh_003_000',
#      'Eesh_002_000'
#    ]
#  },
#  'HEAD' => '1.2',
#  'TAGS' => {
#    'Eesh_002_000' => '1.1',
#    'Eesh_003_000' => '1.1'
#  },
#  'BRANCH' => ''
#};
#$rev = {
#  'DATE' => '2000/04/21 17:32:16',
#  'MESSAGE' => 'Moved a bunch of code from eesh, then deleted most of it.
#',
#  'STATE' => 'Exp',
#  'AUTHOR' => 'barries',
#  'REV' => '1.1'
#};
###############################################################################

sub _add_rev {
   my VCP::Source::vss $self = shift ;
   my ( $rev_data, $is_base_rev ) = @_ ;

   my $action = $rev_data->{Action};

   $rev_data->{Type} ||= "text";

#debug map "$_ => $rev_data->{$_}, ", sort keys %{$rev_data} ;

   my $filename = $rev_data->{Name};

   my VCP::Rev $r = VCP::Rev->new(
      vcp_source_scm_fn => $filename,
      name              => $self->normalize_name( $rev_data->{Name} ),
      source_name       => $self->normalize_name( $rev_data->{Name} ),
      source_repo_id    => $self->repo_id,
      rev_id            => $rev_data->{Version} + $self->{VSS_REV_ID_OFFSET}->{$filename},
      type              => $rev_data->{Type},
#      ! $is_base_rev
#	 ? (
	    action      => $action,
	    time        => $self->parse_time( $rev_data->{Date} . " " . $rev_data->{Time} ),
	    user_id     => $rev_data->{User},
	    comment     => $rev_data->{Comment},
	    state       => $rev_data->{STATE},
	    labels      => $rev_data->{Labels},
#	 )
#	 : (),
   ) ;

   $self->{VSS_NAME_REP_NAME}->{$rev_data->{Name}} = $rev_data->{RCS} ;

   eval {
      $self->revs->add( $r ) ;
   } ;
   if ( $@ ) {
      if ( $@ =~ /Can't add same revision twice/ ) {
         pr $@ ;
      }
      else {
         die $@ ;
      }
   }
}

sub add_rev_from_log_parser {
   my ( $self ) = @_;

   my $rev_data = $self->{VSS_LOG_REV};

   $rev_data->{Comment} = ''
      unless defined $rev_data->{Comment};

   $rev_data->{Comment} =~ s/\r\n|\n\r/\n/g ;
   chomp $rev_data->{Comment};
   chomp $rev_data->{Comment};

   $self->_add_rev( $rev_data );

   my $name = $rev_data->{Name};

   $self->{VSS_HIGHEST_VERSION}->{$name} = $rev_data->{Version}
      if ! defined $self->{VSS_HIGHEST_VERSION}->{$name}
         || $rev_data->{Version} > $self->{VSS_HIGHEST_VERSION}->{$name};

   %$rev_data = () ;
   $self->{VSS_LOG_LAZY_COMMIT_PENDING} = 0;
} ;

=head1 VSS NOTES

We lose comments attached to labels: labels are added to the last
"real" (ie non-label-only) revision and the comments are ignored.
This can be changed, contact me.

We assume a file has always been text or binary, don't think this is
stored per-version in VSS.

Looks for deleted files: recovers them if found just long enough to
cope with them, then deletes them again.

VSS does not track renames by version, so a previous name for a file is lost.

VSS lets you add a new file after deleting an old one.  This module
renames the current file, restores the old one, issues its revisions,
then deletes the old on and renames the current file back.  In this
case, the C<rev_id>s from the current file start at the highest
C<rev_id> for the deleted file and continue up.

NOTE: when recovering a deleted file and using it, the current version
takes a "least opportunity to screw up the source repository" approach:
it renames the not-deleted version (if any), restores the deleted one,
does the History or Get, and then deletes it and renames the not-deleted
version back.

This is so that if something (the OS, the hardware, AC mains, or even
VCP code) crashes, the source repository is left as close to the
original state as is possible.  This does mean that this module can
issue many more commands than minimally necessary; perhaps there should
be a --speed-over-safety option.

No incremental export is supported.  VSS' -V~Lfoo option, which says
"all versions since this label" does not actually cause the C<ss.exe
History> command to emit the indicated checkin.  We'll need to make the
history command much smarter to implement that.

=head1 SEE ALSO

L<VCP::Dest::vss>, L<vcp>, L<VCP::Process>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
