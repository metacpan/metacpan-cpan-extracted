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
package SVK::Mirror::Backend::SVNRa;
use strict;
use warnings;

use SVN::Core;
use SVN::Ra;
use SVK::I18N;
use SVK::Editor;
use SVK::Mirror::Backend::SVNRaPipe;
use SVK::Editor::MapRev;
use SVK::Util qw(IS_WIN32 uri_escape);
use SVK::Logger;
use SVK::Editor::FilterProp;
use SVK::Editor::Composite;

use Class::Autouse qw(SVK::Editor::SubTree SVK::Editor::CopyHandler SVK::Editor::Translate);

## class SVK::Mirror::Backend::SVNRa;
## has $.mirror is weak;
## has ($!config, $!auth_baton, $!auth_ref);
## has ($.source_root, $.source_path, $.fromrev)

# We'll extract SVK::Mirror::Backend later.
# use base 'SVK::Mirror::Backend';
use base 'Class::Accessor::Fast';

# for this: things without _'s will probably move to base
# SVK::Mirror::Backend
__PACKAGE__->mk_accessors(qw(mirror _config _auth_baton _auth_ref _auth_baton source_root source_path fromrev _has_replay _cached_ra use_pipeline));

=head1 NAME

SVK::Mirror::Backend::SVNRa - 

=head1 SYNOPSIS


=head1 DESCRIPTION

=over

=item load

=cut

sub new {
    my ( $class, $args ) = @_;
    unless ( defined $args->{use_pipeline} ) {
        $args->{use_pipeline} = 0;#IS_WIN32 ? 0 : 1;
    }
    return $class->SUPER::new($args);
}

sub _do_load_fromrev {
    my $self = shift;
    my $fs = $self->mirror->repos->fs;
    my $root = $fs->revision_root($fs->youngest_rev);
    my $changed = $root->node_created_rev($self->mirror->path);
    return scalar $self->find_changeset($changed);
}

sub refresh {
    my $self = shift;
    $self->fromrev($self->_do_load_fromrev);
}

sub load {
    my ($class, $mirror) = @_;
    my $self = $class->new( { mirror => $mirror } );
    my $t = $mirror->get_svkpath;
    die loc( "%1 is not a mirrored path.\n", $t->depotpath )
        unless $t->root->check_path( $mirror->path );

    my $uuid = $t->root->node_prop($t->path, 'svm:uuid');
    my $ruuid = $t->root->node_prop($t->path, 'svm:ruuid') || $uuid;
    die loc("%1 is not a mirrored path.\n", $t->path) unless $uuid;
    my ( $root, $path ) = split('!',  $t->root->node_prop($t->path, 'svm:source'));
    $path = '' unless defined $path;
    $self->source_root( $root );
    $self->source_path( $path );

    $mirror->url( "$root$path" );
    $mirror->server_uuid( $ruuid );
    $mirror->source_uuid( $uuid );

    $self->refresh;

    die loc("%1 is not a mirrored path.\n", $t->path) unless defined $self->fromrev;

    return $self;
}

=item create

=cut

sub create {
    my ($class, $mirror, $backend, $args, $txn, $editor) = @_;

    my $self = $class->new({ mirror => $mirror });

    my $ra = $self->_new_ra;

    # init the svm:source and svm:uuid thing on $mirror->path
    $mirror->server_uuid($ra->get_uuid);
    my $source_root = $ra->get_repos_root;
    $self->_ra_finished($ra);

    my $source_path = $self->mirror->url;
    # XXX: this shouldn't happen. kill this substr
    die "source url not under source root"
	if substr($source_path, 0, length($source_root), '') ne $source_root;

    $self->source_root( $source_root );
    $self->source_path( $source_path );

    return $self->_init_state($txn, $editor);
}

