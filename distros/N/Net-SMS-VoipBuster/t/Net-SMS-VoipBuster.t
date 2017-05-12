use Test::More tests => 3;

BEGIN { use_ok('Net::SMS::VoipBuster') };

my $user = "xxxxx";
my $pass = "123456";
my $msg  = "This is msg for test....";
my $to   = "+351914235678";

my $c = Net::SMS::VoipBuster->new($user, $pass);

isa_ok($c, 'Net::SMS::VoipBuster');

my $res = $c->send($msg, $to);

is($res->{'is_error'}, 1, 'Failed to send SMS');
