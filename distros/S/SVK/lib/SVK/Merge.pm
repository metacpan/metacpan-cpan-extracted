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
package SVK::Merge;
use strict;
use SVK::Util qw(traverse_history is_path_inside);
use SVK::I18N;
use SVK::Merge::Info;
use SVK::Editor::Merge;
use SVK::Editor::Rename;
use SVK::Editor::Translate;
use SVK::Editor::Delay;
use SVK::Logger;
use List::Util qw(min);

=head1 NAME

SVK::Merge - Merge context class

=head1 SYNOPSIS

  use SVK::Merge;

  SVK::Merge->auto (repos => $repos, src => $src, dst => $dst)->run ($editor, %cb);

=head1 DESCRIPTION

The C<SVK::Merge> class is for representing merge contexts, mainly
including what delta is used for this merge, and what target the delta
applies to.

Given the 3 L<SVK::Path> objects:

=over

=item src

=item dst

=item base

=back

C<SVK::Merge> will be applying I<delta> (C<base>, C<src>) to C<dst>.

=head1 CONSTRUCTORS

=head2 new

Takes parameters the usual way.

=head2 auto

Like new, but the C<base> object will be found automatically as the
nearest ancestor of C<src> and C<dst>.

=head1 METHODS

=over

=cut

sub new {
    my ($class, @arg) = @_;
    my $self = bless {}, $class;
    %$self = @arg;
    return $self;
}

sub auto {
    my $self = new (@_);
    @{$self}{qw/base fromrev/} = $self->find_merge_base(@{$self}{qw/src dst/});

    return $self;
}

sub _rebase2 {
    my $self = shift;
    my ($src, $dst, $base) = @_;

    return unless $base->path eq $dst->path;

    $src->is_merged_from($base)
	or return;

    my $ddst = $src->prev or return;
    $ddst->root->check_path($ddst->path) or return;

    # If the previous source hasn't been merged, use the original base
    # logic.  Otherwise we are merging changes between the alleged
    # merge and actual revision.
    $dst->is_merged_from($ddst) or return;

    require SVK::Path::Txn;
    $ddst = $ddst->clone;
    bless $ddst, 'SVK::Path::Txn'; # XXX: need a saner api for this

    my $xmerge = SVK::Merge->auto(%$self, quiet => 1,
				  src => $base,
				  dst => $ddst);

    my ($editor, $inspector, %cb) = $xmerge->{dst}->get_editor();
    local $ENV{SVKRESOLVE} = 's';
    unless ($xmerge->run( $editor, inspector => $inspector, %cb )) {
	# XXX why isn't the txnroot uptodate??
        my $new_base = $xmerge->{dst};
	$new_base->inspector->root($new_base->txn->root($new_base->pool));
        return $new_base;
    }
    return;
}

# DEPRECATED
sub _is_merge_from {
    my ($self, $path, $target, $rev) = @_;
    my $fs = $self->{repos}->fs;
    my $u = $target->universal;
    my $resource = join (':', $u->{uuid}, $u->{path});
    local $@;
    Carp::cluck unless defined $rev;
    my ($merge, $pmerge) =
	map {SVK::Merge::Info->new (eval { $fs->revision_root ($_)->node_prop
					       ($path, 'svk:merge') })->{$resource}{rev} || 0}
	    ($rev, $rev-1);
    return ($merge != $pmerge) ? $merge : 0;
}

sub _next_is_merge {
    my ($self, $repos, $path, $rev, $checkfrom) = @_;
    return if $rev == $checkfrom;
    my $fs = $repos->fs;
    my $nextrev;

    (traverse_history (
        root     => $fs->revision_root ($checkfrom),
        path     => $path,
        cross    => 0,
        callback => sub {
            return 0 if ($_[1] == $rev); # last
            $nextrev = $_[1];
            return 1;
        }
    ) == 0) or return;

    return unless $nextrev;

    my ($merge, $pmerge) =
	map {$fs->revision_root ($_)->node_prop ($path, 'svk:merge') || ''}
	    ($nextrev, $rev);
    return if $merge eq $pmerge;
    return ($nextrev, $merge);
}

