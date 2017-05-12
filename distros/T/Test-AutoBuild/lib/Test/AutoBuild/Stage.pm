# -*- perl -*-
#
# Test::AutoBuild::Stage
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

Test::AutoBuild::Stage - The base class for an AutoBuild stage

=head1 SYNOPSIS

  use Test::AutoBuild::Stage

  my $stage = Test::AutoBuild::Stage->new(name => $token,
					  label => $string,
					  [critical => $boolean,]
					  [enabled => $boolean]);

  # Execute the stage
  $stage->run($runtime);


  if ($stage->aborted()) {         # Very badly wrong
    die $stage->log();
  } elsif ($stage->failed()) {   # Expected failure
    if ($stage->is_critical()) { # Non-recoverable
      .. do failure case ...
    } else {
      .. do recovery case ...
    }
  } elsif ($stage->success() ||  # Everything's ok
	   $stage->skipped()) {
    .. do normal case ...
  }


=head1 DESCRIPTION

This module is an abstract base class for all AutoBuild
stages. If defines a handful of common methods and the
abstract method C<process> to be implemented by sub-classes
to provide whatever custom processing is required.

=head2 STATUS

The status of a stage starts off as 'pending', and when
the C<run> method is invoked, the status will changed to
one of the following:

=over 4

=item success

If the stage completed its processing without encountering
any problems. Stages will automatically have their status
set to this value if their C<process> method completes without
the C<fail> method having been called.

=item failed

If the stage completed its processing, but encountered
and handled one or more problems. Such problems may include
failure of a module build, failure of a test suite. Upon
encountering such an problem, the stage should call the
C<fail> method providing a description of the problem, and
then return from the C<process> method.

=item aborted

If the stage died as a result of an error during processing.
Stages should simply call the C<die> method to abort processing.
NB, the C<confess> method should not be used to abort since,
autobuilder will automatically hook C<confess> into the perl
SIG{__DIE__} handler.

=item skipped

If the stage was not executed due to the C<is_enabled> flag
being set to false.

=back

=head1 CONFIGURATION

All stage modules have a number of standard configuration
options that are used. Sub-classes are not permitted to
define additional configuration parameters, rather, they
should use the C<options> parameter for their custom configuration
needs.

=over 4

=item name

A short alpha-numeric token representing the stage, typically
based on the last component of the name of the stage module

=item label

An arbitrary string describing the purpose of the stage, suitable
for presenting to users through email alerts, or HTML status pages.

=item enabled

A boolean flag indicating whether the stage is to be executed, or
skipped.

=item critical

A boolean flag indicating whether failure of a stage should be
considered fatal to the build process. NB, if a stage aborts,
it is always considered fatal, regardless of this flag.

=item options

A hash containing options specific to the particular stage sub-class.

=back

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage;

use strict;
use warnings;
use Carp qw(confess);
use Class::MethodMaker
    new_with_init => 'new',
    get_set => [qw( name label start_time end_time status log is_critical is_enabled )];
use Data::Dumper;
use Log::Log4perl;
use Test::AutoBuild::Result;

=item my $stage = Test::AutoBuild::Stage->new(name => $name,
					      label => $label,
					      [critical => $boolean,]
					      [enabled => $boolean,]
					      [options => \%options]);

Creates a new stage, with a name specified by the C<name> parameter
and label by the C<label> parameter. The optional C<critical> parameter
can be used to change the behaviour of stages upon failure, if omitted,
will default to C<true>. The optional C<enabled> parameter can be used
to disable execution of the stage, if omitted, will default to C<true>.
Finally, the C<options> parameter can be used to specify sub-class
specific options.

=item $stage->init(%params);

A method to initialize the stage called automatically by the
C<run> method, so see the docs for that method for details of
the keys accepted in the C<%params> parameter.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    exists $params{name} ?
	$self->name($params{name}) :
	confess "name parameter is required";
    exists $params{label} ?
	$self->label($params{label}) :
	confess "label parameter is required";
    exists $params{critical} ?
	$self->is_critical($params{critical}) :
	$self->is_critical(1);
    exists $params{enabled} ?
	$self->is_enabled($params{enabled}) :
	$self->is_enabled(1);
    $self->{options} = exists $params{options} ? $params{options} : {};

    $self->status("pending");

    $self->{results} = {};
}


