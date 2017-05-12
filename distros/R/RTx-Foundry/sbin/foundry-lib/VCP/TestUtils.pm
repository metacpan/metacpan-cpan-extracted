package VCP::TestUtils ;

=head1 NAME

VCP::TestUtils - support routines for VCP testing

=cut

use Exporter ;

@EXPORT = qw(
   assert_eq
   slurp
   tmpdir
   copy_dir_tree
   rm_dir_tree
   perl_cmd
   vcp_cmd
   compile_dtd_cmd
   parse_files_and_revids_from_head_revs_db
   parse_files_and_revids_from_revml
   parse_files_and_revids_from_p4_files
   parse_files_and_revids_from_cvs_history
   get_vcp_output

   p4d_borken 
   launch_p4d

   cvs_borken
   init_cvsroot

   vss_borken

   s_content
   rm_elts

   run
   run_p4
) ;

@ISA = qw( Exporter ) ;

use strict ;

use Carp ;
use Cwd ;
use File::Copy;
use File::Find;
use File::Path ;
use File::Spec ;
use IPC::Run qw( start kill_kill ) ;
use IPC::Run3;
use POSIX ':sys_wait_h' ;
use Text::Diff ;
use VCP::HeadRevsDB;
use VCP::Rev;
use VCP::Utils qw( shell_quote empty escape_filename );

=head1 General utility functions

=over

=cut

{
   my @tmp_dirs ;
   END { rmtree \@tmp_dirs unless $ENV{VCPNODELETE} }

   sub mk_tmp_dir {
      confess "undef!!" if grep !defined, @_ ;
      rmtree \@_ ;
      mkpath \@_, 0, 0770 ;
      push @tmp_dirs, @_ ;
   }
}

=item copy_dir_tree

   copy_dir_tree $src, $dest;

Copy source directory tree to a destination directory.  Accepts
absolute or relative directory names, but doesn't do tilde expansion.

=cut


sub copy_dir_tree {
   croak "usage $0 <src-dir> <dest-dir>\n"
      unless @_ == 2;

   my ($src_dir, $dest_dir) = @_;

   $src_dir = File::Spec->rel2abs( $src_dir );
   $dest_dir = File::Spec->rel2abs( $dest_dir );

   croak "destination and source directories are the same\n"
      if $dest_dir eq $src_dir;
   croak "destination directory specified as a subdir of source directory, stopping.\n"
      if $dest_dir =~ /^$src_dir/ ;

   croak "source directory '$src_dir' doesn't exist\n"
      unless -e $src_dir;
   croak "source directory '$src_dir' isn't a directory\n"
      unless -d $src_dir;
   croak "destination '$dest_dir' already exists\n"
      if -e $dest_dir;

   find(
      { 
         no_chdir => 1,
         wanted => sub {  
            my $newname = $_;
            $newname =~ s/^$src_dir/$dest_dir/ ;

            my ( $perms, $uid, $gid ) = (stat)[2,4,5];

            if ( -d ) {          # source was a directory
               mkdir $newname or croak "couldn't create directory '$newname': $!\n";
            }
            else {
               copy $_, $newname or croak "couldn't copy file from '$_' to '$newname'\n";
            }

            chmod $perms, $newname or warn "$!: chmod()ing $newname\n";
            chown $uid, $gid, $newname or warn "$!: chown()ing $newname\n";
         },
      },
      $src_dir 
   );
}


=item rm_dir_tree

    rm_dir_tree $path;

Remove a directory tree.  Does not complain if it's not there to remove.

=cut

sub rm_dir_tree {
   croak "usage $0 <doomed-dir>\n"
      unless @_ == 1;

   my( $doomed_dir ) = @_;

   return unless -e $doomed_dir;

   rmtree [ $doomed_dir ], 0;
}



=item assert_eq

   assert_eq $test_name, $in, $out ;

dies with a useful diff in $@ is $in ne $out.  Returns nothing.

Requires a diff that knows about the -d and -U options.

=cut


sub assert_eq {
   my ( $name, $in, $out ) = @_ ;

   ## Doint this because Test::Differences isn't quite "real" yet...
   croak diff \$in, \$out, { CONTEXT => 10 } if $in ne $out ;
}

=item slurp

   $guts = slurp $filename ;
   @lines = slurp $filename;

   read entire contents of file and return as a scalar, or array in
   array context (splitting on newlines.)

=cut

