# See copyright, etc in below POD section.
######################################################################

package SVN::S4::ViewSpec;
require 5.006_001;

use strict;
use Carp;
use IO::Dir;
use IO::File;
use DBI;
use DBD::SQLite;
use Cwd;
use Digest::MD5;
use vars qw($AUTOLOAD);

use SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);
use SVN::S4::Path;

our $VERSION = '1.064';
our $Info = 1;


#######################################################################
# Methods

#######################################################################
#######################################################################
#######################################################################
#######################################################################
# OVERLOADS of S4 object
package SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);

our @list_actions;

sub die_viewspec {
    my $self = shift;
    my $msg = join('',@_);
    die "s4: %Error: $self->{vs_fileline}: $msg\n";
}

sub viewspec_hash {
    my $self = shift;
    my $text_to_hash = "";
    foreach (@{$self->{vs_actions}}) {
        $text_to_hash .= "$_->{cmd} $_->{url} $_->{dir}\n";
	# just omit rev.
    }
    my $viewspec_hash = Digest::MD5::md5_hex($text_to_hash);
    #DEBUG "s4: viewspec is $viewspec_hash\n";
    return $viewspec_hash;
}

sub viewspec_changed {
    my $self = shift;
    my %params = (#path=>
                  @_);
    my $vshash = $self->viewspec_hash;
    $self->read_viewspec_state (path=>$params{path});
    if (!defined $self->{prev_state}) { return 1; } # if not found, return true.
    my $oldhash = $self->{prev_state}->{viewspec_hash} || "not found";
    if (!defined $oldhash) { return 1; } # if not found, return true.
    DEBUG "s4: Compare hash '$vshash' against old '$oldhash'\n" if $self->debug;
    return ($vshash ne $oldhash);
}

sub parse_viewspec {
    my $self = shift;
    my %params = (#filename=>,
		  #revision=>,
                  @_);
    $self->{vs_actions} = [];
    $self->_parse_viewspec_recurse(%params);
}

sub _parse_viewspec_recurse {
    my $self = shift;
    my %params = (#filename=>,
		  #revision=>,
                  @_);
    my $fn = $params{filename};
    # NOTE: parse_viewspec must be called with revision parameter.
    # But when a viewspec includes another viewspec, this function will be
    # called again and revision will be undefined.
    $self->{revision} = $params{revision} if $params{revision};
    # Remember the top level viewspec file. When doing an include, the included
    # file is relative to the top level one.
    $self->{viewspec_path} = $params{filename} if !$self->{viewspec_path};
    DEBUG "s4: params{revision} = $params{revision}\n" if $self->debug && $params{revision};
    DEBUG "s4: now my revision variable is $self->{revision}\n" if $self->debug && $self->{revision};
    # Replace ^
    $fn = $self->_viewspec_expand_root($fn);
    my $fh = new IO::File;
    if ($fn =~ m%://%) {
        # treat it as an svn url
	$fh->open ("svn cat $fn |") or die "s4: %Error: cannot run svn cat $fn";
    } else {
	# When opening an include file, we search relative to the top level
	# viewspec filename.  If it's not an absolute path, prepend the directory
	# part of the top level viewspec name.
	if ($fn !~ m%^/%) {
	    my @dirs = File::Spec->splitdir ($self->{viewspec_path});
	    pop @dirs;
	    push @dirs, File::Spec->splitdir ($fn);
	    my $candidate = File::Spec->catdir (@dirs);
	    DEBUG "s4: Making $fn relative to $self->{viewspec_path}. candidate is $candidate\n" if $self->debug;
	    # if the file exists, accept the $candidate
	    $fn = $candidate if (-f $candidate);
	}
	$fh->open ("< $fn") or die "s4: %Error: cannot open file $fn";
    }
    while (<$fh>) {
        s/#.*//;       # hash mark means comment to end of line
	s/^\s+//;      # remove leading space
	s/\s+$//;      # remove trailing space
	next if /^$/;  # remove empty lines
	#DEBUG ("viewspec: $_\n") if $self->debug;
	$self->_parse_viewspec_line ($fn, $_);
    }
    $fh->close;
}

