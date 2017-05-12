package Solstice::Person;

=head1 NAME

Solstice::Person - Represents a person in the Solstice framework.

=head1 SYNOPSIS

  my $person    = Solstice::Person->new();
  $person        = Solstice::Person->new($person_id);

  my $person2   = Solstice::Person->new();
  my $equal     = $person->equals($person2);


=head1 DESCRIPTION

This object represents a person, most commonly a logged in user, or someone who is 
authorized to make use of something.

Subclassing this module is recommended for specific implementations. 

=head2 Superclass
L<Solstice::Model|Solstice::Model>

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Solstice::Database;
use Solstice::DateTime;
use Solstice::LoginRealm;
use Solstice::Service::LoginRealm;

use Digest::MD5 qw(md5_hex);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 2253 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new()

=item new($person_id)

Instantiates a new person object.  If given an id of a person,
this will return undef unless there is a person in the local 
data store matching that id.

=cut

sub new {
    my $obj = shift;
    my $input = shift;
    my $password = shift;

    my $self = $obj->SUPER::new(@_);

    if (defined $input and $input) {
        if ($self->isValidHashRef($input)) {
            $self->_initFromHash($input);
        } elsif (defined $password) {
            return undef unless $self->_initFromLogin($input, $password);
        } else {
            return undef unless $self->_initFromID($input);
        }
    }

    return $self;
}

=item store()

Saves person attributes to the datastore.  Returns TRUE on 
success, FALSE otherwise.

=cut

sub store {
    my $self = shift;

    return TRUE unless $self->_isTainted();

    unless (defined $self->getLoginName()) {
        warn "store() failed: login name is undefined ". join(' ',caller()) ."\n";
        return FALSE;
    }

    unless (defined $self->getLoginRealm()) {
        warn "store() failed: login realm is undefined". join(' ',caller()) ."\n";
        return FALSE;
    }
    
    my $id = $self->getID() || 0;
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();    
    
    if ($self->_isLoginTainted()) {
        $db->readQuery('SELECT person_id from '.$db_name.'.Person where login_name = ? AND login_realm_id = ?', $self->getLoginName(), $self->getLoginRealm()->getID());
        my $data = $db->fetchRow();
        my $person_id;
        if (defined $data) {
            $person_id = $data->{'person_id'};
        }
        
        if (defined $person_id and $person_id != $id) {
            warn "store() failed: login name exists in this login realm: ".$self->getLoginName(). " ". join(' ',caller()) ."\n";
            return FALSE;
        }
    }

    my ($date_created, $date_modified, $date_sys_modified);
    if ($id) {
        $db->writeQuery('UPDATE '.$db_name.'.Person SET login_realm_id = ?, login_name = ?, remote_key = ?, name = ?, surname = ?, email = ?, system_name = ?, system_surname = ?, system_email = ?, password = ?, date_modified = NOW() WHERE person_id = ?',
            $self->getLoginRealm()->getID(),
            $self->getLoginName(),
            $self->getRemoteKey(),
            $self->getName(),
            $self->getSurname(),
            $self->getEmail(),
            $self->getSystemName(),
            $self->getSystemSurname(),
            $self->getSystemEmail(),
            $self->_getPassword(),
            $id
        );
        $db->readQuery('SELECT date_modified FROM '.$db_name.'.Person where person_id = ?',$id);
        $date_modified = $db->fetchRow()->{'date_modified'};
        $self->_setModificationDate(Solstice::DateTime->new($date_modified));
    } else {
        $date_sys_modified = defined $self->getRemoteKey() ? 'NOW()' : 'NULL';
        $db->writeQuery('INSERT INTO '.$db_name.'.Person (login_realm_id, login_name, remote_key, name, surname, email, system_name, system_surname, system_email, password, date_created, date_modified, date_sys_modified) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), '.$date_sys_modified.')',
            $self->getLoginRealm()->getID(),
            $self->getLoginName(),
            $self->getRemoteKey(),
            $self->getName(),
            $self->getSurname(),
            $self->getEmail(),
            $self->getSystemName(),
            $self->getSystemSurname(),
            $self->getSystemEmail(),
            $self->_getPassword()
        );

        $self->_setID($db->getLastInsertID());
        $db->readQuery('SELECT date_created, date_modified, date_sys_modified FROM '.$db_name.'.Person WHERE person_id=?', $self->getID());
        my $data_ref = $db->fetchRow();
        
        $self->_setCreationDate(Solstice::DateTime->new($data_ref->{'date_created'}));
        $self->_setModificationDate(Solstice::DateTime->new($data_ref->{'date_modified'}));
        $self->_setSystemModificationDate(Solstice::DateTime->new($data_ref->{'date_sys_modified'}));
    }
    
    $self->_untaint();
    $self->_untaintLogin();
    
    return TRUE;
}

