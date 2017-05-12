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
package SVK::Editor::Merge;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;

use base 'SVK::Editor';
use SVK::I18N;
use SVK::Logger;
use autouse 'SVK::Util'
    => qw( slurp_fh md5_fh tmpfile devnull abs2rel );

__PACKAGE__->mk_accessors(qw(inspector static_inspector notify storage ticket cb_merged));

use Class::Autouse qw(SVK::Inspector::Root SVK::Notify
		      Data::Hierarchy IO::Digest);

use constant FH => 0;
use constant FILENAME => 1;
use constant CHECKSUM => 2;

=head1 NAME

SVK::Editor::Merge - An editor that does merges for the storage editor

=head1 SYNOPSIS

  $editor = SVK::Editor::Merge->new
    ( anchor => $anchor,
      base_anchor => $base_anchor,
      base_root => $fs->revision_root ($arg{fromrev}),
      target => $target,
      storage => $storage_editor,
      %cb,
    );


=head1 DESCRIPTION

Given the base root and callbacks for local tree, SVK::Editor::Merge
forwards the incoming editor calls to the storage editor for modifying
the local tree, and merges the tree delta and text delta
transparently.

=head1 PARAMETERS

=head2 options for base and target tree

=over

=item anchor

The anchor of the target tree.

=item target

The target path component of the target tree.

=item base_anchor

The anchor of the base tree.

=item base_root

The root object of the base tree.

=item storage

The editor that will receive the merged callbacks.

=item allow_conflicts

Close the editor instead of abort when there are conflicts.

=item open_nonexist

open the directory even if cb_exist failed. This is for use in
conjunction with L<SVK::Editor::Rename> for the case that a descendent
exists but its parent does not.

=item inspector

The inspector reflecting the target of the merge.

=back

=head2 callbacks for local tree

Since the merger needs to have information about the local tree, some
callbacks must be supplied.

=over

=item cb_rev

Check the revision of the given path.

=item cb_conflict

When a conflict is detected called with path and conflict
type as argument. At this point type can be either 'node' or
'prop'.

=item cb_prop_merged

Called when properties are merged without changes, that is, the C<g>
status.

=item cb_merged

Called right before closing the target with changes flag, node type and
ticket.

=item cb_closed

Called after each file close call.

=back

=cut

use Digest::MD5 qw(md5_hex);
use File::Compare ();

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(ref $_[0] ? @_ :{@_});

    if ($self->storage->can('rename_check')) {
	my $editor = $self->storage;
	$self->inspector_translate
	    (sub { $_[0] = $editor->rename_check($_[0])});

	my $flush = $self->notify->{cb_flush};
	$self->notify->{cb_flush} = sub {
	    my ($path, $st) = @_;
	    my $newpath = $self->storage->rename_check($path);
	    $flush->($path, $st, $path eq $newpath ? undef : $newpath) };
    }

    return $self;
}

sub cb_for_root {
    my ($class, $root, $anchor, $base_rev) = @_;
    # XXX $root and $anchor are actually SVK::Path
    my $inspector = SVK::Inspector::Root->new({
        root => $root, 
        anchor => $anchor, 
    });

    return (
        inspector => $inspector,
        cb_rev => sub { $base_rev },
    );
}

sub inspector_translate {
    my ($self, $translate) = @_;
    # XXX: should do a real clone and then push
    $self->inspector($self->inspector->new($self->inspector));
    $self->inspector->path_translations([]);
    $self->inspector->push_translation($translate);
    for (qw/cb_conflict/) {
        my $sub = $self->{$_};
        next unless $sub;
        $self->{$_} = sub { my $path = shift; $translate->($path);
			    unshift @_, $path; goto &$sub };
    }
}

sub copy_info {
    my ($self, $src_from, $src_fromrev, $dst_from, $dst_fromrev) = @_;
    $self->{copy_info}{$src_from}{$src_fromrev} = [$dst_from, $dst_fromrev];
}

sub set_target_revision {
    my ($self, $revision) = @_;
    $self->{revision} = $revision;
    $self->{storage}->set_target_revision ($revision);
}

sub set_ticket {
    my ($self, $baton, $type, $pool) = @_;

    my $func = "change_${type}_prop";

    $self->{storage}->$func( $baton, 'svk:merge', $self->ticket->as_string, $pool );

}

