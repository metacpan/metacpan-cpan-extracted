# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Util;
use strict;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
    IS_WIN32 DEFAULT_EDITOR TEXT_MODE HAS_SYMLINK HAS_SVN_MIRROR $EOL $SEP

    get_prompt get_buffer_from_editor edit_file

    get_encoding get_encoder from_native to_native

    find_svm_source traverse_history

    read_file write_file slurp_fh md5_fh bsd_glob mimetype mimetype_is_text
    is_binary_file

    abs_path abs2rel catdir catfile catpath devnull dirname get_anchor 
    move_path make_path splitpath splitdir tmpdir tmpfile get_depot_anchor
    catdepot abs_path_noexist 

    is_symlink is_executable is_uri can_run is_path_inside is_depotpath

    uri_escape uri_unescape

    str2time time2str reformat_svn_date

    find_dotsvk
);
use SVK::Version;  our $VERSION = $SVK::VERSION;


use Config ();
use SVK::Logger;
use SVK::I18N;
use SVN::Core;
use autouse 'Encode'            => qw(resolve_alias($) decode encode);
use File::Glob qw(bsd_glob);
use autouse 'File::Basename' 	=> qw(dirname);
use autouse 'File::Spec::Functions' => 
                               qw(catdir catpath splitpath splitdir tmpdir);
use autouse 'List::Util'        => qw( max(@) );


=head1 NAME

SVK::Util - Utility functions for SVK classes

=head1 SYNOPSIS

    use SVK::Util qw( func1 func2 func3 )

=head1 DESCRIPTION

This is yet another abstraction function set for portable file, buffer and
IO handling, tailored to SVK's specific needs.

No symbols are exported by default; the user module needs to specify the
list of functions to import.


=head1 CONSTANTS

=head2 Constant Functions

=head3 IS_WIN32

Boolean flag to indicate whether this system is running Microsoft Windows.

=head3 DEFAULT_EDITOR

The default program to invoke for editing buffers: C<notepad.exe> on Win32,
C<vi> otherwise.

=head3 TEXT_MODE

The I/O layer for text files: C<:crlf> on Win32, empty otherwise.

=head3 HAS_SYMLINK

Boolean flag to indicate whether this system supports C<symlink()>.

=head3 HAS_SVN_MIRROR

Boolean flag to indicate whether we can successfully load L<SVN::Mirror>.

=head2 Constant Scalars

=head3 $SEP

Native path separator: platform: C<\> on dosish platforms, C</> otherwise.

=head3 $EOL

End of line marker: C<\015\012> on Win32, C<\012> otherwise.

=cut

use constant IS_WIN32 => ($^O eq 'MSWin32');
use constant TEXT_MODE => IS_WIN32 ? ':crlf' : '';
use constant DEFAULT_EDITOR => IS_WIN32 ? 'notepad.exe' : 'vi';
use constant HAS_SYMLINK => $Config::Config{d_symlink};

sub HAS_SVN_MIRROR () {
    no warnings 'redefine';
    local $@;
    my $has_svn_mirror = $ENV{SVKNOSVM} ? 0 : eval { require SVN::Mirror; 1 };
    *HAS_SVN_MIRROR = $has_svn_mirror ? sub () { 1 } : sub () { 0 };
    return $has_svn_mirror;
}

our $SEP = catdir('');
our $EOL = IS_WIN32 ? "\015\012" : "\012";

=head1 FUNCTIONS

=head2 User Interactivity

=head3 get_prompt ($prompt, $pattern)

Repeatedly prompt the user for a line of answer, until it matches 
the regular expression pattern.  Returns the chomped answer line.

=cut

