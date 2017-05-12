package SVN::Mirror::Ra;
@ISA = ('SVN::Mirror');
$VERSION = '0.73';
use strict;
use SVN::Core;
use SVN::Repos;
use SVN::Fs;
use SVN::Delta;
use SVN::Ra;
use SVN::Client ();
use constant OK => $SVN::_Core::SVN_NO_ERROR;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    %$self = @_;
    $self->{source} =~ s{/+$}{}g;

    @{$self}{qw/source source_root source_path/} =
	_parse_source ($self->{source});

    @{$self}{qw/rsource rsource_root rsource_path/} =
	_parse_source ($self->{rsource}) if $self->{rsource};

    return $self;
}

sub _parse_source {
    my $source = shift;
    my ($root, $path) = split ('!', $source, 2);
    $path ||= '';
    return (join('', $root, $path), $root, $path)
}

sub _store_source {
    my ($root, $path) = @_;
    return join('!', $root, $path);
}

sub _get_prop {
    my ($self, $ra, $path, $propname) = @_;
}

sub _is_descendent {
    my ($parent, $child) = @_;
    return 1 if $parent eq $child;
    $parent = "$parent/" unless $parent eq '/';
    return $parent eq substr ($child, 0, length ($parent));
}

sub _check_overlap {
    my ($self) = @_;
    my $fs = $self->{repos}->fs;
    my $root = $fs->revision_root ($fs->youngest_rev);
    for (map {$root->node_prop ($_, 'svm:source')} SVN::Mirror::list_mirror ($self->{repos})) {
	my (undef, $source_root, $source_path) = _parse_source ($_);
	next if $source_root ne $self->{source_root};
	die "Mirroring overlapping paths not supported\n"
	    if _is_descendent ($source_path, $self->{source_path})
	    || _is_descendent ($self->{source_path}, $source_path);
    }
}

sub init_state {
    my ($self, $txn) = @_;
    my $ra = $self->_new_ra (url => $self->{source});

    my $uuid = $self->{source_uuid} = $ra->get_uuid ();
    my $source_root = $ra->get_repos_root ();
    my $path = $self->{source};
    $txn->abort, die "source url not under source root"
	if substr($path, 0, length($source_root), '') ne $source_root;

    $self->{source_root} = $source_root;
    $self->{source_path} = $path;
    $self->{fromrev} = 0;

    # XXX: abort txn before dying
    $self->_check_overlap;

    # check if the url exists
    if ($ra->check_path ('', -1) != $SVN::Node::dir) {
	$txn->abort;
	die "$self->{source} is not a directory.\n";
    }
    unless ($self->{source} eq $self->{source_root}) {
	undef $ra; # bizzare perlgc
	$ra = $self->_new_ra (url => $self->{source_root});
    }

    # check if mirror source is already a mirror
    # older SVN::RA will return Reporter so prop would be undef
    my (undef, undef, $prop) = eval { $ra->get_dir ('', -1) };
    warn "Unable to read $ra->{url}, relay support disabled\n" if $@;
    if ($prop && $prop->{'svm:mirror'}) {
	my $rroot;
	for ($prop->{'svm:mirror'} =~ m/^.*$/mg) {
	    if (_is_descendent ($_, $self->{source_path})) {
		$rroot = $_;
		last;
	    }
	    elsif (_is_descendent ($self->{source_path}, $_)) {
		$txn->abort, die "Can't relay mirror outside mirror anchor $_";
	    }
	}
	if ($rroot) {
	    $rroot =~ s|^/||;
	    (undef, undef, $prop) = $ra->get_dir ($rroot, -1);
	    $txn->abort, die "relayed mirror source doesn't not have svm:source"
		unless exists $prop->{'svm:source'};
	    @{$self}{qw/rsource rsource_root rsource_path/} =
		@{$self}{qw/source source_root source_path/};
	    $self->{rsource_uuid} = $uuid;
	    $self->{source_path} =~ s|^/\Q$rroot\E||;
	    @{$self}{qw/source source_uuid/} = @{$prop}{qw/svm:source svm:uuid/};
	    $self->{source} .= '!' if index ($self->{source}, '!') == -1;
	    @{$self}{qw/source source_root source_path/} =
		_parse_source ($self->{source}.$self->{source_path});

	    $txn->abort, die "relayed source and source have same repository uuid"
		if $self->{source_uuid} eq $self->{rsource_uuid};

	    my $txnroot = $txn->root;
	    $txnroot->change_node_prop ($self->{target_path}, 'svm:rsource',
					_store_source ($source_root, $path));
	    $txnroot->change_node_prop ($self->{target_path}, 'svm:ruuid',
					$uuid);
	    $txn->change_prop ("svm:headrev", "$self->{rsource_uuid}:$self->{fromrev}\n");

	    return _store_source ($self->{source_root}, $self->{source_path});
	}
    }

    @{$self}{qw/rsource rsource_root rsource_path/} =
	@{$self}{qw/source source_root source_path/};

    $self->{rsource_uuid} = $self->{source_uuid};

    $txn->change_prop ("svm:headrev", "$self->{rsource_uuid}:$self->{fromrev}\n");
    return _store_source ($source_root, $path);
}

sub load_state {
    my ($self) = @_;

    my $prop = $self->{root}->node_proplist ($self->{target_path});
    @{$self}{qw/source_uuid rsource_uuid/} =
	@{$prop}{qw/svm:uuid svm:ruuid/};
    unless ($self->{rsource}) {
	@{$self}{qw/rsource rsource_root rsource_path/} =
	    @{$self}{qw/source source_root source_path/};
	$self->{rsource_uuid} = $self->{source_uuid};
    }

    die "please upgrade the mirror state\n"
	if $self->{root}->node_prop ('/', join (':', 'svm:mirror', $self->{source_uuid},
						$self->{source_path} || '/'));

    unless ($self->{ignore_lock}) {
	die "no headrev"
	    unless defined $self->load_fromrev;
    }
    return;
}