sub _init_state {
    my ($self, $txn, $editor) = @_;

    my $mirror = $self->mirror;
    my $uuid = $mirror->server_uuid;

    my $t = $mirror->get_svkpath('/');
    die loc( "%1 already exists.\n", $mirror->path )
        if $t->root->check_path( $mirror->path );

    $self->_check_overlap;

    unless ($txn) {
        my %opt;
        ( $editor, %opt ) = $t->get_dynamic_editor(
            ignore_mirror => 1,
            author        => $ENV{USER},
        );
        $opt{txn}->change_prop( 'svm:headrev', "$uuid:0" );
    }
    else {
        $txn->change_prop( 'svm:headrev', "$uuid:0" );
    }

    my $dir_baton = $editor->add_directory( substr($mirror->path, 1), 0, undef, -1 );
    $editor->change_dir_prop( $dir_baton, 'svm:uuid', $uuid);
    $editor->change_dir_prop( $dir_baton, 'svm:source', $self->source_root.'!'.$self->source_path );
    $editor->close_directory($dir_baton);
    $editor->adjust;
    $editor->close_edit unless $txn;

    $mirror->server_uuid( $uuid );

    return $self;
}

sub _check_overlap {
    my ($self) = @_;
    my $depot = $self->mirror->depot;
    my $fs = $depot->repos->fs;
    my $root = $fs->revision_root($fs->youngest_rev);
    my $prop = $root->node_prop ('/', 'svm:mirror') or return;
    my @mirrors = $prop =~ m/^(.*)$/mg;

    for (@mirrors) {
	my $mirror = SVK::Mirror->load( { depot => $depot, path => $_ } );
	next if $self->source_root ne $mirror->_backend->source_root;
	# XXX: check overlap with svk::mirror objects.

	my ($me, $other) = map { Path::Class::Dir->new_foreign('Unix', $_) }
	    $self->source_path, $mirror->_backend->source_path;
	die "Mirroring overlapping paths not supported\n"
	    if $me->subsumes($other) || $other->subsumes($me);
    }
}

=item relocate($newurl)

=cut

sub relocate {
    my ($self, $source, $options) = @_;

    $source =~ s{/+$}{}g;
    my $ra = $self->_new_ra(url => $source);
    my $ra_uuid = $ra->get_uuid;
    my $mirror = $self->mirror;
    die loc("Mirror source UUIDs differ.\n")
	unless $ra_uuid eq $mirror->server_uuid;
    my $source_root = $ra->get_repos_root;
    my $source_path = $source;
    die "source url not under source root"
	if substr($source_path, 0, length($source_root), '') ne $source_root;

    die loc( "Can't relocate: mirror subdirectory changed from %1 to %2.\n",
        $self->source_path, $source_path )
        unless $self->source_path eq $source_path;

    $self->source_root( $ra->get_repos_root );
    $mirror->url($source);

    $self->_do_relocate;
}

sub _do_relocate {
    my ($self) = @_;
    my $mirror = $self->mirror;
    my $t = $mirror->get_svkpath;

    my ( $editor, %opt ) = $t->get_dynamic_editor(
        ignore_mirror => 1,
        message       => loc( 'Mirror relocated to %1', $mirror->url ),
        author        => $ENV{USER},
    );
    $opt{txn}->change_prop( 'svm:headrev', join(':', $mirror->server_uuid, $self->fromrev ) );
    $opt{txn}->change_prop( 'svm:incomplete', '*');

    $editor->change_dir_prop( 0, 'svm:source', $self->source_root.'!'.$self->source_path );
    $editor->adjust;
    $editor->close_edit;
}

=item has_replay_api

Returns if the svn client library has replay capability

=cut

sub has_replay_api {
    my $self = shift;

    return if $ENV{SVKNORAREPLAY};

    return unless _p_svn_ra_session_t->can('replay');

    # The Perl bindings shipped with 1.4.0 has broken replay support
    return $SVN::Core::VERSION gt '1.4.0';
}

=item has_replay

Returns if we can do ra_replay with the mirror source url.

=cut

sub has_replay {
    my $self = shift;
    return $self->_has_replay if defined $self->_has_replay;

    return $self->_has_replay(0) unless $self->has_replay_api;

    my $ra = $self->_new_ra;

    my $err;
    {
        local $SVN::Error::handler = sub { $err = $_[0]; die \'error handled' };
        if ( eval { $ra->replay( 0, 0, 0, SVK::Editor->new ); 1 } ) {
            $self->_ra_finished($ra);
            return $self->_has_replay(1);
        }
        die $@ unless $err;
    }
    $self->_ra_finished($ra);
    # FIXME: if we do ^c here $err would be empty. do something else.
    return $self->_has_replay(0)
      if $err->apr_err == $SVN::Error::RA_NOT_IMPLEMENTED      # ra_svn
      || $err->apr_err == $SVN::Error::UNSUPPORTED_FEATURE     # ra_dav
      || $err->apr_err == $SVN::Error::RA_DAV_REQUEST_FAILED;  # ra_dav (googlecode)
    die $err->expanded_message;
}

