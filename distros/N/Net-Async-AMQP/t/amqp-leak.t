use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Net::Async::AMQP;
use IO::Async::Loop;
use Variable::Disposition qw(dispose);

BEGIN {
	plan skip_all => 'set NET_ASYNC_AMQP_HOST/USER/PASS/VHOST env vars to test' unless exists $ENV{NET_ASYNC_AMQP_HOST};

	eval {
		require Test::MemoryGrowth;
		Test::MemoryGrowth->import;
		1
	} or plan skip_all => 'needs Test::MemoryGrowth installed'
}

my $loop = IO::Async::Loop->new;
for(1..3) {
	$loop->add(my $amqp = Net::Async::AMQP->new);
	{
	$amqp->connect(
	  host  => $ENV{NET_ASYNC_AMQP_HOST},
	  user  => $ENV{NET_ASYNC_AMQP_USER},
	  pass  => $ENV{NET_ASYNC_AMQP_PASS},
	  vhost => $ENV{NET_ASYNC_AMQP_VHOST},
	)->then(sub {
		my ($mq) = @_;
		$mq->open_channel->on_done(sub {
			my ($ch) = @_;
			die "Invalid channel ID" unless $ch->id;
#		})->then(sub {
#			$mq->close
		})
	})->get;
	}
	$loop->remove($amqp);
	is(exception {
		dispose $amqp;
	}, undef, 'can dispose of AMQP instance');
}
done_testing;