sub _new_ra {
    my ($self, %arg) = @_;
    $self->{config} ||= SVN::Core::config_get_config(undef, $self->{pool});
    $self->{auth} ||= $self->_new_auth;

    SVN::Ra->new( url => $self->{rsource},
		  auth => $self->{auth},
		  config => $self->{config},
		  %arg);
}

sub _new_auth {
    my ($self) = @_;
    # create a subpool that is not automatically destroyed
    my $pool = SVN::Pool::create (${$self->{pool}});
    $pool->default;
    my ($baton, $ref) = SVN::Core::auth_open_helper([
        SVN::Client::get_simple_provider (),
        SVN::Client::get_ssl_server_trust_file_provider (),
        SVN::Client::get_username_provider (),
        SVN::Client::get_simple_prompt_provider( $self->can('_simple_prompt'), 2),
        SVN::Client::get_ssl_server_trust_prompt_provider( $self->can('_ssl_server_trust_prompt') ),
        SVN::Client::get_ssl_client_cert_prompt_provider( $self->can('_ssl_client_cert_prompt'), 2 ),
        SVN::Client::get_ssl_client_cert_pw_prompt_provider( $self->can('_ssl_client_cert_pw_prompt'), 2 ),
        SVN::Client::get_username_prompt_provider( $self->can('_username_prompt'), 2),
    ]);
    $self->{auth_ref} = $ref;
    return $baton;
}

sub _simple_prompt {
    my ($cred, $realm, $default_username, $may_save, $pool) = @_;

    if (defined $default_username and length $default_username) {
        print "Authentication realm: $realm\n" if defined $realm and length $realm;
        $cred->username($default_username);
    }
    else {
        _username_prompt($cred, $realm, $may_save, $pool);
    }

    $cred->password(_read_password("Password for '" . $cred->username . "': "));
    $cred->may_save($may_save);

    return OK;
}

sub _ssl_server_trust_prompt {
    my ($cred, $realm, $failures, $cert_info, $may_save, $pool) = @_;

    print "Error validating server certificate for '$realm':\n";

    print " - The certificate is not issued by a trusted authority. Use the\n",
          "   fingerprint to validate the certificate manually!\n"
      if ($failures & $SVN::Auth::SSL::UNKNOWNCA);

    print " - The certificate hostname does not match.\n"
      if ($failures & $SVN::Auth::SSL::CNMISMATCH);

    print " - The certificate is not yet valid.\n"
      if ($failures & $SVN::Auth::SSL::NOTYETVALID);

    print " - The certificate has expired.\n"
      if ($failures & $SVN::Auth::SSL::EXPIRED);

    print " - The certificate has an unknown error.\n"
      if ($failures & $SVN::Auth::SSL::OTHER);

    printf(
        "Certificate information:\n".
        " - Hostname: %s\n".
        " - Valid: from %s until %s\n".
        " - Issuer: %s\n".
        " - Fingerprint: %s\n",
        map $cert_info->$_, qw(hostname valid_from valid_until issuer_dname fingerprint)
    );

    print(
        $may_save
            ? "(R)eject, accept (t)emporarily or accept (p)ermanently? "
            : "(R)eject or accept (t)emporarily? "
    );

    my $choice = lc(substr(<STDIN> || 'R', 0, 1));

    if ($choice eq 't') {
        $cred->may_save(0);
        $cred->accepted_failures($failures);
    }
    elsif ($may_save and $choice eq 'p') {
        $cred->may_save(1);
        $cred->accepted_failures($failures);
    }

    return OK;
}

sub _ssl_client_cert_prompt {
    my ($cred, $realm, $may_save, $pool) = @_;

    print "Client certificate filename: ";
    chomp(my $filename = <STDIN>);
    $cred->cert_file($filename);

    return OK;
}

sub _ssl_client_cert_pw_prompt {
    my ($cred, $realm, $may_save, $pool) = @_;

    $cred->password(_read_password("Passphrase for '%s': "));

    return OK;
}

sub _username_prompt {
    my ($cred, $realm, $may_save, $pool) = @_;

    print "Authentication realm: $realm\n" if defined $realm and length $realm;
    print "Username: ";
    chomp(my $username = <STDIN>);
    $username = '' unless defined $username;

    $cred->username($username);

    return OK;
}

sub _read_password {
    my ($prompt) = @_;

    print $prompt;

    require Term::ReadKey;
    Term::ReadKey::ReadMode('noecho');

    my $password = '';
    while (defined(my $key = Term::ReadKey::ReadKey(0))) {
        last if $key =~ /[\012\015]/;
        $password .= $key;
    }

    Term::ReadKey::ReadMode('restore');
    print "\n";

    return $password;
}

sub _revmap {
    my ($self, $rev, $ra) = @_;
    $ra ||= $self->{cached_ra};
    $SVN::Core::VERSION ge '1.1.0' ?
	$ra->rev_prop ($rev, 'svm:headrev') :
	$ra->rev_proplist ($rev)->{'svm:headrev'};
}

sub committed {
    my ($self, $revmap, $date, $sourcerev, $rev) = @_;
    $self->{headrev} = $rev;

    # Even though we set this on the transaction, we need to set it
    # again after commit, since the fs will always make it the current
    # time after committing.
    $self->{fs}->change_rev_prop($rev, 'svn:date', $date);

    $self->unlock ('mirror');
    print "Committed revision $rev from revision $sourcerev.\n";
}

our $debug;

