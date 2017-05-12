# -*- perl -*-
#
# Test::AutoBuild::Repository::Subversion by Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Repository::Subversion - A repository for Subversion

=head1 SYNOPSIS

  use Test::AutoBuild::Repository::Subversion


=head1 DESCRIPTION

Description

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository::Subversion;

use base qw(Test::AutoBuild::Repository);
use strict;
use warnings;
use POSIX qw(strftime);
use Log::Log4perl;
use Test::AutoBuild::Change;
use Date::Manip;

=item my $repository = AutoBuild::Repository::Subversion->new();

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    $self->{changelists} = {};

    bless $self, $class;

    return $self;
}


sub changelist {
    my $self = shift;
    my $runtime = shift;
    my $path = shift || "/";
    my $logfile = shift;

    my $timestamp = $runtime->timestamp;

    $self->{changelists}->{$timestamp} = {} unless defined $self->{changelists}->{$timestamp};

    if (!exists $self->{changelists}->{$timestamp}->{$path}) {
	$self->{changelists}->{$timestamp}->{$path} = $self->get_changelist($runtime, $path, $logfile);
    }
    return $self->{changelists}->{$timestamp}->{$path};
}

sub export {
    my $self = shift;
    my $runtime = shift;
    my $src = shift;
    my $dst = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    my $url = $self->option("url") or die "url option is required";
    $url =~ s,/$,,;

    my $date = strftime("{%Y-%m-%d %H:%M:%S +0000}", gmtime $runtime->timestamp);
    my $default = 0;
    my %changes;
    my $changed = 0;
    my $rev;
    if ($src =~ /^(.*?)(?:@(\d+))?\s*$/) {
	$src = $1;
	$rev = $2;
    }

    my $path = $url . "/" . $src;
    my $preRevision = -d $dst ? $self->current_revision($dst, $logfile) : undef;
    my ($output, $errors) =
	$self->_run(["svn", "checkout", "-r", $rev ? $rev : $date, $path, $dst], undef, $logfile);
    my $postRevision = $self->current_revision($dst, $logfile);

    if (defined $preRevision) {
	if ($preRevision  < $postRevision) {
	    $log->debug("Files updated, getting changes");
	    $self->get_changes($dst, \%changes, $preRevision+1, $postRevision, $logfile);
	    $changed = 1;
	} elsif ($preRevision != $postRevision) {
	    $log->debug("Files downgraded, skipping changes");
	    $changed = 1;
	} else {
	    $log->debug("Files unchanged");
	}
    } else {
	$log->debug("New checkout, skipping changes");
	$changed = 1;
    }

    return ($changed, \%changes);
}

sub current_revision {
    my $self = shift;
    my $path = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    $log->debug("Getting revision for path $path");
    my ($out, $errors) = $self->_run(["svn", "log", "-r", "COMMITTED", "-q", $path], undef, $logfile);
    my @lines = split /\n/, $out;
    if ($#lines != 2) {
	$log->error(@lines);
	die "expected 3 lines of log, got " . ($#lines +1);
    }
    if ($lines[1] !~ /^r(\d+)\s/) {
	die "cannot extract revision from log output '$lines[1]'";
    }
    return $1;
}


sub get_changelist {
    my $self = shift;
    my $runtime = shift;
    my $path = shift;
    my $logfile = shift;

    my $url = $self->option("url") or die "url option is required";
    $url .= $path;
    my $log = Log::Log4perl->get_logger();

    my $date = strftime("{%Y-%m-%d %H:%M:%S +0000}", gmtime $runtime->timestamp);

    $log->debug("Getting revision for path $path");
    my ($out, $errors) = $self->_run(["svn", "log", "-r", $date, "-q", $url], undef, $logfile);
    my @lines = split /\n/, $out;
    if ($#lines != 2) {
	$log->error(@lines);
	die "expected 3 lines of log, got " . ($#lines +1);
    }
    if ($lines[1] !~ /^r(\d+)\s/) {
	die "cannot extract revision from log output '$lines[1]'";
    }
    return $1;
}

sub get_changes {
    my $self = shift;
    my $path = shift;
    my $changes = shift;
    my $from = shift;
    my $to = shift;
    my $logfile = shift;

    my $log = Log::Log4perl->get_logger();

    $log->debug("Getting logs between $from and $to for $path");

    my ($out, $errors) = $self->_run(["svn", "log", "-v", "-r", "$from:$to", $path], undef, $logfile);
    my @entries = split /\n/, $out;
    shift @entries;
    while ($#entries != -1) {
	my @lines;
	while (defined (my $entry = shift @entries)) {
	    last if $entry =~ /^\s*\-+\s*$/;
	    push @lines, $entry;
	}
	my $change = $self->get_change(@lines);
	$changes->{$change->number} = $change;
    }
}

sub get_change {
    my $self = shift;
    my @lines = @_;

    my $meta = shift @lines;
    my $revision;
    my $author;
    my $datestr;
    my $tz;
    if ($meta =~ /^\s*r(\d+)\s*\|\s*(.*?)\s*\|\s*(.*?)\s+((?:\+|-)\d\d\d\d)\s*\(.*?\)\s*\|\s*(\d+)\s*line/) {
	$revision = $1;
	$author = $2;
	$datestr = $3;
	$tz = $4;
    } else {
	die "cannot extract revision metadata from log output '$meta'";
    }

    shift @lines; # 'Changed paths:'

    my @files;
    while (defined (my $entry = shift @lines)) {
	last if $entry =~ /^\s*$/;

	$entry =~ /^\s*(.*?)\s*$/;
	push @files, $1;
    }

    my $message = join ("\n", @lines);
    my $date = ParseDate($datestr);
    die "cannot parse date '$datestr'" unless defined $date;
    $date = Date_ConvTZ($date, $tz, "GMT");
    $date = $date . "+0000";

    return Test::AutoBuild::Change->new(number => $revision,
					user => $author,
					date => UnixDate($date, "%s"),
					files => \@files,
					description => $message);
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
