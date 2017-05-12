# -*- perl -*-
#
# Test::AutoBuild::Stage::Group
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2004 Red Hat, Inc.
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

Test::AutoBuild::Stage::Group - Groups several stages together

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::Group


=head1 DESCRIPTION

This stage groups a number of stages together into a single
logical stage. The primary reason for such a setup is to allow
one or more of the sub-stages to fail, without terminating the
entire build process. For example, by grouping the Build and
ISOGenerator stages together it is possible to have the ISOGenerator
stage skipped whenever the Build stage fails, but still have all
the post-build output stages run to generate status pages, etc.

=head1 CONFIGURATION

In addition to the standard parameters defined by the L<Test::AutoBuild::Stage>
module, this module also handles the optional C<stages> parameter to specify
a list of sub-stages. Sub-stages are listed in the same format as top level
stages, ie an array of hashes.

=head2 EXAMPLE

  {
    name = build
    label = Build group
    module = Test::AutoBuild::Stage::Group
    # Don't abort entire cycle if the module build fails
    critical = 0
    stages = (
      # Basic build
      {
	name = build
	label = Build
	module = Test::AutoBuild::Stage::Build
	options = {
	  ...snip build options...
	}
      }
      # Generate isos
      {
	name = iso
	label = ISO image generator
	module = Test::AutoBuild::Stage::ISOGenetator
	options = {
	  ...snip options...
	}
      }
    )
  }

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::Group;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use Log::Log4perl;

=item $stage->init(%params);

Overrides the super-class to add in handling of the optional C<stages>
parameter for defining sub-stages. It is not neccessary to call this
method, since it is called by the C<new> method automatically.

=cut

sub init {
    my $self = shift;
    my %params = @_;
    my $log = Log::Log4perl->get_logger();

    $self->SUPER::init(@_);

    $self->{stages} = exists $params{stages} ? $params{stages} : [];
}

=item my @stages = $stage->stages();

Retrieves the list of sub-stages that belong to this group. The
elements in the array are instances of L<Test::AutoBuild::Stage>
module.

=cut

sub stages {
    my $self = shift;
    return @{$self->{stages}};
}

sub add_stage {
    my $self = shift;
    my $stage = shift;
    push @{$self->{stages}}, $stage;
}


sub prepare {
    my $self = shift;
    my $runtime = shift;
    my $context = shift;

    my $result = $self->SUPER::prepare($runtime, $context);

    foreach my $stage ($self->stages) {
	my $subres = $stage->prepare($runtime, $context);
	$result->add_result($subres);
    }
    return $result;
}

=item $stage->process($runtime);

Runs all sub-stages returned by the C<stages> method. If any sub-stages
fails & that stage is marked as critical, this stage will be marked as
failing and return control immediately. If the sub-stage is non-critical,
then the processing will continue onto the next sub-stage.

=cut

sub process {
    my $self = shift;
    my $runtime = shift;
    my @args = @_;

    my $log = Log::Log4perl->get_logger();
    foreach my $stage ($self->stages) {
	$stage->run($runtime, @args);
	if ($stage->aborted()) {
	    die $stage->log;
	} elsif ($stage->failed() && $stage->is_critical()) {
	    $self->fail("stage " . $stage->name() . " " . $stage->log());
	    last;
	}
    }
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004 Red Hat, Inc.

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>

=cut
