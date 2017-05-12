use Test::Most;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';
use HTTP::Request::Common qw/POST/;

my $request = POST '/login',
             [ username   => 'appkitadmin',
             password  => 'password' ];

my($res, $c) = ctx_request($request);
is $res->code, 302;


note 'Testing the always allowed bits';
ok $c->can_access('/default'), 'can_access /default';
ok $c->can_access('/begin'), 'can_access /begin';
ok $c->can_access('/end'), 'can_access /end';
ok $c->can_access('/access_denied'), 'can_access /access_denied';
ok $c->can_access('default'), 'can_access default';
ok $c->can_access('begin'), 'can_access begin';
ok $c->can_access('end'), 'can_access end';
ok $c->can_access('access_denied'), 'can_access access_denied';
ok $c->can_access('View::Download'), 'can_access View::Download';
ok $c->can_access('index'), 'can_access index';
ok $c->can_access('appkit/admin/index'), 'can_access appkit/admin/index';

note 'Now checking for paths that should not be allowed';
ok !$c->can_access('/not_access_denied'), 'NOT can_access /not_access_denied';
ok !$c->can_access('test/who_can_access_stuff'), 'NOT can_access test/who_can_access_stuff';

my $controller = $c->controller('Root');
my $action = $controller->action_for('index');
ok $c->can_access($action), 'Lookup by action';

my @users = map { $_->username } $c->who_can_access('appkit/admin/index')->all;
eq_or_diff \@users, [ 'appkitadmin', 'tester' ];

request('/logout');

done_testing;
