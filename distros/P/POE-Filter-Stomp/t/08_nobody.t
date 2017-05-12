use strict;
use Test::More (tests => 17);
use Data::Dumper;

BEGIN
{
    use_ok("POE::Filter::Stomp");
}

my $message = join(
    "\n",
    "CONNECTED",
	"session: client-290",
    "",
    "\000",
);
my $filter = POE::Filter::Stomp->new;

for (1..2) {
    my @parts = split_message($message . $message);
    $filter->get_one_start(\@parts);
    for (1..2) {
        my $arrayref = $filter->get_one;
        my $frame = $arrayref->[0];
        ok($frame);
        isa_ok($frame, "Net::Stomp::Frame");
        is($frame->command, "CONNECTED");
        is($frame->headers->{session}, "client-290");
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