sub open_root {
    my ($self, $baserev, $pool) = @_;
    $self->{baserev} = $baserev;
    $self->{notify} ||= SVK::Notify->new_with_report ($self->{report}, $self->{target});
    $self->{storage_baton}{''} =
	$self->{storage}->open_root ($self->{cb_rev}->($self->{target}||''));
    $self->{notify}->node_status ('', '');

    $self->{dh} = Data::Hierarchy->new;

    $self->set_ticket($self->{storage_baton}{''}, 'dir', $pool)
	if !length $self->{target} && $self->ticket;

    return '';
}

sub add_file {
    my ($self, $path, $pdir, @arg) = @_;
    unless ( defined $pdir ) {
        ++$self->{skipped};
        $self->{notify}->flush ($path);
        return undef;
    }
    return unless defined $pdir;
    my $pool = pop @arg;
    # a replaced node shouldn't be checked with cb_exist
    my $spool = SVN::Pool->new_default($pool);
    my $touched = $self->{notify}->node_status($path);
    if (!$self->{added}{$pdir} && !$touched &&
	(my $kind = $self->inspector->exist($path, $spool))) {
	unless ($kind == $SVN::Node::file) {
	    $self->{notify}->flush ($path) ;
	    return undef;
	}
	$self->{info}{$path}{addmerge} = 1;
	$self->{info}{$path}{open} = [$pdir, -1];
	$self->{info}{$path}{fpool} = $pool;
	if (defined $arg[0]) {
	    warn "===> add merge with history... very bad";
	}
	$self->{cb_add_merged}->($path) if $self->{cb_add_merged};
    }
    else {
	++$self->{changes};
	$self->{added}{$path} = 1;
	$self->{notify}->node_status ($path, $touched ? 'R' : 'A');
	if (defined $arg[0]) {
	    $self->{notify}->hist_status ($path, '+');
	    @arg = $self->resolve_copy($path, @arg);
	    $self->{info}{$path}{baseinfo} = [$self->resolve_base($path, 0, $pool)];
	    $self->{info}{$path}{fpool} = $pool;
	}
	$self->{storage_baton}{$path} =
	    $self->{storage}->add_file ($path, $self->{storage_baton}{$pdir}, @arg, $pool);
	# XXX: Why was this here? All tests pass without it.
	#$pool->default if $pool && $pool->can ('default');

	# XXX: fpool is used for testing if the file is open rather than add,
	# so use another field to hold it.
	$self->{info}{$path}{hold_pool} = $pool;
    }
    return $path;
}

sub _resolve_base {
    my ($self, $path, $orig) = @_;
    my ($entry) = $self->{dh}->get("/$path");
    return unless $entry->{copyanchor};
    $entry = $self->{dh}->get($entry->{copyanchor})
	unless $entry->{copyanchor} eq "/$path";
    my $key = $orig ? 'orig_copyfrom' : 'copyfrom';
    return (abs2rel("/$path",
		    $entry->{copyanchor} => $entry->{".$key"}, '/'),
	    $entry->{".${key}_rev"});
}

sub resolve_base {
    my ($self, $path, $orig, $pool) = @_;
    my ($basepath, $fromrev) = $self->_resolve_base($path, $orig);
    if ($basepath) {
	# if the inspector is involving copy base, we can't use
	# $self->inspector, as it represent the current txn
	return ($basepath, $fromrev, $self->static_inspector);
    }

    return ($path, undef, $self->inspector) 
}

sub open_file {
    my ($self, $path, $pdir, $rev, $pool) = @_;
    # modified but rm locally - tag for conflict?
    my ($basepath, $fromrev, $inspector) = $self->resolve_base($path);
    if (defined $pdir && $inspector->exist($basepath, $pool) == $SVN::Node::file) {
	$self->{info}{$path}{baseinfo} = [$basepath, $fromrev, $inspector]
	    if defined $fromrev;
	$self->{info}{$path}{open} = [$pdir, $rev];
	$self->{info}{$path}{fpool} = $pool;
	$self->{notify}->node_status ($path, '');
	$pool->default if $pool && $pool->can ('default');
	return $path;
    }
    ++$self->{skipped};
    $self->{notify}->flush ($path);
    return undef;
}

