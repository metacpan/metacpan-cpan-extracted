# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.

package Stow::Util;

=head1 NAME

Stow::Util - general utilities

=head1 SYNOPSIS

    use Stow::Util qw(debug set_debug_level error ...);

=head1 DESCRIPTION

Supporting utility routines for L<Stow>.

=cut

use strict;
use warnings;

use File::Spec;
use POSIX qw(getcwd);

use base qw(Exporter);
our @EXPORT_OK = qw(
    error debug set_debug_level set_test_mode
    join_paths parent canon_path restore_cwd
    adjust_dotfile unadjust_dotfile
);

our $ProgramName = 'stow';
our $VERSION = '2.4.1';

#############################################################################
#
# General Utilities: nothing stow specific here.
#
#############################################################################

=head1 IMPORTABLE SUBROUTINES

=head2 error($format, @args)

Outputs an error message in a consistent form and then dies.

=cut

sub error {
    my ($format, @args) = @_;
    die "$ProgramName: ERROR: " . sprintf($format, @args) . "\n";
}

=head2 set_debug_level($level)

Sets verbosity level for C<debug()>.

=cut

our $debug_level = 0;

sub set_debug_level {
    my ($level) = @_;
    $debug_level = $level;
}

=head2 set_test_mode($on_or_off)

Sets testmode on or off.

=cut

our $test_mode = 0;

sub set_test_mode {
    my ($on_or_off) = @_;
    if ($on_or_off) {
        $test_mode = 1;
    }
    else {
        $test_mode = 0;
    }
}

=head2 debug($level[, $indent_level], $msg)

Logs to STDERR based on C<$debug_level> setting.  C<$level> is the
minimum verbosity level required to output C<$msg>.  All output is to
STDERR to preserve backward compatibility, except for in test mode,
when STDOUT is used instead.  In test mode, the verbosity can be
overridden via the C<TEST_VERBOSE> environment variable.

Verbosity rules:

=over 4

=item    0: errors only

=item >= 1: print operations: LINK/UNLINK/MKDIR/RMDIR/MV

=item >= 2: print operation exceptions

e.g. "_this_ already points to _that_", skipping, deferring,
overriding, fixing invalid links

=item >= 3: print trace detail: trace: stow/unstow/package/contents/node

=item >= 4: debug helper routines

=item >= 5: debug ignore lists

=back

=cut

sub debug {
    my $level = shift;
    my $indent_level;
    # Maintain backwards-compatibility in case anyone's relying on this.
    $indent_level = $_[0] =~ /^\d+$/ ? shift : 0;
    my $msg = shift;
    if ($debug_level >= $level) {
        my $indent = '    ' x $indent_level;
        if ($test_mode) {
            print "# $indent$msg\n";
        }
        else {
            warn "$indent$msg\n";
        }
    }
}

#===== METHOD ===============================================================
# Name      : join_paths()
# Purpose   : concatenates given paths
# Parameters: path1, path2, ... => paths
# Returns   : concatenation of given paths
# Throws    : n/a
# Comments  : Factors out some redundant path elements:
#           : '//' => '/', and 'a/b/../c' => 'a/c'.  We need this function
#           : with this behaviour, even though b could be a symlink to
#           : elsewhere, as noted in the perldoc for File::Spec->canonpath().
#           : This behaviour is deliberately different to
#           : Stow::Util::canon_path(), because the way join_paths() is used
#           : relies on this.  Firstly, there is no guarantee that the paths
#           : exist, so a filesystem check is inappropriate.
#           :
#           : For example, it's used to determine the path from the target
#           : directory to a symlink destination.  So if a symlink
#           : path/to/target/a/b/c points to ../../../stow/pkg/a/b/c,
#           : then joining path/to/target/a/b with ../../../stow/pkg/a/b/c
#           : yields path/to/stow/pkg/a/b/c, and it's crucial that the
#           : path/to/stow prefix matches a recognisable stow directory.
#============================================================================
sub join_paths {
    my @paths = @_;

    debug(5, 5, "| Joining: @paths");
    my $result = '';
    for my $part (@paths) {
        next if ! length $part;  # probably shouldn't happen?
        $part = File::Spec->canonpath($part);

        if (substr($part, 0, 1) eq '/') {
            $result = $part; # absolute path, so ignore all previous parts
        }
        else {
            $result .= '/' if length $result && $result ne '/';
            $result .= $part;
        }
        debug(7, 6, "| Join now: $result");
    }
    debug(6, 5, "| Joined: $result");

    # Need this to remove any initial ./
    $result = File::Spec->canonpath($result);

    # remove foo/..
    1 while $result =~ s,(^|/)(?!\.\.)[^/]+/\.\.(/|$),$1,;
    debug(6, 5, "| After .. removal: $result");

    $result = File::Spec->canonpath($result);
    debug(5, 5, "| Final join: $result");

    return $result;
}

#===== METHOD ===============================================================
# Name      : parent
# Purpose   : find the parent of the given path
# Parameters: @path => components of the path
# Returns   : returns a path string
# Throws    : n/a
# Comments  : allows you to send multiple chunks of the path
#           : (this feature is currently not used)
#============================================================================
sub parent {
    my @path = @_;
    my $path = join '/', @_;
    my @elts = split m{/+}, $path;
    pop @elts;
    return join '/', @elts;
}

#===== METHOD ===============================================================
# Name      : canon_path
# Purpose   : find absolute canonical path of given path
# Parameters: $path
# Returns   : absolute canonical path
# Throws    : n/a
# Comments  : is this significantly different from File::Spec->rel2abs?
#============================================================================
sub canon_path {
    my ($path) = @_;

    my $cwd = getcwd();
    chdir($path) or error("canon_path: cannot chdir to $path from $cwd");
    my $canon_path = getcwd();
    restore_cwd($cwd);

    return $canon_path;
}

sub restore_cwd {
    my ($prev) = @_;
    chdir($prev) or error("Your current directory $prev seems to have vanished");
}

sub adjust_dotfile {
    my ($pkg_node) = @_;
    (my $adjusted = $pkg_node) =~ s/^dot-([^.])/.$1/;
    return $adjusted;
}

# Needed when unstowing with --compat and --dotfiles
sub unadjust_dotfile {
    my ($target_node) = @_;
    return $target_node if $target_node =~ /^\.\.?$/;
    (my $adjusted = $target_node) =~ s/^\./dot-/;
    return $adjusted;
}

=head1 BUGS

=head1 SEE ALSO

=cut

1;

# Local variables:
# mode: perl
# end:
# vim: ft=perl
