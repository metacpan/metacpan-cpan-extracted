use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll'; $ENV{MOJO_LOG_LEVEL} = 'info' }

use Test::More;

use Mojo::IOLoop;
use Mojolicious::Lite;
use Test::Mojo;

use Mojo::JSON qw/true false/;
use Mojo::CallFire;

# Faux "Send Calls"
post '/calls' => sub {
  my $c = shift;
  $c->render(json => {
    "items" => [
      {
        "id" => 13394,
        "fromNumber" => "12135551189",
        "toNumber" => "12135551100",
        "state" => "READY",
        "campaignId" => 10,
        "batchId" => 6,
        "contact" => {
            "id" => 4096,
            "homePhone" => "12135551100"
        },
        "inbound" => false,
        "created" => 1443373382000,
        "modified" => 1443373382000,
        "agentCall" => false
      },
      {
        "id" => 13395,
        "fromNumber" => "12135551189",
        "toNumber" => "12135551101",
        "state" => "READY",
        "campaignId" => 10,
        "batchId" => 6,
        "contact" => {
            "id" => 4097,
            "homePhone" => "12135551101"
        },
        "inbound" => false,
        "created" => 1443373386000,
        "modified" => 1443373386000,
        "agentCall" => false
      }
    ]
  });
};

# Faux "Find Calls"
get '/calls' => sub {
  my $c = shift;
  $c->render(json => {
    "items" => [
        {
            "id" => 13395,
            "fromNumber" => "12135551189",
            "toNumber" => "12135551101",
            "state" => "FINISHED",
            "campaignId" => 10,
            "batchId" => 6,
            "contact" => {
                "id" => 4097,
                "homePhone" => "12135551101"
            },
            "labels" => [
                "survey 1"
            ],
            "attributes" => {
                "external_user_id" => "45450007002",
                "external_route_id" => "77770007002"
            },
            "inbound" => false,
            "created" => 1443373386000,
            "modified" => 1443373412000,
            "finalCallResult" => "LA",
            "records" => [
                {
                    "id" => 10306,
                    "billedAmount" => 1.1667,
                    "finishTime" => 1443373425000,
                    "callResult" => "LA",
                    "questionResponses" => [
                        {
                            "question" => "Do you have a dog",
                            "response" => "Yes"
                        },
                        {
                            "question" => "What's your favorite movie",
                            "response" => "StarWars"
                        }
                    ]
                }
            ],
            "agentCall" => false
        },
        {
            "id" => 13394,
            "fromNumber" => "12135551189",
            "toNumber" => "12135551100",
            "state" => "FINISHED",
            "campaignId" => 10,
            "batchId" => 6,
            "contact" => {
                "id" => 4096,
                "homePhone" => "12135551100"
            },
            "inbound" => false,
            "created" => 1443373382000,
            "modified" => 1443373412000,
            "finalCallResult" => "CARRIER_ERROR",
            "records" => [
                {
                    "id" => 10305,
                    "billedAmount" => 0,
                    "finishTime" => 1443373408000,
                    "callResult" => "CARRIER_ERROR"
                }
            ],
            "agentCall" => false
        }
    ],
    "limit" => 2,
    "offset" => 0,
    "totalCount" => 7160
  });
};

my $t = Test::Mojo->new;
my $cf = Mojo::CallFire->new(username => 'abc', password => '123', base_url => $t->ua->server->url =~ s/\/$//r, _ua => $t->ua);

is $cf->username, 'abc', 'right username';
is $cf->password, '123', 'right password';
my $send_call = [
  {
      phoneNumber => "12135551100",
      liveMessage => "Why hello there!"
  },
  {
      phoneNumber => "12135551101",
      liveMessage => "And hello to you too."
  }
];
is $cf->post('/calls' => json => $send_call)->result->json('/items/0/id'), 13394, 'right id';
is $cf->get('/calls' => form => {limit => 2})->result->json('/items/1/id'), 13394, 'right id';

done_testing;