sub ensure_open {
    my ($self, $path) = @_;
    return unless $self->{info}{$path}{open};
    my ($pdir, $rev, $pool) = (@{$self->{info}{$path}{open}},
			       $self->{info}{$path}{fpool});
    $self->{storage_baton}{$path} ||=
	$self->{storage}->open_file ($path, $self->{storage_baton}{$pdir},
				     $self->{cb_rev}->($path), $pool);
    ++$self->{changes};
    delete $self->{info}{$path}{open}; # 

    $self->set_ticket( $self->{storage_baton}{$path}, 'file', $pool )
	if $path eq $self->{target} && $self->ticket;
}

sub ensure_close {
    my ($self, $path, $checksum, $pool) = @_;

    $self->cleanup_fh ($self->{info}{$path}{fh});
    $self->{notify}->flush ($path, 1);
    $self->{cb_closed}->($path, $checksum, $pool)
        if $self->{cb_closed};

    if ($path eq $self->{target} && $self->cb_merged) {
	$self->ensure_open ($path);
	$self->cb_merged->($self->{changes},'file', $self->{ticket});
    }

    if (my $baton = $self->{storage_baton}{$path}) {
	$self->{storage}->close_file ($baton, $checksum, $pool);
	delete $self->{storage_baton}{$path};
    }

    delete $self->{info}{$path};
}

sub node_conflict {
    my ($self, $path) = @_;
    $self->{cb_conflict}->($path, 'node') if $self->{cb_conflict};
    ++$self->{conflicts};
    $self->{notify}->node_status ($path, 'C');
}

sub cleanup_fh {
    my ($self, $fh) = @_;
    for (qw/base new local/) {
	close $fh->{$_}[FH]
	    if $fh->{$_}[FH];
    }
}

sub prepare_fh {
    my ($self, $fh, $eol) = @_;
    for my $name (qw/base new local/) {
	my $entry = $fh->{$name};
	next unless $entry->[FH];
	# if there's eol translation required, we can't use the
	# prepared tmp files.
	if ($entry->[FILENAME]) {
	    next unless $eol;
	    # reopen the tmp file, since apply_textdelta closes it
	    open $entry->[FH], $entry->[FILENAME];
	}
	my $tmp = [tmpfile("$name-"), $entry->[CHECKSUM]];
	binmode $tmp->[FH], $eol if $eol;
	slurp_fh ($entry->[FH], $tmp->[FH]);
	close $entry->[FH];
	$entry = $fh->{$name} = $tmp;
	seek $entry->[FH], 0, 0;
    }
}

sub _retrieve_base
{
    my ($self, $path, $pool) = @_;
    my @base = tmpfile('base-');

    my ($basepath, $fromrev) = $self->{info}{$path}{baseinfo} ?
	$self->_resolve_base($path, 1)
      : ($path);
    my $root = $fromrev ? $self->{base_root}->fs->revision_root($fromrev, $pool)
	: $self->{base_root};
    $basepath = "$self->{base_anchor}/$path"
	if $basepath !~ m{^/} && $self->{base_anchor};
    slurp_fh ($root->file_contents ($basepath, $pool), $base[FH]);
    seek $base[FH], 0, 0;
    return @base;
}

sub apply_textdelta {
    my ($self, $path, $checksum, $ppool) = @_;
    return unless $path;

    my $info = $self->{info}{$path};
    my ($basepath, $fromrev, $inspector) = $info->{baseinfo} ? @{$info->{baseinfo}} : ($path, undef, $self->inspector);
    my $fh = $info->{fh} = {};
    my $pool = $info->{fpool};
    if ($pool && ($fh->{local} = $inspector->localmod($basepath, $checksum || '', $pool))) {
	# retrieve base
	unless ($info->{addmerge}) {
	    $fh->{base} = [$self->_retrieve_base($path, $pool)];
	}
	# get new
	$fh->{new} = [tmpfile('new-')];
	return [SVN::TxDelta::apply ($fh->{base}[FH], $fh->{new}[FH], undef, undef, $pool)];
    }
    $self->{notify}->node_status ($path, 'U')
	unless $self->{notify}->node_status ($path);

    $self->ensure_open ($path);

    my $handle = $self->{storage}->apply_textdelta ($self->{storage_baton}{$path},
						    $checksum, $ppool);

    if ($self->{storage_has_unwritable} && !$handle) {
	delete $self->{notify}{status}{$path};
	$self->{notify}->flush ($path);
    }
    return $handle;
}