sub find_merge_base {
    my ($self, $src, $dst) = @_;
    my $repos = $self->{repos};
    my $fs = $repos->fs;
    my $yrev = $fs->youngest_rev;
    my ($srcinfo2, $dstinfo2) = map {$self->find_merge_sources2($_)} ($src, $dst);
    my $joint_info = $srcinfo2->intersect($dstinfo2)->resolve($src->depot);
    my ($basepath, $baserev, $baseentry);
    my ($merge_base, $merge_baserev) = $self->{merge_base} ?
	split(/:/, $self->{merge_base}) : ('', undef);
    die loc("Invalid merge base:'%1'\n", $self->{merge_base} )
	if $merge_baserev && $merge_baserev !~ /^\d+$/;
    ($merge_base, $merge_baserev) = (undef, $merge_base)
        if $merge_base =~ /^\d+$/;

    return ($src->as_depotpath->new
	    (path => $merge_base, revision => $merge_baserev, targets => undef),
	    $merge_baserev)
	if $merge_base && $merge_baserev;

    if ($merge_base) {
        my %allowed = map { ($_ =~ /:(.*)$/) => $_ } sort keys %$joint_info;

        unless ($allowed{$merge_base}) {
	    die loc("base '%1' is not allowed without revision specification.\nUse one of the next or provide revision:%2\n",
                $merge_base, (join '', map "\n    $_", sort keys %allowed) );
        }
	my $rev = $joint_info->{$allowed{$merge_base}};
	return ($src->as_depotpath->new
		(path => $merge_base, revision => $rev, targets => undef),
		$rev);
    }

    return ($src->new (revision => $merge_baserev), $merge_baserev)
        if $merge_baserev;

    my @preempt_result;

    for (sort keys %{$joint_info}) {
	my ($path) = m/:(.*)$/;
	my $rev = $joint_info->{$_};

        # if the candidate is condensed (like being part of a skip-to
        # sync), we can't really use it as base
        next if $rev == -1;

	# when the base is one of src or dst, make sure the base is
	# still the same node (not removed and replaced)
	if ($rev && $path eq $dst->path) {
	    next unless $dst->related_to($dst->as_depotpath->seek_to($rev));
	}
	if ($rev && $path eq $src->path) {
	    next unless $src->related_to($src->as_depotpath->seek_to($rev));
	}

        if (!$basepath || $fs->revision_prop($rev, 'svn:date') gt $fs->revision_prop($baserev, 'svn:date')) {
            ($basepath, $baserev, $baseentry) = ($path, $rev, $_);
            if ($path eq $dst->path &&
                $src->is_merged_from($dst->mclone(revision => $rev))) {

                my ($base, $from) = $self->_mk_base_and_from( $src, $dstinfo2, $basepath, $baserev );
                # this takes precedence than other potential base or
                # rebasable base that is on src.
                if (my $rebased = $self->_rebase2( $src, $dst, $base)) {
                    return ($rebased, $from);
                }
            }
            elsif ($path eq $src->path && $dst->is_merged_from($src->mclone(revision => $rev))) {
                my ($base, $from) = $self->_mk_base_and_from( $src, $dstinfo2, $basepath, $baserev );
                $base = $self->_rebase2( $dst, $src, $base) || $base;
                @preempt_result = ($base, $from);
            }
            else {
                @preempt_result = ();
            }
        }
    }

    return @preempt_result if @preempt_result;

    unless ($basepath) {
	return ($src->new (path => '/', revision => 0), 0)
	    if $self->{baseless};
	die loc("Can't find merge base for %1 and %2\n", $src->path, $dst->path);
    }

    # XXX: document this, cf t/07smerge-foreign.t
    if ($basepath ne $src->path && $basepath ne $dst->path) {
        my ($srcinfo, $dstinfo) = map {$self->find_merge_sources ($_)} ($src, $dst);

	my ($fromrev, $torev) = ($srcinfo->{$baseentry}, $dstinfo->{$baseentry});
	($fromrev, $torev) = ($torev, $fromrev) if $torev < $fromrev;
	if (my ($mrev, $merge) =
	    $self->_next_is_merge ($repos, $basepath, $fromrev, $torev)) {
	    my $minfo = SVK::Merge::Info->new ($merge);
	    my $root = $fs->revision_root ($yrev);
	    my ($srcinfo, $dstinfo) = map { SVK::Merge::Info->new ($root->node_prop ($_->path, 'svk:merge')) }
		($src, $dst);
	    $baserev = $mrev
		if $minfo->subset_of ($srcinfo) && $minfo->subset_of ($dstinfo);
	}
    }
    return $self->_mk_base_and_from( $src, $dstinfo2, $basepath, $baserev );
}

