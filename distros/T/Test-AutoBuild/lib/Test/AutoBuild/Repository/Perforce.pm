# -*- perl -*-
#
# Test::AutoBuild::Repository::Perforce by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>
#
# This program is free software; you can redistribute it and/or modify
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id$

=pod

=head1 NAME

Test::AutoBuild::Repository::Perforce - A repository for Perforce

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::Perforce


=head1 DESCRIPTION

This module provides access to source stored in a Perforce
repository.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::Perforce;

use base qw(Test::AutoBuild::Repository);
use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use POSIX qw(strftime);
use Date::Manip;
use Class::MethodMaker
    get_set => [qw( initialized client_name server_timezone )];
use Log::Log4perl;
use Test::AutoBuild::Change;

# Before we get started, a word about timezone handling...
#
# According to the perforce docs
#
#   "Date and time specifications are always interpreted
#    with respect to the local time zone of the Perforce
#    server. Note that because the server stores times
#    internally in terms of number of seconds since the
#    Epoch (00:00:00 GMT Jan. 1, 1970), if you move your
#    server across time zones, the times recorded on the
#    server will automatically be reported in the new
#    timezone."
#
# Sounds reasonable, right ?
#
# Yes, if that's what it actually did, life would be
# golden.
#
# But...its broken. It does indeed report times in the TZ
# that the server is currently using, however, it applies
# a DST offset based on the DST value at the time the
# changeset was committed! So, if you're server is say in
# Boston, mid-April - thus EDT - and you're quering a change
# that was made in Jan - when EST was in force, then rather
# than reporting the time in EDT, it adjusts for DST and
# reports it relative to EST.
#
# Things get even more fun, if your client is in another
# timezone, say you're in London. At the time London is on
# BST, your server is EDT - so simply have a delta of 5
# hours to worry about. Bzzzt. No, that change from mid
# Dec is still being reported in EST, 4 hours difference.
#
# While you can figure out what the server's current time
# zone is from 'p4 info', you cant reliably infer what the
# timezone was back in Dec from this info - so states may
# do the EST<->EDT switch, others may be on EST all year
# around. So, basically the date / time from 'p4 changes'
# or 'p4 describe' is useless in itself.
#
# Now fortuntely, p4 does actually store times internally
# as seconds since the epoch. So rather than passing a date
# to the p4 sync command, we run 'p4 -ztag changes' to find
# out the timestamp associated with each changelist. Then
# sort them & find out the most recent changelist, and then
# explicitly sync to that.

sub sync_view {
    my $self = shift;
    my $runtime = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    # Get the existing client
    my ($client, $errors) = $self->_run(['p4', 'client', '-o'], undef, $logfile);
    my $orig_client = $client;

    # Change the Root: section
    my $root = $runtime->source_root();
    $client =~ s/\n\s*Root:(.*)$/\nRoot: $root/m;

    die "cannot find client name" unless $client =~ /\n\s*Client:\s*(.*?)\s+/m;
    $self->client_name($1);
    $log->debug("Got client name '$1'");

    # Strip out the View: section
    $client =~ s/\n\s*View:(.*)$//s;

    my $view = "";
    my %views;
    my @views;
    # Compose the new View: section
    foreach my $name ($runtime->modules) {
	my $module = $runtime->module($name);

	my @paths = $module->paths($self);
	foreach my $path (@paths) {
	    my $src;
	    my $dst;
	    $log->debug("Input path is '$path'");
	    if ($path =~ /^\s*(\S+)\s*->\s*(\S+)\s*$/) {
		($src, $dst) = $self->normalize_paths($1, catfile($module->dir, $2));
	    } else {
		($src, $dst) = $self->normalize_paths($path, $module->dir);
	    }
	    $log->debug("Normalized path is $src -> $dst");
	    if ( (exists $views{$src}) && ($views{$src} ne $dst) ) {
		die "Trying to set path '($src,$dst)' but source is already set to '$dst'";
	    }

	    $views{$src} = $dst;
	    push @views, $src;
	}
    }

    foreach my $src (@views) {
	$view .= "\n\t$src $views{$src}";
    }

    $log->debug("New view is $view");

    $client .= "\n\nView:$view\n\n";

    if ($client ne $orig_client) {
	# The client has changes, so now update it
	{
	    local %ENV = %ENV;
	    foreach (keys %{$self->{env}}) {
		$ENV{$_} = $self->{env}->{$_};
	    }

	    my $cmd = "p4 client -i";
	    open P4CLIENT, "| $cmd 2>&1" or die "$cmd: $!";
	    print P4CLIENT $client;
	    close P4CLIENT;
	}
    }
    $log->debug("Client view is $client");

    $self->initialized(1);
}

