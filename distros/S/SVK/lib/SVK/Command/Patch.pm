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
package SVK::Command::Patch;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use SVK::XD;
use SVK::Patch;
use SVK::Merge;
use SVK::Editor::Merge;
use SVK::I18N;
use SVK::Command::Log;
use SVK::Logger;

sub options {
    (
        'view|cat'    => 'view',
        'dump'    => 'dump',
        'regen|regenerate'   => 'regen',
        'update|up'  => 'update',
        'test'    => 'test',
        'apply'   => 'apply',
        'delete|del|rm'  => 'delete',
        'list|ls'    => 'list',
        'depot=s' => 'depot'
    );
}

sub parse_arg {
    my ($self, @args) = @_;
    my $cmd = shift @args or return;

    # Try to find a subcommand for invocations such as "svk patch ls"
    my %options = $self->options;
    while (my ($names, $canonical) = each %options) {
        $cmd =~ /\A$names\z/ or next;
        bless($self, "SVK::Command::Patch::$canonical");
        return($self->parse_arg(@args));
    }

    # Can't find a subcommand - return help
    return;
}

sub _store {
    my ($self, $patch) = @_;
    $patch->store ($self->{xd}->patch_file ($patch->{name}));
}

sub _load {
    my ($self, $name) = @_;
    SVK::Patch->load (
        $self->{xd}->patch_file ($name),
        $self->{xd},
        ($self->{depot} || ''),
    );
}

sub run {
    my ($self, $func, @arg) = @_;
    $self->$func (@arg);
}

package SVK::Command::Patch::FileRequired;
use base qw/SVK::Command::Patch/;
use SVK::Logger;
use SVK::I18N;

sub parse_arg {
    my ($self, @arg) = @_;

	die loc ("Filename required.\n")
	    unless $arg[0];
	splice @arg, 0, 1, $self->_load ($arg[0]);
    return @arg;
}

package SVK::Command::Patch::view;
use base qw/SVK::Command::Patch::FileRequired/;

sub run {
    my ($self, $patch) = @_;
    return $patch->view;
}

package SVK::Command::Patch::dump;
use SVK::Logger;

use base qw/SVK::Command::Patch::FileRequired/;

sub run {
    my ($self, $patch) = @_;
    $logger->info( YAML::Syck::Dump ($patch));
    return;
}

package SVK::Command::Patch::test;

use base qw/SVK::Command::Patch::FileRequired/;
use SVK::I18N;
use SVK::Logger;

sub run {
    my ($self, $patch, $not_applicable) = @_;

    return $not_applicable if $not_applicable;
    if (my $conflicts = $patch->apply (1)) {
	$logger->error(loc("%*(%1,conflict) found.", $conflicts));
	$logger->error(loc("Please do a merge to resolve conflicts and regen the patch."));
    }

    return;
}

package SVK::Command::Patch::regen;
use SVK::I18N;
use SVK::Logger;

use base qw/SVK::Command::Patch::FileRequired/;

sub run {
    my ($self, $patch, $not_applicable) = @_;
    return $not_applicable if $not_applicable;
    if (my $conflicts = $patch->regen) {
	# XXX: check empty too? probably already applied.
	return loc("%*(%1,conflict) found, patch aborted.\n", $conflicts)
    }
    $self->_store ($patch);
    return;

}

package SVK::Command::Patch::update;
use SVK::I18N;

use base qw/SVK::Command::Patch::FileRequired/;

sub run {
    my ($self, $patch, $not_applicable) = @_;
    return $not_applicable if $not_applicable;
    if (my $conflicts = $patch->update) {
	# XXX: check empty too? probably already applied.
	return loc("%*(%1,conflict) found, update aborted.\n", $conflicts)
    }
    $self->_store ($patch);
    return;

}

package SVK::Command::Patch::delete;

use base qw/SVK::Command::Patch::FileRequired/;

sub run {
    my ($self, $patch) = @_;
    unlink $self->{xd}->patch_file ($patch->{name});
    return;
}

package SVK::Command::Patch::list;

use base qw/SVK::Command::Patch/;
use SVK::Logger;