sub get_prompt { {
    my ($prompt, $pattern) = @_;

    return '' if ($ENV{'SVKBATCHMODE'});

    local $| = 1;
    print $prompt;

    local *IN;
    local *SAVED = *STDIN;
    local *STDIN = *STDIN;

    my $formfeed = "";
    if (!-t STDIN and -r '/dev/tty' and open IN, '<', '/dev/tty') {
        *STDIN = *IN;
        $formfeed = "\r";
    }

    require Term::ReadKey;
    Term::ReadKey::ReadMode(IS_WIN32 ? 'normal' : 'raw');
    my $out = (IS_WIN32 ? sub { 1 } : sub { print @_ });

    my $erase;
    if (!IS_WIN32 && -t) {
       my %keys = Term::ReadKey::GetControlChars();
       $erase = $keys{ERASE};
    }
    my $answer = '';
    while (defined(my $key = Term::ReadKey::ReadKey(0))) {
        if ($key =~ /[\012\015]/) {
            $out->("\n") if $key eq $formfeed;
	    $out->($key); last;
        }
        elsif ($key eq "\cC") {
            Term::ReadKey::ReadMode('restore');
            *STDIN = *SAVED;
            Term::ReadKey::ReadMode('restore');
            my $msg = loc("Interrupted.\n");
            $msg =~ s{\n\z}{$formfeed\n};
            die $msg;
        }
       elsif (defined $erase and $key eq $erase) {
            next unless length $answer;
            $out->("\cH \cH");
            chop $answer; next;
       }
        elsif ($key eq "\cH") {
            next unless length $answer;
            $out->("$key $key");
            chop $answer; next;
        }
        elsif ($key eq "\cW") {
            my $len = (length $answer) or next;
            $out->("\cH" x $len, " " x $len, "\cH" x $len);
            $answer = ''; next;
        }
        elsif (ord $key < 32) {
            # control character -- ignore it!
            next;
        }
        $out->($key);
        $answer .= $key;
    }

    if (defined $pattern) {
        $answer =~ $pattern or redo;
    }

    Term::ReadKey::ReadMode('restore');
    return $answer;
} }

=head3 edit_file ($file_name)

Launch editor to edit a file.

=cut

sub edit_file {
    my ($file) = @_;
    my $editor =	defined($ENV{SVN_EDITOR}) ? $ENV{SVN_EDITOR}
	   		: defined($ENV{EDITOR}) ? $ENV{EDITOR}
			: DEFAULT_EDITOR; # fall back to something
    my @editor = split (/ /, $editor);

    if ( IS_WIN32 ) {
        my $o;
        my $e = shift @editor;
        $e =~ s/^"//;
        while ( !defined($o = can_run ($e)) ) {
            die loc ("Can not find the editor: %1\n", $e) unless @editor;
            $e .= " ".shift @editor;
            $e =~ s/"$//;
        }
        unshift @editor, $o;
    }

    $logger->info(loc("Waiting for editor..."));

    # XXX: check $?
    system {$editor[0]} (@editor, $file) and die loc("Aborted: %1\n", $!);
}

=head3 get_buffer_from_editor ($what, $sep, $content, $filename, $anchor, $targets_ref)

XXX Undocumented

=cut