sub _new_ra {
    my ( $self, %args ) = @_;

    if ( $self->_cached_ra ) {
        my $ra = delete $self->{_cached_ra};
        my $url = uri_escape($args{url} || $self->mirror->url);
        return $ra if $ra->{url} eq $url;
        if ( _p_svn_ra_session_t->can('reparent') ) {
            $ra->reparent($url);
            $ra->{url} = $url;
            return $ra;
        }
    }
    $self->_initialize_svn;
    $args{url} = uri_escape($args{url}) if $args{url};
    return SVN::Ra->new(
        url    => uri_escape($self->mirror->url),
        auth   => $self->_auth_baton,
        config => $self->_config,
        %args
    );
}

sub _ra_finished {
    my ($self, $ra) = @_;
    return if $self->_cached_ra;
    return if ref($ra) eq 'SVK::Mirror::Backend::SVNRaPipe';
    $self->_cached_ra( $ra );
}

sub _initialize_svn {
    my ($self) = @_;

    $self->_config( SVN::Core::config_get_config(undef, $self->mirror->pool) )
      unless $self->_config;
    $self->_initialize_auth
      unless $self->_auth_baton;
}

sub _initialize_auth {
    my ($self) = @_;

    # create a subpool that is not automatically destroyed
    my $auth_pool = SVN::Pool::create (${ $self->mirror->pool });
    $auth_pool->default;

    my ($baton, $ref) = SVN::Core::auth_open_helper(SVK::Config->get_auth_providers);

    $self->_auth_baton($baton);
    $self->_auth_ref($ref);
}

=back

=head2 METHODS

=over

=item find_rev_from_changeset($remote_identifier)

=cut

sub find_rev_from_changeset {
    my ($self, $changeset, $seekback) = @_;
    my $r = $self->_find_rev_from_changeset($changeset, $seekback);
    return unless defined $r;

    my $fs = $self->mirror->depot->repos->fs;

    return -1
	if $self->find_changeset($r) == 0
        || $fs->revision_prop($r, 'svm:incomplete');

    return $r;
}

sub _find_rev_from_changeset {
    my ($self, $changeset, $seekback) = @_;
    my $t = $self->mirror->get_svkpath;

    no warnings 'uninitialized'; # $s_changeset below may be undef

    my $r = $t->search_revision
	( cmp => sub {
	      my $rev = shift;
              my $s_changeset = scalar $self->find_changeset($rev);
              return $s_changeset <=> $changeset;
          } );

    return defined $r ? $r : () if $r || !$seekback;

    my $result;
    $r = $t->search_revision
	( cmp => sub {
	      my $rev = shift;

              my $s_changeset = scalar $self->find_changeset($rev);

	      if ($s_changeset > $changeset) {
		  my $prev = $t->mclone(revision => $rev)->prev;
		  $result = $prev
		      if scalar $self->find_changeset($prev->revision) < $changeset;
	      }
	      return $s_changeset <=> $changeset;
          } );

    return $t->normalize->revision unless $result;

    return $result->revision;
}

=item find_changeset( $local_rev )

=cut

sub find_changeset {
    my ($self, $rev) = @_;
    return $self->_find_remote_rev($rev, $self->mirror->repos);
}

sub _find_remote_rev {
    my ($self, $rev, $repos) = @_;
    $repos ||= $self->mirror->repos;
    my $fs = $repos->fs;
    my $prop = $fs->revision_prop($rev, 'svm:headrev') or return;
    my %rev = map {split (':', $_, 2)} $prop =~ m/^.*$/mg;
    return %rev if wantarray;
    # XXX: needs to be more specific
    return $rev{ $self->mirror->source_uuid } || $rev{ $self->mirror->server_uuid };
}


=item traverse_new_changesets()

=cut

