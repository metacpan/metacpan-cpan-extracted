# See copyright, etc in below POD section.
######################################################################
#
# Goal: Create a patch file that describes how to reproduce the svn
#       working copy exactly.  If anything prevents such a patch from
#       being created, die with an error.
#
# Usage:
#   s4 complete_patch [--debug] PATH
#
# Future improvement:
# - handle spaces in files or directory (yuck)
# - restore permissions correctly
# - use rsvn capabilities
# - move interesting bits into perl module
# - using random numbers makes patches different every time, so md5sum is useless.
#   If I can do the dividers safely, without randomness, it would be better.
#
# Already done:
# - (DONE) Include unversioned things in the diff?
# - (DONE) What about svn added and svn removed stuff?
# - (DONE) binary files
# - (DONE) property changes? svn diff prints these, but patch does not understand
#   them.  As long as properties are TEXT and don't have apostrophes, I'm okay.
# - (DONE) Externals?  Does that patch show how to get a repository that is pegged
#   to the current version of each external?  Does svn diff go into the
#   external?
#   - (DONE) If an svn:external was added, it should be done with a checkout.
# - (DONE) svn updates of individual files is really slow. Even if I list them together
#   like "svn up -r25269 DmaAluBeh.sp DmaCsrRtl.sp DmaRxpCmuxBeh.sp DmaUeInstDebug.sp".
#   More efficient to update the directory, then apply a patch for the files.
# - (DONE) If you do "svn up -r25269 beh/file1 beh/file2 beh/file3", it locks every directory
#   of the repository three times.  If you do "(cd beh;svn up -r25269 file{1,2,3})" it
#   only locks beh three times.  Do everything at depth=1, then depth=2, then depth=3,
#   etc.  In theory, everything at the same depth could be done in parallel!(?)
# - (DONE) squash everything into one file. binary sections will be uuencoded.
# - (DONE) command line switch to the patch script that controls whether it does reverts or not.
#

package SVN::S4::Snapshot;
require 5.006_001;

use strict;
use Carp;
use IO::Dir;
use IO::File;
use Cwd;
use Digest::MD5;
use MIME::Base64;
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

sub snapshot {
    my $self = shift;
    $self->_snapshot_main (@_);
}

######################################################################
### Package return
#package SVN::S4::Snapshot;

our $Snapshot_Errors = 0;

# 0 means SKIP the svn:ignore files, which is the subversion default.
# 1 means to include the svn:ignore files in the patch.
our $Opt_Disregard_Ignore_List = 0;

# here is a bash function that deletes all the properties on a file or dir
our $Propclear_bash_func = q{
# remove all svn properties from a file or dir
function propclear {
  for f in `svn proplist $1|tail -n +2`; do
    svn propdel $f $1;
  done
}


};


our @svn_status_data;
our $Snapshot_Statfunc_Debug;

# if directory foo is an external, $Externals{'foo'} will be set to 1.
our %Externals;

# These data structures are built up using the "svn status" information, then
# used to produce a set of svn update --revision commands that will restore the tree
# to the same revision numbers as the original.
#
#   Data structure for a directory
#     $dir = {depth=>D, dirpath=>P, rev=>R)
#     depth=1 for root, 2 for first level dirs, etc
#     fullpath is . for root, "hw" for depth=2, etc.
#     rev is revision of the directory
#   I need a @list of these $dir objects, and a hash of fullpath=>$dir mapping.
our @Dirs;            # list of $dir objects
our %Dir_by_dirpath;  # @dirs indexed by their dirpath, used to find parent dirs

#   Data structure for files
#     $file = {filename=>F, rev=>R}
#     hash indexed by dirpath points to a list of $file objects.
our %File_by_dirpath; # a hash of lists of $files.

## If there's not an svn tree there, blow up.


