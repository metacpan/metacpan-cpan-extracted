package Solstice::State::FlowTransition;

=head1 NAME

Solstice::State::FlowTransition - Representation of the transition to a new page flow.

=head1 SYNOPSIS

use Solstice::State::FlowTransition;

my $transition = new Solstice::State::FlowTransition($action,
  $application, $name, $onBack, {update => $update,
                                                  revert => $revert,
                                                  freshen => $freshen,
                                                  validate => $validate,
                                                  commit => $commit});

$pageFlow->addTransition($transition);

=cut


use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::State::Transition);


=head2 Methods

=over 4

=cut


=item new($action, $appName, $name, $onBack,
                                  {update => $update,
                                   revert => $revert,
                                   freshen => $freshen,
                                   commit => $commit,
                                   validate => $validate})

Creates a new Solstice::State::FlowTransition object.

$action - the keyword on which to transition.
$appName - the name of the application that owns the new flow.
$name - the name of the flow to transition to.
$onBack - the error message if the back button is used (undef if allowed).
$update - whether to update on transition.
$revert - whether to revert on transition.
$freshen - whether to freshen data on transition.
$commit - whether to commit data on transition.
$validate - whether to validate on transition.

returns - a new flow transition object.

=cut

sub new {
    my ($classname, $action, $app_name, $flow_name,
        $on_back, $operations) = @_;

    my $self = $classname->SUPER::new($action, undef, $on_back,undef, $operations);
    $self->{_appName} = $app_name;
    $self->{_flowName} = $flow_name;

    return $self;
}


=item getApplicationName()

Returns the name of the application that owns the flow that this
transition goes to.

=cut

sub getApplicationName {
    my ($self) = @_;
    return $self->{_appName};
}

=item getPageFlowName()

Returns the name of the page flow this transitions to.

=cut

sub getPageFlowName {
    my ($self) = @_;
    return $self->{_flowName};
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
