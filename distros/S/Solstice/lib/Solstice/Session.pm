package Solstice::Session;

# $Id: Session.pm 3364 2006-05-05 07:18:21Z mcrawfor $

# TODO break new() into discrete methods, e.g. create_session(), login(), etc.
# TODO look into nuking seemingly unneccessary attr's cookie, cookie_name, and cookie_path

=head1 NAME

Solstice::Session - Manage a Solstice Tools session.

=head1 SYNOPSIS

  use CGI;
  use Solstice::Session;

  my $session = Solstice::Session->new;

  #or, if you'd like to use a custom session name for the cookie
  my $session = Solstice::Session->new('custom_name');

  my $cookie = $session->cookie();
  print CGI->header(-cookie => $cookie);

  ## To retrieve the session information
  my $session = Solstice::Session->new;
  $session->set('mydata', $mydata);
  $session->get('mydata');

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::Configure;
use Solstice::Cookie;
use Solstice::Service;
use Solstice::Subsession;
use Digest::MD5;
use Data::Dumper;
use Compress::Zlib qw(compress uncompress);
use Time::HiRes qw(usleep);

use constant TRUE  => 1;
use constant FALSE => 0;
use constant SESSION_SERVICE_KEY => '_solstice_session_service';
use constant MAX_SUBSESSION_LOAD_ATTEMPTS => 20;

# in my trials, the time/increased compression ratio was not worth increasing this
use constant COMPRESSION_LEVEL => 1;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

=item new($cookie_name, $database_name)

Constructor.  Values for C<$cookie_name> and C<$database_name> are provided by
the configuration file if they are not specified in the constructor.

=cut

sub new {
    my $pkg = shift;
    $pkg = 'Solstice::Session::' .$pkg->getConfigService()->getSessionBackend();
    Solstice->loadModule($pkg);
    my ($cookie_name) = @_;

    #We use a generic service object here instead of subclassing service to avoid 
    #any potential confusion over the fact that both Service and Session have 
    #"set" and "get" methods.                                 
    my $service = Solstice::Service->new();

    # To make it so we can support multiple sessions with different cookie names, make that session key more dynamic!
    # Get this default now...
    $cookie_name = $pkg->_getDefaultCookieName()  unless defined $cookie_name;
    my $session_service_key = SESSION_SERVICE_KEY .'___'. $cookie_name;

    if(defined $service->get($session_service_key)){
        my $cached = $service->get($session_service_key);
        return $cached;
    }else{
        my $self = $pkg->_init($cookie_name);

        #tuck this away in our service so other uses of it this click don't 
        #creat conflicts
        $service->set($session_service_key, $self);
        return $self;
    }
}

=item hasSession

Returns true if the user is reporting a session ID

=cut

sub hasSession {
    my $self = shift;
    my $cookie_name = $self->getCookieName() ? $self->getCookieName() : $self->_getDefaultCookieName();
    my $cookie = Solstice::Cookie->new($cookie_name);
    return $cookie->getValue();
}


=item getSessionID

=cut

sub getSessionID {
    my $self = shift;
    my $cookie_name = shift;
    my $session_id;

    #we're empty, so we'll need to find the id from the cookie
    $cookie_name = $self->_getDefaultCookieName() unless $cookie_name;
    my $cookie = Solstice::Cookie->new($cookie_name);
    $session_id = $cookie->getValue();

    unless( $session_id ){
        $session_id = $self->getCookie()->getValue() if defined $self->getCookie();
    }
    return $session_id;
}

=item getSubsessionID

=cut

sub getSubsessionID {
    my $self = shift;
    return defined $self->_getSubsession() ? $self->_getSubsession()->getID() : undef;
}


=item getSubsessionChainID

=cut

sub getSubsessionChainID {
    my $self = shift;
    return $self->_getSubsession()->getChainID() if defined $self->_getSubsession();
}

=item setCookie()

=cut

sub setCookie {
    my $self = shift;
    $self->{'_solstice_session_cookie'} = shift; 
}

=item getCookie()

=cut

