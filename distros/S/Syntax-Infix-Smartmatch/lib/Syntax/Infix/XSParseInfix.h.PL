#! perl

use strict;
use warnings;

if ($] >= 5.038) {
	require XS::Parse::Infix::Builder_data;
	open my $fh, '>', shift // 'XSParseInfix.h';
	print $fh XS::Parse::Infix::Builder_data::XSPARSEINFIX_H();
	close $fh;
}
