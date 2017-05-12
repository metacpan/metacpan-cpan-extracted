package Solstice::PreferenceService;

# $Id: PreferenceService.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::PreferenceService - Allows for the permanent storage of user preferences.

=head1 SYNOPSIS

    Only the subclasses of this object should be used, WebQ::PreferenceService 
    for example.
    
    use Solstice::PreferenceService;
    my $pref_service = new Solstice::PreferenceService;

    my $nickname = $pref_service->getPreference('nick');
    $pref_service->setPreference('nick', 'Magic Tom');

    The "solstice" database has a table named "Preference" that contains the
    definitions of the preference tags AKA magic strings e.g. 'nick'.

    All preferences are automatically set and got for the current user.

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Solstice::Database;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new([$namespace])

=cut

sub new {
    my $class = shift;
    my $namespace = shift;
    
    my $self = $class->SUPER::new(@_);
    
    unless (defined $namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }

    $self->setNamespace($namespace);
    
    return $self;
}

=item getPreference($tag);

=cut

sub getPreference {
    my $self = shift;
    my $tag  = shift;

    unless (defined $tag) {
        warn "getPreference() failed: Tag not defined.";
        return FALSE;
    }

    $self->_loadCache() unless $self->_isLoaded;

    return FALSE unless $self->_isLoaded();

    return $self->_getPreference($tag);
}

=item setPreference($tag, $value);

=cut

sub setPreference {
    my $self = shift;
    my ($tag, $value) = @_;

    unless (defined $tag) {
        warn "setPreference() failed: Tag not defined.";
        return FALSE;
    }
    
    my $preference_id = $self->_getPreferenceID($tag);
    unless (defined $preference_id) {
        warn "setPreference(): Creating tag '$tag' for namespace ".
            $self->getNamespace();

        $preference_id = $self->_insertPreference($tag);
    
        unless ($preference_id) {
            warn "_insertPreference() failed for tag '$tag'";
            return FALSE;
        }
    }

    $self->_loadCache() unless $self->_isLoaded();
    
    return $self->_setPreference($preference_id, $tag, $value);
}

=item _insertPreference(tag)

Used to insert all solstice preferences that might be missing
override this method for application specific preferences

=cut

sub _insertPreference {
    my $self = shift;
    my $tag  = shift;

    return unless defined $tag && $self->getNamespace();
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    my $application = Solstice::Application->new({namespace => $self->getNamespace()});

    return FALSE unless defined $application;

    $db->writeQuery('INSERT INTO '.$db_name.'.Preference 
        (application_id, tag)
        VALUES (?, ?)', $application->getID(), $tag);

    return $db->getLastInsertID();
}

=back

=head2 Private Methods

=over 4

=cut


=item _setPreference($id, $tag, $value)

=cut

sub _setPreference {
    my $self = shift;
    my ($id, $tag, $value) = @_;

    my $person_id = $self->_getUserID;
    
    return FALSE unless $person_id;
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    if ($self->_tagExists($tag)) {
        $db->writeQuery('UPDATE '.$db_name.'.PreferenceValue 
            SET value = ? 
            WHERE preference_id = ? AND person_id = ?', $value, $id, $person_id);

    } else {
        $db->writeQuery('INSERT INTO '.$db_name.'.PreferenceValue
            (preference_id, person_id, value)
            VALUES (?, ?, ?)', $id, $person_id, $value);
    }

    my $namespace = $self->getNamespace();
    my $cache = $self->get($namespace.'_cache');
    $cache->{$tag} = $value;
    $self->set($namespace.'_cache', $cache);
    
    return TRUE;
}

=item _getPreference($tag)

=cut

sub _getPreference {
    my $self = shift;
    my $tag  = shift;
    return $self->get($self->getNamespace().'_cache')->{$tag};
}

=item _getPreferenceID($tag)

=cut

sub _getPreferenceID {
    my $self = shift;
    my $tag  = shift;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery('SELECT p.preference_id 
        FROM '.$db_name.'.Preference AS p, '.$db_name.'.Application AS a, '.
            $db_name.'.Preference AS p1
        WHERE p.preference_id = p1.preference_id 
            AND a.application_id = p.application_id 
            AND a.namespace = ? AND p.tag = ?', $self->getNamespace(), $tag);
    
    my $data = $db->fetchRow();
    
    return $data->{'preference_id'};
}

=item _getUserID

=cut

sub _getUserID {
    my $self = shift;
    
    my $user_service = $self->getUserService();
    
    if (defined $user_service->getUser()) {
        return $user_service->getUser()->getID();
    }
    return;
}

=item _fillCache()

=cut

sub _fillCache {
    my $self = shift;

    my $namespace = $self->getNamespace();
    my $person_id = $self->_getUserID();

    return FALSE unless ($person_id and $namespace);
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery('SELECT p.tag, pv.value
        FROM '.$db_name.'.Application AS a, '.$db_name.'.Preference AS p 
            LEFT JOIN '.$db_name.'.PreferenceValue AS pv ON p.preference_id = pv.preference_id
        WHERE p.application_id = a.application_id AND a.namespace = ? AND pv.person_id = ?',
        $namespace, $person_id);

    my %cache;
    while (my $data = $db->fetchRow()) {
        $cache{$data->{'tag'}} = $data->{'value'};
    }
    
    $self->set($namespace.'_cache', \%cache);
    
    return TRUE;
}

=item _loadCache()

=cut

sub _loadCache {
    my $self = shift;
    $self->set($self->getNamespace().'_loaded_cache', $self->_fillCache());
}

=item _emptyCache()

=cut

sub _emptyCache {
    my $self = shift;
    $self->set($self->getNamespace().'_cache', undef);
    $self->set($self->getNamespace().'_loaded_cache', FALSE);
}

=item _isLoaded()

=cut

sub _isLoaded {
    my $self = shift;
    return $self->get($self->getNamespace().'_loaded_cache');
}

=item _tagExists($tag)

=cut

sub _tagExists {
    my $self = shift;
    my $tag  = shift;
    return (exists $self->get($self->getNamespace().'_cache')->{$tag});
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Database|Solstice::Database>,
L<Solstice::Service|Solstice::Service>.

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