sub _snapshot_main {
    my $self = shift;
    my %params = (#path=>,
                  #disregard_ignore_list=>,
		  #scrub_cmd=>,
                  @_);
    die "s4: Internal-%Error: parameter disregard_ignore_list is undefined"
        if !defined $params{disregard_ignore_list};
    my $url = $self->file_url (filename=>$params{path});
    # find base revision
    # this is an "our" variable so that the status callback function can use it
    our $baseRev = $self->get_svn_rev ($params{path});
    die "s4: %Error: could not find revision number of tree at $params{path}" if !defined $baseRev;

    my $canonical_path = $self->abs_filename($params{path});
    chdir $canonical_path or die "s4: %Error: chdir $canonical_path";

    $self->_snapshot_get_info($canonical_path);

    $Snapshot_Statfunc_Debug = $self->debug || 0;
    $self->client->notify(\&_notify_callback);
    my @objects = do_svn_status ($self, $canonical_path, $params{disregard_ignore_list});
    $self->client->notify(undef);

    my $patch_path = "/tmp/complete_patch_$$";
    my $used_patch = 0;
    $self->run("/bin/rm -rf $patch_path");

    my $shellcmds = "";
    my $svn_adds = "";
    my @inlinebins;
    my $svn_prop_changes = "";
    foreach my $obj (@objects) {
	my $ts = $obj->{text_status};
	my $ps = $obj->{prop_status};
	my $kind = $obj->{kind};
	my $fullpath = $obj->{path};
	DEBUG "Deciding about '$fullpath' : text is $ts, prop is $ps\n" if $self->debug;
	my $relpath = $fullpath;
	$relpath =~ s/^$canonical_path\///;
	$relpath = '.' if $relpath eq $canonical_path;
	# script does a series of svn updates to get files to the proper revision
	my $rev = $obj->{revision};
	if (defined $rev) {
	    add_dir  ($relpath, $rev, $obj) if $kind eq 'dir';
	    add_file ($relpath, $rev, $obj) if $kind eq 'file';
	}
	# look for property differences
	if ($ps eq 'normal' || $ps eq 'none') {
	    # no diff needed
	} else {
	    DEBUG "Restore properties for $relpath\n" if $self->debug;
	    $svn_prop_changes .= _restore_proplist ($self,$relpath,$fullpath);
	}
	# look for text differences
	if ($ts eq 'normal') {
	    # no diff needed
	} elsif ($ts eq 'unversioned' || $ts eq 'ignored') {
	    if (-d $relpath) {
		$shellcmds .= "/bin/mkdir -p '$relpath'\n";  # to add a dir, you just mkdir it!
		# FIXME what about contents of directory?  If directory is
		# non-empty, die and force user to svn add it.  Or we could read
		# the dir and issue mkdirs and patches for all the contents.
		my $num_contents = `find '$relpath' -print|wc -l`;
		die "s4: %Error: find on directory $relpath failed to return number of items inside" if $num_contents < 1;
		if ($num_contents != 1) {
		    die "s4: %Error: the directory '$relpath' cannot be snapshotted. To fix this, svn add the directory and try again.";
		}
	    } elsif (-l $relpath) {
		# symbolic link
		my $readlink = readlink($relpath);
		$shellcmds .= "/bin/ln -s '$readlink' '$relpath'\n";
	    } elsif (-f $relpath && -z $relpath) {
		$shellcmds .= "/usr/bin/touch '$relpath'\n";
	    } else {
		# Make a diff that shows a file being created.  Try text diff first, and
		# if it fails, encode the whole file and put it inline.
		$self->run("echo >> '$patch_path'");
		my $code = $self->run_nocheck("diff -c /dev/null '$relpath' >> '$patch_path'");
		if ($code == 2) {  # diff returns this if the file is binary
		    push @inlinebins, $relpath;
		} else {
		    $used_patch++;  # diff produced a good text diff
		}
	    }
	} elsif ($ts eq 'added'
		 || $ts eq 'modified'
		 || $ts eq 'replaced'
		 ) {
	    if ($kind eq 'dir') {
		$shellcmds .= "/bin/mkdir -p '$relpath'\n";  # in case it didn't exist
	    } elsif (-l $relpath) {
		# symbolic link
		my $readlink = readlink($relpath);
		$shellcmds .= "/bin/ln -s '$readlink' '$relpath'\n";
	    } elsif (-f $relpath && -z $relpath) {
		# empty file
		$shellcmds .= "/usr/bin/touch '$relpath'\n";
	    } else {
		# is it text or binary?
		my $type = text_or_binary ($self, $fullpath);
		if ($type eq 'text') {
		    # use svn diff
		    $self->run("$self->{svn_binary} diff '$relpath' >> '$patch_path'");
		    $used_patch++;
		} else {
		    push @inlinebins, $relpath;
		}
	    }
	    my $quiet = $self->{quiet} ? "--quiet" : "";
	    $svn_adds .= "svn add --force $quiet '$relpath'\n" if $ts eq 'added';
	} elsif ($ts eq 'deleted') {
	    $shellcmds .= "svn rm '$relpath'\n" if $kind eq 'dir' || $kind eq 'file';
	} elsif ($ts eq 'missing') {
	    print STDERR "%Error: $relpath is missing (type=$kind) according to svn.  You can either svn rm it, or revert it to make your svn tree healthy again.\n";
	    $Snapshot_Errors++;
	    # these work, but it's probably not a good idea.
	    #$shellcmds .= "/bin/rm -f '$relpath'\n" if $kind eq 'file';
	    #$shellcmds .= "/bin/rm -rf '$relpath'\n" if $kind eq 'dir';
	} elsif ($ts eq 'external') {
	    # FIXME: should I do anything here?
	} else {
	    print STDERR "%Error: file has status '$ts' that cannot be diffed: $relpath\n";
	    $Snapshot_Errors++;
	}
    }

    if ($Snapshot_Errors) {
	die "s4: %Error: stopping due to above errors";
    }

    our %Dividers = (
	1 => _gen_section_divider(1),
	2 => _gen_section_divider(2),
	3 => _gen_section_divider(3)
    );

    print STDOUT qq{#!/bin/bash -x
# This file is a s4 snapshot file, created by SVN::S4::Snapshot.pm $VERSION,
# that describes how to recreate a subversion working area.  If you run this
# script in the directory FOO with the --revert option, it will change FOO into
# a working area that exactly matches the directory that was snapshotted.  Of
# course, that means your changes will disappear...so be careful!
#
# You can also apply this file as a patch, like
#    patch -p0 < THIS_FILE
# And patch will merge the changes in this file with your changes.

###########################################################
# Section 1 is a shell script that recreates the source tree
###########################################################

#S4=s4
S4=$self->{s4_binary}
if test "--revert" = "\$1"; then
    # Call $params{scrub_cmd} to get the source tree to a known state.
    $params{scrub_cmd} --url=$url --revision=$baseRev .
    if test \$? != 0; then
      echo $params{scrub_cmd} failed, so I will stop.
      exit 1
    fi
fi
};

    #
    # Do updates of dirs in increasing order of depth.
    my @sorted_dirs = sort {$a->{depth} cmp $b->{depth}
			    || $a->{dirpath} cmp $b->{dirpath}} @Dirs;
    foreach my $dir (@sorted_dirs) {
	my $dirpath = $dir->{dirpath};
	#print STDERR "# directory $dirpath\n";
	my $parent = parent_of_dir($dir);
	my $extern = $Externals{$dir->{obj}->{path}};  #ask externals hash if it is one
	my $this_url = $self->get_svn_url($dir->{obj}{path});
	my $quiet = $self->{quiet} ? "--quiet" : "";
	my $parent_url = $parent && $self->get_svn_url($parent->{obj}{path});
	if ($extern) {
	    print STDOUT "# directory '$dirpath' is an extern\n";
	    print STDOUT "svn checkout $quiet --revision $dir->{rev} '$this_url' '$dirpath'\n";
	} elsif ($parent) {
	    # if this dir has a different rev than its parent, or if its url
	    # is not what one would expect (svn switch), generate a command
	    # to recreate that in the new tree.
	    my $dirpath_last_elem = $dirpath;
	    $dirpath_last_elem =~ s/.*\///;
	    my $match_url = "$parent_url/$dirpath_last_elem";
	    # handle spaces. but some other characters will surely screw us up.
	    $match_url =~ s/ /%20/g;
	    my $switched = $this_url ne $match_url;
	    my $revchange = nonzero($parent->{rev})
		&& nonzero($dir->{rev})
		&& ($parent->{rev} != $dir->{rev});
	    if ($switched) {
		DEBUG "this_url=$this_url, expected $parent_url/$dirpath_last_elem\n" if $self->debug;
		print STDOUT "# directory '$dirpath' url differs from parent\n";
		print STDOUT "(cd '$dirpath' && \$S4 --orig switch $quiet --revision $dir->{rev} '$this_url')\n";
	    } elsif ($revchange) {
		DEBUG "urls match. thisrev=$dir->{rev}, parent rev=$parent->{rev}\n" if $self->debug;
		print STDOUT "# directory '$dirpath' revision differs from parent\n";
		print STDOUT "(cd '$dirpath' && \$S4 --orig up $quiet --revision $dir->{rev})\n";
	    }
	}
	# find files in this directory whose rev differs from the directory
	$parent_url = $this_url;  # Parent of file is the directory
	foreach my $file (@{$File_by_dirpath{$dirpath}}) {
	    #print STDOUT "# file '$file->{filename}' is rev $file->{rev}\n";
	    my $filepath = $dirpath."/".$file->{filename};
	    my $this_url;
	    $this_url = $self->get_svn_url($file->{obj}{path});
	    my $dirpath_last_elem = $file->{filename};
	    $dirpath_last_elem =~ s/.*\///;
	    my $match_url = "$parent_url/$dirpath_last_elem";
	    my $switched = $this_url ne $match_url;
	    if ($switched) {
		print STDOUT "(cd '$dirpath' && \$S4 --orig switch $quiet --revision $file->{rev} '$this_url' '$file->{filename}')\n";
	    } elsif ($file->{rev} != 0 && $dir->{rev} != 0
		     && ($file->{rev} != $dir->{rev})) {
		print STDOUT "(cd '$dirpath' && \$S4 --orig up $quiet --revision $file->{rev} '$file->{filename}')\n";
	    }
	}
    }

    print STDOUT "# Shell commands to update to the right version, recreate files and directories.\n";
    print STDOUT $shellcmds;
    print STDOUT "\n";

    if ($used_patch != 0) {
	print STDOUT q{
# Apply the patch at the bottom of this script
echo Applying patches
patch -N -t -p0 -s < $0
};
    } else {
	print STDOUT "# no patch needed\n\n";
    }

    if (@inlinebins) {
	print STDOUT "# Extract the binary files from section 3.\n";
	print STDOUT "# The binaries are tarred, gzipped, and base64 encoded.\n";
	print STDOUT "echo Extracting binaries:\n";

	# do this in stages to avoid horrid quoting problems
	my $extract_perlcode = q{print decode_base64($_) if $found; $found=1 if /^__DIV__$/};
	$extract_perlcode =~ s/__DIV__/$Dividers{3}/g;
	my $cmd = q{
    cat $0 | \
      perl -MMIME::Base64 -ne \
	'__PERLCODE__' | \
      gunzip -c | \
      tar xvf -
    };
	$cmd =~ s/__PERLCODE__/$extract_perlcode/;
	print STDOUT $cmd;
    }

    print STDOUT "# svn add commands go here, if needed\n";
    print STDOUT "echo Doing svn adds\n" unless length $svn_adds==0;
    print STDOUT $svn_adds;
    print STDOUT "\n";
    print STDOUT "# svn property changes go here, if needed\n";
    print STDOUT "echo Doing svn property changes\n" unless length $svn_adds==0;
    print STDOUT $svn_prop_changes;
    print STDOUT "\n";
    print STDOUT "exit 0   # end of executable section\n";
    print STDOUT "\n";

    if ($used_patch) {
	print STDOUT "###########################################################\n";
	print STDOUT "# Section 2 is a patch file containing text changes\n";
	print STDOUT "###########################################################\n";
	print STDOUT "\n";
	$self->run ("/bin/cat '$patch_path'");
    }
    $self->run("/bin/rm -rf '$patch_path'");

    if (@inlinebins) {
	print STDOUT "\n";
	print STDOUT "###########################################################\n";
	print STDOUT "# Section 3 contains binary files.\n";
	print STDOUT "# The format is a TAR which is gzipped and base64 encoded.\n";
	print STDOUT "# The files inside are: \n#   ";
	print join("\n#   ", @inlinebins);
	print STDOUT "\n###########################################################\n";
	print STDOUT $Dividers{3}, "\n";
	$self->_inline_binaries (@inlinebins);
    }
    print STDOUT "\n";
}

