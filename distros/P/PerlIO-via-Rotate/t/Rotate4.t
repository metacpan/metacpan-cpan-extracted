BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
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

use PerlIO::via::Rotate 1;
use PerlIO::via::Rotate qw( 1 2 3 );

use Test::More tests => 10;

my $file= 'test.rot1';

my $decoded= <<EOD;
This is a test for rotated text that has hardly any special characters in it
but which is nonetheless an indication of the real world.

With long lines and paragraphs and all that sort of things.

And so on and so on.
-- 
And a signature
EOD

my $encoded= <<EOD;
Uijt jt b uftu gps spubufe ufyu uibu ibt ibsemz boz tqfdjbm dibsbdufst jo ju
cvu xijdi jt opofuifmftt bo joejdbujpo pg uif sfbm xpsme.

Xjui mpoh mjoft boe qbsbhsbqit boe bmm uibu tpsu pg uijoht.

Boe tp po boe tp po.
-- 
Boe b tjhobuvsf
EOD

# Create the encoded test-file

ok(
 open( my $out,'>:via(PerlIO::via::rot1)', $file ),
 "opening '$file' for writing"
);

ok( (print $out $decoded),		'print to file' );
ok( close( $out ),			'closing encoding handle' );

# Check encoding without layers

{
local $/ = undef;
ok( open( my $test,$file ),		'opening without layer' );
is( readline( $test ),$encoded,		'check encoded content' );
ok( close( $test ),			'close test handle' );
}

# Check decoding _with_ layers

ok(
 open( my $in,'<:via(rot1)', $file ),
 "opening '$file' for reading"
);
is( join( '',<$in> ),$decoded,		'check decoding' );
ok( close( $in ),			'close decoding handle' );

# Remove whatever we created now

ok( unlink( $file ),			"remove test file '$file'" );
1 while unlink $file; # multiversioned filesystems