sub mirror {
    my ($self, $fromrev, $paths, $rev, $author, $date, $msg, $ppool) = @_;
    my $ra;

    if ($debug and eval { require BSD::Resource; 1 }) {
	my ($usertime, $systemtime,
	    $maxrss, $ixrss, $idrss, $isrss, $minflt, $majflt, $nswap,
	    $inblock, $oublock, $msgsnd, $msgrcv,
	    $nsignals, $nvcsw, $nivcsw) = BSD::Resource::getrusage();
	print ">>> mirroring $rev:\n";
	print ">>> $usertime $systemtime $maxrss $ixrss $idrss $isrss\n";
    }

    my $pool = SVN::Pool->new_default ($ppool);
    my ($newrev, $revmap);

    $ra = $self->{cached_ra}
	if exists $self->{cached_ra_url} &&
	    $self->{cached_ra_url} eq $self->{rsource};
    if ($ra && $self->{rsource} =~ m/^http/ && --$self->{cached_life} == 0) {
	undef $ra;
    }
    $ra ||= $self->_new_ra;

    $revmap = $self->_revmap ($rev, $ra) if $self->_relayed;
    $revmap ||= '';

    my $txn = $self->{repos}->fs_begin_txn_for_commit
	($self->{fs}->youngest_rev, $author, $msg);
    $txn->change_prop('svk:commit', '*')
	if $self->{fs}->revision_prop(0, 'svk:notify-commit');

    $txn->change_prop('svn:date', $date);
    # XXX: sync remote headrev too
    $txn->change_prop('svm:headrev', $revmap."$self->{rsource_uuid}:$rev\n");
    $txn->change_prop('svm:incomplete', '*')
	if $self->{rev_incomplete};

    my $editor = SVN::Mirror::Ra::NewMirrorEditor->new
	($self->{repos}->get_commit_editor2
	 ($txn, '', $self->{target_path}, $author, $msg,
	  sub { $newrev = $_[0];
		$self->committed ($revmap, $date, $rev, @_) }));

    $self->{working} = $rev;
    $editor->{mirror} = $self;

    @{$self}{qw/cached_ra cached_ra_url/} = ($ra, $self->{rsource});

    $self->{cached_life} ||= 100; # some leak in ra_dav, so reconnect every 100 revs
    $editor->{target} ||= '' if $SVN::Core::VERSION gt '0.36.0';

=begin NOTES

The structure of mod_lists:

* Key is the path of a changed path, a relative path to source_path.
  This is what methods in MirrorEditor get its path, therefore easier
  for them to look up information.

* Value is a hash, containing the following values:

  * action: 'A'dd, 'M'odify, 'D'elete, 'R'eplace
  * remote_path: The path on remote depot
  * remote_rev: The revision on remote depot
  * local_rev:
    * Not Add: -1
    * Add but source is not in local depot: undef
    * Add and source is in local depot: the source revision in local depot
  * local_path: The mapped path of key, ie. the changed path, in local
    depot.
  * local_source_path:
    * Source path is not in local depot: undef
    * Source path is in local depot: a string
  * source_node_kind: Only meaningful if action is 'A'.

=cut

    $editor->{mod_lists} = {};
    foreach ( keys %$paths ) {
	my $spool = SVN::Pool->new_default;
        my $item = $paths->{$_};
	s/\n/ /g; # XXX: strange edge case
        my $href;

        my $svn_lpath = my $local_path = $_;
        if ( $editor->{anchor} ) {
            $svn_lpath = $self->{rsource_root} . $svn_lpath;
            $svn_lpath =~ s|^\Q$editor->{anchor}\E/?||;
            my $source_path = $self->{rsource_path} || "/";
            $local_path =~ s|^\Q$source_path\E|$self->{target_path}|;
        } else {
            $svn_lpath =~ s|^\Q$self->{rsource_path}\E/?||;
            $local_path = "$self->{target_path}/$svn_lpath";
        }

	my $local_rev = -1;
	unless ($item->copyfrom_rev == -1) {
	    $local_rev = $self->find_local_rev
		($item->copyfrom_rev, $self->{rsource_uuid});
	}
	# XXX: the logic of the code here is a mess!
        my ($action, $rpath, $rrev, $lrev) =
            @$href{qw/action remote_path remote_rev local_rev local_path/} =
                ( $item->action,
                  $item->copyfrom_path,
                  $item->copyfrom_rev,
		  $local_rev,
                  $local_path,
                );
	# workaround fsfs remoet_path inconsistencies
	$rpath = "/$rpath" if $rpath && substr ($rpath, 0, 1) ne '/';
        my ($src_lpath, $source_node_kind) = (undef, $SVN::Node::unknown);
	# XXX: should check if the copy is within the anchor before resolving lrev
        if ( defined $lrev && $lrev != -1 ) {
	    $src_lpath = $rpath;
	    # copy within mirror anchor
            if ($src_lpath =~ s|^\Q$self->{rsource_path}\E/|$self->{target_path}/|) {
		# $source_node_kind is used for deciding if we need reporter later
		my $rev_root = $self->{fs}->revision_root ($lrev);
		$source_node_kind = $rev_root->check_path ($src_lpath);
	    }
	    else {
		($src_lpath, $href->{local_rev}) = (undef, undef);
	    }
	}
	elsif ($rrev != -1) {
	    # The source is not in local depot.  Invalidate this
	    # copy.
	    ($src_lpath, $href->{local_rev}) =
		$self->{cb_copy_notify}
		? $self->{cb_copy_notify}->($self, $local_path, $rpath, $rrev)
		: (undef, undef)
        }
	$src_lpath =~ s/%/%25/g if defined $src_lpath;
        @$href{qw/local_source_path source_node_kind/} =
            ( $src_lpath, $source_node_kind );

	# XXX: the loop should not reached here if changed path is
	# not interesting to us, skip them at the beginning the the loop
        if ( $_ eq $self->{rsource_path} or
	     index ("$_/", "$self->{rsource_path}/") == 0 ) {
            $editor->{mod_lists}{$svn_lpath} = $href;
            $editor->{mod_lists}{$svn_lpath}{path} = $svn_lpath;
        } elsif ($rrev != -1 && $href->{action} eq 'A' &&
		 index ($self->{rsource_path}, "$_/") == 0) {
	    # special case for the parent of the anchor is copied.
	    my $reanchor = $self->{rsource_path};
            my $path = length $svn_lpath ? "$svn_lpath/$reanchor" : $reanchor;
	    $reanchor =~ s{^\Q$_\E/}{};
	    $href->{remote_path} .= '/'.$reanchor;
	    $href->{local_path} = $self->{target_path};
            $editor->{mod_lists}{$path} = $href;
            $editor->{mod_lists}{$path}{path} = $path;
        }
    }

    unless (keys %{$editor->{mod_lists}}) {
	my $root = $editor->open_root($self->{headrev});
	$editor->change_dir_prop ($root, svm => undef);
	$editor->close_directory($root);
	$editor->close_edit;
    } else {
        my @mod_list = sort keys %{$editor->{mod_lists}};
	# mark item as directory that we are sure about.
	# do not use !isdir for deciding the item is _not_ a directory.
	for my $parent (@mod_list) {
	    for (@mod_list) {
		next if $parent eq $_;
		if (index ("$_/", "$parent/") == 0) {
		    $editor->{mod_lists}{$parent}{isdir} = 1;
		    last;
		}
	    }
	}
        if (($self->{skip_to} && $self->{skip_to} <= $rev) ||
	     grep { my $href = $editor->{mod_lists}{$_};
                    !( ( ($href->{action} eq 'A' || $href->{action} eq 'R')
                         && ((defined $href->{local_rev}
			      && $href->{local_rev} != -1
			      && $href->{source_node_kind} == $SVN::Node::dir)
			     || ($href->{isdir})
			    ))
                       || $href->{action} eq 'D' )
                } @mod_list ) {
	    my $pool = SVN::Pool->new_default_sub;

            my $start = $fromrev || ($self->{skip_to} ? $fromrev : $rev-1);
            my $reporter =
                $ra->do_update ($rev, $editor->{target} || '', 1, $editor);
	    my @lock = $SVN::Core::VERSION ge '1.2.0' ? (undef) : ();

	    if ($fromrev == 0 || $start == 0) {
		$reporter->set_path ('', $rev, 1, @lock); # start_empty
	    }
	    else {
		$reporter->set_path ('', $start, 0, @lock);
	    }

            $reporter->finish_report ();
        } else {
            # Copies only.  Don't bother fetching full diff through network.
            my $edit = SVN::Simple::Edit->new
                (_editor => [$editor],
                 missing_handler => \&SVN::Simple::Edit::open_missing
                );

            $edit->open_root ($self->{headrev});

            foreach (@mod_list) {
                my $href = $editor->{mod_lists}{$_};
                my $action = $href->{action};

		if ($action eq 'D' || $action eq 'R') {
		    # XXX: bad pool usage here, but svn::simple::edit sucks
                    $edit->delete_entry($_);
                }

		# can't use a new pool for these, because we need to
		# keep the parent.  switch to svk dynamic editor when we can
                if ($action eq 'A' || $action eq 'R') {
		    my $ret;
		    if (defined $href->{local_rev} && $href->{local_rev} != -1) {
			$ret = $edit->copy_directory( $_, $href->{local_source_path},
						      $href->{local_rev});
		    }
		    else {
			$ret = $edit->add_directory($_);
		    }
                    $edit->close_directory($_) if $ret;
		}
	    }
            $edit->close_edit ();
        }
    }
    return if defined $self->{mirror}{skip_to} &&
        $self->{mirror}{skip_to} > $rev;

    my $prop;
    $prop = $ra->rev_proplist ($rev) if $self->{revprop};
    for (@{$self->{revprop}}) {
	$self->{fs}->change_rev_prop($newrev, $_, $prop->{$_})
	    if exists $prop->{$_};
    }
}

