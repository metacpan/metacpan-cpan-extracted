use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojo::JSON 'j';
use Mojo::Server::Prefork;
use Mojo::UserAgent;
use POSIX qw(getuid getgid geteuid);
use Unix::Groups::FFI 'getgroups';

plan skip_all => 'TEST_RUN_SUDO=1' unless $ENV{TEST_RUN_SUDO};
if ((my $uid = geteuid()) != 0) {
	my $user = getpwuid $uid;
	my $gid = getgid();
	my $group = getgrgid $gid;
	my $groups = [getgroups()];
	$ENV{TEST_ORIGINAL_USER} = j {user => $user, group => $group, uid => $uid, gid => $gid, groups => $groups};
	my @args = ('sudo', '-nE', $^X);
	push @args, '-I', $_ for @INC;
	push @args, $0, @ARGV;
	exec @args;
}

my $original = j($ENV{TEST_ORIGINAL_USER} || '{}');
plan skip_all => "user is missing in TEST_ORIGINAL_USER=$ENV{TEST_ORIGINAL_USER}"
	unless my $user = delete $original->{user};
my $group = delete $original->{group};

my $port = Mojo::IOLoop::Server->generate_port;

defined(my $pid = fork) or die "Fork failed: $!";

unless ($pid) {
	my $daemon = Mojo::Server::Prefork->new(listen => ["http://127.0.0.1:$port?single_accept=1"],
		silent => 1, workers => 2, accepts => 10, multi_accept => 1);
	$daemon->app->plugin(SetUserGroup => {user => $user, group => $group});
	$daemon->app->routes->children([]);
	$daemon->app->routes->get('/' => sub {
		shift->render(json => {
			uid => getuid(),
			gid => getgid(),
			groups => [getgroups()],
		});
	});
	$daemon->run;
	exit 0;
}

my $ua = Mojo::UserAgent->new;
my @responses;
Mojo::IOLoop->delay(sub {
	Mojo::IOLoop->timer(0.2 => shift->begin);
}, sub {
	my $delay = shift;
	$ua->get("http://127.0.0.1:$port/", $delay->begin) for 1..5;
}, sub {
	my ($delay, @txs) = @_;
	push @responses, map { $_->res->body } @txs;
	Mojo::IOLoop->stop;
});

my $failed;
Mojo::IOLoop->timer(1 => sub { $failed = 1; Mojo::IOLoop->stop });
Mojo::IOLoop->start;

kill 'TERM', $pid or die "Failed to stop prefork server: $!";
waitpid $pid, 0;

ok !$failed, 'Loop stopped successfully';
my $orig_groups = delete $original->{groups};

foreach my $response (@responses) {
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
}

done_testing;
