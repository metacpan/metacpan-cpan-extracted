package Solstice::State::Tracker;

# $Id: Tracker.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::State::Tracker - Tracks each users' progress through the state graph.

=head1 SYNOPSIS

  use Solstice::State::Tracker;
  my $tracker = new Solstice::State::Tracker;

  my $current_state = $tracker->getState();

  # These are passthroughs to the state machine
  $validate = $tracker->requiresValidation('transition');
  $revert = $tracker->requiresRevert('transition');
  $fresh = $tracker->requiresFresh('transition');
  $commit = $tracker->requiresCommit('transition');
  $update = $tracker->requiresUpdate('transition');

  if (! $tracker->transition('transition')) {
    die "Couldn't make a transition";
  }

  my $controller_name = $tracker->getController();

=head1 DESCRIPTION

This tracks the way a user moves through a Solstice tool.  It
seperates the state data from the movement through it, to help save
some memory/cpu in the generation/storing of the state table.  This is
also the model for the navigation view.

=cut

use 5.006_000;
use strict;
use warnings;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

use Solstice::State::Machine;
use Solstice::ProcessService;

use constant TRUE => 1;
use constant FALSE => 0;

=head2 Methods

=over 4

=cut


=item new()

Constructor for a new State::Tracker object.  You are not in a state
yet until you call startApplication.

=cut

sub new {
    my ($obj) = @_;
    my $self = bless {}, $obj;

    $self->{_flowStack} = [];

    $self->{_lastBackError} = undef;

    return $self;
}


=item startApplication($pageFlowName, $state)

Pushes a new flow and state onto the stack.  Use this when you need to
set the user's position to a particular flow/state (like when they type
in a URL).

=cut

sub startApplication {
    my ($self, $pageflow_name, $state) = @_;

    push @{$self->{_flowStack}}, [$pageflow_name, $state];
}


sub getGlobalTransition {
    my $self = shift;
    my $action = shift;
    my $namespace = shift;

    my $machine = Solstice::State::Machine->new();

    my $transition = $machine->getGlobalTransition($action, $namespace);
    
    return $transition;
    
}

sub getPageFlowGlobalTransition {
    my $self = shift;
    my $action = shift;
    my $namespace = shift;

    my $machine = Solstice::State::Machine->new();

    my $transition = $machine->getPageFlowGlobalTransition($action, $namespace, $self->_getFlow());

    return $transition;
}


sub clearPageFlowStack {
    my $self = shift;
    $self->{_flowStack} = [];
}
=item transition($action)

Transitions to the next state given the action.

returns - the next state name; undef if invalid.

=cut

sub transition {
    my ($self, $action) = @_;

    my $machine = new Solstice::State::Machine();
    my $process_service = Solstice::ProcessService->new();

    # update the back error message if necessary
    unless ($machine->canUseBackButton($self->_getFlow(),
                                       $self->getState(),
                                       $action)) {
        $self->{_lastBackError} =
          $machine->getBackErrorMessage($self->_getFlow(),
                                        $self->getState(),
                                        $action);
    }

    my ($do_pop, $new_flow, $new_state) =
      $machine->transition($self->_getFlow(),
                           $self->getState(), $action);

    
    if (defined $new_flow) {
        $process_service->setIsPageFlowEntrance(TRUE);
    }
    if ($new_state =~ /::__exit__$/) {
        $process_service->setIsPageFlowExit(TRUE);
    }

    if ($do_pop) {
        pop @{$self->{_flowStack}};
    } elsif (defined $new_flow) {
        push @{$self->{_flowStack}}, [$new_flow, $new_state];
    } else {
        $self->_setState($new_state);
    }

    return $self->getState();
}



=item getController($app)

Returns the controller for the current state.

=cut

sub getController {
    my ($self, $app) = @_;
    return unless $self->getState();
    my $machine = new Solstice::State::Machine();
    return $machine->getController($self->getState(), $app);
}


=item getState()

Returns the name of the current state.

=cut

sub getState {
    my $self = shift;

    die 'Attempting to use a State::Tracker without calling startApplication()\n' if !$self->{_flowStack};
    return FALSE unless scalar @{$self->{_flowStack}};

    return $self->{_flowStack}->[(scalar @{$self->{_flowStack}}) - 1]->[1];
}


=item setState()

Sets the current state.

=cut

sub _setState {
    my ($self, $state) = @_;
    $self->{_flowStack}->[(scalar @{$self->{_flowStack}}) - 1]->[1] = $state;
}

=item canUseBackButton($action)

Returns whether the user should be able to use the back button after
this transition.

=cut

sub canUseBackButton {
    my ($self, $action) = @_;
    my $machine = new Solstice::State::Machine();
    return $machine->canUseBackButton($self->_getFlow(),
                                      $self->getState(),
                                      $action);
}


=item getBackErrorMessage()

Returns the error message a user should receive if the back button is
used but not allowed.

=cut

sub getBackErrorMessage {
    my ($self) = @_;
    return $self->{_lastBackError};
}


=item requires*($action)

Returns whether we have to run lifecycle stages

=cut

sub requiresValidation {
    my ($self, $action) = @_;
    my $machine = new Solstice::State::Machine();
    return $machine->requiresValidation($self->_getFlow(),
                                        $self->getState(),
                                        $action);
}