sub _merge_text_change {
    my ($self, $fh, $label, $pool) = @_;
    my $diff = SVN::Core::diff_file_diff3
	(map {$fh->{$_}[FILENAME]} qw/base local new/);
    my $mfh = tmpfile ('merged-');
    my $marker = time.int(rand(100000));
    my $ylabel
        = ref($self->{inspector}) eq 'SVK::Inspector::Compat'
        ? $label
        : $label . ' (' . $self->{inspector}->{anchor}.')'
        ;
    my $tlabel = $label . ' (' . $self->{anchor}.')';
    SVN::Core::diff_file_output_merge
	    ( $mfh, $diff,
	      (map {
		  $fh->{$_}[FILENAME]
	      } qw/base local new/),
	      "==== ORIGINAL VERSION $label $marker",
	      ">>>> YOUR VERSION $ylabel $marker",
	      "<<<< $marker",
	      "==== THEIR VERSION $tlabel $marker",
	      1, 0, $pool);

    my $conflict = SVN::Core::diff_contains_conflicts ($diff);
    $conflict ||= $self->{tree_conflict};
    if (my $resolve = $self->{resolve}) {
	$resolve->run
	    ( fh              => $fh,
	      mfh             => $mfh,
	      path            => $label,
	      marker          => $marker,
	      # Do not run resolve for diffs with no conflicts
	      ($conflict ? (has_conflict => 1) : ()),
            );
	$conflict = 0 if $resolve->{merged};
	my $mfn = $resolve->{merged} || $resolve->{conflict};
	open $mfh, '<:raw', $mfn or die "Cannot read $mfn: $!" if $mfn;
    }
    seek $mfh, 0, 0; # for skipped
    return ($conflict, $mfh);
}

sub _overwrite_local_file {
    my ($self, $fh, $path, $nfh, $pool) = @_;
    # XXX: document why this is like this
    my $storagebase = $fh->{local};
    my $info = $self->{info}{$path};
    my ($basepath, $fromrev) = $info->{baseinfo} ? @{$info->{baseinfo}} : ($path);

    if ($fromrev) {
	my $sbroot = $self->{base_root}->fs->revision_root($fromrev, $pool);
	$storagebase->[FH] = $sbroot->file_contents($basepath, $pool);
	$storagebase->[CHECKSUM] = $sbroot->file_md5_checksum($basepath, $pool);
    }

    my $handle = $self->{storage}->
	apply_textdelta ($self->{storage_baton}{$path},
			 $storagebase->[CHECKSUM], $pool);

    if ($handle && $#{$handle} >= 0) {
	if ($self->{send_fulltext}) {
	    SVN::TxDelta::send_stream ($nfh, @$handle, $pool);
	}
	else {
	    seek $storagebase->[FH], 0, 0 unless $fromrev; # don't seek for sb
	    my $txstream = SVN::TxDelta::new($fh->{local}[FH], $nfh, $pool);
	    SVN::TxDelta::send_txstream ($txstream, @$handle, $pool);
	}
	return 1;
    }

    if ($self->{storage_has_unwritable}) {
	delete $self->{notify}{status}{$path};
	$self->{notify}->flush ($path);
	return 0;
    }
    return 1;
}

sub _merge_file_unchanged {
    my ($self, $path, $checksum, $pool) = @_;
    ++$self->{changes} unless $self->{g_merge_no_a_change};
    $self->{notify}->node_status ($path, 'g');
    $self->ensure_close ($path, $checksum, $pool);
    return;
}