sub get_buffer_from_editor {
    my ( $what, $sep, $content, $file, $anchor, $targets_ref ) = @_;
    my $fh;
    if ( defined $content ) {
        ( $fh, $file ) = tmpfile( $file, TEXT => 1, UNLINK => 0 );
        print $fh $content;
        close $fh;
    } else {
        open $fh, $file or die $!;
        local $/;
        $content = <$fh>;
        close $fh;
    }

    my $time = time;

    while (!$ENV{'SVKBATCHMODE'} && 1) {
        open my $fh, '<', $file or die $!;
        my $md5 = md5_fh($fh);
        close $fh;

        edit_file($file);

        open $fh, '<', $file or die $!;
        last if ( $md5 ne md5_fh($fh) );
        close $fh;

        my $ans = get_prompt(
            loc( "%1 not modified: a)bort, e)dit, c)ommit?", ucfirst($what) ),
            qr/^[aec]/,
        );
        last if $ans =~ /^c/;

        # XXX: save the file somewhere
        unlink($file), die loc("Aborted.\n") if $ans =~ /^a/;
    }

    open $fh, $file or die $!;
    local $/;
    my @ret = defined $sep ? split( /\n\Q$sep\E\n/, <$fh>, 2 ) : (<$fh>);
    close $fh;
    unlink $file;

    die loc("Cannot find separator; aborted.\n")
        if defined($sep)
            and !defined( $ret[1] );

    return $ret[0] unless wantarray;

    # Compare targets in commit message
    my $old_targets = ( split( /\n\Q$sep\E\n/, $content, 2 ) )[1];
    $old_targets =~ s/^\?.*//mg;    # remove unversioned files

    my @new_targets
        = map {
        s/^\s+//;                   # proponly change will have leading spacs
        [ split( /[\s\+]+/, $_, 2 ) ]
        }
        grep {
        !/^\?/m
        }    # remove unversioned fils
        grep {/\S/}
        split( /\n+/, $ret[1] );

    if ( $old_targets ne $ret[1] ) {

        # Assign new targets
        @$targets_ref = map abs2rel( $_->[1], $anchor, undef, '/' ),
            @new_targets;
    }
    return ( $ret[0], \@new_targets );
}

=head3 get_encoding

Get the current encoding from locale

=cut

sub get_encoding {
    return 'utf8' if $^O eq 'darwin';
    local $@;
    return (resolve_alias (eval {
	require Locale::Maketext::Lexicon;
        local $Locale::Maketext::Lexicon::Opts{encoding} = 'locale';
        Locale::Maketext::Lexicon::encoding();
    } || eval {
        require 'encoding.pm';
        defined &encoding::_get_locale_encoding() or die;
        return encoding::_get_locale_encoding();
    }) or 'utf8');
}

=head3 get_encoder ([$encoding])

=cut

sub get_encoder {
    my $enc = shift || get_encoding;
    return Encode::find_encoding ($enc);
}

=head3 from_native ($octets, $what, [$encoding])

=cut

sub from_native {
    my $enc = ref $_[2] ? $_[2] : get_encoder ($_[2]);
    my $buf = eval { $enc->decode ($_[0], 1) };
    die loc ("Can't decode %1 as %2.\n", $_[1], $enc->name) if $@;
    $_[0] = $buf;
    Encode::_utf8_off ($_[0]);
    return;
}

=head3 to_native ($octets, $what, [$encoding])

=cut

sub to_native {
    my $enc = ref $_[2] ? $_[2] : get_encoder ($_[2]);
    Encode::_utf8_on ($_[0]);
    my $buf = eval { $enc->encode ($_[0], 1) };
    die loc ("Can't encode %1 as %2.\n", $_[1], $enc->name) if $@;
    $_[0] = $buf;
    return;
}

sub find_svm_source { # DEPRECATED: use SVK::Path->universal, only used in SVK::Command now.
    my ($repos, $path, $rev) = @_;
    my $t = SVK::Path->real_new({ depot => SVK::Depot->new({repos => $repos}),
                                  path => $path, revision => $rev });
    $t->refresh_revision unless $rev;
    my $u = $t->universal;
    return map { $u->$_ } qw(uuid path rev);
}

=head2 File Content Manipulation

=head3 read_file ($filename)

Read from a file and returns its content as a single scalar.

=cut

sub read_file {
    local $/;
    open my $fh, "< $_[0]" or die $!;
    return <$fh>;
}

=head3 write_file ($filename, $content)

Write out content to a file, overwriting existing content if present.

=cut

sub write_file {
    return print $_[1] if ($_[0] eq '-');
    open my $fh, '>', $_[0] or die $!;
    print $fh $_[1];
}

=head3 slurp_fh ($input_fh, $output_fh)

Read all data from the input filehandle and write them to the
output filehandle.  The input may also be a scalar, or reference
to a scalar.

=cut