sub _relayed { $_[0]->{rsource} ne $_[0]->{source} }

sub _debug_args { map { $_ = '' if !defined($_) } @_ }

sub get_merge_back_editor {
    my ($self, $path, $msg, $committed) = @_;
    die "relayed merge back not supported yet" if $self->_relayed;
    @{$self}{qw/cached_ra cached_ra_url/} =
	($self->_new_ra ( url => "$self->{source}$path"), "$self->{source}$path" );

    $self->{commit_ra} = $self->{cached_ra};
    $self->load_fromrev;
    my @lock = $SVN::Core::VERSION ge '1.2.0' ? (undef, 0) : ();
    return ($self->{fromrev}, SVN::Delta::Editor->new
	    ($self->{cached_ra}->get_commit_editor ($msg, $committed, @lock)));
}

sub switch {
    my ($self, $url) = @_;
    my $ra = $self->_new_ra (url => $url);
    # XXX: get proper uuid like init_state
    die "uuid is different" unless $ra->get_uuid eq $self->{source_uuid};
    # warn "===> switching from $self->{source} to $url";
    # get a txn, change rsource and rsource_uuidto new url
}

sub get_latest_rev {
    my ($self, $ra) = @_;
    # don't care about real last-modified rev num unless in skip to mode.
    return $ra->get_latest_revnum
	unless $self->{skip_to};
    my ($rev, $headrev);
    my $offset = 2;

    # there were once get_log2, but it then was refactored by the svn_ra
    # overhaul.  We have to check the version.
    # also, it's harmful to make use of the limited get_log for svn 1.2
    # vs svnserve 1.1, it retrieves all logs and leave the connection
    # in an inconsistent state.
    if ($SVN::Core::VERSION ge '1.2.0' && $self->{rsource} !~ m/^svn/) {
        $ra->get_log ([''], $ra->get_latest_revnum, 0, 1, 0, 1,
    		   sub { $rev = $_[1] });
    }
    else {
        until (defined $rev) {
	    $headrev = $ra->get_latest_revnum
		unless defined $headrev;

	    $headrev -= $offset;
	    $ra->get_log ([''], -1, $headrev,
			  ($SVN::Core::VERSION ge '1.2.0') ? (0) : (),
			  0, 1,
			  sub { $rev = $_[1] unless defined $rev});
	    if ( $offset < $headrev ) {
		$offset*=2;
	    }
	    else {
		$offset = 2;
	    }
	}
    }

    die 'fatal: unable to find last-modified revision'
	unless defined $rev;
    return $rev;
}