sub close_file {
    my ($self, $path, $checksum, $pool) = @_;
    return unless $path;
    my $info = $self->{info}{$path};
    my $fh = $info->{fh};
    my $iod;

    my ($basepath, $fromrev, $inspector) = $info->{baseinfo} ? @{$info->{baseinfo}} : ($path, undef, $self->inspector);
    no warnings 'uninitialized';
    my $storagebase_checksum = $fh->{local}[CHECKSUM];
    if ($fromrev) {
	$storagebase_checksum = $self->{base_root}->fs->revision_root
	    ($fromrev, $pool)->file_md5_checksum($basepath, $pool);
    }

    # let close_directory reports about its children
    if ($info->{fh}{new}) {

	$self->_merge_file_unchanged ($path, $checksum, $pool), return
	    if $checksum eq $storagebase_checksum;

	my $eol = $inspector->localprop($basepath, 'svn:eol-style', $pool);
	my $eol_layer = SVK::XD::get_eol_layer({'svn:eol-style' => $eol}, '>');
	$eol_layer = '' if $eol_layer eq ':raw';
	$self->prepare_fh ($fh, $eol_layer);
	# XXX: There used be a case that this explicit comparison is
	# needed, but i'm not sure anymore.
	$self->_merge_file_unchanged ($path, $checksum, $pool), return
	    if File::Compare::compare ($fh->{new}[FILENAME], $fh->{local}->[FILENAME]) == 0;

	$self->ensure_open ($path);
        if ($info->{addmerge}) {
            $fh->{base}[FILENAME] = devnull;
            open $fh->{base}[FH], '<', $fh->{base}[FILENAME];
        }
	my ($conflict, $mfh) = $self->_merge_text_change ($fh, $path, $pool);
	$self->{notify}->node_status ($path, $conflict ? 'C' : 'G');

	$eol_layer = SVK::XD::get_eol_layer({'svn:eol-style' => $eol}, '<');
	binmode $mfh, $eol_layer or die $! if $eol_layer;

	$iod = IO::Digest->new ($mfh, 'MD5');

	if ($self->_overwrite_local_file ($fh, $path, $mfh, $pool)) {
	    undef $fh->{base}[FILENAME] if $info->{addmerge};
	    $self->node_conflict ($path) if $conflict;
	}
	$self->cleanup_fh ($fh);
    }
    elsif ($info->{fpool}) {
	if (!$self->{notify}->node_status($path) || !exists $fh->{local} ) {
	    # open but without text edit, load local checksum
	    if ($basepath ne $path) {
		$checksum = $self->{base_root}->fs->revision_root($fromrev, $pool)->file_md5_checksum($basepath, $pool);
	    }
	    elsif (my $local = $inspector->localmod($basepath, $checksum, $pool)) {
		$checksum = $local->[CHECKSUM];
		close $local->[FH];
	    }
	}
    }

    $checksum = $iod->hexdigest if $iod;
    $self->ensure_close ($path, $checksum, $pool);
}

sub add_directory {
    my ($self, $path, $pdir, @arg) = @_;
    unless ( defined $pdir ) {
        ++$self->{skipped};
        $self->{notify}->flush ($path);
        return undef;
    }
    my $pool = pop @arg;
    my $touched = $self->{notify}->node_status($path);
    # This comes from R (D+A) where the D has conflict
    if ($touched && $touched eq 'C') {
	return undef;
    }
    # Don't bother calling cb_exist (which might be expensive if the parent is
    # already added.
    if (!$self->{added}{$pdir} && !$touched &&
	(my $kind = $self->inspector->exist($path, $pool))) {
	unless ($kind == $SVN::Node::dir) {
	    $self->{notify}->flush ($path) ;
	    return undef;
	}
	$self->{storage_baton}{$path} =
	    $self->{storage}->open_directory ($path, $self->{storage_baton}{$pdir},
					      $self->{cb_rev}->($path), $pool);
	$self->{notify}->node_status ($path, 'G');
	$self->{cb_add_merged}->($path) if $self->{cb_add_merged};
    }
    else {
	if (defined $arg[0]) {
	    @arg = $self->resolve_copy($path, @arg);
	}
	my $baton =
	    $self->{storage}->add_directory ($path, $self->{storage_baton}{$pdir},
					     @arg, $pool);
	unless (defined $baton) {
	    $self->{notify}->flush ($path);
	    return undef;
	}
	$self->{storage_baton}{$path} = $baton;
	$self->{added}{$path} = 1;
	$self->{notify}->hist_status ($path, '+')
	    if defined $arg[0];
	$self->{notify}->node_status ($path, $touched ? 'R' : 'A');
	$self->{notify}->flush ($path, 1);
    }
    ++$self->{changes};
    return $path;
}

sub resolve_copy {
    my ($self, $path, $from, $rev) = @_;
    die "unknown copy $from $rev for $path"
	unless exists $self->{copy_info}{$from}{$rev};
    my ($dstfrom, $dstrev) = @{$self->{copy_info}{$from}{$rev}};
    $self->{dh}->store("/$path", { copyanchor => "/$path",
				   '.copyfrom' => $dstfrom,
				   '.copyfrom_rev' => $dstrev,
				   '.orig_copyfrom' => $from,
				   '.orig_copyfrom_rev' => $rev,
				 });
    return $self->{cb_copyfrom}->($dstfrom, $dstrev)
	if $self->{cb_copyfrom};
    return ($dstfrom, $dstrev);
}

