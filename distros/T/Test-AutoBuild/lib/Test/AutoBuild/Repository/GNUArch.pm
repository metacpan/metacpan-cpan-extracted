# -*- perl -*-
#
# Test::AutoBuild::Repository::GNUArch by Daniel Berrange
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

Test::AutoBuild::Repository::GNUArch - A repository for GNU Arch

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::GNUArch


=head1 DESCRIPTION

This module provides a repository implementation for the
GNU Arch revision control system. It requires that the
'tla' command version 1.1 or higher be installed. It has
full support for detecting updates to an existing checkout.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::GNUArch;

use base qw(Test::AutoBuild::Repository);
use strict;
use warnings;
use Log::Log4perl;

use Test::AutoBuild::Change;
use Date::Manip;

=item my $repository = Test::AutoBuild::Repository::GNUArch->new(  );

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

    # Make sure all archives are up2date
    $self->_register_archives($logfile);

    my $arch_name = $self->option("archive-name");

    my $changed = 0;
    my %changes;
    if (!-d $dst) {
	my ($output, $errors) = $self->_run(["tla","get", "--archive", $arch_name, $src, $dst], undef, $logfile);
	$changed = 1;
    }

    my $current = $self->_get_revision($dst, $logfile);
    $log->debug("Current change for $src is $current");
    my $all_changes = $self->_get_changes($arch_name, $src, $logfile);
    my $sync_to;
    my $found = 0;
    foreach (sort { $all_changes->{$a}->{date} <=> $all_changes->{$b}->{date}} keys %{$all_changes}) {
	$sync_to = $_ unless $sync_to;
	$log->debug("Compare " . $all_changes->{$_}->date . " to " . $runtime->timestamp);
	last if $all_changes->{$_}->date > $runtime->timestamp;
	$sync_to = $_;
	$changes{$_} = $all_changes->{$_} if $found;
	$found = 1 if $current eq $_;
    }

    $log->debug("Sync to change $sync_to");


    if ($current ne $sync_to) {

	my ($output, $errors) = $self->_run(["tla", "apply-delta", "--archive", $arch_name, $current, $sync_to], $dst, $logfile);
	$changed = 1;
    }

    return ($changed, \%changes);
}

sub _register_archives {
    my $self = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my $arch_name = $self->option("archive-name");
    my $arch_uri = $self->option("archive-uri");

    my ($existing, $errors) = $self->_run(["tla", "archives","-n", "-R"], undef, $logfile);

    my %existing;
    if ($existing) {
	map { $existing{$_} = 1 } split /\n/, $existing;
    }

    if (! exists $existing{$arch_name}) {
	my ($output, $errors2) = $self->_run(["tla", "register-archive", $arch_name, $arch_uri], undef, $logfile);
    }
}


sub _get_revision {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my ($output, $errors) = $self->_run(["tla", "logs", "-d", $path, "-r"], undef, $logfile);
    my @lines = split /\n/, $output;
    return $lines[0];
}

sub _get_changes {
    my $self = shift;
    my $arch_name = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my ($data, $errors) = $self->_run(["tla","abrowse", "-A", $arch_name, "-f", "-s", "-D", "-c", $path], undef, $logfile);

    my @lines = split /\n/, $data;

    if ($lines[0] =~ /Failed to access file '\.archive-version'/) {
	shift @lines;
    }
    if ($lines[0] =~ /Could not determine archive format/) {
	shift @lines;
    }

    die "archive name $lines[0] did not match $arch_name"
	unless $lines[0] eq $arch_name;
    $lines[1] =~ s/^\s*//g;
    die "module name $lines[1] did not match $path"
	unless (index $path, $lines[1]) == 0;
    $lines[2] =~ s/^\s*//g;
    die "module branch $lines[2] did not match $path"
	unless (index $path, $lines[2]) == 0;
    $lines[3] =~ s/^\s*//g;
    die "module version $lines[3] did not match $path"
	unless (index $path, $lines[3]) == 0;
    splice @lines, 0, 4;

    my %logs;
    my $number;
    foreach my $line (@lines) {
	next if $line =~ /^\s*$/;
	#$log->debug("[$line]");
	if ($line =~ m,^\s+$arch_name/$path--((?:(?:patch)|(?:base))-\d+)\s*$,) {
	    $number = $1;
	    $log->debug("Version " . $number);
	    $logs{$number} = {};
	} elsif ($line =~ /^\s*(\d\d\d\d-\d\d-\d\d\s+\d\d:\d\d:\d\d\s+\S+)\s+(.*?)\s*$/) {
	    $logs{$number}->{date} = $1;
	    $logs{$number}->{user} = $2;
	    $log->debug("Date " . $logs{$number}->{date});
	    $log->debug("User " . $logs{$number}->{user});
	} elsif (!exists $logs{$number}->{description}) {
	    $line =~ s/(^\s*)|(\s*$)//g;
	    $logs{$number}->{description} = $line;
	    $log->debug("Desc " . $logs{$number}->{description});
	} else {
	    $line =~ s/(^\s*)|(\s*$)//g;
	    $logs{$number}->{description} .= "\n" . $line;
	    $log->debug("Append Desc " . $logs{$number}->{description});
	}
    }

    my %changes;
    foreach (keys %logs) {
	my $date = ParseDate($logs{$_}->{date});
	die "cannot parse date " . $logs{$_}->{date} unless $date;
	my $time = UnixDate($date, "%s");
	$log->debug("Date was $date and time is $time");
	$changes{$_} = Test::AutoBuild::Change->new(number => $_,
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

Copyright (C) 2004 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Repository>

=cut
