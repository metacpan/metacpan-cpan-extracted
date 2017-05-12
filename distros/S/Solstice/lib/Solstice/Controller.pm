package Solstice::Controller;

# $Id: Controller.pm 3365 2006-05-05 07:52:21Z pmichaud $

=head1 NAME

Solstice::Controller - A virtual superclass for constructing Solstice controllers.

=head1 SYNOPSIS

  package MyApp::Controller;

  use Solstice::Controller;

  our @ISA = qw(Solstice::Controller);

=head1 DESCRIPTION

This is a virtual class for creating Solstice controller classes.  This class
should never be instantiated as an object, rather, it should always be
sub-classed.  This particular implementation uses L<Solstice::CGI> to handle events
by the user. 

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::CGI;
use Solstice::CGI::FormError;

use Solstice::Service;
use Solstice::LogService;
use Solstice::UserService;
use Solstice::NavigationService;
use Solstice::IconService;

use Solstice::ValidationParam;

use Data::FormValidator;

use Solstice::Controller::FormInput::DateTime;
use Solstice::Controller::FormInput::DateTime::YahooUI;
use Solstice::Controller::FormInput::TextArea;

use constant TRUE  => 1;
use constant FALSE => 0;
use constant GLOBAL_FORM_ERROR_KEY => 'form_error';

