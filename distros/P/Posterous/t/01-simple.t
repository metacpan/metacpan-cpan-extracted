use Test::More "no_plan";
use lib qw(lib);

use Posterous;
use Data::Dumper;

my $user = q{hello@world.com};
my $pass = "pass";

my $posterous = Posterous->new($user, $pass);

is ($posterous->auth_key, "aGVsbG9Ad29ybGQuY29tOnBhc3M=\n");
# is ($posterous->auth_key, `echo -n \"$user:$pass\" | openssl base64 -e`, "contrast with openssl");


