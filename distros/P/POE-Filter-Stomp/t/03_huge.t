use strict;
use Test::More (tests => 21);

BEGIN
{
    use_ok("POE::Filter::Stomp");
}

# This is bigger
my $body = join(
    "\n",
    ("0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz") x 2000
);

my $count = 1;
my $message = join(
    "\n",
    "MESSAGE",
    "destination: /queue/foo",
    "",
    "$body\000",
);
my $filter = POE::Filter::Stomp->new;

for (1..2) {
    my @parts = split_message($message . "\n". $message);
    $filter->get_one_start(\@parts);
    for (1..2) {
        my $arrayref = $filter->get_one;
        my $frame = $arrayref->[0];
        ok($frame);
        isa_ok($frame, "Net::Stomp::Frame");
        is($frame->command, "MESSAGE");
	    is($frame->headers->{destination}, "/queue/foo");
        is($frame->body, $body);
    }
}

sub split_message
{
    my $message = shift;
    my $len     = length($message);

    my @ret;
    while ($len > 0) {
        push @ret, substr($message, 0, int(rand($len) + 1), '');
        $len = length($message);
    }
    return @ret;
}