sub updateLoginDate {
    my $self = shift;
    return unless $self->getID();

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->writeQuery("UPDATE $db_name.Person SET last_login_date = NOW() WHERE person_id = ?", $self->getID());

    return TRUE;
}

=item delete()

Remove the person from the datastore.

=cut

#TODO: add is_visible attribute to solstice.Person table and refactor
# person factory & objs to honor it

=item getID()

Accessor for the person's primary key in the local datastore.

=cut

=item getLoginRealm()

Accessor for the login realm that the person authenticates against.
This allows for multiple authentication methods.

=item setLoginRealm($login_realm)

=cut

sub setLoginRealm {
    my $self = shift;
    my $login_realm = shift;

    return FALSE unless $self->_isValidLoginRealm($login_realm); 
    
    $self->_setLoginRealm($login_realm);
    $self->_taintLogin();
    
    return TRUE;
}

=item getLoginName()

Accessor for the login name of the user.  This should be whatever 
key is used to identify the user via Apache's REMOTE_USER variable.

=item setLoginName($name)

=cut

sub setLoginName {
    my $self = shift;
    my $login_name = shift;

    $self->_setLoginName($login_name);
    $self->_taintLogin();

    return TRUE;
}

# This alias exists for legacy applications.
*getUsername = *getLoginName;

=item getRemoteKey()

Returns the peron's primary key oh the realm side, if known.

=item getName()

Accessor for the person's user-selected name.

=item setName($name)

Sets the user-selected name.

=item getSurname()

Accessor for the person's user-selected surname.

=item setSurname($sur_name)

Sets the user-selected surname.

=item getEmail()

Accessor for the user-selected email.

=item setEmail($email_address)

Sets the user-selected email address.

=item getSystemName()

Accessor for the system-defined, non-editable person's name.

=item setSystemName($name)

Allows the system first name to be set, this should not be chosen 
by the user.

=item getSystemSurname()

Accessor for the system-defined, non-editable person's surname.

=item setSystemSurname($sur_name)

Allows the system surname to be set, this should not be chosen 
by the user.

=item getSystemEmail()

Accessor for the system-defined, non-editable person's email 
address.

=item setSystemEmail($email_address)

Allows the system email address to be set, this should not be 
chosen by the user.

=item getCreationDate()

Returns a Solstice::DateTime that represents the date the Person 
was first stored.

=cut

sub getCreationDate {
    my $self = shift;
    return $self->_getCreationDate() if defined $self->_getCreationDate();
    $self->_setCreationDate(Solstice::DateTime->new($self->_getCreationDateStr()));
    return $self->_getCreationDate();
}

=item getModificationDate()

Returns a Solstice::DateTime that represents the date the Person 
was last stored, with changes.

=cut

sub getModificationDate {
    my $self = shift;
    return $self->_getModificationDate() if defined $self->_getModificationDate();
    $self->_setModificationDate(Solstice::DateTime->new($self->_getModificationDateStr()));
    return $self->_getModificationDate();
}

=item getSystemModificationDate()

Returns a Solstice::DateTime that represents the date the Person 
was last stored by an automated system.