sub parse_arg { undef }
sub run {
    my ($self) = @_;
    opendir my $dir, $self->{xd}->patch_directory;
    foreach my $file (readdir ($dir)) {
	next if $file =~ /^\./;
	$file =~ s/\.patch$// or next;
	my ($patch, $not_applicable) = $self->_load ($file);
	$logger->info( "$patch->{name}\@$patch->{level}: ".
	    ( $not_applicable ? "[n/a]" : '' ) );
    }
    return;
}

package SVK::Command::Patch::apply;
use SVK::I18N;

use base qw/SVK::Command::Patch::FileRequired/;
use SVK::Logger;

sub run {
    my ($self, $patch, $not_applicable, @args) = @_;
    return $not_applicable if $not_applicable;
    my $mergecmd = $self->command ('merge');
    $mergecmd->getopt (\@args);
    my $dst = $self->arg_co_maybe ($args[0] || '');
    $self->lock_target ($dst) if $dst->isa('SVK::Path::Checkout');
    my $ticket;
    $mergecmd->get_commit_message ($patch->{log})
	unless $dst->isa('SVK::Path::Checkout');
    my $merge = SVK::Merge->new (%$mergecmd, dst => $dst, repos => $dst->repos);
    my $dstinfo = $merge->merge_info($dst);
    $ticket = $merge->_get_new_ticket (SVK::Merge::Info->new ($patch->{ticket})) 
	if $patch->{ticket} && $dst->universal->same_resource ($patch->{target});
    $patch->apply_to ($dst, $mergecmd->get_editor ($dst),
		      resolve => $merge->resolver,
		      ticket => $ticket,
		      dstinfo => $dstinfo);
    delete $mergecmd->{save_message};
    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Patch - Manage patches

=head1 SYNOPSIS

 patch --ls    [--list]
 patch --cat   [--view]       PATCHNAME
 patch --regen [--regenerate] PATCHNAME
 patch --up    [--update]     PATCHNAME
 patch --apply                PATCHNAME [DEPOTPATH | PATH] [-- MERGEOPTIONS]
 patch --rm    [--delete]     PATCHNAME

=head1 OPTIONS

 --depot DEPOTNAME      : operate on a depot other than the default one

=head1 DESCRIPTION

To create a patch, use C<commit -P> or C<smerge -P>.  To import a patch
that's sent to you by someone else, just drop it into the C<patch>
directory in your local svk repository. (That's usually C<~/.svk/>.)

svk patches are compatible with GNU patch. Extra svk-specific metadata
is stored in an encoded chunk at the end of the file.

A patch name of C<-> refers to the standard input and output.

=head1 INTRODUCTION

C<svk patch> command can help out on the situation where you want
to maintain your patchset to a given project.  It is used under the
situation that you have no direct write access to remote repository,
thus C<svk push> cannot be used.

Suppose you mirror project C<foo> to C<//mirror/foo>, create a local copy
on C<//local/foo>, and check out to C<~/dev/foo>. After you've done some
work, you type:

    svk commit -m "Add my new feature"

to commit changes from C<~/dev/foo> to C<//local/foo>. If you have commit
access to the upstream repository, you can submit your changes directly
like this:

    svk push //local/foo

Sometimes, it's useful to send a patch, rather than submit changes
directly, either because you don't have permission to commit to the
upstream repository or because you don't think your changes are ready
to be committed.

To create a patch containing the differences between C<//local/foo>
and C<//mirror/foo>, use this command:

    svk push -P Foo //local/foo

The C<-P> flag tells svk that you want to create a patch rather than
push the changes to the upstream repository.  C<-P> takes a single flag:
a patch name.  It probably makes sense to name it after the feature
implemented or bug fixed by the patch. Patch files you generate will be
created in the C<patch> subdirectory of your local svk repository.

Over time, other developers will make changes to project C<foo>. From
time to time, you may need to update your patch so that it still applies
cleanly. 

First, make sure your local branch is up to date with any changes made
upstream:

    svk pull //local/foo

Next, update your patch so that it will apply cleanly to the newest
version of the upstream repository:

    svk patch --update Foo

Finally, regenerate your patch to include other changes you've made on
your local branch since you created or last regenerated the patch:

    svk patch --regen Foo

To get a list of all patches your svk knows about, run:

    svk patch --list

To see the current version of a specific patch, run:
    
    svk patch --view Foo

When you're done with a patch and don't want it hanging around anymore,
run:
    svk patch --delete Foo

To apply a patch to the repository that someone else has sent you, run:

    svk patch --apply - < contributed_feature.patch

