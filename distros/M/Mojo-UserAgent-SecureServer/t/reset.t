use Mojo::Base -strict;
use Mojo::HelloWorld;
use Mojo::UserAgent::SecureServer;
use Test::More;

note 'initial';
my $server = Mojo::UserAgent::SecureServer->new(app => Mojo::HelloWorld->new);
ok !$server->{nb_port},   'initial nb_port';
ok !$server->{nb_server}, 'initial nb_server';
ok !$server->{port},      'initial port';
ok !$server->{server},    'initial server';

note 'nb_url';
$server->nb_url;
ok $server->{nb_port},   'nb_url nb_port';
ok $server->{nb_server}, 'nb_url nb_server';
ok !$server->{port},   'nb_url nb_port';
ok !$server->{server}, 'nb_url server';

note 'url';
$server->url;
ok $server->{nb_port},   'url nb_port';
ok $server->{nb_server}, 'url nb_server';
ok $server->{port},      'url port';
ok $server->{server},    'url server';

note 'restart';
$server->restart;
ok !$server->{nb_port},   'restart nb_port';
ok !$server->{nb_server}, 'restart nb_server';
ok !$server->{port},      'restart port';
ok !$server->{server},    'restart server';

done_testing;
