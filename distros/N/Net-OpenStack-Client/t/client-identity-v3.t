use strict;
use warnings;

use File::Basename;
use Test::More;
use Test::Warnings;

BEGIN {
    push(@INC, dirname(__FILE__));
}

use Test::MockModule;

use Net::OpenStack::Client;
use mock_rest qw(identity_v3);
use logger;

=head1 init

=cut

use Net::OpenStack::Client::Identity::v3;
is_deeply(\@Net::OpenStack::Client::Identity::v3::SUPPORTED_OPERATIONS,
   [qw(region domain project user group role rolemap service endpoint)],
   "ordered supported operations (order is meaningful, should not just change)");

my $items = {
    a => {par => 'c'},
    b => {par => 'f'},
    c => {},
    d => {par => 'e'},
    e => {par => 'c'},
    f => {},
    # filler, eg update or delete
    g => {},
    e => {par => 'g'},
};

my $res = [Net::OpenStack::Client::Identity::v3::sort_parents([qw(a b c d e f)], $items, 'par')];
diag "sort result ", explain $res;
is_deeply($res, [qw(c f a b e d)], "something sorted according to parenting");


my $openrcfn = dirname(__FILE__)."/openrc_example";
ok(-f $openrcfn, "example openrc file exists");


my $cl = Net::OpenStack::Client->new(log => logger->new(), debugapi => 1, openrc => $openrcfn);

=head1 get_id

=cut

reset_method_history();
my $id = $cl->api_identity_get_id('user', 'existing');
dump_method_history;
ok(method_history_ok(['GET .*/users\?name=existing ']), "get_id uses name parameter");
is($id, 2, "get_id returns id");

=head1 sync with filter

=cut

reset_method_history();
$res = $cl->api_identity_sync('user', {
    anewuser => {description => 'new user', domain_id => 'somedomain', email => 'a@b'},
    existing => {description => 'existing user (managed by)', email => 'e@b'},
    update => {description => 'to be updated (managed by)', email => 'u@b'},
}, filter => sub {my $op = shift; return ($op->{description} || '') =~ m/managed by/});

diag "sync result ", explain $res;
is_deeply($res, {
    create => [['anewuser', {id => 123}]],
    update => [['update', {id => 2}]],
    delete => [['disable', {id => 4}]],
}, "api_identity_sync user returns success");

dump_method_history;
ok(method_history_ok(
       [
        'GET .*/users/',
        'POST .*/users/ .*"description":"new user","domain_id":"dom123","email":"a@b","enabled":true.*name":"anewuser',
        'PATCH .*/users/2 .*description":',
        'PATCH .*/users/4 .*enabled":false',
       ],
       [
        'PATCH .*/users/[135]', # 1: nothing to update; 3: filtered out, 5: already disabled
        'PATCH .*/users/2 .*enabled', # only update what is required
       ]),
   "users created/updated/disabled; nothing done for certain existing users");

=head1 sync with tagstore

=cut


reset_method_history();
$res = $cl->api_identity_sync('region', {
    regone => {},
    a2nd => {parent_region_id => 'regone'},
    regtwo => {}}, tagstore => 'hoopla');

diag "region result ", explain $res;
is_deeply($res, {
    create => [['regone', {id => 'regone'}], ['regtwo', {id => 'regtwo'}], ['a2nd', {id => 'a2nd'}]],
    update => [],
    delete => [['toremove', {id => 'toremove'}]],
}, "region sync ok");

dump_method_history;
ok(method_history_ok(
       [
        'GET http://controller:35357/v3/projects[?]name=hoopla ',
        'GET .*/regions/',
        'GET http://controller:35357/v3/projects[?]parent_id=2 ',
        'POST .*/regions/ .*enabled":true.*"id":"regone',
        'PUT http://controller:35357/v3/projects/10/tags/ID_region_regone \{\} ',
        'POST .*/regions/ .*"id":"regtwo',
        'PUT http://controller:35357/v3/projects/10/tags/ID_region_regtwo \{\} ',
        'POST .*/regions/ .*"id":"a2nd".*parent_region_id":"regone"',
        'PUT http://controller:35357/v3/projects/10/tags/ID_region_a2nd \{\} ',
        'PATCH http://controller:35357/v3/regions/toremove .*"enabled":false.* ',
        'DELETE http://controller:35357/v3/projects/10/tags/ID_region_toremove ',
       ], [
        'POST .*/regions/ .*"parent"',
       ]),
   "regions created in order");

=head1 endpoint sync with tagstore

=cut

reset_method_history();
$res = $cl->api_identity_sync('endpoint', {
    "int_url1" => {interface => 'int', url => 'url1', region_id => 'regone'}, # add
    "pub_url2" => {interface => 'pub', url => 'url2', region_id => 'regone'}, # update region_id
    "priv_url3" => {interface => 'priv', url => 'url3', region_id => 'regtwo'}, # do nothing
}, tagstore => 'hoopla');

diag "endpoint result ", explain $res;
is_deeply($res, {
    create => [['int_url1', {id => 'pub1'}]],
    update => [['pub_url2', {id => 'pub2'}]],
    delete => [['pub_url4', {id => 'toremove'}]],
}, "endpoint sync ok");

dump_method_history;
ok(method_history_ok(
       [
    'GET http://controller:35357/v3/endpoints/  ',
    'POST http://controller:35357/v3/endpoints/ .*"enabled":true,"interface":"int","region_id":"regone","url":"url1".*',
    'PUT http://controller:35357/v3/projects/10/tags/ID_endpoint_pub1 ',
    'PATCH http://controller:35357/v3/endpoints/pub2 .*"region_id":"regone".*',
    'PATCH http://controller:35357/v3/endpoints/toremove .*"enabled":false.*',
       ], ['"name":']), "endpoints synced (no name set)");

=head1 sync roles

=cut


reset_method_history();

my $roles = {
    project => {someproj => {user => {auser => [qw(garden gnome)]}}},
    domain => {somedomain => {group => {agroup => [qw(smurfs)]}}},
};

$res = $cl->api_identity_sync_rolemap($roles, tagstore => 'hoopla');
ok($res, "sync_rolemap ok");

dump_method_history;
ok(method_history_ok([
    'GET .*/projects[?]name=someproj ',
    'GET .*/users[?]name=auser ',
    'GET .*/domains[?]name=somedomain ',
    'GET .*/groups[?]name=agroup ',
    'PUT .*/domains/dom123/groups/12345/roles/9904 \{\} ',
    'PUT .*/projects/10/tags/ROLE_ZG9tYWlucy9kb20xMjMvZ3JvdXBzLzEyMzQ1L3JvbGVzLzk5MDQ \{\} ',
    'PUT .*/projects/3/users/12333/roles/9903 \{\} ',
    'PUT .*/projects/10/tags/ROLE_cHJvamVjdHMvMy91c2Vycy8xMjMzMy9yb2xlcy85OTAz \{\} ',
    'DELETE .*/projects/3/users/12333/roles/9901 ',
    'DELETE .*/projects/10/tags/ROLE_cHJvamVjdHMvMy91c2Vycy8xMjMzMy9yb2xlcy85OTAx ',
    ],
    ['(PUT|DELETE).*gnome']), # already exists, nothing to update
    "roles created/deleted");

done_testing;