sub run {
    my $self = shift;
    my $ra = $self->_new_ra;
    my $latestrev = $self->get_latest_rev ($ra);

    $self->lock ('sync');
    $self->load_fromrev;
    # there were code here to use find_local_rev, but it will get base that
    # is too old for use, if there are relocate happening.
    # but this might cause race condition, while we also have lock now, need
    # to take a closer look.
    $self->{headrev} = $self->{fs}->youngest_rev;
    if ($self->{skip_to} && $self->{skip_to} =~ m/^HEAD(?:-(\d+))?/) {
	$self->{skip_to} = $latestrev - ($1 || 0);
    }
    my $startrev = ($self->{skip_to} || 0);
    $startrev = $self->{fromrev}+1 if $self->{fromrev}+1 > $startrev;
    my $endrev = shift || -1;
    if ($endrev && $endrev =~ m/^HEAD(?:-(\d+))?/) {
        $endrev = $latestrev - ($1 || 0);
    }
    $endrev = $latestrev if $endrev == -1;

    print "Syncing $self->{source}".($self->_relayed ? " via $self->{rsource}\n" : "\n");

    $self->unlock ('sync'), return
	unless $endrev == -1 || $startrev <= $endrev;

    print "Retrieving log information from $startrev to $endrev\n";

    my $firsttime = 1;
    eval {
    $ra->get_log ([''], $startrev, $endrev,
		  ($SVN::Core::VERSION ge '1.2.0') ? (0) : (),
		  1, 1,
		  sub {
		      my ($paths, $rev, $author, $date, $msg, $pool) = @_;
		      # for the first time, skip_to might not hit
		      # active revision in the tree. adjust to make it so.
		      if ($firsttime) {
			  $self->{skip_to} = $rev if defined $self->{skip_to};
			  $firsttime = 0;
		      }
		      # move the anchor detection stuff to &mirror ?
		      if (defined $self->{skip_to} && $rev <= $self->{skip_to}) {
			  # XXX: get the logs for skipped changes
			  $self->{rev_incomplete} = 1;
			  $author = 'svm';
			  $msg = sprintf('SVM: skipping changes %d-%d for %s',
					 $self->{fromrev}, $rev, $self->{rsource});
		      }
		      else {
			  delete $self->{rev_incomplete};
		      }
		      $self->mirror($self->{fromrev}, $paths, $rev, $author,
				    $date, $msg, $pool);
		      $self->{fromrev} = $rev;
		  });
    };

    delete $self->{cached_ra};
    delete $self->{cached_ra_url};

    $self->unlock ('sync');

    return unless $@;
    if ($@ =~ /no item/) {
	print "Mirror source already removed.\n";
	undef $@;
    }
    else {
	die $@;
    }
}

sub DESTROY {
}

package SVN::Mirror::Ra::NewMirrorEditor;
our @ISA = ('SVN::Delta::Editor');
use strict;

#use Smart::Comments '###', '####';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub set_target_revision {
    return;
}

# class method
# _visited_path_item( $path, $pass_thru, $copied, $ref_mod )
# ref_mod is the reference item in mod_list.
sub _visited_path_item {
    return { path      => shift,
             pass_thru => shift,
             copied    => shift,
             ref_mod   => shift,
           };
}

# object method
# visit_path( $path, @args )
# @args are as the same as _visited_path_item().  '-inherit' for
# inheriting from the counterpart of the last path.
#
# Call this method whenever a directory is entered.
sub visit_path {
    my ($self, $path) = (shift, shift);

    my $last = $self->{visited_paths}[-1];
    my @inherited = @$last{qw/pass_thru copied ref_mod/};
    my @args = map { my $o = shift @inherited;
                     ( ( $_ || '' ) eq '-inherit' ) ? $o : $_
                 } @_;
    push @{$self->{visited_paths}}, _visited_path_item( $path, @args );

    return $self;
}

# Call this method whenever a directory is left.
sub leave_path {
    my ($self) = @_;

    my $last = $self->{visited_paths}[-1];
    pop @{$self->{visited_paths}};

    return $self;
}

sub is_pass_thru { $_[0]->{visited_paths}[-1]{pass_thru} }

sub is_copied { $_[0]->{visited_paths}[-1]{copied} }

sub _remove_entries_in_path {
    my ($self, $path, $pb, $pool) = @_;

    foreach ( sort grep $self->{mod_lists}{$_}{action} eq 'D',
              keys %{$self->{mod_lists}} ) {
        next unless m{^\Q$path\E/([^/]+)$};
        $self->delete_entry ($_, -1, $pb, $pool);
    }
}

# Return undef if not in modified list, action otherwise.
# 'A'dd, 'D'elete, 'R'eplace, 'M'odify
sub _in_modified_list {
    my ($self, $path) = @_;

    if (exists $self->{mod_lists}{$path}) {
        return $self->{mod_lists}{$path}{action};
    } else {
        return;
    }
}

# From source to target.  Given a path what svn lib gives, get a path
# where it should be.
sub _translate_rel_path {
    my ($self, $path) = @_;

    if ( exists $self->{mod_lists}{$path} ) {
        return $self->{mod_lists}{$path}{local_path};
    } else {
        if ( $self->{anchor} ) {
            $path = "$self->{anchor}/$path";
            $path =~ s|\Q$self->{mirror}{rsource_root}\E||;
        } else {
            $path = "$self->{mirror}{rsource_path}/$path";
        }
        $path =~ s|^\Q$self->{mirror}{rsource_path}\E|$self->{mirror}{target_path}|;
        return $path;
    }

}

# If there's modifications under specified path, return true.
sub _contains_mod_in_path {
    my ($self, $path) = @_;

    foreach ( reverse sort keys %{$self->{mod_lists}} ) {
        return $self->{mod_lists}{$_}
            if index ($_, $path, 0) == 0;
    }

    return;
}

