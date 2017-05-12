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
package SVK::Command::Info;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use constant opt_recursive => 0;
use SVK::XD;
use SVK::Merge;
use SVK::I18N;
use YAML::Syck;
use SVK::Logger;
use SVK::Project;
use autouse 'SVK::Util' => qw( reformat_svn_date );

# XXX: provide -r which walks peg to the specified revision based on
# the root.

sub parse_arg {
    my ($self, @arg) = @_;
    @arg = ('') if $#arg < 0;

    return map {$self->arg_co_maybe ($_)} @arg;
}

sub run {
    my ( $self, @arg ) = @_;
    my $exception = '';
    my $errs      = [];
    $self->run_command_recursively(
        $_,
        sub {
            $self->_do_info( $_[0] );
        }, $errs, $#arg,
    ) for @arg;

    return scalar @$errs;
}

sub _do_info {
    my ($self, $target) = @_;

    # XXX: handle checkout specific ones such as schedule
    $target->root->check_path($target->path)
	or die loc("Path %1 does not exist.\n", $target->depotpath);

    my ($m, $mpath) = $target->is_mirrored;

    my ($proj) = SVK::Project->create_from_path(
	         $target->depot, $target->path );

    $logger->info( loc("Checkout Path: %1\n",$target->copath))
	if $target->isa('SVK::Path::Checkout');
    $logger->info( loc("Depot Path: %1\n", $target->depotpath));
    $proj->info($target) if $proj;
    $logger->info( loc("Revision: %1\n", $target->revision));
    if (defined( my $lastchanged = $target->root->node_created_rev( $target->path ))) {
        $logger->info( loc( "Last Changed Rev.: %1\n", $lastchanged ));
        my $date
            = $target->root->fs->revision_prop( $lastchanged, 'svn:date' );
        $logger->info( loc(
            "Last Changed Date: %1\n",
            reformat_svn_date( "%Y-%m-%d", $date )
        ));
    }

    $logger->info( loc("Mirrored From: %1, Rev. %2\n",$m->url, $m->fromrev))
	if $m;

    for ($target->copy_ancestors) {
	$logger->info( loc("Copied From: %1, Rev. %2\n", $_->[0], $_->[1]));
    }

    $self->{merge} = SVK::Merge->new (%$self);
    my $minfo = $self->{merge}->find_merge_sources ($target, 0,1);
    for (sort { $minfo->{$b} <=> $minfo->{$a} } keys %$minfo) {
	$logger->info( loc("Merged From: %1, Rev. %2\n",(split/:/)[1],$minfo->{$_}));
    }
    $logger->info( "\n");
}

1;

__DATA__

=head1 NAME

SVK::Command::Info - Display information about a file or directory

=head1 SYNOPSIS

 info [PATH | DEPOTPATH]...

=head1 OPTIONS

 -R [--recursive]       : descend recursively

=head1 DESCRIPTION

For example, here's the way to display the info of a checkout path:

 % svk info ~/dev/svk
 Checkout Path: /Users/gugod/dev/svk
 Depot Path: //svk/local
 Revision: 447
 Last Changed Rev.: 447
 Last Changed Date: 2006-11-28
 Copied From: /svk/trunk, Rev. 434
 Merged From: /svk/trunk, Rev. 445

You can see the result has some basic information: the actual depot path,
and current revision. Next are advanced information about copy and merge
source for this depot path.

The result of C<svk info //svk/local> is almost the same as above,
except for the C<Checkout Path:> line is not there, because
you are not referring to a checkout path.

Note that the revision numbers on C<Copied From:> and C<Merged From:> lines
are for the source path (//svk/trunk), not the target path (//svk/local).
The example above state that, I<//svk/local is copied from the revision 434
of //svk/trunk>, and I<//svk/local was merged from the revision 445 of
//svk/trunk>.  Hence if you do a C<svk log -r 434 //svk/local>, svk would tell
you that //svk/local does not exist at revision 434.

So far there is no easy way to tell the actual revision number
of //svk/local right after a copy or merge.

If the target is a depot path, or the corresponding depot path of the target
checkout path is actually a mirroring path, the output of this command will
look like this:

 % svk info //svk/trunk
 Depot Path: //svk/trunk
 Revision: 447
 Last Changed Rev.: 445
 Mirrored From: svn://svn.clkao.org/svk, Rev. 1744

So you can see this depot path is mirrored from a remote repository,
and so far mirrored up to revision 1744.

