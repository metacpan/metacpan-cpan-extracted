package VCP::Plugin ;

=head1 NAME

VCP::Plugin - A base class for VCP::Source and VCP::Dest

=head1 SYNOPSIS

   use VCP::Plugin;
   @ISA = qw( VCP::Plugin );
   ...

=head1 DESCRIPTION

Some functionality is common to sources and destinations, such as
cache access, Pod::Usage conversion, command-line access shortcut
member, etc.

=head1 EXTERNAL METHODS

=over

=cut

use strict ;

use Carp;
use Cwd ;
use File::Basename ;
use File::Path ;
use File::Spec ;
use File::Spec::Unix ;
use File::Temp qw( tempfile );
use Getopt::Long;
use POSIX qw( dup dup2 );
use UNIVERSAL qw( isa );
use VCP::Debug qw( :debug :profile );
use VCP::Branches;
use VCP::Logger qw( lg lg_fh pr BUG );
use VCP::Rev ;
use VCP::Revs ;
use VCP::Utils qw(
   empty
   prepend_time_cmd
   shell_quote
   start_dir
   xchdir
);

use constant is_win32 => $^O =~ /Win32/;

use vars qw( $VERSION $debug ) ;

$VERSION = 0.1 ;

$debug = 0 ;

use fields (
   'WORK_ROOT',     ## The root of the export work area.
   'COMMAND_CHDIR', ## Where to chdir to when running COMMAND
   'COMMAND_STDERR_FILTER', ## How to modify the stderr when running a command
   'COMMAND_OK_RESULT_CODES', ## HASH keyed on acceptable COMMAND return vals
   'COMMAND_RESULT_CODE',     ## What the last run_safely command returned.
   'REV_ROOT',
   'REVS',          ## Any revisions we need to work with
   'REPO_ID',       ## uniquely identifies repository
   'REPO_SCHEME',   ## The scheme (this is usually superfluous, since new() has
                    ## already been called on the correct class).
   'REPO_USER',     ## The user name to log in to the repository with, if any
   'REPO_PASSWORD', ## The password to log in to the repository with, if any
   'REPO_SERVER',   ## The repository to connect to
   'REPO_FILESPEC', ## The filespec to get/store

   'BRANCHES',      ## The branches database.  Filled by the source,
                    ## passed to the dest in the header.
) ;


=item new

Creates an instance, see subclasses for options.  The options passed are
usually native command-line options for the underlying repository's
client.  These are usually parsed and, perhaps, checked for validity
by calling the underlying command line.

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my $self ;

   {
      no strict 'refs' ;
      $self = bless [ \%{"$class\::FIELDS"} ], $class ;
   }

   $self->work_root( $self->tmp_dir ) ;
   rmtree $self->work_root if ! $ENV{VCPNODELETE} && -e $self->work_root ;

   $self->{REVS} = VCP::Revs->new;

   $self->{COMMAND_OK_RESULT_CODES} = [ 0 ];

   $self->{BRANCHES} = VCP::Branches->new;

   $self->command_chdir( $self->work_path ) ;

   return $self ;
}

=back

=cut


###############################################################################

=head1 SUBCLASSING

This class uses the fields pragma, so you'll need to use base and 
possibly fields in any subclasses.

=head2 SUBCLASS API

These methods are intended to support subclasses.

=over


=item init

Stub init method.  

=cut

sub init {
}


=item parse_options

   $self->parse_options( \@options, @spec );

Parses out all options according to @spec.  The --repo-id option is
always parsed and VCP::Source.pm and VCP::Dest.pm offer common
options as well.

=cut

sub parse_options {
   my VCP::Plugin $self = shift;
   my $options = shift;
   return unless defined $options;

   local *ARGV = $options;
   GetOptions(
       @_,
       "repo-id=s"  => sub { $self->repo_id( $_[1] ) },
   ) or $self->usage_and_exit ;
}

=item revs

Sets/gets the revs container.  This is used by most sources to accumulate
the set of revisions to be copied.

This member should be set by the child in copy_revs().  It should then be
passed to the destination

=cut

sub revs {
   my VCP::Plugin $self = shift ;

   $self->{REVS} = $_[0] if @_ ;
   return $self->{REVS} ;
}


