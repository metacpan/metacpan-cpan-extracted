package Solstice::PersonFactory;

=head1 NAME

Solstice::PersonFactory - 

=head1 SYNOPSIS

=head1 DESCRIPTION

This package is deprecated. Use Solstice::Factory::Person instead.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::Database;
use Solstice::Person;
use Solstice::Factory::Person;
use Solstice::Service::LoginRealm;

our ($VERSION) = ('$Revision: 2253 $' =~ /^\$Revision:\s*([\d.]*)/);

use constant TRUE     => 1;
use constant FALSE    => 0;

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub createByID {
    my $self = shift;
    return $self->createByIDs([shift])->[0];
}

*createById = *createByID;

sub createByLogin {
    my $self = shift;
    return $self->createByLogins([shift])->[0];
}

=item isValidLogin($login)

Returns true if the login specified is a username in the 
current realm, false otherwise.

=cut

sub isValidLogin {
    my $self = shift;
    my $login = shift;

    my $lr_service = Solstice::Service::LoginRealm->new();
    
    my $login_name = $lr_service->getLoginNameForLogin($login);
    return FALSE unless defined $login_name;
    
    my $login_realm = $lr_service->getByLogin($login);
    return FALSE unless defined $login_realm;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery('SELECT person_id
        FROM '.$db_name.'.Person
        WHERE login_realm_id = ? AND login_name = ?',
        $login_realm->getID(), $login_name);

    my $valid_entry = $db->fetchRow();

    return (defined $valid_entry && $valid_entry->{'person_id'}) ? TRUE : FALSE; 
}

=item createByIDs(\@ids)

Returns an array ref of person objects, for as many of the ids as it can. 

=cut

sub createByIDs {
    my $self = shift;
    return Solstice::Factory::Person->new()->createByIDs(@_)->getAll();
}

*createByIds = *createByIDs;

=item createAllLogins()

Returns a list of Person objects, one for each member of the login realm.

=cut

sub getAllLoginNamesByDate {
    my $self = shift;
    return Solstice::Factory::Person->new()->getAllLoginNamesByDate(@_);
}

=item createByLogins($login_name_array_ref)

Returns an array ref of people objects. If the loginrealm has not 
been set, we'll read the default realm from Solstice::ConfigService.
If the default realm can't be used, an empty array ref is returned.

=cut

sub createByLogins {
    my $self = shift;
    return Solstice::Factory::Person->new()->createByLogins(@_)->getAll();
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
