# -*- perl -*-
#
# Test::AutoBuild::Repository::Darcs by Daniel Berrange
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

Test::AutoBuild::Repository::Darcs - A repository for Darcs

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::Darcs


=head1 DESCRIPTION

This module provides a repository implementation for the
Darcs revision control system. It requires that the
'darcs' command version 1.0.0 or higher be installed. It has
full support for detecting updates to an existing checkout.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::Darcs;

use base qw(Test::AutoBuild::Repository);
use warnings;
use strict;
use Log::Log4perl;
use XML::Simple;

use Test::AutoBuild::Change;
use Date::Manip;

=item my $repository = Test::AutoBuild::Repository::Darcs->new(  );

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
    my $current;
    if (-d $dst) {
	$current = $self->_get_current($dst, $logfile);
	$log->debug("Current changeset in $dst is $current");
	$self->_pull_repository($src, $dst, $logfile);
    } else {
	$self->_get_repository($src, $dst, $logfile);
	$changed = 1;
    }

    my %changes;

    my $all_changes = $self->_get_changes($dst, $logfile);

    my $sync_to;
    my $found = 0;
    # Find the first patch newer than our timestamp
    foreach (sort { $all_changes->{$a}->date <=> $all_changes->{$b}->date} keys %{$all_changes}) {
	#$log->debug("Compare changelist $_ at " . $all_changes->{$_}->date . " to " . $runtime->timestamp);
	if ($all_changes->{$_}->date > $runtime->timestamp) {
	    $sync_to = $_;
	    last;
	}
	if ($found) {
	    $changes{$all_changes->{$_}->number} = $all_changes->{$_};
	    $changed = 1;
	}
	$found = 1 if defined $current && $current eq $_;
    }

    if ($sync_to) {
	$log->debug("Sync to change $sync_to");

	# Revert any changed local files otherwise unpull will complain bitterly
	my ($output, $errors) = $self->_run(["darcs", "revert", "--all"], $dst, $logfile);

	# Suck suck suck. Darcs prompts interactively on unpull
	# if you've just donea revert, even if you tell it --all
	unlink "$dst/_darcs/patches/unrevert";

	# Finally unpull, upto the change we actually want
	($output, $errors) = $self->_run(["darcs", "unpull", "--all", "--match", "hash $sync_to"], $dst, $logfile);
    } else {
	$log->debug("Working directory already synced to neccessary change");
    }

    return ($changed, \%changes);
}

sub _get_repository {
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
    my ($result, $errors) = $self->_run(["darcs", "get", "--complete", $url, $dest], undef, $logfile);
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
    my ($result, $errors) = $self->_run(["darcs", "pull", "--no-summary", "--all", "$url"], $dest, $logfile);
}

sub _get_current {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();
    my ($output, $errors) = $self->_run(["darcs", "changes", "--xml-output", "--last=1"], $path, $logfile);

    my $xml = XMLin($output, ForceArray => 1);
    my $change = $xml->{patch}->[0];
    return $change->{hash};
}

sub _get_changes {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my ($output, $errors) = $self->_run(["darcs", "changes", "--xml-output"], $path, $logfile);

    my $xml = XMLin($output, ForceArray => 1);

    my %changes;
    foreach my $change (@{$xml->{patch}}) {
	my $date = ParseDateString($change->{date});
	$date = $date . "+0000";
	die "cannot parse date '" . $change->{date} . "'" unless $date;
	my $time = UnixDate($date, "%s");

	$changes{$change->{hash}} = Test::AutoBuild::Change->new(number => $change->{date},
								 date => $time,
								 user => $change->{author},
								 description => $change->{name}->[0],
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