sub slurp_fh {
    my $from = shift;
    my $to = shift;

    local $/ = \16384;

    if (!ref($from)) {
        print $to $from;
    }
    elsif (ref($from) eq 'SCALAR') {
        print $to $$from;
    }
    else {
        while (<$from>) {
            print $to $_;
        }
    }
}

=head3 md5_fh ($input_fh)

Calculate MD5 checksum for data in the input filehandle.

=cut

{
    no warnings 'once';
    push @EXPORT_OK, qw( md5 ); # deprecated compatibility API
    *md5 = *md5_fh;
}

sub md5_fh {
    require Digest::MD5;
    my $fh = shift;
    my $ctx = Digest::MD5->new;
    $ctx->addfile($fh);

    return $ctx->hexdigest;
}

=head3 mimetype ($file)

Return the MIME type for the file, or C<undef> if the MIME database
is missing on the system.

=cut

{ my $mm; # C<state $mm>, yuck

sub mimetype {
    my ($filename) = @_;

    # find an implementation module if necessary
    $mm ||= do {
        my $module = $ENV{SVKMIME} || 'Internal';
        $module =~ s/:://;
        $module = "SVK::MimeDetect::$module";
        eval "require $module";
        die $@ if $@;
        $module->new();
    };

    return $mm->checktype_filename($filename);
}

}

=head3 mimetype_is_text ($mimetype)

Return whether a MIME type string looks like a text file.

=cut


sub mimetype_is_text {
    my $type = shift;
    scalar $type =~ m{^(?:text/.*
                         |application/x-(?:perl
		                          |python
                                          |ruby
                                          |php
                                          |java
                                          |[kcz]?sh
                                          |awk
                                          |shellscript)
                         |image/x-x(?:bit|pix)map)$}x;
}

=head3 is_binary_file ($filename OR $filehandle)

Returns true if the given file or filehandle contains binary data.  Otherwise,
returns false.

=cut

sub is_binary_file {
    my ($file) = @_;

    # let Perl do the hard work
    return 1 if -f $file && !-T _;  # !-T handles empty files correctly
    return;
}

=head2 Path and Filename Handling

=head3 abspath ($path)

Return paths with components in symlink resolved, but keep the final
path even if it's symlink.  Returns C<undef> if the base directory
does not exist.

=cut

sub abs_path {
    my $path = shift;

    if (!IS_WIN32) {
        require Cwd;
	return Cwd::abs_path ($path) unless -l $path;
	my (undef, $dir, $pathname) = splitpath ($path);
	return catpath (undef, Cwd::abs_path ($dir), $pathname);
    }

    # Win32 - Complex handling to get the correct base case
    $path = '.' if !length $path;
    $path = ucfirst(Win32::GetFullPathName($path));
    return undef unless -d dirname($path);

    my ($base, $remainder) = ($path, '');
    while (length($base) > 1) {
	my $new_base = Win32::GetLongPathName($base);
	return $new_base.$remainder if defined $new_base;

	$new_base = dirname($base);
	$remainder = substr($base, length($new_base)) . $remainder;
	$base = $new_base;
    }

    return undef;
}

=head3 abs_path_noexist ($path)

Return paths with components in symlink resolved, but keep the final
path even if it's symlink.  Unlike abs_path(), returns a valid value
even if the base directory doesn't exist.

=cut

sub abs_path_noexist {
    my $path = shift;

    my $rest = '';
    until (abs_path ($path)) {
	return $rest unless length $path;
	my $new_path = dirname($path);
	$rest = substr($path, length($new_path)) . $rest;
	$path = $new_path;
    }

    return abs_path ($path) . $rest;
}

=head3 abs2rel ($pathname, $old_basedir, $new_basedir, $sep)

Replace the base directory in the native pathname to another base directory
and return the result.

If the pathname is not under C<$old_basedir>, it is returned unmodified.

If C<$new_basedir> is an empty string, removes the old base directory but
keeps the leading slash.  If C<$new_basedir> is C<undef>, also removes
the leading slash.

