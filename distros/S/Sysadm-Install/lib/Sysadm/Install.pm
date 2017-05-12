###############################################
package Sysadm::Install;
###############################################

use 5.006;
use strict;
use warnings;

our $VERSION = '0.48';

use File::Copy;
use File::Path;
use File::Which;
use Log::Log4perl qw(:easy);
use Log::Log4perl::Util;
use File::Basename;
use File::Spec::Functions qw(rel2abs abs2rel);
use Cwd;
use File::Temp qw(tempfile);

our $DRY_RUN;
our $CONFIRM;
our $DRY_RUN_MSG;
our $DATA_SNIPPED_LEN = 60;

dry_run(0);
confirm(0);

###############################################
sub dry_run {
###############################################
    my($on) = @_;

    if($on) {
        $DRY_RUN     = 1;
        $DRY_RUN_MSG = "(skipped - dry run)";
    } else {
        $DRY_RUN     = 0;
        $DRY_RUN_MSG = "";
    }
}

###############################################
sub confirm {
###############################################
    my($on) = @_;

    $CONFIRM = $on;
}

###########################################
sub _confirm {
###########################################
    my($msg) = @_;

    if($DRY_RUN) {
        INFO "$msg $DRY_RUN_MSG";
        return 0 if $DRY_RUN;
    }

    if($CONFIRM) {
        my $answer = ask("$msg ([y]/n)", "y");
        if($answer =~ /^\s*y\s*$/) {
            INFO $msg;
            return 1;
        }

        INFO "$msg (*CANCELLED* as requested)";
        return 0;
    }

    return 1;
}

our @EXPORTABLE = qw(
cp rmf mkd cd make 
cdback download untar 
pie slurp blurt mv tap 
plough qquote quote perm_cp owner_cp
perm_get perm_set
sysrun untar_in pick ask
hammer say
sudo_me bin_find
fs_read_open fs_write_open pipe_copy
snip password_read nice_time
def_or blurt_atomic
is_utf8_data utf8_available
printable home_dir
);

our %EXPORTABLE = map { $_ => 1 } @EXPORTABLE;

our @DIR_STACK;

##################################################
sub import {
##################################################
    my($class) = shift;

    no strict qw(refs);

    my $caller_pkg = caller();

    my(%tags) = map { $_ => 1 } @_;

        # Export all
    if(exists $tags{':all'}) {
        %tags = map { $_ => 1 } @EXPORTABLE;
    }

    for my $func (keys %tags) {
        LOGDIE __PACKAGE__ . 
            "doesn't export \"$func\"" unless exists $EXPORTABLE{$func};
        *{"$caller_pkg\::$func"} = *{$func};
    }
}

=pod

=head1 NAME

Sysadm::Install - Typical installation tasks for system administrators

=head1 SYNOPSIS

  use Sysadm::Install qw(:all);

  my $INST_DIR = '/home/me/install/';

  cd($INST_DIR);
  cp("/deliver/someproj.tgz", ".");
  untar("someproj.tgz");
  cd("someproj");

     # Write out ...
  blurt("Builder: Mike\nDate: Today\n", "build.dat");

     # Slurp back in ...
  my $data = slurp("build.dat");

     # or edit in place ...
  pie(sub { s/Today/scalar localtime()/ge; $_; }, "build.dat");

  make("test install");

     # run a cmd and tap into stdout and stderr
  my($stdout, $stderr, $exit_code) = tap("ls", "-R");

=head1 DESCRIPTION

Have you ever wished for your installation shell scripts to run
reproducibly, without much programming fuzz, and even with optional
logging enabled? Then give up shell programming, use Perl.

C<Sysadm::Install> executes shell-like commands performing typical
installation tasks: Copying files, extracting tarballs, calling C<make>.
It has a C<fail once and die> policy, meticulously checking the result
of every operation and calling C<die()> immediately if anything fails.

C<Sysadm::Install> also supports a I<dry_run> mode, in which it 
logs everything, but suppresses any write actions. Dry run mode
is enabled by calling C<Sysadm::Install::dry_run(1)>. To switch
back to normal, call C<Sysadm::Install::dry_run(0)>.

As of version 0.17, C<Sysadm::Install> supports a I<confirm> mode,
in which it interactively asks the user before running any of its
functions (just like C<rm -i>). I<confirm> mode is enabled by calling 
C<Sysadm::Install::confirm(1)>. To switch
back to normal, call C<Sysadm::Install::confirm(0)>.

C<Sysadm::Install> is fully Log4perl-enabled. To start logging, just
initialize C<Log::Log4perl>. C<Sysadm::Install> acts as a wrapper class,
meaning that file names and line numbers are reported from the calling
program's point of view.

=head2 FUNCTIONS

=over 4

=item C<cp($source, $target)>

Copy a file from C<$source> to C<$target>. C<target> can be a directory.
Note that C<cp> doesn't copy file permissions. If you want the target
file to reflect the source file's user rights, use C<perm_cp()>
shown below.

=cut

###############################################
sub cp {
###############################################

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm("cp $_[0] $_[1]") or return 1;

    INFO "cp $_[0] $_[1]";

    File::Copy::copy @_ or 
        LOGCROAK("Cannot copy $_[0] to $_[1] ($!)");
}

=pod

=item C<mv($source, $target)>

