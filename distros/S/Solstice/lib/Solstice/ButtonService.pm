package Solstice::ButtonService;

# $Id: ButtonService.pm 3396 2006-05-22 16:10:19Z jlaney $

=head1 NAME

Solstice::ButtonService - A service that tracks what buttons have been created for a page.

=cut

=head1 SYNOPSIS

  use Solstice::ButtonService;

  my $button_service = new Solstice::ButtonService;

  $button_service->initialize($my_solstice_session);
  
  Functions for views: 
  Standard buttons
  my $button = $button_service->makeButton( {
    label => 'Text on button',
    title => 'Title, for text links',
    action => 'TheKeywordInState.xml',
    client_action => 'Name of a Javascript function to happen onClick',
    attributes => {
      keys => 'and values',
      that => 'will be retrievable in controller',
    },
  } );

  If you are creating a link to another application, add the application's url:
  my $button = $button_service->makeButton( {
    label => 'Text on button',
    title => 'Title, for text links',
    action => 'TheKeywordInState.xml',
    url    => '/tools/webq/',
    client_action => 'Name of a Javascript function to happen onClick',
    attributes => {
      keys => 'and values',
      that => 'will be retrievable in controller',
    },
  } );


  Flyout menus
  my $button = $button_service->makeFlyoutButton( {
    label => 'Text on button',
    title => 'Title, for text links',
    action => 'TheKeywordInState.xml',
    flyout_actions => [ {
        label => 'Text on button',
        title => 'Title, for text links',
        action => 'TheKeywordInState.xml',
    },
    {
        label => 'Text on button',
        title => 'Title, for text links',
        action => 'TheKeywordInState.xml',
    }, ... ],
  } );

  Pop-in buttons
  You may also use buttonservice to create "pop ins", as long as you create the Solstice::View::PopIns on the same page
 
  my $pop_in = $button_service->makePopinButton( {
    label => "Text on link",
  } );
    
  See Button.pm for details on how to use the button objects.

  Functions for controllers:
  my $button = $button_service->getSelectedButton();
  my $attribute = $button_service->getAttribute('keyname');

=head1 DESCRIPTION

This manages all action objects on a page, including buttons, links, image links, and all of those as popups.  Using ButtonService is required for actions to take place, otherwise the page a button was clicked on will just reload.

This must be initialized with a Solstice::Session, preferably the only one created in your application.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Solstice::Button;
use Solstice::Button::Flyout;
use Solstice::Button::PopIn;
use Solstice::Button::PopUp;
use Solstice::Button::Static;
use Solstice::Button::Transition;
use Solstice::Session;
use Solstice::JavaScriptService;
use Solstice::CGI;
use Solstice::Service::YahooUI;

use Digest::MD5;
use Carp qw(confess);
use HTTP::BrowserDetect;
use Time::HiRes qw(gettimeofday tv_interval);

use constant TRUE   => 1;
use constant FALSE  => 0;
use constant PREFIX => 'btn_'; #this lives in the buttonservice subclasses as well
use constant FLYOUT_JS => 'javascript/flyout.js';


our ($VERSION) = ('$Revision: 3396 $' =~ /^\$Revision:\s*([\d.]*)/);
our $application_destination_tracker;

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods 

=over 4

=cut



=item new()

Constructor.

=cut

sub new {
    my $pkg = shift;
    $pkg = 'Solstice::ButtonService::' .$pkg->getConfigService()->getSessionBackend();
    Solstice->loadModule($pkg);
    my $namespace = shift;
    my $self =  $pkg->SUPER::new(@_);

    $self->setNamespace($namespace);

    return $self;
}


=item initialize($session)

This is a required function to get functionality.  This gets the 
session id from session.

=cut

sub initialize {
    my $self = shift;
    my $session = Solstice::Session->new();

    $self->setValue('session', $session);
    $self->setValue('commit_id', $self->_generateCommitID());
    $self->setValue('current_button_number', 0);
    $self->setValue('button_array', []);
    
    my $browser = HTTP::BrowserDetect->new();
    
    $self->setHasJavascript(Solstice::JavaScriptService->new()->hasJavascript());
    
    return TRUE;
}

=item makeButton($params)

This will create a Button object from the param hash.  For a normal button, the following keys should be defined: label, action.  The following keys can be defined: title, attributes, client_action, popup_attributes.

client_action is the name of a Javascript function.  The name given will be appended with "(form)", where form is the form object of the page.

popup_attributes is a string that controls what a popup window will look like, if the button is rendered as a popup.

=cut