sub traverse_new_changesets {
    my ($self, $code, $torev, $cross, $want_paths) = @_;
    $self->refresh;
    my $from = ($self->fromrev || 0)+1;
    my $to = defined $torev ? $torev : -1;

    my $ra = $self->_new_ra;
    $to = $ra->get_latest_revnum() if $to == -1;
    return if $from > $to;
    $logger->info( "Retrieving log information from $from to $to");
    eval {
        $ra->get_log([''], $from, $to, 0,
		  $want_paths, !$cross,
		  sub {
		      my ($paths, $rev, $author, $date, $msg, $pool) = @_;
		      $code->($rev, { author => $author, date => $date, message => $msg }, $paths);
		  });
    };
    $self->_ra_finished($ra);
    die $@ if $@;
}

=item sync_changeset($changeset, $metadata, $ra, $extra_prop, $callback )

=cut

sub sync_changeset {
    my ( $self, $changeset, $metadata, $extra_prop, $callback, $delta_generator, $translate_from ) = @_;
    my $t = $self->mirror->get_svkpath;
    my ( $editor, undef, %opt ) = $t->get_editor(
        ignore_mirror => 1,
        message       => $metadata->{message},
        author        => $metadata->{author},
        callback      => sub {
            $t->repos->fs->change_rev_prop( $_[0], 'svn:date',
                $metadata->{date} );
            $self->fromrev( $_[0] );
            $callback->( $changeset, $_[0] ) if $callback;
        }
    );

    for (keys %$extra_prop) {
	$opt{txn}->change_prop( $_, $extra_prop->{$_} );
    }
    $self->_revmap_prop( $opt{txn}, $changeset );

    $editor = $self->_get_sync_editor($editor, $changeset, $translate_from);

    $delta_generator->( $editor, $opt{txn});

    return;

}

sub _after_replay {
    my ($self, $ra, $editor) = @_;
    if ( $editor->isa('SVK::Editor::SubTree') ) {
	my $baton = $editor->anchor_baton;
        if ( $editor->needs_touch ) {
            $editor->change_dir_prop( $baton, 'svk:mirror' => undef );
        }
	if (!$editor->changes) {
	    $editor->abort_edit;
	    return;
	}
        $editor->close_directory($baton);
    }

    $editor->close_edit;
    return;

}

sub _get_sync_editor {
    my ($self, $oeditor, $changeset, $translate_from) = @_;

    my $editor = SVK::Editor::CopyHandler->new(
        _editor => $oeditor,
        cb_copy => sub {
            my ( undef, $path, $rev, $current_path, $pb ) = @_;
            return ( $path, $rev ) if $rev == -1;
            my $source_path = $self->source_path;
            my $copy_prefix = $translate_from || $self->source_path;
            $path =~ s/^\Q$copy_prefix//;
	    my $lrev = $self->find_rev_from_changeset($rev, 1);
	    if ($lrev == -1) {
		# vivify the copy that we don't have
		my $cb = sub {
		    my $editor = $oeditor;
		    my ($method, $baton) = @_;
		    my $ra = $self->_new_ra;
		    if ($method eq 'add_directory') {
			# Here we use translate instead of composite
			# to make it not care about target_baton
			$editor = SVK::Editor::Translate->new
			    ( { translate => sub { $_[0] = "$current_path/$_[0]"; },
				_editor => $editor } );
		    }
		    $editor =
			SVK::Editor::SubTree->new
			( { master_editor => $editor,
			    anchor        => $current_path,
			    anchor_baton  => $baton,
			  } );

		    $ra->replay($changeset, $changeset, 1, $editor);
		    $self->_ra_finished($ra);
		};
		return (undef, -1, $cb);
	    }
            return ( $self->mirror->path . $path, $lrev );
        }
    );

    # ra->replay gives us editor calls based on repos root not
    # base uri, so we need to get the correct subtree.
    my $baton;
    if ( $translate_from || length $self->source_path ) {
        my $anchor = substr( $translate_from || $self->source_path, 1 );
        $baton  = $editor->open_root(-1);      # XXX: should use $t->revision
        $editor = SVK::Editor::SubTree->new(
            {   master_editor => $editor,
                anchor        => $anchor,
                anchor_baton  => $baton
            }
        );
    }

    return $editor;
}