sub requiresRevert {
    my ($self, $action) = @_;
    my $machine = new Solstice::State::Machine();
    return $machine->requiresRevert($self->_getFlow(),
                                    $self->getState(),
                                    $action);
}

sub requiresFresh {
    my ($self, $action) = @_;
    my $machine = new Solstice::State::Machine();
    return $machine->requiresFresh($self->_getFlow(),
                                   $self->getState(),
                                   $action);
}

sub requiresCommit {
    my ($self, $action) = @_;
    my $machine = new Solstice::State::Machine();
    return $machine->requiresCommit($self->_getFlow(),
                                    $self->getState(),
                                    $action);
}

sub requiresUpdate {
    my ($self, $action) = @_;
    my $machine = new Solstice::State::Machine();
    return $machine->requiresUpdate($self->_getFlow(),
                                    $self->getState(),
                                    $action);
}

sub getTransition {
    my ($self, $action) = @_;
    my $machine = new Solstice::State::Machine();
    return $machine->getTransition($self->_getFlow(),
        $self->getState(),
        $action);
}
    
=item fail*()

Transitions to the failover state for the corresponding lifecycle
stage.

returns - the controller for the new state.

=cut

sub failValidation {
    my ($self, $app) = @_;

    my $machine = new Solstice::State::Machine();

    my $state =
      $machine->getValidationFailoverState($self->_getFlow(),
                                           $self->getState());

    if (!$state) {
        return; # don't transition
    }

    $self->_setState($state);
    return $machine->getController($self->getState(), $app);
}

sub failRevert {
    my ($self, $app) = @_;

    my $machine = new Solstice::State::Machine();

    my $state =
      $machine->getRevertFailoverState($self->_getFlow(),
                                       $self->getState());

    die "revert failed for state: '".$self->getState()."' controller: '".$machine->getControllerName($self->getState())."' and no failover was defined.\n" unless $state;

    $self->_setState($state);
    return $machine->getController($self->getState(), $app);
}

sub failCommit {
    my ($self, $app) = @_;

    my $machine = new Solstice::State::Machine();

    my $state =
      $machine->getCommitFailoverState($self->_getFlow(),
                                       $self->getState());

    die "commit failed for state: '".$self->getState()."' controller: '".$machine->getControllerName($self->getState())."' and no failover was defined.\n" unless $state;

    $self->_setState($state);
    return $machine->getController($self->getState(), $app);
}

sub failUpdate {
    my ($self, $app) = @_;

    my $machine = new Solstice::State::Machine();

    my $state =
      $machine->getUpdateFailoverState($self->_getFlow(),
                                       $self->getState());

    die "update failed for state: '".$self->getState()."' controller: '".$machine->getControllerName($self->getState())."' and no failover was defined.\n" unless $state;

    $self->_setState($state);
    return $machine->getController($self->getState(), $app);
}

sub failValidPreConditions {
    my ($self, $app ) = @_;

    my $machine = new Solstice::State::Machine();

    my $state =
      $machine->getValidPreConditionsFailoverState($self->_getFlow(),
                                                   $self->getState());

    die "validPreConditions failed for state: '".$self->getState()."' controller: '".$machine->getControllerName($self->getState())."' and no failover was defined.\n" unless $state;

    $self->_setState($state);
    return $machine->getController($self->getState(), $app);
}

sub failFreshen {
    my ($self) = @_;

    my $machine = new Solstice::State::Machine();

    my $state =
      $machine->getFreshenFailoverState($self->_getFlow(),
                                                 $self->getState());

    die "freshen failed for state: '".$self->getState()."' controller: '".$machine->getControllerName($self->getState())."' and no failover was defined.\n" unless $state;

    $self->_setState($state);
}


=item getUpdateFailoverController()

Nontransitioning version of failUpdate()

=cut

sub getUpdateFailoverController {
    my ($self, $app) = @_;

    my $machine = new Solstice::State::Machine();

    my $state =
      $machine->getUpdateFailoverState($self->_getFlow(),
                                       $self->getState());

    die "No update failover for '".$self->getState()."'\n" unless $state;

    return $machine->getController($state, $app);
}


=item getValidPreConditionsFailoverController()

Nontransitioning version of failValidPreConditions()

=cut

sub getValidPreConditionsFailoverController {
    my ($self, $action, $app) = @_;

    my $machine = new Solstice::State::Machine();

    my $state =
      $machine->transition($self->_getFlow(),
                           $self->getState(),
                           $action);

    my $failover =
      $machine->getValidPreConditionsFailoverState($self->_getFlow(),
                                                   $state);

    die "No validPreConditions failover for '".$state."'\n" unless $failover;

    return $machine->getController($failover, $app);
}


=item getFlow()

Returns the current page flow.

=cut

sub _getFlow {
    my ($self) = @_;

    if (!@{$self->{_flowStack}}) {
        die "Attempting to use a State::Tracker without calling startApplication()\n";
    }

    # just look at the top of the flow stack.  simple, isn't it?
    return $self->{_flowStack}->[(scalar @{$self->{_flowStack}}) - 1]->[0];
}


1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



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