sub _snapshot_statfunc {
    my ($path, $status) = @_;
    if ($Snapshot_Statfunc_Debug) {
	print STDERR "================================\n";
	print STDERR "path=$path\n";
	#print STDERR "status=", Dumper($status);
	if ($status->entry) {
	    my $name = $status->entry->name;
	    print STDERR "name = $name\n";
	    my $rev = $status->entry->revision;
	    print STDERR "rev = $rev\n";
	}
	my $textstat = $status->text_status;
	my $textstatname = $SVN::S4::WCSTAT_STRINGS{$textstat};
	die "s4: %Error: text_status code $textstat not recognized" if !defined $textstatname;
	print STDERR "text_status = $textstatname (value=$textstat)\n";
	my $propstat = $status->prop_status;
	my $propstatname = $SVN::S4::WCSTAT_STRINGS{$propstat};
	die "s4: %Error: prop_status code $propstat not recognized" if !defined $propstatname;
	print STDERR "prop_status = $propstatname (value=$propstat)\n";
	my $entry = $status->entry;
	if ($entry) {
	    print STDERR "entry = $entry\n";
	    my $kind = $entry->kind;
	    my $kindname = $SVN::S4::WCKIND_STRINGS{$kind};
	    print STDERR "kind = $kindname (value=$kind)\n";
	}
    }
    my $obj;
    $obj->{path} = $path;
    my $textstat = $status->text_status;
    my $propstat = $status->prop_status;
    my $textstatname = $SVN::S4::WCSTAT_STRINGS{$textstat};
    my $propstatname = $SVN::S4::WCSTAT_STRINGS{$propstat};
    die "s4: %Error: text_status code $textstat not recognized" if !defined $textstatname;
    die "s4: %Error: prop_status code $propstat not recognized" if !defined $propstatname;
    $obj->{text_status} = $textstatname;
    $obj->{prop_status} = $propstatname;
    my $entry = $status->entry;
    if ($entry) {
	$obj->{revision} = $entry->revision;
	my $kind = $entry->kind;
	my $kindname = $SVN::S4::WCKIND_STRINGS{$kind};
	$obj->{kind} = $kindname;
    } else {
	$obj->{kind} = "?";  # easier to read if it's never undef
    }
    push @svn_status_data, $obj;
    return 0;
}

