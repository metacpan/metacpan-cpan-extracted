#!/usr/local/bin/perl

use strict;
use warnings;
use 5.006_000;

use constant TRUE  => 1;
use constant FALSE => 0;
use constant DATABASE => 'solstice';
use constant TEST_USER => 'solstice_test_user';

use Test::More;

use Solstice::Database;
use Solstice::DateTime;
use Solstice::LoginRealm;
use Solstice::Service::LoginRealm;
use Solstice::Person;
use Digest::MD5 qw(md5_hex);


plan(tests => 34);

my $service = Solstice::Service::LoginRealm->new();
my $login_realm_hash = $service->get('scope_lookup');
my $login_realm;
foreach my $key (keys %$login_realm_hash) {
    my $lr = $login_realm_hash->{$key};
    if ((ref $lr) eq 'Solstice::LoginRealm') {
        $login_realm = $lr;
    }
}

my $p = new Solstice::Person();

#basic functions
ok($p->setLoginRealm($login_realm),    "setLoginRealm");
ok($p->setLoginName(TEST_USER),    "setLoginName");
ok($p->setName('Joe'), "setName");
ok($p->setSurname('Smith'),        "setSurname");
ok($p->setEmail('f@f.com'),    "setEmail");
ok($p->setPassword('j'), "setPassword");
ok($p->_setRemoteKey('c'), "_setRemoteKey");
ok($p->_setSystemName('k'), "_setSystemName");
ok($p->_setSystemSurname('l'), "_setSystemSurname");          
ok($p->_setSystemEmail('m@m.org'), "_setSystemEmail");

isa_ok($p->getLoginRealm(), 'Solstice::LoginRealm', "getLoginRealm");
is($p->getLoginName(), TEST_USER, "getLoginName");
is($p->getRemoteKey(),    'c', "getRemoteKey");
is($p->getName(), 'Joe', "getName");
is($p->getSurname(), 'Smith', "getSurname");
is($p->getEmail(),    'f@f.com', "getEmail");
is($p->_getPassword(), md5_hex(TEST_USER.':j'), "getPassword");
is($p->getSystemName(),     'k', "getSystemName");
is($p->getSystemSurname(), 'l', "getSystemSurname");
is($p->getSystemEmail(), 'm@m.org', "getSystemEmail");

ok(!$p->getCreationDate()->isValid(), "Creation date is not valid");
ok(!$p->getModificationDate()->isValid(), "Modification date is not valid");

#storage testing
ok($p->_isTainted(), "Person is tainted");

ok($p->store(), "Store the new Person");

isa_ok($p->getCreationDate(), "Solstice::DateTime", "Creation date");

isa_ok($p->getModificationDate(), "Solstice::DateTime", "Modification date");

isa_ok($p->getSystemModificationDate(), "Solstice::DateTime", "getSystemModificationDate");

ok($p->getID(), "ID is valid");

ok(!$p->_isTainted(), "Person is untainted");

# TODO - make this load up the default login realm...
is($p->getLoginRealm()->getID(), $login_realm->getID(), 'Login realm is valid');

my $p_from_db = Solstice::Person->new($p->getID());
is($p->equals($p_from_db), '1', "stored person equals() fetched person");

# update the person
$p_from_db->setName('new name');
ok($p_from_db->store(), "Store the existing Person");

my $p2 = Solstice::Person->new($p_from_db->getID());
is($p2->equals($p_from_db), '1', "updated person equals() fetched person");

# test duplicate name/realm
my $p3 = Solstice::Person->new();
$p3->setLoginRealm($login_realm);
$p3->setLoginName(TEST_USER);
is($p3->store(), '0', "unable to store a duplicate name/realm");


# clean up
if ($p->getID()) {
    my $db = Solstice::Database->new();
    $db->writeQuery('DELETE FROM solstice.Person where person_id=?',$p->getID());
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
