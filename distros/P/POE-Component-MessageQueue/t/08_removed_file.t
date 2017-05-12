use strict;
use warnings;
use lib 't/lib';

use POE::Component::MessageQueue::Test::Stomp;
use POE::Component::MessageQueue::Test::MQ;
use POE::Component::MessageQueue::Test::EngineMaker;

use File::Path;
use IO::Dir qw(DIR_UNLINK);
use Test::Exception;
use Test::More;

if ($^O eq 'MSWin32') {
    plan skip_all => 'Tests hang on Windows :(';
} else {
    plan tests => 10;
}

# 1) Start MQ with Filesystem
# 2) send some messages
# 3) shutdown MQ
# 4) delete the message bodies of a few
# 5) Start MQ back up
# 6) receive remaining messages without gumming anything up

lives_ok { 
	rmtree(DATA_DIR); 
	mkpath(DATA_DIR); 
	make_db() 
} 'setup data dir';

my $pid = start_mq(storage => 'FileSystem');
ok($pid, 'MQ started');
sleep 2;

lives_ok {
	my $sender = stomp_connect();
	stomp_send($sender) for (1..100);
	$sender->disconnect;
} 'messages sent';

ok(stop_fork($pid), 'MQ shut down');

my %data_dir;
tie %data_dir, 'IO::Dir', DATA_DIR, DIR_UNLINK;
sub find_messages { grep { /msg-.*\.txt/ } (keys %data_dir) }

my @files = find_messages();
is(@files, 100, "100 messages stored");
# Remove random files
for (1..20) {
	my $file = splice(@files, rand(@files), 1);
	delete $data_dir{$file};
}
is(find_messages(), 80, "20 messages removed");

$pid = start_mq(storage => 'FileSystem');
ok($pid, "MQ restarted");
sleep 2;

lives_ok { 
	my $stomp = stomp_connect();
	stomp_subscribe($stomp);
	stomp_receive($stomp) for (1..80);
	$stomp->disconnect;
} 'Got 80 messages';

ok(stop_fork($pid), 'MQ shut down');

lives_ok { rmtree(DATA_DIR) } 'Data dir removed';
