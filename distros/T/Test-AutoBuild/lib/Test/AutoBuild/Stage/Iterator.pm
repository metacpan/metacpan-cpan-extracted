# -*- perl -*-
#
# Test::AutoBuild::Stage::Iterator
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

Test::AutoBuild::Stage::Iterator - Run a set of stages for each module

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::Iterator


=head1 DESCRIPTION

This stage iterates over the (ordered) list of modules, running a
set of sub-stages against each one. The current module being passed
into the C<run> method of each stage. If the sub-stages are iterator-aware
this enables a configuration to be setup to generate incremental HTML
status pages during the course of the build cycle.

=head1 CONFIGURATION

In addition to the standard parameters defined by the L<Test::AutoBuild::Stage>
module, this module also handles the optional C<stages> parameter to specify
a list of sub-stages. Sub-stages are listed in the same format as top level
stages, ie an array of hashes.

=head2 EXAMPLE

  {
    name = build
    label = Build iterator
    module = Test::AutoBuild::Stage::Iterator
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
      # Status pages
      {
	name = html
	label = HTML status pages
	module = Test::AutoBuild::Stage::HTMLStatus
	options = {
	  ...snip status options...
	}
      }
    )
  }

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::Iterator;

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

    $self->SUPER::init(@_);

    $self->{stages} = exists $params{stages} ? $params{stages} : [];
    $self->{module_results} = {};
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

    die "cannot nest iterators" if defined $context;


    my $result = $self->SUPER::prepare($runtime, $context);

    my @ordered_modules = $runtime->sorted_modules();
    foreach my $name (@ordered_modules) {
	my $modres = Test::AutoBuild::Result->new(name => $self->name . " [$name]",
						  label => $self->label . " [" . $runtime->module($name)->label . "]");
	$result->add_result($modres);
	$self->{module_results}->{$name} = $modres;

	foreach my $stage ($self->stages) {
	    my $subres = $stage->prepare($runtime, $name);
	    $modres->add_result($subres);
	}
    }
    return $result;
}


=item $stage->process($runtime);

Iterates over all modules (in depenedancy sorted order), for each module,
running the set of configured sub-stages. The sub-stages will have the
name of the current module passed in as the second parameter to the
C<run> method. If any sub-stages fails & that stage is marked as critical,
this stage will be marked as failing and return control immediately. If
the sub-stage is non-critical, then the iterator will continue processing.

=cut

sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();
    my @ordered_modules = $runtime->sorted_modules();

    if ($log->is_debug()) {
	$log->debug("Iterator module order: " . join("\n  ", @ordered_modules) . "\nEnd");
    }

    foreach my $name (@ordered_modules) {
	my $failed = 0;
	my $start = time;
	foreach my $stage (@{$self->{stages}}) {
	    $stage->run($runtime, $name);
	    if ($stage->aborted()) {
		die $stage->log;
	    } elsif ($stage->failed()) {
		if ($stage->is_critical()) {
		    $self->fail("stage " . $stage->name() . " " . $stage->log());
		    return;
		} else {
		    $failed = 1;
		}
	    }
	}
	my $modres = $self->{module_results}->{$name};
	$modres->status($failed ? "failed" : "success");
	$modres->log($failed ? "one or more stages failed" : "");
	$modres->start_time($start);
	$modres->end_time(time);
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
