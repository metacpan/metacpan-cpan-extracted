# See copyright, etc in below POD section.
######################################################################
#
# Goal: Completely clean a svn source tree.
# Usage:
#   s4 scrub [--revision REV] [--url URL]
#            [--verbose] [--debug] PATH
#
# Ideas:
# - option to leave svn switches alone, e.g. impl
# - any time I'm going to erase a directory, prompt the user first.
#   Then add a flag that suppresses the prompt, so that people who
#   think they know what they are doing can use the force switch.
# - fall back to "rm -rf and svn checkout" method if wierd things happen.
# - what is this error: No authentication provider available: No provider
#   registered for 'svn.username' credentials at ./scrub line 368
#   I get it whenever I run scrub on a checkout of
#   file:///home/denney/stress_svn_repo/svn-stress/sandbox
# - performance: untar from trusted place, update -r is faster than checkout


package SVN::S4::Scrub;
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

sub scrub {
    my $self = shift;
    $self->_scrub_main (@_);
}

######################################################################
### Package return
#package SVN::S4::Scrub;

our @Scrub_status_data;
our $externals_found_during_stat = 0;
our $Scrub_Statfunc_Debug;


sub _scrub_main {
    my $self = shift;
    my %params = (#path=>,
                  #revision=>,
                  #url=>,
		  #verbose=>1,
                  @_);
    $Scrub_Statfunc_Debug = $self->debug || 0;
    $params{revision} = "HEAD" if !defined $params{revision};
    # If there's not already a svn tree there, just erase it and check out a new
    # one.
    my $existing_tree_url = $self->file_url (filename=>$params{path}, assert_exists=>0);
    if (!defined $existing_tree_url) {
	if (!defined $params{url}) {
	    die "s4: %Error: You must specify --url since there isn't an existing source tree at $params{path}\n";
	}
	if (-d $params{path}) {
	    print "Existing directory not usable.  Removing it and starting over.\n" if !$self->quiet;
	}
	print "Checking out revision $params{revision} of $params{url}: " if !$self->quiet;
	flush STDOUT;
	$self->client->notify(\&_scrub_update_callback);
	$self->_wipe_tree_and_checkout($params{path}, $params{url}, $params{revision});
	$self->client->notify(undef);
	print "\n" if !$self->quiet;
	exit 0;
    }
    $params{url} = $existing_tree_url if !defined $params{url};

    my $canonical_path = $self->abs_filename ($params{path});
    #print "Reverting tree at $params{path}\n";
    #print "Revision: $params{revision}\n";
    #print "URL: $params{url}\n";

    # The basic algorithm is:
    #   cleanup, update, cleanup (if needed)
    # The cleanup stage does an svn stat, then a remove and/or revert on anything
    # that is not clean.  The update is a normal svn update.
    #

    # Why cleanup before update?
    # If you don't clean up unversioned files (? on svn stat output), update can
    # get stuck in some cases, for example if the update tries to add a new FILE1,
    # but you have created it already
    #   cd hw/chip/dma/beh; svn up -r21432; touch DmaUeRtl.sp; svn up -r21433
    #   svn: Failed to add file 'DmaUeRtl.sp': object of the same name already exists
    # If all ? files are removed before the update, the update has a better chance
    # of success.
    DEBUG "  + first cleanup stage\n" if $self->debug;
    $self->_cleanup_stage(\%params, $canonical_path);

    # Update the tree.  Hopefully this goes to completion.
    # If the update fails, we're going
    DEBUG "  + updating to revision $params{revision}:\n" if $self->debug;
    #flush STDOUT;
    $self->client->notify(\&_scrub_update_callback);
    $self->_scrub_update_tree ($canonical_path, $params{url}, $params{revision});
    $self->client->notify(undef);
    #print "\n";

    # FIXME: There are times that the update fails anyway, e.g. when an external
    # turns into a checked-in directory in a later rev.  When we find an example of
    # that, add the ability to detect that this has happened and deal with it.
    # One workaround is to erase the external in the error message and update
    # again, but you may have to do this N times.  Another workaround is to erase
    # every external and update again TWICE (the first will fail).
    #
    # Removing the tree and doing a brand new checkout is always a fallback option.
    # It would be nice to do this in case of ANY failure during cleaning and
    # updating, even ones that we have not ever seen before.
    #
    # Example: If an external points to an invalid URL, almost every command will fail
    # until you manually edit the svn:externals property.
    #

    if ($externals_found_during_stat) {
	# When an external disappears, its directory stays around in the working copy.
	# So, if we saw any externals during our "svn status" earlier, do another clean up
	# just in case.
	# NOTE: One could make this more efficient by only considering cleanup
	# where the externals were.  That would run faster than a complete "svn status".
	DEBUG "  + second cleanup stage\n" if $self->debug;
	$self->_cleanup_stage(\%params, $canonical_path);
    }
    # wipe out any s4 state files
    DEBUG "  + cleanup s4 state\n" if $self->debug;
    $self->clear_viewspec_state (path=>$canonical_path);
    DEBUG "  + scrub done\n" if $self->debug;
}

