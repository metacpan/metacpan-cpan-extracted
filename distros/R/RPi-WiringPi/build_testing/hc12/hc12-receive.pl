use warnings;
use strict;

use RPi::Serial;

my $run = 1;
$SIG{INT} = sub { $run = 0; };

if (! $ARGV[0]){
    print "usage: perl script.pl BAUDRATE\n";
    exit;
}
my $baud = $ARGV[0];
my $dev = '/dev/ttyUSB0';

my $s = RPi::Serial->new($dev, $baud);

my $cmd;

while ($run){
    print $s->avail . "\n";
    if ($s->avail){
        my $char = $s->getc;
        $cmd .= chr $char;

        if (hex(sprintf("%x", $char)) == 0x0A){
            print "> $cmd\n";
            $cmd = '';
        }
    }
}
