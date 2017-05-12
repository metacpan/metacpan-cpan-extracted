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
package SVK::Command::Switch;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Update );
use SVK::XD;
use SVK::I18N;
use File::Spec;

sub options {
    ($_[0]->SUPER::options,
     'd|delete|detach' => 'detach',
    );
}

sub parse_arg {
    my ($self, @arg) = @_;

    if ($self->{detach}) {
        goto &{ $self->rebless ('checkout::detach')->can ('parse_arg') };
    }

    return if $#arg < 0 || $#arg > 1;
    return ($self->arg_uri_maybe($arg[0]),
	    $self->arg_copath($arg[1] || ''));
}

sub lock { $_[0]->lock_target ($_[2]) }

sub run {
    my ($self, $target, $cotarget) = @_;
    die loc("different depot") unless $target->same_repos ($cotarget);

    my ($entry, @where) = $self->{xd}{checkout}->get ($cotarget->copath_anchor);
    die loc("Can only switch checkout root.\n")
	unless $where[0] eq $cotarget->copath;

    $target = $target->as_depotpath ($self->{rev});
    die loc("Path %1 does not exist.\n", $target->report)
	if $target->root->check_path ($target->path_anchor) == $SVN::Node::none;
    SVK::Merge->auto (%$self, repos => $target->repos,
		      src => $cotarget, dst => $target);
#    switch to related_to once the api is ready
    # check if the switch has a base at all
#    die loc ("%1 is not related to %2.\n", $cotarget->{report}, $target->{report})
#	unless $cotarget->new->as_depotpath->related_to ($target);

    $self->do_update ($cotarget, $target);
    $self->{xd}{checkout}->store ($cotarget->copath,
				  {depotpath => $target->depotpath,
				   revision => $target->revision});
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Switch - Switch to another branch and keep local changes

=head1 SYNOPSIS

 switch DEPOTPATH [PATH]

For information about how to change the mirrored location of a remote
repository, please see the C<--relocate> option to C<svk mirror>.

=head1 OPTIONS

 -r [--revision] REV    : act on revision REV instead of the head revision
 -d [--detach]          : mark a path as no longer checked out
 -q [--quiet]           : print as little as possible

