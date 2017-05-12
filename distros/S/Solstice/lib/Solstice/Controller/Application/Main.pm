package Solstice::Controller::Application::Main;

# $Id: Main.pm 3375 2006-05-12 23:03:35Z jdr99 $

=head1 NAME

Solstice::Controller::Application::Main - Controls the lifcycle of Solstice requests.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Controller::Application Solstice::Model);

use Solstice::Session;
use Solstice::Server;
use Solstice::JavaScriptService;
use Solstice::NamespaceService;
use Solstice::ProcessService;
use Solstice::State::Tracker;
use Solstice::CGI qw(param header);
use Solstice::StringLibrary qw(unrender);

use Solstice::View::Application;
use Solstice::View::Boilerplate;
use Solstice::View::Developer::Toolbar;
use Solstice::View::InvalidPreConditions;
use Solstice::View::NoCookies;
use Solstice::View::DeniedBrowser;
use Solstice::View::DeniedUser;
#use Solstice::View::PopIn;

use Solstice::Controller::Application::Auth;

use HTTP::BrowserDetect;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3375 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Controller::Application|Solstice::Controller::Application>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);

    # Set some defaults...
    $self->setViewTopNav(TRUE);

    return $self;
}

=item runApp()
=cut

sub runApp {
    my $self = shift;
    my $screen = shift;

    $self->_setScreen($screen);

    # session, user, js and so on
    # Could enforce url level auth
    return unless $self->_denyUnstableBrowser();
    return unless $self->_initializeSession();

    return if $self->requiresURLAuth();

    return unless $self->_isLoginValid();
    return unless $self->_checkJavascript();

    return unless $self->_initializeState();

    return unless $self->loadApplicationForNamespace();
    return unless $self->_handleButtonAction();
    $self->_setPreClickState(Solstice::Session->new()->getStateTracker()->getState());

    return unless $self->_handlePreClick();

    return unless $self->_paintPreClickView();
    $self->_getPreClickController()->finalize();

    return TRUE;
}

sub requiresURLAuth {
    my $self = shift;

    my $config   = $self->getConfigService();

    my $auth_controller = Solstice::Controller::Application::Auth->new();
    if ($self->_getRequiresAuth() ){
        if (!$auth_controller->hasAuthenticated()) {
            return $auth_controller->requiresUserLogin();
        }
        elsif (!$auth_controller->hasUserAuth()) {
            $self->_paintView(Solstice::View::DeniedUser->new());
            return TRUE;
        }
    }
    return FALSE;
}

sub _paintPreClickView {
    my $self = shift;

    my $preclick_controller = $self->_getPreClickController();
    my $view = $preclick_controller->getView();
    $view->setError($preclick_controller->getController()->getError());

    return $self->_paintView($view);
}



sub _paintView {
    my $self = shift;
    my $view = shift;

    my $application = $self->_getApplication();
    my $server  = Solstice::Server->new();

    my $screen = $self->_getScreen();

    $view->sendHeaders();

    if($view->isDownloadView()){
        $server->printHeaders();
        $view->printData();

    }else{ ### The traditional view
        my $config = $self->getConfigService();

        ### Init the Application View
        my $app_view = Solstice::View::Application->new($application, 1);
        $app_view->setEscapeFrames($self->_getEscapeFrames());
        $app_view->setDocumentTitle($self->_getDocumentTitle());
        $app_view->setSessionAppKey('__'.Solstice::NamespaceService->new()->getNamespace().'__');
        #$app_view->addChildView('solstice_popin_container', Solstice::View::PopIn->new());
        
        ### Now create the boilerplate View
        my $boiler_class;
        if ($self->_getBoilerplateView()) {
            $boiler_class = $self->_getBoilerplateView();
            $self->loadModule($boiler_class);

        }elsif ($config->getBoilerplateView()) {
            $boiler_class = $config->getBoilerplateView();
            $self->loadModule($boiler_class);

        } else {
            $boiler_class = 'Solstice::View::Boilerplate';
        }

        my $boiler_view = $boiler_class->new($application);

        $boiler_view->setViewTopNav($self->_getViewTopNav()) if $boiler_view->can('setViewTopNav');

        $app_view->addChildView('boilerplate', $boiler_view);
        $boiler_view->addChildView('content', $view);
        
        $app_view->addChildView('developer_toolbar', Solstice::View::Developer::Toolbar->new($application));
        
        # Paint the App View - the content is returned by the screen 
        # scalar ref
        $app_view->paint($screen);
    }
    return  TRUE;
}

