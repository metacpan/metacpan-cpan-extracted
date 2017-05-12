#!perl

use strict;
use warnings;
use PerlIO::Util;

use Ruby::Run;

Perl.open($0, "<:flock :reverse :crlf"){
	|i|

	i.each{
		|l|
		print l;
	};
};