By default, the return value of this function will use C<$SEP> as its
path separator.  Setting C<$sep> to C</> will turn native path separators
into C</> instead.

=cut

sub abs2rel {
    my ($pathname, $old_basedir, $new_basedir, $sep) = @_;

    my $rel = File::Spec::Functions::abs2rel($pathname, $old_basedir);

    if ($rel =~ /(?:\A|\Q$SEP\E)\.\.(?:\Q$SEP\E|\z)/o) {
        $rel = $pathname;
    }
    elsif (defined $new_basedir) {
        $rel = catdir($new_basedir, $rel);
    }

    # resemble file::spec pre-3.13 behaviour, return empty string.
    return '' if $rel eq '.';

    $rel =~ s/\Q$SEP/$sep/go if $sep and $SEP ne $sep;
    return $rel;
}

=head3 catdir (@directories)

Concatenate directory names to form a complete path; also removes the
trailing slash from the resulting string, unless it is the root directory.

=head3 catfile (@directories, $pathname)

Concatenate one or more directory names and a filename to form a complete
path, ending with a filename.  If C<$pathname> contains directories, they
will be splitted off to the end of C<@directories>.

=cut

sub catfile {
    my $pathname = pop;
    return File::Spec::Functions::catfile (
	(grep {defined and length} @_), splitdir($pathname)
    )
}

=head3 catpath ($volume, $directory, $filename)

XXX Undocumented - See File::Spec

=head3 devnull ()

Return a file name suitable for reading, and guaranteed to be empty.

=cut

my $devnull;
sub devnull () {
    IS_WIN32 ? ($devnull ||= tmpfile('', UNLINK => 1))
             : File::Spec::Functions::devnull();
}

=head3 get_anchor ($need_target, @paths)

Returns the (anchor, target) pairs for native path @paths.  Discard
the targets being returned unless $need_target.

=cut

sub get_anchor {
    my $need_target = shift;
    map {
	my ($volume, $anchor, $target) = splitpath ($_);
	chop $anchor if length ($anchor) > 1;
	($volume.$anchor, $need_target ? ($target) : ())
    } @_;
}

=head3 get_depot_anchor ($need_target, @paths)

Returns the (anchor, target) pairs for depotpaths @paths.  Discard the
targets being returned unless $need_target.

=cut

sub get_depot_anchor {
    my $need_target = shift;
    map {
	my (undef, $anchor, $target) = File::Spec::Unix->splitpath ($_);
	chop $anchor if length ($anchor) > 1;
	($anchor, $need_target ? ($target) : ())
    } @_;
}

=head3 catdepot ($depot_name, @paths)

=cut

sub catdepot {
    return File::Spec::Unix->catdir('/', @_);
}

=head3 make_path ($path)

Create a directory, and intermediate directories as required.  

=cut

sub make_path {
    my $path = shift;

    return undef if !defined($path) or -d $path;

    require File::Path;
    my @ret = eval { File::Path::mkpath([$path]) };
    if ($@) {
	$@ =~ s/ at .*//;
	die $@;
    }
    return @ret;
}

=head3 splitpath ($path)

Splits a path in to volume, directory, and filename portions.  On systems
with no concept of volume, returns an empty string for volume.

=head3 splitdir ($path)

The opposite of C<catdir()>; return a list of path components.

=head3 tmpdir ()

Return the name of the first writable directory from a list of possible
temporary directories.

=head3 tmpfile (TEXT => $is_textmode, %args)

In scalar context, return the filehandle of a temporary file.
In list context, return the filehandle and the filename.

If C<$is_textmode> is true, the returned file handle is marked with
C<TEXT_MODE>.

See L<File::Temp> for valid keys of C<%args>.

=cut