# from man SVN::Client:
#   The subroutine will receive 6 parameters.  The first parameter will be the path of the
#   changed file (absolute or relative to the cwd).  The second is an integer specifying the
#   type of action taken.  See SVN::Wc for a list of the possible actions values and what
#   they mean.  The 3rd is an integer specifying the kind of node the path is, which can be:
#   $SVN::Node::none, $SVN::Node::file, $SVN::Node::dir, $SVN::Node::unknown.  The fourth
#   parameter is the mime-type of the file or undef if the mime-type is unknown (it will
#   always be undef for directories).  The 5th parameter is the state of the file, again see
#   SVN::Wc for a list of the possible states.  The 6th and final parameter is the numeric
#   revision number of the changed file.  The revision number will be -1 except when the
#   action is $SVN::Wc::Notify::Action::update_completed.

sub _notify_callback {
    my ($path,$action,$kind,$mimetype,$state,$rev) = @_;
    my $msg="notify callback: path=$path";
    if ($action == $SVN::Wc::Notify::Action::status_external) {
        $msg .= " action=status_external";
	$Externals{$path} = 1;
    }
    if ($action == $SVN::Wc::Notify::Action::status_completed) {
        $msg .= " action=status_completed";
    }
    DEBUG "$msg\n" if $Snapshot_Statfunc_Debug > 0;
}