sub _mk_base_and_from {
    my $self = shift;
    my ($src, $dstinfo2, $basepath, $baserev) = @_;

    my $base = $src->as_depotpath->new
	(path => $basepath, revision => $baserev, targets => undef);
    $base->anchorify if exists $src->{targets}[0];
    $base->{path} = '/' if $base->revision == 0;

    # When /A:1 is copied to /B:2, then removed, /B:2 copied to /A:5
    # the fromrev shouldn't be /A:1, as it confuses the copy detection during merge.
    my $from = $dstinfo2->{$src->universal->ukey};
    $from = $from->local($src->depot)->revision if $from;
    if ($from) {
	my ($toroot, $fromroot) = $src->nearest_copy;
	$from = 0 if $toroot && $from < $toroot->revision_root_revision;
    }

    return ($base, $from || ($basepath eq $src->path ? $baserev : 0));
}

sub merge_info {
    my ($self, $target) = @_;
    my $tgt = $target->path_target;
    return SVK::Merge::Info->new
	( $target->inspector->localprop($tgt, 'svk:merge') );
}

sub merge_info_with_copy {
    my ($self, $target) = @_;
    my $minfo = $self->merge_info($target);

    for ($self->copy_ancestors($target)) {
	my $srckey = join(':', $_->{uuid}, $_->{path});
	$minfo->{$srckey} = $_
	    unless $minfo->{$srckey} && $minfo->{$srckey} > $_->{rev};
    }

    return $minfo;
}

sub copy_ancestors {
    my ($self, $target) = @_;

    $target = $target->as_depotpath;
    return map { $target->new
		     ( path => $_->[0],
		       targets => undef,
		       revision => $_->[1])->universal;
		   } $target->copy_ancestors;
}

sub find_merge_sources {
    my ($self, $target, $verbatim, $noself) = @_;
    my $pool = SVN::Pool->new_default;
    my $info = $self->merge_info ($target->new);

    $target = $target->new->as_depotpath ($self->{xd}{checkout}->get ($target->copath. 1)->{revision})
	if $target->isa('SVK::Path::Checkout');
    $info->add_target ($target, $self->{xd}) unless $noself;

    return $info->verbatim if $verbatim || !$target->root->check_path($target->path);
    my $minfo = $info->resolve($target->depot);

    my $myuuid = $target->repos->fs->get_uuid ();

    for (reverse $target->copy_ancestors) {
	my ($path, $rev) = @$_;
	my $entry = "$myuuid:$path";
	$minfo->{$entry} = $rev
	    unless $minfo->{$entry} && $minfo->{$entry} > $rev;
    }

    return $minfo;
}

sub find_merge_sources2 {
    my ($self, $target) = @_;
    my $pool = SVN::Pool->new_default;
    my $info = $self->merge_info ($target->new);

    $target = $target->new->as_depotpath ($self->{xd}{checkout}->get ($target->copath. 1)->{revision})
	if $target->isa('SVK::Path::Checkout');
    $info->add_target($target);

    return $info if !$target->root->check_path($target->path);

    for (reverse $target->copy_ancestors) {
	my ($path, $rev) = @$_;
        # XXX: short circuit it when we have the ancestor already.
        my $t = $target->mclone( targets => undef, path => $path, revision => $rev)->universal;
        $info->add_target( $t )
            if !$info->{ $t->ukey } || $info->{ $t->ukey }->rev < $t->rev;
    }
    return $info;
}

