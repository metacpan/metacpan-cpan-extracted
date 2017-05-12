use strict;
use warnings;
use Test::More 'no_plan';
use Mojo::UserAgent;
use Mojo::Util 'slurp';
use Mojo::JSON 'j';

use Data::Dumper 'Dumper';
use Test::Exception;
use Test::MockObject;

BEGIN {
  use_ok('Mojo::Cloudstack') || print "Bail out!\n";
}

diag("Testing Mojo::Cloudstack $Mojo::Cloudstack::VERSION, Perl $], $^X");

my $api_key = slurp("t/api_key");
chomp $api_key;
my $secret_key = slurp("t/secret_key");
chomp $secret_key;

my $cs = Mojo::Cloudstack->new(
  host       => "localhost",
  path       => "/client/api",
  port       => "8080",
  scheme     => "http",
  api_key    => $api_key,
  secret_key => $secret_key,
);

my $params = Mojo::Parameters->new('command=listUsers&response=json');
$params->append(apiKey => $cs->api_key);
is $cs->_build_request($params->to_hash), 'http://localhost:8080/client/api?apiKey=plgWJfZK4gyS3mOMTVmjUVg-X-jlWlnfaUJ9GAbBbf9EdM-kAYMmAiLqzzq1ElZLYq_u38zCm0bewzGUdP66mg&command=listUsers&response=json&signature=TTpdDq%2F7j%2FJ58XCRHomKoQXEQds%3D', 'built request';
