use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

use File::Temp qw(tempfile);
use Mojo::File qw(path);
use Mojo::JSON qw(decode_json);

my (undef, $tempfile) = tempfile;

plugin 'AutoSecrets' => {
  path => $tempfile,
};

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

ok $t->app->secrets, 'Secrets are set';

ok -f $tempfile, 'Secret file created';

my $secrets_json = path($tempfile)->slurp;
ok $secrets_json, 'Secrets file has content';

my $secrets = decode_json $secrets_json;
is scalar @$secrets, 1, 'One secret is saved';

done_testing();