sub makeButton {
    my $self = shift;
    my $params = shift;

    my $button;
    if($self->isValidHashRef($params)){
        $button = $self->_makeButton('Solstice::Button::Transition', $params);
    }else{
        $button = $self->_makeButton('Solstice::Button::Transition', {action => $params });
    }

    return $button;
}

=item makeLoginButton($params)

This creates a button that forces the user to login.  This button will override any action you give it with a special action used to force
the login.

=cut

sub makeLoginButton {
    my $self = shift;
    my $params = shift;

    my $button;

    if($self->isValidHashRef($params)){
        $params->{'action'} = '__requires_auth__';
        $button = $self->_makeButton('Solstice::Button::Transition', $params);
    }else{
        $button = $self->_makeButton('Solstice::Button::Transition', {action => '__requires_auth__' });
    }
    return $button;
}
=item makePopupButton(\%params)

=cut

sub makePopupButton {
    my $self = shift;
    if($self->isValidHashRef(@_) && defined @_){
        return $self->_makeButton('Solstice::Button::PopUp', @_);
    }else{
        return $self->_makeButton('Solstice::Button::PopUp', {action =>@_});

    }
}

=item makePopinButton(\%params)

=cut

sub makePopinButton {
    my $self = shift;
    if($self->isValidHashRef(@_) && defined @_){
        return $self->_makeButton('Solstice::Button::PopIn', @_);
    }else{
        return $self->_makeButton('Solstice::Button::PopIn', {action    =>@_});
    }
}

=item makeStaticButton(\%params)

Creates a button to a bookmarkable url.

=cut

sub makeStaticButton {
    my $self = shift;
    my $params = shift;

    my $button;
    if($self->isValidHashRef($params) && defined $params){
        if (!defined $params->{'url'} && !defined $params->{'disabled'}) {
            die "makeStaticButton called without a URL.  Called from ".join(' ', caller)."\n";
        }
        if ( defined $params->{'action'}){
            die "makeStaticButton does not take an 'action' option. Called from ". join (' ', caller)."\n";
        }else{
            $params->{'action'} = '__nav_only__';
        }
        $button = $self->_makeButton('Solstice::Button::Static', $params);
    }else{
        $button = $self->_makeButton('Solstice::Button::Static', {action    => '__nav_only__'});
    }

    return $button;
}

=item makeFlyoutButton(\%params)

Create a button that contains child buttons.

=cut

sub makeFlyoutButton {
    my $self = shift;
    my $params = shift;

    my $flyout_button;
    if(!$self->isValidHashRef($params) || !defined $params){
        $flyout_button = $self->_makeButton('Solstice::Button::Flyout', {action => $params});
    }else{

        $flyout_button = $self->_makeButton('Solstice::Button::Flyout', $params);
        
        return $flyout_button if $params->{'disabled'};

        my $flyouts = [];
        my $flyout_actions = $params->{'flyout_actions'} || [];
        for my $action (@$flyout_actions) {
            push @$flyouts, $self->_makeButton('Solstice::Button', $action) if defined $action;
        }
        $flyout_button->{'_flyouts'} = $flyouts;
    }
    
    unless ($self->getValue('flyouts_initialized')) {
        my $yahooui_service = Solstice::Service::YahooUI->new();
        $yahooui_service->addFlyoutMenuFiles();

        $self->getIncludeService()->addJSFile(FLYOUT_JS);
        $self->setValue('flyouts_initialized', TRUE);
    }
    
    return $flyout_button;
}

=item commit()

This commits all of the created buttons to the database, and clears 
our global memory.

=cut


sub commit {
    my $self = shift;

    my $button_array = $self->getValue('button_array'); 
    my $button_commit_id = $self->getValue('commit_id');

    if(defined $button_array && scalar @$button_array){
        unless (defined $self->getValue('session')) {
            $self->initialize();
        }
    }

    $self->_storeButtonList($button_array, $button_commit_id);

    return $self->_clear();
}

=item getSelectedButton()

Returns the button that was selected on the previous page, if a button was 
selected.  Otherwise returns undef.

=cut

