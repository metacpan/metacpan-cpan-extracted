use strict;
use warnings;
use Test::More;
use Protocol::Redis::Faster;
use Protocol::Redis::Test;

protocol_redis_ok 'Protocol::Redis::Faster', 1;

my $protocol = Protocol::Redis::Faster->new(api => 1);

# Allow on_message callback to call on_message or parse
my @messages;
$protocol->on_message(sub {
  my ($protocol, $message) = @_;
  $protocol->on_message(sub { push @messages, $_[1] });
});

$protocol->parse("+one\r\n+two\r\n");
is_deeply \@messages, [{type => '+', data => 'two'}], 'on_message changed';

@messages = ();
$protocol->on_message(sub {
  my ($protocol, $message) = @_;
  $protocol->on_message(sub { push @messages, $_[1] });
  $protocol->parse("+two\r\n");
});

$protocol->parse("+one\r\n");
is_deeply \@messages, [{type => '+', data => 'two'}], 'parsed additional message';

done_testing;