Move a file from C<$source> to C<$target>. C<target> can be a directory.

=cut

###############################################
sub mv {
###############################################

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm("mv $_[0] $_[1]") or return 1;

    INFO "mv $_[0] $_[1]";

    File::Copy::move @_ or 
        LOGCROAK("Cannot move $_[0] to $_[1] ($!)");
}

=pod

=item C<download($url)>

Download a file specified by C<$url> and store it under the
name returned by C<basename($url)>.

=cut

###############################################
sub download {
###############################################
    my($url) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    INFO "download $url";

    _confirm("Downloading $url => ", basename($url)) or return 1;

    require LWP::UserAgent;
    require HTTP::Request;
    require HTTP::Status;

    my $ua = LWP::UserAgent->new();
    my $request = HTTP::Request->new(GET => $url);
    my $response = $ua->request($request, basename($_[0]));
    my $rc = $response->code();
    
    if($rc != HTTP::Status::RC_OK()) {
        LOGCROAK("Cannot download $_[0] (", 
                  $response->message(),
                 ")");
    }

    return 1;
}

=pod

=item C<untar($tarball)>

Untar the tarball in C<$tarball>, which typically adheres to the
C<someproject-X.XX.tgz> convention. 
But regardless of whether the 
archive actually contains a top directory C<someproject-X.XX>,
this function will behave if it had one. If it doesn't have one,
a new directory is created before the unpacking takes place. Unpacks
the tarball into the current directory, no matter where the tarfile
is located. 
Please note that if you're
using a compressed tarball (.tar.gz or .tgz), you'll need
IO::Zlib installed. 

=cut

###############################################
sub untar {
###############################################

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    LOGCROAK("untar called without defined tarfile") unless 
         @_ == 1 and defined $_[0];

    _confirm "untar $_[0]" or return 1;

    my($nice, $topdir, $namedir) = archive_sniff($_[0]);

    check_zlib($_[0]);
    require Archive::Tar;
    my $arch = Archive::Tar->new($_[0]);

    my @extracted = ();

    if($nice and $topdir eq $namedir) {
        DEBUG "Nice archive, extracting to subdir $topdir";
        @extracted = $arch->extract();
    } elsif($nice) {
        DEBUG "Not-so-nice archive topdir=$topdir namedir=$namedir";
            # extract as topdir
        @extracted = $arch->extract();
        rename $topdir, $namedir or 
            LOGCROAK("Can't rename $topdir, $namedir");
    } else {
        LOGCROAK("no topdir") unless defined $topdir;
        DEBUG "Not-so-nice archive (no topdir), extracting to subdir $topdir";
        $topdir = basename $topdir;
        mkd($topdir);
        cd($topdir);
        @extracted = $arch->extract();
        cdback();
    }

    if( !@extracted ) {
        LOGCROAK "Archive $_[0] was empty.";
    }

    return $topdir;
}

=pod

=item C<untar_in($tar_file, $dir)>

Untar the tarball in C<$tgz_file> in directory C<$dir>. Create
C<$dir> if it doesn't exist yet.

=cut

###############################################
sub untar_in {
###############################################
    my($tar_file, $dir) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    LOGCROAK("not enough arguments") if
      ! defined $tar_file or ! defined $dir;

    _confirm "Untarring $tar_file in $dir" or return 1;

    mkd($dir) unless -d $dir;

    my $tar_file_abs = rel2abs($tar_file);

    cd($dir);

    check_zlib($tar_file_abs);
    require Archive::Tar;
    my $arch = Archive::Tar->new("$tar_file_abs");
    $arch->extract() or 
        LOGCROAK("Extract failed: ($!)");
    cdback();
}

=pod

=item C<pick($prompt, $options, $default, $opts)>

Ask the user to pick an item from a displayed list. C<$prompt>
is the text displayed, C<$options> is a referenc to an array of
choices, and C<$default> is the number (starting from 1, not 0)
of the default item. For example,

    pick("Pick a fruit", ["apple", "pear", "pineapple"], 3);

will display the following:

    [1] apple
    [2] pear
    [3] pineapple
    Pick a fruit [3]>

If the user just hits I<Enter>, "pineapple" (the default value) will
be returned. Note that 3 marks the 3rd element of the list, and is
I<not> an index value into the array.