=cut

sub getSystemModificationDate {
    my $self = shift;
    return $self->_getSystemModificationDate() if defined $self->_getSystemModificationDate();
    $self->_setSystemModificationDate(Solstice::DateTime->new($self->_getSystemModificationDateStr()));
    return $self->_getSystemModificationDate();
}

=item equals($person)

Returns TRUE if the passed $person obj represents the same person 
as $self, FALSE otherwise.

=cut

sub equals {
    my $self = shift;
    my $person = shift;

    unless (defined $person) {
        warn 'equals(): $person arg is not defined!', return;
    }

    return TRUE if (defined $self->getID() && defined $person->getID() && $self->getID() == $person->getID());
    
    return FALSE unless (defined $self->getLoginRealm() && defined $person->getLoginRealm() && $self->getLoginRealm()->getID() == $person->getLoginRealm()->getID());
    
    return FALSE unless (defined $self->getLoginName() && defined $person->getLoginName() && $self->getLoginName() eq $person->getLoginName());
    
    return TRUE;
}


=item setPassword($password)

Allows the user's password to be set. Note that this may not be 
necessary, depending on the AuthN method.

=cut

sub setPassword {
    my $self = shift;
    my $password = shift;
    my $login = $self->getLoginName();
    $self->_taint();

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->writeQuery("UPDATE $db_name.Person SET password_reset_ticket = NULL WHERE person_id = ?", $self->getID());

    $self->{'_password'} = md5_hex("$login:$password");
}

=item hasPassword 

=cut

sub hasPassword {
    my $self = shift;
    return $self->{'_password'} ? TRUE : FALSE;
}

=item checkPasswordResetTicket($str)

=cut

sub checkPasswordResetTicket {
    my $self = shift;
    my $encrypted = shift;

    #don't want this to hang around in memory, so...
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    my $crypt = Solstice::Encryption->new();
    my $decrypted;
    eval{
        $decrypted = $crypt->decryptHex($encrypted);
    };
    return FALSE unless $decrypted;
    my ($id, $ticket) = split(/-/, $decrypted);

    return FALSE unless $self->getID() && $self->getID() == $id;

    $db->readQuery("SELECT password_reset_ticket FROM $db_name.Person WHERE person_id = ?", $self->getID());
    my $dbticket = $db->fetchRow()->{'password_reset_ticket'};

    return $dbticket eq $ticket ? TRUE : FALSE;
}

=item getPasswordResetTicket()

=cut

sub getPasswordResetTicket {
    my $self = shift;

    return FALSE unless $self->getID();

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    my $crypt = Solstice::Encryption->new();

    my $ticket = rand();

    $db->writeQuery("UPDATE $db_name.Person SET password_reset_ticket = ? WHERE person_id = ?", $ticket, $self->getID());

    return $crypt->encryptHex($self->getID() .'-'. $ticket);
}

=back

=head2 Output Methods

=over 4

=cut

=item getScopedLoginName()

Returns the loginname, scoped to the identity provider.  e.g., joe@washington.edu, joe@idp.protectnetwork.org.

=cut

sub getScopedLoginName {
    my $self = shift;
    my $login_name = $self->getLoginName();

    return $self->getLoginRealm()->getScopedLoginName($login_name);
}

=item getFullName($delimiter)

Returns a full name for the person, created from whatever data 
we have available. A delimiter can be specified, default is a single 
space.

=cut

sub getFullName {
    my $self = shift;
    my $delimiter = shift || ' ';
    return join($delimiter, @{$self->_getNameTokens()});
}

=item getSystemFullName($delimiter)

=cut

sub getSystemFullName {
    my $self = shift;
    my $delimiter = shift || ' ';
    return join($delimiter, @{$self->_getSystemNameTokens()});
}

=item getReverseFullName($delimiter)

Returns a full name for the person, created from whatever data 
we have available. A delimiter can be specified. 

=cut