=item my $boolean = $stage->pending();

Returns a true value if the stage is still pending
execution.

=cut

sub pending {
    my $self = shift;
    return $self->status() eq "pending";
}

=item my $boolean = $stage->failed();

Returns a true value if the stage encountered one or
more problems during execution. To mark a stage as
failed, use the C<fail> method supplying a explanation
of the failure.

=cut

sub failed {
    my $self = shift;
    return $self->status() eq "failed";
}

=item my $boolean = $stage->succeeded();

Returns a true value if the stage completed execution
without encountering any problems

=cut

sub succeeded {
    my $self = shift;
    return $self->status() eq "success";
}

=item my $boolean = $stage->skipped();

Returns a true value if the stage was skipped, due to
the C<is_enabled> flag being disabled.

=cut

sub skipped {
    my $self = shift;
    return $self->status() eq "skipped";
}

=item my $boolean = $stage->aborted();

Returns a true value if the stage aborted, due to the
C<process> method calling C<die>.

=cut

sub aborted {
    my $self = shift;
    return $self->status() eq "aborted";
}


=item my $seconds = $stage->duration();

Returns the duration of the stage execution, rounded
to the nearest second.

=cut

sub duration {
    my $self = shift;
    return $self->end_time - $self->start_time;
}

=item $stage->fail($message);

Marks the stage as failing, providing an explanation
with the C<$message> parameter. Should be called from
the C<process> method if an expected error condition
arises.

=cut

sub fail {
    my $self = shift;
    my $message = shift;
    $self->log($message);
    $self->status("failed");
}

=item $value = $stage->option($name[, $newvalue]);

Retrieves the subclass specific configuration
option specified by the C<$name> parameter. If the
C<$newvalue> parameter is supplied, then the configuration
option is updated.

=cut

sub option {
   my $self = shift;
   my $name = shift;

   $self->{options}->{$name} = shift if @_;

   return $self->{options}->{$name};
}

sub prepare {
    my $self = shift;
    my $runtime = shift;
    my $context = shift;

    my $result = defined $context ?
	Test::AutoBuild::Result->new(name => $self->name . " [$context] ",
				     label => $self->label . " [" . $runtime->module($context)->label . "]") :
	Test::AutoBuild::Result->new(name => $self->name,
				     label => $self->label);

    my $key = defined $context ? $self->name . "." . $context : $self->name;

    $self->{results}->{$key} = $result;
    return $result;
}


=item $stage->run($runtime);

Executes the stage, recording the start and end time,
and updating the stage status to reflect the result of
its execution. The C<$runtime> parameter should be an
instance of the L<Test::AutoBuild::Runtime> module.

=cut

sub run {
    my $self = shift;
    my $runtime = shift;
    my $context = shift;

    $self->start_time(time);

    if ($self->is_enabled()) {
	$runtime->notify("beginStage", $self->name, time);
	eval {
	    $self->status("success");
	    $self->process($runtime, $context);

	    if ($self->failed) {
		$runtime->notify("failStage", $self->name, time, $self->is_critical ? "critical": "recoverable", $self->log);
	    } else {
		$runtime->notify("completeStage", $self->name, time);
	    }
	};
	if ($@) {
	    my $message = $@;
	    $self->log($message);
	    $self->status("aborted");
	    $runtime->notify("abortStage", $self->name, time, $message);
	}
    } else {
	$self->status("skipped");
	$runtime->notify("skipStage", $self->name, time);
    }

    $self->end_time(time);

    my $key = defined $context ? $self->name . "." . $context : $self->name;
    my $result = $self->{results}->{$key};
    if ($result) {
	$result->status($self->status);
	$result->log($self->log);
	$result->start_time($self->start_time);
	$result->end_time($self->end_time);
    }
}


=item $stage->process($runtime);

This method should be implemented by subclasses to provide
whatever processing logic is required. The C<$runtime> parameter
should be an instance of the L<Test::AutoBuild::Runtime> module.
The C<process> method should call the C<fail> method is an
expected error occurrs, otherwise it should simply call C<die>.

=cut

sub process {
    my $self = shift;

    confess "class " . ref($self) . " forgot to implement the process method";
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004 Red Hat, Inc.

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>

=cut
