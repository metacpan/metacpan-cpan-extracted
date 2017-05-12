# -*- perl -*-
#
# Test::AutoBuild::Repository::Bazaar by Daniel Berrange
#
# Copyright (C) 2004-2007 Daniel Berrange
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

Test::AutoBuild::Repository::Bazaar - A repository for Bazaar

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::Bazaar


=head1 DESCRIPTION

This module provides a repository implementation for the
Bazaar revision control system. It requires that the
'bzr' command version 0.91 or higher be installed. It has
full support for detecting updates to an existing checkout.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::Bazaar;

use base qw(Test::AutoBuild::Repository);
use warnings;
use strict;
use Log::Log4perl;

use Test::AutoBuild::Change;
use Date::Manip;

=item my $repository = Test::AutoBuild::Repository::Bazaar->new(  );

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
    my $changed = 0;
    my $orig;
    my $now;
    if (-d $dst) {
	$orig = $self->_get_current($dst, $logfile);
	$log->debug("Current changeset in $dst is $orig");
	$self->_pull_repository($src, $dst, $logfile);
    } else {
	$self->_checkout_repository($src, $dst, $logfile);
	$changed = 1;
    }

    $now = $self->_get_current($dst, $logfile);

    my %changes;
    my $all_changes = $self->_get_changes($dst, $logfile);

    my $sync_to;
    my $found = 0;
    foreach (sort { $all_changes->{$a}->date <=> $all_changes->{$b}->date} keys %{$all_changes}) {
	$sync_to = $_ unless defined $sync_to;
	#$log->debug("Compare changelist $_ at " . $all_changes->{$_}->date . " to " . $runtime->timestamp);
	last if $all_changes->{$_}->date > $runtime->timestamp;
	$sync_to = $_;
#	warn "[$_ ] $found\n";
	$changes{$all_changes->{$_}->number} = $all_changes->{$_} if $found;
	$found = 1 if defined $orig && $orig eq $_;
    }


    if ($sync_to &&
	(!$orig ||
	$orig ne $sync_to)) {
	$log->debug("Sync to change $sync_to");
	$changed = 1;
    }

    if ($sync_to ne $now) {
	my ($output, $errors) = $self->_run(["bzr", "uncommit", "--force", "--revision", "revid:" . $sync_to], $dst, $logfile);
	($output, $errors) = $self->_run(["bzr", "revert"], $dst, $logfile);
	($output, $errors) = $self->_run(["bzr", "update"], $dst, $logfile);
    }

    return ($changed, \%changes);
}

sub _checkout_repository {
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
    my ($result, $errors) = $self->_run(["bzr", "clone", $url, $dest], undef, $logfile);
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
    my ($result, $errors) = $self->_run(["bzr", "pull", "$url"], $dest, $logfile);
}

sub _get_current {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();
    my ($output, $errors) = $self->_run(["bzr", "log", "--show-ids", "--short", "--limit=1"], $path, $logfile);
#    warn $output;
    my @lines = split /\n/, $output;
    foreach (@lines) {
	if (/^\s*revision-id:\s*(.*?)\s*$/i) {
	    return $1;
	}
    }
    die "cannot extract current changelist from bzr log --show-ids --short --limit=1 output";
}

sub _get_changes {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my ($data, $errors) = $self->_run(["bzr", "log", "--show-ids", "--timezone=utc"], $path, $logfile);

    my @lines = split /\n/, $data;

    my %logs;
    my $number;
    foreach my $line (@lines) {
	next if $line =~ /^\s*$/;
	#$log->debug("[$line]");
	if ($line =~ m,^revno:\s*(\d+(?:\.\d+)*)\s*(\[merge\])?\s*$,i) {
	    $number = $1;
	    $log->debug("Version number " . $number );
	    $logs{$number} = { number => $number };
	} elsif (defined $number) {
	    if ($line =~ m,^committer:\s*(.*?)\s*$,) {
		$logs{$number}->{user} = $1;
		$log->debug("User $1");
	    } elsif ($line =~ m,^revision-id:\s*(.*?)\s*$,) {
		$logs{$number}->{hash} = $1;
		$log->debug("Hash $1");
	    } elsif ($line =~ m,^timestamp:\s*(.*?)\s*$,) {
		$logs{$number}->{timestamp} = $1;
		$log->debug("Timestamp $1");
	    } elsif ($line =~ m,^message:\s*(.*?)\s*$,) {
		$logs{$number}->{description} = $1;
	    } elsif ($line =~ m,^\s*\-+\s*$,) {
		$number = undef;
	    } elsif (defined $logs{$number}->{description}) {
		$line =~ s/(^\s*)|(\s*$)//g;
		if ($logs{$number}->{description} eq "") {
		    $logs{$number}->{description} .= $line;
		} else {
		    $logs{$number}->{description} .= "\n" . $line;
		}
		#$log->debug("Append Desc " . $line);
	    }
	} else {
	    $log->warn("Got content outside changelist " . $line);
	}
    }

    my %changes;
    foreach (keys %logs) {
	# XXX hate to hardcode date format. Probably break in non en_* locales
	die "cannot grok date '"  . $logs{$_}->{timestamp} . "'"
	    unless $logs{$_}->{timestamp} =~ /\s*(.*?)\s+((?:\-|\+)\d+)\s*$/;
	my $mungedDate = $1;
	my $timezone = $2;

	my $date = ParseDateString($mungedDate);
	die "cannot parse date '" . $mungedDate . "'" unless $date;
	#$log->debug("Initial parsing from '$mungedDate' gives $date");
	$date = Date_ConvTZ($date, $timezone, "GMT");
	$date = $date . "+0000";
	#$log->debug("After adjustment from $timezone to GMT date is $date");
	my $time = UnixDate($date, "%s");
	#$log->debug("Date was $date and time is $time");

	$changes{$logs{$_}->{hash}} = Test::AutoBuild::Change->new(number => $logs{$_}->{number},
								   date => $time,
								   user => $logs{$_}->{user},
								   description => $logs{$_}->{description},
								   files => []);
    }
    return \%changes;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange

=head1 COPYRIGHT

Copyright (C) 2004-2007 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Repository>

=cut
