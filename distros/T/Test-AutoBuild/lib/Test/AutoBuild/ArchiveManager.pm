# -*- perl -*-
#
# Test::AutoBuild::ArchiveManager
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2004-2005 Dennis Gregorovice, Daniel Berrange
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

Test::AutoBuild::ArchiveManager - The base class for managing archive

=head1 SYNOPSIS

  # Create a manager (must be some subclass)
  use Test::AutoBuild::ArchiveManager::XXX;
  my $manager = Test::AutoBuild::Manager::XXX->new()


  # Create a new archive, keyed off current time
  $manager->create_archive(time);


  # Get current archive & store some stuff
  my $archive = $manager->get_current_archive
  $archive->save_data("myobject", "build", { status => "failed" });


  # Get prevous archive, aka the 'cache' from last cycle
  my $cache = $manager->get_previous_archive
  if ($cache->has_data("myobject", "build")) {
    my $build = $cache->get_data("myobject", "build");
    print "Previous status was ", $build->{status};
  }


  # Purge invalid archives
  foreach ($manager->list_invalid_archives) {
    $manager->delete_archive($_->key);
  }


=head1 DESCRIPTION

The C<Test::AutoBuild::ArchiveManager> module provides capabilities
for managing a set of C<Test::AutoBuild::Archive> instances. It provides
apis for creation, deletion and retrieval of archive intances, and for
determining when an archive should be expired. This module is an abstract
base class providing generic functionality, and is intended to be subclassed
to provide functionality specific to the backend storage system. It works
hand in hand with the L<Test::AutoBuild::Archive> module which defines
APIs for working with a single archive intance.

The most commonly used subclass is L<Test::AutoBuild::ArchiveManager::File>
which provides for management of archives stored on local filesystem, via
the L<Test::AutoBuild::Archive::File> module. For demo & test purposes there
is also an in-memory manager L<Test::AutoBuild::ArchiveManager::Memory>,
although obviously this should not be used for large scale archives, since
it stores absolutely everything in RAM.

=head1 SUBCLASSING

There are three methods which must be implemented by all subclasses; The
default implementations of these methods simply call C<die>, informing
the caller that the subclass forgot to override them.

=over 4

=item list_archives

To retrieve a list of all archives currently managed. This will later
be filtered to separate out current / expired archives.

=item create_archive

To create a new empty instance of the L<Test::AutoBuild::Archive> subclass
related to this module

=item delete_archive

To delete an instance of L<Test::AutoBuild::Archive> no longer required.

=back

=head1 METHODS

=over 4

=item my $manager = Test::AutoBuild::ArchiveManager->new('max-age' => $age,
							 'max-instance' => $count,
							 'max-size' => $size,
							 'options' => \%options);

This method creates a new archive manager instance. This method is not for use
by end users since this is an abstract base class; indeed this metohd will die
unless the class being constructed is a subclass. The C<max-age> parameter
is used to set the C<max_age> property, defaulting to C<7d>. The C<max-size>
parameter is used to set the C<max_size> property defaulting to C<1g>. The
C<max-instance> parameter is used to set the C<max_instance> property defaulting
to C<10>. The final C<options> parameter is a hash reference containing
arbitrary key, value pairs. These are not used by this class, however, may be
used by subclasses for implementation specific configuration parameters.

=cut

package Test::AutoBuild::ArchiveManager;

use warnings;
use strict;
use Class::MethodMaker
    new_with_init => qw(new),
    get_set => [qw(max_age max_instance max_size)];
use Log::Log4perl;

sub init {
    my $self = shift;
    my %params = @_;

    die ref($self) . " is an abstract module and must be sub-classed"
	if ref($self) eq "Test::AutoBuild::ArchiveManager";

    $self->max_age(exists $params{'max-age'} ? $params{'max-age'} : "7d");
    $self->max_instance(exists $params{'max-instance'} ? $params{'max-instance'} : "10");
    $self->max_size(exists $params{'max-size'} ? $params{'max-size'} : "1g");

    $self->{options} = $params{options} ? $params{options} : {};
}


