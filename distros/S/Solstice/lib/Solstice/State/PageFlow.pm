package Solstice::State::PageFlow;

=head1 NAME

Solstice::State::PageFlow - Represents a set of transitions that flow a user through a graph of Solstice::State::Node objects.

=head1 SYNOPSIS

use Solstice::State::PageFlow;

my $transition = new Solstice::State::PageFlow($appName,
                                               $flowName,
                                               $entrance);

$pageFlow->addTransition($transition);

=cut


use 5.006_000;
use strict;
use warnings;


=head2 Methods

=over 4

=cut


=item new($appName, $flowName, $entrance)

Creates a new Solstice::State::PageFlow object.

$appName - the name of the application.
$flowName - the name of the page flow.
$entrance - the entrance state of the flow.

returns - a new page flow object.

=cut

sub new {
    my ($classname, $app_name, $flow_name, $entrance) = @_;

    my $self = bless {}, $classname;
    $self->{_appName} = $app_name;
    $self->{_name} = $flow_name;
    $self->{_entrance} = $entrance;

    return $self;
}


=item addFailover($startState, $stage, $failoverState)

Adds a failover state to go to when stage $stage fails.

=cut

sub addFailover {
    my ($self, $start_state, $stage, $failover_state) = @_;

    $self->{_failovers}->{$start_state}->{$stage} = $failover_state;
}


=item getFailover($startState, $stage)

Gets the name of the state to fail over to given the lifecycle stage.

=cut

sub getFailover {
    my ($self, $start_state, $stage) = @_;

    return $self->{_failovers}->{$start_state}->{$stage};
}


=item getName()

Returns the name of the page flow.

=cut

sub getName {
    my ($self) = @_;
    return $self->{_name};
}


=item getApplicationName()

Returns the name of the application this flow belongs to.

=cut

sub getApplicationName {
    my ($self) = @_;
    return $self->{_appName};
}


=item getEntrance()

Returns the name of the entrance state

=cut

sub getEntrance {
    my ($self) = @_;
    return $self->{_entrance};
}


=item addTransition($transition)

Adds a transition to the page flow.

$startState - the state name that the transition begins at.
$transition - the Solstice::State::Transition object to add.

=cut

sub addTransition {
    my ($self, $start_state, $transition) = @_;
    $self->{_transitions}->{$start_state}->{$transition->getName()} =
      $transition;
}


=item getTransition($state, $action)

Returns the transition from state via action.

=cut

sub getTransition {
    my ($self, $state, $action) = @_;
    return $self->{_transitions}->{$state}->{$action};
}


=item getTransitions()

Returns a hash of hashes of transitions keyed by their start state and
action.

=cut

sub getTransitions {
    my ($self) = @_;
    return $self->{_transitions} || {};
}


1;

=back

=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
