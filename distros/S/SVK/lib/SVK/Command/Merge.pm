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
package SVK::Command::Merge;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base qw( SVK::Command::Commit );
use SVK::XD;
use SVK::I18N;
use SVK::Command::Log;
use SVK::Logger;
use SVK::Merge;
use SVK::Util qw( get_buffer_from_editor traverse_history tmpfile );

sub options {
    ($_[0]->SUPER::options,
     'a|auto'		=> 'auto',
     'l|log'		=> 'log',
     'summary'		=> 'summary',
     'remoterev'	=> 'remoterev',
     'track-rename'	=> 'track_rename',
     'host=s'   	=> 'host',
     'I|incremental'	=> 'incremental',
     'verbatim'		=> 'verbatim',
     'no-ticket'	=> 'no_ticket',
     'r|revision=s@'	=> 'revspec',
     'c|change=s',	=> 'chgspec',
     't|to'             => 'to',
     'f|from'           => 'from',
     's|sync'           => 'sync');
}

sub parse_arg {
    my ($self, @arg) = @_;
    return if $#arg > 1;

    if (!$self->{to} && !$self->{from}) {
        return if scalar (@arg) == 0;
	my ($src, $dst) = ($self->arg_depotpath ($arg[0]), $self->arg_co_maybe ($arg[1] || ''));
	die loc("Can't merge across depots.\n") unless $src->same_repos ($dst);
        return ($src, $dst);
    }

    if (scalar (@arg) == 2) {
        die loc("Cannot specify 'to' or 'from' when specifying a source and destination.\n");
    }

    if ($self->{to} && $self->{from}) {
        die loc("Cannot specify both 'to' and 'from'.\n");
    }

    my $target1 = $self->arg_co_maybe (@arg ? $arg[0] : '');
    my $target2;

    if ($self->{from}) {
        # When using "from", $target1 must always be a depotpath.
        if ($target1->isa('SVK::Path::Checkout')) {
            # Because merging under the copy anchor is unsafe, we always merge
            # to the most immediate copy anchor under copath root.
            ($target1, $target2) = $self->find_checkout_anchor (
                $target1, 1, $self->{sync}
               );
	    $target1 = $target1->as_depotpath;
        }
    }

    $target2 ||= $target1->copied_from($self->{sync});
    if (!defined ($target2)) {
        die loc ("Cannot find the path which '%1' copied from.\n", $arg[0] || '');
    }
    return ( ($self->{from}) ? ($target1, $target2) : ($target2, $target1) );
}

sub lock {
    my $self = shift;
    $self->lock_target($_[1]) if $_[1];
}

sub get_commit_message {
    my ($self, $log) = @_;
    return if $self->{check_only} || $self->{incremental};
    $self->SUPER::get_commit_message ($log);
}