sub _revmap_prop {
    my ($self, $txn, $changeset) = @_;
    $txn->change_prop('svm:headrev', $self->mirror->server_uuid.":$changeset\n");
}


=item mirror_changesets

=cut

sub mirror_changesets {
    my ( $self, $torev, $callback, $fake_last ) = @_;
    $self->mirror->with_lock(
        'mirror',
        sub { $self->refresh;
              $self->_mirror_changesets( $torev, $callback, $fake_last ) } );
}

sub _sync_edge_changeset {
    my ($self, $revdata, $callback, $translate_from, $up_to) = @_;

    my $paths = $revdata->[2];
    unless ($paths) {
        my $ra = $self->_new_ra;

        $ra->get_log([''], $revdata->[0], $revdata->[0], 0,
                     1, 1, sub { $paths = _dclone_log_change_paths(shift); } );
        $self->_ra_finished($ra);
    }

    my ($entry, $old_path, $old_rev) = $self->_find_edge_entry( $paths, $translate_from || $self->source_path ) or return;

    my ($copyfrom_path, $copyfrom_rev) = ($entry->{copyfrom_path}, $entry->{copyfrom_rev});

    if ($up_to) {
        $self->_mirror_changesets_with_cross( $revdata->[0], $callback, 0, $old_path );
    }


    my $ra = $self->_new_ra;

    $ra->reparent( $self->source_root . $old_path );
    $self->sync_changeset
        ( $revdata->[0], $revdata->[1], {},
          $callback,
          sub {
              my ($editor, $txn) = @_;
              $editor = $editor->master_editor;
              $editor = SVK::Editor::Composite->new( { master_editor => $editor } );
              $editor = SVK::Editor::FilterProp->new
                  ( { cb_prop => sub { return $_[0] !~ m/^svn:(wc|entry)/; },
                      _editor => [ $editor ] } );
              my $report = $ra->do_diff($revdata->[0], '', 1, 1, $self->source_root.($translate_from || $self->source_path), $editor);
              $report->set_path('', $copyfrom_rev, 0, undef );
              $report->finish_report;
              if ( %{$txn->root->paths_changed} ) {
                  $editor->master_editor->close_edit;
              }
 }) ;

}

sub _sync_up_to_edge_changeset {
    my ($self, $revdata, $callback) = @_;

    return $self->_sync_edge_changeset($revdata, $callback, undef, 1);
}


sub _find_edge_entry {
    my ($self, $paths, $translate_from) = @_;

    for (reverse sort keys %$paths) {
        if (Path::Class::Dir->new_foreign("Unix", $_)
            ->subsumes($translate_from)) {
            my $entry = $paths->{$_};
            if ($entry->{action} eq 'A' && $entry->{copyfrom_path}) {
                return ($entry,
                        SVK::Util::abs2rel($translate_from, $_ => $entry->{copyfrom_path}, '/'),
                        $entry->{copyfrom_rev});
            }
        }
    }
    return;
}

sub _dclone_log_change_paths {
    my $p = shift or return;
    my $paths = {};
    for ( keys %$p ) {
        $paths->{$_} = { action => $p->{$_}->action,
            copyfrom_path => $p->{$_}->copyfrom_path,
            copyfrom_rev  => $p->{$_}->copyfrom_rev,
        };
    }
    return $paths;
}

# note this method doesn't actually sync $torev, it's dealing with all
# the changes before it
sub _mirror_changesets_with_cross {
    my ( $self, $torev, $callback, $fake_last, $translate_from ) = @_;
    my @revs;
    $self->traverse_new_changesets(
        sub {
            my $paths = _dclone_log_change_paths(pop);
            push @revs, [ @_, $paths ]
                unless $fake_last && $torev && $_[0] == $torev;
        },
        $torev, 1, 1 );

    # the last revision belongs to our caller, so don't sync it.
    pop @revs;

    return unless @revs;

    my @batch;

    # if we are in cross mode, our @revs might already contain
    # renames that we need to segment with different
    # translate_from into different batches
    my $tmp_translate_from = $translate_from || $self->source_path;
    my (@newrev);
    for ( reverse @revs ) {
        my $paths = $_->[-1];
        my ( $entry, $old_path, $oldrev ) = $self->_find_edge_entry( $paths, $tmp_translate_from );

        # if there's no edge entry, it's the same batch
        unless ($entry) {
            unshift @newrev, $_;
            next;
        }

        push @batch, [ [@newrev], $_, $tmp_translate_from, $old_path ];
        @newrev             = ();
        $tmp_translate_from = $old_path;
    }
    @revs = @newrev;

    $self->_sync_changesets($callback, \@revs, $tmp_translate_from);

    for (@batch) {
        my ($revs, $edge, $t, $ot) = @$_;
        $self->_sync_edge_changeset($edge, $callback, $ot);
        $self->_sync_changesets($callback, $revs, $t);
    }


}