If the user enters C<1>, C<2> or C<3>, the corresponding text string
(C<"apple">, C<"pear">, C<"pineapple"> will be returned by
C<pick()>.

If the optional C<$opts> hash has C<{ tty =E<gt> 1 }> set, then 
the user response will be expected from the console, not STDIN.

=cut

##################################################
sub pick {
##################################################
    my ($prompt, $options, $default, $opts) = @_;    

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    my $default_int;
    my %files;

    if(@_ < 3 or ref($options) ne "ARRAY") {
        LOGCROAK("pick called with wrong #/type of args");
    }
    
    {
        my $count = 0;

        my $user_prompt = "";

        foreach (@$options) {
            $user_prompt .= "[" . ++$count . "] $_\n";
            $default_int = $count if $count eq $default;
            $files{$count} = $_;
        }
    
        $user_prompt .= "$prompt [$default_int]> ";
        my $input = user_input($user_prompt, $opts);

        $input = $default_int if !defined $input or !length($input);

        redo if $input !~ /^\d+$/ or 
                $input == 0 or 
                $input > scalar @$options;
        return "$files{$input}";
    }
}

=pod

=item C<ask($prompt, $default, $opts)>

Ask the user to either hit I<Enter> and select the displayed default
or to type in another string.

If the optional C<$opts> hash has C<{ tty =E<gt> 1 }> set, then 
the user response will be expected from the console, not STDIN.

=cut

##################################################
sub ask {
##################################################
    my ($prompt, $default, $opts) = @_;    

    $opts = {} if !defined $opts;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    if(@_ < 2) {
        LOGCROAK("ask() called with wrong # of args");
    }

    my $value = user_input("$prompt [$default]> ", $opts);
    $value = $default if $value eq "";

    return $value;
}

##################################################
sub user_prompt {
##################################################
    my ($prompt, $opts) = @_;    

    $opts = {} if !defined $opts;

    my $fh     = *STDERR;
    my $old_stderr;
    if( $opts->{ tty } ) {
        open $old_stderr, ">&", \*STDERR or
            die "Can't dup STDERR: $!";
        open $fh, ">>", '/dev/tty' or 
            die "Cannot open /dev/tty ($!)";
    }

    print $fh $prompt
        or die "Couldn't write to $fh: ($!)";

    if( $opts->{ tty } ) {
        close $fh;
        open STDERR, ">&", $old_stderr or 
            die "Can't reset STDERR";
    }

    return 1;
}

##################################################
sub user_input {
##################################################
    my ($prompt, $opts) = @_;    

    $opts = {} if !defined $opts;

    user_prompt( $prompt );

    my $fh = *STDIN;

    if( $opts->{ tty } ) {
        open $fh, "<", '/dev/tty' or 
            die "Cannot open /dev/tty ($!)";
    }

    my $input = <$fh>;
    chomp $input if defined $input;

    return $input;
}

=pod

=item C<mkd($dir)>

Create a directory of arbitrary depth, just like C<File::Path::mkpath>.

=cut

###############################################
sub mkd {
###############################################

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "mkd @_" or return 1;

    INFO "mkpath @_";

    mkpath @_ or 
        LOGCROAK("Cannot mkdir @_ ($!)");
}

=pod

=item C<rmf($dir)>

Delete a directory and all of its descendents, just like C<rm -rf>
in the shell.

=cut

###############################################
sub rmf {
###############################################

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "rmf $_[0]" or return 1;

    if(!-e $_[0]) {
        DEBUG "$_[0] doesn't exist - ignored";
        return;
    }

    INFO "rmtree @_";

    rmtree $_[0] or 
        LOGCROAK("Cannot rmtree $_[0] ($!)");
}

=pod

=item C<cd($dir)>

chdir to the given directory. If you don't want to have cd() modify
the internal directory stack (used for subsequent cdback() calls), 
set the stack_update parameter to a false value:

    cd($dir, {stack_update => 0});

=cut

###############################################
sub cd {
###############################################

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    INFO "cd $_[0]";

    my $opts = { stack_update => 1 };
    $opts = $_[1] if ref $_[1] eq "HASH";

    if ($opts->{stack_update}) {
        my $cwd = getcwd();
        if(! defined $cwd) {
            LOGCROAK("Cannot getcwd ($!)");        ;
        }
        push @DIR_STACK, $cwd;
    }

    chdir($_[0]) or 
        LOGCROAK("Cannot cd $_[0] ($!)");
}

=pod

=item C<cdback()>

chdir back to the last directory before a previous C<cd>. If the
option C<reset> is set, it goes all the way back to the beginning of the
directory stack, i.e. no matter how many cd() calls were made in between,
it'll go back to the original directory:

      # go all the way back
    cdback( { reset => 1 } );

=cut

###############################################
sub cdback {
###############################################
    my( $opts ) = @_;

    $opts = {} if !defined $opts;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    LOGCROAK("cd stack empty") unless @DIR_STACK;

    if( $opts->{ reset } ) {
        @DIR_STACK = ( $DIR_STACK[0] );
    }

    my $old_dir = pop @DIR_STACK;

    LOGCROAK("Directory stack empty")
        if ! defined $old_dir;

    INFO "cdback to $old_dir";
    cd($old_dir, {stack_update => 0});
}

=pod

=item C<make()>

Call C<make> in the shell.

=cut

###############################################
sub make {
###############################################

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "make @_" or return 1;

    INFO "make @_";

    system("make @_") and 
        LOGCROAK("Cannot make @_ ($!)");
}

=pod

=cut

###############################################
sub check_zlib {
###############################################
    my($tar_file) = @_;

    if($tar_file =~ /\.tar\.gz\b|\.tgz\b/ and
       !Log::Log4perl::Util::module_available("IO::Zlib")) {

        LOGCROAK("$tar_file: Compressed tarballs can ",
               "only be processed with IO::Zlib installed.");
    }
}
     
#######################################
sub archive_sniff {
#######################################
    my($name) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    DEBUG "Sniffing archive '$name'";

    my ($dir) = ($name =~ /(.*?)\.(tar\.gz|tgz|tar)$/);
 
    return 0 unless defined $dir;

    $dir = basename($dir);
    DEBUG "dir=$dir";

    my $topdir;

    check_zlib($name);

    require Archive::Tar;
    my $tar = Archive::Tar->new($name);

    my @names = $tar->list_files(["name"]);
    
    LOGCROAK("Archive $name is empty") unless @names;

    (my $archdir = $names[0]) =~ s#/.*##;

    DEBUG "archdir=$archdir";

    for my $name (@names) {
        next if $name eq "./";
        $name =~ s#^\./##;
        ($topdir = $name) =~ s#/.*##;
        if($topdir ne $archdir) {
            return (0, $dir, $dir);
        }
    }

    DEBUG "Return $topdir $dir";

    return (1, $topdir, $dir);
}

=pod

=item C<pie($coderef, $filename, ...)>

Simulate "perl -pie 'do something' file". Edits files in-place. Expects
a reference to a subroutine as its first argument. It will read out the
file C<$filename> line by line and calls the subroutine setting
a localized C<$_> to the current line. The return value of the subroutine
will replace the previous value of the line.

Example:

    # Replace all 'foo's by 'bar' in test.dat
        pie(sub { s/foo/bar/g; $_; }, "test.dat");

Works with one or more file names.

If the files are known to contain UTF-8 encoded data, and you want it
to be read/written as a Unicode strings, use the C<utf8> option:

    pie(sub { s/foo/bar/g; $_; }, "test.dat", { utf8 => 1 });

=cut

###############################################
sub pie {
###############################################
    my($coderef, @files) = @_;

    my $options = {};

    if(defined $files[-1] and
       ref $files[-1] eq "HASH") {
       $options = pop @files;
    }

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    for my $file (@files) {

        _confirm "editing $file in-place" or next;

        my $out = "";

        open FILE, "<$file" or 
            LOGCROAK("Cannot open $file ($!)");

        if( $options->{utf8} ) {
            binmode FILE, ":utf8";
        }

        while(<FILE>) {
            $out .= $coderef->($_);
        }
        close FILE;

        blurt($out, $file, $options);
    }
}

=pod

=item C<plough($coderef, $filename, ...)>

Simulate "perl -ne 'do something' file". Iterates over all lines
of all input files and calls the subroutine provided as the first argument. 

Example:

    # Print all lines containing 'foobar'
        plough(sub { print if /foobar/ }, "test.dat");

Works with one or more file names.

If the files are known to contain UTF-8 encoded data, and you want it
to be read into Unicode strings, use the C<utf8> option:

    plough(sub { print if /foobar/ }, "test.dat", { utf8 => 1 });

=cut

###############################################
sub plough {
###############################################
    my($coderef, @files) = @_;

    my $options = {};

    if(defined $files[-1] and
        ref $files[-1] eq "HASH") {
        $options = pop @files;
    }

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    for my $file (@files) {

        _confirm "Ploughing through $file" or next;

        my $out = "";

        open FILE, "<$file" or 
            LOGCROAK("Cannot open $file ($!)");

        if( $options->{utf8} ) {
            binmode FILE, ":utf8";
        }

        while(<FILE>) {
            $coderef->($_);
        }
        close FILE;
    }
}

=pod

=item C<my $data = slurp($file, $options)>

Slurps in the file and returns a scalar with the file's content. If
called without argument, data is slurped from STDIN or from any files
provided on the command line (like E<lt>E<gt> operates).

If the file is known to contain UTF-8 encoded data and you want to
read it in as a Unicode string, use the C<utf8> option:

    my $unicode_string = slurp( $file, {utf8 => 1} );

=cut

###############################################
sub slurp {
###############################################
    my($file, $options) = @_;

    $options = {} unless defined $options;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    my $from_file = defined($file);

    local $/ = undef;

    my $data;

    if($from_file) {
        INFO "Slurping data from $file";
        open FILE, "<$file" or 
            LOGCROAK("Cannot open $file ($!)");
        binmode FILE; # Win32 wants that
        if( exists $options->{utf8} ) {
            binmode FILE, ":utf8";
        }
        $data = <FILE>;
        close FILE;
        DEBUG "Read ", snip($data, $DATA_SNIPPED_LEN), " from $file";
    } else {
        INFO "Slurping data from <>";
        $data = <>;
        DEBUG "Read ", snip($data, $DATA_SNIPPED_LEN), " from <>";
    }

    return $data;
}

=pod

=item C<blurt($data, $file, $options)>

Opens a new file, prints the data in C<$data> to it and closes the file.  If
C<$options-E<gt>{append}> is set to a true value, data will be appended to the
file. Default is false, existing files will be overwritten.

If the string is a Unicode string, use the C<utf8> option:

    blurt( $unicode_string, $file, {utf8 => 1} );

=cut

###############################################
sub blurt {
###############################################
    my($data, $file, $options) = @_;

      # legacy signature
    if(defined $options and ref $options eq "") {
        $options = { append => 1 };
    }

    $options = {} unless defined $options;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    $options->{append} = 0 unless defined $options->{append};

    _confirm(($options->{append} ? "Appending" : "Writing") . " " .
         length($data) . " bytes to $file") or return 1;

    open FILE, ">" . ($options->{append} ? ">" : "") . $file 
        or 
        LOGCROAK("Cannot open $file for writing ($!)");

    binmode FILE; # Win32 wants that

    if( $options->{utf8} ) {
        binmode FILE, ":utf8";
    }

    print FILE $data
        or 
        LOGCROAK("Cannot write to $file ($!)");        
    close FILE
        or 
        LOGCROAK("Cannot close $file ($!)");        

    DEBUG "Wrote ", snip($data, $DATA_SNIPPED_LEN), " to $file";
}

=pod

=item C<blurt_atomic($data, $file, $options)>

Write the data in $data to a file $file, guaranteeing that the operation
will either complete fully or not at all. This is accomplished by first
writing to a temporary file which is then rename()ed to the target file.

Unlike in C<blurt>, there is no C<$append> mode in C<blurt_atomic>.

If the string is a Unicode string, use the C<utf8> option:

    blurt_atomic( $unicode_string, $file, {utf8 => 1} );

=cut

###############################################
sub blurt_atomic {
###############################################
    my($data, $file, $options) = @_;

    _confirm("Writing atomically " .
         length($data) . " bytes to $file") or return 1;

    $options = {} unless defined $options;

    my($fh, $tmpname) = tempfile(DIR => dirname($file));

    blurt($data, $tmpname, $options);

    close $fh;

    rename $tmpname, $file or
        LOGDIE "Can't rename $tmpname to $file";

    DEBUG "Wrote ", snip($data, $DATA_SNIPPED_LEN), " atomically to $file";
}

=pod

=item C<($stdout, $stderr, $exit_code) = tap($cmd, @args)>

Run a command $cmd in the shell, and pass it @args as args.
Capture STDOUT and STDERR, and return them as strings. If
C<$exit_code> is 0, the command succeeded. If it is different,
the command failed and $exit_code holds its exit code.

Please note that C<tap()> is limited to single shell
commands, it won't work with output redirectors (C<ls E<gt>/tmp/foo>
2E<gt>&1).

