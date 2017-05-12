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
package SVK::Command::Commit;
use strict;
use SVK::Version;  our $VERSION = $SVK::VERSION;
use base qw( SVK::Command );
use constant opt_recursive => 1;
use SVK::XD;
use SVK::I18N;
use SVK::Logger;
use SVK::Editor::Status;
use SVK::Editor::Dynamic;
use SVK::Command::Sync;
use SVK::Editor::InteractiveCommitter;
use SVK::Editor::InteractiveStatus;

use SVK::Util qw( get_buffer_from_editor slurp_fh read_file
		  tmpfile abs2rel from_native to_native
		  get_encoder get_anchor );

use Class::Autouse qw( SVK::Editor::Rename SVK::Editor::Merge );

sub options {
    ('m|message=s'    => 'message',
     'F|file=s'       => 'message_file',
     'C|check-only'   => 'check_only',
     'P|patch=s'      => 'patch',
     'import'         => 'import',
     'direct'         => 'direct',
     'template'       => 'template',
     'i|interactive'  => 'interactive',
     'set-revprop=s@' => 'setrevprop',
    );
}

sub parse_arg {
    my ($self, @arg) = @_;
    @arg = ('') if $#arg < 0;

    return $self->arg_condensed (@arg);
}

sub lock { $_[0]->lock_coroot($_[1]) }

sub target_prompt {
    loc('=== Targets to commit (you may delete items from it) ===');
}

sub unversioned_prompt {
    loc("=== You may change '?' to 'A' to add unversioned items ===");
}

sub message_prompt {
    loc('=== Please enter your commit message above this line ===');
}

sub under_mirror {
    my ($self, $target) = @_;
    return if $self->{direct};
    return $target->is_mirrored;
}

sub fill_commit_message {
    my $self = shift;
    if ($self->{message_file}) {
	die loc ("Can't use -F with -m.\n")
	    if defined $self->{message};
	$self->{message} = read_file ($self->{message_file});
    }
}

sub get_commit_message {
    my ($self, $extra_message) = @_;
    # The existence of $extra_message (the logs from a sm -l, say) should *not*
    # prevent the editor from being opened, if there is no -m/-F
    
    $self->fill_commit_message; # from -F to -m

    # We have to decide whether or not to launch the editor *before* we append
    # $extra_message to the -m/-F message
    my $should_launch_editor = ($self->{template} or not defined $self->{message});

    if (defined $extra_message or defined $self->{message}) {
	$self->{message} = join "\n", grep { defined $_ and length $_ } ($self->{message}, $extra_message);
    } 

    if ($should_launch_editor) {
	$self->{message} = get_buffer_from_editor
	    (loc('log message'), $self->message_prompt,
	     join ("\n", $self->{message} || '', $self->message_prompt, ''), 'commit');
	$self->{save_message} = $$;
    }
    $self->decode_commit_message;
}

sub decode_commit_message {
    my $self = shift;
    eval { from_native ($self->{message}, 'commit message', $self->{encoding}); 1 }
	or die $@.loc("try --encoding.\n");
}

# XXX: This should just return Editor::Dynamic objects
sub get_dynamic_editor {
    my ($self, $target) = @_;
    my $m = $self->under_mirror ($target);
    my $anchor = $m ? $m->path : '/';
    my ($storage, %cb) = $self->get_editor ($target->new (path => $anchor));

    my $editor = SVK::Editor::Dynamic->new
	( editor => $storage, root_rev => $cb{cb_rev}->(''),
	  inspector => $self->{parent} ? $cb{inspector} : undef );

    return ($anchor, $editor);
}

sub finalize_dynamic_editor {
    my ($self, $editor) = @_;
    $editor->close_edit;
    delete $self->{save_message};
}

sub adjust_anchor {
    my ($self, $editor) = @_;
    $editor->adjust;
}

sub save_message {
    my $self = shift;
    return unless $self->{save_message};
    return unless $self->{save_message} == $$;
    local $@;
    my ($fh, $file) = tmpfile ('commit', DIR => '', TEXT => 1, UNLINK => 0);
    print $fh $self->{message};
    $logger->warn(loc ("Commit message saved in %1.", $file));
}

