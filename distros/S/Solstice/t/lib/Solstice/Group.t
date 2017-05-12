#!/usr/bin/perl

use strict;
use warnings;
use 5.006_000;

use Test::More;
use constant TRUE => 1;
use constant FALSE => 0;

use Solstice::Person;
use Solstice::LoginRealm;
use Solstice::Service::LoginRealm;
use Solstice::Group;
use Solstice::Application;

plan(tests => 128);


BEGIN {
    use_ok('Solstice::Group');
}

my $service = Solstice::Service::LoginRealm->new();
my $login_realm_hash = $service->get('scope_lookup');
my $login_realm;
foreach my $key (keys %$login_realm_hash) {
    my $lr = $login_realm_hash->{$key};
    if ((ref $lr) eq 'Solstice::LoginRealm') {
        $login_realm = $lr;
    }
}

ok (my $group0 = Solstice::Group->new(), "initializing new group");
is_deeply(Solstice::Group::_getAccessorDefinition(), _getAccessorDefinition(), 'Accessor definition is accurate'); 

ok (my $group1 = Solstice::Group->new(), "initializing a new group");
isa_ok($group1, 'Solstice::Group');

# Test setting/getting the group name
ok (my $group2 = Solstice::Group->new(), "initializing a new group");
isa_ok($group2, 'Solstice::Group');

ok ($group2->setName('test name'), 'Set name passes');
cmp_ok ($group2->getName(), 'eq', 'test name', 'Get name passes');

# Test setting/getting the group description
ok ($group2->setDescription('test description'), 'Set description passes');
cmp_ok ($group2->getDescription(), 'eq', 'test description', 'Get description passes');

# Test setting/getting a creator
ok (my $person1 = Solstice::Person->new({person_id => 1, login_realm => $login_realm}), 'Creating a new person object');
ok ($group2->setCreator($person1), 'Set creator passed');
is_deeply($group2->getCreator(), $person1, 'Get creator passed');

# Test settings/getting the creating application
ok (my $application1 = bless({}, 'Solstice::Application'), 'Creating a new application object');
ok ($group2->setCreationApplication($application1), 'Set creating application passed');
is_deeply ($group2->getCreationApplication(), $application1, 'Get creating application passed');