sub _parse_viewspec_line {
    my $self = shift;
    my $filename = shift;
    my $line = shift;
    my @args = split(/\s+/, $line);
    $self->{vs_fileline} = "$filename:$.";  # for die_viewspec
    $self->_expand_viewspec_vars (\@args);
    my $cmd = shift @args;
    if ($cmd eq 'view') {
        $self->_viewspec_cmd_view (@args);
    } elsif ($cmd eq 'unview') {
        $self->_viewspec_cmd_unview (@args);
    } elsif ($cmd eq 'include') {
        $self->_viewspec_cmd_include (@args);
    } elsif ($cmd eq 'set') {
        $self->_viewspec_cmd_set (@args);
    } else {
	if ($line =~ /(>>>>>>|<<<<<<|======)/) {
	    $self->die_viewspec("It looks like viewspec has SVN conflict markers in it\n");
	}
        $self->die_viewspec("Unrecognized command in Project.viewspec: '$cmd'\n");
    }
}

sub _expand_viewspec_vars {
    my $self = shift;
    my $listref = shift;
    my %vars;
    for (my $i=0; $i<=$#$listref; $i++) {
	my $foo;
        #DEBUG "before substitution: $listref->[$i]\n" if $self->debug;
	# Note this doesn't expand ${digit}, those are regular expression replacements
	$listref->[$i] =~ s/\$([A-Za-z_]+[A-Za-z0-9_]*)/$self->{viewspec_vars}->{$1}/g;
	#DEBUG "after substitution: $listref->[$i]\n" if $self->debug;
    }
}

sub _viewspec_expand_root {
    my $self = shift;
    my $url = shift;
    if ($url =~ s!^\^!!) {
	my $root = $self->file_root(filename=>$self->{viewspec_path});
	$url = $root.$url;
	DEBUG "expanded url to $url\n" if $self->debug;
    }
    return $url;
}

sub _viewspec_regexp_urlbase {
    my $self = shift;
    my $url = shift;
    if ($url !~ /[\(\)]/) {  # No wildcard
	return $url;
    } else {
	# Find directory part of url
	my $urlbase = $url;
	$urlbase =~ s!\(.*$!!;
	$urlbase =~ s!/[^/]*$!! or $self->die_viewspec("In viewspec, wildcard URL is missing base path");
	DEBUG "regexp URL found: '$url' base is '$urlbase'\n" if $self->debug;
	# Note _expand assumes that urlbase is a prefix of $url
	return $urlbase;
    }
}

sub _viewspec_regexp_expand {
    my $self = shift;
    my $url = shift;
    my $dir = shift;
    my $rev = shift;
    my $urlbase = $self->_viewspec_regexp_urlbase($url);
    if ($urlbase eq $url) {  # No wildcard
	$dir !~ /\$\d+/ or $self->die_viewspec("In viewspec, \$ expansion requested with no regexp\n");
	return ({url=>$url, dir=>$dir});
    } else {
	my $pattern = substr($url,length($urlbase)+1);  # +1 for the /
	DEBUG "s4: ls $urlbase -r $rev\n" if $self->debug;
	my $dirent = $self->client->ls($urlbase,
				       $rev,
				       0, # recurive
				       );
	keys %{$dirent} or $self->die_viewspec("In viewspec, wildcard URL '$url' matches no objects");
	#print Dumper($dirent);
	my @out;
	foreach my $basename (sort keys %{$dirent}) {
	    # Accelerate future is_file_in_repo
	    $self->known_file_in_repo(revision=>$rev, url=>$urlbase."/".$basename);
	    if ($basename =~ /^$pattern$/) {
		my $one = $1;  my $two = $2;

		my $urlexp = $url;
		$urlexp =~ s!\([^\)]*\)!$one!;
		$urlexp =~ s!\([^\)]*\)!$two!;
		$urlexp !~ m!\(! or $self->die_viewspec("Unsupported in viewspec, wildcard URL '$url' with more than two groups");

		my $direxp = $dir;
		$direxp =~ s!\$1!$one!g;
		$direxp =~ s!\$2!$two!g;
		push @out, {url=>$urlexp, dir=>$direxp};
		DEBUG "view wildcard: '$url' hit  '$basename' -> '$urlexp' '$direxp'\n" if $self->debug;
	    } else {
		DEBUG "view wildcard: '$url' miss '$basename' via pattern '$pattern'\n" if $self->debug;
	    }
	}
	return @out;
    }
}

