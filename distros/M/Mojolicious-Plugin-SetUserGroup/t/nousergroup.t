use Test::More;
use Mojolicious::Lite;
use Mojo::IOLoop;
use POSIX qw(getuid getgid);
use Unix::Groups::FFI 'getgroups';

my $init_uid = getuid();
my $init_gid = getgid();
my $init_groups = [getgroups()];

app->plugin(SetUserGroup => {});
Mojo::IOLoop->timer(0.5 => sub { Mojo::IOLoop->stop });

app->start;

is getuid(), $init_uid, 'UID is unchanged';
is getgid(), $init_gid, 'GID is unchanged';
is_deeply [getgroups()], $init_groups, 'Groups are unchanged';

done_testing;