sub getReverseFullName {
    my $self = shift;
    my $delimiter = shift || ', ';
    return join($delimiter, reverse @{$self->_getNameTokens()});
}

=item getReverseSystemFullName($delimiter)

Returns a full name for the person, using system data. A delimiter 
can be specified. 

=cut

sub getReverseSystemFullName {
    my $self = shift;
    my $delimiter = shift || ', ';
    return join($delimiter, reverse @{$self->_getSystemNameTokens()});
}

=item getMoniker()

Returns a name string, using best available data.

=cut

sub getMoniker {
    my $self = shift;
    my $fullname = $self->getFullName();
    return ($fullname eq '') ? $self->getLoginName() : $fullname;
}

=item getSystemMoniker()

Returns a name string, using best available system data.

=cut

sub getSystemMoniker {
    my $self = shift;
    my $fullname = $self->getSystemFullName();
    return ($fullname eq '') ? $self->getLoginName() : $fullname;
}

=item getFullMoniker()

Returns a name string, using best available data.

=cut

sub getFullMoniker {
    my $self = shift;
    my $fullname = $self->getFullName();
    return $self->getLoginName() if $fullname eq '';
    return $fullname.' ('.$self->getScopedLoginName().')';
}

=item getEmailAddress()

Returns an email address, falling back on system info if necessary.

=cut

sub getEmailAddress {
    my $self = shift;
    return $self->getEmail() || $self->getSystemEmail() || '';
}

=back

=head2 Private Methods

=over 4

=cut

=item _getNameTokens()

Return an array ref of person name tokens.

=cut

sub _getNameTokens {
    my $self = shift;
   
    my $list = $self->_getUserNameTokens();
    return $list if @$list;

    $list = $self->_getSystemNameTokens();
    return $list if @$list;

    return [];
}