# Return the editor according to copath, path, and is_mirror (path)
# It will be Editor::XD, repos_commit_editor, or svn::mirror merge back editor.
sub _editor_for_patch {
    my ($self, $target, $source) = @_;
    require SVK::Patch;
    my ($m);
    if (($m) = $target->is_mirrored) {
	$logger->info(loc("Patching locally against mirror source %1.", $m->url));
    }
    die loc ("Illegal patch name: %1.\n", $self->{patch})
	if $self->{patch} =~ m!/!;
    my $patch = SVK::Patch->new ($self->{patch}, $self->{xd},
				 $target->depotname, $source,
				 $target->as_depotpath->new(targets => undef));
    $patch->ticket (SVK::Merge->new (xd => $self->{xd}), $source, $target)
	if $source;
    $patch->{log} = $self->{message};
    my $fname = $self->{xd}->patch_file ($self->{patch});
    if ($fname ne '-' && -e $fname) {
	die loc ("file %1 already exists.\n", $fname).
	    ($source ? loc ("use 'svk patch regen %1' instead.\n", $self->{patch}) : '');
    }

    $target = $target->new->as_depotpath;
    $target->refresh_revision;
    my %cb = SVK::Editor::Merge->cb_for_root
	($target->root, $target->path_anchor,
	 $m ? $m->fromrev : $target->revision);
    # XXX: the insepctor's root doesn't belong to it, so we have to
    # hold the target for now.
    $cb{__hold_target} = $target;
    return ($patch->commit_editor ($fname),
	    %cb, send_fulltext => 0);
}

sub _commit_callback {
    my ($self, $callback) = @_;

    return sub {
	$logger->info(loc("Committed revision %1.", $_[0]));
	$callback->(@_) if $callback,
    }
}

sub get_editor {
    my ($self, $target, $callback, $source) = @_;
    # Commit as patch
    return $self->_editor_for_patch($target, $source)
	if defined $self->{patch};

    if (   !$target->isa('SVK::Path::Checkout')
        && !$self->{direct}
        && ( my $m = $target->is_mirrored ) ) {
        if ( $self->{check_only} ) {
            $logger->info(loc( "Checking locally against mirror source %1.", $m->url ))
		unless $self->{incremental};
        }
        else {
            $logger->warn(loc("Commit into mirrored path: merging back directly."))
                if ref($self) eq __PACKAGE__;    # XXX: output compat
            $logger->info(loc( "Merging back to mirror source %1.", $m->url ));
        }
    }
    else {
	$callback = $self->_commit_callback($callback)
    }

    my ($editor, $inspector, %cb) = $target->get_editor
	( ignore_mirror => $self->{direct},
	  check_only => $self->{check_only},
	  callback => $callback,
	  message => $self->{message},
	  author => $ENV{USER} );

    # Note: the case that the target is an xd is actually only used in merge.
    return ($editor, %cb, inspector => $inspector)
	if $target->isa('SVK::Path::Checkout');

    if ($self->{setrevprop}) {
	my $txn = $cb{txn} or
	    die loc("Can't use set-revprop with remote repository.\n");
	for (@{$self->{setrevprop}}) {
	    $txn->change_prop( split(/=/, $_) );
	}
    }


    unless ($self->{check_only}) {
	my $txn = $cb{txn};
	for ($SVN::Error::FS_TXN_OUT_OF_DATE,
	     $SVN::Error::FS_CONFLICT,
	     $SVN::Error::FS_ALREADY_EXISTS,
	     $SVN::Error::FS_NOT_DIRECTORY,
	     $SVN::Error::RA_DAV_REQUEST_FAILED,
	    ) {
	    # XXX: this error should actually be clearer in the destructor of $editor.
	    $self->clear_handler ($_);
	    # XXX: there's no copath info here
	    $self->msg_handler ($_, $cb{mirror} ? "Please sync mirrored path ".$target->path_anchor." first."
				       : "Please update checkout first.");
	    $self->add_handler( $_,
				sub {
				    $editor->abort_edit;
				    $txn->abort if $txn and not $cb{aborts_txn};
				} );
	}
	$self->clear_handler ($SVN::Error::REPOS_HOOK_FAILURE);
	$self->msg_handler($SVN::Error::REPOS_HOOK_FAILURE);
    }

    return ($editor, inspector => $inspector, %cb);
}

sub exclude_mirror {
    my ($self, $target) = @_;
    return () if $self->{direct};

    ( exclude => {
	map { substr ($_, length($target->path_anchor)) => 1 }
	    $target->contains_mirror },
    );
}

