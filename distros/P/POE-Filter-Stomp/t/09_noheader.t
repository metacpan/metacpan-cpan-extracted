use strict;
use Test::More (tests => 19);
use Data::Dumper;

BEGIN
{
    use_ok("POE::Filter::Stomp");
}

my $message = join(
    "\n",
    "DISCONNECT",
    "",
    "\000",
);
my $filter = POE::Filter::Stomp->new;

for (1..2) {
    my @parts = split_message($message . $message. $message);
    $filter->get_one_start(\@parts);
    for (1..3) {
        my $arrayref = $filter->get_one;
        my $frame = $arrayref->[0];
        ok($frame);
        isa_ok($frame, "Net::Stomp::Frame");
        is($frame->command, "DISCONNECT");
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
