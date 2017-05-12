package Solstice::State::Node;

=head1 NAME

Solstice::State::Node - Representation for one State node inside of a Solstice::State::Machine.

=head1 SYNOPSIS

use Solstice::State::Node;

my $state = new Solstice::State::Node($stateName, $controller);
$state->getController();

=cut


use 5.006_000;
use strict;
use warnings;

=head2 Methods

=over 4

=cut


=item new($stateName, $controller)

Creates a new Solstice::State::Node object.

$stateName - the name of the state
$controller - the name of the controller class

returns - a new state object.

=cut

sub new {
    my ($classname, $state_name, $controller) = @_;

    my $self = bless {}, $classname;
    $self->{_name} = $state_name;
    $self->{_controller} = $controller;

    return $self;
}


=item getName()

returns - the name of the state

=cut

sub getName {
    my ($self) = @_;
    return $self->{_name};
}


=item getController()

returns - the name of the controller

=cut

sub getController {
    my ($self) = @_;
    return $self->{_controller};
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
