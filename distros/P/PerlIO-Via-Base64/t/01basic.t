use Test::More tests => 22;

BEGIN { use_ok('PerlIO::Via::Base64') }

my $file = 't/test.mime';

my $decoded = <<EOD;
This is a tést for MIME-encoded (base64) text that has hàrdly any speçial characters in it but which is nonetheless an indication of the real world.

With long lines and paragraphs and all that sort of things.

And so on and so on.
-- 
And a signature
EOD

my $encoded = <<EOD;
VGhpcyBpcyBhIHTpc3QgZm9yIE1JTUUtZW5jb2RlZCAoYmFzZTY0KSB0ZXh0IHRoYXQgaGFzIGjg
cmRseSBhbnkgc3Bl52lhbCBjaGFyYWN0ZXJzIGluIGl0IGJ1dCB3aGljaCBpcyBub25ldGhlbGVz
cyBhbiBpbmRpY2F0aW9uIG9mIHRoZSByZWFsIHdvcmxkLgoKV2l0aCBsb25nIGxpbmVzIGFuZCBw
YXJhZ3JhcGhzIGFuZCBhbGwgdGhhdCBzb3J0IG9mIHRoaW5ncy4KCkFuZCBzbyBvbiBhbmQgc28g
b24uCi0tIApBbmQgYSBzaWduYXR1cmUK
EOD

(my $encodednoeol = $encoded) =~ s#\n##sg;

# Check class methods

is( PerlIO::Via::Base64->eol,"\n",		'check eol setting first time' );

# Create the encoded test-file

ok(
 open( my $out,'>:Via(PerlIO::Via::Base64)', $file ),
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
 open( my $in,'<:Via(PerlIO::Via::Base64)', $file ),
 "opening '$file' for reading"
);
is( join( '',<$in> ),$decoded,		'check decoding' );
ok( close( $in ),			'close decoding handle' );

# Do the same, now without line endings

PerlIO::Via::Base64->eol( '' );
is( PerlIO::Via::Base64->eol,'',	'check eol setting second time' );

# Create the encoded test-file

ok(
 open( my $out,'>:Via(PerlIO::Via::Base64)', $file ),
 "opening '$file' for writing without eol"
);

ok( (print $out $decoded),		'print to file without eol' );
ok( close( $out ),			'closing encoding handle without eol' );

# Check encoding without layers

{
local $/ = undef;
ok( open( my $test,$file ),		'opening without layer without eol' );
is( readline( $test ),$encodednoeol,	'check encoded content without eol' );
ok( close( $test ),			'close test handle without eol' );
}

# Check decoding _with_ layers

ok(
 open( my $in,'<:Via(PerlIO::Via::Base64)', $file ),
 "opening '$file' for reading without eol"
);
is( join( '',<$in> ),$decoded,		'check decoding without eol' );
ok( close( $in ),			'close decoding handle without eol' );

# Remove whatever we created now

ok( unlink( $file ),			"remove test file '$file'" );
