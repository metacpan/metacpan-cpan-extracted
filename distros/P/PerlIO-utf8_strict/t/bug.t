#! perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Test::Exception;
use IO::Handle;
use lib 't/lib';
use Util qw[fh_with_octets slurp];


my $fh = fh_with_octets("\xE2\x98\xBA" x 8092);

lives_ok { 
    my $data = do { local $/; <$fh> } 
} q[successfull reading 8092 WHITE SMILING FACE's];

{
    my $line = 'ascii';
    my ( $in, $out );
    pipe $in, $out;
    binmode $out, ':utf8_strict';
    binmode $in,  ':utf8_strict';
    print $out "...\n";
    $out->flush;
    $line .= readline $in;

    is($line, "ascii...\n", 'Appending from utf8 to ascii');
}


done_testing;
