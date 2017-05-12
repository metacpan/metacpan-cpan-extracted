use strict;
use warnings;
use 5.010001;
use PlugAuth::Client;

my $client = PlugAuth::Client->new;

print "user: ";
my $username = <STDIN>;
print "pass: ";
my $password = <STDIN>;

chomp $username;
chomp $password;

$client->login($username, $password);

if($client->auth)
{
  say "$username is authenticated";
}
else
{
  say "AUTH FAILED";
}

if($client->authz($username, 'GET', '/some/user/resource'))
{
  say "$username is authorized to GET /some/user/resource";
}
else
{
  say "AUTHZ FAILED";
}