=item _getUserNameTokens {

Return an array ref of person name tokens, or undef.

=cut

sub _getUserNameTokens {
    my $self = shift;

    my $name  = $self->getName();
    my $sname = $self->getSurname();

    my @list = ();
    if ((defined $name && $name ne '') || (defined $sname && $sname ne '')) {
        push @list, $name if (defined $name && $name ne '');
        push @list, $sname if (defined $sname && $sname ne '');
        return \@list;
    }
    return \@list;
}

=item _getSystemNameTokens {

Return an array ref of person name tokens, or undef.

=cut

sub _getSystemNameTokens {
    my $self = shift;
    
    my $name  = $self->getSystemName();
    my $sname = $self->getSystemSurname();

    my @list = ();
    if ((defined $name && $name ne '') || (defined $sname && $sname ne '')) {
        push @list, $name if (defined $name && $name ne '');
        push @list, $sname if (defined $sname && $sname ne '');
    }
    return \@list;
}

=item _initFromLogin($username, $password)

Initializes a Person based on login information, if it is correct.

=cut

sub _initFromLogin {
    my $self = shift;
    my $username = shift;
    my $password = shift;

    return FALSE unless (defined $username && defined $password);

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery('SELECT p.*, lr.package
        FROM '.$db_name.'.Person AS p, '.$db_name.'.LoginRealm AS lr 
        WHERE p.login_realm_id = lr.login_realm_id AND p.login_name = ? 
            AND p.password = ?',
        $username, md5_hex("$username:$password"));

    my $data_ref = $db->fetchRow();
    return FALSE unless defined $data_ref;
    return FALSE unless defined $data_ref->{'person_id'};

    return $self->_initFromHash($data_ref);
}

=item _initFromID($person_id)

Initializes the person from the database. 

=cut

sub _initFromID {
    my $self = shift;
    my $input = shift;

    return FALSE unless $self->isValidInteger($input);
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery('SELECT p.*, lr.login_realm_id
        FROM '.$db_name.'.Person AS p, '.$db_name.'.LoginRealm AS lr 
        WHERE p.login_realm_id = lr.login_realm_id AND p.person_id = ?',
        $input);

    my $data_ref = $db->fetchRow();
    return FALSE unless defined $data_ref->{'person_id'};

    return $self->_initFromHash($data_ref);
}

=item _initFromHash(\%hash)

Does a minimal initialization, with data from an outside source.

=cut

sub _initFromHash {
    my $self = shift;
    my $input = shift;

    my $login_realm = $input->{'login_realm'};
    unless (defined $login_realm) {
        my $service = Solstice::Service::LoginRealm->new();
        $login_realm = $service->getByID($input->{'login_realm_id'});
        return FALSE unless defined $login_realm;
    }

    $self->_setID($input->{'person_id'});
    $self->_setLoginRealm($login_realm);
    $self->_setLoginName($input->{'login_name'});
    $self->_setRemoteKey($input->{'remote_key'});
    $self->_setSystemName($input->{'system_name'});
    $self->_setSystemSurname($input->{'system_surname'});
    $self->_setSystemEmail($input->{'system_email'} || undef);
    $self->_setName($input->{'name'});
    $self->_setSurname($input->{'surname'});
    $self->_setEmail($input->{'email'} || undef);
    $self->_setPassword($input->{'password'});

    # hash inits set date strings into the person object, to
    # be converted into DateTime objects later
    $self->_setCreationDateStr($input->{'date_created'});
    $self->_setModificationDateStr($input->{'date_modified'});
    $self->_setSystemModificationDateStr($input->{'date_sys_modified'});
    
    return TRUE;    
}

=item _isValidLoginRealm($obj)

=cut

sub _isValidLoginRealm {
    my $self = shift;
    my $obj  = shift;
    return TRUE if (!defined $obj);
    return (UNIVERSAL::isa($obj, 'Solstice::LoginRealm')) ? TRUE : FALSE;
}

=item _taintLogin()

=cut

sub _taintLogin {
    my $self = shift;
    $self->{'_login_tainted'} = TRUE;
    $self->_taint();
    return;
}

=item _untaintLogin()

=cut

sub _untaintLogin {
    my $self = shift;
    delete $self->{'_login_tainted'};
    return;
}

=item _isLoginTainted()

=cut

sub _isLoginTainted {
    my $self = shift;
    return $self->{'_login_tainted'};
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'LoginRealm',
            key  => '_login_realm',
            type => 'Solstice::LoginRealm',
            taint => TRUE,
        },
        {
            name => 'LoginName',
            key  => '_login_name',
            type => 'String',
            taint => TRUE,
        },
        {
            name => 'Name',
            key  => '_name',
            type => 'String',
            taint => TRUE,
        },
        {
            name => 'Surname',
            key  => '_sur_name',
            type => 'String',
            taint => TRUE,
        },
        {
            name => 'Email',
            key  => '_email',
            type => 'Email',
            taint => TRUE,
        },
        {
            name => 'RemoteKey',
            key  => '_remote_key',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'SystemName',
            key  => '_system_name',
            type => 'String',
            taint => TRUE,
        },
        {
            name => 'SystemSurname',
            key  => '_system_sur_name',
            type => 'String',
            taint => TRUE,
        },
        {
            name => 'SystemEmail',
            key  => '_system_email',
            type => 'Email',
            taint => TRUE,
        },
        {
            name        => 'Password',
            key         => '_password',
            type        => 'String',
            private_get => TRUE,
        },
        {
            name => 'CreationDate',
            key  => '_creation_date',
            type => 'DateTime',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'ModificationDate',
            key  => '_modification_date',
            type => 'DateTime',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'SystemModificationDate',
            key  => '_system_modification_date',
            type => 'DateTime',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'CreationDateStr',
            key  => '_creation_date_str',
            type => 'String',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'ModificationDateStr',
            key  => '_modification_date_str',
            type => 'String',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'SystemModificationDateStr',
            key  => '_system_modification_date_str',
            type => 'String',
            private_set => TRUE,
            private_get => TRUE,
        },
    ];
}

1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $



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