sub get_committable {
    my ($self, $target, $skipped_items) = @_;
    my ($fh, $file);
    $self->fill_commit_message;
    if ($self->{template} or not defined $self->{message}) {
	($fh, $file) = tmpfile ('commit', TEXT => 1, UNLINK => 0);
    }
    
    my @targets;
    my @unversioned;
    my $targets = [];
    my $encoder = get_encoder;
    my ($status_editor, $commit_editor, $conflict_handler);
    
    my $notify = SVK::Notify->new( 
        cb_flush => sub {
            my ($path, $status) = @_;
            to_native ($path, 'path', $encoder);
            my $copath = $target->copath ($path);
            push @$targets, [
                (($status->[0]||'') eq 'C' || ($status->[1]||'') eq 'C')? 'C'
                    : ($status->[0] || ($status->[1]? 'P' : '')),
                $copath
            ];
            no warnings 'uninitialized';
            push @targets, sprintf ("%1s%1s%1s \%s\n", @{$status}[0..2], $copath);
        }
    );
    
    if ($self->{interactive}) {
        $status_editor = SVK::Editor::InteractiveStatus->new
        (
            inspector => $target->source->inspector,
            notify => $notify,
            cb_skip_prop_change => sub {
                my ($path, $prop, $value) = @_;
                $skipped_items->{props}{$target->copath($path)}{$prop} = $value;
            },
            cb_skip_add => sub {
                my ($path, $prop) = @_;
                push @{$skipped_items->{adds}}, $target->copath($path);
            },
        ); 

       $commit_editor = SVK::Editor::InteractiveCommitter->new(
            inspector => $target->source->inspector,
            status => $status_editor, 
        );

    } else {
        $status_editor = SVK::Editor::Status->new(notify => $notify);
    }

    my %may_need_to_add;

    $self->{xd}->checkout_delta
	( $target->for_checkout_delta,
	  depth => $self->{recursive} ? undef : 0,
	  $self->exclude_mirror ($target),
	  xdroot => $target->create_xd_root,
	  nodelay => 1,
	  delete_verbose => 1,
	  absent_ignore => 1,
	  editor => $status_editor,
	  cb_conflict => sub { shift->conflict(@_) },
      cb_unknown  => sub {
          my ($self, $path) = @_;
          $path = $target->copath($path);
          $may_need_to_add{$path} = 1;
          push @unversioned, "?   $path\n";
      },
	);

    my $conflicts = grep {$_->[0] eq 'C'} @$targets;

    if ($#{$targets} < 0 || $conflicts) {
	if ($fh) {
	    close $fh;
	    unlink $file;
	}

	die loc("No targets to commit.\n") if $#{$targets} < 0;
	die loc("%*(%1,conflict) detected. Use 'svk resolved' after resolving them.\n", $conflicts);
    }

    if ($self->{interactive}) {
    	$target->{targets} =
            [map{abs2rel($_->[1], $target->{copath}, undef, '/')} @$targets];
    }

    if ($fh) {
	print $fh $self->{message} if $self->{template} and defined $self->{message};

    my $header = $self->target_prompt;
    $header .= "\n" . $self->unversioned_prompt
        if @unversioned;
	print $fh "\n", $header, "\n";

    print $fh @targets;
    print $fh @unversioned;

	close $fh;

        # get_buffer_from_editor may modify it, so it must be a ref first
        $target->source->{targets} ||= [];

	($self->{message}, $targets) =
	    get_buffer_from_editor (loc('log message'), $header,
				    undef, $file, $target->copath, $target->source->{targets});
	die loc("No targets to commit.\n") if $#{$targets} < 0;
	$self->{save_message} = $$;
	unlink $file;
    }

    # additional check for view
    # XXX: put a flag in view - as we can know well in advance
    # if the view is cross mirror and skip this check if not.
    if ($target->source->isa('SVK::Path::View')) {
	my $vt = $target->source;
	my $map = $vt->view->rename_map('');
	my @dtargets = map { abs2rel($_->[1], $target->copath => $target->path_anchor, '/') }
	    @$targets;
	# get actual anchor, condense
	my $danchor = Path::Class::Dir->new_foreign('Unix', $dtargets[0]);
	my $dactual_anchor = $vt->_to_pclass($vt->root->rename_check($danchor, $map), 'Unix');
	for (@dtargets) {
	    # XXX: ugly
	    until ($dactual_anchor->subsumes($vt->root->rename_check($_, $map))) {
		$danchor = $danchor->parent;
		$dactual_anchor = $vt->_to_pclass($vt->root->rename_check($danchor, $map), 'Unix');
	    }
	}
	until ($vt->root->check_path($danchor) == $SVN::Node::dir) {
	    $danchor = $danchor->parent;
            $dactual_anchor = $dactual_anchor->parent;
	}

	$target->copath_anchor(Path::Class::Dir->new($target->copath_anchor)->subdir
	    ( abs2rel($danchor, $vt->path_anchor => undef, '/') ));
	$vt->{path} = $danchor; # XXX: path_anchor is not an accessor yet!
	$vt->{targets} = [ map { abs2rel( $_, $vt->path_anchor => undef, '/' ) } @dtargets];
    }

    $self->decode_commit_message;

    my @need_to_add = map  { $_->[1] }
                      grep { $may_need_to_add{ $_->[1] } }
                      grep { $_->[0] eq 'A' }
                      @$targets;

    if (@need_to_add) {
        my $old_targets = $target->{targets};
        $target->{targets} = \@need_to_add;
        $self->{xd}->do_add($target,
            unknown_verbose => 1,
        );
        $target->{targets} = $old_targets;
    }

    return ($commit_editor, [sort {$a->[1] cmp $b->[1]} @$targets]);
}

