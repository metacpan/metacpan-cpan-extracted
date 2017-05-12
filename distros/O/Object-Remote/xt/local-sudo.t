use IO::Prompter; # dies, utterly, if loaded after strictures, no idea why
use strictures 1;
use Test::More;
use lib 'xt/lib';

use Object::Remote;


my $user = $ENV{TEST_SUDOUSER}
    or plan skip_all => q{Requires TEST_SUDOUSER to be set};

my $conn = Object::Remote->connect('-')->connect("${user}\@");

my $remote = TestFindUser->new::on($conn);
my $remote_user = $remote->user;
like $remote_user, qr/^\d+$/, 'returned an int';
isnt $remote_user, $<, 'ran as different user';

$remote->send_err;

done_testing;
