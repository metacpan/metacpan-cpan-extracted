use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use POSIX qw(getuid getgid);

my $uid = getuid();
my $gid = getgid();
my $user = getpwuid $uid;
my $group = getgrgid $gid;

my $daemon = Mojo::Server::Daemon->new(listen => ['http://127.0.0.1'], silent => 1);
$daemon->app->plugin(SetUserGroup => {user => $user, group => $group});
$daemon->start;
my $failed = 1;
Mojo::IOLoop->timer(0.1 => sub { $failed = 0; Mojo::IOLoop->stop });
Mojo::IOLoop->start;
ok !$failed, 'Server has started';
cmp_ok getuid(), '==', $uid, 'User has not changed';
cmp_ok getgid(), '==', $gid, 'Group has not changed';

done_testing;