=item parse_repo_spec

   my $spec = $self->split_repo_spec( $spec ) ;

This splits a repository spec in one of the following formats:

   scheme:user:passwd@server:filespec
   scheme:user@server:filespec
   scheme::passwd@server:filespec
   scheme:server:filespec
   scheme:filespec

into the indicated fields, which are stored in $self and may be
accessed and altered using L</repo_scheme>, L</repo_user>, L</repo_password>,
L</repo_server>, and L</repo_filespec>. Some sources and destinations may
add additional fields. The p4 drivers create an L<VCP::Utils::p4/repo_client>,
for instance, and parse the repo_user field to fill it in.  See
L<VCP::Utils::p4/parse_p4_repo_spec> for details.

The spec is parsed from the ends towards the middle in this order:

   1. SCHEME (up to first ':')
   2. FILESPEC  (after last ':')
   3. USER, PASSWORD (before first '@')
   4. SERVER (everything left).

This approach allows the FILESPEC string to contain '@', and the SERVER
string to contain ':' and '@'.  USER can contain ':'.  Funky, but this
works well, at least for cvs and p4.

If a section of the repo spec is not present, the corresponding entry
in $hash will not exist.

The attributes repo_user, repo_password and repo_server are set
automatically by this method.  It does not store the SCHEME anywhere
since the SCHEME is usually ignored by the plugin (the plugin is
selected using the scheme, so it knows the scheme implicitly), and
the FILES setting often needs extra manipulation, so there's no point
in storing it.

=cut

sub parse_repo_spec {
   my VCP::Plugin $self = shift ;

   my ( $spec ) = @_ ;
   confess "parse_repo_spec called with missing argument"
      if empty $spec;

   for ( $spec ) {
      return unless s/^([^:]*)(?::|$)// ;
      $self->repo_scheme( $1 ) ;

      return unless s/(?:^|:)([^:]*)$// ;
      $self->repo_filespec( $1 ) ;

      if ( s/^([^\@]*?)(?::([^\@:]*))?@// ) {
         $self->repo_user( $1 ) if defined $1 ;
         $self->repo_password( $2 ) if defined $2 ;
      }

      return unless length $spec ;
      $self->repo_server( $spec ) ;
   }
}



=item usage_and_exit

   GetOptions( ... ) or $self->usage_and_exit ;

Used by subclasses to die if unknown options are passed in.

Requires Pod::Usage when called.

=cut

sub usage_and_exit {
   my VCP::Plugin $self = shift ;

   lg "options error emitted to STDERR for ", ref $self;

   require Pod::Usage ;
   my $f = ref $self ;
   $f =~ s{::}{/}g ;
   $f .= '.pm' ;

   for ( @INC ) {
      my $af = File::Spec->catfile( $_, $f ) ;
      if ( -f $af ) {
	 Pod::Usage::pod2usage(
	    -input   => $af,
	    -verbose => 0,
	    -exitval => 2,
	 ) ;
	 BUG "pod2usage returned";
      }
   }

   die "can't locate '$f' to print usage.\n" ;
}


=item branches

    $plugin->branches( $b );
    my $b = $plugin->branches;

Set

=cut

sub branches {
   my VCP::Plugin $self = shift;
   $self->{BRANCHES} = shift if @_;
   return $self->{BRANCHES};
}


=item tmp_dir

Returns the temporary directory this plugin should use, usually something
like "/tmp/vcp123/dest-p4".

=cut

my %tmp_dirs ;

END {
   return unless keys %tmp_dirs;
   ## This delay seems to be required to give NT a chance
   ## to clean up the tmpdir, otherwise we get a
   ## "permission denied error on Win32.
   select undef, undef, undef, 0.01 if $^O =~ /Win32/ ;
   rmtree [ reverse sort { length $a <=> length $b } keys %tmp_dirs ]
      if ! $ENV{VCPNODELETE} && %tmp_dirs ;
}