=pod

=item my $value = $manager->option($name[, $newvalue]);

Retrieves the subclass specific configuration option specified
by the C<$name> parameter. If there is no stored option associated
with the key C<$name>, then C<undef> is returned. If the C<$newvalue>
parameter is supplied, then the stored option value is updated.

=cut

sub option {
   my $self = shift;
   my $name = shift;

   $self->{options}->{$name} = shift if @_;

   return $self->{options}->{$name};
}

=pod

=item my $archive = $manager->get_current_archive();

This retrieves the most recently created, and still valid,
archive instance managed by this object. If there are no
valid archives currently managed, this returns C<undef>.
This is the method one would typically use to retrieve
the archive into which the current build cycle's results
will be stored.

=cut

sub get_current_archive {
    my $self = shift;

    my @archives = $self->list_archives;
    if ($#archives > -1) {
	return $archives[$#archives];
    }
    return;
}

=pod

=item my $archive = $manager->get_previous_archive();

This retrieves the second most recently created, and still
valid archive instance managed by this object. If there are
less than two valid archives managed, this returns C<undef>.
This is the method one would typically use to retrieve
the archive from which the previous build cycle's results
can be extracted.

=cut

sub get_previous_archive {
    my $self = shift;

    my @archives = $self->list_archives;
    if ($#archives > 0) {
	return $archives[$#archives-1];
    }
    return;
}

=pod

=item my $archive = $manager->create_archive($key);

This creates a new instance of the L<Test::AutoBuild::Archive>
subclass used by this object, assigning it the unique key
C<$key>. Archive keys should be generated such that when comparing
the keys for two archives, the key associated with the newest
archive compares numerically larger than that of the older archive.
For all intents & purposes this means, that keys should be monotonically
increasing integers. New prescence of a newly created archive is
immediately reflected by the other methods in this class. ie, what
was the 'current archive' is will become the 'previous archive', and
the new archive will be the new 'previous archive'. Any expiry / validity
rules will also immediately take effect, for example 'max-instances' may
cause an older archive to become invalid. This method must be overriden
by subclass, since the default implementation will simply call C<die>.

=cut

sub create_archive {
    my $self = shift;
    my $key = shift;

    die "module " . ref($self) . " forgot to implement the create_archive method";
}

=pod

=item $manager->delete_archive($key);

This deletes archive instance associated with this manager which
has the key C<$key>. If there is no matching achive instance, this
method will call C<die>. The deletion of an archive is immediately
reflected by the other methods in this class. This method must be
overriden by subclass, since the default implementation will simply
call C<die>.

=cut

sub delete_archive {
    my $self = shift;
    my $key = shift;

    die "module " . ref($self) . " forgot to implement the delete_archive method";
}

=pod

=item my @archives = $manager->list_archives;

Returns a list of all archive instances, valid or not, currently managed
by this manager object. The archive instances will be some subclass of
L<Test::AutoBuild::Archive> applicable to this manager object. The list
will be sorted such that the oldest archive is the first in the list,
while the newest archive is the last in the list. This method must be
overriden by subclasses, since the default implementation simply calls
C<die>.

=cut

sub list_archives {
    my $self = shift;

    die "module " . ref($self) . " forgot to implement the list_archives method";
}


=pod

=item my @archives = $manager->list_invalid_archives;

Returns a list of all invalid archive instances currently managed by
this manager. An archive is invalid, if its inclusion in the list
would cause any of the C<max-size>, C<max-instance>, or C<max-age>
constraints to be violated. Invalid archives are typically candidates
for immediate deletion.

=cut

sub list_invalid_archives {
    my $self = shift;

    my $now = time;
    my @invalid;
    my $log = Log::Log4perl->get_logger();
    my @archives = reverse $self->list_archives;
    $log->debug("Checking validity of " . int(@archives) . " archives");
    my $seen = {};
    my $size = 0;
    for (my $i = 0 ; $i <= $#archives ; $i++) {
	if ($i >= $self->max_instance) {
	    $log->info("Archive $i is invalid because there are too many instances");
	    push @invalid, $archives[$i];
	    next;
	}
	if ($self->_has_archive_expired($archives[$i], $now)) {
	    $log->info("Archive $i is invalid because it has expired");
	    push @invalid, $archives[$i];
	    next;
	}

	$size += $archives[$i]->size($seen);
	if ($self->_is_archive_to_large($size)) {
	    $log->info("Archive $i is invalid because the total size is too great");
	    push @invalid, $archives[$i];
	    next;
	}
    }

    return @invalid;
}


sub total_size {
    my $self = shift;
    my @archives = shift;

    my $size;
    my $seen = {};
    foreach my $archive (@archives) {
	$size += $archive->size($seen);
    }
    return $size;
}

# Not an official public API at this time.
sub _has_archive_expired {
    my $self = shift;
    my $archive = shift;
    my $now = shift;

    my $max_age = $self->max_age;
    # max_age option has the format like "7d" for 7 days, "4h" for 4 hours,
    # etc. Convert this into minutes.
    my $max_age_seconds;
    if ($max_age =~ /^(\d+)d$/) {
	$max_age_seconds = $1 * 24 * 60 * 60;
    } elsif ($max_age =~ /^(\d+)h$/) {
	$max_age_seconds = $1 * 60 * 60;
    } elsif ($max_age =~ /^(\d+)m$/) {
	$max_age_seconds = $1 * 60;
    } else {
	die "max_age option, if it exists, must have form NNd (days), NNh (hours) or NNm (mins)";
    }

    my $log = Log::Log4perl->get_logger();
    $log->debug("Max age of $max_age correspond to $max_age_seconds");

    my $expires_at = $archive->created + $max_age_seconds;

    $log->debug("Archive expires at $expires_at, but we're now at $now");

    if ($expires_at < $now) {
	return 1;
    }
    return 0;
}


sub _is_archive_to_large {
    my $self = shift;
    my $size = shift;

    my $max_size = $self->max_size;
    my $max_size_bytes;
    if ($max_size =~ /^(\d+(?:\.\d+)?)GB?$/i) {
	$max_size_bytes = $1 * (1024 * 1024 * 1024);
    } elsif ($max_size =~ /^(\d+(?:\.\d+)?)MB?$/i) {
	$max_size_bytes = $1 * (1024 * 1024);
    } elsif ($max_size =~ /^(\d+(?:\.\d+)?)KB?$/i) {
	$max_size_bytes = $1 * 1024;
    } elsif ($max_size =~ /^(\d+(?:\.\d+)?)B?$/i) {
	$max_size_bytes = $1;
    } else {
	die "max_size option, if it exists, must have form NNg (gigabytes), NNm (megabytes) or NNk (kilobytes)";
    }

    if ($size > $max_size_bytes) {
	return 1;
    }
    return 0;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 PROPERTIES

The following properties each have a correspondingly named method
which supports getting & setting of the property value. The getter
is the no-arg version, while the setter is the one-argument version.
eg,

  my $age = $manager->max_age
  $manager->max_age("7d");

=over 4

=item max_age

This property controls how long an archive can exist before it is
considered invalid & thus a candidate for removal. It is represented as an
integer, followed by a unit specifier, eg '7d' for seven days, '8h' for eight
hours, or '9m' for nine minutes.

=item max_instance

This property specifies the total number of archive instances to create
before beginning to mark old archives as invalid. It is simply an integer
count.

=item max_size

This property controls the maximum storage to allow to be
consumed by all managed archives. It is represented as an integer followed
by a unit specifier, eg '1g' for 1 gigabyte, or '2m' for 2 megabytes.

=back

=head1 BUGS

Although nicely documented, the C<max_instance> and C<max_size> properties
are not currently used when determining list of invalid archives. This
ommision ought to be fixed at some point....

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004-2005 Dennis Gregorovic, Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>

=cut
