use Test::More;
use Mojolicious::Lite;
use Mojo::IOLoop;
use POSIX qw(geteuid getegid);
use Unix::Groups 'getgroups';

my $init_uid = geteuid();
my $init_gid = getegid();
my $init_groups = [getgroups()];

app->plugin(SetUserGroup => {});
Mojo::IOLoop->timer(0.5 => sub { Mojo::IOLoop->stop });

app->start;

is geteuid(), $init_uid, 'UID is unchanged';
is getegid(), $init_gid, 'GID is unchanged';
is_deeply [getgroups()], $init_groups, 'Groups are unchanged';

done_testing;