sub tmp_dir {
   my VCP::Plugin $self = shift ;
   my $plugin_dir = ref $self ;
   $plugin_dir =~ tr/A-Z/a-z/ ;
   $plugin_dir =~ s/^VCP:://i ;
   $plugin_dir =~ s/::/-/g ;
   my $tmp_dir_root = File::Spec->catdir( File::Spec->tmpdir, "vcp$$" ) ;

   ## Make sure no old tmpdir is there to mess us up in case
   ## a previous run crashed before cleanup or $ENV{VCPNODELETE} is set.
   if ( ! $tmp_dirs{$tmp_dir_root} && -e $tmp_dir_root ) {
      pr "removing previous working directory $tmp_dir_root";
      rmtree [$tmp_dir_root ], 0;
   }

   $tmp_dirs{$tmp_dir_root} = 1 ;
   return File::Spec->catdir( $tmp_dir_root, $plugin_dir, @_ ) ;
}


=item work_path

   $full_path = $self->work_path( $filename, $rev ) ;

Returns the full path to the working copy of the local filename.

Each VCP::Plugin gets their own hierarchy to use, usually rooted at
a directory named /tmp/vcp$$/plugin-source-foo/ for a module
VCP::Plugin::Source::foo.  $$ is vcp's process ID.

This is typically $work_root/$filename/$rev, but this may change.
$rev is put last instead of first in order to minimize the overhead of
creating lots of directories.

It *must* be under $work_root in order for rm_work_path() to fully
clean.

All directories will be created as needed, so you should be able
to create the file easily after calling this.  This is only
called by subclasses, and is optional: a subclass could create it's
own caching system.

Directories are created mode 0775 (rwxrwxr-x), subject to modification
by umask or your local operating system.  This will be modifiable in
the future.

=cut

sub work_path {
   my VCP::Plugin $self = shift ;

   my $path = File::Spec->canonpath(
      File::Spec->catfile( $self->work_root, @_ )
   ) ;

   return $path ;
}


=item mkdir

   $self->mkdir( $filename ) ;
   $self->mkdir( $filename, $mode ) ;

Makes a directory and any necessary parent directories.

The default mode is 770.  Does some debug logging if any directories are
created.

Returns nothing.

=cut

sub mkdir {
   my VCP::Plugin $self = shift ;

   my ( $path, $mode ) = @_ ;

   BUG "undefined \$path" unless defined $path;
   BUG "empty \$path" unless length  $path;

   unless ( -d $path ) {
      $mode = 0770 unless defined $mode ;
      lg "\$ ", shell_quote "mkdir", sprintf( "--mode=%04o", $mode ), $path;
      eval { mkpath [ $path ], 0, $mode }
         or die "failed to create $path with mode $mode: $@\n" ;
   }

   return ;
}


=item mkpdir

   $self->mkpdir( $filename ) ;
   $self->mkpdir( $filename, $mode ) ;

Makes the parent directory of a filename and all directories down to it.

The default mode is 770.  Does some debug logging if any directories are
created.

Returns the path of the parent directory.

=cut

sub mkpdir {
   my VCP::Plugin $self = shift ;

   my ( $path, $mode ) = @_ ;

   my ( undef, $dir ) = fileparse( $path ) ;

   $self->mkdir( $dir, $mode ) ;

   return $dir ;
}


=item rm_work_path

   $self->rm_work_path( $filename, $rev ) ;
   $self->rm_work_path( $dirname ) ;

Removes a directory or file from the work directory tree.  Also
removes any and all directories that become empty as a result up to
the work root (/tmp on Unix).

=cut

sub rm_work_path {
   my VCP::Plugin $self = shift ;

   my $path = $self->work_path( @_ ) ;

   if ( defined $path && -e $path ) {
      lg "\$ ", shell_quote "rm", "-rf", $path;
      if ( ! $ENV{VCPNODELETE} ) {
         rmtree $path or pr "$!: $path"
      }
      else {
         pr "not removing working directory $path due to VCPNODELETE\n";
      }
   }

   my $root = $self->work_root ;

   if ( substr( $path, 0, length $root ) eq $root ) {
      while ( length $path > length $root ) {
	 ( undef, $path ) = fileparse( $path ) ;
	 ## TODO: More discriminating error handling.  But the error emitted
	 ## when a directory is not empty may differ from platform
	 ## to platform, not sure.
	 last unless rmdir $path ;
      }
   }
}


=item work_root

   $root = $self->work_root ;
   $self->work_root( $new_root ) ;
   $self->work_root( $new_root, $dir1, $dir2, .... ) ;