sub open_directory {
    my ($self, $path, $pdir, $rev, @arg) = @_;
    my $pool = $arg[-1];

    unless ($self->{open_nonexist}) {
	return undef unless defined $pdir;

	my ($basepath, $fromrev, $inspector) = $self->resolve_base($path);

	unless ($inspector->exist($basepath, $pool) || $self->{open_nonexist}) {
	    ++$self->{skipped};
	    $self->{notify}->flush ($path);
	    return undef;
	}
    }
    $self->{notify}->node_status ($path, '');
    my $baton = $self->{storage_baton}{$path} =
	$self->{storage}->open_directory ($path, $self->{storage_baton}{$pdir},
					  $self->{cb_rev}->($path), @arg);
    $self->set_ticket($baton, 'dir', $pool)
	if $path eq $self->{target} && $self->ticket;

    return $path;
}

sub close_directory {
    my ($self, $path, $pool) = @_;
    return unless defined $path;
    no warnings 'uninitialized';

    delete $self->{added}{$path};
    $self->{notify}->flush_dir ($path);

    my $baton = $self->{storage_baton}{$path};
    $self->cb_merged->( $self->{changes}, 'dir', $self->{ticket})
	if $path eq $self->{target} && $self->cb_merged;


    $self->{storage}->close_directory ($baton, $pool);
    delete $self->{storage_baton}{$path}
	unless $path eq '';
}

sub _merge_file_delete {
    my ($self, $path, $rpath, $pdir, $pool) = @_;

    my ($basepath, $fromrev, $inspector) = $self->resolve_base($path);
    
    my $no_base;
    my $md5 = $self->{base_root}->check_path ($rpath, $pool)?
        $self->{base_root}->file_md5_checksum ($rpath, $pool)
        : do { $no_base = 1; require Digest::MD5; Digest::MD5::md5_hex('') };

    return undef unless $inspector->localmod ($basepath, $md5, $pool);
    return {} unless $self->{resolve};

    my $fh = $self->{info}{$path}->{fh} || {};
    $fh->{base} ||= [$no_base? (tmpfile('base-')): ($self->_retrieve_base($path, $pool))];
    $fh->{new} = [tmpfile('new-')];
    $fh->{local} = [tmpfile('local-')];
    my ($tmp) = $inspector->localmod($basepath, '', $pool);
    slurp_fh ( $tmp->[FH], $fh->{local}[FH]);
    seek $fh->{local}[FH], 0, 0;
    $fh->{local}[CHECKSUM] = $tmp->[CHECKSUM];

    my ($conflict, $mfh) = $self->_merge_text_change( $fh, $path, $pool);
    if( $conflict ) {
	$self->clean_up($fh);
	return {};
    } elsif( !(stat($mfh))[7] ) {
	#delete file if merged size is 0
	$self->clean_up($fh);
	return undef;
    }
    seek $mfh, 0, 0;
    my $iod = IO::Digest->new ($mfh, 'MD5');

    $self->{info}{$path}{open} = [$pdir, -1];
    $self->{info}{$path}{fpool} = $pool;
    $self->ensure_open ($path);
    $self->_overwrite_local_file ($fh, $path, $mfh, $pool);
    ++$self->{changes};
    $self->ensure_close ($path, $iod->hexdigest, $pool);

    return 1;
}