sub _viewspec_cmd_view {
    my $self = shift;
    my ($url, $dir, $revtype, $rev) = @_;
    $revtype = "" if !defined $revtype;
    $rev = "" if !defined $rev;
    DEBUG "_viewspec_cmd_view: url=$url  dir=$dir  revtype=$revtype  rev=$rev\n" if $self->debug;
    if (!defined $url || !defined $dir) {
        $self->die_viewspec("In viewspec, view command requires URL and DIR argument\n");
    }
    # Allow @PEGREV
    my ($pegurl,$pegrev) = SVN::S4::Getopt->parse_pegrev($url);
    $url = $pegurl;
    if ($pegrev) {
	!$revtype or $self->die_viewspec("In viewspec, rev specified along with \@PEGREV: $url\n");
	$revtype = 'rev';
	$rev = $pegrev;
    }
    # Replace ^
    $url = $self->_viewspec_expand_root($url);
    # Find a URL point we can reference
    my $urlbase = $self->_viewspec_regexp_urlbase($url);
    # check syntax of revtype,rev
    if ($revtype eq 'rev') {
	# string in $rev should be a revision number
    } elsif ($revtype eq 'date') {
	$self->ensure_valid_date_string($rev);
	$rev = "{$rev}";
	$rev = $self->rev_on_date(url=>$urlbase, date=>$rev);
    } elsif ($self->{revision}) {
	$rev = $self->{revision};
    } else {
	$self->die_viewspec("In viewspec, view line missing revision variable");
    }
    $self->ensure_valid_rev_string($rev);

    foreach my $expref ($self->_viewspec_regexp_expand($url,$dir,$rev)) {
	my $urlexp = $expref->{url};
	my $direxp = $expref->{dir};

	# if there is already an action on this directory, abort.
	foreach (@{$self->{vs_actions}}) {
	    if ($direxp eq $_->{dir}) {
		$self->die_viewspec("In viewspec, one view line collides with a previous one for directory '$direxp'. You must either remove one of the view commands or add an 'unview' command before it.\n");
	    }
	}
	my $action = {fileline => $self->{vs_fileline}};
	$action->{cmd} = "switch";
	$action->{url} = $urlexp;
	$action->{dir} = $direxp;
	$action->{rev} = $rev;
	push @{$self->{vs_actions}}, $action;
    }
}

sub _viewspec_cmd_unview {
    my $self = shift;
    my ($dir) = @_;
    DEBUG "_viewspec_cmd_unview: dir=$dir\n" if $self->debug;
    my @act_out = grep {
	my $cmd = $_->{cmd};
	my $actdir = $_->{dir};
	DEBUG "  checking $cmd on $actdir\n" if $self->debug;
	if ($cmd eq 'switch' && $actdir =~ m!^$dir([/\\]|$)!) {
	    DEBUG "    deleting action=$cmd on dir=$dir\n" if $self->debug;
	    0;
	} else {
	    1;
	}
    } @{$self->{vs_actions}};
    $self->{vs_actions} = \@act_out;
}

