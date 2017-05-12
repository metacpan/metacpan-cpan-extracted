# PurpleWiki::Database.pm
# vi:sw=4:ts=4:ai:sm:et:tw=0
#
# $Id: Database.pm 448 2004-08-06 11:25:09Z eekim $
#
# Copyright (c) Blue Oxen Associates 2002-2003.  All rights reserved.
#
# This file is part of PurpleWiki.  PurpleWiki is derived from:
#
#   UseModWiki v0.92          (c) Clifford A. Adams 2000-2001
#   AtisWiki v0.3             (c) Markus Denker 1998
#   CVWiki CVS-patches        (c) Peter Merel 1997
#   The Original WikiWikiWeb  (c) Ward Cunningham
#
# PurpleWiki is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA

package PurpleWiki::Database;

# PurpleWiki Page Data Access

# $Id: Database.pm 448 2004-08-06 11:25:09Z eekim $

use strict;
use PurpleWiki::Config;

our $VERSION;
$VERSION = sprintf("%d", q$Id: Database.pm 448 2004-08-06 11:25:09Z eekim $ =~ /\s(\d+)\s/);

# Reads a string from a given filename and returns the data.
# If it cannot open the file, it dies with an error.
# Public
sub ReadFileOrDie {
  my $fileName = shift;
  my ($status, $data);

  ($status, $data) = ReadFile($fileName);
  if (!$status) {
    die("Can not open $fileName: $!");
  }
  return $data;
}

# Reads a string from a given filename and returns a
# status value and the string. 1 for success, 0 for 
# failure.
# Public
sub ReadFile {
  my $fileName = shift;
  my ($data);
  local $/ = undef;   # Read complete files

  if (open(IN, "<$fileName")) {
    $data=<IN>;
    close IN;
    return (1, $data);
  }
  return (0, "");
}

# Creates a directory if it doesn't already exist.
# FIXME: there should be some error checking here.
# Public
sub CreateDir {
    my $newdir = shift;

    mkdir($newdir, 0775)  if (!(-d $newdir));
}

# Creates a diff using Text::Diff
# We require it in here rather than at the top in
# case we never need it in the current running
# process.
# Private
sub _GetDiff {
    require Text::Diff;
    my ($old, $new, $lock) = @_;

    my $diff_out = Text::Diff::diff(\$old, \$new, {STYLE => "OldStyle"});
    return $diff_out;
}

# Creates a directory that acts as a general locking
# mechanism for the system.
# FIXME: ForceReleaseLock (below) is not immediately accessible
# to mortals.
# Private.
sub _RequestLockDir {
    my ($name, $tries, $wait, $errorDie) = @_;
    my ($lockName, $n);
    my $config = PurpleWiki::Config->instance();

    CreateDir($config->TempDir);
    $lockName = $config->LockDir . $name;
    $n = 0;
    while (mkdir($lockName, 0555) == 0) {
        if ($! != 17) {
            die("can not make $lockName: $!\n")  if $errorDie;
            return 0;
        }
        return 0  if ($n++ >= $tries);
        sleep($wait);
    }
    return 1;
}

# Removes the locking directory, destroying the lock
# Private
sub _ReleaseLockDir {
    my ($name) = @_;
    my $config = PurpleWiki::Config->instance();
    rmdir($config->LockDir . $name);
}

# Requests a general editing lock for the system.
# Public
sub RequestLock {
    # 10 tries, 3 second wait, die on error
    return _RequestLockDir("main", 10, 3, 1);
}

# Releases the general editing lock
# Public
sub ReleaseLock {
    _ReleaseLockDir('main');
}

# Forces the lock to be released
# Public
sub ForceReleaseLock {
    my ($name) = @_;
    my $forced;

    # First try to obtain lock (in case of normal edit lock)
    # 5 tries, 3 second wait, do not die on error
    $forced = !_RequestLockDir($name, 5, 3, 0);
    _ReleaseLockDir($name);  # Release the lock, even if we didn't get it.
    return $forced;
}

# Writes the given string to the given file. Dies
# if it can't write.
# Public
sub WriteStringToFile {
    my $file = shift;
    my $string = shift;

    open (OUT, ">$file") or die("can't write $file: $!");
    print OUT  $string;
    close(OUT);
 }