# return a hash for partial delete
# returns undef for deleting this
# returns 1 for merged delete (user changed content and we leave node)
# Note that empty hash means don't delete - conflict.
sub _check_delete_conflict {
    my ($self, $path, $rpath, $kind, $pdir, $pool) = @_;

    my $localkind = $self->inspector->exist ($path, $pool);

    # node doesn't exist in dst
    return undef unless $localkind;

    # deleting, but local node is of different type already
    # original node could be moved to different place
    # Editor::Rename should track the latter case
    # XXX: prompt for resolution
    return {} if $kind && $kind != $localkind;

    return $self->_merge_file_delete ($path, $rpath, $pdir, $pool) if $localkind == $SVN::Node::file;

    # TODO: checkouts may have unversioned files/dirs under the dir we are going to delete
    # we still has no interactive resolver for this
    return {} unless $localkind == $SVN::Node::dir;

    # it's dir...

    my $dirmodified = $self->inspector->dirdelta ($path, $self->{base_root}, $rpath, $pool);
    my $entries = $self->{base_root}->dir_entries ($rpath, $pool);

    my $baton = $self->{storage_baton}{$path} = $self->{storage}->open_directory (
        $path, $self->{storage_baton}{$pdir}, $self->{cb_rev}->($path), $pool
    );

    my $torm;
    for my $name (sort keys %$entries) {
	my ($cpath, $crpath) = ("$path/$name", "$rpath/$name");
        my $entry = $entries->{$name};

	if (my $mod = $dirmodified->{$name}) {
	    if ($mod eq 'D') {
                $torm->{$name} = undef;
	    }
            else {
                $torm->{$name} = $self->_check_delete_conflict ($cpath, $crpath, $entry->kind, $path, SVN::Pool->new_default($pool));
            }
            delete $dirmodified->{$name};
	}
	else { # dir or unmodified file
            $torm->{$name} = $self->_check_delete_conflict
                ($cpath, $crpath, $entry->kind, $path, SVN::Pool->new_default($pool));
	}
    }

    foreach my $node (keys %$dirmodified) {
        local $self->{tree_conflict} = 1;
        my ($cpath, $crpath) = ("$path/$node", "$rpath/$node");
        my $kind = $self->{base_root}->check_path ($crpath);
        $torm->{$node} = $self->_check_delete_conflict ($cpath, $crpath, $kind, $path, SVN::Pool->new_default($pool));
    }

    $self->{storage}->close_directory ($baton, $pool);

    return $torm;
}

sub _partial_delete {
    my ($self, $torm, $path, $pbaton, $pool, $no_status) = @_;

    unless (ref $torm) {
        my $s;
        if ($torm && $torm == 1) {
            $s = 'G';
        } else {
            if ($self->inspector->exist($path, $pool)) {
                $self->{storage}->delete_entry (
                    $path, $self->{cb_rev}->($path), $pbaton, $pool
                );
            }
            $s = 'D';
        }
        $self->{notify}->node_status($path, $s) unless $no_status;
        return $s;
    } elsif (!keys %$torm) {
        $self->node_conflict($path) unless $no_status;
        return 'C';
    }
    # it's dir...

    my $baton = $self->{storage}->open_directory ($path, $pbaton, $self->{cb_rev}->($path), $pool);
    my $summary = '';
    my @children_stats;
    my $skip_children = 1;
    for (sort keys %$torm) {
	my $cpath = "$path/$_";
        # check that out
	my $status = $self->_partial_delete ($torm->{$_}, $cpath, $baton, SVN::Pool->new_default($pool), 1);
        push @children_stats, [$cpath, $status];
        $skip_children = 0  unless $status eq 'D';
        $summary = 'C' if $status eq 'C';
        $summary = 'G' if !$summary && $status eq 'G';
    }
    $summary ||= 'D';
    $self->{storage}->close_directory ($baton, $pool);

    if ($summary eq 'D') {
        if ($self->inspector->exist($path, $pool)) {
            $self->{storage}->delete_entry ($path, $self->{cb_rev}->($path), $pbaton, $pool);
        }
        $self->{notify}->node_status ($path, 'D') unless $no_status;
    }
    elsif ($summary eq 'C') {
        $self->node_conflict ($path) unless $no_status;
    }
    elsif ($summary eq 'G') {
        $self->{notify}->node_status ($path, 'G') unless $no_status;
    }
    else { # really should be assert
        $self->node_conflict ($path) unless $no_status;
        $summary = 'C';
    }

    unless ($skip_children) {
        foreach (@children_stats) {
            if ($_->[1] ne 'C') {
                $self->{notify}->node_status (@$_);
            } else {
                $self->node_conflict ($_->[0]);
            }
        }
    }

    return $summary;
}

sub delete_entry {
    my ($self, $path, $revision, $pdir, $pool) = @_;
    no warnings 'uninitialized';
    $pool = SVN::Pool->new_default($pool);
    my ($basepath, $fromrev, $inspector) = $self->resolve_base($path);

    return unless defined $pdir && $inspector->exist($basepath);
    my $rpath = $basepath =~ m{^/} ? $basepath :
	$self->{base_anchor} eq '/' ? "/$basepath" : "$self->{base_anchor}/$basepath";
    my $torm;

    # XXX: need txn-aware cb_*! for the case current path is from a
    # copy and to be deleted - Note this might have been done, exam it.
    {
	# XXX: this is too evil
	local $self->{base_root} = $self->{base_root}->fs->revision_root($fromrev) if $basepath ne $path;
	my $kind = $self->{base_root}->check_path ($rpath);
	$torm = $self->_check_delete_conflict ($path, $rpath, $kind, $pdir, $pool);
    }

    $self->_partial_delete ($torm, $path, $self->{storage_baton}{$pdir}, $pool);
    ++$self->{changes};
}

