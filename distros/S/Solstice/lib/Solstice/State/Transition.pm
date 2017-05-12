package Solstice::State::Transition;

=head1 NAME

Solstice::State::Transition - Representation of the transition between Solstice::State objects.

=head1 SYNOPSIS

use Solstice::State::Transition;

my $transition = new Solstice::State::Transition(
  $action, $targetState, $pageflow, {update => $update,
                                    revert => $revert,
                                    freshen => $freshen,
                                    commit => $commit,
                                    validate => $validate});

$pageFlow->addTransition($transition);

=cut


use 5.006_000;
use strict;
use warnings;


=head2 Methods

=over 4

=cut



=item new ($action, $targetState, $onBack, $pageflow, {update => $update,
                                                        revert => $revert,
                                                        freshen => $freshen,
                                                        commit => $commit,
                                                        validate => $validate})

Creates a new Solstice::State::Transition object.

$action - the keyword on which to transition.
$targetState - the name of the state to transition to.
$onBack - the error message for using the back button (undef if allowed).
$pageflow - global transtions can specify what page flow they will start in
$update - whether to update on transition.
$revert - whether to revert on transition.
$freshen - whether to freshen data on transition.
$commit - whether to commit data on transition.
$validate - whether to validate on transition.

returns - a new state transition object.

=cut

sub new {
    my ($classname, $action, $target_state, $on_back, $pageflow, $operations) = @_;

    my $self = bless {}, $classname;
    $self->{_action} = $action;
    $self->{_targetState} = $target_state;
    $self->{_onBack} = $on_back;
    $self->{_pageflow} = $pageflow;
    $self->{_update} = $operations->{update} || 0;
    $self->{_revert} = $operations->{revert} || 0;
    $self->{_freshen} = $operations->{freshen} || 0;
    $self->{_commit} = $operations->{commit} || 0;
    $self->{_validate} = $operations->{validate} || 0;

    return $self;
}


=item getName()

returns - the name of the transition (the action)

=cut

sub getName {
    my ($self) = @_;
    return $self->{_action};
}

sub getTargetPageFlow {
    my $self = shift;
    return $self->{'_pageflow'};
}
=item getTargetState()

returns - the name of the state to transition to.

=cut

sub getTargetState {
    my ($self) = @_;
    return $self->{_targetState};
}


=item getBackErrorMessage()

returns - the error message for using the back button (undef if allowed).

=cut

sub getBackErrorMessage {
    my ($self) = @_;
    return $self->{_onBack};
}


=item requiresUpdate()

returns - whether the transition requires an update.

=cut

sub requiresUpdate {
    my ($self) = @_;
    return $self->{_update};
}


=item requiresRevert()

returns - whether the transition requires a revert.

=cut

sub requiresRevert {
    my ($self) = @_;
    return $self->{_revert};
}

=item requiresFresh()

returns - whether the transition requires a freshen.

=cut

sub requiresFresh {
    my ($self) = @_;
    return $self->{_freshen};
}

=item requiresCommit()

returns - whether the transition requires a commit.

=cut

sub requiresCommit {
    my ($self) = @_;
    return $self->{_commit};
}

=item requiresValidation()

returns - whether the transition requires a validation.

=cut

sub requiresValidation {
    my ($self) = @_;
    return $self->{_validate};
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