sub _viewspec_cmd_include {
    my $self = shift;
    my ($file) = @_;
    DEBUG "_viewspec_cmd_include $file\n" if $self->debug;
    $self->{parse_viewspec_include_depth}++;
    $self->die_viewspec("Excessive viewspec includes. Is this infinite recursion?")
         if $self->{parse_viewspec_include_depth} > 100;
    $self->_parse_viewspec_recurse (filename=>$file);
    $self->{parse_viewspec_include_depth}--;
}

sub _viewspec_cmd_set {
    my $self = shift;
    my ($var,$value) = @_;
    DEBUG "_viewspec_cmd_set $var = $value\n" if $self->debug;
    $self->{viewspec_vars}->{$var} = $value;
}

# Call with $s4->viewspec_compare_rev($rev)
# Compares every action in the viewspec against $rev, and returns true
# if every part of the tree will be switched to $rev.  If any rev mismatches,
# returns false.
sub viewspec_compare_rev {
    my $self = shift;
    my ($rev_to_match) = @_;
    foreach my $action (@{$self->{vs_actions}}) {
	my $rev = $action->{rev};
	if ($rev ne $rev_to_match) {
	    return undef; # found inconsistent revs, return false
	}
    }
    return 1;  # all revs were the same, return true
}

sub apply_viewspec {
    my $self = shift;
    my %params = (#path=>,
                  @_);
    DEBUG "revision is $self->{revision}\n" if $self->{revision} && $self->debug;
    $self->{viewspec_managed_switches} = [];  # ref to empty array
    my $base_uuid;
    foreach my $action (sort {$a->{dir} cmp $b->{dir}}
			@{$self->{vs_actions}}) {
	my $dbg = "Action: ";
        foreach my $key (sort keys %$action) {
	    $dbg .= "$key=$action->{$key} ";
	}
	DEBUG "$dbg\n" if $self->debug;
	unless ($base_uuid) {
	    my $base_url = $self->file_url (filename=>$params{path});
	    $base_uuid = $self->client->uuid_from_url ($base_url);
	    DEBUG "Base repository UUID is $base_uuid\n" if $self->debug;
	}

	if ($action->{cmd} eq 'switch') {
	    my $reldir = $action->{dir};
	    push @{$self->{viewspec_managed_switches}}, $reldir;
	    if (!-e "$params{path}/$reldir") {
	        # Directory does not exist yet. Use the voids trick to create
		# a versioned directory there that is switched to an empty dir.
		DEBUG "s4: Creating empty directory to switch into: $reldir\n" if $self->debug;
		my $basedir = $params{path};
		$self->_create_switchpoint_hierarchical($basedir, $reldir);
	    }
	    my $rev = $action->{rev};
	    if ($rev eq 'HEAD') {
	        die "s4: %Error: with '-r HEAD' in the viewspec actions list, the tree can have inconsistent revision numbers.  This is thus not allowed.\n";
	    }

	    my $url = $self->file_url(filename=>"$params{path}/$reldir");
	    my $verb;
	    my $cleandir = $self->clean_filename("$params{path}/$reldir");
	    if ($url && $url eq $action->{url}) {
		my $cmd = "$self->{svn_binary} update $cleandir -r$rev";
		$cmd .= ' --quiet' if $self->quiet;
		if (!$self->quiet) {
		    print "s4: Updating $reldir\n";
		}
		$self->run ($cmd);
	    } else {
		if (!$self->is_file_in_repo(url=>$action->{url}, revision=>$rev)) {
		    die "s4: %Error: Cannot switch to nonexistent URL: $action->{url}";
		}
		DEBUG "s4: uuid_from_url $action->{url}\n" if $self->debug;
		my $uuid = $self->client->uuid_from_url($action->{url});
		if ($uuid ne $base_uuid) {
		    die "s4: %Error: URL $action->{url} is in a different repository! What you need is an SVN external, which viewspecs presently do not support.";
		}
		my $ign = ($self->svn_version >= 1.7) ? "--ignore-ancestry" : "";
		my $cmd = "$self->{svn_binary} switch $ign $action->{url} $cleandir -r$rev";
		$cmd .= ' --quiet' if $self->quiet;
		if (!$self->quiet) {
		    print "s4: Switching $reldir";
		    my $rootre = quotemeta($self->file_root(path=>$action->{url}));
		    (my $showurl = $action->{url}) =~ s/$rootre/^/;
		    print " to $showurl";
		    print " rev $rev" if $rev ne 'HEAD';
		    print "\n";
		}
		$self->run ($cmd);
	    }
	} else {
	    die "s4: %Error: unknown s4 viewspec command: $action\n";
	}
    }
    # Look for any switch points that S4 __used to__ maintain, but no longer does.
    # Undo those switch points, if possible.
    $self->_undo_switches (basepath=>$params{path});
    # Set viewspec hash in the S4 object.  The caller MAY decide to save the
    # state by calling $self->save_viewspec_state, or not.
    $self->{viewspec_hash} = $self->viewspec_hash;
}