# Not used?
sub AppendStringToFile {
    my ($file, $string) = @_;

    open (OUT, ">>$file") or die("can't write $file $!");
    print OUT  $string;
    close(OUT);
}

# Creates and returns an array containing a list of all the
# wiki pages in the database.
# Public
sub AllPagesList {
    my $config = PurpleWiki::Config->instance();
    my (@pages, @dirs, $id, $dir, @pageFiles, @subpageFiles, $subId);

    @pages = ();
    # The following was inspired by the FastGlob code by Marc W. Mengel.
    # Thanks to Bob Showalter for pointing out the improvement.
    opendir(PAGELIST, $config->PageDir);
    @dirs = readdir(PAGELIST);
    closedir(PAGELIST);
    @dirs = sort(@dirs);
    foreach $dir (@dirs) {
        next  if (($dir eq '.') || ($dir eq '..'));
        my $directory = $config->PageDir . "/$dir";
        opendir(PAGELIST, $directory);
        @pageFiles = readdir(PAGELIST);
        closedir(PAGELIST);
        foreach $id (@pageFiles) {
            next  if (($id eq '.') || ($id eq '..'));
            if (substr($id, -3) eq '.db') {
		my $pageName = substr($id, 0, -3);
		$pageName =~ s/_/ /g if ($config->FreeLinks);
                push(@pages, {
		    'id' => substr($id, 0, -3),
		    'pageName' => $pageName,
                });
            } elsif (substr($id, -4) ne '.lck') {
                opendir(PAGELIST, "$directory/$id");
                @subpageFiles = readdir(PAGELIST);
                closedir(PAGELIST);
                foreach $subId (@subpageFiles) {
                    if (substr($subId, -3) eq '.db') {
			my $pageName = "$id/" . substr($subId, 0, -3);
			$pageName =~ s/_/ /g if ($config->FreeLinks);
			push(@pages, {
			    'id' => "$id/" . substr($subId, 0, -3),
			    'pageName' => $pageName,
			});
                    }
                }
            }
        }
    }
    return sort { $a->{id} cmp $b->{id} } @pages;
}

# Updates the diffs keps for a page.
# Public
sub UpdateDiffs {
    my $page = shift;
    my $keptRevision = shift;
    my ($id, $editTime, $old, $new, $isEdit, $newAuthor) = @_;
    my ($editDiff, $oldMajor, $oldAuthor);
    my $config = PurpleWiki::Config->instance();

    $editDiff  = _GetDiff($old, $new, 0);     # 0 = already in lock
    $oldMajor  = $page->getPageCache('oldmajor');
    $oldAuthor = $page->getPageCache('oldauthor');
    if ($config->UseDiffLog) {
        _WriteDiff($id, $editTime, $editDiff);
    }
    $page->setPageCache('diff_default_minor', $editDiff);

    if (!$isEdit) {
        $page->setPageCache('diff_default_major', "1");
    } else {
        $page->setPageCache('diff_default_major',
            GetKeptDiff($keptRevision, $new, $oldMajor, 0));
    }

    if ($newAuthor) {
        $page->setPageCache('diff_default_author', "1");
    } elsif ($oldMajor == $oldAuthor) {
        $page->setPageCache('diff_default_author', "2");
    } elsif ($oldMajor == $oldAuthor) {
        $page->setPageCache('diff_default_author', "2");
    } else {
        $page->setPageCache('diff_default_author',
            GetKeptDiff($keptRevision, $new, $oldAuthor, 0));
    }
}

# Retrieves a cached diff for a page.
# Public
sub GetCacheDiff {
  my ($page, $type) = @_;
  my ($diffText);

  $diffText = $page->getPageCache("diff_default_$type");
  $diffText = GetCacheDiff($page, 'minor')  if ($diffText eq "1");
  $diffText = GetCacheDiff($page, 'major')  if ($diffText eq "2");
  return $diffText;
}

