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
package SVK::Command::Update;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command );
use constant opt_recursive => 1;
use SVK::XD;
use SVK::I18N;
use SVK::Logger;

sub options {
    ('r|revision=s'    => 'rev',
     's|sync'          => 'sync',
     'm|merge'         => 'merge',
     'q|quiet'         => 'quiet',
     'C|check-only'    => 'check_only',
     'I|incremental'   => 'incremental', # -- XXX unsafe -- undocumented XXX --
    );
}

sub parse_arg {
    my ($self, @arg) = @_;
    @arg = ('') if $#arg < 0;
    return map {$self->arg_copath ($_)} @arg;
}

sub lock {
    my ($self, @arg) = @_;
    $self->lock_target ($_) for @arg;
}

sub run {
    my ($self, @arg) = @_;

    die loc ("--check-only cannot be used in conjunction with --merge.\n")
        if defined $self->{check_only} && $self->{merge};

    die loc ("--revision cannot be used in conjunction with --sync or --merge.\n")
	if defined $self->{rev} && ($self->{merge} || $self->{sync});

    die loc("Non-recursive update not supported.\n")
	unless $self->{recursive};

    for my $target (@arg) {
	my $update_target = $target->source->new;
	$update_target->path($self->{update_target_path})
	    if defined $self->{update_target_path};

	my $rev = defined $self->{rev} ?
	    $self->resolve_revision($target->new,$self->{rev}) :
	    $target->repos->fs->youngest_rev;

	if ($update_target->isa('SVK::Path::View')) {
	    # always use the latest view layout
	    $update_target->refresh_revision;
	    $update_target->source->revision($rev);
	}
        else {
	    $update_target->revision($rev);
	}

        # Because merging under the copy anchor is unsafe, we always merge
        # to the most immediate copy anchor under copath root.
        my ($merge_target, $copied_from) = $self->find_checkout_anchor (
            $target, $self->{merge}, $self->{sync}
        );

        my $sync_target = $copied_from || $merge_target;
        delete $self->{merge} if !$copied_from;

        if ($self->{sync}) {
            # Because syncing under the mirror anchor is impossible,
            # we always sync from the mirror anchor.
            my $m = $sync_target->is_mirrored;
            $m->run if $m;
        }

        if ($self->{merge}) {
            $self->command (
                smerge => {
                    ($self->{incremental} ? () : (message => '', log => 1)),
                    %$self, sync => 0,
                }
            )->run (
                $merge_target->copied_from($self->{sync}) => $merge_target
            );
        }
	$update_target->refresh_revision if $self->{sync} || $self->{merge};

	$self->do_update ($target, $update_target);
    }
    return;
}

sub do_update {
    my ($self, $cotarget, $update_target) = @_;
    my $pool = SVN::Pool->new_default;
    my $xdroot = $cotarget->create_xd_root;
    my $newroot = $update_target->root;
    # unanchorified
    my $report = $cotarget->report;
    my $kind = $newroot->check_path ($update_target->path);
    if ($kind == $SVN::Node::none) {
	# if update target doesn't exist, only allows updating from
	# something that exist.
	die loc("Path %1 does not exist.\n", $update_target->depotpath)
	    unless $xdroot->check_path($cotarget->path);
	$cotarget->anchorify;
	# still in the checkout
	if ($self->{xd}{checkout}->get($cotarget->copath)->{depotpath}) {
	    $update_target->anchorify;
	    $kind = $newroot->check_path($update_target->path_anchor);
	}
	else {
	    die loc("Path %1 no longer exists.\n", $update_target->depotpath);
	}
    }

    my $content_revision = $update_target->isa('SVK::Path::View') ?
	$update_target->source->revision : $update_target->revision;
    $logger->info(loc("Syncing %1(%2) in %3 to %4.", $cotarget->depotpath,
	      $cotarget->path_anchor, $cotarget->copath,
	      $content_revision));

    if ($kind == $SVN::Node::file ) {
	$cotarget->anchorify;
	$update_target->anchorify;
	# can't use $cotarget->{path} directly since the (rev0, /) hack
	$cotarget->source->{targets}[0] = $cotarget->{copath_target};
    }
    my $base = $cotarget->as_depotpath;
    $base = $base->new(path => '/')
	if $xdroot->check_path ($base->path) == $SVN::Node::none;

    unless (-e $cotarget->copath) {
	die loc ("Checkout directory gone. Use 'checkout %1 %2' instead.\n",
		 $update_target->depotpath, $cotarget->report)
	    unless $base->path_anchor eq '/';
	mkdir ($cotarget->copath) or
	    die loc ("Can't create directory %1 for checkout: %2.\n", $cotarget->report, $!);
    }

    my $notify = SVK::Notify->new_with_report
	($report, $cotarget->path_target, 1);
    $notify->{quiet}++ if $self->{quiet};
    my $merge = SVK::Merge->new
	(repos => $cotarget->repos, base => $base, base_root => $xdroot,
	 no_recurse => !$self->{recursive}, notify => $notify, nodelay => 1,
	 src => $update_target, dst => $cotarget, check_only => $self->{check_only},
	 auto => 1, # not to print track-rename hint
	 xd => $self->{xd},
    );
    my ($editor, $inspector, %cb) = $cotarget->get_editor
	( ignore_checksum => 1,
	  check_only => $self->{check_only},
	  store_path => $update_target->path_anchor,
	  update => $self->{check_only} ? 0 : 1,
	  newroot => $newroot,
	  revision => $content_revision,
	);
    $cb{'prop_resolver'}{'svk:merge'} = sub {
        my ($path, $prop) = @_;
        my %info;
        $info{$_} = SVK::Merge::Info->new($prop->{$_}) foreach (qw(base local new));
        return ('G', undef, 1) if $info{local}->is_equal($info{base});
        return ('g', $info{new}->as_string) if $info{local}->is_equal($info{new});
        return ('G', $info{new}->union($info{local})->as_string);
    };
    $merge->run($editor, %cb, inspector => $inspector);

    if ($update_target->isa('SVK::Path::View')) {
	$self->{xd}{checkout}->store
	    ($cotarget->copath,
	     {depotpath => $update_target->depotpath});
    }
}

1;

__DATA__

=head1 NAME

SVK::Command::Update - Bring changes from repository to checkout copies

=head1 SYNOPSIS

 update [PATH...]

=head1 OPTIONS

 -r [--revision] REV    : act on revision REV instead of the head revision
 -N [--non-recursive]   : do not descend recursively
 -C [--check-only]      : try operation but make no changes
 -s [--sync]            : synchronize mirrored sources before update
 -m [--merge]           : smerge from copied sources before update
 -q [--quiet]           : print as little as possible

=head1 DESCRIPTION

Synchronize checkout copies to revision given by -r or to HEAD
revision by default.

For each updated item a line will start with a character reporting the
action taken. These characters have the following meaning:

  A  Added
  D  Deleted
  U  Updated
  C  Conflict
  G  Merged
  g  Merged without actual change

A character in the first column signifies an update to the actual
file, while updates to the file's props are shown in the second
column.

If both C<--sync> and C<--merge> are specified, like in C<svk up -sm>,
it will first synchronize the mirrored copy source path, and then smerge
from it.