sub do_svn_status {
    my ($self, $path, $disregard_ignore_list) = @_;
    # do svn status and record anything that looks strange.
    # Have to use get_all=1 so that we notice clean files with a different rev number.
    undef @svn_status_data;
    my $stat = $self->client->status (
	    $path,		# canonical path
	    "WORKING",		# revision
	    \&_snapshot_statfunc,	# status func
	    1,			# recursive
	    1,			# get_all
	    0,			# update
	    $disregard_ignore_list,	# no_ignore
	    );
    return @svn_status_data;
}

sub run_nocheck {
    my ($self, $cmd) = @_;
    DEBUG "Exec: $cmd\n" if $self->debug;
    my $status = system($cmd)
	or die "s4: %Error: system $cmd failed: $?";
    return ($? >> 8);
}

sub get_svn_rev {
    # I don't know how to do this with SVN::Client.
    # So do it the old fashioned way.
    my ($self,$path) = @_;
    DEBUG "Exec: cd '$path' && $self->{svn_binary} info\n" if $self->debug;
    open (INFO, "cd '$path' && $self->{svn_binary} info |");
    my $rev;
    while (<INFO>) {
	if (/^Revision: (\d+)/) {
	    $rev = $1;
	    #last;  # Causes broken pipe
	}
    }
    close INFO;
    return $rev;
}

