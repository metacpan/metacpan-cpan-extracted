use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojo::JSON 'j';
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use POSIX qw(geteuid getegid);
use Unix::Groups 'getgroups';

plan skip_all => 'TEST_RUN_SUDO=1' unless $ENV{TEST_RUN_SUDO};
if ((my $uid = geteuid()) != 0) {
	my $user = getpwuid $uid;
	my $gid = getegid();
	my $groups = [getgroups()];
	$ENV{TEST_ORIGINAL_USER} = j {user => $user, uid => $uid, gid => $gid, groups => $groups};
	my @args = ('sudo', '-nE', $^X);
	push @args, '-I', $_ for @INC;
	push @args, $0, @ARGV;
	exec @args;
}

my $original = j($ENV{TEST_ORIGINAL_USER} || '{}');
plan skip_all => "user is missing in TEST_ORIGINAL_USER=$ENV{TEST_ORIGINAL_USER}"
	unless my $user = delete $original->{user};

my $port = Mojo::IOLoop::Server->generate_port;

defined(my $pid = fork) or die "Fork failed: $!";

unless ($pid) {
	my $daemon = Mojo::Server::Daemon->new(listen => ["http://127.0.0.1:$port"], silent => 1);
	$daemon->app->plugin(SetUserGroup => {user => $user, group => $user});
	$daemon->app->routes->children([]);
	$daemon->app->routes->get('/' => sub {
		shift->render(json => {
			uid => geteuid(),
			gid => getegid(),
			groups => [getgroups()],
		});
	});
	$daemon->run;
	exit 0;
}

my $ua = Mojo::UserAgent->new;
my $response;
Mojo::IOLoop->delay(sub {
	Mojo::IOLoop->timer(0.2 => shift->begin);
}, sub {
	$ua->get("http://127.0.0.1:$port/", shift->begin);
}, sub {
	my ($delay, $tx) = @_;
	$response = $tx->res->body;
	Mojo::IOLoop->stop;
});

my $failed;
Mojo::IOLoop->timer(1 => sub { $failed = 1; Mojo::IOLoop->stop });
Mojo::IOLoop->start;

kill 'TERM', $pid or die "Failed to stop daemon server: $!";
waitpid $pid, 0;

ok !$failed, 'Loop stopped successfully';
my $orig_groups = delete $original->{groups};
my $r_json = j($response);
my $new_groups = delete $r_json->{groups};
is_deeply($r_json, $original, 'UID and GID match') or diag $response;

my %check_groups = map { ($_ => 1) } @$new_groups;
my $is_in_groups = 1;
foreach my $gid (@$orig_groups) {
	$is_in_groups = 0 unless exists $check_groups{$gid};
}
ok $is_in_groups, "User is in all original secondary groups";
%check_groups = map { ($_ => 1) } @$orig_groups;
$is_in_groups = 1;
foreach my $gid (@$new_groups) {
	$is_in_groups = 0 unless $gid == $r_json->{gid} or exists $check_groups{$gid};
}
ok $is_in_groups, "All secondary groups are assigned to user";

done_testing;
