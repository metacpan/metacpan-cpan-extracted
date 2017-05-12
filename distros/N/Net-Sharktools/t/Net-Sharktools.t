use strict;
use warnings;

use FindBin qw( $Bin );
use File::Spec::Functions qw( catfile );

use Test::More tests => 5;
BEGIN { use_ok('Net::Sharktools', qw( perlshark_read perlshark_read_xs)) };

my $test_file = catfile($Bin, 'capture1.pcap');

my ($expected, $fields, $result);

$fields = [qw(
    frame.number
    ip.version
    tcp.seq
    udp.dstport
    frame.len
)];

$expected = {
    'frame.number' => 1, 
    'tcp.seq'      => undef,
    'frame.len'    => 60,
    'udp.dstport'  => 60000,
    'ip.version'   => 4,
};

$result = perlshark_read(
    filename => $test_file,
    fieldnames => $fields,
    dfilter => 'ip.version eq 4'
);

ok(defined($result), 'perlshark_read return');
is_deeply($result->[0], $expected, 'perlshark_read returns expected info');

$result = perlshark_read_xs(
    $test_file,
    $fields,
    'ip.version eq 4',
);

ok(defined($result), 'perlshark_read_xs return');
is_deeply($result->[0], $expected, 'perlshark_read_xs returns expected info');