sub getCookie {
    my $self = shift;
    return ref $self ? $self->{'_solstice_session_cookie'} : undef;
}

=item getCookieName()

=cut

sub getCookieName {
    my $self = shift;
    return $self->getCookie()->getName() if defined $self->getCookie();
    return undef;
}

=item get( $key )

=cut

sub get {
    my $self = shift;
    my $key = shift;
    return $self->_getSubsession()->{$key};
}

=item set($key , $val)

Sets the session object's passed attribute to a value.

=cut

sub set {
    my $self = shift;
    my ($key, $val) = @_;
    $self->_getSubsession()->{$key} = $val;
}

=item fields()

=cut

sub fields {
    my $self = shift;
    return keys %{$self};
}

=item setUser($person)

=cut

sub setUser {
    my $self = shift;
    my $user = shift;
    $self->{'_solstice_user'} = $user;
    $self->{'_solstice_original_user'} = $user unless defined $self->{'_solstice_original_user'};
}

=item getUser()

=cut

sub getUser {
    my $self = shift;
    return $self->{'_solstice_user'};
}


=item setOriginalUser($person)

=cut

sub setOriginalUser {
    my $self = shift;
    $self->{'_solstice_original_user'} = shift;
}

=item getOriginalUser()

=cut

sub getOriginalUser {
    my $self = shift;
    return $self->{'_solstice_original_user'};
}


=item setHasJavascript

=cut

sub setHasJavascript {
    my $self = shift;
    $self->{'_solstice_has_javascript'} = shift;
}

=item hasJavascript()

=cut

sub hasJavascript {
    my $self = shift;
    return $self->{'_solstice_has_javascript'};
}

=item getIllegalSession()

=cut

sub getIllegalSession {
    my $self = shift;
    return $self->{'_illegal_session'};
}


sub _setIllegalSession {
    my $self = shift;
    $self->{'_illegal_session'} = shift;
}


=item getLoginTime()
=cut

sub getLoginTime {
    my $self = shift;
    return $self->{'_solstice_login_time'};
}

sub setLoginTime {
    my $self = shift;
    $self->{'_solstice_login_time'} = shift;
}

=item loadSubsession()

=cut

sub loadSubsession {
    my $self = shift;
    my $chain_id = shift;
    my $load_count = shift || 0;

    $self->_setIllegalSession(FALSE);

    my $button_service = Solstice::ButtonService->new();
    my $selected_button = $button_service->getSelectedButton();

    my $subsession;

    if($selected_button){
        $subsession = Solstice::Subsession->new($selected_button->getSubsessionID());


        if ( ! defined $subsession ){
            #looks like that subsession is illegal, fall back to our latest in that chain
            #and note the fact
            $self->_setIllegalSession(TRUE);
            $subsession = Solstice::Subsession->new(
                $self->_getLatestSubsessionIDInChain($selected_button->getSubsessionChainID())
            );

            #also, make sure the button isn't used to attempt a transition or trigger any controller code
            $selected_button->setIsIllegal();

        }
        $subsession->revision() if defined $subsession;

    }elsif( $chain_id ){
        #if we've been passed a specific chain_id to work with, grab it and don't revision
        #This is for things like ajax that need to affect the session without changing user state
        $subsession = Solstice::Subsession->new(
            $self->_getLatestSubsessionIDInChain($chain_id)
        );

    }else{
        $subsession = Solstice::Subsession->new();
    }

    if (!defined $subsession) {
        # If someone is clicking rapidly on a button that blocks the back button,
        # they could end up here in between deleting the subsessions, and storing a new
        # one.  This usleep loop gives them a few more tries before we give up on loading
        # the subsession.

        # If not, they could have bookmarked a url with a button name as a param, they should probably
        # just get a fresh subsession.
        if ($load_count > MAX_SUBSESSION_LOAD_ATTEMPTS) {
            $subsession = Solstice::Subsession->new();
        }
        else {
            usleep(500);
            return $self->loadSubsession($chain_id, $load_count+1);
        }
    }

    $self->_setSubsession($subsession);
}