sub _setDevelopmentOptions {
    my $self = shift;

    my $application = $self->_getApplication();
    my $preference_service = $self->getPreferenceService($application->getNamespace());
    $Solstice::View::use_wireframes = $preference_service->getPreference('display_wire_frames');
    $Solstice::LangService::display_tags = $preference_service->getPreference('display_lang_tags');
    
    return TRUE;
}

sub _handlePreClick {
    my $self = shift;

    my $application = $self->_getApplication();
    my $state_tracker = Solstice::Session->new()->getStateTracker();
    my $selected_button = $self->getButtonService()->getSelectedButton();

    #most of the time a preclick will have been set, if not, pull from state tracker the
    #default for this url or pageflow
    my $preclick_controller = $self->_getPreClickController();
    unless( $preclick_controller ){
        $preclick_controller = $state_tracker->getController($application);
    }

    if (defined $selected_button) {
        $preclick_controller = $self->_preClickFallbacks($preclick_controller);
    }

    if ($preclick_controller->getRequiresAuth() &&
        $self->_requiresAuthentication()) {
            return FALSE;
    }

    unless ($preclick_controller->getController()){
        my $ref = ref $preclick_controller ;
        die("$ref did not set a controller in it's constructor.  Solstice cannot continue\n");
    }
    $preclick_controller->initialize();
    $self->_setPreClickController($preclick_controller);
    return TRUE;
}

sub _preClickFallbacks {
    my $self = shift;
    my $preclick_controller = shift;

    my $application = $self->_getApplication();
    my $state_tracker = Solstice::Session->new()->getStateTracker();
    
    #If we do not have a transition, eg for a bad back button or default state,
    #we cannot check for freshen
    my $transition = $self->_getTransition();

    if ( $transition && $transition->requiresFresh() ) {
        if (!$preclick_controller->freshen()) {
            return $self->_preClickFallbacks($state_tracker->failFreshen());
        }
    }
    if (!$preclick_controller->validPreConditions()) {
        return $self->_preClickFallbacks($state_tracker->failValidPreConditions($application));
    }

    return $preclick_controller;
}

sub _handleButtonAction {
    my $self = shift;

    my $state_tracker = Solstice::Session->new()->getStateTracker();
    # Get the user action and destination application
    my $selected_button = $self->getButtonService()->getSelectedButton();

    if ($self->getConfigService()->getDevelopmentMode()) {
        $self->_setDevelopmentOptions();
    }

    if(!defined $selected_button){
        return TRUE;
    }

    $self->_setPostClickState($state_tracker->getState()); # for logging only

    my $action = $selected_button->getAction();

    #if the button clicked was a navigation-only link (a "StaticButton")
    #we do not want to act as if any action was selected
    if($action eq '__nav_only__'){
        return TRUE;
    }

    $self->_setAction($action);
    my $session = Solstice::Session->new();

    # __bad_back_button__ is the action on the ajax submit that blocks the back button, 
    # getIllegalSession() traps the person who manages to click a button on a bad screen
    if ($action eq '__bad_back_button__' || $session->getIllegalSession()) {
        return $self->_handleBadBackButton();
    }
    if ($action eq "__set_preference__") {
        return $self->_handlePreferenceButton();
    }
    if ($action eq "__requires_auth__") {
        return $self->_handleLoginButton();
    }

    # Clear the session history if the user should not be able to use
    # the back button after this transition.
    if ( !$state_tracker->canUseBackButton($action) || $self->_getDisableBackButton() ) {
        #Clear the session history so this can't be backed over.
        $session->deleteSubsessionChain();
    }

    $self->_findTransition($action);

    return FALSE if ($self->_requiresPostClickAuthentication());

    # Returns false if validation fails - stay on the current state.
    if ($self->_runPostClickLifeCycle()) {

        if ($self->_getIsGlobalTransition()) {
            $self->_runGlobalTransition();
        }else{
            #run standard transition
            $state_tracker->transition($action);
        }

        #reset application incase we changed pageflows
        $state_tracker->getState() =~ /^(.*?):/;
        my $namespace = $1;
        $self->_setNamespace($namespace);
        $self->loadApplicationForNamespace();
    }

    return TRUE;
}