# Test managing owners
{

    ok (my $go_person1 = Solstice::Person->new({person_id => 2, login_realm => $login_realm}), 'Creating a new person object'); 
    ok (my $go_person2 = Solstice::Person->new({person_id => 3, login_realm => $login_realm}), 'Creating a new person object'); 
    ok (my $go_person3 = Solstice::Person->new({person_id => 4, login_realm => $login_realm}), 'Creating a new person object'); 
    ok ($go_person1->_setID(1), 'Set ID of group owner 1');
    ok ($go_person2->_setID(2), 'Set ID of group owner 2');
    ok ($go_person3->_setID(3), 'Set ID of group owner 3');

    ok (my $group3 = Solstice::Group->new(), 'Creating a new group object');
    ok (my $owner_list1 = $group3->getOwners(), 'Got an owner list from a new group');
    isa_ok ($owner_list1, 'Solstice::List', 'Owner list is a List object');
    cmp_ok ($owner_list1->size(), '==', 0, 'Owner list is empty on a new group');

    ok ($group3->removeOwner($go_person1), 'Removed a non-owner from the owner list');
    ok (my $owner_list2 = $group3->getOwners(), 'Got an owner list from a new group with improperly removed owner');
    isa_ok ($owner_list2, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list2->size(), '==', 0, 'Owner list is empty on a group with no owners, with a non-owner removed');

    ok ($group3->addOwner($go_person1), 'Added an owner to a group');
    ok (my $owner_list3 = $group3->getOwners(), 'Got an owner list from a new group with 1 owner');
    isa_ok ($owner_list3, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list3->size(), '==', 1, 'Owner list has 1 member'); 

    ok ($group3->removeOwner($go_person1), 'Removed an owner from the owner list');
    ok (my $owner_list4 = $group3->getOwners(), 'Got an owner list from a new group with properly removed owner');
    isa_ok ($owner_list4, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list4->size(), '==', 0, 'Owner list is empty on a group with no owners, with an owner removed');

    ok ($group3->addOwner($go_person1), 'Added an owner to a group');
    ok (my $owner_list5 = $group3->getOwners(), 'Got an owner list from a new group with 1 owner');
    isa_ok ($owner_list5, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list5->size(), '==', 1, 'Owner list has 1 member'); 

    ok ($group3->addOwner($go_person2), 'Added an owner to a group');
    ok (my $owner_list6 = $group3->getOwners(), 'Got an owner list from a new group with 2 owners');
    isa_ok ($owner_list6, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list6->size(), '==', 2, 'Owner list has 2 members'); 

    ok ($group3->addOwner($go_person3), 'Added an owner to a group');
    ok (my $owner_list7 = $group3->getOwners(), 'Got an owner list from a new group with 3 owners');
    isa_ok ($owner_list7, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list7->size(), '==', 3, 'Owner list has 3 members'); 

    ok ($group3->removeOwner($go_person1), 'Removed an owner from a group');
    ok (my $owner_list8 = $group3->getOwners(), 'Got an owner list from a new group with 2 owners');
    isa_ok ($owner_list8, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list8->size(), '==', 2, 'Owner list has 2 members'); 

    ok ($group3->removeOwner($go_person1), 'Removed an invalid owner from a group');
    ok (my $owner_list9 = $group3->getOwners(), 'Got an owner list from a new group with 2 owners, after an invalid removal');
    isa_ok ($owner_list9, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list9->size(), '==', 2, 'Owner list has 2 members after improper removal of an owner'); 

    ok ($group3->removeOwner($go_person2), 'Removed a valid owner from a group');
    ok (my $owner_list10 = $group3->getOwners(), 'Got an owner list from a new group with 1 owners');
    isa_ok ($owner_list10, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list10->size(), '==', 1, 'Owner list has 1 member after removal of an owner'); 

    ok ($group3->removeOwner($go_person3), 'Removed last owner from a group');
    ok (my $owner_list11 = $group3->getOwners(), 'Got an owner list from a new group with 1 owners');
    isa_ok ($owner_list11, 'Solstice::List', 'Owner list is a Solstice::List object');
    cmp_ok ($owner_list11->size(), '==', 0, 'Owner list has 1 member after removal of an owner'); 

    cmp_ok ($group3->addOwner('invalid_string'), '==', FALSE, 'Unable to add a string as a group owner');
    cmp_ok ($group3->addOwner(undef), '==', FALSE, 'Unable to add undef as a group owner');
    cmp_ok ($group3->addOwner([]), '==', FALSE, 'Unable to add array ref as a group owner');
    cmp_ok ($group3->addOwner({}), '==', FALSE, 'Unable to add hash ref as a group owner');
    cmp_ok ($group3->addOwner(my @array), '==', FALSE, 'Unable to add array as a group owner');
    cmp_ok ($group3->addOwner(my %hash), '==', FALSE, 'Unable to add hash as a group owner');

}