Gets/sets the work root.  This defaults to

   File::Spec->tmpdir . "/vcp$$/" . $plugin_name

but may be altered.  If set to a relative path, the current working
directory is prepended.  The returned value is always absolute, and will
not change if you chdir().  Depending on the operating system, however,
it might not be located on to the current volume.  If not, it's a bug,
please patch away.

=cut

sub work_root {
   my VCP::Plugin $self = shift ;

   if ( @_ ) {
      if ( defined $_[0] ) {
	 $self->{WORK_ROOT} = File::Spec->catdir( @_ ) ;
	 lg ref $self, " work_root set to '",$self->work_root,"'";
	 unless ( File::Spec->file_name_is_absolute( $self->{WORK_ROOT} ) ) {
	    require Cwd ;
	    $self->{WORK_ROOT} = File::Spec->catdir( start_dir, @_ ) ;
	 }
      }
      else {
         $self->{WORK_ROOT} = undef ;
      }
   }

   return $self->{WORK_ROOT} ;
}


=item command_chdir

Sets/gets the directory to chdir into before running the default command.

DEPRECATED: use in_dir => "dirname" instead:

   $self->cvs(
      [..],
      \$in,
      \$out,
      in_dir => $dirname,
   );

=cut

sub command_chdir {
   my VCP::Plugin $self = shift ;
   if ( @_ ) {
      $self->{COMMAND_CHDIR} = shift ;
      lg ref $self, " command_chdir set to '", $self->command_chdir, "'";
   }
   return $self->{COMMAND_CHDIR} ;
}


=item command_stderr_filter

   $self->command_stderr_filter( qr/^cvs add: use 'cvs commit'.*\n/m ) ;
   $self->command_stderr_filter( sub { my $t = shift ; $$t =~ ... } ) ;

Some commands--cough*cvs*cough--just don't seem to be able to shut up
on stderr.  Other times we need to watch stderr for some meaningful output.

This allows you to filter out expected whinging on stderr so that the command
appears to run cleanly and doesn't cause $self->cmd(...) to barf when it sees
expected output on stderr.

This can also be used to filter out intermittent expected errors that
aren't errors in all contexts when they aren't actually errors.

DEPRECATED: use stderr_filter => qr/regexp/ instead:

    $self->ss( [ 'Delete', $file, "-I-y" ],
        stderr_filter => qr{^You have.*checked out.*Y[\r\n]*$}s,
        );

=cut

sub command_stderr_filter {
   my VCP::Plugin $self = shift ;
   $self->{COMMAND_STDERR_FILTER} = $_[0] if @_ ;
   return $self->{COMMAND_STDERR_FILTER} ;
}


=item command_ok_result_codes

   $self->command_ok_result_codes( 0, 1 ) ;

Occasionally, a non-zero result is Ok.  this method lets you set a list
of acceptable result codes.

DEPRECATED: use ok_result_codes => [ 0, 1, ... ] instead:

   $self->p4(
      [..],
      \$in,
      \$out,
      ok_result_codes => [ 0, 1 ]
   );

=cut

sub command_ok_result_codes {
   my VCP::Plugin $self = shift ;

   @{$self->{COMMAND_OK_RESULT_CODES}} = @_ if @_;

   return @{$self->{COMMAND_OK_RESULT_CODES}} ;
}


=item repo_id

   $self->repo_id( $repo_id ) ;
   $repo_id = $self->repo_id ;

Sets/gets the repo_id, a unique identifier for the repository.

=cut

sub repo_id {
   my VCP::Plugin $self = shift ;
   $self->{REPO_ID} = $_[0] if @_ ;
   return $self->{REPO_ID} ;
}



=item repo_scheme

   $self->repo_scheme( $scheme_name ) ;
   $scheme_name = $self->repo_scheme ;

Sets/gets the scheme specified ("cvs", "p4", "revml", etc). This is normally
superfluous, since the scheme name is peeked at in order to load the
correct VCP::{Source,Dest}::* class, which then calls this.

This is usually set automatically by L</parse_repo_spec>.

=cut

sub repo_scheme {
   my VCP::Plugin $self = shift ;
   $self->{REPO_SCHEME} = $_[0] if @_ ;
   return $self->{REPO_SCHEME} ;
}