sub _requiresPostClickAuthentication {
    my $self = shift;
    my $transition      = $self->_getTransition();
    my $state_tracker   = Solstice::Session->new()->getStateTracker();
    my $application     = $self->_getApplication();
    my $postclick_controller = $state_tracker->getController($application);
    $self->setPostClickController($postclick_controller);

    if ($postclick_controller->getRequiresAuth() &&
        $self->_requiresAuthentication()) {
            return TRUE;
    }
    return FALSE;
}

sub _requiresAuthentication {
    my $self = shift;

    my $auth_controller = Solstice::Controller::Application::Auth->new();

    if (!$auth_controller->hasUserAuth() ) {
        $auth_controller->getAuthentication();
        return TRUE;
    }
    return FALSE;
}

sub _runPostClickLifeCycle {
    my $self = shift;

    my $transition      = $self->_getTransition();
    my $state_tracker   = Solstice::Session->new()->getStateTracker();
    my $application     = $self->_getApplication();
    my $postclick_controller = $self->_getPostClickController();

    if ($transition->requiresRevert()) {
        if (!$postclick_controller->revert()) {
            $self->_setPreClickController($state_tracker->failRevert($application));
            return FALSE;
        }
    }

    if ($transition->requiresUpdate()) {
        if (!$postclick_controller->update()) {
            $self->_setPreClickController($state_tracker->failUpdate($application));
            return FALSE;
        }
    }
    if ($transition->requiresValidation()) {
        if (!$postclick_controller->validate()) {

            if (my $controller = $state_tracker->failValidation($application)) {
                $self->_setPreClickController($controller);
            } else {
                $self->_setPreClickController($postclick_controller);
            }
            return FALSE;
        }
    }

    if ($transition->requiresCommit()) {
        if (!$postclick_controller->commit()) {
            $self->_setPreClickController($state_tracker->failCommit($application));
            return FALSE;
        }
    }
    return TRUE;
}


sub _runGlobalTransition {
    my $self = shift;

    my $transition = $self->_getTransition();
    my $target_pageflow = $transition->getTargetPageFlow();
    my $machine = Solstice::State::Machine->new();
    my $application = $self->_getApplication();
    my $state_tracker = Solstice::Session->new()->getStateTracker();

    #assume main page flow if none is specified
    my $pageflow = $application->getNamespace().'::'.((defined $target_pageflow) ? $target_pageflow : 'Main');

    my $state;
    if ("Solstice::State::FlowTransition" eq ref($transition)) {
       $pageflow = $transition->getPageFlowName();
       my $current_pageflow = $machine->getPageFlow($pageflow);
       $state = $current_pageflow->getEntrance();
    }else{
        $state_tracker->clearPageFlowStack();
    }
    $state_tracker->startApplication($pageflow, $transition->getName());
    $state_tracker->_setState($transition->getTargetState()||$state);

    return;
}

sub _findTransition {
    my $self = shift;
    my $action = shift;

    my $state_tracker = Solstice::Session->new()->getStateTracker();

    if( my $transition = $state_tracker->getTransition($action)){
        $self->_setTransition($transition);
        $self->_setIsGlobalTransition(FALSE);

    }elsif( $transition = $state_tracker->getPageFlowGlobalTransition($action, $self->_getNamespace())){
        $self->_setTransition($transition);
        $self->_setIsGlobalTransition(TRUE)

    }elsif( $transition = $state_tracker->getGlobalTransition($action, $self->_getNamespace())){
        $self->_setTransition($transition);
        $self->_setIsGlobalTransition(TRUE);

   }else{
        my $state = $state_tracker->getState();
        die "Could not transition from state $state via action $action\n"
   }
}