sub _undo_switches {
    my $self = shift;
    my %params = (#basepath=>,
                  @_);
    DEBUG "s4: undo_switches basepath = $params{basepath}\n" if $self->debug;
    # Find the list of switchpoints that S4 created
    # If it can't be found, just return.
    if (!$self->{prev_state}) {
        DEBUG "s4: _undo_switches cannot find prev_state, no undo needed\n" if $self->debug;
	return;
    }
    if (!$self->{prev_state}->{viewspec_managed_switches}) {
        DEBUG "s4: _undo_switches cannot find previous list of viewspec_managed_switches, no undo needed\n" if $self->debug;
	return;
    }
    my @prevlist = sort @{$self->{prev_state}->{viewspec_managed_switches}};
    my @thislist = sort @{$self->{viewspec_managed_switches}};
    DEBUG "s4: prevlist: ", join(' ',@prevlist), "\n" if $self->debug;
    DEBUG "s4: thislist: ", join(' ',@thislist), "\n" if $self->debug;
    foreach my $dir (@prevlist) {
	# I'm only interested in directories that were in @prevlist but
	# are not in @thislist.  If dir is in both lists, quit.
        next if grep(/^$dir$/, @thislist);
	if (grep(/^$dir/, @thislist)) {
	    # There is another mountpoint in @thislist that starts
	    # with $dir, in other words there is a mountpoint underneath
	    # this one.  We can't remove the dir, but leave it in the
	    # state file, so we can remove it when we have the chance.
	    DEBUG "s4: Remember that we manage $dir\n" if $self->debug;
	    push @{$self->{viewspec_managed_switches}}, $dir;
	    next;
	}
	print "s4: Remove unused switchpoint $dir\n";
	$self->_remove_switchpoint (dir=>$dir, basepath=>$params{basepath});
    }
}

