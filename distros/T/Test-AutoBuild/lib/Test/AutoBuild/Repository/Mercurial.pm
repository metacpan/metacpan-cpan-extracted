# -*- perl -*-
#
# Test::AutoBuild::Repository::Mercurial by Daniel Berrange
#
# Copyright (C) 2004 Daniel Berrange
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

Test::AutoBuild::Repository::Mercurial - A repository for Mercurial

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::Mercurial


=head1 DESCRIPTION

This module provides a repository implementation for the
Mercurial revision control system. It requires that the
'hg' command version 0.7 or higher be installed. It has
full support for detecting updates to an existing checkout.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::Mercurial;

use base qw(Test::AutoBuild::Repository);
use warnings;
use strict;
use Log::Log4perl;

use Test::AutoBuild::Change;
use Date::Manip;

=item my $repository = Test::AutoBuild::Repository::Mercurial->new(  );

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    bless $self, $class;

    return $self;
}


sub export {
    my $self = shift;
    my $runtime = shift;
    my $src = shift;
    my $dst = shift;
    my $logfile = shift;
    my $log = Log::Log4perl->get_logger();

    # Don't support using multiple paths yet
    if (-d $dst) {
	$self->_pull_repository($src, $dst, $logfile);
    } else {
	$self->_clone_repository($src, $dst, $logfile);
    }

    my $changed = 0;
    my %changes;

    my $current = $self->_get_changeset($dst, $logfile);
    $log->debug("Current changeset in $dst is $current");

    my $all_changes = $self->_get_changes($dst, $logfile);

    my $sync_to;
    my $found = 0;
    foreach (sort { $all_changes->{$a}->date <=> $all_changes->{$b}->date} keys %{$all_changes}) {
	$sync_to = $_ unless defined $sync_to;
	#$log->debug("Compare changelist $_ at " . $all_changes->{$_}->date . " to " . $runtime->timestamp);
	last if $all_changes->{$_}->date > $runtime->timestamp;
	$sync_to = $_;
	$changes{$all_changes->{$_}->number} = $all_changes->{$_} if $found;
	$found = 1 if $current eq $_;
    }

    $log->debug("Sync to change $sync_to");

    if ($current ne $sync_to) {
	my ($output, $errors) = $self->_run(["hg", "update", "-C", $sync_to], $dst, $logfile);
	$changed = 1;
    }

    return ($changed, \%changes);
}

sub _clone_repository {
    my $self = shift;
    my $path = shift;
    my $dest = shift;
    my $logfile = shift;
    my $log = Log::Log4perl->get_logger();

    my $base_url = $self->option("base-url");
    die "base-url option is required" unless $base_url;
    $base_url =~ s,\/$,,;
    $path =~ s,^/,,;
    my $url = "$base_url/$path";

    $log->info("Cloning repository at $url");
    my ($result, $errors) = $self->_run(["hg", "clone", $url, $dest], undef, $logfile);
}

sub _pull_repository {
    my $self = shift;
    my $path = shift;
    my $dest = shift;
    my $logfile = shift;
    my $log = Log::Log4perl->get_logger();

    my $base_url = $self->option("base-url");
    die "base-url option is required" unless $base_url;
    $base_url =~ s,\/$,,;
    $path =~ s,^/,,;
    my $url = "$base_url/$path";

    $log->info("Pulling from repository at $url");
    my ($result, $errors) = $self->_run(["hg", "pull", "$url"], $dest, $logfile);
}

sub _get_changeset {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();
    my ($output, $errors) = $self->_run(["hg", "identify", "-v"], $path, $logfile);

    my @lines = split /\n/, $output;
    foreach (@lines) {
	if (/^([a-f0-9]+)\+?(?:\s+(.*))?$/i) {
	    return $1;
	}
    }
    die "cannot extract current changelist from hg identify -v output";
}

sub _get_changes {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my ($data, $errors) = $self->_run(["hg", "history", "-v"], $path, $logfile);

    my @lines = split /\n/, $data;

    my %logs;
    my $number;
    my $hash;
    foreach my $line (@lines) {
	next if $line =~ /^\s*$/;
	#$log->debug("[$line]");
	if ($line =~ m,^changeset:\s*(\d+):([a-f0-9]+)\s*$,i) {
	    $number = $1;
	    $hash = $2;
	    $log->debug("Version number " . $number . " changeset hash " . $hash);
	    $logs{$hash} = { number => $number };
	} elsif (defined $hash) {
	    if ($line =~ m,^user:\s*(.*?)\s*$,) {
		$logs{$hash}->{user} = $1;
		#$log->debug("User " . $logs{$hash}->{user});
	    } elsif ($line =~ m,^date:\s*(.*?)\s*$,) {
		$logs{$hash}->{date} = $1;
		$log->debug("Date " . $logs{$hash}->{date});
	    } elsif ($line =~ m,^files:\s*(.*?)\s*$,) {
		$logs{$hash}->{files} = $1;
		#$log->debug("Files " . $logs{$hash}->{files});
	    } elsif ($line =~ m,^description:\s*(.*?)\s*$,) {
		$logs{$hash}->{description} = '';
		#$log->debug("Description started ");
	    } elsif (defined $logs{$hash}->{description}) {
		$line =~ s/(^\s*)|(\s*$)//g;
		if ($logs{$hash}->{description} eq "") {
		    $logs{$hash}->{description} .= $line;
		} else {
		    $logs{$hash}->{description} .= "\n" . $line;
		}
		#$log->debug("Append Desc " . $line);
	    } elsif ($line =~ m,^(tag|parent|branch),) {
		# nada
	    } else {
		$log->warn("Got unexpected changelist tag " . $line);
	    }
	} else {
	    $log->warn("Got content outside changelist " . $line);
	}
    }

    my %changes;
    foreach (keys %logs) {
	# XXX hate to hardcode date format. Probably break in non en_* locales
	die "cannot grok date '"  . $logs{$_}->{date} . "'"
	    unless $logs{$_}->{date} =~ /(\w+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)\s+(\S+)\s*$/;
	my $mungedDate = "$1 $2 $3 $7 $4:$5:$6";
	my $timezone = $8;

	my $date = ParseDateString($mungedDate);
	die "cannot parse date '" . $mungedDate . "'" unless $date;
	$log->debug("Initial parsing from '$mungedDate' gives $date");
	$date = Date_ConvTZ($date, $timezone, "GMT");
	$date = $date . "+0000";
	$log->debug("After adjustment from $timezone to GMT date is $date");
	my $time = UnixDate($date, "%s");
	$log->debug("Date was $date and time is $time");

	my @files = $logs{$_}->{files} ? split / /, $logs{$_}->{files} : ();

	$changes{$_} = Test::AutoBuild::Change->new(number => $logs{$_}->{number},
						    date => $time,
						    user => $logs{$_}->{user},
						    description => $logs{$_}->{description},
						    files => \@files);
    }
    return \%changes;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange

=head1 COPYRIGHT

Copyright (C) 2004 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Repository>

=cut