# Given a path, return true if it is a copied path.
sub _is_copy {
    my ($self, $path) = @_;

    return exists $self->{mod_lists}{$path} &&
        $self->{mod_lists}{$path}{remote_path};
}

# Given a path, return source path and revision number in local depot.
sub _get_copy_path_rev {
    my ($self, $path) = @_;

    return unless exists $self->{mod_lists}{$path};
    my ($cp_path, $cp_rev) =
        @{$self->{mod_lists}{$path}}{qw/local_source_path local_rev/};
    return ($cp_path, $cp_rev);
}

sub open_root {
    my ($self, $remoterev, $pool) =@_;
    ### open_root()...
    ### $remoterev

    # {visited_paths} keeps track of visited paths.  Parents at the
    # beginning of array, and children the end.  '' means '/'.  $path
    # passed to add_directory() and other methods are in the form of
    # 'deep/path' instead of '/deep/path'.
    $self->{visited_paths} = [ _visited_path_item( '', undef) ];

    $self->{root} = $self->SUPER::open_root($self->{mirror}{headrev}, $pool);
}

sub open_file {
    my ($self,$path,$pb,undef,$pool) = @_;
    ### open_file()...
    ### $path
    return undef unless $pb;

    my $action = $self->_in_modified_list ($path);
    ### Action for path is action...
    ### $path
    ### $action
    if ( $self->is_pass_thru() && !$action ) {
        #### Skip this file...
        return undef;
    }
    if ( ($action || '') eq 'R' ) {
        my $item = $self->{mod_lists}{$path};
	return $self->add_file($path, $pb, undef, -1, $pool)
	    unless defined $item->{remote_rev} xor defined $item->{local_rev};
	# If we are replacing with history and the source is out side
	# of the mirror, assume assume a simple replace.  Note that
	# the server would send a delete+add if the source is actually
	# unrelated.
    }

    ++$self->{changes};
    return $self->SUPER::open_file ($path, $pb,
				    $self->{mirror}{headrev}, $pool);
}

sub change_dir_prop {
    my $self = shift;
    my $baton = shift;
    ### change_dir_prop()...
    ### $_[0]
    ### $_[1]

    # filter wc specified stuff
    return unless $baton;
    return if $_[0] =~ /^svm:/;
    return if $_[0] =~ /^svn:(?:entry|wc):/;
    return $self->SUPER::change_dir_prop ($baton, @_)
}

sub change_file_prop {
    my $self = shift;
    ### change_file_prop()...
    ### $_[1]
    ### $_[2]

    # filter wc specified stuff
    return unless $_[0];
    return if $_[1] =~ /^svn:(?:entry|wc):/;
    return $self->SUPER::change_file_prop (@_)
}

sub apply_textdelta {
    my $self = shift;
    return undef unless $_[0];
    ### apply_textdelta()...
    ### $_[0]

    $self->SUPER::apply_textdelta (@_);
}

sub open_directory {
    my ($self,$path,$pb,undef,$pool) = @_;
    ### open_directory()...
    ### $path
    return undef unless $pb;

    if ( ($self->_in_modified_list($path) || '') eq 'R' ) {
        ### Found an R item...
	# if the path is replaced with history, from outside the
	# mirror anchor... HATE
	my $bogus_copy = $self->_is_copy($path) && !defined $self->{mod_lists}{$path}{local_source_path};
	if ($bogus_copy ) {
            ##### Is a bogus...
	    $self->visit_path( $path,
			       0, 1, # copy but source not in local
			       $self->{mod_lists}{$path} );
	}
	else {
            ##### Call add_directory()...
	    return $self->add_directory($path, $pb, undef, -1, $pool);
	}
    }

    my $dir_baton = $self->SUPER::open_directory ($path, $pb,
                                                  $self->{mirror}{headrev},
                                                  $pool);

    $self->visit_path( $path, '-inherit', '-inherit', '-inherit' );
    ### Visit info for this path: $self->{visited_paths}[-1]

    if ($self->is_pass_thru()) {
        ### Under latest copy, remove entries under path...
        # $self->_enter_new_copied_path();
        $self->_remove_entries_in_path ($path, $dir_baton, $pool);
    }

    ++$self->{changes};
    return $dir_baton;
}

# Return an array of two elements: if pass thru and if copied.
sub _visit_info_for_dir {
    my $copyrev = shift;

    if ( !defined($copyrev) ) {
        ### Copy source is not in local depot...
        return ( 0, 1 );                # copy but source not in local
    } elsif ( $copyrev == -1 ) {
        ### Usual action...
        return ( 0, 0 );                # not a copy
    } else {
        ### Copy source is in local depot...
        return ( 1, 1 );                # copy with source in local
    }
}

=comment

Please keep in mind that subversion's update editor is optimized for
file system.  That's why we need to keep many data in add_directory()
because we need to deal with many different situations.

It means open_directory() or add_directory() (as well as counterparts
for files) is called depends on the existence of the target directory.
An add_diectory() call in a file system may be not necessary in a
repostiroy.  If a directory is copied from another directory in a
repository, every directory or file under it needs a add_directory()
or add_file() call, but absolutely not necessary in another
repository, since they are brought automatically by the copy
operation.  If some entries are deleted under the copied diectory, no
add_directory() and add_file() is necessary in a file system, but
explicit calls to delete_entry() are needed in a repository.

=cut

