use Test::More tests => 5;

use Net::OpenSoundControl;

# Don't use non-integers for floating point tests, as
# e.g. 0.200000002980232 != 0.2. *sigh*.

my $msgs = [
    ["/test/1", 'b', "\001\002\003\004\005"],
    ["/test/2", 'f', 42],
    ["/test/3", 'i', 42],
    ["/test/4", 's', "Hello, world"],
    ["/test/5", 'b', "\007", 'i', 42, 'f', 42, 's', "Foo Bar Baz"]];

foreach my $m (@$msgs) {
    my $correct = 1;
    my $mnew = Net::OpenSoundControl::decode(Net::OpenSoundControl::encode($m));

    for (0 .. $#$mnew) {
        $correct = 0
          unless $mnew->[$_] eq $m->[$_];
    }

    ok($correct);
}