sub getSelectedButton {
    my $self = shift;

    return $self->getValue('selected_button') if $self->get('selected_button');

    unless (defined $self->getValue('session')) {
        $self->initialize();
    }

    my $session_id = $self->getValue('session')->getSessionID();

    if (!defined $session_id) {
        confess "You failed to initialize ButtonService with a Solstice session.  You should read it's pod.";
    }

    my $selected_button = param('solstice_selected_button') || '';
    unless ($selected_button) {
        # Go through the CGI hash param, and find something that looks 
        # like a button...
        my $prefix = PREFIX;
        for my $param (param()) {
            if ($param =~ /^($prefix\w+_[0-9]+)(\.x)?$/) {
                $selected_button = $1;
            }
        }
    }

    return undef unless $selected_button;

    my $button = $self->_selectedButtonLookup($selected_button);

    if (defined $button && $self->getValue('session')->hasSubsessionChainByID($button->getSubsessionChainID())) {
        $self->setValue('selected_button', $button);
        return $button;
    }
    return undef;
}

=item getAttribute('attribute_key')

If there was a selected button on the previous screen, and that button 
had the given attribute key, this will return the value attached to 
that key.  Otherwise it will return undef.  There will be a warning 
in the error log if there was no button selected.

=cut

sub getAttribute {
    my $self = shift;
    my $key  = shift;

    if (!defined $key) {
        $self->warn("getAttribute() called with no attributes");
        return;
    }

    my $button = $self->getValue('selected_button');
    if (defined $button) {
        return $button->{'_attributes'}->{$key};
    }
    else {
    #    This should respect a debug level, but it's a useless warn in most cases.
    #    warn "Called getAttributes without a button, called from: ".join (" ", caller);
        return undef;
    }
}

sub setNamespace {
    my $self = shift;
    $self->{'namespace'} = shift;
}

sub getNamespace {
    my $self = shift;
    return $self->{'namespace'};
}

=back

=head2 Private Methods

=over 4

=cut

=item _clear()

Undef all global data

=cut

sub _clear {
    my $self = shift;

    $self->setValue('selected_button', undef);
    $self->setValue('session', undef);
    $self->setValue('button_array', undef);
    $self->setValue('current_button_number', undef);
    
    return TRUE;
}

=item _makeButton($class, \%params)

=cut

sub _makeButton {
    my $self = shift;
    my ($class, $params) = @_;

    unless (defined $self->getValue('session') ) {
        $self->initialize();
    }
    
    my $button = $class->new($params);
    $button->{'_name'} = $self->_generateButtonName();
    $button->{'_tooltip'} = $params->{'tooltip'};
    $button->{'_has_javascript'} = $self->_hasJavascript();
    $button->{'_namespace'} = $self->getNamespace();

    my $buttons = $self->getValue('button_array');
    push @$buttons, $button;
    $self->setValue('button_array', $buttons);

    return $button;
}

=item _generateButtonName()

Return a unique button name string.

=cut

sub _generateButtonName {
    my $self = shift;
    
    my $current_number = $self->getValue('current_button_number') || 0;
    $self->setValue('current_button_number', $current_number + 1);
    
    my $commit_id = $self->getValue('commit_id') || 0;
    return (PREFIX.$commit_id.'_'.$current_number);
}

=item _selectedButtonLookup($selected_button_name)

=cut

sub _selectedButtonLookup {
    die "_selectedButtonLookup must be implemented in the buttonservice backend chosen in config.";
}

=item _storeButtonList(\@button_array, $commit_id)

=cut

sub _storeButtonList {
    die "_storeButtonList must be implemented in the buttonservice backend chosen.";
}

=item _isButtonStorable($button)

=cut

sub _isButtonStorable {
    my $self = shift;
    my $button = shift;
   
    return FALSE unless (defined $button && defined $button->{'_name'});
    
    return TRUE if defined $button->{'_action'};
    
    if (defined $button->{'_attributes'}) {
        $button->{'_action'} = '__nav_only__';
        return TRUE;
    }
    return FALSE;
}

=item setHasJavascript($bool)

=cut

sub setHasJavascript {
    my $self = shift;
    my $bool = shift;
    $self->setValue('_has_javascript', $bool);
}

=item _hasJavascript()

=cut

sub _hasJavascript {
    my $self = shift;
    return $self->getValue('_has_javascript');
}

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::ButtonService';
}

#these are used just to aggregate buttonids for speedier operation in commit
sub _generateCommitID {
    my $self = shift;
    return Digest::MD5::md5_hex( time().{}.rand().$$ );
}

sub isInitialized {
    my $self = shift;
    return (defined $self->getValue('session'));
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Button|Solstice::Button>,
L<Solstice::Button::Disabled|Solstice::Button::Disabled>,
L<Solstice::Button::Flyout|Solstice::Button::Flyout>,
L<Solstice::Service|Solstice::Service>,
L<Solstice::Database|Solstice::Database>,
L<Solstice::Session|Solstice::Session>,
L<Carp|Carp>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3396 $



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
