package Solstice::Factory::Person;

=head1 NAME

Solstice::Factory::Person

=head1 SYNOPSIS

my $person_factory = Solstice::Factory::Person->new();

my $person = $person_factory->createById($person_id);

my $person_list = $person_factory->createByIds(\@people_ids);

# This method has the potential to create new entries in the data store.
my $person_list = $person_factory->createByLogins(['pmichaud', 'mcrawfor@washington.edu', 'jlaney@u.washington.edu']);

my $person = $person_factory->createLoggedInUser();

=head1 DESCRIPTION

Thiss object has the ability to create people.  This turns out to be rather useful, as a given person could have for it's package any number of possible classes. 

In addition to keeping programmers out of the sausage factory of person creation, this also allows you to create a large list of people very quickly.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Factory);

use Solstice::Database;
use Solstice::List;
use Solstice::Person;
use Solstice::Service::LoginRealm;

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item createByIDs(\@list)

=cut

sub createByIDs {
    my $self = shift;
    my $ids  = shift;
    my $list = Solstice::List->new();

    return $list unless defined $ids;
    return $list unless @$ids;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    my $in_ids_placeholder = join ',', map { '?' } @$ids;

    return $list unless $in_ids_placeholder;

    $db->readQuery('SELECT *
        FROM '.$db_name.'.Person
            WHERE person_id IN ('.$in_ids_placeholder.')', @$ids);

    my $lr_service = Solstice::Service::LoginRealm->new();

    while (my $person_data = $db->fetchRow()) {
        my $login_realm = $lr_service->getByID($person_data->{'login_realm_id'});
        next unless defined $login_realm;

        $person_data->{'login_realm'} = $login_realm;

        my $person = Solstice::Person->new($person_data);

        $list->push($person);
    }

    return $list;
}

=item createByLogin($login_name)

Returns a Person object.  If they don't already exist, they will be created.

=cut

sub createByLogin {
    my $self  = shift;
    my $login = shift;
    return $self->createByLogins([$login])->shift();
}

=item getByLogin($login_name)

Returns a person object for the login name, if it already exists in our database.

=cut

sub getByLogin {
    my $self   = shift;
    my $login = shift;

    my $lr_service = Solstice::Service::LoginRealm->new();

    my $login_name = $lr_service->getLoginNameForLogin($login);
    return unless defined $login_name;
    
    my $login_realm = $lr_service->getByLogin($login);
    return unless defined $login_realm;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery('SELECT *
        FROM '.$db_name.'.Person WHERE login_realm_id = ?
        AND login_name = ?',
        $login_realm->getID(), $login_name);

    if (my $person_data = $db->fetchRow()) {
        $person_data->{'login_realm'} = $login_realm;
        return Solstice::Person->new($person_data);
    }

    return;
}

=item createByLogin(\@login_names)

=cut

sub createByLogins {
    my $self   = shift;
    my $logins = shift;
    my $list   = Solstice::List->new();

    return $list unless (defined $logins and @$logins);

    my $login_realm_data = {};
    my $uncreated_users  = {};

    my $lr_service = Solstice::Service::LoginRealm->new();

    foreach my $login (@$logins) {
        my $login_name = $lr_service->getLoginNameForLogin($login);
        next unless defined $login_name;

        my $login_realm = $lr_service->getByLogin($login);
        next unless defined $login_realm;
        
        my $lr_id = $login_realm->getID();

        push @{$login_realm_data->{$lr_id}}, $login_name;

        # Track these for creation later, and stash the login realm away 
        # for use when querying to see who currently exists.
        $uncreated_users->{$lr_id}->{$login_name} = $login_realm;
    }

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    foreach my $login_realm_id (keys %$login_realm_data) {
        my @login_names = @{$login_realm_data->{$login_realm_id}};

        my $placeholders = join(',', map{ '?' } @login_names);

        if ($placeholders) {
            $db->readQuery('SELECT *
                FROM '.$db_name.'.Person WHERE login_realm_id = ?
                AND login_name IN ('.$placeholders.')',
                $login_realm_id, @login_names);

            while (my $person_data = $db->fetchRow()) {
                my $lr_id = $person_data->{'login_realm_id'};
                my $login_name = $person_data->{'login_name'};

                my $login_realm = $uncreated_users->{$lr_id}->{$login_name};
                $person_data->{'login_realm'} = $login_realm;

                my $person = Solstice::Person->new($person_data);

                delete $uncreated_users->{$lr_id}->{$login_name};
                $list->push($person);
            }
        }
    }

    foreach my $login_realm_id (keys %$uncreated_users) {

        my @person_insert_values;
        my @person_insert_placeholders;
        my @person_select_placeholders;
        my @person_select_values;
        my $login_realm;
        my $login_names;
        my %created_users;
        foreach my $login_name (keys %{$uncreated_users->{$login_realm_id}}) {
            if (!defined $login_realm) {
                $login_realm = $uncreated_users->{$login_realm_id}->{$login_name};
                push @$login_names, $login_name;
            }
        }

        # Short circuit and work if there are no members
        next unless defined $login_realm;

        my $system_data_lookup = $login_realm->getSystemDataForLogins($login_names);
        foreach my $login_name (keys %{$uncreated_users->{$login_realm_id}}) {
            my $system_data = $system_data_lookup->{$login_name} || {};

            my $person = Solstice::Person->new();
            $person->_setLoginRealm($login_realm);
            $person->_setLoginName($login_name);
            $person->_setRemoteKey($system_data->{'remote_key'});
            $person->_setSystemName($system_data->{'system_name'});
            $person->_setSystemSurname($system_data->{'system_surname'});
            $person->_setSystemEmail($system_data->{'system_email'});
            $created_users{$login_name} = $person;

            $login_name        = $login_name;
            my $remote_key     = $system_data->{'remote_key'};
            my $system_name    = $system_data->{'system_name'};
            my $system_surname = $system_data->{'system_surname'};
            my $system_email   = $system_data->{'system_email'};
            my $date_sys_modified = (defined $system_data->{'remote_key'}) ? 'NOW()' : 'NULL';

            push @person_insert_values, ($login_realm_id, $login_name, $remote_key, $system_name, $system_surname, $system_email);
            push @person_insert_placeholders, "(?, ?, ?, ?, ?, ?, NOW(), NOW(), $date_sys_modified)";
            push @person_select_values, ($login_name);
            push @person_select_placeholders, '?';

        }

        my $person_select_placeholder = join(',', @person_select_placeholders);
        my $person_insert_placeholder = join(',', @person_insert_placeholders);

        if (@person_insert_values) {
            $db->writeQuery('INSERT INTO '.$db_name.'.Person (
                    login_realm_id, login_name, remote_key, system_name, 
                    system_surname, system_email, date_created, date_modified,
                    date_sys_modified) 
                VALUES '. $person_insert_placeholder, @person_insert_values);
            
            $db->readQuery('SELECT *
                FROM '.$db_name.'.Person
                WHERE login_realm_id = ?
                    AND login_name IN ('.$person_select_placeholder.')',
                $login_realm_id, @person_select_values);

            while (my $new_person = $db->fetchRow()) {
                my $person = $created_users{$new_person->{'login_name'}};
                $person->_setID($new_person->{'person_id'});
                $person->_setCreationDateStr($new_person->{'date_created'});
                $person->_setModificationDateStr($new_person->{'date_modified'});
                $person->_setSystemModificationDateStr($new_person->{'date_sys_modified'});
                $list->push($person);
            }
        }
    }

    return $list;
}

=item getAllLoginNamesByDate(\%params)

Returns a list of Person objects, one for each member of the login realm.

=cut

sub getAllLoginNamesByDate {
    my $self = shift;
    my $params = shift;

    my $login_realm = $params->{'login_realm'};
    my $logged_in_after_date = $params->{'last_login_date'};
    my $created_after_date = $params->{'created_after_date'};

    my $config = $self->getConfigService();

    return [] unless defined $login_realm;
    #both dates or no dates must be defined to make a query
    return [] if defined $logged_in_after_date && !defined $created_after_date;

    my $login_realm_id = $login_realm->getID();
    my $db_name = $config->getDBName();

    my $where = 'WHERE login_realm_id = ?';
    $where .= 'AND ((last_login_date IS NULL AND date_created > ?) OR last_login_date > ?)' if $logged_in_after_date;

    my $db_params;

    push @$db_params, $login_realm_id;
    push @$db_params, $created_after_date->toSQL() if $created_after_date;
    push @$db_params, $logged_in_after_date->toSQL() if $logged_in_after_date;

    my $db = Solstice::Database->new();
    $db->readQuery("SELECT login_name, date_created FROM $db_name.Person $where", @$db_params);

    my @names = ();
    while (my $data = $db->fetchRow()) {
        push @names, $data->{'login_name'};
    }
    return \@names;
}


1;

__END__

=back

=head1 AUTHOR

Educational Technology Development Group E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 597 $

=head1 SEE ALSO

L<Solstice::List|Solstice::List>.

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