sub tmpfile {
    my ($temp, %args) = @_;
    my $dir = tmpdir;
    my $text = delete $args{TEXT};
    $temp = "svk-${temp}XXXXX";

    require File::Temp;
    return File::Temp::mktemp ("$dir/$temp") if exists $args{OPEN} && $args{OPEN} == 0;
    my $tmp = File::Temp->new ( TEMPLATE => $temp,
				DIR => $dir,
				SUFFIX => '.tmp',
				%args
			      );
    binmode($tmp, TEXT_MODE) if $text;
    return wantarray ? ($tmp, $tmp->filename) : $tmp;
}

=head3 is_symlink ($filename)

Return whether a file is a symbolic link, as determined by C<-l>.
If C<$filename> is not specified, return C<-l _> instead.

=cut

sub is_symlink {
    HAS_SYMLINK ? @_ ? (-l $_[0]) : (-l _) : 0;
}

=head3 is_executable ($filename)

Return whether a file is likely to be an executable file.
Unlike C<is_symlink()>, the C<$filename> argument is not optional.

=cut

sub is_executable {
    require ExtUtils::MakeMaker;
    defined($_[0]) and length($_[0]) and MM->maybe_command($_[0]);
}

=head3 can_run ($filename)

Check if we can run some command.

=cut

sub can_run {
    my ($_cmd, @path) = @_;

    return $_cmd if (-x $_cmd or $_cmd = is_executable($_cmd));

    for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), @path, '.') {
        my $abs = catfile($dir, $_[0]);
        next if -d $abs;
        return $abs if (-x $abs or $abs = is_executable($abs));
    }

    return;
}

=head3 is_uri ($string)

Check if a string is a valid URI.

=cut

sub is_uri {
    ($_[0] =~ /^[A-Za-z][-+.A-Za-z0-9]+:/)
}

=head3 move_path ($source, $target)

Move a path to another place, creating intermediate directories in the target
path if neccessary.  If move failed, tell the user to move it manually.

=cut

sub move_path {
    my ($source, $target) = @_;

    if (-d $source and (!-d $target or rmdir($target))) {
        require File::Copy;
        make_path (dirname($target));
        File::Copy::move ($source => $target) and return;
    }

    $logger->error(loc(
        "Cannot rename %1 to %2; please move it manually.",
        catfile($source), catfile($target),
    ));
}

=head3 traverse_history (root => $fs_root, path => $path,
    cross => $cross, callback => $cb($path, $revision))

Traverse the history of $path in $fs_root backwards until the first
copy, unless $cross is true.  We do cross renames regardless of the
value of $cross being non-zero, but not -1.  We invoke $cb for each
$path, $revision we encounter.  If cb returns a nonzero value we stop
traversing as well.

=cut

sub traverse_history {
    my %args = @_;

    my $old_pool = SVN::Pool->new;
    my $new_pool = SVN::Pool->new;
    my $spool = SVN::Pool->new_default;

    my ($root, $path) = @args{qw/root path/};
    # If the root is txn root, get a similar one.
    # XXX: We actually want to move this to SVK::Path::, and
    # svk::checkout should respect copies on checkout
    if ($root->can('txn') && $root->txn) {
	($root, $path) = $root->get_revision_root
	    ($path, $root->txn->base_revision );
    }

    my $hist = $root->node_history ($path, $old_pool);
    my $rv;
    my $revision;

    while (1) {
        my $ohist = $hist;
        $hist = $hist->prev(max(0, $args{cross} || 0), $new_pool);
        if (!$hist) {
            last if $args{cross};
            last unless $hist = $ohist->prev((1), $new_pool);
            # We are not supposed to cross copies, ($path,$revision)
            # refers to a node in $ohist that is a copy and that has a
            # prev if we ask svn to traverse copies.
            # Let's find out if the copy was actually a rename instead
            # of a copy.
            my $root = $root->fs->revision_root($revision, $spool);
            my $frompath;
            my $fromrev = -1;
            # We know that $path was a real copy and it that it has a
            # prev, so find the node from which it was copied.
            do {
                ($fromrev, $frompath) = $root->copied_from($path, $spool);
            } until ($fromrev >= 0 || !($path =~ s{/[^/]*$}{}));
            die "Assertion failed: $path in $revision isn't a copy."
                if $fromrev < 0;
            # Ok, $path in $root was a copy of ($frompath,$fromrev).
            # If $frompath was deleted in $root then the copy was really
            # a rename.
            my $entry = $root->paths_changed($spool)->{$frompath};
            last unless $entry &&
                $entry->change_kind == $SVN::Fs::PathChange::delete;

            # XXX Do we need to worry about a parent of $frompath having
            # been deleted instead?  If so the 2 lines below might work as
            # an alternative, to the previous 3 lines.  However this also
            # treats a delete followed by a copy of an older revision in
            # two separate commits as a rename, which technically it's not.
            #last unless $root->check_path($frompath, $spool) ==
            #    $SVN::Node::none;
        }
        ($path, $revision) = $hist->location ($new_pool);
        $old_pool->clear;
        $rv = $args{callback}->($path, $revision);
        last if !$rv;
        $spool->clear;
        ($old_pool, $new_pool) = ($new_pool, $old_pool);
    }

    return $rv;
}

