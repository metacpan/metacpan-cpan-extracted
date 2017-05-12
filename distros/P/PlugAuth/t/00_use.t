use strict;
use warnings;
use Test::More tests => 14;
BEGIN { eval 'use EV' } # load it if it is there to avoid warning

use_ok 'PlugAuth';
use_ok 'PlugAuth::Routes';
use_ok 'PlugAuth::Plugin::FlatAuth';
use_ok 'PlugAuth::Plugin::FlatAuthz';
use_ok 'PlugAuth::Plugin::FlatUserList';
use_ok 'PlugAuth::Plugin::Test';
use_ok 'PlugAuth::Plugin::DisableGroup';

use_ok 'PlugAuth::Role::Auth';
use_ok 'PlugAuth::Role::Authz';
use_ok 'PlugAuth::Role::Plugin';
use_ok 'PlugAuth::Role::Refresh';
use_ok 'PlugAuth::Role::Flat';

use_ok 'Clustericious::Plugin::SelfPlugAuth';

use_ok 'PlugAuth::Client';