In default mode, C<tap()> will concatenate the command and args
given and create a shell command line by redirecting STDERR to a temporary
file. C<tap("ls", "/tmp")>, for example, will result in

    'ls' '/tmp' 2>/tmp/sometempfile |

Note that all commands are protected by single quotes to make sure
arguments containing spaces are processed as singles, and no globbing
happens on wildcards. Arguments containing single quotes or backslashes
are escaped properly.

If quoting is undesirable, C<tap()> accepts an option hash as
its first parameter, 

    tap({no_quotes => 1}, "ls", "/tmp/*");

which will suppress any quoting:

    ls /tmp/* 2>/tmp/sometempfile |

Or, if you prefer double quotes, use

    tap({double_quotes => 1}, "ls", "/tmp/$VAR");

wrapping all args so that shell variables are interpolated properly:

    "ls" "/tmp/$VAR" 2>/tmp/sometempfile |

Another option is "utf8" which runs the command in a terminal set to 
UTF8.

Error handling: By default, tap() won't raise an error if the command's
return code is nonzero, indicating an error reported by the shell. If 
bailing out on errors is requested to avoid return code checking by
the script, use the raise_error option:

    tap({raise_error => 1}, "ls", "doesn't exist");

In DEBUG mode, C<tap> logs the entire stdout/stderr output, which
can get too verbose at times. To limit the number of bytes logged, use
the C<stdout_limit> and C<stderr_limit> options

    tap({stdout_limit => 10}, "echo", "123456789101112");

=cut

###############################################
sub tap {
###############################################
    my(@args) = @_;

    my $options = {};

    if(defined $args[-1] and
       ref $args[-1] eq "HASH") {
       $options = pop @args;
    }

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "tapping @args" or return 1;

    my $opts = {};

    $opts = shift @args if ref $args[0] eq "HASH";

    my $tmpfh   = File::Temp->new(UNLINK => 1, SUFFIX => '.dat');
    my $tmpfile = $tmpfh->filename();

    DEBUG "tempfile $tmpfile created";

    my $cmd;

    if($opts->{no_quotes}) {
        $cmd = join ' ', @args;
    } elsif($opts->{double_quotes}) {
        $cmd = join ' ', map { qquote($_, ":shell") } @args;
    } else {
            # Default mode: Single quotes
        $cmd = join ' ', map { quote($_, ":shell") } @args;
    }
       
    $cmd = "$cmd 2>$tmpfile |";
    INFO "tapping $cmd";

    open PIPE, $cmd or 
        LOGCROAK("open $cmd | failed ($!)");
        
    if( $options->{utf8} ) {
        binmode PIPE, ":utf8";
    }

    my $stdout = join '', <PIPE>;
    close PIPE;

    my $exit_code = $?;

    my $stderr = slurp($tmpfile, $options);

    if( $opts->{ stderr_limit } ) {
        $stderr = snip( $stderr, $opts->{ stderr_limit } );
    }

    if($exit_code != 0 and $opts->{raise_error}) {
        LOGCROAK("tap $cmd | failed ($stderr)");
    }

    if( $opts->{ stdout_limit } ) {
        $stdout = snip( $stdout, $opts->{ stdout_limit } );
    }

    DEBUG "tap $cmd results: rc=$exit_code stderr=[$stderr] stdout=[$stdout]";

    return ($stdout, $stderr, $exit_code);
}

=pod

=item C<$quoted_string = qquote($string, [$metachars])>

Put a string in double quotes and escape all sensitive characters so
there's no unwanted interpolation. 
E.g., if you have something like

   print "foo!\n";

and want to put it into a double-quoted string, it will look like

    "print \"foo!\\n\""

Sometimes, not only backslashes and double quotes need to be escaped,
but also the target environment's meta chars. A string containing

    print "$<\n";

needs to have the '$' escaped like

    "print \"\$<\\n\";"

if you want to reuse it later in a shell context:

    $ perl -le "print \"\$<\\n\";"
    1212

C<qquote()> supports escaping these extra characters with its second,
optional argument, consisting of a string listing  all escapable characters:

    my $script  = 'print "$< rocks!\\n";';
    my $escaped = qquote($script, '!$'); # Escape for shell use
    system("perl -e $escaped");

    => 1212 rocks!

And there's a shortcut for shells: By specifying ':shell' as the
metacharacters string, qquote() will actually use '!$`'.

For example, if you wanted to run the perl code

    print "foobar\n";

via

    perl -e ...

on a box via ssh, you would use

    use Sysadm::Install qw(qquote);

    my $cmd = 'print "foobar!\n"';
       $cmd = "perl -e " . qquote($cmd, ':shell');
       $cmd = "ssh somehost " . qquote($cmd, ':shell');

    print "$cmd\n";
    system($cmd);

and get

    ssh somehost "perl -e \"print \\\"foobar\\\!\\\\n\\\"\""

which runs on C<somehost> without hickup and prints C<foobar!>.

Sysadm::Install comes with a script C<one-liner> (installed in bin),
which takes arbitrary perl code on STDIN and transforms it into
a one-liner:

    $ one-liner
    Type perl code, terminate by CTRL-D
    print "hello\n";
    print "world\n";
    ^D
    perl -e "print \"hello\\n\"; print \"world\\n\"; "

=cut

###############################################
sub qquote {
###############################################
    my($str, $metas) = @_;

    $str =~ s/([\\"])/\\$1/g;

    if(defined $metas) {
        $metas = '!$`' if $metas eq ":shell";
        $metas =~ s/\]/\\]/g;
        $str =~ s/([$metas])/\\$1/g;
    }

    return "\"$str\"";
}

=pod

=item C<$quoted_string = quote($string, [$metachars])>

Similar to C<qquote()>, just puts a string in single quotes and
escapes what needs to be escaped.

Note that shells typically don't support escaped single quotes within
single quotes, which means that

    $ echo 'foo\'bar'
    >

is invalid and the shell waits until it finds a closing quote. 
Instead, there is an evil trick which gives the desired result:

    $ echo 'foo'\''bar'  # foo, single quote, \, 2 x single quote, bar
    foo'bar

It uses the fact that shells interpret back-to-back strings as one.
The construct above consists of three back-to-back strings: 

    (1) 'foo'
    (2) '
    (3) 'bar'

which all get concatenated to a single 

    foo'bar

If you call C<quote()> with C<$metachars> set to ":shell", it will
perform that magic behind the scenes:

    print quote("foo'bar");
      # prints: 'foo'\''bar'

=cut

###############################################
sub quote {
###############################################
    my($str, $metas) = @_;

    if(defined $metas and $metas eq ":shell") {
        $str =~ s/([\\])/\\$1/g;
        $str =~ s/(['])/'\\''/g;
    } else {
        $str =~ s/([\\'])/\\$1/g;
    }

    if(defined $metas and $metas ne ":shell") {
        $metas =~ s/\]/\\]/g;
        $str =~ s/([$metas])/\\$1/g;
    }

    return "\'$str\'";
}

=pod

=item C<perm_cp($src, $dst, ...)>

Read the C<$src> file's user permissions and modify all
C<$dst> files to reflect the same permissions.

=cut

######################################
sub perm_cp {
######################################
    # Lifted from Ben Okopnik's
    # http://www.linuxgazette.com/issue87/misc/tips/cpmod.pl.txt

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "perm_cp @_" or return 1;

    LOGCROAK("usage: perm_cp src dst ...") if @_ < 2;

    my $perms = perm_get($_[0]);
    perm_set($_[1], $perms);
}

=pod

=item C<owner_cp($src, $dst, ...)>

Read the C<$src> file/directory's owner uid and group gid and apply
it to $dst.

For example: copy uid/gid of the containing directory to a file
therein:

    use File::Basename;

    owner_cp( dirname($file), $file );

Usually requires root privileges, just like chown does.

=cut

######################################
sub owner_cp {
######################################
    my($src, @dst) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "owner_cp @_" or return 1;

    LOGCROAK("usage: owner_cp src dst ...") if @_ < 2;

    my($uid, $gid) = (stat($src))[4,5];

    if(!defined $uid or !defined $gid ) {
        LOGCROAK("stat of $src failed: $!");
        return undef;
    }

    if(!chown $uid, $gid, @dst ) {
        LOGCROAK("chown of ", join(" ", @dst), " failed: $!");
        return undef;
    }

    return 1;
}

=pod

=item C<$perms = perm_get($filename)>

Read the C<$filename>'s user permissions and owner/group. 
Returns an array ref to be
used later when calling C<perm_set($filename, $perms)>.

=cut 

######################################
sub perm_get {
######################################
    my($filename) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    my @stats = (stat $filename)[2,4,5] or
        
        LOGCROAK("Cannot stat $filename ($!)");

    INFO "perm_get $filename (@stats)";

    return \@stats;
}

=pod

=item C<perm_set($filename, $perms)>

Set file permissions and owner of C<$filename>
according to C<$perms>, which was previously
acquired by calling C<perm_get($filename)>.

=cut 

######################################
sub perm_set {
######################################
    my($filename, $perms) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "perm_set $filename (@$perms)" or return 1;

    chown($perms->[1], $perms->[2], $filename) or 
        
        LOGCROAK("Cannot chown $filename ($!)");
    chmod($perms->[0] & 07777,    $filename) or
        
        LOGCROAK("Cannot chmod $filename ($!)");
}

=pod

=item C<sysrun($cmd)>

Run a shell command via C<system()> and die() if it fails. Also 
works with a list of arguments, which are then interpreted as program
name plus arguments, just like C<system()> does it.

=cut

######################################
sub sysrun {
######################################
    my(@cmds) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "sysrun: @cmds" or return 1;

    LOGCROAK("usage: sysrun cmd ...") if @_ < 1;

    system(@cmds) and 
        LOGCROAK("@cmds failed ($!)");
}

=pod

=item C<hammer($cmd, $arg, ...)>

Run a command in the shell and simulate a user hammering the
ENTER key to accept defaults on prompts.

=cut

######################################
sub hammer {
######################################
    my(@cmds) = @_;

    require Expect;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

        _confirm "Hammer: @cmds" or return 1;

    my $exp = Expect->new();
    $exp->raw_pty(0);

    INFO "spawning: @cmds";
    $exp->spawn(@cmds);

    $exp->send_slow(0.1, "\n") for 1..199;
    $exp->expect(undef);
}

=pod

=item C<say($text, ...)>

Alias for C<print ..., "\n">, just like Perl6 is going to provide it.

=cut

######################################
sub say {
######################################
    print @_, "\n";
}

=pod

=item C<sudo_me()>

Check if the current script is running as root. If yes, continue. If not,
restart the current script with all command line arguments is restarted
under sudo:

    sudo scriptname args ...

Make sure to call this before any C<@ARGV>-modifying functions like
C<getopts()> have kicked in.

=cut

######################################
sub sudo_me {
######################################
    my($argv) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    _confirm "sudo_me" or return 1;

    $argv = \@ARGV unless $argv;

       # If we're not running as root, 
       # re-invoke the script via sudo
    if($> != 0) {
        DEBUG "Not running as root, calling sudo $0 @$argv";
        my $sudo = bin_find("sudo");
        LOGCROAK("Can't find sudo in PATH") unless $sudo;
        exec($sudo, $0, @$argv) or 
            LOGCROAK("exec failed!");
    }
}

=pod

=item C<bin_find($program)>

Search all directories in $PATH (the ENV variable) for an executable
named $program and return the full path of the first hit. Returns
C<undef> if the program can't be found.

=cut

######################################
sub bin_find {
######################################
    my($exe) = @_;

      # File::Which returns a list in list context, we just want the first
      # match.
    return scalar File::Which::which( $exe );
}

=pod

=item C<fs_read_open($dir)>

Opens a file handle to read the output of the following process:

    cd $dir; find ./ -xdev -print0 | cpio -o0 |

This can be used to capture a file system structure. 

=cut

######################################
sub fs_read_open {
######################################
    my($dir, $options) = @_;

    $options = {} unless defined $options;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    my $find = bin_find("find");
    LOGCROAK("Cannot find 'find'") unless defined $find;

    my $cpio = bin_find("cpio");
    LOGCROAK("Cannot find 'cpio'") unless defined $cpio;

    cd $dir;
 
    my $cmd = "$find . -xdev -print0 | $cpio -o0 --quiet 2>/dev/null ";

    DEBUG "Reading from $cmd";
    open my $in, "$cmd |" or 
        LOGCROAK("Cannot open $cmd");

    binmode $in, ":utf8" if $options->{utf8};

    cdback;

    return $in;
}

=pod

=item C<fs_write_open($dir)>

Opens a file handle to write to a 

    | (cd $dir; cpio -i0)

process to restore a file system structure. To be used in conjunction
with I<fs_read_open>.

=cut

######################################
sub fs_write_open {
######################################
    my($dir, $options) = @_;

    $options = {} unless defined $options;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    my $cpio = bin_find("cpio");
    LOGCROAK("Cannot find 'cpio'") unless defined $cpio;

    mkd $dir unless -d $dir;

    cd $dir;

    my $cmd = "$cpio -i0 --quiet";

    DEBUG "Writing to $cmd in dir $dir";
    open my $out, "| $cmd" or 
        LOGCROAK("Cannot open $cmd");

    binmode $out, ":utf8" if $options->{utf8};

    cdback;

    return $out;
}

=pod

=item C<pipe_copy($in, $out, [$bufsize])>

Reads from $in and writes to $out, using sysread and syswrite. The
buffer size used defaults to 4096, but can be set explicitly.

=cut

######################################
sub pipe_copy {
######################################
    my($in, $out, $bufsize) = @_;

    local $Log::Log4perl::caller_depth =
          $Log::Log4perl::caller_depth + 1;

    $bufsize ||= 4096;
    my $bytes = 0;

    INFO "Opening pipe (bufsize=$bufsize)";
    my $ret;
    while($ret = sysread($in, my $buf, $bufsize)) {
        $bytes += length $buf;
        if (!defined syswrite $out, $buf) {
            LOGCROAK("Write to pipe failed: ($!)");
        }
    }
    if (!defined $ret) {
        LOGCROAK("Read from pipe failed: ($!)");
    }
    INFO "Closed pipe (bufsize=$bufsize, transferred=$bytes)";
}

=pod

=item C<snip($data, $maxlen)>

Format the data string in C<$data> so that it's only (roughly) $maxlen
characters long and only contains printable characters.

If C<$data> is longer than C<$maxlen>, it will be
formatted like

    (22)[abcdef[snip=11]stuvw]

indicating the length of the original string, the beginning, the
end, and the number of 'snipped' characters.

If C<$data> is shorter than $maxlen, it will be returned unmodified 
(except for unprintable characters replaced, see below).

If C<$data> contains unprintable character's they are replaced by 
"." (the dot).

=cut

###########################################
sub snip {
###########################################
    my($data, $maxlen) = @_;

    if(length $data <= $maxlen) {
        return printable($data);
    }

    $maxlen = 12 if $maxlen < 12;
    my $sniplen = int(($maxlen - 8) / 2);

    my $start   = substr($data,  0, $sniplen);
    my $end     = substr($data, -$sniplen);
    my $snipped = length($data) - 2*$sniplen;

    return lenformat("$start\[snip=$snipped]$end", length $data);
}
    
###########################################
sub lenformat {
###########################################
    my($data, $orglen) = @_;

    return "(" . ($orglen || length($data)) . ")[" .
        printable($data) . "]";
}

###########################################
sub printable {
###########################################
    my($data) = @_;

    $data =~ s/[^ \w.;!?@#$%^&*()+\\|~`',><[\]{}="-]/./g;
    return $data;
}

=pod

=item C<password_read($prompt, $opts)>

Reads in a password to be typed in by the user in noecho mode.
A call to password_read("password: ") results in

    password: ***** (stars aren't actually displayed)

This function will switch the terminal back into normal mode
after the user hits the 'Return' key.

If the optional C<$opts> hash has C<{ tty =E<gt> 1 }> set, then 
the prompt will be redirected to the console instead of STDOUT.

=cut

###########################################
sub password_read {
###########################################
    my($prompt, $opts) = @_;

    use Term::ReadKey;
    ReadMode 'noecho';
    $| = 1;
    user_prompt($prompt, $opts);
    my $pw = ReadLine 0;
    chomp $pw;
    ReadMode 'restore';
    user_prompt("\n", $opts);

    return $pw;
}

=pod

=item C<nice_time($time)>

Format the time in a human-readable way, less wasteful than the 
'scalar localtime' formatting. 

    print nice_time(), "\n";
      # 2007/04/01 10:51:24

It uses the system time by default, but it can also accept epoch seconds:

    print nice_time(1170000000), "\n";
      # 2007/01/28 08:00:00

It uses localtime() under the hood, so the outcome of the above will
depend on your local time zone setting.

=cut

###########################################
sub nice_time {
###########################################
    my($time) = @_;

    $time = time() unless defined $time;

    my ($sec,$min,$hour,$mday,$mon,$year,
     $wday,$yday,$isdst) = localtime($time);

    return sprintf("%d/%02d/%02d %02d:%02d:%02d",
     $year+1900, $mon+1, $mday,
     $hour, $min, $sec);
}

=item C<def_or($foo, $default)>

Perl-5.9 added the //= construct, which helps assigning values to
undefined variables. Instead of writing

    if(!defined $foo) {
        $foo = $default;
    }

you can just write

    $foo //= $default;

However, this is not available on older perl versions (although there's 
source filter solutions). Often, people use

    $foo ||= $default;

instead which is wrong if $foo contains a value that evaluates as false.
So Sysadm::Install, the everything-and-the-kitchen-sink under the CPAN
modules, provides the function C<def_or()> which can be used like

    def_or($foo, $default); 

to accomplish the same as

    $foo //= $default;

How does it work, how does $foo get a different value, although it's 
apparently passed in by value? Modifying $_[0] within the subroutine
is an old Perl trick to do exactly that.

=cut

###########################################
sub def_or($$) {
###########################################
    if(! defined $_[0]) {
        $_[0] = $_[1];
    }
}

=item C<is_utf8_data($data)>

Check if the given string has the utf8 flag turned on. Works just like 
Encode.pm's is_utf8() function, except that it silently returns a 
false if Encode isn't available, for example when an ancient perl 
without proper utf8 support is used.

=cut

###############################################
sub is_utf8_data {
###############################################
    my($data) = @_;

    if( !utf8_available() ) {
        return 0;
    }

    return Encode::is_utf8( $data );
}

=item C<utf8_check($data)>

Check if we're using a perl with proper utf8 support, by verifying the
Encode.pm module is available for loading.

=cut

###############################################
sub utf8_available {
###############################################

    eval "use Encode";

    if($@) {
        return 0;
    }

    return 1;
}

=item C<home_dir()>

Return the path to the home directory of the current user.

=cut

###############################################
sub home_dir {
###############################################

    my( $home ) = glob "~";

    return $home;
}

=pod

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Mike Schilli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
