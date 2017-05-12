# -*- perl -*-
#
# Test::AutoBuild::Platform
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2005 Daniel Berrange
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

Test::AutoBuild::Platform - represents a build host's environment

=head1 SYNOPSIS

  use Test::AutoBuild::Platform;

  # Create a new platform based on the host machine's native
  # environment
  my $platform = Test::AutoBuild::Platform->new(name => "host");


  # Or create a platform describing a chroot environment which
  # has a differing OS, but same architecture
  my $platform = Test::AutoBuild::Platform->new(name => "host",
						label => "Fedora Core 3");

  # Or create a platform describing an emulated OS
  my $platform = Test::AutoBuild::Platform->new(name => "host",
						label => "Free BSD",
						operating_system => "bsd",
						architecture => "x86_64");

  # Create a platform describing the host, with some 'interesting'
  # extra metadata about the toolchain
  my $platform = Test::AutoBuild::Platform->new(name => "host",
						options => {
	  'compiler.cc' => "GCC 3.2.3",
	  'compiler.c++' => "G++ 3.2.3",
	  'linker' => "GNU LD 2.15",
	});

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Platform;

use warnings;
use strict;
use Log::Log4perl;

use File::Spec::Functions qw(catfile rootdir);
use POSIX qw(uname);

use Class::MethodMaker
  get_set => [qw(
		name
		label
		architecture
		operating_system
		 )];

=item my $stage = Test::AutoBuild::Platform->new(name => $name,
						 [label => $label,]);
						 [architecture => $arch,]);
						 [operating_system => $os,]
						 [options => \%options]);

Creates a new platform object describing a build root environment. The C<name>
parameter is a short tag for the platform. The optional C<label> parameter is a
free text descriptive title for the platform, typically the OS distribution name.
If omitted, the first line of /etc/issue will be used. The C<architecture> parameter
is the formal machine architecture, defaulting to the 'machine' field from the
C<uname(2)> system call. The C<operating_system> parameter is the formal operating
system name, defaulting to the 'sysname' field from the C<uname(2)> system call.
The optional C<options> parameter is a hash reference containing arbitrary
deployment specific metadata about the platform.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my %params = @_;

    $self->{options} = exists $params{options} ? $params{options} : {};

    bless $self, $class;

    $self->name(exists $params{name} ? $params{name} : die "name parameter is required");
    $self->label(exists $params{label} ? $params{label} : $self->_guess_host_label());
    $self->architecture(exists $params{architecture} ? $params{architecture} : $self->_guess_architecture());
    $self->operating_system(exists $params{operating_system} ? $params{operating_system} : $self->_guess_operating_system());

    return $self;
}

sub _guess_host_label {
    my $self = shift;

    my $issue = catfile(rootdir, "etc", "issue");
    if (-f $issue) {
	open ISSUE, "<$issue"
	    or die "cannot read $issue: $!";

	# Yes there is often > 1 line in /etc/issue
	# be we only care about a short descriptive
	# label, for which the first line will be
	# sufficient
	my $line = <ISSUE>;
	close ISSUE;

	chomp $line;
	return $line;
    } else {
	my ($sysname, $nodename, $release, $version, $machine) = uname();

	return "$sysname $release $version ($machine)";
    }
}

sub _guess_architecture {
    my $self = shift;
    my ($sysname, $nodename, $release, $version, $machine) = uname();

    return $machine;
}


sub _guess_operating_system {
    my $self = shift;
    my ($sysname, $nodename, $release, $version, $machine) = uname();

    return $sysname;
}


=item $value = $platform->option($name[, $newvalue]);

Retrieves a custom option describing a custom aspect of the
build host platform, identified as interesting by the administrator.
If the C<$newvalue> parameter is supplied, then the configuration
option is updated.

=cut

sub option {
   my $self = shift;
   my $name = shift;

   $self->{options}->{$name} = shift if @_;

   return $self->{options}->{$name};
}


=item my @names = $platform->options;

Return a list of all custom options set against this platform. The
names returned can be used in calling the C<option> method to
lookup a value.

=cut

sub options {
    my $self = shift;
    return keys %{$self->{options}};
}

1; # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>

=cut