sub _init {
    my $pkg = shift;
    my $cookie_name = shift;

    my $session_id = $pkg->getSessionID($cookie_name);

    if (defined $session_id) {

        # This is released on store.
        $pkg->_getSessionLock($session_id);

        my $self = $pkg->_loadSessionByID($session_id);
        if( $self ){
            return $self;
        }
    }

    return $pkg->_createNewSession($cookie_name);
}

=item clear()

=cut

sub clear {
    my $self = shift;
    
    #no work to be done, no session exists to be cleared
    return TRUE unless $self->hasSession();

    my $cookie_name = $self->getCookieName();

    #clear out the cookie
    my $cookie = Solstice::Cookie->new();
    $cookie->setName($cookie_name);
    $cookie->setValue('');
    $self->setCookie($cookie);

    #finally, clear the cache that contains this session
    my $session_key = SESSION_SERVICE_KEY .'___'. $cookie_name;
    my $service = Solstice::Service->new();
    $service->set($session_key, undef);
    
    return TRUE;

}

sub store {
    my $self = shift;

    my $session_id = $self->getSessionID($self->getCookieName());
    die "Cannot store a session with no id\n" unless $session_id;

    $self->_setLatestSubsessionIDInChain($self->getSubsessionChainID(), $self->getSubsessionID());

    #pull out the subsession so it doesn't get stored along with session
    my $subsession = $self->_getSubsession();
    $self->{'_subsession'} = undef;

    $self->_store($session_id);

    $self->_releaseSessionLock($session_id);

    if ($subsession) {
        $subsession->store($self->getSessionID());
    }

    return TRUE;
}

=item deleteSubsessionChain

For use when the user should not be able to back up to a previous state.

=cut

sub deleteSubsessionChain {
    my $self = shift; 
    my $chain_id = $self->_getSubsession()->getChainID();
    $self->_getSubsession()->_deleteSubsessionsInChain($chain_id);
}

sub _setSubsession {
    my $self = shift;
    $self->{'_subsession'} = shift;
}

sub _getSubsession {
    my $self = shift;
    return $self->{'_subsession'};
}


=item _getDefaultCookieName()

=cut

sub _getDefaultCookieName {
    my $self = shift;
    return Solstice::Configure->new()->getSessionCookie() or die "No default session cookie name defined in solstice_conf.xml\n";
}

=item _generateSessionID

=cut

sub _generateSessionID {
    my $self = shift;
    return Digest::MD5::md5_hex( time().{}.rand().$$ );
}


=item _createNewSession($cookie_name)

Create a new Cookie with name $cookie_name and set it

=cut

sub _createNewSession {
    my $pkg = shift;
    my $cookie_name = shift;

    my $self = bless {}, ref $pkg || $pkg;

    my $session_id = $self->_generateSessionID();

    $pkg->_getSessionLock($session_id);

    # Expires when browser closes.
    my $cookie = Solstice::Cookie->new();
    $cookie->setName($cookie_name);
    $cookie->setValue($session_id);
    $self->setCookie($cookie);

    $self->{'_subsession_chains'} = {};

    return $self;
}

sub hasSubsessionChainByID {
    my $self     = shift;
    my $chain_id = shift;

    my $subsession_id = $self->_getLatestSubsessionIDInChain($chain_id);

    return TRUE if (defined $subsession_id);
    return FALSE;
}

sub _getLatestSubsessionIDInChain {
    my ($self, $chain_id) = @_;
    return unless $chain_id;
    return $self->{'_subsession_chains'}{$chain_id};
}

sub _setLatestSubsessionIDInChain {
    my ($self, $chain_id, $subsession_id) = @_;
    return unless defined $chain_id && defined $subsession_id;
    $self->{'_subsession_chains'}{$chain_id} = $subsession_id;
}

sub setStateTracker {
    my $self = shift;
    $self->set('__solstice_state_tracker', shift);

}

sub getStateTracker {
    my $self = shift;
    return $self->get('__solstice_state_tracker');
}

sub _loadSessionByID {
    die "_loadSessionByID must be implented in the chosen session backend subclass";
}

sub _store {
    die "_store must be implented in the chosen session backend subclass";
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
