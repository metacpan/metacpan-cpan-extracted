use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::Fluidinfo::Object;
use Net::Fluidinfo::Namespace;
use Net::Fluidinfo::Tag;
use Net::Fluidinfo::Permission;
use Net::Fluidinfo::User;
use Net::Fluidinfo::TestUtils;

use_ok('Net::Fluidinfo');

my $fin;

# -----------------------------------------------------------------------------

delete $ENV{FLUIDINFO_USERNAME};
delete $ENV{FLUIDINFO_PASSWORD};

$fin = Net::Fluidinfo->new;
ok !defined $fin->username;
ok !defined $fin->password;

$fin = Net::Fluidinfo->new(username => 'u');
ok $fin->username eq 'u';
ok !defined $fin->password;

$fin = Net::Fluidinfo->new(username => 'u', password => 'p');
ok $fin->username eq 'u';
ok $fin->password eq 'p';

# -----------------------------------------------------------------------------

$ENV{FLUIDINFO_USERNAME} = 'eu';

$fin = Net::Fluidinfo->new;
ok $fin->username eq 'eu';
ok !defined $fin->password;

$fin = Net::Fluidinfo->new(username => 'u');
ok $fin->username eq 'u';
ok !defined $fin->password;

$fin = Net::Fluidinfo->new(username => 'u', password => 'p');
ok $fin->username eq 'u';
ok $fin->password eq 'p';

# -----------------------------------------------------------------------------

$ENV{FLUIDINFO_USERNAME} = 'eu';
$ENV{FLUIDINFO_PASSWORD} = 'ep';

$fin = Net::Fluidinfo->new;
ok $fin->username eq 'eu';
ok $fin->password eq 'ep';

$fin = Net::Fluidinfo->new(username => 'u');
ok $fin->username eq 'u';
ok $fin->password eq 'ep';

$fin = Net::Fluidinfo->new(username => 'u', password => 'p');
ok $fin->username eq 'u';
ok $fin->password eq 'p';

# -----------------------------------------------------------------------------

$fin = Net::Fluidinfo->new_for_testing;
ok $fin->username eq 'test';
ok $fin->password eq 'test';
{
    no warnings;
    ok $fin->host eq $Net::Fluidinfo::SANDBOX_HOST;
}

# -----------------------------------------------------------------------------

$fin = Net::Fluidinfo->_new_for_net_fluidinfo_test_suite;
ok $fin->username eq 'net-fluidinfo';
ok $fin->password eq 'ai3hs45kl2';
{
    no warnings;
    ok $fin->host eq $Net::Fluidinfo::DEFAULT_HOST;
}

# -----------------------------------------------------------------------------

foreach my $md5 (0, 1) {
    $fin = Net::Fluidinfo->_new_for_net_fluidinfo_test_suite(md5 => $md5);

    my $user = $fin->user;
    my $object = $user->object;

    my $object2 = $fin->get_object_by_id($object->id, about => 1);
    ok $object2->isa('Net::Fluidinfo::Object');
    ok $object2->id eq $object->id;
    ok $object2->about eq $object->about;

    my $object3 = $fin->get_object_by_about($object->about);
    ok $object3->isa('Net::Fluidinfo::Object');
    ok $object3->id eq $object->id;
    ok $object3->about eq $object->about;

    my $ns = $fin->get_namespace($fin->username);
    ok $ns->isa('Net::Fluidinfo::Namespace');
    ok $ns->path eq $fin->username;

    my $description = random_description;
    my $name        = random_name;
    my $path        = $fin->username . "/$name";

    my $tag = Net::Fluidinfo::Tag->new(
        fin         => $fin,
        description => $description,
        indexed     => 1,
        path        => $path
    );

    ok $tag->create;
    ok $object->tag($tag, integer => 0);

    tolerate_delay {
        my @ids = $fin->search("$path = 0");
        if (@ids) {
            ok @ids == 1;
            ok $ids[0] eq $object->id;
            1; # halt the wait loop no matter whether the assertion passes
        }
    };

    my $tag2 = $fin->get_tag($tag->path);
    ok $tag2->isa('Net::Fluidinfo::Tag');
    ok $tag2->path eq $tag->path;
    ok $tag->delete;

    my $permission = $fin->get_permission('namespaces', $user->username, 'create');
    ok $permission->category eq 'namespaces';
    ok $permission->action eq 'create';

    my $user2 = $fin->get_user($user->username);
    ok $user2->isa('Net::Fluidinfo::User');
    ok $user2->username eq $user->username;
}

done_testing;