sub slurp {
   my ( $fn ) = @_ ;
   open F, "<$fn" or croak "$!: $fn" ;
   binmode F ;
   local $/ ;
   my $s = <F>;
   close F;
   return $s;
}


=item perl_cmd

   @perl = perl_cmd

Returns a list containing the Perl executable and some options to reproduce
the current Perl options , like -I.

=cut

sub perl_cmd {
   my %seen ;
   return (
      $^X,
      (
	 map {
	    my $s = $_ ;
	    $s = File::Spec->rel2abs( $_ ) ;
	    "-I$s" ;
	 } grep ! $seen{$_}++, @INC
      )
   ) ;
}


=item find_command

   @vcp = find_command "vcp"

Find a script within the main distro directory or one subdir under it.
Looks for "bin/<cmd>" and "../bin/<cmd>".  This should be adequate for
almost all uses.

=cut

sub find_command {
   ## We always run vcp by doing a @perl, vcp, to make sure that vcp runs under
   ## the same version of perl that we are running under.
   my $cmd = shift;
   $cmd = "bin/$cmd"    if -e "bin/$cmd" ;
   $cmd = "../bin/$cmd" if -e "../bin/$cmd" ;

   $cmd = File::Spec->rel2abs( $cmd ) ;

   return $cmd;
}




=item vcp_cmd

   @vcp = vcp_cmd

Returns a list containing the Perl executable and some options to reproduce
the current Perl options , like -I.

vcp_cmd assumes it is called from within the main distro directory or one
subdir under it, since it looks for "bin/vcp" and "../bin/vcp".  This should be
adequate for almost all uses.

vcp_cmd caches it's results to allow it to be run from other directories after
the first time it's called. (this is not a significant performance improvement;
running the vcp process takes several orders of magnitude longer than the quick
checks vcp_cmd does).

=cut

my @vcp_cmd ;

sub vcp_cmd {
   unless ( @vcp_cmd ) {
      ## We always run vcp by doing a @perl, vcp, to make sure that
      ## vcp runs under the same version of perl that we are running under.
      @vcp_cmd = ( perl_cmd, find_command 'vcp' ) ;
   }
   return @vcp_cmd ;
}


=item compile_dtd_cmd

   @compile_dtd = compile_dtd_cmd

Returns a list containing the Perl executable and some options to
reproduce the current Perl options , like -I.

compile_dtd_cmd assumes it is called from within the main distro
directory or one subdir under it, since it looks for "bin/compile_dtd"
and "../bin/compile_dtd".  This should be adequate for almost all
uses.

compile_dtd_cmd caches it's results to allow it to be run from other
directories after the first time it's called.

=cut

my @compile_dtd_cmd ;

sub compile_dtd_cmd {
   unless ( @compile_dtd_cmd ) {
      ## We always run compile_dtd by doing a @perl, compile_dtd, to
      ## make sure that compile_dtd runs under the same version of
      ## perl that we are running under.
      @compile_dtd_cmd = ( perl_cmd, find_command 'compile_dtd' ) ;
   }
   return @compile_dtd_cmd ;
}



# =item run
# 
# Run a command using IPC::Run::run, but with logging and a verbose
# exception on non-0 result code.
# 
# Arguments are the same as and are passed to IPC::Run
# 
# =cut
# 
# sub run_old {
#    goto &run_new
#        if ref $_[-1] eq "HASH" || ! grep defined $_ && 0 <= index( "<>", $_ ), @_;
# 
#    my $options = @_ && ref $_[-1] eq "HASH" ? pop : ();
# 
#    Carp::cluck "\n\n==RUNNING== \n";
# 
#    my @log_cmd = @{$_[0]};
# 
#    if ( $log_cmd[0] eq $^X ) {  # running a command via perl
#       # replace all perl -I options with a "-I..." option to enhance
#       # readability.
#       @log_cmd = (
#          $log_cmd[0],
#          "-I...",
#          grep ! /^-I/, @log_cmd[1..$#log_cmd]
#       );
# 
#       # vcp is run using perl.  get rid of perl and its lengthy
#       # arguments in the log so the user doesn't need to see them.
#       my $i;
#       my @run_command = grep $i ||= /\bvcp\z/, @log_cmd[1..$#log_cmd];
#       @log_cmd = ( "vcp", @run_command[ 1..$#run_command ] ) if @run_command;
#    }
#    print "#\$ ", shell_quote( @log_cmd ), "\n";
# 
#    my $start_time = time;
#    IPC::Run::run( @_ );
# 
#    my $r = $? >> 8;
# 
#    $options->{ok_result_codes} ||= [0];
# 
#    $r = undef
#       if grep $r == $_, @{$options->{ok_result_codes}};
# 
#    croak "`", shell_quote( @log_cmd ), "`",
#       " returned $r, not one of (",
#       @{$options->{ok_result_codes}} == 1
#          ? $options->{ok_result_codes}->[0]
#          : join( ", ", @{$options->{ok_result_codes}} ),
#       ")"
#       if defined $r;
# 
#    my $time = time - $start_time;
#    my $mins = int( $time / 60 );
#    printf "# %02d:%02d\n", $mins, $time - $mins * 60;
# }