sub _snapshot_get_info {
    my ($self,$path) = @_;
    $self->{_snapshot_infos} = {};
    $path = SVN::S4::Path::fileNoLinks($path);
    my $pathre = quotemeta($path);
    $pathre = qr!$pathre!;
    my $stat = $self->client->info
	($path,			# canonical path
	 undef,			# peg_revision
	 undef,			# revision - NULL means don't contact server
	 sub {
	     my ($path, $info, $pool) = @_;
	     my $relpath = $path;
	     # Keeping the whole object around causes a core dump, so pick what we need
	     $self->{_snapshot_infos}{$relpath} = {
		 URL => $info->URL,
	     };
	     #DEBUG "get_info ADD $relpath\n"; # if $self->debug;
	 }, # status func
	 1,			# recursive
	 );
}

sub get_svn_url {
    my ($self,$path) = @_;
    my $rtn = $self->{_snapshot_infos}{$path};
    #DEBUG "get_svn_url $path  GG $rtn\n";  # if $self->debug;
    if ($rtn && $rtn->{URL}) {
	return $rtn->{URL};
    } else {
	return undef;
    }
}

sub add_dir {
    my ($path, $rev, $obj) = @_;
    $path =~ s/\/+$//;  # remove trailing slashes, if any
    my @dirparts = split('/', $path);
    my $depth = scalar @dirparts;
    $depth = 0 if $path eq '.';
    my $dir = {depth=>$depth, dirpath=>$path, rev=>$rev, obj=>$obj};
    push @Dirs, $dir;
    $Dir_by_dirpath{$path} = $dir;
}

sub add_file {
    my ($path, $rev, $obj) = @_;
    my $dirpath;
    my $filename;
    if ($path =~ /^(.*)\/([^\/]+)$/) {
        ($dirpath,$filename) = ($1,$2);
    } else {
        ($dirpath,$filename) = ('.', $path);
    }
    my $file = {filename=>$filename, rev=>$rev, obj=>$obj};
    push @{$File_by_dirpath{$dirpath}}, $file;
    #DEBUG "File_by_dirpath{$dirpath} = $filename\n";  # if $self->debug;
}