sub _prop_eq {
    my ($prop1, $prop2) = @_;
    return 0 if defined $prop1 xor defined $prop2;
    return defined $prop1 ? ($prop1 eq $prop2) : 1;
}

sub _merge_prop_content {
    my ($self, $path, $propname, $prop, $pool) = @_;

    if (my $resolver = $self->{prop_resolver}{$propname}) {
	return $resolver->($path, $prop, $pool);
    }

    if (_prop_eq (@{$prop}{qw/base local/})) {
	return ('U', $prop->{new});
    }
    elsif (_prop_eq (@{$prop}{qw/new local/})) {
	return ('g', $prop->{local});
    }

    my $fh = { map {
	my $tgt = defined $prop->{$_} ? \$prop->{$_} : devnull;
	open my $f, '<', $tgt;
	($_ => [$f, ref ($tgt) ? undef : $tgt]);
    } qw/base new local/ };
    $self->prepare_fh ($fh);

    my ($conflict, $mfh) = $self->_merge_text_change ($fh, loc ("Property %1 of %2", $propname, $path), $pool);
    return ($conflict ? 'C' : 'G', do { local $/; <$mfh> });
}

sub _merge_prop_change {
    my $self = shift;
    my $path = shift;
    my $pool;
    return unless defined $path;
    return if $_[0] =~ m/^svm:/;
    # special case the the root node that was actually been added
    if ($self->{added}{$path} or
	(!length ($path) and $self->{base_root}->is_revision_root
	 and $self->{base_root}->revision_root_revision == 0)) {
	$self->{notify}->prop_status ($path, 'U') unless $self->{added}{$path};
	return 1;
    }
    my $rpath = $self->{base_anchor} eq '/' ? "/$path" : "$self->{base_anchor}/$path";
    my $prop;
    $prop->{new} = $_[1];
    my ($basepath, $fromrev) = $self->{info}{$path}{baseinfo} ? @{$self->{info}{$path}{baseinfo}} : ($path);
    {
	local $@;
	$prop->{base} = eval { $self->{base_root}->node_prop ($rpath, $_[0], $pool) };
	$prop->{local} = $self->inspector->exist($basepath, $pool)
	    ? $self->inspector->localprop($basepath, $_[0], $pool) : undef;
    }
    # XXX: only known props should be auto-merged with default resolver
    $pool = pop @_ if ref ($_[-1]) =~ m/^(?:SVN::Pool|_p_apr_pool_t)$/;
    my ($status, $merged, $skipped) =
	$self->_merge_prop_content ($path, $_[0], $prop, $pool);

    return if $skipped;

    if ($status eq 'g') {
	$self->{cb_prop_merged}->($path, $_[0])
	    if $self->{cb_prop_merged};
    }
    else {
        if ($status eq 'C') {
            $self->{cb_conflict}->($path, 'prop') if $self->{cb_conflict};
            ++$self->{conflicts};
        }
	$_[1] = $merged;
    }
    $self->{notify}->prop_status ($path, $status);
    ++$self->{changes};
    return $status eq 'g' ? 0 : 1;
}

sub change_file_prop {
    my ($self, $path, @arg) = @_;
    $self->_merge_prop_change ($path, @arg) or return;
    $self->ensure_open ($path);
    $self->{storage}->change_file_prop ($self->{storage_baton}{$path}, @arg);
}

sub change_dir_prop {
    my ($self, $path, @arg) = @_;
    $self->_merge_prop_change ($path, @arg) or return;
    $self->{storage}->change_dir_prop ($self->{storage_baton}{$path}, @arg);
}

sub close_edit {
    my ($self, @arg) = @_;
    if ($self->{allow_conflicts} ||
	(defined $self->{storage_baton}{''} && !$self->{conflicts}) && $self->{changes}) {
	$self->{storage}->close_edit(@arg);
    }
    else {
	$logger->warn(loc("Empty merge.")) unless $self->{notify}{quiet};
	$self->{storage}->abort_edit(@arg);
    }
}

=head1 BUGS

=over

=item Tree merge

still very primitive, have to handle lots of cases

=back

=cut

1;