sub _mirror_changesets {
    my ( $self, $torev, $callback, $fake_last ) = @_;
    my @revs;
    $self->traverse_new_changesets(
        sub {
            my $paths = _dclone_log_change_paths(pop);
            push @revs, [ @_, $paths ]
                unless $fake_last && $torev && $_[0] == $torev;
        },
        $torev, 0, 0 );

    return unless @revs;

    # get the first revision and see if it's renamed from somewhere else
    if ($self->mirror->follow_anchor_copy) {
        $self->_sync_up_to_edge_changeset(shift @revs, $callback );
    }

    # the rest
    $self->_sync_changesets($callback, \@revs);
}

sub _sync_changesets {
    my ($self, $callback, $revs, $translate_from) = @_;

    # prepare generator for pipelined ra
    my @gen;
    # XXX: this is so wrong
    my $revprop = $self->mirror->depot->mirror->revprop;

    my $ra = $self->_new_ra;

    $ra->reparent( $translate_from
                   ? $self->source_root . $translate_from 
                   : $self->mirror->url)
        if $translate_from;

    if ( $self->use_pipeline ) {
        for (@$revs) {
            push @gen, [ 'rev_proplist', $_->[0] ] if $revprop;
            push @gen, [ 'replay', $_->[0], 0, 1, 'EDITOR' ];
        }
        $ra = SVK::Mirror::Backend::SVNRaPipe->new( $ra, sub { shift @gen } );
    }
    my $progress =
      $self->mirror->{use_progress}
      ? SVK::Notify->new->progress( max => scalar @$revs )
      : undef;
    my $pool = SVN::Pool->new_default;
    my $i = 0;
    for (@$revs) {
        $pool->clear;
        my ( $changeset, $metadata ) = @$_;
        my $extra_prop = {};
        if ($revprop) {
            my $prop = $ra->rev_proplist($changeset);
            for (@$revprop) {
                $extra_prop->{$_} = $prop->{$_}
                    if exists $prop->{$_};
            }
        }
        $self->sync_changeset( $changeset, $metadata, $extra_prop,
            $callback, sub {
                my $editor = shift;
                $ra->replay( $changeset, 0, 1, $editor );
                $self->_after_replay($ra, $editor);
            }, $translate_from );
        local $| = 1;
        print STDERR $progress->report( "%45b %p\r", ++$i ) if $progress;
    }
    print STDERR "\n" if $progress; # forced newline
    $self->_ra_finished($ra);
}

=item get_commit_editor


=cut

sub _relayed {
    my $self = shift;
    $self->mirror->server_uuid ne $self->mirror->source_uuid;
}

sub get_commit_editor {
    my ($self, $path, $msg, $committed, $opts) = @_;
    die loc("relayed merge back not supported yet.\n") if $self->_relayed;
    $self->{commit_ra} = $self->_new_ra( url => $self->mirror->url.$path );

    # XXX: add error check for get_commit_editor here, auth error happens here
    return SVN::Delta::Editor->new(
        $self->{commit_ra}->get_commit_editor(
            $msg,
            sub {
		# only recycle the ra if we are committing from root
		$self->_ra_finished($self->{commit_ra});
                $committed->(@_);
            }, $opts->{lock_tokens}, 0 ) );
}

sub change_rev_prop {
    my $self = shift;
    my $ra = $self->_new_ra;
    $ra->change_rev_prop(@_);
    $self->_ra_finished($ra);
}

1;

