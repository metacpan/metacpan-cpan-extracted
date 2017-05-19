use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

use Mojo::IOLoop;
use Mojolicious::Lite;
use Test::Mojo;

use Mojo::CloudCheckr;

get '/account.json/get_accounts_v2' => sub {
  my $c = shift;
  my $key = $c->param('access_key');
  $c->render(json => {
    accounts_and_users => [
      {
        "account_name" => "AWS Account1",
        "cc_account_id" => "1",
      },
      {
        "account_name" => "AWS Account2",
        "cc_account_id" => "2",
      },
      {
        "account_name" => "AWS Account3",
        "cc_account_id" => "3",
      }
    ]
  });
};

my $t = Test::Mojo->new;

my $cc = Mojo::CloudCheckr->new(access_key => 'abc', base_url => $t->ua->server->url =~ s/\/$//r, _ua => $t->ua);

is $cc->access_key, 'abc', 'right access_key';
is $cc->get(account => 'get_accounts_v2')->result->json('/accounts_and_users/0/account_name'), 'AWS Account1', 'right account name';

done_testing;
