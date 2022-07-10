# Tests: async childs

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

# cpantester: strawberry perl defaults to JSON::PP and has blessing problem with JSON::true objects
BEGIN { $ENV{PERL_JSON_BACKEND} = 'JSON::backportPP' if ($^O eq 'MSWin32'); }

use Test::More;
use JSON;
use Data::Dumper;
use Time::HiRes qw(time);
use RPC::Switch::Client::Tiny::Async;

plan tests => 6;

# test async child
#
sub trace_cb {
	my ($type, $msg) = @_;
	printf "%s: %s\n", $type, to_json($msg, {pretty => 0, canonical => 1});
}

my $async = RPC::Switch::Client::Tiny::Async->new(trace_cb => \&trace_cb);

sub child_handler {
	my ($self, $fh) = @_;
	my $req = <$fh>;
	if ($req) {
		chomp $req;
		print ">> child $$ got: $req\n";
		print $fh "pong\n";
		$fh->flush();
	}
	exit 0;
}
my $worker = bless {};
my $child = $async->child_start($worker);

print {$child->{reader}} "ping\n";
$child->{reader}->flush();
my $res = readline($child->{reader});
chomp $res;

is($res, 'pong', "test async child read");

$async->child_finish($child, 'done');
my $remain = join(' ', keys %{$async->{finished}});
is($remain, $child->{pid}, "test async child finished");

$async->childs_reap();
$remain = join(' ', keys %{$async->{finished}});
is($remain, '', "test async child stopped");

# test async jobqueue
#
$async = RPC::Switch::Client::Tiny::Async->new(trace_cb => \&trace_cb, max_async => 4);

for my $id (1 .. 6) {
	$async->msg_enqueue({id => $id});
}

while (my $msg = $async->msg_dequeue()) {
	my $child = $async->child_start($worker, $msg->{id});
	$async->job_add($child, $msg->{id}, {});
}
my ($childs, $msgs) = $async->jobs_terminate('stopped', sub { $_[0]->{id} });

is(scalar @$msgs, 2, "test async jobqueue");
is(scalar @$childs, 4, "test async active jobs");

$async->childs_reap(nonblock => 1);
$async->childs_kill();
$async->childs_reap();

$childs = [values %{$async->{jobs}}];

is(scalar @$childs, 0, "test async active stopped");

