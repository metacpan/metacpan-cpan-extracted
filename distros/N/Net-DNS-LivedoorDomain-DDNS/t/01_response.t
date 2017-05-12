use strict;
use warnings;
use Test::More tests => 1;

use Net::DNS::LivedoorDomain::DDNS;
use Test::MockObject;
use HTTP::Response;

my $res  = HTTP::Response->new;
$res->code(200);
$res->content(join "\n",
              (
               "<PRE>",
               "RESULT_CODE: 200",
               "IP: 192.0.2.2",
               "USER: user",
               "HOSTNAME: www.example.com",
               "MESSAGE: OK",
               "</PRE>"
           )
          );

my $mock = Test::MockObject->new;
$mock->fake_module(
                   'LWP::UserAgent',
                   new => sub { bless {}, shift },
                   request => sub { return $res },
               );

my $ddns = Net::DNS::LivedoorDomain::DDNS->new;
my $ret = $ddns->update(
                        username => 'user',
                        password => 'pass',
                        hostname => 'www.example.com',
                    );
is($ret->is_success, '1', 'updated');

1;