sub add_directory {
    my $self = shift;
    my $path = shift;
    my $pb = shift;
    my (undef,undef,$pool) = @_;
    my ($copypath, $copyrev) = $self->_get_copy_path_rev( $path );
    my $crazy_replace;
    ### add_directory()...
    ### $path
    ### $copypath
    ### $copyrev
    return undef unless $pb;

    # rules:
    # in mod_lists, not under copied path:
    #   * A: add_directory()
    #   * M: open_directory()
    #   * R: delete_entry($path), add_directory()
    # under copied path, with local copy source:
    #   * in mod_lists:
    #     A: add_directory()
    #     M: open_directory()
    #     R: delete_entry($path), add_directory()
    #   * not in mod_lists:
    #     * Modifications in the path:
    #       * open_directory().
    #     * No modification in the path:
    #       * Ignore unconditionally.
    # under copied path, without local copy source:
    #   ( add_directory() unconditionally )

    my $method = 'add_directory';
    my $action = $self->_in_modified_list ($path);
    my $do_remove_items = undef;
    if (defined $self->{mirror}{skip_to} &&
        $self->{mirror}{skip_to} >= $self->{mirror}{working}) {
        # no-op.
    } elsif ( $action ) {
        ### Change item.  Action : $action
        my $item = $self->{mod_lists}{$path};
        ### More info: $item

        my @visit_info;
        if ( $action eq 'A' ) {
            ### Add a directory...
            @visit_info = _visit_info_for_dir( $copyrev );
            if ( $visit_info[0] && $visit_info[1] ) {
                $do_remove_items = 1;
                splice (@_, 0, 2, $copypath, $copyrev);
            }
            push @visit_info, $item;
        } elsif ( $action eq 'M' ) {
            ### Modify a directory...
            $method = 'open_directory';
            @visit_info = ( '-inherit', # as parent
                            '-inherit', # as parent
                            $item
                          );
	    $do_remove_items = 1;
        } elsif ( $action eq 'R' ) {
            ### Replace a directory...
            $self->delete_entry ($path,
                                 $self->{mirror}{headrev},
                                 $pb, $pool);

            @visit_info = _visit_info_for_dir( $copyrev );
            if ( $visit_info[0] && $visit_info[1] ) {
                $do_remove_items = 1;
                splice (@_, 0, 2, @$item{qw/local_source_path local_rev/});
            }
	    if ($copypath) {
		++$crazy_replace;
		$visit_info[0] = 0; # don't pass thru for crazy replace
	    }
            push @visit_info, $item;
        }
        $self->visit_path( $path, @visit_info );
    } elsif ( $self->is_pass_thru() ) {
        ### Is pass thru...

        # We are supposed to pass everything, but check if we have
        # modifications under current path.
        if ( (my $ref_mod = $self->_contains_mod_in_path ($path)) ) {
            ### Contains modifications under path...
            #### ref_mod : $ref_mod
            $do_remove_items = 1;
            if ( $ref_mod->{path} ne $path ) { $ref_mod = undef }
            $self->visit_path( $path,
                               '-inherit',   # should not pass thru
                               '-inherit',       # yes, copied
                               $ref_mod # whatever previous node is
                             );
            $method = 'open_directory';
        } else {
            ### No modifications under path.  Bypass anything under it...
            return;
        }
    } elsif ( $self->is_copied() ) {
        ### Not pass thru, but is copied.  Modifications under path...
        $method = 'open_directory';
        $self->visit_path( $path,
                           '-inherit',  # pass_thru
                           '-inherit',  # copied
                           '-inherit'   # ref_mod
                         );
    } else {
        my $item = $self->{mod_lists}{$path};
        ### path is not catched by conditionals...
        ### Action : $action
        ### Mod item : $item
        ### Last item in visited paths : $self->{visited_paths}[-1]
        $self->visit_path( $path,
                           '-inherit',  # pass_thru
                           '-inherit',  # copied
                           '-inherit'   # ref_mod
                         );
    }

    ### Visit info for this path: $self->{visited_paths}[-1]

    $method = "open_directory" if $path eq $self->{target};
    my $tran_path = $self->_translate_rel_path ($path);
    $method = 'open_directory'
        if $tran_path eq $self->{mirror}{target_path};

    my $dir_baton;
    if ( $method eq 'open_directory' ) {
        my @args = @_;
        splice @args, 0, 2, $self->{mirror}{headrev};
        $dir_baton = eval {
            $self->SUPER::open_directory ($tran_path, $pb, @args);
        };
        if ( $@ ) {
            $dir_baton = $self->SUPER::add_directory ($tran_path, $pb, @_);
        }
    } else {
        $dir_baton = $self->SUPER::add_directory ($tran_path, $pb, @_);
    }

    $self->_remove_entries_in_path ($path, $dir_baton, $pool) if $do_remove_items;

    ++$self->{changes};

    if ($crazy_replace) {
	# When there's a replace with history, we need to replay the
	# diff between the base (which we reconstruct the replace
	# with) and the actual new revision.  The problem is that
	# do_update gives us only the delta between our fromrev and
	# current rev, which is unusable if we are reconstructing the
	# copy.
        my $item = $self->{mod_lists}{$path};
	my $remote_path = $item->{remote_path};
	$remote_path =~ s/%/%25/g;
	my $ra = $self->{mirror}->_new_ra( url => "$self->{mirror}{source_root}$remote_path" );
	my $compeditor = SVN::Mirror::Ra::CompositeEditor->new
	    ( master_editor => $self,
	      anchor => $path, anchor_baton => $dir_baton );
	$path =~ s/%/%25/g;
	my ($reporter) =
	    $ra->do_diff($self->{mirror}{working}, '', 1, 1,
			 "$self->{mirror}{source}/$path", $compeditor);
	my @lock = $SVN::Core::VERSION ge '1.2.0' ? (undef) : ();
	$reporter->set_path('', $item->{remote_rev}, 0, @lock);
	$reporter->finish_report ();

        $self->close_directory($dir_baton);
	return undef;
    }

    return $dir_baton;
}

