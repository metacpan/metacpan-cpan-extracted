use strict;
use warnings;
use Test::More;
use Mojito::Auth;
use Mojito::Model::Config;
use Data::Dumper::Concise;
BEGIN {
    if (!$ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release testing');
    }
}

# Need config as a constructor arg for Auth
my $config = Mojito::Model::Config->new->config;
my %constructor_args = (
    config => $config,
    first_name => 'xavi',
    last_name  => 'exemple',
    email      => 'xavi@somewhere.org',
    username   => 'xavi',
    realm      => 'mojito',
    password   => 'top_secret',
);
my $mojito_auth = Mojito::Auth->new(%constructor_args);
ok(my $id = $mojito_auth->add_user, 'Add user');
# Get a second object because elasticsearch may need a new connection to see
# the newly added user.
sleep 1;
$mojito_auth = Mojito::Auth->new(%constructor_args);
my $user = $mojito_auth->get_user('xavi');
my $name = $user->{first_name}. ' '.$user->{last_name};
my $email = $user->{email};
is($email, 'xavi@somewhere.org', 'email');
is($name, 'xavi exemple', 'name');
ok($mojito_auth->remove_user('xavi'), 'Remove user');

done_testing();