sub _cleanup_stage {
    my ($self, $params, $path) = @_;
    print "Cleaning... " if !$self->quiet;
    flush STDOUT;
    my @unclean = $self->_find_unclean_stuff ($path);
    print "\n" if !$self->quiet;
    flush STDOUT;
    if ($#unclean >= 0) {
	$self->_cleanup ($params, $path, @unclean);
    }
}

sub _Scrub_statfunc {
    my ($path, $status) = @_;
    my $stat = $status->text_status;
    my $text_status_name = $SVN::S4::WCSTAT_STRINGS{$stat};
    die "s4: %Error: text_status code $stat not recognized" if !defined $text_status_name;
    $stat = $status->prop_status;
    my $prop_status_name = $SVN::S4::WCSTAT_STRINGS{$stat};
    die "s4: %Error: prop_status code $stat not recognized" if !defined $prop_status_name;
    if ($Scrub_Statfunc_Debug) {
	print "================================\n";
	print "path=$path\n";
	print "text_status = $text_status_name\n";
	print "prop_status = $prop_status_name\n";
	if ($status->entry) {
	    my $name = $status->entry->name;
	    print "name = $name\n";
	    my $rev = $status->entry->revision;
	    print "rev = $rev\n";
	}
	my $entry = $status->entry;
	if ($entry) {
	    print "entry = $entry\n";
	    my $kind = $entry->kind;
	    my $kindname = $SVN::S4::WCKIND_STRINGS{$kind};
	    print "kind = $kindname (value=$kind)\n";
	    print "url = ", $entry->url, "\n";
	}
    }
    my $obj;
    $obj->{path} = $path;
    $obj->{text_status} = $text_status_name;
    $obj->{prop_status} = $prop_status_name;
    my $entry = $status->entry;
    if ($entry) {
	my $kind = $entry->kind;
	my $kindname = $SVN::S4::WCKIND_STRINGS{$kind};
	$obj->{kind} = $kindname;
    } else {
	$obj->{kind} = "?";  # easier to read if it's never undef
    }
    push @Scrub_status_data, $obj;
    return 0;
}

sub _find_unclean_stuff {
    my ($self, $path) = @_;
    # do svn status and record anything that looks strange.
    undef @Scrub_status_data;
    my $stat = $self->client->status (
	    $path,		# canonical path
	    "WORKING",		# revision
	    \&_Scrub_statfunc,	# status func
	    1,			# recursive
	    0,			# get_all
	    0,			# update
	    1,			# no_ignore
	    );
    return @Scrub_status_data;
}

sub _cleanup {
    my $self = shift;
    my $params = shift;
    my ($path, @list) = @_;
    my @rmlist;
    my @revlist;
    my @svnrmlist;
    foreach my $obj (@list) {
	#DEBUG "status of $obj->{path} is ", Dumper($obj->{text_status}), "\n";
	#DEBUG "$obj->{text_status} $obj->{kind} $obj->{path}\n" if $self->debug;
	my $stat = $obj->{text_status};
	$externals_found_during_stat++ if $stat eq 'external';
	my $propstat = $obj->{prop_status};
	#die "s4: Internal-%Error: if text_status is normal and prop_status is normal, why was this marked unclean? $obj->{path}" if ($stat eq 'normal' && $propstat eq 'normal');
	if ($stat eq 'external') {
	    # leave these alone
	    next;
	} elsif ($stat eq 'missing'
		|| $stat eq 'deleted'
		|| $stat eq 'replaced'
	        || $stat eq 'modified'
		|| $stat eq 'merged'
		|| $stat eq 'conflicted'
		|| $stat eq 'incomplete'
		|| ($stat eq 'normal' && $propstat ne 'none')
		) {
	    # need to revert
	    # Why revert a "normal"?  If it was totally clean, it would not
	    # have shown up here at all, right?  This happens when a property
	    # changes but the file stays the same.  So revert it.
	    DEBUG "$obj->{path} is $stat. must revert it\n" if $self->debug;
	    push @revlist, $obj->{path};
	} elsif ($stat eq 'normal') {
	    # if text status is normal, then why did it show up?
	    # Maybe a property change. Revert those.
	    # Maybe a svn switch.
	    # In any case, just add it to the revert list.
	    if ($propstat ne 'none') {
		DEBUG "$obj->{path} has a property change. revert it\n" if $self->debug;
		push @revlist, $obj->{path};
	    } else {
	        # why else? maybe it's a svn switch. If I can detect svn switches
		# In any case, do a revert on it.
		DEBUG "$obj->{path} showed up on svn status, but it isn't a text or property change. revert it, to be safe.\n" if $self->debug;
		push @revlist, $obj->{path};
	    }
	} elsif ($stat eq 'unversioned'
	         || $stat eq 'ignored') {
	    # just delete it
	    DEBUG "$obj->{path} is $stat. must remove it\n" if $self->debug;
	    push @rmlist, $obj->{path};
	} elsif ($stat eq 'added') {
	    # svn rm --force it
	    DEBUG "$obj->{path} is $stat. must svn rm --force it\n" if $self->debug;
	    push @svnrmlist, $obj->{path};
	} elsif ($stat eq 'obstructed') {
	    # remove it and then revert
	    DEBUG "$obj->{path} is $stat. remove it and then revert it\n" if $self->debug;
	    push @rmlist, $obj->{path};
	    push @revlist, $obj->{path};
	} else {
	    die "s4: Internal-%Error: status code unknown '$stat'";
	}
    }
    my $changes = 0;
    # remove everything on remove list
    if (@rmlist) {
	#print "  Deleting ", ($#rmlist+1), " files/directories\n" if $params->{verbose};
	open (RM, "| xargs --null /bin/rm -rf") or die "s4: %Error: open pipe to xargs rm";
	foreach my $name (@rmlist) {
	    next if $name eq $path || $name eq '.' || $name eq '..';
	    DEBUG "  + rm -rf '$name'\n" if $self->debug;
	    print "D    $name\n" if $params->{verbose};
	    print RM "$name\0";
	    $changes++;
	}
	close RM;
    }
    # revert everything on revert list
    if (@revlist) {
	#print "  Svn reverting ", ($#revlist+1), " files/directories\n" if $params->{verbose};
	open (REV, "| xargs --null $self->{svn_binary} revert -q")
	    or die "s4: %Error: open pipe to xargs revert";
	foreach my $name (@revlist) {
	    DEBUG "  + $self->{svn_binary} revert $name\n" if $self->debug;
	    print "U    $name\n" if $params->{verbose};
	    print REV "$name\0";
	    $changes++;
	}
	close REV;
    }
    # "svn rm --force" everything on svnrmlist
    if (@svnrmlist) {
	#print "  Svn removing ", ($#svnrmlist+1), " files/directories\n" if $params->{verbose};
	open (REV, "| xargs --null $self->{svn_binary} rm -q --force")
	    or die "s4: %Error: open pipe to xargs svn rm";
	# Reverse sort list by length, so that any subdirectories will be removed
	# before the parent directory. Otherwise you run into "bla is not a working copy"
	# problems and some of the removes are not done.
	foreach my $name (sort {length $b cmp length $a} @svnrmlist) {
	    DEBUG "  + $self->{svn_binary} rm --force $name\n" if $self->debug;
	    print "D    $name\n" if $params->{verbose};
	    print REV "$name\0";
	    $changes++;
	}
	close REV;
    }
    return $changes;
}