sub committed_commit {
    my ($self, $target, $targets, $skipped_items) = @_;
    my $fs = $target->repos->fs;
    sub {
	my $rev = shift;
	my ($entry, $dataroot) = $self->{xd}{checkout}->get($target->copath($target->{copath_target}), 1);
	my (undef, $coanchor) = $self->{xd}->find_repos ($entry->{depotpath});
	my $oldroot = $fs->revision_root ($rev-1);
	# optimize checkout map
	for my $copath ($self->{xd}{checkout}->find ($dataroot, {revision => qr/.*/})) {
	    my $coinfo = $self->{xd}{checkout}->get ($copath, 1);
	    next if $coinfo->{'.deleted'};
	    my $orev = eval { $oldroot->node_created_rev (abs2rel ($copath, $dataroot => $coanchor, '/')) };
	    defined $orev or next;
	    # XXX: cache the node_created_rev for entries within $target->path
	    next if $coinfo->{revision} < $orev;
	    $self->{xd}{checkout}->store ($copath, {revision => $rev}, {override_descendents => 0});
	}
	# update checkout map with new revision
	for (reverse @$targets) {
	    my ($action, $path) = @$_;
	    $self->{xd}{checkout}->store ($path,
                                          { $self->_schedule_empty },
                                          {override_sticky_descendents => $self->{recursive}});
            if (($action eq 'D') and $self->{xd}{checkout}->get ($path, 1)->{revision} == $rev ) {
                # Fully merged, remove the special node
                $self->{xd}{checkout}->store (
                    $path, { revision => undef, $self->_schedule_empty }
                );
            }
            else {
                $self->{xd}{checkout}->store (
                    $path, {
                        revision => $rev,
                        ($action eq 'D') ? ('.deleted' => 1) : (),
                    }
                )
            }
	}

    # regenerate schedule information about skipped properties...
    for (keys %{$skipped_items->{props}}) {
        $self->{xd}{checkout}->store($_, {
            '.newprop' => $skipped_items->{props}{$_},
            '.schedule' => 'prop'
        });
    }

    # ...and files in interactive commit mode.
    $self->{xd}{checkout}->store($_, {'.schedule' => 'add' })
        for @{$skipped_items->{adds}};

	# XXX: fix view/path revision insanity
	my $root = $target->source->new->refresh_revision->root(undef);
	# update keyword-translated files
	my $encoder = get_encoder;
	for (@$targets) {
	    my ($action, $copath) = @$_;
	    next if $action eq 'D' || -d $copath;
	    my $path = $target->path_anchor;
	    $path = "$path"; # XXX: Fix to_native
	    $path = '' if $path eq '/';
	    to_native($path, 'path', $encoder);
	    my $dpath = abs2rel($copath, $target->copath_anchor => $path, '/');
	    from_native ($dpath, 'path', $encoder);
	    my $prop = $root->node_proplist ($dpath);
	    my $layer = SVK::XD::get_keyword_layer ($root, $dpath, $prop);
	    my $eol = SVK::XD::get_eol_layer ($prop, '>');
	    # XXX: can't bypass eol translation when normalization needed
	    next unless $layer || ($eol ne ':raw' && $eol ne ' ');

            # We need to read the file for normalization from the
            # checkout, not from the repository, since if we just did
            # an interactive commit, there may be skipped changes
            # there.
            #
            # Pretty sure that the input does not need to have keyword
            # or eol translation itself, though this might not be
            # right (esp eol).
            #
            # Have to use a temp file for the content because
            # otherwise we'd be reading and writing a file
            # simultaneously.

            my ($basedir, $basefile) = get_anchor(1, $copath);
            my $basename = "$basedir.svk.$basefile.commit-base";

	    my $perm = (stat ($copath))[2];
            rename ($copath, $basename)
              or do { warn loc("rename %1 to %2 failed: %3", $copath, $basename, $!), next };

            open my ($fh), '<:raw', $basename or die $!; 

	    open my ($newfh), ">$eol", $copath or die $!;
	    $layer->via ($newfh) if $layer;
	    slurp_fh ($fh, $newfh);
            close $fh;
            unlink $basename;

	    chmod ($perm, $copath);
	}
    }
}

