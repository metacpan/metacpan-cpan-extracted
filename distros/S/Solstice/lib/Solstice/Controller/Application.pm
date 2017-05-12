package Solstice::Controller::Application;

# $Id: Application.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::Controller::Application - The super class for all application controllers.

=head1 SYNOPSIS

  use Solstice::Controller::Application;
  our @ISA = qw(Solstice::Controller::Application);

=head1 DESCRIPTION

Has the stub functions that all application controllers need.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Controller);

use Carp qw(confess);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Controller|Solstice::Controller>,

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new($application)

Constructor.

=cut

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

=item getController()

Returns the controller currently set for a subclass.

=cut

sub getController {
    my $self = shift;
    return $self->{'_controller'};
}

=item setController($controller)

This function is for subclasses, so they can tell us which controller to use.

=cut

sub setController {
    my $self = shift;
    $self->{'_controller'} = shift;
}

=item validate()

Validates user input from the previous screen.

=cut

sub validate {
    my $self = shift;
    
    unless (defined $self->getController()) {
        confess "validate(): Controller not defined";
    }
    
    return $self->getController()->validate();
}

=item update()

=cut

sub update {
    my $self = shift;
    
    unless (defined $self->getController()) {
        confess "update(): Controller not defined";
    }
    
    return $self->getController()->update();
}

=item revert()

=cut

sub revert {
    my $self = shift;
    
    unless (defined $self->getController()) {
        confess "revert(): Controller not defined";
    }
    
    return $self->getController()->revert();
}

=item commit()

Does any action of the controller after validation, such as saving objects or deleting them.

=cut

sub commit {
    my $self = shift;
    
    unless (defined $self->getController()) {
        confess "commit(): Controller not defined";
    }
    
    return $self->getController()->commit();
}

=item validPreConditions()

Makes sure the controller knows everything it needs to in order to create the
next view.

=cut

sub validPreConditions {
    my $self = shift;
    
    unless (defined $self->getController()) {
        confess "validPreConditions(): Controller not defined";
    }
    
    return $self->getController()->validPreConditions();
}

sub initialize {
    my $self = shift;

    unless (defined $self->getController()) {
        confess "initialize(): Controller not defined";
    }

    return $self->getController()->initialize();
}

=item finalize()

Allows conrollers to clean up any resource they need to right before the click lifecycle is over

=cut

sub finalize {
    my $self = shift;
    
    unless (defined $self->getController()) {
        confess "finalize(): Controller not defined"; 
    }
    
    return $self->getController()->finalize();
}

=item getView()

Returns the view of the summary.

=cut

sub getView {
    my $self = shift;
    
    unless (defined $self->getController()) {
        confess "getView(): Controller not defined"; 
    }
    
    return $self->getController()->getView();
}

=item setInputName()

=cut

sub setInputName {
    my $self = shift;

    unless (defined $self->getController()) {
        confess "setInputName(): Controller not defined";
    }

    return $self->getController()->setInputName(@_);
}

=item setOutputName()

=cut

sub setOutputName {
    my $self = shift;

    unless (defined $self->getController()) {
        confess "setOutputName(): Controller not defined";
    }
    
    return $self->getController()->setOutputName(@_);
}

=item setRequiresAuth($boolean)

=cut

sub setRequiresAuth {
    my $self = shift;
    $self->{'_requires_auth'} = shift;
}

=item getRequiresAuth()

=cut

sub getRequiresAuth {
    my $self = shift;
    return $self->{'_requires_auth'} || FALSE;
}

=item getBookmarkState()

=cut

sub getBookmarkState {

}

=item getBookmarkID()

=cut

sub getBookmarkID {

}

=item getBookmarkLabel()

=cut

sub getBookmarkLabel {

}

=item setBookmarkID($id)

=cut

sub setBookmarkID {
    warn "setBookmarkID should really be handled by the application controller.";
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::Controller|Solstice::Controller>,
L<HTTP::BrowserDetect|HTTP::BrowserDetect>.

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
