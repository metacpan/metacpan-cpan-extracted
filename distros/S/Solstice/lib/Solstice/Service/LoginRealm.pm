package Solstice::Service::LoginRealm;

# $Id: LoginRealm.pm 2257 2005-05-19 17:31:38Z jlaney $

=head1 NAME

Solstice::Service::LoginRealm - Provides mapping between user login and login realm objects.

=head1 SYNOPSIS

    use Solstice::Service::LoginRealm;

    my $service = Solstice::Service::LoginRealm->new();
   
    # Three ways to get a login realm...
    my $login_realm = $service->getByID('5');
    
    $login_realm = $service->getByScope('washington.edu');
    
    $login_realm = $service->getByLogin('jsmith@washington.edu'); 
   
    my $login_name = $service->getLoginNameForLogin('jsmith@washington.edu');
    # returns 'jsmith'
    
    my $scope = $service->getScopeForLogin('jsmith@u.washington.edu');
    # returns 'washington.edu'

    # Get the current user login
    my $login = $service->getLogin();

=head1 DESCRIPTION

Solstice::Service::LoginRealm is a service for getting a login realm object
for a given login string.

Several other methods are also provided which are designed to be overridable 
in a subclass:

getLoginNameForLogin() returns the login name for a login string.
getScopeForLogin() returns the scope for a login string.

Finally, getLogin() returns the login of the currently logged-in user.

=cut

use 5.006_000;
use strict;
use warnings;

use constant TRUE  => 1;
use constant FALSE => 0;

use base qw(Solstice::Service::Memory);

use Solstice::Database;

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item new()

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_init();
    
    return $self;
}

=item getByScope($scope)

Returns a login realm identified by the passed $scope string.

=cut

sub getByScope {
    my $self  = shift;
    my $scope = shift;

    $scope = '' unless defined $scope;

    return $self->get('scope_lookup')->{$scope};
}

=item getByID($id)

Returns a login realm identified by the passed $id.

=cut

sub getByID {
    my $self = shift;
    my $id   = shift;
    
    return unless defined $id;

    return $self->get('id_lookup')->{$id};
}

=item getByLogin($login)

Returns a login realm identified by the passed $login string.

=cut

sub getByLogin {
    my $self  = shift;
    my $login = shift;

    return unless defined $login;

    return $self->getByScope($self->_toScope($login));
}

=item getLoginNameForLogin($login)

Returns the login name for the passed $login string.

=cut

sub getLoginNameForLogin {
    my $self  = shift;
    my $login = shift;

    return unless defined $login;

    return $self->_toName($login);
}
    
=item getScopeForLogin($login)

Returns the login realm scope for the passed $login string.

=cut

sub getScopeForLogin {
    my $self  = shift;
    my $login = shift;

    return unless defined $login;

    my $scope = $self->_toScope($login); 
   
    # Normalize login realm scope synonyms
    if (my $login_realm = $self->get('scope_lookup')->{$scope}) {
        return $login_realm->getScope();
    }

    # Not a supported scope
    return $scope;
}

=item getLogin()

Returns the current user login, in this implementation from $ENV{REMOTE_USER}.
Only accessible in an auth container, does not look at the user in session.

=cut

sub getLogin {
    return $ENV{'REMOTE_USER'};
}

=back

=head2 Private Methods

=over 4

=cut

# Overridable $login parsing methods
sub _toScope {
    my $self = shift;
    return (split(/[\@\:]/, shift))[1] || '';
}

sub _toName {
    my $self = shift;
    return (split(/[\@\:]/, shift))[0];
}

=item _init()

=cut

sub _init {
    my $self = shift;

    return if $self->get('login_realms_initialized');

    my $db = Solstice::Database->new();
    my $dbname = $self->getConfigService()->getDBName();

    my %id_lookup;
    my %scope_lookup;

    # LoginRealm data will be used to populate the ID and scope lookups
    $db->readQuery("SELECT * FROM $dbname.LoginRealm");
    while (my $data = $db->fetchRow()) {
        my $scope = $data->{'scope'} || '';

        if (defined $scope_lookup{$scope}) {
            die "Duplicate login realm scope $scope";
        }

        my $package = $data->{'package'};
        eval {
            $self->loadModule($package);
        };
        if ($@) {
            warn "Can't load package '$package' for login realm '$scope'\n";
        }
        else {
            my $login_realm = $package->new($data);

            $scope_lookup{$scope} = $login_realm;
            $id_lookup{$data->{'login_realm_id'}} = $login_realm;
        }
    }

    # Fetch the login realm scope synonyms and add them to the scope lookup
    $db->readQuery("SELECT * FROM $dbname.LoginRealmSynonym");
    while (my $data = $db->fetchRow()) {
        my $scope = $data->{'scope'};
        $scope = '' unless defined $scope;

        if (defined $scope_lookup{$scope}) {
            die "Duplicate login realm scope $scope";
        }
        
        $scope_lookup{$scope} = $id_lookup{$data->{'login_realm_id'}};
    }

    $self->set('id_lookup', \%id_lookup);
    $self->set('scope_lookup', \%scope_lookup);

    $self->set('login_realms_initialized', TRUE);

    return;
}

1;

__END__

=back

=head1 AUTHOR

Educational Technology Development Group E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 597 $

=head1 SEE ALSO

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