sub _handleBadBackButton {
    my $self = shift;

    my $state_tracker   = Solstice::Session->new()->getStateTracker();
    my $application     = $self->_getApplication();

    if( $state_tracker->getBackErrorMessage() ){
        my $ns = Solstice::NamespaceService->new()->getAppNamespace();
        $self->getMessageService()->addInfoMessage(
            $self->getLangService($ns)->getMessage($state_tracker->getBackErrorMessage())
        );
    }else{
        $self->getMessageService()->addInfoMessage(
            $self->getLangService()->getMessage('generic_back_error')
        );
    }

    $self->_setPreClickController($state_tracker->getController($application));

    return TRUE;
}

sub _handlePreferenceButton {
    my $self = shift;

    my $selected_button = $self->getButtonService()->getSelectedButton();
    my $application     = $self->_getApplication();
    my $state_tracker   = Solstice::Session->new()->getStateTracker();

    my $key = $selected_button->getPreferenceKey();
    my $value = $selected_button->getPreferenceValue();

    if (defined $key) {
        my $preference_service = $self->getPreferenceService($application->getNamespace());
        $preference_service->setPreference($key, $value);
    }

    my $controller = $state_tracker->getController($application);
    $controller->update();
    $self->_setPreClickController($controller);

    # This ensures that dev toolbar prefs get picked up immediately
    if ($self->getConfigService()->getDevelopmentMode()) {
        $self->_setDevelopmentOptions();
    }

    return TRUE;
}

sub _handleLoginButton {
    my $self = shift;

    my $selected_button = $self->getButtonService()->getSelectedButton();
    my $application     = $self->_getApplication();
    my $state_tracker   = Solstice::Session->new()->getStateTracker();
    
    my $controller = $state_tracker->getController($application);
    $controller->setRequiresAuth(TRUE);
    $self->_setPreClickController($controller);
    
    return TRUE;
}

sub _denyUnstableBrowser {
    my $self = shift;

    # Do we support this browser?
    if( $self->_isBrowserStable() ){
        return TRUE;
    }else{
        $self->_paintView(Solstice::View::DeniedBrowser->new());
        return FALSE;
    }
}

sub _initializeSession {
    my $self = shift;

    # Initialize session
    my $session = Solstice::Session->new;

    # Before we do anything else, make sure we have a proper session
    # to work with
    unless ($session->hasSession()) {
        if($self->_getRequireSession()){
            $self->_forceCreateSession();
            return FALSE;
        }else{
            $self->_passiveCreateSession();
        }
    }
    # Okay, we have a useful session - since this is a user-pageview
    # controller, we'll need a subsession too
    $session->loadSubsession();
    return TRUE;
}

sub _isLoginValid {
    my $self = shift;

    # Is the login name valid?
    if (my $user = $self->getUserService()->getOriginalUser()) {
        # Is this really the first place where we need to load the login realm module?
        $self->loadModule($user->getLoginRealm());
        unless ($user->getLoginRealm()->isValidLogin($user->getLoginName())) {
            $self->_paintView(Solstice::View::DeniedUser->new());
            return FALSE;
        }
    }
    return TRUE;
}

sub _checkJavascript {
    my $self = shift;

    my $session = Solstice::Session->new();
    # Check that javascript flag has been set
    if($self->_getRequireSession()){
        if (!defined $session->hasJavascript()) {
            my $has_js = param('has_js');
            if (!defined $has_js) {
                $self->_checkHasJavascript();
                return FALSE;
            }
            $session->setHasJavascript($has_js);
            Solstice::ButtonService->new()->setHasJavascript($has_js);
        }
        Solstice::JavaScriptService->new()->setHasJavascript($session->hasJavascript());
    }else{
        #if we aren't doing a session bounce we just have to assume
        #TODO: this exposes that our JS detection method is kinda weak. Can we do better?
        Solstice::JavaScriptService->new()->setHasJavascript(TRUE);
    }

    return TRUE;
}