sub _get_new_ticket {
    my ($self, $srcinfo) = @_;
    my $dstinfo = $self->merge_info($self->{dst});
    # We want the ticket representing src, but not dst.
    return $dstinfo->union ($srcinfo)->del_target($self->{dst});
}

# deprecated
sub get_new_ticket {
    my ($self, $srcinfo) = @_;
    my $newinfo = $self->_get_new_ticket($srcinfo);
    $self->print_new_ticket($newinfo);
    return $newinfo->as_string;
}

sub print_new_ticket {
    my ($self, $dstinfo, $newinfo) = @_;
    for (sort keys %$newinfo) {
	$logger->info(loc("New merge ticket: %1:%2", $_, $newinfo->{$_}{rev}))
	    if !$dstinfo->{$_} || $newinfo->{$_}{rev} > $dstinfo->{$_}{rev};
    }
}

sub log {
    my ($self, $no_separator) = @_;
    open my $buf, '>', \ (my $tmp = '');
    no warnings 'uninitialized';

    require Sys::Hostname;
    my $get_remoterev = SVK::Command::Log::_log_remote_rev(
            $self->{src},
            $self->{remoterev}
    );
    my $host = $self->{host} || (split ('\.', Sys::Hostname::hostname(), 2))[0];

    require SVK::Log::FilterPipeline;
    my $pipeline = SVK::Log::FilterPipeline->new(
        presentation  => 'std',
        output        => $buf,
        indent        => 1,
        remote_only   => $self->{remoterev},
        host          => $host,
        get_remoterev => $get_remoterev,
        no_sep        => $no_separator,
        verbatim      => $self->{verbatim} ? 1 : 0,
        quiet         => 0,
        suppress      => sub {
            $self->_is_merge_from ($self->{src}->path, $self->{dst}, $_[0])
        },
    );

    SVK::Command::Log::do_log(
        repos   => $self->{repos},
        path    => $self->{src}->path,
        fromrev => $self->{fromrev} + 1,
        torev   => $self->{src}->revision,
        pipeline => $pipeline,
    );
    return $tmp;
}

=item info

Return a string about how the merge is done.

=cut

sub info {
    my $self = shift;
    return loc("Auto-merging (%1, %2) %3 to %4 (base %5%6:%7).\n",
	       $self->{fromrev}, $self->{src}->revision, $self->{src}->path,
	       $self->{dst}->path,
	       $self->{base}->isa('SVK::Path::Txn') ? '*' : '',
           $self->{base}->path,
           $self->{base}->revision,
    );
}

sub _collect_renamed {
    my ($renamed, $pathref, $reverse, $rev, $root, $props) = @_;
    my $entries;
    my $path = $$pathref;
    my $paths = $root->paths_changed();
    for (keys %$paths) {
	my $entry = $paths->{$_};
	require SVK::Command;
	my $action = $SVK::Command::Log::chg->[$entry->change_kind];
	$entries->{$_} = [$action , $action eq 'D' ? (-1) : $root->copied_from ($_)];
	# anchor is copied
	if ($action eq 'A' && $entries->{$_}[1] != -1 &&
	    (is_path_inside($path, $_))) {
	    $path =~ s/^\Q$_\E/$entries->{$_}[2]/;
	    $$pathref = $path;
	}
    }
    for (keys %$entries) {
	my $entry = $entries->{$_};
	my $from = $entry->[2] or next;
	if (exists $entries->{$from} && $entries->{$from}[0] eq 'D') {
	    s|^\Q$path\E/|| or next;
	    $from =~ s|^\Q$path\E/|| or next;
	    push @$renamed, $reverse ? [$from, $_] : [$_, $from];
	}
    }
}

sub _collect_rename_for {
    my ($self, $renamed, $target, $base, $reverse) = @_;
    my $path = $target->path;
    SVK::Command::Log::do_log(
        repos   => $target->repos,
        path    => $path,
        torev   => $base->revision + 1,
        fromrev => $target->revision,
        cb_log  => sub { _collect_renamed( $renamed, \$path, $reverse, @_ ) }
    );
}