=item repo_user

   $self->repo_user( $user_name ) ;
   $user_name = $self->repo_user ;

Sets/gets the user name to log in to the repository with.  Some plugins
ignore this, like revml, while others, like p4, use it.

This is usually set automatically by L</parse_repo_spec>.

=cut

sub repo_user {
   my VCP::Plugin $self = shift ;
   $self->{REPO_USER} = $_[0] if @_ ;
   return $self->{REPO_USER} ;
}


=item repo_password

   $self->repo_password( $password ) ;
   $password = $self->repo_password ;

Sets/gets the password to log in to the repository with.  Some plugins
ignore this, like revml, while others, like p4, use it.

This is usually set automatically by L</parse_repo_spec>.

=cut

sub repo_password {
   my VCP::Plugin $self = shift ;
   $self->{REPO_PASSWORD} = $_[0] if @_ ;
   return $self->{REPO_PASSWORD} ;
}


=item repo_server

   $self->repo_server( $server ) ;
   $server = $self->repo_server ;

Sets/gets the repository to log in to.  Some plugins
ignore this, like revml, while others, like p4, use it.

This is usually set automatically by L</parse_repo_spec>.

=cut

sub repo_server {
   my VCP::Plugin $self = shift ;
   $self->{REPO_SERVER} = $_[0] if @_ ;
   return $self->{REPO_SERVER} ;
}


=item repo_filespec

   $self->repo_filespec( $filespec ) ;
   $filespec = $self->repo_filespec ;

Sets/gets the filespec.

This is usually set automatically by L</parse_repo_spec>.

=cut

sub repo_filespec {
   my VCP::Plugin $self = shift ;
   $self->{REPO_FILESPEC} = $_[0] if @_ ;
   return $self->{REPO_FILESPEC} ;
}


=item rev_root

   $self->rev_root( 'depot' ) ;
   $rr = $self->rev_root ;

The rev_root is the root of the tree being sourced. See L</deduce_rev_root>
for automated extraction.

Root values should have neither a leading or trailing directory separator.

'/' and '\' are recognized as directory separators and runs of these
are converted to single '/' characters.  Leading and trailing '/'
characters are then removed.

=cut

sub _slash_hack {
   for ( my $spec = shift ) {
      BUG "undef arg" unless defined $spec ;
      s{[/\\]+}{/}g ;
      s{^/}{}g ;
      s{/\Z}{}g ;
      return $_ ;
   }
}

sub rev_root {
   my VCP::Plugin $self = shift ;

   if ( @_ ) {
      $self->{REV_ROOT} = &_slash_hack ;
      lg ref $self, " rev_root set to '$self->{REV_ROOT}'";
   }
   return $self->{REV_ROOT} ;
}


=item deduce_rev_root

   $self->deduce_rev_root ;
   print $self->rev_root ;

This is used in most plugins to deduce the rev_root from the filespec portion
of the source or destination spec if the user did not specify a rev_root as
an option.

This function sets the rev_root to be the portion of the filespec up to (but
not including) the first file/directory name with a wildcard.

'/' and '\' are recognized as directory separators, and '*', '?', and '...'
as wildcard sequences.  Runs of '/' and '\' characters are treated as
single '/' characters (this may damage UNC paths).

NOTE: if no wildcards are found and the last character is a '/' or '\\', then
the entire string will be considered to be the rev_root.  Otherwise the
spec is expected to refer to a file, in which case the rev_root does
not include the final name.  This means that

   cvs:/foo

and

   cvs:/foo/

are different.

=cut

sub deduce_rev_root {
   my VCP::Plugin $self = shift ;

   my ( $spec ) = @_;

   $spec =~ s{^[\\/]*}{}g;
   my @dirs ;
   for ( split( /[\\\/]+/, $spec, -1 ) ) {
      if ( /[*?]|\.\.\./ ) {
         push @dirs, "";  ## Pretend "/foo/bar/..." was "/foo/bar/"
         last ;
      }
      push @dirs, $_ ;
   }

   pop @dirs;  ## Throw away trailiing filename or ""

   $self->rev_root( join( '/', @dirs ) ) ;
}


=item normalize_name

   $fn = $self->normalize_name( $fn ) ;

