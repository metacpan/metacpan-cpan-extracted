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
package SVK::Command::Admin;
use strict;
use SVK::I18N;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );

sub options {
    ();
}

sub parse_arg {
    my ($self, @arg) = @_;

    @arg or return;

    my $command = shift(@arg);
    return ($command, undef, @arg) if $command eq 'help';

    my $depot = '/'.(@arg ? pop(@arg) : '').'/';

    return ($command, $self->arg_depotroot($depot), @arg);
}

sub run {
    my ($self, $command, $target, @arg) = @_;

    if ($command eq 'rmcache') {
        my $dir = $self->{xd}->cache_directory;
        opendir my $fh, $dir or die loc("cannot open %1: %2", $dir, $!);
        unlink map "$dir/$_", readdir($fh);
        close $fh;
        return;
    }

    (system(
        'svnadmin',
        $command,
        ($target ? $target->repospath : ()),
        @arg
    ) >= 0) or die loc("Could not run %1: %2", 'svnadmin', $?);

    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Admin - Administration tools

=head1 SYNOPSIS

Subcommands provided by F<svnadmin>:

 admin help [COMMAND]
 admin deltify [DEPOTNAME]
 admin dump [DEPOTNAME]
 admin hotcopy /path/to/repository [DEPOTNAME]
 admin list-dblogs [DEPOTNAME]
 admin list-unused-dblogs [DEPOTNAME]
 admin load [DEPOTNAME]
 admin lstxns [DEPOTNAME]
 admin recover [DEPOTNAME]
 admin rmtxns [DEPOTNAME]
 admin setlog -r REVISION FILE [DEPOTNAME]
 admin verify [DEPOTNAME]

Subcommands specific to F<svk>:

 admin rmcache

The C<rmcache> subcommand purges the inode/mtime/size cache on all checkout
subdirectories.  Use C<svk admin help> for helps on other subcommands.