sub track_rename {
    my ($self, $editor, $cb) = @_;

    my ($base) = $self->find_merge_base (@{$self}{qw/base dst/});
    my ($renamed, $path) = ([]);

    print "Collecting renames, this might take a while.\n";
    $self->_collect_rename_for($renamed, $self->{base}, $base, 0)
	unless $self->{track_rename} eq 'dst';

    { # different base lookup logic for smerge
	if ($self->{track_rename} eq 'dst') {
	    my $usrc = $self->{src}->universal;
	    my $dstkey = $self->{dst}->universal->ukey;
	    my $srcinfo = $self->merge_info_with_copy($self->{src}->new);

	    if ($srcinfo->{$dstkey}) {
		$base = $srcinfo->{$dstkey}->local($self->{src}->depot);
	    }
	    else {
		$base = $base->mclone(revision => 0);
	    }
	}
	$self->_collect_rename_for($renamed, $self->{dst}, $base, 1);
    }

    return $editor unless @$renamed;

    my $rename_editor = SVK::Editor::Rename->new (editor => $editor, rename_map => $renamed);
    return $rename_editor;
}

=item run

Given the storage editor and L<SVK::Editor::Merge> callbacks, apply
the merge to the storage editor. Returns the number of conflicts.

=back

=cut

sub run {
    my ($self, $storage, %cb) = @_;
    my ($base, $src) = @{$self}{qw/base src/};
    my $base_root = $self->{base_root} || $base->root;
    # XXX: for merge editor; this should really be in SVK::Path
    my ($report, $target) = ($self->{report}, $src->path_target);
    my $dsttarget = $self->{dst}->path_target;
    my $is_copath = $self->{dst}->isa('SVK::Path::Checkout');
    my $notify_target = defined $self->{target} ? $self->{target} : $target;
    my $notify = $self->{notify} || SVK::Notify->new_with_report
	($report, $notify_target, $is_copath);
    $notify->{quiet} = 1 if $self->{quiet};
    my $translate_target;
    if ($target && $dsttarget && $target ne $dsttarget) {
	$translate_target = sub { $_[0] =~ s/^\Q$target\E/$dsttarget/ };
	$storage = SVK::Editor::Translate->new (_editor => [$storage],
						translate => $translate_target);
	# if there's notify_target, the translation is done by svk::notify
	$notify->notify_translate ($translate_target) unless length $notify_target;
    }
    $storage = SVK::Editor::Delay->new ($storage)
	unless $self->{nodelay};
    $storage = $self->track_rename ($storage, \%cb)
	if $self->{track_rename};

    # XXX: this should be removed when cmerge is gone. also we should
    # use the inspector of the txn we are working on, rather than of
    # the (static) target

    # $cb{inspector} = $self->{dst}->inspector
    # unless ref($cb{inspector}) eq 'SVK::Inspector::Compat' ;

    my $dstinfo = $self->merge_info($self->{dst});

    my %ticket_options;
    if ( $self->{ticket} ) {
        $ticket_options{prop_resolver} = {
            'svk:merge' => sub {
                my ($path, $prop) = @_;
		return (undef, undef, 1)
		    if $path eq $target;
		return ('G', SVK::Merge::Info->new($prop->{new})
                    ->union(SVK::Merge::Info->new ($prop->{local}))
                    ->as_string
                );
	    },
	};
	$ticket_options{ticket} = $self->_get_new_ticket(
            $self->merge_info_with_copy($src)->add_target($src)
        );
        $ticket_options{cb_merged} = sub {
            my ($changes, $type, $ticket) = @_;
            if (!$changes) { # rollback all ticket
                my $func = "change_${type}_prop";
                my $baton = $storage->open_root ($cb{cb_rev}->($cb{target}||''));
                $storage->$func( $baton, 'svk:merge', undef );
                return;
            }
            $self->print_new_ticket( $dstinfo, $ticket ) unless $self->{quiet};
	};
    } else {
        $ticket_options{prop_resolver} = {
            'svk:merge' => sub { return ('G', undef, 1) },
        };
    }

    my $meditor = SVK::Editor::Merge->new
	( anchor => $src->path_anchor,
	  repospath => $src->repospath, # for stupid copyfrom url
	  static_inspector => $self->{dst}->inspector,
	  base_anchor => $base->path_anchor,
	  base_root => $base_root,
	  target => $target,
	  storage => $storage,
	  notify => $notify,
	  g_merge_no_a_change => ($src->path ne $base->path),
	  # if storage editor is E::XD, applytext_delta returns undef
	  # for failed operations, and merge editor should mark them as skipped
	  storage_has_unwritable => $is_copath && !$self->{check_only},
	  allow_conflicts => $is_copath,
	  resolve => $self->resolver,
	  open_nonexist => $self->{track_rename},
	  # XXX: make the prop resolver more pluggable
          %ticket_options,
	  %cb,
	);

    $meditor->inspector_translate($translate_target)
	if $translate_target;

    my $editor = $meditor;
    if ($self->{notice_copy}) {
	my $dstinfo = $self->merge_info_with_copy($self->{dst}->new);
	my $srcinfo = $self->merge_info_with_copy($self->{src}->new);

	my $boundry_rev;
	if ($self->{base}->path eq $self->{src}->path) {
	    $boundry_rev = $self->{base}->revision;
	}
	else {
	    my $usrc = $src->universal;
	    my $srckey = join(':', $usrc->{uuid}, $usrc->{path});
	    if ($dstinfo->{$srckey}) {
                # find which rev on src is merged from the base.
		$boundry_rev = $src->merged_from
		    ($self->{base}, $self, $self->{base}{path});
                # however if src is removed and later copied again
                # from base, we need the later one as boundry
                my $t = $src;
                while (my ($toroot, $fromroot, $path) = $t->nearest_copy) {
                    if ($path eq $self->{base}->path_anchor) {
                        $boundry_rev = List::Util::max( grep { defined $_ } $boundry_rev, $toroot->revision_root_revision );
                    }
                    $t = $t->mclone( path => $path, revision => $fromroot->revision_root_revision );
                }
	    }
	    else {
		# when did the branch first got created?
		$boundry_rev = $src->search_revision
		    ( cmp => sub {
			  my $rev = shift;
			  my $root = $src->mclone(revision => $rev)->root(undef);
			  return $root->node_history($src->path)->prev(0)->prev(0) ? 1 : 0;
		      }) or die loc("Can't find the first revision of %1.\n", $src->path);
	    }
	}
	$logger->debug("==> got $boundry_rev as copyboundry, add $self->{fromrev} as boundry as well");

	if (defined $boundry_rev) {
	  require SVK::Editor::Copy;
	  $editor = SVK::Editor::Copy->new
	    ( _editor => [$meditor],
	      merge => $self, # XXX: just for merge_from, move it out
	      copyboundry_rev => [$boundry_rev, $self->{fromrev}],
	      copyboundry_root => $self->{repos}->fs->revision_root($boundry_rev
),
	      src => $src,
	      dst => $self->{dst},
	      cb_query_copy => sub {
		  my ($from, $rev) = @_;
		  return @{$meditor->{copy_info}{$from}{$rev}};
	      },
	      cb_resolve_copy => sub {
		  my $path = shift;
		  my $replace = shift;
		  my ($src_from, $src_fromrev) = @_;
		  # If the target exists, don't use copy unless it's a
		  # replace, because merge editor can't handle it yet.
		  return if !$replace && $self->{dst}->inspector->exist($path);

		  my ($dst_from, $dst_fromrev) =
		      $self->resolve_copy($srcinfo, $dstinfo, @_);
		  return unless defined $dst_from;
		  # ensure the dst from path exists
		  my $dst_path = SVK::Path->real_new({depot => $self->{dst}->depot, path => $dst_from, revision => $dst_fromrev});
		  return unless $dst_path->root->check_path($dst_path->path);
		  $dst_path->normalize;
		  # Because the delta still need to carry the copy
		  # information of the source, make merge editor note
		  # the mapping so it can do the translation
		  ($dst_from, $dst_fromrev) =
		      ($dst_path->path, $dst_path->revision);
		  $meditor->copy_info($src_from, $src_fromrev,
				      $dst_from, $dst_fromrev);

		  return ($dst_from, $dst_fromrev);
	      } );
	  $editor = SVK::Editor::Delay->new ($editor);
	}
    }

    SVK::XD->depot_delta
	    ( oldroot => $base_root, newroot => $src->root,
	      oldpath => [$base->path_anchor, $base->path_target],
	      newpath => $src->path,
#	      pool => SVN::Pool->new,
	      no_recurse => $self->{no_recurse}, editor => $editor,
	    );
    unless ($self->{quiet}) {
	$logger->warn(loc("%*(%1,conflict) found.", $meditor->{conflicts}))
	    if $meditor->{conflicts};
	$logger->warn(loc("%*(%1,file) skipped, you might want to rerun merge with --track-rename.",
		  $meditor->{skipped})) if $meditor->{skipped} && !$self->{track_rename} && !$self->{auto};
    }

    return $meditor->{conflicts};
}

 # translate to (path, rev) for dst