Normalizes the filename by converting runs of '\' and '/' to '/', removing
leading '/' characters, and removing a leading rev_root.  Dies if the name
does not begin with rev_root.

=cut

sub normalize_name {
   my VCP::Plugin $self = shift ;

   ## my $revr = $self->{REV_ROOT};

   my ( $spec ) = &_slash_hack ;

   my $rr = $self->rev_root ;
   my $rrl = length $rr ;

   return $spec unless $rrl ;
   BUG "'$spec' does not begin with rev_root '$rr'"
      unless substr( $spec, 0, $rrl ) eq $rr ;
   die "no files under the rev root '$rr' in spec '$spec'\n"
      if $rrl + 1 > length $spec;
   my $s = substr( $spec, $rrl + 1 ) ;
   return $s;
}


=item denormalize_name

   $fn = $self->denormalize_name( $fn ) ;

Denormalizes the filename by prepending the rev_root.  May do more in
subclass overloads.  For instance, does not prepend a '//' by default for
instance, but p4 overloads do that.

=cut

sub denormalize_name {
   my VCP::Plugin $self = shift ;

   return join( '/', $self->rev_root, shift ) ;
}


=item run_safely

Runs a command "safely", first chdiring in to the proper directory and
then running it while examining STDERR through an optional filter and
looking at the result codes to see if the command exited acceptably.

Most often called from VCP::Utils::foo methods.

=cut