sub reformat_svn_date {
    my ($format, $svn_date) = @_;
    return time2str($format, str2time($svn_date));
}

sub str2time {
    require Time::Local;
    my ($year, $month, $day, $hh, $mm, $ss) = split /[-T:]/, $_[0];
    $year -= 1900;
    $month--;
    chop($ss);  # remove the 'Z'
    my $zone = 0;  # UTC

    my @lt = localtime(time);

    my $frac = $ss - int($ss);
    $ss = int $ss;

    for ( $year, $month, $day, $hh, $mm, $ss ) {
        return undef unless defined($_) 
    }
    return undef
      unless ( $month <= 11
        && $day >= 1
        && $day <= 31
        && $hh <= 23
        && $mm <= 59
        && $ss <= 59 );

    my $result;

    $result = eval {
        local $SIG{__DIE__} = sub { };    # Ick!
        Time::Local::timegm( $ss, $mm, $hh, $day, $month, $year );
    };
    return undef
        if !defined $result
        or $result == -1
        && join( "", $ss, $mm, $hh, $day, $month, $year ) ne "595923311169";

    return $result + $frac;
}

sub time2str {
    my ($format, $time) = @_;
    if (IS_WIN32) {
	require Date::Format;
	goto \&Date::Format::time2str;
    }

    require POSIX;
    return POSIX::strftime($format, localtime($time) );
}


sub find_dotsvk {
    require Cwd;
    require Path::Class;

    my $p = Path::Class::Dir->new( Cwd::cwd() );

    my $prev = "not $p";
    my $found = q{};
    while ( $p && $p ne $prev && -r $p ) {
	$prev = $p;
	my $svk = $p->subdir('.svk');
	return $svk if -e $svk && -e $svk->file('floating');
	$p = $p->parent();
    }

    return
}

=head3 is_path_inside($path, $parent)

Returns true if unix path C<$path> is inside C<$parent>.
If they are the same, return true as well.

=cut

sub is_path_inside {
    my ($path, $parent) = @_;
    return 1 if $path eq $parent;
    return substr ($path, 0, length ($parent)+1) eq "$parent/";
}

=head3 uri_escape($uri)

Returns escaped URI.

=cut

sub uri_escape {
    my ($uri) = @_;
    $uri =~ s/([^0-9A-Za-z@%+\-\/:_.!~*'()])/sprintf("%%%02X", ord($1))/eg;
    return $uri;
}

=head3 uri_unescape($uri)

Unescape escaped URI and return it.

=cut

sub uri_unescape {
    my ($uri) = @_;
    $uri =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $uri;
}

=head3 is_depotpath($path)

Check if a string is a valid depotpath.

=cut

sub is_depotpath {
    ($_[0] =~ m|^/([^/]*)(/.*?)/?$|)
}

1;

__END__

