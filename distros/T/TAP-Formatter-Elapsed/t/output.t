#!perl -w

use strict;
use Test::More 0.88;

use TAP::Formatter::Elapsed;

my $formatter = TAP::Formatter::Elapsed->new;
isa_ok $formatter, 'TAP::Formatter::Elapsed';
isa_ok $formatter, 'TAP::Formatter::Console';

delete $ENV{'TAP_ELAPSED_FORMAT'};

# These lines shouldn't be modified.

is capture_output( $formatter, '# no timestamp' ), '# no timestamp', 'no change';
is capture_output( $formatter, 'ok     34 ms' ),   'ok     34 ms',   'no change';

# Test the default format.

my $expected = qr/\[\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d, \d\.\d\d, \d\.\d\d elapsed\]$/;

like capture_output( $formatter, 'ok 1' ),     qr/^ok 1 $expected/,     'default format';
like capture_output( $formatter, 'not ok 2' ), qr/^not ok 2 $expected/, 'default format';

# Test that setting the environment variable works.

$ENV{'TAP_ELAPSED_FORMAT'} = '%t0 %t1';

$expected = qr/\d\.\d\d \d\.\d\d$/;

like capture_output( $formatter, 'ok 3' ),     qr/^ok 3 $expected/,     'alternative format';
like capture_output( $formatter, 'not ok 4' ), qr/^not ok 4 $expected/, 'alternative format';

done_testing;

sub capture_output {
    my ( $formatter, $line ) = @_;

    open my $fh, '>', \my $stdout or die $!;
    $formatter->stdout($fh);
    $formatter->_output($line);
    close $fh;

    return $stdout;
}