my $log_fh = lg_fh;
{

my $cached_in_fh  = tempfile( "vcp_XXXX" );
my $cached_in_fd  = fileno $cached_in_fh;
my $cached_out_fh = tempfile( "vcp_XXXX" );
my $cached_out_fd = fileno $cached_out_fh;
my $cached_err_fh = tempfile( "vcp_XXXX" );
my $cached_err_fd = fileno $cached_err_fh;

my $null_fn = File::Spec->devnull;;
my $null_in_fh = do {
   local *NULL;
   open NULL, "<$null_fn" or die "$!: $null_fn";
   *NULL{IO};
};
my $null_in_fd = fileno $null_in_fh;

my $null_out_fh = do {
   local *NULL;
   open NULL, ">$null_fn" or die "$!: $null_fn";
   *NULL{IO};
};

my $log_fd = fileno $log_fh;

## We ASSume that STDIN and STDOUT are not redirected in the course of running
## VCP, so we only have to save these off now.
my $saved_fd0;
my $saved_fd1;
my $saved_fd2;

if ( is_win32 ) {
   $saved_fd0 = dup 0;
   $saved_fd1 = dup 1;
   $saved_fd2 = dup 2;
}

sub _run3 {
   profile_start "run3()" if profiling;
   my ( $cmd, $stdin, $stdout, $stderr ) = @_;

   lg '$ ', shell_quote( @$cmd ),
      !ref $stdout && defined $stdout
        ? ( " > ", shell_quote( $stdout ) )
        : ();

   BUG "undef passed for stdin" unless defined $stdin;

   my $in_fh;
   my $in_fd;
   if ( $stdin != \undef ) {
      $in_fh = $cached_in_fh;
      truncate $in_fh, 0;
      seek $in_fh, 0, 0;
      $in_fd = $cached_in_fd;
      print $in_fh ref $stdin eq "ARRAY" ? @$stdin : $$stdin
         or die "$! writing to temp file\n";
      seek $in_fh, 0, 0;
   }
   else {
      $in_fh = $null_in_fh;
      $in_fd = $null_in_fd;
   }

   my $out_fh;
   my $out_fd;
   if ( defined $stdout ) {
      if ( ref $stdout ) {
        $out_fh = $cached_out_fh;
        $out_fd = $cached_out_fd;
        seek $out_fh, 0, 0;
        truncate $out_fh, 0;
      }
      else {
        local *OUT_FH;
        open OUT_FH, ">$stdout" or die "$!: $stdout";
        $out_fh = *OUT_FH{IO};
        $out_fd = fileno $out_fh;
      }
   }
   else {
      $out_fh = $log_fh;
      $out_fd = $log_fd;
   }

   my $err_fh;
   my $err_fd;
   if ( defined $stderr ) {
      $err_fh = $cached_err_fh;
      $err_fd = $cached_err_fd;
      seek $err_fh, 0, 0;
      truncate $err_fh, 0;
   }
   else {
      $err_fh = $log_fh;
      $err_fd = $log_fd;
   }

   if ( is_win32 ) {
      ## TODO: see if CreateProcess, etc, is faster.
      require IO::Handle;  ## need flush()

      ## Perl tries hard to flush these in system() but we're messing
      ## it up by sneaking the dup2()s in when it's not looking, so
      ## we need to flush these.
      flush STDOUT;
      flush STDERR;

      dup2 $in_fd,  0 or die "$! redirecting STDIN";
      dup2 $out_fd, 1 or die "$! redirecting STDOUT";
      dup2 $err_fd, 2 or die "$! redirecting STDERR";

      profile_start if profiling;
      my $r = system
         {$cmd->[0]}
         map {
            ## Probably need to offer a win32 escaping
            ## option to handle commands with
            ## different ideas of quoting.
            ( my $s = $_ ) =~ s/"/"""/g;
            $s;
         } @$cmd;
      my $x = $!;
      profile_end if profiling;

      dup2 $saved_fd0, 0 or die "$! restoring STDIN";
      dup2 $saved_fd1, 1 or die "$! restoring STDOUT";
      dup2 $saved_fd2, 2 or die "$! restoring STDERR";
      die $x unless defined $r;
   }
   else {
      ## ASSume Unix-like fork()/exec()
      profile_start if profiling;
      my $pid = fork;
      unless ( $pid ) {
         ## In child or with error.
         die "$! forking ", shell_quote( @$cmd ) unless defined $pid;

         ## In child, phew!
         dup2 $in_fd,  0 or die "$! redirecting STDIN";
         dup2 $out_fd, 1 or die "$! redirecting STDOUT";
         dup2 $err_fd, 2 or die "$! redirecting STDERR";
         exec @$cmd
            or die "$! execing ", shell_quote( @$cmd );
      }
      waitpid $pid, 0;
      profile_end if profiling;
   }


   if ( ! defined $stdout ) {
   }
   elsif ( ref $stdout eq "SCALAR" ) {
      seek $out_fh, 0, 0 or die "$! seeking on temp file for child output";

      my $count = read $out_fh, $$stdout, 10_000;
      $count = read $out_fh, $$stdout, 10_000, length $$stdout
         while $count == 10_000;

      die "$! reading child output from temp file"
         unless defined $count;
   }
   elsif ( ref $stdout eq "CODE" ) {
      seek $out_fh, 0, 0 or die "$! seeking on temp file for child output";
      $stdout->( $out_fh );
   }

   if ( defined $stderr ) {
      seek $err_fh, 0, 0 or die "$! seeking on temp file for child errput";

      my $count = read $err_fh, $$stderr, 10_000;
      $count = read $err_fh, $$stderr, 10_000, length $$stdout
         while $count == 10_000;

      die "$! reading child stderr from temp file"
         unless defined $count;
   }

   profile_end "run3()" if profiling;
}

}

