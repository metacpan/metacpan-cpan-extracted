package Solstice::LoginRealm;

=head1 NAME

Solstice::LoginRealm - Represents a person login realm.

=head1 SYNOPSIS

=head1 DESCRIPTION

This object exists as a superclass for specific person login realm objects

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 2253 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new([\%input])

=cut

sub new {
    my $obj = shift;
    my $input = shift;

    my $self = $obj->SUPER::new();
    
    if (defined $input && $self->_isValidHashRef($input)) {
        return undef unless $self->_initFromHash($input);
    } else {
        $input = 'undef' unless defined $input; # Just for the msg.
        die ((ref $self). ": Improper argument passed to new(): $input\n");
    }
    
    return $self;
}

=item getSystemDataForLogin($login_name)

=cut

sub getSystemDataForLogin {
    my $self = shift;
    my $login_name = shift;

    my $hash_ref = $self->getSystemDataForLogins([$login_name]);
    return $hash_ref->{$login_name} || {};
}

=item getSystemDataForLogins(\@login_names)

=cut

sub getSystemDataForLogins {
    warn "getSystemDataForLogins(): Not implemented";
    return {};
}

=item setPersonDataOnLogin($person)

If applicable, a login realm can set information, such as system name or email, on login.  This is mainly useful for login realms that pull values from ENV.

=cut

sub setPersonDataOnLogin {
    return;
}

=item isValidLogin($login_name)

Returns TRUE by default. This method can be subclassed to provide a set
of criteria used to allow logins access to solstice applications.

=cut

sub isValidLogin {
    return TRUE;
}

=item isValidAccountName($login_name)

Returns TRUE by default. This method can be subclassed if there are 
login_name patterns that are simply invalid.

=cut

sub isValidAccountName {
    return TRUE;
}

=item getEmailAddress($login_name)

Returns a version of the username as an email address. Must be implemented
in a subclass.

=cut

sub getEmailAddress {
    return;
}

=item getScopedLoginName($login_name)

Returns the login name, scoped to the login realm. Can be subclassed to return
something other than the passed $login_name.

=cut

sub getScopedLoginName {
    return $_[1];
}

=item isActiveLogin($time)

Decides if the current login is active, based on the time.  If this returns FALSE, the user will be forced to reauthenticate.  Defaults to never timing out a login.

=cut

sub isActiveLogin {
    return TRUE;
}

=back

=head2 Private Methods

=over 4

=cut

=item _initFromHash(\%data)

=cut

sub _initFromHash {
    my $self = shift;
    my $data = shift;

    return FALSE unless defined $data->{'login_realm_id'};

    unless (defined $data->{'package'} and ($data->{'package'} eq $self->getClassName())) {
        warn 'Incorrect package name: '.$data->{'package'};
        return FALSE;
    }

    $self->_setID($data->{'login_realm_id'});
    $self->_setName($data->{'name'});
    $self->_setDescription($data->{'description'});
    $self->_setDisplayName($data->{'display_name'});
    $self->_setContactName($data->{'contact_name'});
    $self->_setContactEmail($data->{'contact_email'});
    $self->_setScope($data->{'scope'});
    
    return TRUE;
}

=item getRemoteGroupControllerPackage()
=cut

sub getRemoteGroupControllerPackage {
    return;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'Name',
            key  => '_name',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'Description',
            key  => '_description',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'DisplayName',
            key  => '_display_name',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'ContactName',
            key  => '_contact_name',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'ContactEmail',
            key  => '_contact_email',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'Scope',
            key  => '_scope',
            type => 'String',
            private_set => TRUE,
        },
    ];
}


1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$ Revision: $



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