=item run_new

Run a command using IPC::Run3::run3, but with logging and a verbose
exception on non-0 result code.

Arguments are the same as and are passed to IPC::Run

=cut

sub run {
   confess "BUG: pass options in a trailing HASH instead of inline, please"
      if grep defined && /ok_result_codes|in_dir|stderr_filter/, @_;

   ## !!! this was in the old run to call this sub when it was called run_new
   ## !!! I've reversed the logic here to catch calls that were meant to drop
   ## !!! through to the old run.
   croak "'run' call designed for old run routine (using IPC::Run)"
      unless ref $_[-1] eq "HASH" || ! grep defined $_ && 0 <= index( "<>", $_ ), @_;

   my $options = @_ && ref $_[-1] eq "HASH" ? pop : ();
   my ( $cmd, $stdin, $stdout, $stderr ) = @_;
   $options ||= {};

   my @log_cmd = @$cmd;

   if ( $log_cmd[0] eq $^X ) {  # running a command via perl
      # replace all perl -I options with a "-I..." option to enhance
      # readability.
      @log_cmd = (
         $log_cmd[0],
         "-I...",
         grep ! /^-I/, @log_cmd[1..$#log_cmd]
      );

      # vcp is run using perl.  get rid of perl and its lengthy
      # arguments in the log so the user doesn't need to see them.
      my $i;
      my @run_command = grep $i ||= /\bvcp\z/, @log_cmd[1..$#log_cmd];
      @log_cmd = ( "vcp", @run_command[ 1..$#run_command ] ) if @run_command;
   }

   print "#\$ ", shell_quote( @log_cmd ), "\n";

   my $run_cmd = $cmd;
   my $start_time = time;
   IPC::Run3::run3( $run_cmd, $stdin, $stdout, $stderr, $options );

   my $r = $? >> 8;

   $options->{ok_result_codes} ||= [0];

   $r = undef
      if grep $r == $_, @{$options->{ok_result_codes}};

   croak "`", shell_quote( @log_cmd ), "`",
      " returned $r, not one of (",
      @{$options->{ok_result_codes}} == 1
         ? $options->{ok_result_codes}->[0]
         : join( ", ", @{$options->{ok_result_codes}} ),
      ")"
      if defined $r;

   my $time = time - $start_time;
   my $mins = int( $time / 60 );
   printf "# %02d:%02d\n", $mins, $time - $mins * 60;
}


=item run_p4

calls 'run' to run p4 binary after deciding which platform specific
program to run.

determines p4 executable name based on operating system.

builds p4 options string from $p4_options hash

examples: 

    run_p4 \@args, \$stdin, \$stdout, \$stderr, $p4_options;
    run_p4 [ qw(files) ], \undef, \$stdout, $p4_options;

arguments:

=over

=item 1.

array of words to add to end of p4 command

=item 2...

remaining arguments passed on to 'run' sub (except final arg)

=item final arg:

p4_options hash (may contain: port, user, client, password ... ?)

=back

=cut   


sub run_p4 {
   die "usage: run_p4 <array-of-additional-p4-commands> <p4-options-hash> [args-to-run-cmd]..."
      unless @_ >= 2;

   my $extra_p4_commands = shift;
   my $p4_options = pop;
   croak "no options passed" unless ref $p4_options eq "HASH" ;
   my @p4_args;
   local $ENV{P4PASSWD} = $p4_options->{password} if defined $p4_options->{password} ;

   push @p4_args, '-p', $p4_options->{port}    if defined $p4_options->{port} ;
   push @p4_args, '-c', $p4_options->{client}  if defined $p4_options->{client} ;
   push @p4_args, '-u', $p4_options->{user}    if defined $p4_options->{user} ;
   push @p4_args, @$extra_p4_commands;

   my $p4_binary = $^O =~ /Win32/ ? "p4.exe" : "p4" ;

   run [ $p4_binary, @p4_args ], @_ ;
}


=item parse_files_and_revids_from_head_revs_db <options-hash>

options:
    state_dir
    repo_id
    remove_rev_root (string to be removed from front of filename)

given a vcp state directory and repo_id, dump the head revs to a
string, and parse out the <name> and <rev_id> elements within each
<rev>, then return a string (sorted by line) of the form:

    <name1> <max_revision_num1>
    <name2> <max_revision_num2>
    <name3> <max_revision_num3>
    .
    .
    .

examples:

   my $revs = parse_files_and_revids_from_head_revs_db
      { state_dir => $state_dir, repo_id => $repo_id }
   my $revs = parse_files_and_revids_from_head_revs_db $state_dir $repo_id 
      { state_dir => $state_dir, repo_id => $repo_id, remove_rev_root => "/ignore/" }

=cut

sub parse_files_and_revids_from_head_revs_db {
   croak "usage: parse_files_and_revids_from_head_revs_db <options hash>"
      unless @_ == 1 && ref $_[0] eq "HASH";
   my $options = shift;

   my $state_dir       = $options->{state_dir};
   croak "state_dir option required" if empty $state_dir;
   my $repo_id         = $options->{repo_id};
   croak "repo_id option required" if empty $repo_id;
   my $remove_rev_root = $options->{remove_rev_root};

   my $store_loc = File::Spec->catfile( $state_dir, escape_filename $repo_id );

   my $db = VCP::HeadRevsDB->new( StoreLoc => $store_loc );
   $db->open_existing_db;
   my @dump = $db->dump;
   $db->close_db;

   my $revs = {};

   my $line;
   for( @dump ) {
      $line++;

      # make the dump look like parse_files_and_revids_from_revml
      s/^[^\s]+\s+// ;   # remove repo_id field
      s/\s+/ /g ;        # collapse multiple spaces

      # Dump output seems to look like either of
      #   a/file/name => '1.1'
      # or the more complicated cases:
      #   a/file/name<> => ('1.1','edit')
      #   a/file/name<1> => ('1.1','edit')
      #
      # This code makes the complicated case look like the simple case.
      s/<[\d.]*> => \(/ => / ;
      s/\)$// ;
      s/'[^\d.',]+'//g ;
      s/,*$// ;

      # remove quotes from version number
      s/=> '([\d.]+)'/=> $1/ ;

      unless( empty $remove_rev_root ) {
         die "'HeadRevsDB->dump' output lines weren't preceeded by $remove_rev_root as expected"
            if index( $_, $remove_rev_root ) < 0 ;
         $_ = substr $_, length $remove_rev_root ;
      }
         
   }

   return join "", map "$_\n", sort @dump;
}


=item parse_files_and_revids_from_revml

given one or more revml filenames, slurp them up, parse out the <name>
and <rev_id> elements within each <rev>, then return a string (sorted
by line) of the form:

    <name1> <max_revision_num1>
    <name2> <max_revision_num2>
    <name3> <max_revision_num3>
    .
    .
    .


The final (optional) argument may be a reference to a hash of
parameters.  Currently the only parameter is
IGNORE_REVS_WITH_DELETE_FLAG, which if true, causes any revs
containing the <delete /> or <delete/> tags to be ignored.

examples:

   my $revs = parse_files_and_revids_from_revml $infile ;
   my $revs = parse_files_and_revids_from_revml $infile1, $infile2 ;

=cut

sub parse_files_and_revids_from_revml {
   my $options = @_ && ref $_[-1] ? pop : {} ;
   croak "usage: parse_files_and_revids_from_revml <infile> ... [options-hash-ref]"
      unless @_ >= 1;

   my $ignore_revs_with_delete_tag = $options->{IGNORE_REVS_WITH_DELETE_FLAG};
   my $revs = {};

   for( @_ ) {
      my $revml = slurp $_;

      # find <rev> tag
      while ( $revml =~ / < rev \b [^>] * > ( .*? ) < \/ rev > /gsx ) {   
         my $rev = $1;

         # look for tags within <rev> tag
         my ($name, $rev_id, $source_filebranch_id);

         # <name> tag
         $name = $1
            if $rev =~ m{ <name> ( [^<] * ) <\/name> }gx ;

         # <source_filebranch_id> tag
         $source_filebranch_id = $1
            if $rev =~ m{ <source_filebranch_id> ( [^<] * ) <\/source_filebranch_id> }gx ;

         # <rev_id> tag
         $rev_id = $1
            if $rev =~ m{ <rev_id> ( [^<] * ) <\/rev_id> }gx ;

         # <delete /> tag
         next if $ignore_revs_with_delete_tag 
            && $rev =~ m{<delete ?\/>} ;

         croak "rev found without <name> tag at line $."
            unless defined $name;
         croak "rev found without <rev_id> tag at line $."
            unless defined $rev_id;
         croak "rev found without <source_filebranch_id> tag at line $."
            unless defined $source_filebranch_id;

         # keep name and source_filebranch_id for the greatest rev_id
         if( ! exists $revs->{$source_filebranch_id}
             || VCP::Rev->cmp_id( $revs->{$source_filebranch_id}->{rev_id}, $rev_id ) < 0
           ) 
         {
            $revs->{$source_filebranch_id}->{rev_id} = $rev_id;
            $revs->{$source_filebranch_id}->{name} = $name;
         }

      }
   }

   return join "", map { "$revs->{$_}->{name} => $revs->{$_}->{rev_id}\n" } sort keys %$revs;
}


=item parse_files_and_revids_from_p4_files

Run p4 files command line to get list of changed files.  Parse the
output so it can be diffed with the output of parse_files_and_revids_from_revml.

returns a string containing names and revision numbers, 1 per line.
See that sub above for a description of the output format.   

arguments are:

=over

=item 1.

revision root, e.g. "//depot/something/".  This string will be removed
from the output so it may be diffed with parse_files_and_revids_from_revml
output.

=item 2.

p4_options hash as returned from launch_p4d

=item 3...

1 or more file[revRange] spec for p4 files command (run 'p4 help
files' and 'p4 help revisions' command line for formatting help)

=back

example usage:

    parse_files_and_revids_from_p4_files $p4_rev_root, $p4_options, "//..."

=cut   

sub parse_files_and_revids_from_p4_files {
   croak "usage: parse_files_and_revids_from_p4_files <p4_rev_root>, <p4_options hash>, <file_spec>... "
      unless @_ >= 3;

   my ($p4_rev_root, $p4_options) = (shift, shift);
   my $output;

   run_p4 [ "files", @_ ], 
      \undef, \$output, $p4_options;

   my $h = {};
   while ( $output =~ m{(.*)#(\d+) - }g ) {
      die "'p4 files' output lines weren't preceeded by $p4_rev_root as expected"
         if index( $1, $p4_rev_root ) < 0 ;
      my $name = substr $1, length $p4_rev_root ;

      die "duplicate file names in p4 files output"
         if exists $h->{$name};
      $h->{$name} = $2 ;
   }

   return join "", map { "$_ => $h->{$_}\n" } sort keys %$h;
}


=item parse_files_and_revids_from_cvs_history

Run cvs history command line to get list of changed files.  Parse the
output so it can be diffed with the output of parse_files_and_revids_from_revml.

returns a string containing names and revision numbers, 1 per line.
See that sub above for a description of the output format.   

arguments are:

=over

=item 1.

cvs root directory.

=item 2.

cvs module name.  This string will be removed from the output so it
may be diffed with parse_files_and_revids_from_revml output.

=back

example usage:

    parse_files_and_revids_from_cvs_history "/home/blah/blah/cvsroot_0/", "module-blah"

=cut   

sub parse_files_and_revids_from_cvs_history {
   croak "usage: parse_files_and_revids_from_cvs_history <cvs-root>, <cvs-module>"
      unless @_ == 2;

   my ($cvs_root, $cvs_module) = (shift, shift);
   my $output;

#   run [ "cvs", "-d", $cvs_root, "history", "-xAM" ], 
   run [ "cvs", "-d", $cvs_root, "history", "-c" ], 
      \undef, \$output;

   my $h = {};
   my @lines = split /\n/, $output;
   for ( @lines ) {
      my @fields = split;
      my $name = "$fields[7]/$fields[6]";
      die "'cvs history' output line ($_), name ($name) didn't contain module name '$cvs_module' as expected"
         if index( $name, $cvs_module ) != 0 ;
      # remove cvs_module name plus directory separator
      $name = substr $name, length( $cvs_module ) + 1; 

      # keep the greatest rev_id
      my $rev_id = $fields[5];
      $h->{$name} = $rev_id
         if ! exists $h->{$name} || ! defined $h->{$name} || $h->{$name} lt $rev_id ;
   }
   
   return join "", map { "$_ => $h->{$_}\n" } sort keys %$h;
}



=item get_vcp_output

   @vcp = get_vcp_output "foo:", "-bar" ;

Does a:

   run [ vcp_cmd, @_, "sort:", "--", "revml:", ... ], \undef, \$out
      or croak "`vcp blahdy blah` returned $?";

and returns $out.  The "..." refers to whatever output options are needed
to make the test output agree with C<bin/gentrevml>'s test files
(t/test-*.revml).

You may pass in options as a hash reference as the final argument.
The supported option is:

  revml_out_spec

which, if present, is tacked on to the revml: output spec's list of options,

=cut

sub get_vcp_output {
   my $options = @_ && ref $_[-1] eq "HASH" ? pop : {} ;
   my @args = ( @_, "sort:", "--", "revml:" );

   push @args, @{ $options->{revml_out_spec} }
      if exists $options->{revml_out_spec};
   
   run [ vcp_cmd, @args ], \undef, \my $out;
   return $out ;
}


=back

=head1 XML "cleanup" functions

These are used to get rid of content or elements that are known to differ
when comparing the revml fed in to a repository with the revml that
comes out.

=over

=item s_content

   s_content
      $elt_type1, $elt_type2, ..., \$string1, \$string2, ..., $new_content ;

Changes the contents of the elements, since some things, like suer id or
mod_time can't be the same after going through a repository.

If $new_val is not supplied, a constant string is used.

=cut

sub s_content {
   my $new_val = pop if @_ && ! ref $_[-1] ;
   $new_val = "<!-- deleted by test suite -->" unless defined $new_val ;

   my $elt_type_re = do {
      my @a ;
      push @a, quotemeta shift while @_ && ! ref $_[0] ;
      join "|", @a ;
   } ;

   $$_ =~ s{(<($elt_type_re)[^>]*?>).*?(</\2\s*>)}
	   {$1$new_val$3}sg
      for @_ ;

   $$_ =~ s{(<($elt_type_re)[^>]*?>).*?(</\2\s*>)}{$1$new_val$3}sg
      for @_ ;
}


=item rm_elts

   rm_elts $elt_type1, $elt_type2, ..., \$string1, \$string2
   rm_elts $elt_type1, $elt_type2, ..., qr/$content_re/, \$string1, \$string2

Removes the specified elements from the strings, including leading whitespace
and trailing line separators.  If the optional $content_re regular expression
is provided, then only elements containing that pattern will be removed.

=back

=cut

sub rm_elts {
   my $elt_type_re = do {
      my @a ;
      push @a, quotemeta shift while @_ && ! ref $_[0] ;
      join "|", @a ;
   } ;

   my $content_re = @_ && ref $_[0] eq "Regexp" ? shift : qr/.*?/s ;
   my $re = qr{^\s*<($elt_type_re)\b[^>]*?>$content_re</\1\s*>\r?\n}sm ;

   $$_ =~ s{$re}{}g for @_ ;
}

=head1 p4 repository mgmt functions

=over

=item p4_borken

Returns true if the p4 is missing or too old (< 99.2).

=cut

sub p4d_borken {
   my $p4dV = `p4d -V` || 0 ;
   return "p4d not found" unless $p4dV ;

   my ( $p4d_version ) = $p4dV =~ m{^Rev[^/]*/[^/]*/([^/]*)}m ;

   my $min_version = 99.2 ;
   return "p4d version too old, need at least $min_version"
       unless $p4d_version >= $min_version ;
   return "" ;
}


=item tmpdir

    my $d = tmpdir            ## create a directory like /tmp/vcp_95cvs2p4_#####
    my $d = tmpdir( "foo" );  ## create a directory like /tmp/vcp_95cvs2p4_foo_#####

Return a temporary directory that will be deleted in an END block.

The prefix is advisory only and is meant to allow developers to intuit
the purpose of a temporary directory from its name.

See File::Spec::Unix's tmpdir() function for details, but you can set
the TMPDIR environment variable to control where the VCP test suite
places temp dirs (and, after testing, where vcp places test dirs, but
vcp has separate temp directory management functions).

=cut

sub tmpdir {
   my ( $prefix ) = @_;

   $prefix = ( ! empty $prefix ) ? "${prefix}_" : "";

   require File::Basename;
   ( my $progname = File::Basename::basename( $0 ) ) =~ s/\..*//;

   require File::Temp;
   my $dir = File::Temp::tempdir(
      "vcp_${progname}_${prefix}XXXX",
      DIR => File::Spec->tmpdir,
   );

   ## We clean up the dir ourselves cuz tempdir( CLEANUP => 1 ) doesn't
   ## delete the dir if it's nonempty.
   mk_tmp_dir $dir;
   $dir;
}


=item launch_p4d

   launch_p4d "prefix_" ;

Creates an empty repository and launches a p4d for it.  The p4d will be killed
and it's repository deleted on exit.  Returns the options needed to access
the repository, plus a handle to the IPC::Run harness for the p4d.

May pass these options as a hash argument:
  
repo_dir : name of repository directory

rm_repo_dir : if true, remove existing repository directory before creating new one.

copy_from_dir : copy repository from this directory.  implies rm_repo_dir.

=cut

sub launch_p4d {
   my $options = @_ && ref $_[-1] ? pop : {} ;

   $options->{rm_repo_dir} ||= defined $options->{copy_from_dir} ;

   my $prefix = shift || "" ;

   {
      my $borken = p4d_borken ;
      croak $borken if $borken ;
   }

   my $repo = $options->{repo_dir};

   if ( defined $repo ) {
      rmtree [ $repo ] if $options->{rm_repo_dir};
      mkpath [ $repo ] unless -e $repo || defined $options->{copy_from_dir} ;
   }
   else {
      $prefix .= "_" if length $prefix;
      $repo = tmpdir "${prefix}p4repo";
   }
   copy_dir_tree $options->{copy_from_dir}, $repo
      if defined $options->{copy_from_dir} ;

   ## Ok, this is wierd: we need to fork & run p4d in foreground mode so that
   ## we can capture it's PID and kill it later.  There doesn't seem to be
   ## the equivalent of a 'p4d.pid' file. If we let it daemonize, then I
   ## don't know how to get it's PID.

   my $port ;
   my $tries ;
   my $h ;
   while () {
      ## 30_000 is because I vaguely recall some TCP stack that had problems
      ## with listening on really high ports.  2048 is because I vaguely recall
      ## that some OS required root privs up to 2047 instead of 1023.
      $port = ( rand( 65536 ) % 30_000 ) + 2048 ;
      my @p4d = ( "p4d", "-f", "-r", $repo, "-p", $port ) ;
      print "# Running ", join( " ", @p4d ), "\n" ;
      $h = start \@p4d ;
      ## Wait for p4d to start.  'twould be better to wait for P4PORT to
      ## be seen.
      sleep 1 ;

      ## The child process will have died if the port is taken or due
      ## to other errors.
      last if $h->pumpable;
      finish $h;
      die "p4d failed to start after $tries tries, aborting\n"
         if ++$tries >= 3 ;
      warn "p4d failed to start, retrying\n" ;
   }

   END {
      return unless $h;
      $h->kill_kill;
      $? = 0;  ## p4d exits with a "15", which becomes our exit code
               ## if we don't clear this.
   }

   return {
      user => "${prefix}t_user",
      port => $port,
      p4d_handle => $h,           
   } ;
}

=back

=head1 CVS mgmt functions

=over

=item cvs_borken

Returns true if cvs -v works and outputs "Concurrent Versions System".

=cut

sub cvs_borken {
   my $cvsV = `cvs -v` || 0 ;
   return "cvs command not found" unless $cvsV ;
   return "cvs command does not appear to be for CVS: '$cvsV'"
       unless $cvsV =~ /Concurrent Versions System/;

   return "" ;
}

=item init_cvsroot

   my $cvs_options = init_cvsroot $prefix, $module_name ;
   my $cvs_options = init_cvsroot $prefix, $module_name, $rootdir ;

Creates a CVS repository containing an empty module. Also sets
$ENV{LOGNAME} if it notices that we're running as root, so CVS won't give
a "cannot commit files as 'root'" error. Tries "nobody", then "guest".

Returns the options needed to access the cvs repository.

=cut

sub init_cvsroot {
   my ( $prefix , $module, $root ) = @_ ;

   my $tmp = File::Spec->tmpdir ;

   my $is_tmp_root = ! defined $root;

   $prefix = "" unless defined $prefix;
   $prefix .= "_" if length $prefix;
   $root = tmpdir( "${prefix}cvsroot" ) unless defined $root;

   my $options = {
      repo => $root,
      work => tmpdir( "${prefix}cvswork" ),
   } ;

   my $cwd = cwd ;
   ## Give vcp ... cvs:... a repository to work with.  Note that it does not
   ## use $cvswork, just this test script does.

   $ENV{CVSROOT} = $options->{repo} ;

   ## CVS does not like root to commit files.  So, try to fool it.
   ## CVS calls geteuid() to determine rootness (so does perl's $>).
   ## If root, CVS calls getlogin() first, then checks the LOGNAME and USER
   ## environment vars.
   ##
   ## What this means is: if the user is actually logged in on a physical
   ## terminal as 'root', getlogin() will return "root" to cvs and we can't
   ## fool CVS.
   ##
   ## However, if they've used "su", a very common occurence, then getlogin()
   ## will return failure (NULL in C, undef in Perl) and we can spoof CVS
   ## using $ENV{LOGNAME}.
   if ( ! $>  && $^O !~ /Win32/ ) {
      my $login = getlogin ;
      if ( ( ! defined $login || ! getpwnam $login )
         && ( ! exists $ENV{LOGNAME} || ! getpwnam $ENV{LOGNAME} )
      ) {
	 for ( qw( nobody guest ) ) {
	    my $uid = getpwnam $_ ;
	    next unless defined $uid ;
	    ( $ENV{LOGNAME}, $> ) = ( $_, $uid ) ;
	    last ;
	 }
	 ## Must set uid, too, to keep perl (and thus vcp) from bombing
	 ## out when running setuid and given a -I option. This happens
	 ## a lot in the test suite, since the tests often call vcp
	 ## using "perl", "-Iblib/lib", "bin/vcp", ... to recreate the
	 ## appropriate operating environment for Perl.  If this becomes
	 ## a problem, perhaps we can hack in a "run as user" option to
	 ## VCP::Utils::cvs so that only the cvs subcommands are run
	 ## setuid, or perhaps we can avoid passing "-I" to the perls.
	 $< = $> ;
	 
	 warn
	    "# Setting real & eff. uids=",
	    $>,
	    "(",
	    $ENV{LOGNAME},
	    qq{) to quell "cvs: cannot commit files as 'root'"\n} ;
      }
   }

   run [ qw( cvs init ) ];

   chdir $options->{work}                    or die "$!: $options->{work}" ;

   mkdir $module, 0770                       or die "$!: $module" ;
   chdir $module                             or die "$!: $module" ;
   run [ qw( cvs import -m ), "$module import", $module, "${module}_vendor", "${module}_release" ];
   chdir $cwd                                or die "$!: $cwd" ;

   delete $ENV{CVSROOT} ;
#   chdir ".."                                or die "$! .." ;
#
#   system qw( cvs checkout CVSROOT/modules ) and die "cvs checkout failed" ;
#
#   open MODULES, ">>CVSROOT/modules"         or  die "$!: CVSROOT/modules" ;
#   print MODULES "\n$module $module/\n"      or  die "$!: CVSROOT/modules" ;
#   close MODULES                             or  die "$!: CVSROOT/modules" ;
#
#   system qw( cvs commit -m foo CVSROOT/modules )
#                                             and die "cvs commit failed" ;
   return $options ;
}

=back

=head1 VSS mgmt functions

=over

=item vss_borken

fails unless $ENV{SSUSER} is defined and the command C<ss whoami> runs and
returns what looks like a username.

May lock up if the ss.exe command prompts for a password.

This is because I can't figure out a reliable way to detect if the "ss" command
runs well without risking a lock up, since it has a habit of prompting for
a password that I can't break it of without initalizing a custom Source Safe
repository.

=cut

sub vss_borken {
   return "SSUSER not in the environment" unless defined $ENV{SSUSER};

   my $user = `ss Whoami` ;
   return "ss command not found" if empty $user;
   return "ss command did not return just a username"
       unless $user =~ /\A\S+$/m;

   return "" ;
}

=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=cut



1 ;


