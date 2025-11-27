use strict;
use Test::More 0.98;
use Mojo::URL;
use lib '../lib';

my $username = 'U53rN4m3';
my $password = 'p455w0rd#';
my $url = Mojo::URL->new->with_roles('+Auth');
$url->auth($username, $password);
is($url->auth, $url->userinfo, 'userinfo has been added');
is($username, $url->username, 'username is correct');
is($password, $url->password, 'username is correct');
isnt($url->username, $url->userinfo, "userinfo isn't username");
isnt($url->password, $url->userinfo, "userinfo isn't password");

done_testing;

