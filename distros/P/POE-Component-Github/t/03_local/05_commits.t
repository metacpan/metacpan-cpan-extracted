use strict;
use warnings;
use Test::More tests => 5;
use POE qw(Component::Github);
use Test::POE::Server::TCP;
use POE::Filter::HTTP::Parser;
use JSON::Any;
use HTTP::Response;

my $payload = {
                      'commits' => [
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '750bd034f5a629ebabd25e29a7af15b6ca16713b',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/41e6c9887d986842c59405bb104adf486b74857a',
                                       'committed_date' => '2009-05-11T08:22:31-07:00',
                                       'id' => '41e6c9887d986842c59405bb104adf486b74857a',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-11T08:22:31-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => '80f9b3cf5c8014a9178a7b9bffbab575fb2d4501'
                                                      }
                                                    ],
                                       'message' => 'Okay, that should be Users and Repository APIs implemented. Just the rest to do =['
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '27cbbb1aeb21fbd2d34985a0136fe543cd816181',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/80f9b3cf5c8014a9178a7b9bffbab575fb2d4501',
                                       'committed_date' => '2009-05-11T07:46:38-07:00',
                                       'id' => '80f9b3cf5c8014a9178a7b9bffbab575fb2d4501',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-11T07:46:38-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => '41b679c72b7462135229996966bfcac4f42deb16'
                                                      }
                                                    ],
                                       'message' => 'Fixed up authenticated requests'
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '7e9d70a4e115b82a730d5a361d31e5cda359b679',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/41b679c72b7462135229996966bfcac4f42deb16',
                                       'committed_date' => '2009-05-11T07:24:36-07:00',
                                       'id' => '41b679c72b7462135229996966bfcac4f42deb16',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-11T07:24:36-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => '68d1ab9658fd98c0d58ef140b5f2d205d2b66889'
                                                      }
                                                    ],
                                       'message' => 'Various updates. Broke out the construction of HTTP::Request objects into helper modules.'
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '8fd0442ee1e25492a9c982b9e86711aa4fe33361',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/68d1ab9658fd98c0d58ef140b5f2d205d2b66889',
                                       'committed_date' => '2009-05-11T01:42:56-07:00',
                                       'id' => '68d1ab9658fd98c0d58ef140b5f2d205d2b66889',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-11T01:42:56-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => '9c0470e045e69366dbc91a0a80d76401c1edd776'
                                                      }
                                                    ],
                                       'message' => 'Made a start on the params and url generation modules.'
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '8708e74134d98d357a31030c491bb5e20a152797',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/9c0470e045e69366dbc91a0a80d76401c1edd776',
                                       'committed_date' => '2009-05-10T07:28:03-07:00',
                                       'id' => '9c0470e045e69366dbc91a0a80d76401c1edd776',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-10T07:28:03-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => 'd3e3ce7260721a8b38adbdf8d4cdc0b7dcdbcea6'
                                                      }
                                                    ],
                                       'message' => 'Add POE::Component::SSLify to the requires list'
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '2169a01715b6d26d584dc49489ca12d95ec9980d',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/d3e3ce7260721a8b38adbdf8d4cdc0b7dcdbcea6',
                                       'committed_date' => '2009-05-10T05:19:54-07:00',
                                       'id' => 'd3e3ce7260721a8b38adbdf8d4cdc0b7dcdbcea6',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-10T05:19:54-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => 'f4db856ef9f590bfe1922213578c083f4ff6207a'
                                                      }
                                                    ],
                                       'message' => 'Added an example to find the following network. Mainly to test the floodcontrol code.'
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '24319dc44e0a6e49fd84b37e87e307c6e70bbea6',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/f4db856ef9f590bfe1922213578c083f4ff6207a',
                                       'committed_date' => '2009-05-09T16:12:29-07:00',
                                       'id' => 'f4db856ef9f590bfe1922213578c083f4ff6207a',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-09T16:12:29-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => '62f93f512730b4ecdfe2094de2f135c123fe70ad'
                                                      }
                                                    ],
                                       'message' => 'Added repository querying'
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '910cea62f37833deebc0cb49b16533d64d021766',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/62f93f512730b4ecdfe2094de2f135c123fe70ad',
                                       'committed_date' => '2009-05-09T15:53:56-07:00',
                                       'id' => '62f93f512730b4ecdfe2094de2f135c123fe70ad',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-09T15:53:56-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => 'ebfbe3447edae50c019ef254f767a1f0d64e4fc8'
                                                      }
                                                    ],
                                       'message' => 'Incredible, it works.'
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => 'd21430c87f1a0c5621dbd4995fec7fd8a9edf64f',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/ebfbe3447edae50c019ef254f767a1f0d64e4fc8',
                                       'committed_date' => '2009-05-09T08:20:28-07:00',
                                       'id' => 'ebfbe3447edae50c019ef254f767a1f0d64e4fc8',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-09T08:20:28-07:00',
                                       'parents' => [
                                                      {
                                                        'id' => '4138227e0e3c3c9c51d3bcbf7ed014870a3c7037'
                                                      }
                                                    ],
                                       'message' => 'Started to build up the API'
                                     },
                                     {
                                       'committer' => {
                                                        'email' => 'chris@bingosnet.co.uk',
                                                        'name' => 'Chris Williams'
                                                      },
                                       'tree' => '1d9cde6455f758ce549065228c2cc707673302b6',
                                       'url' => 'http://github.com/bingos/poe-component-github/commit/4138227e0e3c3c9c51d3bcbf7ed014870a3c7037',
                                       'committed_date' => '2009-05-09T04:09:47-07:00',
                                       'id' => '4138227e0e3c3c9c51d3bcbf7ed014870a3c7037',
                                       'author' => {
                                                     'email' => 'chris@bingosnet.co.uk',
                                                     'name' => 'Chris Williams'
                                                   },
                                       'authored_date' => '2009-05-09T04:09:47-07:00',
                                       'parents' => [],
                                       'message' => 'Initial commit'
                                     }
                                   ]
                    };

