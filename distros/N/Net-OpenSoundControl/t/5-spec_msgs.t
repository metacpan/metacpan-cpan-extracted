use Test::More tests => 2;

use Net::OpenSoundControl;

my $messages = [
    {
        message => ['/oscillator/4/frequency', 'f', 440.0],
        expect  => [
            qw( 2f 6f 73 63 69 6c 6c 61 74 6f 72 2f 34 2f 66 72
              65 71 75 65 6e 63 79  0 2c 66  0  0 43 dc  0  0
              )
        ]},
    {
        message =>
          ['/foo', 'i', 1000, 'i', -1, 's', 'hello', 'f', 1.234, 'f', 5.678],
        expect => [
            qw( 2f 66 6f 6f  0  0  0  0 2c 69 69 73 66 66  0  0
              0  0  3 e8 ff ff ff ff 68 65 6c 6c 6f  0  0  0
              3f 9d f3 b6 40 b5 b2 2d
              )
        ]}];

foreach (@$messages) {
    my $ok = 1;

    my $encode = Net::OpenSoundControl::encode($_->{message});
    if (length($encode) != scalar(@{$_->{expect}})) {
        diag("encoded message was wrong length");
        $ok = 0;
    } else {
        foreach my $n (0 .. length($encode) - 1) {
            my $char = substr($encode, $n, 1);
            my $hex = sprintf("%x", ord($char));

            if ($hex ne $_->{expect}->[$n]) {
                $ok = 0;
                diag("error on byte #$n, $hex ne $_->{expect}->[$n]");
            }
        }
        print "\n";
    }

    ok($ok);
}