# Test managing users
{

    ok (my $go_person1 = Solstice::Person->new({person_id => 4, login_realm => $login_realm}), 'Creating a new person object'); 
    ok (my $go_person2 = Solstice::Person->new({person_id => 5, login_realm => $login_realm}), 'Creating a new person object'); 
    ok (my $go_person3 = Solstice::Person->new({person_id => 6, login_realm => $login_realm}), 'Creating a new person object'); 
    ok ($go_person1->_setID(1), 'Set ID of group member 1');
    ok ($go_person2->_setID(2), 'Set ID of group member 2');
    ok ($go_person3->_setID(3), 'Set ID of group member 3');

    ok (my $group3 = Solstice::Group->new(), 'Creating a new group object');
    ok (my $member_list1 = $group3->getMembers(), 'Got an member list from a new group');
    isa_ok ($member_list1, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list1->size(), '==', 0, 'Member list is empty on a new group');

    ok ($group3->removeMember($go_person1), 'Removed a non-member from the member list');
    ok (my $member_list2 = $group3->getMembers(), 'Got an member list from a new group with improperly removed member');
    isa_ok ($member_list2, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list2->size(), '==', 0, 'Member list is empty on a group with no members, with a non-member removed');

    ok ($group3->addMember($go_person1), 'Added an member to a group');
    ok (my $member_list3 = $group3->getMembers(), 'Got an member list from a new group with 1 member');
    isa_ok ($member_list3, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list3->size(), '==', 1, 'Member list has 1 member'); 

    ok ($group3->removeMember($go_person1), 'Removed an member from the member list');
    ok (my $member_list4 = $group3->getMembers(), 'Got an member list from a new group with properly removed member');
    isa_ok ($member_list4, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list4->size(), '==', 0, 'Member list is empty on a group with no members, with an member removed');

    ok ($group3->addMember($go_person1), 'Added an member to a group');
    ok (my $member_list5 = $group3->getMembers(), 'Got an member list from a new group with 1 member');
    isa_ok ($member_list5, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list5->size(), '==', 1, 'Member list has 1 member'); 

    ok ($group3->addMember($go_person2), 'Added an member to a group');
    ok (my $member_list6 = $group3->getMembers(), 'Got an member list from a new group with 2 members');
    isa_ok ($member_list6, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list6->size(), '==', 2, 'Member list has 2 members'); 

    ok ($group3->addMember($go_person3), 'Added an member to a group');
    ok (my $member_list7 = $group3->getMembers(), 'Got an member list from a new group with 3 members');
    isa_ok ($member_list7, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list7->size(), '==', 3, 'Member list has 3 members'); 

    ok ($group3->removeMember($go_person1), 'Removed an member from a group');
    ok (my $member_list8 = $group3->getMembers(), 'Got an member list from a new group with 2 members');
    isa_ok ($member_list8, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list8->size(), '==', 2, 'Member list has 2 members'); 

    ok ($group3->removeMember($go_person1), 'Removed an invalid member from a group');
    ok (my $member_list9 = $group3->getMembers(), 'Got an member list from a new group with 2 members, after an invalid removal');
    isa_ok ($member_list9, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list9->size(), '==', 2, 'Member list has 2 members after improper removal of an member'); 

    ok ($group3->removeMember($go_person2), 'Removed a valid member from a group');
    ok (my $member_list10 = $group3->getMembers(), 'Got an member list from a new group with 1 members');
    isa_ok ($member_list10, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list10->size(), '==', 1, 'Member list has 1 member after removal of an member'); 

    ok ($group3->removeMember($go_person3), 'Removed last member from a group');
    ok (my $member_list11 = $group3->getMembers(), 'Got an member list from a new group with 1 members');
    isa_ok ($member_list11, 'Solstice::List', 'Member list is a Solstice::List object');
    cmp_ok ($member_list11->size(), '==', 0, 'Member list has 1 member after removal of an member'); 

    cmp_ok ($group3->addMember('invalid_string'), '==', FALSE, 'Unable to add a string as a group member');
    cmp_ok ($group3->addMember(undef), '==', FALSE, 'Unable to add undef as a group member');
    cmp_ok ($group3->addMember([]), '==', FALSE, 'Unable to add array ref as a group member');
    cmp_ok ($group3->addMember({}), '==', FALSE, 'Unable to add hash ref as a group member');
    cmp_ok ($group3->addMember(my @array), '==', FALSE, 'Unable to add array as a group member');
    cmp_ok ($group3->addMember(my %hash), '==', FALSE, 'Unable to add hash as a group member');

}
# Test managing member groups
# Test managing LDAP groups
# Test managing subgroups

sub _getAccessorDefinition {
    return [

    {
        name => 'Name',
        key  => '_name',
        type => 'String',
    },
    {
        name => 'Description',
        key  => '_description',
        type => 'String',
    },
    {
        name => 'Creator',
        key  => '_creator',
        type => 'Person',
    },
    {
        name => 'CreationApplication',
        key  => '_creation_application',
        type => 'Solstice::Application',
    },
    {
        name => 'CreationDate',
        key  => '_creation_date',
        type => 'DateTime',
        private_set => TRUE,
    },
    {
        name => 'ModificationDate',
        key  => '_modification_date',
        type => 'DateTime',
        private_set => TRUE,
    },
    ];
}



=head1 COPYRIGHT

Copyright  1998-2006 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
