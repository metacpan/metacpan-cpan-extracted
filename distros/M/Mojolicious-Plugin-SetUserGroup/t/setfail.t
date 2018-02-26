use strict;
use warnings;
use Test::More;
use Mojo::Asset::File;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use POSIX qw(getuid getgid geteuid);

plan skip_all => 'Non-root test' if geteuid() == 0;

my $uid = getuid();
my $gid = getgid();
my $user = getpwuid 0;
my $group = getgrgid 0;

plan skip_all => 'User 0 does not exist' unless defined $user;
plan skip_all => 'Group 0 does not exist' unless defined $group;

my $templog = Mojo::Asset::File->new;
$templog->handle; # setup temp file path
my $daemon = Mojo::Server::Daemon->new(listen => ['http://127.0.0.1'], silent => 1);
$daemon->app->log->path($templog->path);
$daemon->app->plugin(SetUserGroup => {user => $user, group => $group});

Mojo::IOLoop->timer(0.5 => sub { $daemon->app->log->error("Test server has started"); Mojo::IOLoop->stop });
{ open my $null, '>', '/dev/null'; local *STDERR = $null; $daemon->run; }

my $log = $templog->slurp;
unlike $log, qr/Test server has started/, 'Server failed to start';
like $log, qr/Can't (switch to (user|group)|set supplemental groups)/, 'right error';
cmp_ok getuid(), '==', $uid, 'User has not changed';
cmp_ok getgid(), '==', $gid, 'Group has not changed';

done_testing;