my $httpd = Test::POE::Server::TCP->spawn(
	address => '127.0.0.1',
	filter  => POE::Filter::HTTP::Parser->new( type => 'server' ),
	prefix  => 'httpd_',
);


my $github = POE::Component::Github->spawn( url_path => '127.0.0.1:' . $httpd->port . '/api/v2/json' );
isa_ok( $github, 'POE::Component::Github');

POE::Session->create(
  package_states => [
	'main' => [qw(_start _github httpd_registered httpd_client_input)],
  ],
);

$poe_kernel->run();
pass("Okay the kernel returned");
exit 0;

sub _start {
  $poe_kernel->post( $httpd->session_id, 'register', 'all' );
  return;
}

sub httpd_registered {
  $poe_kernel->post( $github->get_session_id, 'commits', 'branch',
        { event => '_github', user => 'bingos', repo => 'poe-component-github' },
  );
  return;
}

sub httpd_client_input {
  my ($id,$input) = @_[ARG0,ARG1];
  is( $input->uri->path, '/api/v2/json/commits/list/bingos/poe-component-github/master', 'The URI was right.' );
  my $resp = HTTP::Response->new( 200 );
  $resp->protocol('HTTP/1.1');
  $resp->content( JSON::Any->new->objToJson( $payload ) );
  use bytes;
  $resp->header('Content-Length', length $resp->content);
  $resp->header('Content-Type', 'application/json; charset=utf-8');
  $httpd->send_to_client( $id, $resp );
  return;
}

sub _github {
  my $args = $_[ARG0];
  ok( $args->{data}, 'There appears to be some data' );
  is_deeply( $args->{data}, $payload, 'The data was good' );
  $poe_kernel->post( $github->get_session_id, 'shutdown' );
  $httpd->shutdown();
  return;
}