sub resolve_copy {
    my ($self, $srcinfo, $dstinfo, $cp_path, $cp_rev) = @_;
    $logger->debug("==> to resolve $cp_path $cp_rev");
    my $path = $cp_path;
    my $src = $self->{src};
    my $srcpath = $src->path;
    my $dstpath = $self->{dst}->path;
    return ($cp_path, $cp_rev) if $path =~ m{^\Q$dstpath/};
    my $cpsrc = $src->new( path => $path,
			   revision => $cp_rev );
    if ($path !~ m{^\Q$srcpath/}) {
	# if the copy source is not within the merge source path, only
	# allows using the copy if they are both not mirrored
	return !$src->is_mirrored && !$cpsrc->is_mirrored ?
	    ($cp_path, $cp_rev) : ();
    }

    $path =~ s/^\Q$srcpath/$dstpath/;
    $cpsrc->normalize;
    $cp_rev = $cpsrc->revision;
    # now the hard part, reoslve the revision
    my $usrc = $src->universal;
    my $srckey = join(':', $usrc->{uuid}, $usrc->{path});
    my $udst = $self->{dst}->universal;
    my $dstkey = join(':', $udst->{uuid}, $udst->{path});
    unless ($dstinfo->{$srckey}) {
	return $srcinfo->{$dstkey}{rev} ?
	    ($path, $srcinfo->{$dstkey}->local($self->{dst}->depot)->revision) : ();
    }
    if ($dstinfo->{$srckey}->local($self->{dst}->depot)->revision < $cp_rev) {
	# same as re-base in editor::copy
	my $rev = $self->{src}->merged_from
	    ($self->{base}, $self, $self->{base}->path_anchor);

	return unless defined $rev;
	$rev = $self->merge_info_with_copy(
	  $self->{src}->mclone(revision => $rev)
        )->{$dstkey}
         ->local($self->{dst}->depot)
         ->revision;

	return ($path, $rev);
    }
    # XXX: get rid of the merge context needed for
    # merged_from(); actually what the function needs is
    # just XD
    my $rev = $self->{dst}->
	merged_from($src->new(revision => $cp_rev),
		    $self, $cp_path);

    return ($path, $rev) if defined $rev;
    return;
}

sub resolver {
    return undef if $_[0]->{check_only};
    require SVK::Resolve;
    return SVK::Resolve->new (action => $ENV{SVKRESOLVE},
			      external => $ENV{SVKMERGE});
}

=head1 TODO

Document the merge and ticket tracking mechanism.

=head1 SEE ALSO

L<SVK::Editor::Merge>, L<SVK::Command::Merge>, L<SVK::Merge::Info>, Star-merge
from GNU Arch

=cut

1;
