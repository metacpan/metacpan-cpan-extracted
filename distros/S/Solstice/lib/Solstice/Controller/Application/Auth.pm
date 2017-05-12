package Solstice::Controller::Application::Auth;

# $Id: Auth.pm 3375 2006-05-12 23:03:35Z jdr99 $


=head1 NAME

Solstice::Controller::Application::Auth - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Controller::Application);

use Solstice::Server;
use Solstice::Session;
use Solstice::CGI qw(param getURLParams);
use Solstice::StringLibrary qw(unrender);
use Solstice::Service::LoginRealm;
use Digest::MD5 qw(md5_hex);

use constant TRUE  => 1;
use constant FALSE => 0;

=head2 Superclass

L<Solstice::Controller::Application|Solstice::Controller::Application>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item hasUserAuth()

=cut

sub hasUserAuth {
    my $self = shift;

    my $session = Solstice::Session->new();
    my $login_time = $session->getLoginTime() || time;

    if (my $user = $self->getUserService()->getUser()) {
        my $login_realm = $user->getLoginRealm();
        return $login_realm->isActiveLogin($login_time);
    }
    return FALSE;
}

=item requiresUserLogin()

=cut

sub requiresUserLogin {
    my $self = shift;

    if (!$self->hasUserAuth()) {
        $self->getAuthentication();
        return TRUE;
    }
    else {
        my $user = $self->getUserService()->getUser();
    }
    return FALSE;
}

=item getAuthentication()

=cut

sub getAuthentication {
    my $self = shift;

    my $inputs;
    my $params = param();
    foreach my $key (keys %$params) {
        my @values = param($key);
        $inputs->{$key} = \@values;
    }

    my $session = Solstice::Session->new();

    # Use Time::HiRes?
    my $data_key = md5_hex(time.rand().$ENV{'SERVER_ADDR'});

    my $auth_persist = $session->{'_auth_persistence'} || {};

    # Chance of a collision - 1 in a million?
    $auth_persist->{$data_key} = {  
        uri    => $ENV{'REQUEST_URI'},
        params => $inputs,
    };

    $session->{'_auth_persistence'} = $auth_persist;

    my $auth_url = $self->makeURL(
        $self->getBaseURL(),
        '_auth/',
        $data_key
    );
    

    my $label = $self->getLangService()->getString('clickthrough_no_javascript');
    
    my $server = Solstice::Server->new();
    $server->setContentType('text/html; charset=UTF-8');
    $server->printHeaders();

    print qq|<html><head></head><body>
    <script type="text/javascript">window.location.href = '$auth_url';</script>
    <a href="$auth_url">$label</a>
    </body></html>|;
}

=item hasAuthenticated()

=cut

sub hasAuthenticated {
    my $self = shift;

    my $session = Solstice::Session->new();

    my $auth_persist = $session->{'_auth_persistence'} || {};

    my $data_key = param('__solstice_param_key');

    return FALSE unless defined $data_key;

    my $data = $auth_persist->{$data_key};

    if (exists $auth_persist->{$data_key} && !defined $data) {
        return TRUE;
    }
    return FALSE;
}

=item processAuthentication()

=cut

sub processAuthentication {
    my $self = shift;

    my ($data_key, $test) = getURLParams();

    unless (defined $data_key) {
        my $ns_service = Solstice::NamespaceService->new();
        my $app_config = Solstice::Configure->new($ns_service->getAppNamespace());

        my $server = Solstice::Server->new();
        $server->setStatus(404);
        $server->setContentType('text/html');
        $server->printHeaders();
        my $error_html = $self->getConfigService()->getErrorHTML();
        print $error_html || 'Solstice has experienced an error.';
        return FALSE;

    }

    my $session = Solstice::Session->new();

    # Force initialization of logged-in user. 
    my $user = $self->getUserService()->getUser;
    my $current_login = Solstice::Service::LoginRealm->new()->getLogin();
    my $current_person = Solstice::Factory::Person->new()->createByLogin($current_login);
    
    my $auth_persist = $session->{'_auth_persistence'} || {};
    my $persisted_data = $auth_persist->{$data_key};

    if (!$user || !$user->equals($current_person)) {
        #if we don't have a user, or if we have a different user in session than is 'logged in' we need to clear out our session and bounce them
        $session->clear();
        $persisted_data = {
            uri => $self->getBaseURL(),
            params => {},
        };
    }

    my $login_realm = $user->getLoginRealm();
    $login_realm->setPersonDataOnLogin($user);

    $session->setLoginTime(time);


    unless (defined $persisted_data && %$persisted_data) {
        # If there's no persisted data, send them to the home screen and hope that's good enough...
        $persisted_data = {
            uri => $self->getBaseURL(),
            params => {},
        };
    }

    my $url    = $persisted_data->{'uri'};
    my $params = $persisted_data->{'params'};

    my $str = '';
    for my $key (keys %$params) {
        my $values = $params->{$key} || [];
        my $name = unrender($key);
        for my $value (@$values) {
            $value = unrender($value); 
            $str .= qq|<input type="hidden" name="$name" value="$value"/>\n|;
        }
    }
    $str .= qq|<input type="hidden" name="__solstice_param_key" value="$data_key"/>\n|;

    # Do not delete the key, since we need to see if we've bounced through 
    # auth already. This is useful when there's no login realm for a user, 
    # otherwise it's an infinite bounce loop
    $auth_persist->{$data_key} = undef;

    $session->{'_auth_persistence'} = $auth_persist;

    my $label = $self->getLangService()->getString('clickthrough_no_javascript');

    my $server = Solstice::Server->new();
    $server->setContentType('text/html; charset=UTF-8');
    $server->printHeaders();

    print qq|<html><head></head><body onload="window.history.forward()">
    <form method="post" action="$url" id="auth_form">
        $str
        <noscript><input type="submit" value="$label"/></noscript>
    </form>
    <script type="text/javascript">window.setTimeout(function() { document.getElementById('auth_form').submit(); }, 1);</script>
    </body></html>|;
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::Controller::Application|Solstice::Controller::Application>,
L<Solstice::Session|Solstice::Session>,
L<Solstice::CGI|Solstice::CGI>,
L<Time::HiRes|Time::HiRes>.

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