sub committed_import {
    my ($self, $copath) = @_;
    sub {
	my $rev = shift;
	$self->{xd}{checkout}->store
	    ($copath, {revision => $rev, $self->_schedule_empty}, {override_sticky_descendents => 1});
    }
}

sub run {
    my ($self, $target) = @_;

    # XXX: should use some status editor to get the committed list for post-commit handling
    # while printing the modified nodes.
    my $skipped_items = {};
    my $committed;
    my ($commit_editor, $committable);
    if ($self->{import}) {
      $self->get_commit_message () unless $self->{check_only};
      $committed = $self->committed_import ($target->copath_anchor);
    }
    else {
      ($commit_editor, $committable) = $self->get_committable($target, $skipped_items);
      $committed = $self->committed_commit ($target, $committable, $skipped_items);
    }

    my ($editor, %cb) = $self->get_editor ($target->source, $committed);
    #$editor = SVN::Delta::Editor->new(_editor=>[$editor], _debug=>1);

    if ($commit_editor) {
        $commit_editor->{storage} = $editor;
        $commit_editor->{status}{storage} = $editor;

        $editor = $commit_editor;
    }

    #die loc("unexpected error: commit to mirrored path but no mirror object")
    #	if $target->is_mirrored and !($self->{direct} or $self->{patch} or $cb{mirror});

    $self->run_delta ($target, $target->create_xd_root, $editor, %cb);
}

sub run_delta {
    my ($self, $target, $xdroot, $editor, %cb) = @_;

    $self->{xd}->checkout_delta
	( $target->for_checkout_delta,
	  depth => $self->{recursive} ? undef : 0,
	  debug => $logger->is_debug(),
	  xdroot => $xdroot,
	  editor => $editor,
	  send_delta => !$cb{send_fulltext},
	  nodelay => $cb{send_fulltext},
	  $self->exclude_mirror ($target),
	  cb_exclude => sub { $logger->error(loc ("%1 is a mirrored path, please commit separately.",
					 abs2rel ($_[1], $target->copath => $target->report))) },
	  $self->{import} ?
	  ( auto_add => 1,
	    obstruct_as_replace => 1,
	    absent_as_delete => 1) :
	  ( absent_ignore => 1),
	  cb_copyfrom => $cb{cb_copyfrom}
	);
    delete $self->{save_message};
    return;
}

sub DESTROY {
    $_[0]->save_message;
}

1;

__DATA__

=head1 NAME

SVK::Command::Commit - Commit changes to depot

=head1 SYNOPSIS

 commit [PATH...]

=head1 OPTIONS

 --import               : import mode; automatically add and delete nodes
 --interactive          : interactively select which "chunks" to commit
 -m [--message] MESSAGE : specify commit message MESSAGE
 -F [--file] FILENAME   : read commit message from FILENAME
 --encoding ENC         : treat -m/-F value as being in charset encoding ENC
 --template             : use the specified message as the template to edit
 -P [--patch] NAME      : instead of commit, save this change as a patch
 -C [--check-only]      : try operation but make no changes
 -N [--non-recursive]   : operate on single directory only
 --set-revprop P=V      : set revision property on the commit
 --direct               : commit directly even if the path is mirrored

