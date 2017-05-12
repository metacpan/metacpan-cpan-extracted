# -*- perl -*-
#
# Test::AutoBuild::Repository::Monotone by Daniel Berrange
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

Test::AutoBuild::Repository::Monotone - A repository for Monotone

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::Monotone


=head1 DESCRIPTION

This module provides a repository implementation for the
Monotone revision control system. It requires that the
'hg' command version 0.7 or higher be installed. It has
full support for detecting updates to an existing checkout.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::Monotone;

use base qw(Test::AutoBuild::Repository);
use warnings;
use strict;
use Log::Log4perl;

use Test::AutoBuild::Change;
use Date::Manip;

=item my $repository = Test::AutoBuild::Repository::Monotone->new(  );

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

    die "missing branch spec" unless $src =~ /^\s*(.*?):(.*)\s*$/;
    my $branch = $2;
    $src = $1;

    my $server = $self->option("server");
    my $path = $self->option("path");
    die "server or path option is required" unless $server or $path;
    $src =~ s,^/,,;

    my $db;
    if ($path) {
	$db = $path . "/" . $src;
    } else {
	$db = $self->_setup_repo($dst, $logfile);
	$self->_pull_repo($db, $server, $branch, $logfile);
    }

    # Don't support using multiple paths yet
    my $current;
    my $changed = 0;
    if (!-d $dst) {
	$changed = 1;
	$self->_checkout_repo($db, $branch, $dst, $logfile);
    } else {
	$current = $self->_get_changeset($dst, $logfile);
    }


    my %changes;


    my $all_changes = $self->_get_changes($dst, $branch, $logfile);

    my $sync_to;
    my $found = 0;
    foreach (sort { $all_changes->{$a}->date <=> $all_changes->{$b}->date} keys %{$all_changes}) {
	$sync_to = $all_changes->{$_}->number unless defined $sync_to;
	#$log->debug("Compare changelist $_ at " . $all_changes->{$_}->date . " to " . $runtime->timestamp);
	last if $all_changes->{$_}->date > $runtime->timestamp;
	$sync_to = $all_changes->{$_}->number;
	$log->debug("Add " . $all_changes->{$_}->number) if $found;
	$changes{$all_changes->{$_}->number} = $all_changes->{$_} if $found;
	$found = 1 if defined $current && $current eq $_;
    }

    if ($sync_to) {
	$log->debug("Sync to change $sync_to");
    }

    if (defined $current &&
	$current ne $sync_to) {
	$changed = 1;
    }

    my ($output, $errors) = $self->_run(["mtn", "update", "-r", $sync_to], $dst, $logfile);

    return ($changed, \%changes);
}

sub _setup_repo {
    my $self = shift;
    my $dst = shift;
    my $logfile = shift;

    my $db = $dst . ".db";
    my ($output, $errors) = $self->_run(["mtn", "db", "init", "-d", $db], undef, $logfile)
	unless -f $db;
    return $db;
}

sub _checkout_repo {
    my $self = shift;
    my $db = shift;
    my $branch = shift;
    my $dest = shift;
    my $logfile = shift;
    my $log = Log::Log4perl->get_logger();


    $log->info("Checking out from db $db to $dest");
    my ($result, $errors) = $self->_run(["mtn", "checkout", "-d", $db, "--branch", $branch, $dest], undef, $logfile);
}

sub _pull_repo {
    my $self = shift;
    my $db = shift;
    my $server = shift;
    my $branch = shift;
    my $logfile = shift;
    my $log = Log::Log4perl->get_logger();

    $log->info("Pulling from repository at $server");
    my ($result, $errors) = $self->_run(["mtn", "pull", "-d", $db, $server, $branch], undef, $logfile);
}

sub _get_changeset {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();
    my ($output, $errors) = $self->_run(["mtn", "status"], $path, $logfile);

    my @lines = split /\n/, $output;
    foreach (@lines) {
	if (/^Changes against parent ([a-f0-9]+)\s*$/i) {
	    return $1;
	}
    }
    die "cannot extract current changelist from mtn status output";
}

sub _get_changes {
    my $self = shift;
    my $path = shift;
    my $branch = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my ($data, $errors) = $self->_run(["mtn", "log", "--no-graph", "--from", "b:$branch"], $path, $logfile);

    my @lines = split /\n/, $data;

    my $indesc = 0;

    my %logs;
    my $hash;
    foreach my $line (@lines) {
	next if $line =~ /^\s*$/;
	#$log->debug("[$line]");
	if ($line =~ m,^revision:\s*([a-f0-9]+)\s*$,i) {
	    $hash = $1;
	    $log->debug("Changeset hash " . $hash);
	    $logs{$hash} = { hash => $hash };
	    $indesc = 0;
	} elsif (defined $hash) {
	    if ($line =~ m,^Author:\s*(.*?)\s*$,) {
		$logs{$hash}->{user} = $1;
		#$log->debug("User " . $logs{$hash}->{user});
	    } elsif ($line =~ m,^Date:\s*(.*?)\s*$,) {
		$logs{$hash}->{date} = $1;
		$log->debug("Date " . $logs{$hash}->{date});
	    } elsif ($line =~ m,^\s*(?:patched)\s+(.*?)\s*$,i) {
		$logs{$hash}->{files} = [] unless exists $logs{$hash}->{files};
		push @{$logs{$hash}->{files}}, $1;
		$log->debug("Files " . $logs{$hash}->{files});
	    } elsif ($line =~ m,^ChangeLog:\s*(.*?)\s*$,i) {
		$logs{$hash}->{description} = '';
		$indesc = 1;
		#$log->debug("Description started ");
	    } elsif ($line =~ m,^\s*Changes against parent,) {
		$indesc = 0;
	    } elsif ($line =~ m,^\s*\-+\s*$,) {
		$hash = undef;
	    } elsif ($indesc && defined $logs{$hash}->{description}) {
		$line =~ s/(^\s*)|(\s*$)//g;
		if ($logs{$hash}->{description} eq "") {
		    if ($line ne "") {
			$logs{$hash}->{description} .= $line;
		    }
		} else {
		    $logs{$hash}->{description} .= "\n" . $line;
		}
		#$log->debug("Append Desc " . $line);
	    } elsif ($line =~ m,^(Branch|Parent|Tag),) {
		# nada
	    } else {
		$log->warn("Got unexpected changelist tag " . $line);
	    }
	} elsif ($line =~ m,^\s*\-+\s*$,) {
	    # nada
	} else {
	    $log->warn("Got content outside changelist " . $line);
	}
    }

    my %changes;
    foreach (keys %logs) {
	my $date = ParseDateString($logs{$_}->{date});
	die "cannot parse date '" . $logs{$_}->{date} . "'" unless $date;
	$log->debug("Initial parsing from '" . $logs{$_}->{date} . "' gives $date");
	$date = $date . "+0000";
	my $time = UnixDate($date, "%s");
	#my $change = UnixDate($date, "%Y-%m-%dT%H:%m:%s");
	my $change = $logs{$_}->{date};
	#$log->debug("Date was $date and time is $time");

	$log->debug("Change " . $logs{$_}->{hash} . " " . $date . " " . $logs{$_}->{description});

	$changes{$logs{$_}->{hash}} =
	    Test::AutoBuild::Change->new(number => $logs{$_}->{hash},
					 date => $time,
					 user => $logs{$_}->{user},
					 description => $logs{$_}->{description},
					 files => $logs{$_}->{files});
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