sub wcstat_to_string {
    my ($stat) = @_;
    my $string = $SVN::S4::WCSTAT_STRINGS{$stat};
    #DEBUG "SVN::S4::WCSTAT_STRINGS keys are: ", join (" ",sort keys %SVN::S4::WCSTAT_STRINGS), "\n" if $self->debug;
    return "(unknown status code $stat)" if !defined $string;
    return $string;
}

sub _scrub_update_tree {
    my ($self, $path, $url, $revision) = @_;
    DEBUG "\n" if $self->debug;
    DEBUG "about to do svn update. path=$path, url=$url, rev=$revision\n" if $self->debug;
    $self->update (revision=>$revision, paths=>[$path]);
#    my $actual_url = $self->file_url (filename=>$path);
#    if ($url eq $actual_url) {
#        my @paths = ($path);
#	$self->update (paths => \@paths, revision => $revision);
#    } else {
#	# FIXME: if s4 switch is implemented, use that.
#	#$self->client->switch ($path, $url, $revision, 1);
#	$self->run_s4 ('switch', '--revision', $revision, $url, $path);
#    }
    DEBUG "\n" if $self->debug;
    DEBUG "finished svn update\n" if $self->debug;
    #die "s4: %Error: Update returned revision $revout, should be $revision" if $revout != $revision;
}

sub _scrub_update_callback {
    my ($path,$action,$kind,$mimetype,$state,$rev) = @_;
    if ($Scrub_Statfunc_Debug) {
	print "\n  $path";
    } else {
	print ".";
    }
    flush STDOUT;
}

# last resort method. slowest but surest.
sub _wipe_tree_and_checkout {
    my ($self, $path, $url, $rev) = @_;
    my $pwd = `/bin/pwd`;
    chomp $pwd;
    if ($path ne '.' && $path ne '..' && $path ne $pwd) {
	$self->run("/bin/rm -rf '$path'");
    } else {
        DEBUG "(For safety reasons, I will not remove $path.)\n" if $self->debug;
	$self->run("/bin/rm -rf '$path'/* '$path'/.??*");
    }
    $self->run("mkdirhier $path");
    # now we know it exists. get canonical form
    $path = `cd $path && pwd`;
    chomp $path;
    # svn checkout -q -r $rev $url $path
    return $self->checkout(url=>$url, path=>$path, revision=>$rev);
}


1;
__END__

=pod

=head1 NAME

SVN::S4::Scrub - make working copy completely clean again

=head1 SYNOPSIS

Scripts:
  use SVN::S4::Scrub;
  $svns4_object->scrub (path=>I<path>);

=head1 DESCRIPTION

SVN::S4::Scrub

=head1 METHODS

=over 4

=item $s4->scrub(path=>I<path>);

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