sub add_file {
    my $self = shift;
    my $path = shift;
    my $pb = shift;
    my ($copypath, $copyrev) = $self->_get_copy_path_rev( $path );
    ### add_file()...
    ### $path
    ### $copypath
    ### $copyrev
    return undef unless $pb;

    my $method = 'add_file';
    my $action = $self->_in_modified_list ($path);
    my $crazy_replace;

    if ((defined $self->{mirror}{skip_to}
         && $self->{mirror}{skip_to} >= $self->{mirror}{working})) {
        ### Skiped...
        # no-op.  add_file().
    } elsif ( $action ) {
        ### With action: $action
        if ( !defined($copyrev) || $copyrev == -1) {
            # no-op
        } else {
            ### Come with a copy source.  Use its information...
            ### $copypath
            ### $copyrev
            splice (@_, 0, 2, $copypath, $copyrev);
        }

        if ($action eq 'M') {
            ### Modify...
            # splice @_, 0, 2, $self->{mirror}{headrev};
            $method = 'open_file';
        } elsif ($action eq 'R') {
            ### Replace...
	    $self->delete_entry ($path, $self->{mirror}{headrev}, $pb, $_[-1]);
	    if ($copypath) {
		++$crazy_replace;
	    }
        }
    } elsif ( $self->is_pass_thru() ) {
        ### Pass thru, and not in mod list.  SKip it...
        return;
    } elsif ( $self->is_copied() ) {
        ### path is copied from somewhere.  Accept it...
        # no-op.
    } else {
        my $item = $self->{mod_lists}{$path};
        ### path is not catched by conditionals...
        ### Action : $action
        ### Mod item : $item
        ### Last item in visited paths : $self->{visited_paths}[-1]
    }

    my $tran_path = $self->_translate_rel_path ($path);

    # Why try open_file() first then add_file() later?  I saw a weird
    # rev which looks like:
    #
    #   A  /path
    #   A  /path/foo
    #   M  /path/bar
    #   A  /path/baz
    #
    # /path/bar should be A because /path is A.  Anyway, to accept
    # this rev, falling back to add_file() if open_file() fails will
    # do.
    #
    # - plasma
    ++$self->{changes};
    if ($method eq 'open_file') {
        my @args = @_;
        splice @args, 0, 2, $self->{mirror}{headrev};
        my $res = eval {
            $self->SUPER::open_file ($tran_path, $pb, @args);
        };
        if (!$@) { return $res }
    }

    my $file_baton = $self->SUPER::add_file ($tran_path, $pb, @_);

    if ($crazy_replace) {
        my $item = $self->{mod_lists}{$path};
	my $remote_path = $item->{remote_path};
	$remote_path =~ s/%/%25/g;
	my ($anchor, $target) = "$self->{mirror}{rsource_root}$remote_path" =~ m{(.*)/([^/]+)};
	my $ra = $self->{mirror}->_new_ra( url => $anchor );
	my $compeditor = SVN::Mirror::Ra::CompositeEditor->new
	    ( master_editor => $self,
	      anchor => $path, anchor_baton => $pb,
	      target => $target, target_baton => $file_baton );

	$path =~ s/%/%25/g;
	my ($reporter) =
	    $ra->do_diff($self->{mirror}{working}, $target, 1, 1,
			 "$self->{mirror}{rsource}/$path", $compeditor);
	my @lock = $SVN::Core::VERSION ge '1.2.0' ? (undef) : ();
	my ($tgt) = $path =~ m{([^/]+)$/};
	$reporter->set_path('', $item->{remote_rev}, 0, @lock);
	$reporter->finish_report ();

        $self->close_file($file_baton, undef); # XXX: md5

	return undef;
    }

    return $file_baton;
}

sub close_directory {
    my $self = shift;
    my $baton = shift;
    ### close_directory()...
    ### $self->{visited_paths}[-1]{path}
    return unless $baton;

    $self->leave_path();

    # 'touch' the root if there's no change.
    $self->change_dir_prop ( $baton, 'svm' => undef )
	if $baton eq $self->{root} && !$self->{changes};

    $self->SUPER::close_directory ($baton, @_);
}

sub close_file {
    my $self = shift;
    ### close_file()...
    return unless $_[0];
    $self->SUPER::close_file(@_);
}

sub delete_entry {
    my ($self, $path, $rev, $pb, $pool) = @_;
    ### delete_entry()...
    ### $path
    ### $rev
    return unless $pb;
    if ( $self->is_pass_thru() ) {
	my $action = $self->_in_modified_list($path) || '';
	return unless $action eq 'D' || $action eq 'R';
    }
    ++$self->{changes};
    $self->SUPER::delete_entry ($path, $self->{mirror}{headrev},
				$pb, $pool);
}

sub close_edit {
    my ($self, $pool) = @_;
    ### close_edit()...

    unless ($self->{root}) {
        # If we goes here, this must be an empty revision.  We must
        # replicate an empty revision as well.
        $self->open_root ($self->{mirror}{headrev}, $pool);
	$self->SUPER::close_directory ($self->{root}, $pool);
    }
    delete $self->{root};
    local $SIG{INT} = 'IGNORE';
    local $SIG{TERM} = 'IGNORE';

    $self->{mirror}->lock ('mirror');
    $self->SUPER::close_edit ($pool);
}

package SVN::Mirror::Ra::CompositeEditor;
our @ISA = ('SVN::Delta::Editor');
# XXX: this is from svk, should be merged

sub AUTOLOAD {
    my ($self, @arg) = @_;
    my $func = our $AUTOLOAD;
    $func =~ s/^.*:://;

    if ($func =~ m/^(?:add|open|delete)/) {
        return $self->{target_baton}
            if defined $self->{target} && $arg[0] eq $self->{target};
        $arg[0] = length $arg[0] ?
            "$self->{anchor}/$arg[0]" : $self->{anchor};
    }
    elsif ($func =~ m/^close_(?:file|directory)/) {
        if (defined $arg[0]) {
            return if $arg[0] eq $self->{anchor_baton};
            return if defined $self->{target_baton} &&
                $arg[0] eq $self->{target_baton};
        }
    }

    $self->{master_editor}->$func(@arg);
}

sub set_target_revision {}

sub open_root {
    my ($self, $base_revision) = @_;
    return $self->{anchor_baton};
}

sub close_edit {}

1;