our ($VERSION) = ('$Revision: 3365 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::Controller object.  

=cut

sub new {
    my $class = shift;
    my $model = shift;

    my $self = $class->SUPER::new(@_);
    $self->setModel($model) if defined $model;
    $self->{'_constraints'} = [];
    $self->{'_group_dependencies'} = [];

    return $self;
}

=item build 

=cut

sub build {
    return TRUE;
}

sub initialize {
    return TRUE;
}

sub finalize {
    return TRUE;
}

=item validPreConditions()

=cut

sub validPreConditions{
    return TRUE;
}

=item freshen()

=cut

sub freshen{
    return TRUE;
}

=item update()

=cut

sub update{
    return TRUE;
}

=item validate()

=cut

sub validate{
    return TRUE;
}

=item commit()

=cut

sub commit{
    return TRUE;
}

=item revert()

=cut

sub revert {
    return TRUE;
}

=item setModel($model)

Set the data model that this controller controls.

=cut

sub setModel {
    my $self = shift;
    $self->{'_model'} = shift;
}

=item getModel()

Get the data model that this controller controls.

=cut

sub getModel {
    my $self = shift;
    return $self->{'_model'};
}

=item setSuccessView($view)

Set the success view that this controller controls.

=cut

sub setSuccessView {
    my $self = shift;
    $self->{'_success_view'} = shift;
}

=item getStartingView()

This gets the first view that a controller produces, like the form that the controller will then manage.  Must by subclassed.

=cut

sub getStartingView {
    my $self = shift;
    return $self->{'_success_view'};
}

=item setErrorView($view)

Set the error view for this controller.

=cut

sub setErrorView {
    my $self = shift;
    $self->{'_error_view'} = shift;
}

=item getErrorView()

Get the error view for this controller.

=cut

sub getErrorView {
    my $self = shift;
    return $self->{'_error_view'};
}

=item getChildView($key)

Returns a view object for the child controller of a given key.

=cut


sub getChildView {
    my $self = shift;
    my $key = shift;

    my $controllers = $self->getChildControllers($key);
    if (defined $controllers and defined $$controllers[0]) {
        my $view = ${$controllers}[0]->getView();
        $view->setError($controllers->[0]->getError());
        return $view;
    }
    return;
}

=item getChildViews($key)

Returns an array ref of view objects for all of the child controllers of a given key.

=cut

sub getChildViews {
    my $self = shift;
    my $key = shift;

    my $controllers = $self->getChildControllers($key);
    return () unless defined $controllers;
    my @views;
    foreach (@$controllers) {
        my $view = $_->getView();
        $view->setError($_->getError());
        push @views, $view;
    }
    return \@views;
}

=item setError($error)

Sets an error object for placement into the views

=cut

sub setError {
    my $self = shift;
    $self->{'_error'} = shift;
}

=item getError()

Gets the error object for this controller.

=cut

sub getError {
    my $self = shift;
    return $self->{'_error'};
}

=item getErrMsgs()

Get the error messages for this controller.

=cut

sub getErrMsgs {
    my $self = shift;

    return $self->{'_msgs'} if exists $self->{'_msgs'};

    $self->_initErrMsgs();
    return $self->{'_msgs'};
}

=item checkForm($profile)

This method takes a form profile to be passed to L<Data::FormValidator>,
and returns a Data::FormValidator::Results object.

=cut

sub checkForm {
    my $self = shift;
    my $profile = shift;

    die "checkForm: missing required profile\n" unless $profile;

    my $dfv = Data::FormValidator->new();
    my $form_results = $dfv->check(Solstice::CGI->new(), $profile);

    my $error = undef;
    if ($form_results->has_missing or $form_results->has_invalid) {
        $error = Solstice::CGI::FormError->new();
        $error->setFormMessages($form_results->msgs);
    }
    return $error;
}

=item createParam('param_name')

Adds a new param to be validated.  This is required by default.

=cut

sub createParam {
    my $self = shift;
    return $self->createRequiredParam(@_);
}

=item createRequiredParam('param_name')

Adds a new param to be validated.  Requires user input.

=cut

sub createRequiredParam {
    my $self = shift;
    my $param_name = shift;
    
    my $param = Solstice::ValidationParam->new($param_name);
    $param->setRequired();
    $param->addTrimmedLengthConstraint('input_required', {min => 1});
    
    push @{$self->{'_constraints'}}, $param;

    return $param;
}

=item createOptionalParam('param_name');

Adds a new param to be validated.  Does not require user input.

=cut

sub createOptionalParam {
    my $self = shift;
    my $param_name = shift;

    my $param = Solstice::ValidationParam->new($param_name);
    $param->setOptional();
    
    push @{$self->{'_constraints'}}, $param;

    return $param;
}

=item createGroupDependency({ dependency_name => 'name', require => $count, fields => [ $field1, $field2] });

Allows the use of require_some...

=cut

sub createGroupDependency {
    my $self = shift;
    my $input = shift;

    push @{$self->{'_group_dependencies'}}, $input;

    return TRUE;
}

=item processConstraints()

Takes all of the constraints added to a controller, transforms them into a hash for Data::FormValidator.

=cut

sub processConstraints {
    my $self = shift;
    my $global_error_key = shift;
    if (!defined $global_error_key) {
        $global_error_key = GLOBAL_FORM_ERROR_KEY;
    }
    
    # Start by pulling all of the data out of the constraint objects, and into a mungable form
    my @params = @{$self->{'_constraints'}};

    my (%required, %optional);
    my $constraints = {};
    my $require_some = {};
    
    for my $param (@params) {
        my $name = $param->getFieldName();
        if ($param->isRequired()) {
            $required{$name} = 1;
        } else {
            $optional{$name} = 1;
        }

        my $constraint_iterator = $param->getConstraints()->iterator();
        while (my $constraint = $constraint_iterator->next()) {
            push @{$constraints->{$name}}, { 
                name       => $constraint->{'error_key'},
                constraint => $constraint->{'constraint'},
            };
        }
    }
    
    # Go through the group dependencies...
    for my $dependency (@{$self->{'_group_dependencies'}}) {
        my $name = $dependency->{'dependency_name'};
        my $count = $dependency->{'require'};
        my @fields = @{$dependency->{'fields'}};
        for my $field (@fields) {
            delete $required{$field};
        }
        $require_some->{$name} = [$count, @fields];
    }

    # Create the form profile out of the intermediate data
    my $form_profile = {
        msgs         => $self->getErrMsgs(),
        optional     => [keys %optional],
        required     => [keys %required],
        require_some => $require_some,
        constraints  => $constraints,
    };

    my $valid = TRUE;
    if (my $error = $self->checkForm($form_profile)) {
        $valid = FALSE;

        $self->setError($error);
        
        ref($self) =~ m/^(\w+):.*$/;
        my $ns = $1;
        $self->getMessageService()->addErrorMessage(
            $self->getLangService($ns)->getMessage($global_error_key)
        );
    }
    return $valid;
}

=item setInputName($location_name)

=cut

sub setInputName {
    my $self = shift;
    $self->{'_input_name'} = shift;
}

=item getInputName()

=cut

sub getInputName {
    my $self = shift;
    return $self->{'_input_name'};
}

=item setOutputName($location_name)

=cut

sub setOutputName {
    my $self = shift;
    $self->{'_output_name'} = shift;
}

=item getOutputName()

=cut

sub getOutputName {
    my $self = shift;
    return $self->{'_output_name'};
}

=item getInputObject()

=cut

sub getInputObject {
    my $self = shift;

    my $service = Solstice::Service->new;
    return $service->get($self->getInputName());
}

=item getOutputObject()

=cut

sub getOutputObject {
    my $self = shift;

    my $service = Solstice::Service->new;
    return $service->get($self->getOutputName());
}

=item setInputObject($object)

=cut

sub setInputObject {
    my $self = shift;
    my $object = shift;

    my $service = Solstice::Service->new;
    $service->set($self->getInputName(), $object);
}

=item setOutputObject($object)

=cut

sub setOutputObject {
    my $self = shift;
    my $object = shift;

    my $service = Solstice::Service->new;
    $service->set($self->getOutputName(), $object);
}

=item createChildControllerList( 'loop_name', 'var_name' )

=cut

sub createChildControllerList {
    my ($self, $name) = @_;

    return undef unless ($name);

    my $list = Solstice::List->new();

    ${$self->{'_child_controllers'}}{$name} = $list->getAll();

    return $list;
}


=item addChildController($key,( $controller || \@controllers) )

=cut

sub addChildController {
    my $self = shift;
    my $key = shift;
    my $arg = shift;

    unless (defined $self->{'_child_controllers'}){
        $self->{'_child_controllers'}{$key} = [];
    }
    if (!defined $arg){ 
        $self->warn('Tried to add an undefined child controller');
        return FALSE;
    }

    if (ref $arg eq 'ARRAY'){
        push @{$self->{'_child_controllers'}{$key}}, @$arg;
    }else{
        push @{$self->{'_child_controllers'}{$key}}, $arg;
    }
    return TRUE;
}

=item getChildController($key)

=cut

sub getChildController {
    my $self = shift;
    my $key = shift;

    my $controllers = $self->getChildControllers($key);
    if (defined $controllers and defined $$controllers[0]) {
        return $$controllers[0];
    }
    return;
}
    
=item getChildControllers($key)

returns a reference to an array of 'em.

=cut

sub getChildControllers{
    my $self = shift;
    my $key = shift;

    # Make sure we always return an array ref...
    return $self->{'_child_controllers'}{$key} || [];
}

=item clearChildControllers($key)

=cut

sub clearChildControllers {
    my $self = shift;
    my $key = shift;

    $self->{'_child_controllers'}{$key} = [];
}

=item validateChildren($key)

=cut

sub validateChildren {
    my $self = shift;
    my $key  = shift;

    my $retval = TRUE;
    for my $controller ( @{$self->getChildControllers($key)} ) {
        if (!defined $controller) {
            $self->warn('Tried to call validateChildren with an undefined controller');
            return FALSE;
        }
        $retval &= $controller->validate(@_);
    }
    return $retval;
}

=item updateChildren($key)

=cut

sub updateChildren {
    my $self = shift;
    my $key  = shift;

    my $retval = TRUE;
    for my $controller ( @{$self->getChildControllers($key)} ) {
        if (!defined $controller) {
            $self->warn('Tried to call updateChildren with an undefined controller');
            return FALSE;
        }
        $retval &= $controller->update(@_);
    }
    return $retval;
}

=item revertChildren($key)

=cut

sub revertChildren {
    my $self = shift;
    my $key  = shift;

    my $retval = TRUE;
    for my $controller ( @{$self->getChildControllers($key)} ) {
        if (!defined $controller) {
            $self->warn('Tried to call revertChildren with an undefined controller');
            return FALSE;
        }
        $retval &= $controller->revert(@_);
    }
    return $retval;
}

=item commitChildren($key)

=cut

sub commitChildren {
    my $self = shift;
    my $key  = shift;

    my $retval = TRUE;
    for my $controller ( @{$self->getChildControllers($key)} ) {
        if (!defined $controller) {
            $self->warn('Tried to call commitChildren with an undefined controller');
            return FALSE;
        }
        $retval &= $controller->commit(@_);
    }
    return $retval;
}

=item validPreConditionsChildren($key)

=cut

sub validPreConditionsChildren {
    my $self = shift;
    my $key  = shift;

    my $retval = TRUE;
    for my $controller ( @{$self->getChildControllers($key)} ) {
        if (!defined $controller) {
            $self->warn('Tried to call validPreConditionsChildren with an undefined controller');
            return FALSE;
        }
        $retval &= $controller->validPreConditions(@_);
    }
    return $retval;
}


=item freshenChildren($key)

=cut

sub freshenChildren{
    my $self = shift;
    my $key = shift;

    my $retval = TRUE;
    for my $controller ( @{$self->getChildControllers($key)} ) {
        if (!defined $controller) {
            $self->warn('Tried to call freshenChildren with an undefined controller');
            return FALSE;
        }
        $retval &= $controller->freshen(@_);
    }
    return $retval;
}

=item getDateTimeController($model)

Return the preferred Solstice datetime controller, or a fallback.

=cut

sub getDateTimeController {
    my $self = shift;
    my $model = shift;
    return Solstice::Controller::FormInput::DateTime::YahooUI->new($model);
}

=item getRichTextController($model)

Return the preferred Solstice rich-text controller, or a fallback.

=cut

sub getRichTextController {
    my $self = shift;
    my $model = shift;

    my $service = Solstice::Service::Memory->new();

    my $has_fckeditor = $service->getValue('has_fckeditor');
    unless (defined $has_fckeditor ) {
        eval {
            $self->loadModule('FCKEditor::Controller::Editor');
        };
        $has_fckeditor = ($@) ? FALSE : TRUE;
        $service->setValue('has_fckeditor', $has_fckeditor);
    }
    
    my $controller;
    if ($has_fckeditor) {    
        $controller = FCKEditor::Controller::Editor->new($model);
    } else {
        $controller = Solstice::Controller::FormInput::TextArea->new($model);
    }
    return $controller;
}

=back

=head2 Private Methods

=over 4

=item _initErrMsgs()

Initialize the error messages for this controller.

=cut

sub _initErrMsgs {
    my $self = shift;

    ref($self) =~ m/^(\w+):.*$/;
    my $lang_service = $self->getLangService($1);

    $self->{'_msgs'} = {
        any_errors        => 'err',
        prefix            => 'err_',
        format            => '<span class="sol_error_notification_text">&nbsp;%s</span>',
        invalid_seperator => '<span class="sol_error_notification_text">, </span>',
        missing           => $lang_service->getError('input_required'),
        constraints       => $lang_service->getErrors(),
    };
    return TRUE;
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>,
L<Solstice::LogService|Solstice::LogService>,
L<Solstice::UserService|Solstice::UserService>,
L<Solstice::ValidationParam|Solstice::ValidationParam>,
L<Solstice::CGI|Solstice::CGI>,
L<Solstice::CGI::FormError|Solstice::CGI::FormError>,
L<Data::FormValidator|Data::FormValidator>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: 3365 $



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
