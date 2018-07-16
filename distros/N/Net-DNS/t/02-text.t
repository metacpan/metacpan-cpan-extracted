# $Id: 02-text.t 1694 2018-07-16 04:19:40Z willem $	-*-perl-*-

use strict;
use Test::More tests => 37;


use_ok('Net::DNS::Text');


{
	my $string = 'example';
	my $object = new Net::DNS::Text($string);
	ok( $object->isa('Net::DNS::Text'), 'object returned by new() constructor' );
	is( $object->value,  $string, 'expected object->value' );
	is( $object->string, $string, 'expected object->string' );
}


{
	eval { my $object = new Net::DNS::Text(); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "empty argument list\t[$exception]" );
}


{
	eval { my $object = new Net::DNS::Text(undef); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "argument undefined\t[$exception]" );
}


{
	my $sample = '';
	my $expect = '""';
	my $result = new Net::DNS::Text($sample)->string;
	is( $result, $expect, 'null argument' );
}


{
	my $sample = 'example';
	my $escape = '\e\x\a\m\p\l\e';
	my $result = new Net::DNS::Text($escape)->string;
	is( $result, $sample, 'character escape' );
}


{
	my $sample = 'A';
	my $escape = '\065';
	my $result = new Net::DNS::Text($escape)->string;
	is( $result, $sample, 'numeric escape' );
}


{
	my $string = 'a' x 256;
	my $object = new Net::DNS::Text($string);
	is( scalar(@$object),	       2,		'new() splits long argument' );
	is( length( $object->value ),  length($string), 'object->value reassembles string' );
	is( length( $object->string ), length($string), 'object->string reassembles string' );
}


{
	my $utf8   = '\192\160';
	my $filler = 'a' x 254;
	my $string = join '', $filler, $utf8;
	my $object = new Net::DNS::Text($string);
	is( length( $object->[0] ), length($filler), 'new() does not break UTF8 sequence' );
}


{
	my $sample = 'x\000x\031x\127x\128x\159\160\255x';
	my $expect = '7800781f787f7880789fa0ff78';
	my $length = sprintf '%02x', length pack( 'H*', $expect );
	my $object = new Net::DNS::Text($sample);
	my $buffer = $object->encode;
	is( unpack( 'H*', $buffer ),	  $length . $expect, 'encode() returns expected data' );
	is( unpack( 'H*', $object->raw ), $expect,	     'raw() returns expected data' );
}


{
	my $sample = 'example';
	my $buffer = new Net::DNS::Text($sample)->encode;
	my $object = decode Net::DNS::Text( \$buffer );
	ok( $object->isa('Net::DNS::Text'), 'object returned by decode() constructor' );
	is( $object->string, $sample, 'object matches original data' );
	my ( $x, $next ) = decode Net::DNS::Text( \$buffer );
	is( $next, length $buffer, 'expected offset returned by decode()' );
}


{
	my $sample = 'example';
	my $buffer = new Net::DNS::Text($sample)->encode;
	my ( $object, $next ) = decode Net::DNS::Text( \$buffer, 1, length($buffer) - 1 );
	is( $object->string, $sample,	     'decode() extracts arbitrary substring' );
	is( $next,	     length $buffer, 'expected offset returned by decode()' );
}


{
	my $sample = 'example';
	my $buffer = substr new Net::DNS::Text($sample)->encode, 0, 2;
	eval { my $object = decode Net::DNS::Text( \$buffer ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "corrupt wire-format\t[$exception]" );
}


{
	my %testcase = (
		'000102030405060708090a0b0c0d0e0f' =>
				'\000\001\002\003\004\005\006\007\008\009\010\011\012\013\014\015',
		'101112131415161718191a1b1c1d1e1f' =>
				'\016\017\018\019\020\021\022\023\024\025\026\027\028\029\030\031',
				);

	foreach my $hexcode ( sort keys %testcase ) {
		my $string  = $testcase{$hexcode};
		my $content = pack 'H*', $hexcode;
		my $buffer  = pack 'C a*', length $content, $content;
		my $decoded = decode Net::DNS::Text( \$buffer );
		my $compare = $decoded->string;
		is( $compare, qq($string), "C0 controls:\t$string" );
	}
}


{
	my %testcase = (
		'202122232425262728292a2b2c2d2e2f' => q|" !\"#$%&'()*+,-./"|,
		'303132333435363738393a3b3c3d3e3f' => '0123456789:\;<=>?',
		'404142434445464748494a4b4c4d4e4f' => '@ABCDEFGHIJKLMNO',
		'505152535455565758595a5b5c5d5e5f' => 'PQRSTUVWXYZ[\092]^_',
		'606162636465666768696a6b6c6d6e6f' => '`abcdefghijklmno',
		'707172737475767778797a7b7c7d7e7f' => 'pqrstuvwxyz{|}~\127'
		);

	foreach my $hexcode ( sort keys %testcase ) {
		my $string  = $testcase{$hexcode};
		my $content = pack 'H*', $hexcode;
		my $buffer  = pack 'C a*', length $content, $content;
		my $decoded = decode Net::DNS::Text( \$buffer );
		my $compare = $decoded->string;
		is( $compare, qq($string), "G0 graphics:\t$string" );
	}
}


{
	my %testcase = (
		'808182838485868788898a8b8c8d8e8f' =>
				'\128\129\130\131\132\133\134\135\136\137\138\139\140\141\142\143',
		'909192939495969798999a9b9c9d9e9f' =>
				'\144\145\146\147\148\149\150\151\152\153\154\155\156\157\158\159',
		'a0a1a2a3a4a5a6a7a8a9aaabacadaeaf' =>
				'\160\161\162\163\164\165\166\167\168\169\170\171\172\173\174\175',
		'b0b1b2b3b4b5b6b7b8b9babbbcbdbebf' =>
				'\176\177\178\179\180\181\182\183\184\185\186\187\188\189\190\191',
		'c0c1c2c3c4c5c6c7c8c9cacbcccdcecf' =>
				'\192\193\194\195\196\197\198\199\200\201\202\203\204\205\206\207',
		'd0d1d2d3d4d5d6d7d8d9dadbdcdddedf' =>
				'\208\209\210\211\212\213\214\215\216\217\218\219\220\221\222\223',
		'e0e1e2e3e4e5e6e7e8e9eaebecedeeef' =>
				'\224\225\226\227\228\229\230\231\232\233\234\235\236\237\238\239',
		'f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff' =>
				'\240\241\242\243\244\245\246\247\248\249\250\251\252\253\254\255'
				);

	foreach my $hexcode ( sort keys %testcase ) {
		my $string  = $testcase{$hexcode};
		my $encoded = new Net::DNS::Text($string)->encode;
		is( unpack( 'xH*', $encoded ), $hexcode, qq(8-bit codes:\t$string) );
	}
}

