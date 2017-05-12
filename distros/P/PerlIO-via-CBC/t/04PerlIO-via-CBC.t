BEGIN {				# Magic Perl CORE pragma

	unshift @INC, '../lib';

    unless (find PerlIO::Layer 'perlio') {
        print "1..0 # Skip: PerlIO not used\n";
        exit 0;
    }
    if (ord("A") == 193) {
        print "1..0 # Skip: EBCDIC\n";
    }
}

use strict;
use warnings;
use Test::More tests => 8;

my $file = 'test.cbc';
my $key = 'my secret key';
my $text = 'this is just a little blind text! this is just a little blind text!this is just a little blind text!';

BEGIN { use_ok('PerlIO::via::CBC') };

ok( PerlIO::via::CBC->config(key => $key),	'check setting passphrase' );

ok( open( my $out, '>:via(PerlIO::via::CBC)', $file ), "opening '$file' for writing" );
ok( print($out $text), "writing '$text' to $file" );
ok( close( $out ), "close handle" );

ok( open( my $in, '<:via(PerlIO::via::CBC)', $file ), "opening '$file' for reading" );

is(
 scalar(<$in>),$text,
 'check plain text'
);

ok( close( $in ), "close handle" );

unlink $file;