sub _initializeState {
    my $self = shift;

    my $session = Solstice::Session->new();
    my $namespace = Solstice::NamespaceService->new()->getNamespace();

    my $pageflow = $self->_getPageFlow() || 'Main';
    my $initial_state = $namespace.'::'.$self->_getInitialState();
    $pageflow = $namespace.'::'.$pageflow;

    ### Init the App's State Machine
    my $state_tracker = $session->getStateTracker();

    #if we are just navigating via a button, we want to keep our subsesion
    #but we need to refresh our state to whatever this url thinks is default
    my $clear_state = FALSE;
    my $selected_button = $self->getButtonService()->getSelectedButton();
    if($selected_button && $selected_button->getAction() eq '__nav_only__'){
        $clear_state = TRUE;
    }

    if (!$state_tracker || $clear_state) {
        $state_tracker = new Solstice::State::Tracker();
        $state_tracker->startApplication($pageflow, $initial_state);
        $session->setStateTracker($state_tracker);
    }

    #if there was a state tracker and we were ina pageflow, we may need
    #to capture the name of that pageflow - if we are in the url's default
    #pageflow, this will be essentially a no-op
    $state_tracker->getState() =~ /(.*?):/;
    $namespace = $1;
    $self->_setNamespace($namespace);

    return TRUE;
}

=item _passiveCreateSession($screen)

Adds a header to the current request that will set a session cookie, but does not force
a browser bounce - The session cookie will be send on subsequent requests if it's
accepted.

=cut

sub _passiveCreateSession {
    my $self = shift;
    my $screen = $self->_getScreen();

    my $session = Solstice::Session->new();
    my $server  = Solstice::Server->new();

    my $session_cookie = $session->getCookie()->bake();

    return;
}


=item _forceCreateSession($screen)

Write a cookie to the browser, and do a meta refresh back to the page.
Can't be a 300 redirect, it needs to be a full round trip to the
client for the cookie to be processed properly.

=cut

sub _forceCreateSession {
    my $self = shift;

    my $screen = $self->_getScreen();

    my $session = Solstice::Session->new();
    my $server  = Solstice::Server->new();

    if (defined param('has_js')) {
        #cookies are probably not enabled, we're just bouncing around
        $self->_paintView(Solstice::View::NoCookies->new(), undef, $screen);

        return TRUE;
    }

    my $session_cookie = $session->getCookie()->bake();

    $self->_checkHasJavascript();

    return TRUE;
}

=item _checkHasJavascript()

Round trip to the client, to verify if javascript is enabled or not.

=cut

sub _checkHasJavascript {
    my $self = shift;

    my $server = Solstice::Server->new();
    $server->setContentType('text/html; charset=UTF-8');

    my $query_string = $ENV{'QUERY_STRING'} ? ('?'.$ENV{'QUERY_STRING'}) : '';
    my $url = $server->getURI();

    my $existing_params = '';

    my $params = param();
    foreach my $key (keys %$params) {
        my @values = param($key);
        my $name = unrender($key);
        foreach my $value (@values) {
            $value = unrender($value);
            $existing_params.= qq|<input type="hidden" name="$name" value="$value"/>\n|;
        }
    }

    # Non-javascript clickthrough message
    my $content = $self->getLangService()->getString('clickthrough_no_javascript');

    my $screen = $self->_getScreen();
    $$screen = qq|<html><head></head><body>
    <form method="post" id="init_form" action="$url$query_string">
        $existing_params
        <input type="hidden" id="js_tracker" name="has_js" value="0" />
        <noscript>
        <input id="submit_button" type="submit" value="$content" />
        </noscript>
    </form>
    <script type="text/javascript">
        var has_js = document.getElementById('js_tracker');
        has_js.value = '1';
        document.getElementById('init_form').submit()
    </script>
    </body></html>|;

    return TRUE;
}


sub loadApplicationForNamespace {
    my $self = shift;

    my $namespace = $self->_getNamespace();
    my $session = Solstice::Session->new();

    # Get our app config params
    my $session_app_key = '__'.$namespace.'__';

    # Get our app classes, and require them in.
    my $app_class = $namespace.'::Application';

    $self->loadModule($app_class);

    my $application = $session->get($session_app_key);

    unless (defined $application) {
        $application = $app_class->new();
        unless( $application ){
            die "Failed to load or create an application object $app_class";
        }
        $session->set($session_app_key, $application);
    }

    $self->_setApplication($application);

    return TRUE;
}