sub _remove_switchpoint {
    my $self = shift;
    my %params = (#basepath=>,
		  #dir=>,
                  @_);
    # The algorithm is:
    # 1. svn switch it to an empty directory, e.g. REPO/void
    # 2. svn status --no-ignore in the directory.  If it is totally empty, then
    #    3. rm -rf directory, so that we forget that the dir was ever switched
    #    4. svn up directory, which makes it disappear from the parent
    my $dirpart = $params{dir};
    $dirpart =~ s/.*\///;
    my $path = "$params{basepath}/$params{dir}";
    my $abspath = $self->abs_filename($path);
    if (! -d $abspath) {
        DEBUG "Switchpoint $path has already been removed.\n" if $self->debug;
	return;
    }
    my $url = $self->file_url(filename=>$path);
    my $voidurl = $self->void_url(url => $url);
    my $ign = ($self->svn_version >= 1.7) ? "--ignore-ancestry" : "";
    my $cmd = qq{$self->{svn_binary} switch --quiet $ign $voidurl $path};
    $self->run($cmd);
    # Is it totally empty?
    my $status_items = 0;
    DEBUG "s4: Checking if $path is completely empty\n" if $self->debug;
    my $stat = $self->client->status
	($abspath,			# canonical path
	 "WORKING",			# revision
	 sub { $status_items++; DEBUG Dumper(@_) if $self->debug; }, 	# status func
	 1,				# recursive
	 1,				# get_all
	 0,				# update
	 1,				# no_ignore
     );
     DEBUG "status returned $status_items item(s)\n" if $self->debug;
     # For a totally empty directory, status returns just one thing: the
     # directory itself.
     if ($status_items==1) {
	 DEBUG "s4: Removing $path from working area\n" if $self->debug;
	 # Do it gently to reduce chance of wiping out. Only use the big hammer on
	 # the .svn directory itself.  This may "fail" because of leftover .nfs crap;
	 # then what's the right answer?
         $self->run ("/bin/rm -rf $path/.svn");
         $self->run ("/bin/rmdir $path");
	 DEBUG "s4: running $self->{svn_binary} update -r $self->{revision} on $abspath\n" if $self->debug;
	 my $fmt = $self->_wc_format($params{basepath});
	 if ($fmt == 4 || ($fmt >= 8 && $fmt <= 10)) {
	     $self->run ("$self->{svn_binary} up -N --revision $self->{revision} $path");
	 } elsif ($fmt == 12) {
	     $self->_wc_db_del($params{basepath}, $params{dir});
	 } else {
	     die "s4: %Error: remove_switchpoint: s4 does not know how to remove switchpoints in working copy format " . (0+$fmt);
	 }
     } else {
         print "s4: Ignoring obsolete switchpoint $path because there are still files under it.\n";
         print "s4: If you remove those files, you can remove the switchpoint manually, by deleting\n";
         print "s4: the directory and updating again.\n";
     }
}