# Retrieves the diff of an old kept revision
# Public
sub GetKeptDiff {
    my $keptRevision = shift;
    my ($newText, $oldRevision, $lock) = @_;

    my $section = $keptRevision->getRevision($oldRevision);
    return "" if (!defined $section); # there is no old revision
    my $oldText = $section->getText()->getText();

    return ""  if ($oldText eq "");  # Old revision not found
    return _GetDiff($oldText, $newText, $lock);
}

# Writes out a diff to the diff log.
# Private
sub _WriteDiff {
    my ($id, $editTime, $diffString) = @_;
    my $config = PurpleWiki::Config->instance();

    my $directory = $config->DataDir;
    open (OUT, ">>$directory/diff_log") or die('can not write diff_log');
    print OUT  "------\n" . $id . "|" . $editTime . "\n";
    print OUT  $diffString;
    close(OUT);
}

# Populates a hash reference with recent changes.
# Data structure:
#   $recentChanges = [
#     { timeStamp => ,  # time stamp
#       name => ,       # page name
#       numChanges => , # number of times changed
#       summary => ,    # change summary
#       userName => ,   # username
#       userId => ,     # user ID
#       host => ,       # hostname
#     },
#     ...
#   ]
sub recentChanges {
    my ($config, $timeStamp) = @_;
    my @recentChanges;
    my %pages;

    # Default to showing all changes.
    $timeStamp = 0 if not defined $timeStamp;

    # Convert timeStamp to seconds since the epoch if it's not already in
    # that form.
    if (not $timeStamp =~ /^\d+$/) {
        use Date::Manip;
        $timeStamp = abs(UnixDate($timeStamp, "%o")) || 0;
    }

    ### FIXME: There's also an OldRcFile.  Should we read this also?
    ### What is it for, anyway?
    if (open(IN, $config->RcFile)) {
    # parse logfile into pages hash
        while (my $logEntry = <IN>) {
            chomp $logEntry;
            my $fsexp = $config->FS3;
            my @entries = split /$fsexp/, $logEntry;
            if (scalar @entries >= 6 && $entries[0] >= $timeStamp) {  # Check timestamp
                my $name = $entries[1];
                my $pageName = $name;

                if ($config->FreeLinks) {
                    $pageName =~ s/_/ /g;
                }
                if ( $pages{$name} &&
                    ($pages{$name}->{timeStamp} > $entries[0]) ) {
                    $pages{$name}->{numChanges}++;
                }
                else {
                    if ($pages{$name}) {
                        $pages{$name}->{numChanges}++;
                    }
                    else {
                        $pages{$name}->{numChanges} = 1;
                        $pages{$name}->{pageName} = $pageName;
                    }
                    $pages{$name}->{timeStamp} = $entries[0];
                    if ($entries[2] ne '' && $entries[2] ne '*') {
                        $pages{$name}->{summary} = $entries[2];
                    }
                    else {
                        $pages{$name}->{summary} = '';
                    }
                    $pages{$name}->{minorEdit} = $entries[3];
                    $pages{$name}->{host} = $entries[4];

                    # $entries[5] is garbage and so we ignore it...

                    # Get extra info
                    my $fsexp = $config->FS2;
                    my %userInfo = split /$fsexp/, $entries[6];
                    if ($userInfo{id}) {
                        $pages{$name}->{userId} = $userInfo{id};
                    }
                    else {
                        $pages{$name}->{userId} = '';
                    }
                    if ($userInfo{name}) {
                        $pages{$name}->{userName} = $userInfo{name};
                    }
                    else {
                        $pages{$name}->{userName} = '';
                    }
                }
            }
        }
        close(IN);

    }
    # now parse pages hash into final data structure and return
    foreach my $name (sort { $pages{$b}->{timeStamp} <=> $pages{$a}->{timeStamp} } keys %pages) {
        push @recentChanges, { timeStamp => $pages{$name}->{timeStamp},
                               id => $name,
                               pageName => $pages{$name}->{pageName},
                               numChanges => $pages{$name}->{numChanges},
                               summary => $pages{$name}->{summary},
                               userName => $pages{$name}->{userName},
                               userId => $pages{$name}->{userId},
                               host => $pages{$name}->{host} };
    }
    return \@recentChanges;
}

1;
