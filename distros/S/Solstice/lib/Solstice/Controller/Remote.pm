package Solstice::Controller::Remote;

=head1 NAME

Solstice::Controller::Remote - The superclass for all AJAX-called controllers.

=cut

use base qw(Solstice::Controller);

use strict;
use warnings;
use 5.006_000;

use JSON;
use Solstice::View::Remote;
use Solstice::ButtonService;
use Solstice::Session;
use Solstice::CGI;

use constant TRUE   => 1;
use constant FALSE  => 0;

=over 4

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);

    $self->{'_actions'} = [];

    return $self;
}

sub runApp {
    my $self = shift;
    my $screen = shift;

    #get input values
    my $app_key     = param('solstice_session_app_key');
    my $app         = param('solstice_remote_app');
    my $action      = param('solstice_remote_action');

    unless( $app_key && $app && $action ){
        warn "Badly formed remote call\n";
        return;
    }

    #prepare the js data
    my $data    = param('solstice_remote_data');
    my $json = JSON->new();
    $data = $json->jsonToObj($data);

    #Okay, what controller do we run?
    my $config = Solstice::Configure->new();
    my $controller_name = $config->getRemoteDefs()->{$app}{$action};

    if(defined $controller_name){

        $self->loadModule($controller_name);
        #init the controller
        my $controller = $controller_name->new($data);
        $controller->setSessionAppKey($app_key);

        #Run the remote lifecycle with validation
        if($controller->validate()){
            $controller->runRemote();
        }else{
            $controller->abortRemote();
        }

        $controller->addMessages();#adds any message service messages
        
        #gather the info created by the controller for the view
        my $view = Solstice::View::Remote->new($data);

        $view->setActions($controller->getActions());
        $view->paint($screen);

        $controller->_commitButtonService();

        Solstice::Server->new()->setContentType("text/xml; charset=UTF-8");

        return TRUE;
    }else{
        warn "Call to undefined remote controller \"$app:$action\"\n";
    }
}

sub validate {
    return TRUE;
}

sub runRemote {
    return TRUE;
}

sub abortRemote {
    return TRUE;
}

=item addAction($javascript);

Adds a javascript action that will be evaled by the client.

=cut

sub addAction {
    my $self = shift;
    push @{$self->{'_actions'}}, {type => 'action', content => shift}

}

=item addBlockReplacement($id, $content)

Creates a new element of $content.  This new element will replace the element with id $id.  $content needs to contain any block structure you wish to maintain, such as <div id="replacement_id"> ... </div>.

=cut

sub addBlockReplacement {
    my $self = shift;
    my $block_id = shift;
    my $content = shift;
    push @{$self->{'_actions'}}, {
        type        => 'replacement',
        block_id    => $block_id,
        content     => $content,
    };
}

=item addContentUpdate($id, $content)

Finds the page element with the given id, and replaces its content with the value provided.

=cut

sub addContentUpdate {
    my $self = shift;
    my $block_id = shift;
    my $content = shift;
    push @{$self->{'_actions'}}, {
        type        => 'update',
        block_id    => $block_id,
        content     => $content,
    };
}

=item setPopinContent($title, $content)

Configure a popin with the given content.

=cut

sub setPopinContent {
    my $self    = shift;
    my $title   = shift;
    my $body    = shift;

    $self->addContentUpdate('solstice_popin_title', $title);
    $self->addContentUpdate('solstice_popin_content', $body);

    return TRUE;
}

sub getActions {
    my $self = shift;
    return $self->{'_actions'};
}

sub setSessionAppKey {
    my $self = shift;
    $self->{'_session_app_key'} = shift;
}

sub getSessionAppKey {
    my $self = shift;
    return $self->{'_session_app_key'};
}

sub initStatefulAPI {
    my $self = shift;

    return if $self->{'_stateful_init'};

    my $session = Solstice::Session->new();
    die "Solstice Exception: User with no session making Remote calls\n" unless $session->hasSession();

    #To make sure we use the subsession of the page that is running the remotes,
    #we pretend that a button was used that ties this click to the appropriate
    #subsession. That way, when loadSubsession() runs, it will pull that particular
    #subsession - falling back on the chain if needed
    my $button_service = Solstice::ButtonService->new();
    my $button = Solstice::Button->new();
    $button->_setSubsessionID(param('solstice_subsession_id'));
    $button_service->set('selected_button', $button);

    $session->loadSubsession($self->_getChainID());

    my $application = $session->get($self->getSessionAppKey()) || undef;
    die "No application in user session for Remote call\n" unless $application;

    my $app_class = ref $application;
    $self->loadModule($app_class);

    $self->{"_application"} = $application;
    $self->{'_stateful_init'} = TRUE;
}

sub getSession {
    my $self = shift;
    $self->initStatefulAPI();
    return Solstice::Session->new();
}

sub getApplication {
    my $self = shift;
    $self->initStatefulAPI();
    return $self->{'_application'};
}

sub getButtonService {
    my $self = shift;
    $self->initStatefulAPI();
    return Solstice::ButtonService->new();
}

sub addMessages {
    my $self = shift;
   
    my $msg_service = $self->getMessageService();

    my @messages = $msg_service->getMessages();
    if((scalar @messages) || $msg_service->isScreenClear()){
        my $message_service_view = Solstice::View::MessageService->new();

        my $msg_content;
        $message_service_view->paint(\$msg_content);
        $self->addBlockReplacement('sol_message_service_container',$msg_content);
    }

    return TRUE;
}

sub _commitButtonService {
    my $self = shift;
    if( $self->{'_stateful_init'} ){
        my $button_service = Solstice::ButtonService->new();
        $button_service->commit();
    }
}

sub _getChainID {
    my $self = shift;
    return param('solstice_subsession_chain');
}

1;

__END__

=back

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