sub run_safely {
   profile_start "run_safely()" if profiling;

   my VCP::Plugin $self = shift ;

   BUG "pass options in a trailing HASH instead of inline, please"
      if grep defined && /ok_result_codes|in_dir|stderr_filter/, @_;

   ## !!! this was in the old run_safely to call this sub when it was
   ## !!! called run_safely_new. I've reversed the logic here to catch
   ## !!! calls that were meant to drop through to the old run_safely.
   BUG "'run' call designed for old run routine (using IPC::Run)"
       unless ref $_[-1] eq "HASH" || ! grep defined $_ && 0 <= index( "<>", $_ ), @_;

   my $options = @_ && ref $_[-1] eq "HASH" ? pop : {};
   my ( $cmd, $stdin, $stdout, $stderr ) = @_;
   $options ||= {};

   ## NEVER pass on our own STDIN to the child.
   $stdin = \undef unless defined $stdin;

   my $cmd_path = $cmd->[0] ;
   my $cmd_name = basename( $cmd_path ) ;

   my $in_dir = defined $options->{in_dir} 
      ? File::Spec::Unix->rel2abs(
         $options->{in_dir},
         $self->command_chdir
      )
     : $self->command_chdir;

   my $childs_stderr = '' ;
   my $stderr_filter =
       defined $options->{stderr_filter}
          ? $options->{stderr_filter}
          : $self->command_stderr_filter;

   $stderr = \$childs_stderr if ! defined $stderr && $stderr_filter;

   my $ok_result_codes =
       defined $options->{ok_result_codes}
           ? $options->{ok_result_codes}
           : $self->{COMMAND_OK_RESULT_CODES};

   $self->{COMMAND_RESULT_CODE} = undef;

#   my $cwd ;

   if ( defined $in_dir ) {
      $self->mkdir( $in_dir )
	 unless -e $in_dir;

#      $cwd = cwd;

      xchdir $in_dir;
#      cwd;  # update $ENV{PWD} perhaps?  Can't recall, suspect so.
#      debug "now in ", cwd if debugging ;
   }

#   require IPC::Run3;
   
   _run3( $cmd, $stdin, $stdout, $stderr );
#   IPC::Run3::run3( $cmd, $stdin, $stdout, $stderr, $options );
   $self->{COMMAND_RESULT_CODE} = $? >> 8;

#   if ( defined $cwd ) {
#      chdir $cwd or die "$!: $cwd" ;
##      debug "now in ", cwd if debugging ;
#   }

   my @errors ;

   if ( length $childs_stderr ) {
      print $log_fh $childs_stderr;
      my $err = $childs_stderr;

      if ( ref $stderr_filter eq 'Regexp' ) {
         $err =~ s/$stderr_filter//mg ;
      }
      elsif ( ref $stderr_filter eq 'CODE' ) {
         $stderr_filter->( \$err ) ;
      }

      if ( length $err ) {
	 $err =~ s/^/$cmd_name: /gm ;
	 $err .= "\n" unless substr( $err, -1 ) eq "\n" ;
	 push (
	    @errors,
	    "unexpected stderr from '$cmd_name':\n",
	    $err,
	 ) ;
      }
   }

   ## In checking the result code, we assume the first one is the important
   ## one.  This is done because a few callers pipe the first child's output
   ## in to a perl sub that then does a kill 9,$$ to effectively exit without
   ## calling DESTROY.
   ## TODO: Look at all of the result codes if we can get rid of kill 9, $$.

   push(
      @errors,
      shell_quote( @$cmd ),
      " returned ",
      $self->{COMMAND_RESULT_CODE},
      " not ",
      join( ', ', @$ok_result_codes ),
      "\n",
      empty( $childs_stderr ) ? () : do {
         1 while chomp $childs_stderr;
         $childs_stderr =~ s/^/    /mg;
         ( "stderr:\n", $childs_stderr, "\n" );
      },
   )
      unless grep $_ eq $self->{COMMAND_RESULT_CODE}, @$ok_result_codes;

   die join( '', @errors ) if @errors ;

   BUG "Result of `", join( ' ', @$cmd ), "` checked"
      if defined wantarray ;

   profile_end "run_safely()" if profiling;
}

=item command_result_code

Returns the result code from the last C<run_safely()> command.  This is
a separate method because (a) most invocations set the ok result codes
list so that funny looking but ok results are ignored, and (2) because
returning the command execution code from the run() command leads to
funny looking inverted logic because most shell commands return 0 for
sucess.  Now, if Perl has an "N but false" special case to go with its
"0 but true".

This is read-only.

=cut

sub command_result_code {
   my VCP::Plugin $self = shift ;

   return $self->{COMMAND_RESULT_CODE};
}

=item is_sort_filter

Defaults to 0, set in (at least)
L<VCP::Filter::changesets|VCP::Filter::changesets> and
L<VCP::Filter::sort|VCP::Filter::sort>.  The L<VCP|VCP> module uses this
to determine whether or not to automatically insert
VCP::Filter::changesets or after the source.

If the filter chain contains no filters with a true is_sort_filter then
VCP inserts a sort filter immediately after the source.

=cut

sub is_sort_filter { 0 }



sub DESTROY {
   my VCP::Plugin $self = shift ;

   if ( defined $self->work_root ) {
      local $@ ;
      eval { $self->rm_work_path() ; } ;

      pr "unable to remove work directory '", $self->work_root, "'\n"
	 if ! $ENV{VCPNODELETE} && -d $self->work_root ;
   }
}

=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1