sub run {
    my ($self, $src, $dst) = @_;
    my $merge;
    my $repos = $src->repos;

    if (my @mirrors = $dst->contains_mirror) {
	die loc ("%1 can not be used as merge target, because it contains mirrored path: ", $dst->report)
	    .join(",", @mirrors)."\n"
		unless $mirrors[0] eq $dst->path;
    }

    if ($self->{sync}) {
        my $sync = $self->command ('sync');
	if (my $m = $src->is_mirrored) {
            $sync->run($self->arg_depotpath('/' . $src->depotname .  $m->path));
            $src->refresh_revision;
        }
    }

    if ($dst->root->check_path($dst->path) != $SVN::Node::dir) {
	$src->anchorify; $dst->anchorify;
    }

    # for svk::merge constructor
    # Report only relative for depot / depot merge, but what user
    # types for merge to checkout
    $self->{report} = $dst->isa('SVK::Path::Checkout') ? $dst->report : undef;
    if ($self->{auto}) {
	die loc("Can't merge with specified revisions with smart merge.\n")
	    if defined $self->{revspec} || defined $self->{chgspec};
	# Tell svk::merge to only collect for dst.  There must be
	# better ways doing this.
	$self->{track_rename} = 'dst'
	    if $self->{track_rename};
	++$self->{no_ticket} if $self->{patch};
	# avoid generating merge ticket pointing to other changes
	$src->normalize; $dst->normalize;
	$merge = SVK::Merge->auto (%$self, repos => $repos, target => '',
				   ticket => !$self->{no_ticket},
				   src => $src, dst => $dst);
	$logger->info( $merge->info);
	$logger->info( $merge->log(1)) if $self->{summary};
    }
    else {
	die loc("Incremental merge not supported\n") if $self->{incremental};
	my @revlist = $self->parse_revlist($src);
	die "multi-merge not yet" if $#revlist > 0;
	my ($baserev, $torev) = @{$revlist[0]};
	die loc("Merge requires a range of revision.\n")
	    unless defined $baserev && defined $torev;
	$merge = SVK::Merge->new
	    (%$self, repos => $repos, src => $src->new (revision => $torev),
	     dst => $dst,
	     base => $src->new (revision => $baserev), target => '',
	     fromrev => $baserev);
    }

    $merge->{notice_copy} = 1;
    if ($merge->{fromrev} == $merge->{src}->revision) {
	$logger->info( loc ("Empty merge."));
	return;
    }

    # for checkouts we save later into a file
    $self->get_commit_message ($self->{log} ? $merge->log(1) : undef)
	unless $dst->isa('SVK::Path::Checkout');

    if ($self->{incremental}) {
	die loc ("Not possible to do incremental merge without a merge ticket.\n")
	    if $self->{no_ticket};
	$logger->info( loc ("-m ignored in incremental merge")) if $self->{message};
	my @rev;

        traverse_history (
            root        => $src->root,
            path        => $src->path_anchor,
            cross       => -1,
            callback    => sub {
                my $rev = $_[1];
                return 0 if $rev <= $merge->{fromrev}; # last
                unshift @rev, $rev;
                return 1;
            },
        );
	my $spool = SVN::Pool->new_default;
	my $previous_base;
	if ($self->{check_only}) {
	    require SVK::Path::Txn;
	    $merge->{dst} = $dst = $dst->clone;
	    bless $dst, 'SVK::Path::Txn'; # XXX: need a saner api for this
	}
	foreach my $rev (@rev) {
	    $merge = SVK::Merge->auto(%$merge,
				      src => $src->new(revision => $rev));
	    if ($previous_base) {
		$merge->{fromrev} = $previous_base;
	    }

	    $logger->info( '===> '.$merge->info);
	    $self->{message} = $merge->log (1);
	    $self->decode_commit_message;

	    last if $merge->run( $self->get_editor($dst) );
	    # refresh dst
	    $dst->refresh_revision;
	    $previous_base = $rev;
	    $spool->clear;
	}
    }
    else {
	$merge->run ($self->get_editor ($dst, undef, $self->{auto} ? $src : undef));
	delete $self->{save_message};
    }

    if ( $self->{log} && !$self->{check_only} && $dst->isa('SVK::Path::Checkout') ) {
        my ($fh, $file) = tmpfile ('commit', DIR => '', TEXT => 1, UNLINK => 0);
        print $fh $merge->log(1);
        $logger->warn(loc ("Log message saved in %1.", $file));
    }

    return;
}

1;

__DATA__

=head1 NAME

SVK::Command::Merge - Apply differences between two sources

=head1 SYNOPSIS

 merge -r N:M DEPOTPATH [PATH]
 merge -r N:M DEPOTPATH1 DEPOTPATH2
 merge -r N:M [--to|--from] [PATH]

=head1 OPTIONS

 -r [--revision] N:M    : act on revisions between N and M
 -c [--change] N        : act on change N (between revisions N-1 and N)
                          using -N reverses the changes made in revision N
 -I [--incremental]     : apply each change individually
 -a [--auto]            : merge from the previous merge point
 -l [--log]             : use logs of merged revisions as commit message
 -s [--sync]            : synchronize mirrored sources before operation
 -t [--to]              : merge to the specified path
 -f [--from]            : merge from the specified path
 --summary              : display related logs in this merge
 --verbatim             : verbatim merge log without indents and header
 --no-ticket            : do not record this merge point
 --track-rename         : track changes made to renamed node
 -m [--message] MESSAGE : specify commit message MESSAGE
 -F [--file] FILENAME   : read commit message from FILENAME
 --template             : use the specified message as the template to edit
 --encoding ENC         : treat -m/-F value as being in charset encoding ENC
 -P [--patch] NAME      : instead of commit, save this change as a patch
 -S [--sign]            : sign this change
 -C [--check-only]      : try operation but make no changes
 --direct               : commit directly even if the path is mirrored