sub parent_of_dir {
    my ($dir) = @_;
    my $parent_path = $dir->{dirpath};
    return if $parent_path eq '.';
    if (! ($parent_path =~ s/\/[^\/]+$//)) {
        $parent_path = '.';
    }
    my $parent = $Dir_by_dirpath{$parent_path};
    #die "s4: %Error: could not find parent for directory $dir->{dirpath}" if !defined $parent;
    # Oops, actually this can happen on an external to dir1/dir2 where dir1 is
    # not a versioned directory.
    return $parent;
}

sub text_or_binary {
    my ($self, $path) = @_;
    my $hashref = $self->client->propget('svn:mime-type', $path, "WORKING", 0);
    DEBUG "propget returns ", Dumper($hashref), "\n" if $self->debug;
    my $type = $hashref->{$path};
    return 'binary' if (defined $type && $type eq 'application/octet-stream');
    return 'text';
}

sub _inline_binaries {
    my $self = shift;
    if (!defined $_[0]) { die "s4: Internal-%Error: inline_binaries called with empty list"; }
    my $tarcmd = "tar czf - " . join (' ', @_);
    DEBUG "Exec: $tarcmd |\n" if $self->debug;
    open (PIPE, "$tarcmd |") || die "s4: %Error: open pipe from tar";
    my $status;
    my $buf;
    while ($status = read(PIPE, $buf, 60*57)) {
	print MIME::Base64::encode_base64($buf);
    }
    close PIPE;
    if ($status!=0) {
        die "s4: %Error: while reading gzipped tar file: $!";
    }
}

sub _gen_section_divider {
    my ($section) = @_;
    my $rands = rand() . rand() . rand() . rand();
    return "# BEGIN SECTION $section # $rands";
}

sub _restore_proplist {
    my ($self, $relpath, $fullpath) = @_;
    my $proplist = $self->client->proplist($fullpath, "WORKING", 0);
    my $out = _emit_propclear ($relpath);  # emit code to clear properties
    return $out if !defined $proplist->[0];  # there are no properties. done!
    my $prophash = $proplist->[0]->prop_hash;
    if ($self->debug) {
	DEBUG "path=", $proplist->[0]->node_name, "\n";
	DEBUG Dumper($prophash) if $self->debug;
    }
    foreach my $name (keys %$prophash) {
        my $value = $prophash->{$name};
        DEBUG "name=$name, value=$value\n" if $self->debug;
	$out .= _emit_propset($relpath, $name, $value);
    }
    return $out;
}

sub _emit_propclear {
    my ($path) = @_;
    my $out = $Propclear_bash_func;
    $Propclear_bash_func = "";  # so that it's only printed once into the patch
    return $out . "propclear $path\n";
}

sub _emit_propset {
    my ($path, $name, $value) = @_;
    # name or esp. value could conceivably be things that are impossible to quote.
    if (single_quotable($name) && single_quotable($value)) {
	return "svn propset ".single_quote($name)." ".single_quote($value)." $path\n";
    } else {
        warn "%Error: property name($name) or value($value) has strange characters in $path\n";
    }
}

sub single_quotable {
    my ($v) = @_;
    return 0 if $v =~ /\'/;
    # all chars ascii 0x20 through 0x7e (space through tilde)
    return 1 if $v =~ /^[ -~\t\n\r]*$/;
    return 0;   # some wierd chars in there
}

sub single_quote {
    my ($v) = @_;
    return "'".$v."'";
}

sub nonzero {
    my ($num) = @_;
    return 0 if !defined $num;
    return 0 if $num==0;
    return 1;
}

1;
__END__

=pod

=head1 NAME

SVN::S4::Snapshot - create complete snapshot of working copy

=head1 SYNOPSIS

Scripts:
  use SVN::S4::Snapshot;
  $svns4_object->snapshot (path=>I<path>);

=head1 DESCRIPTION

SVN::S4::Snapshot

=head1 METHODS

=over 4

=item $s4->snapshot(path=>I<path>);

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2005-2013 by Bryce Denney.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Bryce Denney <bryce.denney@sicortex.com>

=head1 SEE ALSO

L<SVN::S4>

=cut
