use strict; use warnings;
use Protocol::OSC;
use Net::LibLO::Message;
use Net::OpenSoundControl;
use Benchmark 'cmpthese';

my $protocol = Protocol::OSC->new;
my $data = $protocol->message(qw(/echo isf 3 laaaa 3.0));

cmpthese -1, {
    'Net::LibLO::Message' => sub { Net::LibLO::Message->new(qw(isf 3 laaaa 3.0)) },
    'Protocol::OSC' => sub { $protocol->message(qw(/echo isf 3 laaaa 3.0)) },
    'Net::OpenSoundControl' => sub { Net::OpenSoundControl::encode([qw(/echo i 3 s laaaa f 3.0)]) }
};

cmpthese -1, {
    'Protocol::OSC' => sub { $protocol->parse($data) },
    'Net::OpenSoundControl' => sub { Net::OpenSoundControl::decode($data) }
};