=item _isBrowserStable()

Check browser/OS combination

=cut

sub _isBrowserStable {
    my $self = shift;

    my $b = HTTP::BrowserDetect->new();

    # special netscape 8 case - we only bock the IE rendering engine
    return FALSE if ($b->user_agent =~ /Netscape\/8/ && $b->user_agent =~ /MSIE/);

    # white list
    # developer tested and APPROVED
    return TRUE if ($b->firefox || $b->mozilla || $b->safari);
    return TRUE if ($b->ie && $b->version > 5.5);
    return TRUE if ($b->netscape && $b->version > 6.1);
    
    # black list
    # developer tested and DENIED
    return FALSE if ($b->netscape || $b->ie);

    # unknown
    return TRUE;
}


=item _getAccessorDefinition()
=cut

sub _getAccessorDefinition {
    return [
        {
            name        => 'RequiresFreshen',
            key         => '_require_freshen',
            type        => 'Boolean',
            private_get => TRUE,
        },
        {
            name        => 'ViewTopNav',
            key         => '_view_top_nav',
            type        => 'Boolean',
            private_get => TRUE,
        },
        {
            name        => 'BoilerplateView',
            key         => '_boilerplate_view',
            type        => 'String',
            private_get => TRUE,
        },
        {
            name        => 'RequiresAuth',
            type        => 'Boolean',
            private_get => TRUE,
        },
        {
            name        => 'RequireSession',
            key         => '_require_session',
            type        => 'Boolean',
            private_get => TRUE,
        },
        {
            name        => 'InitialState',
            key         => '_initial_state',
            type        => 'String',
            private_get => TRUE,
        },
        {
            name        => 'PageFlow',
            key         => '_page_flow',
            type        => 'String',
            private_get => TRUE,
        },
        {
            name        => 'EscapeFrames',
            key         => '_escape_frames',
            type        => 'Boolean',
            private_get => TRUE,
        },
        {
            name        => 'DisableBackButton',
            key         => '_disable_back_button',
            type        => 'Boolean',
            private_get => TRUE,
        },
        {
            name        => 'DocumentTitle',
            key         => '_document_title',
            type        => 'String',
            private_get => TRUE,
        },
        {
            name        => 'PostClickState',
            key         => '_post_click_state',
            type        => 'String',
        },
        {
            name        => 'PreClickState',
            key         => '_pre_click_state',
            type        => 'String',
        },
        {
            name        => 'PostClickController',
            key         => '_post_click_controller',
            type        => 'Solstice::Controller',
            private_get => TRUE,
        },
        {
            name        => 'PreClickController',
            key         => '_pre_click_controller',
            type        => 'Solstice::Controller',
            private_get => TRUE,
        },
        {
            name        => 'Action',
            key         => '_action',
            type        => 'String',
        },
        {
            name        => 'Screen',
            key         => '_screen',
            type        => 'SCALAR',
            private_get => TRUE,
        },
        {
            name        => 'Namespace',
            key         => '_namespace',
            type        => 'String',
            private_get => TRUE,
        },
        {
            name        => 'Application',
            key         => '_application',
            type        => 'Solstice::Application',
            private_get => TRUE,
        },
        {
            name        => 'IsGlobalTransition',
            key         => '_is_global_trans',
            type        => 'Boolean',
            private_get => TRUE,
        },
        {
            name        => 'Transition',
            key         => '_transition',
            type        => 'Solstice::State::Transition',
            private_get => TRUE,
        },

    ];
}


=back

=head2 Private Methods

=over 4

=cut


1;

__END__

=back

=head2 Modules Used

L<Solstice::Controller::Application|Solstice::Controller::Application>,
L<Solstice::Session|Solstice::Session>,
L<Solstice::View::HelpPane|Solstice::View::HelpPane>,
L<Solstice::View::InvalidPreConditions|Solstice::View::InvalidPreConditions>,
L<Solstice::View::Navigation|Solstice::View::Navigation>,
L<Solstice::CGI|Solstice::CGI>,

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3375 $



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