sub _create_switchpoint_hierarchical {
    my $self = shift;
    my ($basedir,$reldir) = @_;
    my $path = "";
    my @dirparts = split ('/', $reldir);
    for (my $i=0; $i <= $#dirparts; $i++) {
	my $dirpart = $dirparts[$i];
	my $last_time_through = ($i == $#dirparts);
	DEBUG "s4: does '$dirpart' exist in $basedir? if not, make it\n" if $self->debug;
	if (! -e "$basedir/$dirpart") {
	    $self->_create_switchpoint ($basedir,$dirpart);
	    if (1) {  # Was $last_time_through, but fails for one level deep views
		# Q: Why is voidurl in a loop?  It takes 1-2 seconds!?
		# A: I don't want to compute void_url unless it is
		# really needed.  And the value gets cached, so the
		# 2nd, 3rd, etc. call takes no time.
		my $voidurl = $self->void_url(url => $self->file_url(filename=>$basedir));
		my $ign = ($self->svn_version >= 1.7) ? "--ignore-ancestry" : "";
		$self->run ("$self->{svn_binary} switch $ign --quiet $voidurl $basedir/$dirpart");
		$self->wait_for_existence (path=>"$basedir/$dirpart");
		push @{$self->{viewspec_managed_switches}},
		    $self->clean_filename("$basedir/$dirpart");
	    }
	}
	$basedir .= "/" . $dirpart;
    }
}

sub _create_switchpoint {
    my $self = shift;
    my ($basedir,$targetdir) = @_;
    DEBUG "s4: create_switchpoint $targetdir from basedir $basedir\n" if $self->debug;
    # Ok, we're going to do something really bizarre to work around a
    # svn limitation.  We want to create an svn switched directory, even if
    # there is no such directory in our working area.  Normally SVN does not
    # allow this unless you svn mkdir a directory and check it in.  But if
    # you artifically add a directory in .svn/entries, then you can switch
    # it to anything you want.  Strange but useful.
    # This hack is specific to the working copy format, so check that the working
    # copy format is one that I recognize.
    die "s4: %Error: can't make a switchpoint with a quote in it!" if $targetdir =~ /\"/;
    my $fmt = $self->_wc_format($basedir);
    if ($fmt == 4 || ($fmt >= 8 && $fmt <= 10)) {
	my $entries_file = "$basedir/.svn/entries";
	my $newfile = "$basedir/.svn/s4_tmp_$$";
	unlink(glob("$basedir/.svn/s4_tmp_*"));
	open (IN, $entries_file) or die "s4: %Error: $! opening $entries_file";
	my @out;
	if ($fmt == 4) {
	    while (<IN>) {
		if (/name="$targetdir"/) {
		    die "s4: %Error: create_switchpoint: an entry called '$targetdir' already exists in .svn/entries";
		}
		if (/<\/wc-entries>/) {
		    # Fmt=4: Just before the </wc-entries> line, add this entry
		    push @out, qq{<entry name="$targetdir" kind="dir"/> \n};
		}
		push @out, $_;
	    }
	}
	elsif ($fmt >= 8) {
	    # See subversion sources: subversion/libsvn_wc/entries.c
	    # Entries terminated by \f at next entry, then
	    #   kind, revision, url path, repo_root, schedule, timestamp, checksum,
	    #   cmt_date, cmt_rev, cmt_author, has_props, has_props_mod,
	    #   cachable_done, present_props,
	    #   prejfile, conflict_old, conflict_new, conflict_wrk,
	    #   copied, copyfrom_url, copyfrom_rev, deleted, absent, incomplete
	    #   uuid, lock_token, lock_owner, lock_comment, lock_creation_date,
	    #   changelist, keep_local, size, depth, tree_conflict_data,
	    #   external information
	    while (<IN>) {
		if (/^$targetdir/) {
		    die "s4: %Error: create_switchpoint: an entry called '$targetdir' already exists in .svn/entries";
		}
		push @out, $_;
	    }
	    # Right at the end, add new entry.
	    push @out, "$targetdir\ndir\n" . chr(12) . "\n";
	}
	open (OUT, ">$newfile") or die "s4: %Error: $! opening $newfile";
	print OUT join('',@out);
	close OUT;
	rename($newfile, $entries_file) or die "s4: Internal-%Error: $! on 'mv $newfile $entries_file',";
    }
    elsif ($fmt == 12) {
	$self->_wc_db_add($basedir, $targetdir);
    }
    else {
	die "s4: %Error: create_switchpoint: s4 does not know how to create switchpoints in working copy format " . (0+$fmt);
    }
}

sub viewspec_urls {
    my $self = shift;
    # Return all URLs mentioned in this action set, for info-switches
    my %urls;
    foreach my $action (@{$self->{vs_actions}}) {
	next if !$action->{url};
	$urls{$action->{url}} = 1;
    }
    return sort keys %urls;
}

sub _wc_format {
    my $self = shift;
    my ($basedir) = @_;
    my $format_file = "$basedir/.svn/format";
    my $entries_file = "$basedir/.svn/entries";
    my $fp = (IO::File->new("<$format_file")
	      || IO::File->new("<$entries_file"));
    $fp or die "s4: %Error: $! opening $format_file or $entries_file";
    my $fmt = $fp->getline;
    chomp $fmt;
    return $fmt;
}

sub _wc_db_connect {
    my $self = shift;
    my $basedir = shift;
    my $dbfile = "$basedir/.svn/wc.db";
    my $dbh = DBI->connect('dbi:SQLite:dbname='.$dbfile,'','',{AutoCommit=>1,RaiseError=>1,PrintError=>1});
    $dbh or die "s4: %Error: $! opening SQLite $dbfile";
    # sqlite3 .svn/wc.db
    # .dump
    return $dbh;
}

sub _wc_db_add {
    my $self = shift;
    my $basedir = shift;
    my $targetdir = shift;
    # Internal, edit .wc.db file to add specified target directory
    my $dbh = $self->_wc_db_connect($basedir);
    {
	my $sql = "SELECT local_relpath FROM nodes WHERE local_relpath = ?";
	my $sth = $dbh->prepare($sql);
	my $e = $sth->execute($targetdir);
	my $fa = $sth->fetchall_arrayref;
	(!$fa->[0]) or die "s4: %Error: create_switchpoint: an entry called '$targetdir' already exists in $basedir,";
    }
    my $max_rev;
    {
	my $sql = "SELECT MAX(revision) FROM nodes";
	my $sth = $dbh->prepare($sql);
	my $e = $sth->execute();
	my $fa = $sth->fetchall_arrayref;
	$max_rev = $fa->[0][0] or die "s4: %Error: create_switchpoint: no maximum revision found in $basedir,";
    }
    my $updir = "";
    $updir = $1 if $targetdir =~ m!^(.*)/([^/]+)$!;
    {
	DEBUG "s4: sql: insert node '$targetdir' under '$updir' rev '$max_rev'\n" if $self->debug;
	my $sql = "INSERT INTO nodes VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
	my $sth = $dbh->prepare($sql);
	my $e = $sth->execute(
	    1,			# wc_id  INTEGER NOT NULL REFERENCES WCROOT (id),
	    $targetdir,		# local_relpath  TEXT NOT NULL,
	    0,			# op_depth INTEGER NOT NULL,
	    $updir,		# parent_relpath  TEXT,
	    1,			# repos_id  INTEGER REFERENCES REPOSITORY (id),
	    'void',		# repos_path  TEXT,
	    $max_rev,		# revision  INTEGER,
	    'normal',		# presence  TEXT NOT NULL,
	    undef,		# moved_here  INTEGER,
	    undef,		# moved_to  TEXT,
	    'dir',		# kind  TEXT NOT NULL,
	    '()',		# properties  BLOB,
	    'infinity',		# depth  TEXT,
	    undef,		# checksum  TEXT REFERENCES PRISTINE (checksum),
	    undef,		# symlink_target  TEXT,
	    1,			# changed_revision  INTEGER,
	    time(),		# changed_date      INTEGER,
	    'author',		# changed_author    TEXT,
	    undef,		# translated_size  INTEGER,
	    undef,		# last_mod_time  INTEGER,
	    undef,		# dav_cache  BLOB,
	    undef,		# file_external  INTEGER,
	    undef);		# inherited_props  BLOB
    }
}

sub _wc_db_del {
    my $self = shift;
    my $basedir = shift;
    my $targetdir = shift;
    # Internal, edit .wc.db file to add specified target directory
    my $dbh = $self->_wc_db_connect($basedir);
    {
	my $sql = "DELETE FROM nodes WHERE local_relpath = ?";
	my $sth = $dbh->prepare($sql);
	my $e = $sth->execute($targetdir);
    }
}

######################################################################
### Package return
package SVN::S4::ViewSpec;
1;
__END__

=pod

=head1 NAME

SVN::S4::ViewSpec - behaviors related to viewspecs

=head1 SYNOPSIS

Scripts:
  use SVN::S4::ViewSpec;
  $svns4_object->parse_viewspec(filename=>I<filename>, revision=>I<revision>);
  $svns4_object->apply_viewspec(filename=>I<filename>);

=head1 DESCRIPTION

SVN::S4::ViewSpec implements parsing viewspec files and performing the
svn updates and svn switches required to make your working copy match the
viewspec file.

For viewspec documentation, see L<s4>.

=head1 METHODS

=over 4

=item $s4->parse_viewspec(parse_viewspec(filename=>I<filename>, revision=>I<revision>);

Parse_viewspec reads the file specified by FILENAME, and builds up
a list of svn actions that are required to build the working area.

The revision parameter is used as the default revision number for
all svn operations, unless the viewspec file has a "rev NUM" clause
that overrides the default.

=item $s4->apply_viewspec

For each of the svn actions, perform the actions.  An example of an action
is to run svn switch on the Foo directory the the URL Bar at revision 50.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2005-2013 by Bryce Denney.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Bryce Denney <bryce.denney@sicortex.com>

=head1 SEE ALSO

L<SVN::S4>, L<s4>

=cut