sub normalize_paths {
    my $self = shift;
    my $src = shift;
    my $dst = shift;

    $src =~ s,^/*,,g;
    $dst =~ s,^/*,,g;

    $src = "//" . $src;
    $dst = "//" . $self->client_name . "/" . $dst;

    if ($src =~ m,/...$,) {
	if ($dst =~ m,/$,) {
	    $dst .= "...";
	} else {
	    $dst .= "/...";
	}
    }

    return ($src, $dst);
}

sub export {
    my $self = shift;
    my $runtime = shift;
    my $src = shift;
    my $dst = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    $self->sync_view($runtime, $logfile) unless $self->initialized();

    ($src, $dst) = $self->normalize_paths($src, $dst);

    my $rev;
    if ($src =~ /^(.*?):(\d+)\s*$/) {
	$src = $1;
	$rev = $2;
	$log->info("Got explicitly sync to $rev");
    }

    $src = "/$src" unless $src =~ m,^//,;
    $dst = "/$dst" unless $dst =~ m,^//,;

    my %changes = $self->list_changes($dst, $logfile);

    unless ($rev) {
	my $newest = 0;
	foreach my $change (sort { $changes{$a} <=> $changes{$b} } keys %changes) {
	    if ($changes{$change} < $runtime->timestamp &&
		$changes{$change} > $newest) {
		$rev = $change;
		$newest = $changes{$change};
	    }
	}
	die "cannot checkout $dst because there are not changelists present"
	    unless $rev;
	$log->info("Decided to sync to $rev");
    }

    my $changes = {};
    my $changed = 0;

    my ($output, $errors) = $self->_run(["p4", "sync", $dst . '@' . $rev], undef, $logfile);

    die "cannot checkout $dst because files at $rev are not in client view" if $errors &&
	$errors =~ /file\(s\) not in client view/;

    if ($output && (!$errors ||
		    $errors !~ /file\(s\) up-to-date/)) {
	$changed = 1;
	$changes = $self->get_changes($output, \%changes, $logfile);
    }

    return ($changed, $changes);
}


sub list_changes {
    my $self = shift;
    my $dst = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();
    $log->debug("Listing all changes at $dst");

    my ($output, $errors) = $self->_run(["p4", "-ztag", "changes", $dst], undef, $logfile);

    # Example output:
    #... change 2
    #... time 1110722418
    #... user dan
    #... client dan-laptop
    #... status submitted
    #... desc        First change
    # 3 blank lines

    my %changes;
    my $change;
    foreach my $line (split /\n/, $output) {
	chomp;
	if ($line =~ /^\s*$/) {
	    if ($change) {
		$change = undef;
	    }
	} else {
	    if ($line =~ /\.\.\.\schange\s(\d+)/) {
		$changes{$1} = 0;
		$change = $1;
	    } elsif ($line =~ /\.\.\.\stime\s(\d+)/) {
		$changes{$change} = $1;
	    }
	}
    }

    return %changes;
}

sub get_changes {
    my $self = shift;
    my $output = shift;
    my $changes = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my %wanted;
    for my $line (split /\n/, $output) {
	if ($line =~ m/^(.*?\#\d+) - (added|updating|deleted)/) {
	    my $depot_file = $1;
	    my $action = $2;
	    $log->debug("$depot_file, $action");
	    $depot_file =~ m/^(.*)\#(\d+)/;
	    my $file = $1;
	    my $revision = $2;
	    $revision++ if $action eq "deleted";

	    # XXX this only gets the most recent change to the file
	    # what if there were many since the last checkout.
	    my $changelist = $self->get_changelist_from_filespec($file, $revision, $logfile);
	    $wanted{$changelist} = 1 if defined $changelist;
	} else {
	    $log->warn("line did not match: $line");
	}
    }
    my %changes;
    for my $changelist (keys %wanted) {
	$changes{$changelist} = $self->get_changelist_info($changelist, $changes->{$changelist}, $logfile);
    }
    return \%changes;
}

sub get_changelist_info {
    my $self = shift;
    my $changelist = shift;
    my $timestamp = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my ($output, $errors) = $self->_run(["p4", "describe", $changelist], undef, $logfile);

    my %params = ( number => $changelist );
    if ($output =~ m/Change (\d+) by (.*?)\@(.*?) on (.*?)\n(.*?)^Affected files/sm) {
	$params{user} = $2;
	$params{description} = $5;
	$params{date} = $timestamp;

	$params{description} =~ s/^\s*//g;
	$params{description} =~ s/\s*$//g;
	$params{description} =~ s/\s*\n\*/\n/g;
    } else {
	die "could not parse $changelist: $output";
    }

    $params{files} = [];
    push @{$params{files}}, $output =~ m/^\.\.\. (.*)/mg;

    return Test::AutoBuild::Change->new(%params);
}

sub get_changelist_from_filespec {
    my $self = shift;
    my $file = shift;
    my $revision = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my %changelists;

    my ($output, $errors) = $self->_run(["p4", "fstat", $file . '#' . $revision], undef, $logfile);

    if ($output =~ m/headChange (.*)/m) {
	return $1;
    }

    return undef;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>,  L<Test::AutoBuild::Repository>

=cut
